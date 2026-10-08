/**
 * INA Platform — /api/extract-template-data
 * Vercel serverless function (Node.js runtime, no external dependencies for
 * the request/response path itself — pdf-parse and the Bedrock SDK are
 * lazily require()'d, same pattern as api/analyze-project.js, see the
 * comment there for why. pdf-parse is pinned to 1.1.4, pure JS, no native
 * @napi-rs/canvas dependency — see that same comment for the Vercel bundling
 * issue that caused).
 *
 * Reads a project's uploaded documents (project_documents) and asks the
 * configured LLM provider to extract values for a caller-supplied list of
 * template fields (key/label/type/options), returning a flat
 * { field_key: value|null } object. Used by app/project-template.html's
 * "Autocomplete from documents" button (assets/platform.js's
 * autofillTemplateAnswers()) so guided templates (Datacenter, Submarine
 * Cable, USTDA preparation funding, FSU/BID/CAF financing, etc.) can be
 * pre-filled — at least partially — from whatever technical/economic/
 * administrative documentation was already attached to the project, instead
 * of the submitter retyping facts that are already written down somewhere.
 *
 * This function is deliberately STATELESS: it never writes to Supabase.
 * Merging the extracted answers into the project's shared_field_answers
 * pool (see migration_v23_project_shared_field_answers.sql) happens
 * client-side afterwards, through the normal RLS-protected supabase-js
 * client (INAPlatform.mergeSharedFieldAnswers()) — same trust boundary as
 * every other project edit, rather than trusting the service-role key with
 * a write it doesn't need to make.
 *
 * Required environment variables: same three Supabase vars as
 * api/analyze-project.js (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 * SUPABASE_ANON_KEY — the service role key is used only to read
 * project_documents/Storage server-side and to verify project ownership;
 * see api/analyze-project.js's file header for the full explanation), plus
 * the SAME LLM_PROVIDER switch and per-provider credentials
 * (ANTHROPIC_API_KEY / GROQ_API_KEY / AWS_* / BEDROCK_MODEL_ID /
 * LOCAL_LLM_BASE_URL / LOCAL_LLM_MODEL / LOCAL_LLM_API_KEY — see
 * api/analyze-project.js's file header for what each does, including
 * LLM_PROVIDER='local' for a model running on your own machine) — no new
 * env vars to set up here if AI Analysis is already configured.
 */

const GROQ_MODEL_DEFAULT = 'openai/gpt-oss-120b'; // was 'llama-3.3-70b-versatile' — Groq deprecated/shut it down 08/16/26, see api/analyze-project.js's header comment
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

// How many documents / how much text per document to read — generous
// relative to api/analyze-project.js's per-call budget (4-8K chars/doc)
// since this endpoint is meant to be called once per project and cached
// (see shared_field_answers), not on every page load.
const MAX_DOCUMENTS = 8;
const MAX_CHARS_PER_DOC = 6000;
const MAX_TOTAL_CHARS = 30000;
const MAX_FIELDS_PER_REQUEST = 60;

// The model call's own max_tokens (see the 4 provider branches below) was
// originally 2000 — too tight once a template's first autofill run sends
// most/all of its fields at once (autofillTemplateAnswers() in
// assets/platform.js only omits fields already in the shared pool, so on a
// brand-new project the very first template opened can easily send
// MAX_FIELDS_PER_REQUEST fields at once — DATACENTER_TEMPLATE and
// SUBMARINE_CABLE_TEMPLATE alone are each around 60-70 fields, several
// `textarea`). The model has to emit one JSON entry per field even for the
// nulls, so a large template's response routinely exceeded 2000 tokens and
// got cut off mid-object — valid-looking output that then failed
// `JSON.parse` below with exactly the "Could not parse extraction output"
// error surfaced to the user. Raised to 6000 (still comfortably under
// every configured provider's per-call ceiling) so a full
// MAX_FIELDS_PER_REQUEST-sized response — worst case, ~60 fields including
// a dozen-plus verbose textareas — has real headroom instead of routinely
// brushing the limit.

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

// Groq's "on_demand" free tier caps at a low tokens-per-minute budget
// SHARED across every AI feature on this same account — a 429 with code
// "rate_limit_exceeded" is routine under normal use, not a real failure,
// and Groq's own error body names exactly how long to wait ("Please try
// again in 17.9s"). One automatic retry after that wait turns a transient
// cross-feature collision into a few extra seconds instead of a hard
// error shown to the user. Bounded at 25s so a single retry can't blow
// past this function's maxDuration once the actual model call time is
// added back in. Same helper duplicated across every api/*.js that calls
// Groq (no shared module bundling on Vercel here).
async function fetchGroqWithRetry(body, headers) {
  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST', headers, body: JSON.stringify(body),
  });
  if (res.status !== 429) return res;
  const errBody = await res.clone().json().catch(() => null);
  if ((errBody && errBody.error && errBody.error.code) !== 'rate_limit_exceeded') return res;
  const match = /try again in ([\d.]+)s/i.exec((errBody.error && errBody.error.message) || '');
  const waitMs = Math.min(match ? Math.ceil(parseFloat(match[1]) * 1000) + 500 : 5000, 25000);
  console.warn(`[extract-template-data] Groq rate-limited, retrying once in ${waitMs}ms`);
  await new Promise((resolve) => setTimeout(resolve, waitMs));
  return fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST', headers, body: JSON.stringify(body),
  });
}

/* Same allowlist/CORS approach as api/analyze-project.js — see that file's
   comment for why this stays a small explicit list rather than '*'. */
const ALLOWED_ORIGINS = [
  'https://international-network-advisors.com',
  'https://www.international-network-advisors.com',
];
function isAllowedOrigin(origin) {
  if (!origin) return false;
  if (ALLOWED_ORIGINS.includes(origin)) return true;
  try {
    return new URL(origin).hostname.endsWith('.vercel.app');
  } catch (e) {
    return false;
  }
}

async function supabaseRest(path, { method = 'GET', body, serviceKey, supabaseUrl, extraHeaders } = {}) {
  const res = await fetch(`${supabaseUrl}/rest/v1${path}`, {
    method,
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      'Content-Type': 'application/json',
      Prefer: method === 'POST' || method === 'PATCH' ? 'return=representation' : undefined,
      ...extraHeaders,
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`Supabase REST ${method} ${path} failed: ${res.status} ${text}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

async function verifyUser(accessToken, { supabaseUrl, anonKey }) {
  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: anonKey, Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) return null;
  return res.json();
}

async function downloadStorageFile(storagePath, { supabaseUrl, serviceKey }) {
  const res = await fetch(
    `${supabaseUrl}/storage/v1/object/project-documents/${storagePath}`,
    { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } }
  );
  if (!res.ok) return null;
  const arrayBuffer = await res.arrayBuffer();
  return Buffer.from(arrayBuffer);
}

function guessMediaType(fileName) {
  const ext = (fileName.split('.').pop() || '').toLowerCase();
  if (ext === 'pdf') return 'application/pdf';
  if (['txt', 'md', 'csv'].includes(ext)) return 'text/plain';
  // Images are deliberately not read here — this endpoint only ever
  // text-extracts (see file header: no vision call is made, to keep the
  // Groq/Bedrock/Anthropic paths behaving identically and the cost/latency
  // predictable for what's meant to be a background "nice to have"
  // convenience, not the main AI Analysis flow).
  return null;
}

function buildFieldsSpec(fields) {
  // Trimmed-down shape sent to the model — just what it needs to decide a
  // value, nothing about bilingual labels/i18n keys.
  return fields.map((f) => {
    const spec = { key: f.key, label: f.label, type: f.type };
    if (f.type === 'select' && Array.isArray(f.options)) {
      spec.allowed_values = f.options.map((o) => o.value);
      spec.options = f.options.map((o) => `${o.value} = ${o.label}`);
    }
    return spec;
  });
}

// Per-agent hint (see migration_v71_agent_hints.sql / app/ai-hints.html) —
// a row of free text an admin can edit live from the platform, fetched
// fresh on every request and appended to buildSystemPrompt()'s output by
// the handler below. Replaces the old api/extract-template-data.hints.js
// static file (oct 2026) — see api/analyze-project.js's matching comment
// for why.
async function getAgentHint(agentKey, { supabaseUrl, serviceKey }) {
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/agent_hints?agent_key=eq.${agentKey}&select=hint_text`,
      { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } }
    );
    if (!res.ok) return '';
    const rows = await res.json();
    return (rows[0] && rows[0].hint_text) || '';
  } catch (e) { return ''; }
}
function hintsSuffix(text) {
  return text && text.trim() ? `\n\nADDITIONAL GUIDANCE FROM INA:\n${text.trim()}` : '';
}

// Admin-only debug mode (migration_v74_debug_mode.sql / app/debug-log.html)
// — see api/extract-project-data.js's matching comment for the full
// rationale; duplicated here per this codebase's usual convention (no
// shared module bundling between these standalone Vercel functions).
const AGENT_VERSION = '1.0';
async function isDebugModeOn({ supabaseUrl, anonKey }) {
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/app_settings?select=debug_mode&limit=1`, { headers: { apikey: anonKey } });
    if (!res.ok) return false;
    const rows = await res.json();
    return !!(rows[0] && rows[0].debug_mode);
  } catch (e) { return false; }
}
async function logDebugAgentCall({ supabaseUrl, serviceKey, userId, agentKey, provider, model, durationMs, usage, systemPrompt, userContent, rawResponse }) {
  try {
    await fetch(`${supabaseUrl}/rest/v1/debug_log`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
      body: JSON.stringify({
        log_type: 'ai_agent',
        user_id: userId,
        agent_key: agentKey,
        agent_version: AGENT_VERSION,
        provider,
        model,
        duration_ms: durationMs,
        prompt_tokens: (usage && (usage.prompt_tokens ?? usage.input_tokens ?? usage.inputTokens)) ?? null,
        completion_tokens: (usage && (usage.completion_tokens ?? usage.output_tokens ?? usage.outputTokens)) ?? null,
        total_tokens: (usage && (usage.total_tokens ?? usage.totalTokens ?? (((usage.input_tokens ?? usage.inputTokens) || 0) + ((usage.output_tokens ?? usage.outputTokens) || 0)))) ?? null,
        details: { systemPrompt, userContent, usage, rawResponse },
      }),
    });
  } catch (e) { /* swallow — see api/extract-project-data.js's matching comment */ }
}

function buildSystemPrompt(fieldsSpec) {
  return `You are a form-filling assistant for INA (International Network Advisors)'s project intake platform. You will be given the text of one or more documents attached to a digital-infrastructure project (technical folders, economic/financial documentation, administrative documentation, etc.) and a list of form fields that need values.

For EACH field in the list, look for a clearly stated or directly inferable value in the documents. If you find one:
- For a "select" field, respond with EXACTLY one of that field's allowed_values (the code, not the human label) — never invent a value outside that list.
- For a "text" field, respond with a short, precise value (a name, a number with its unit, a date, etc.) — not a full sentence copied from the document.
- For a "textarea" field, a concise 1-4 sentence value is fine, but stay factual and specific to what the documents actually say.

If a field's value is not stated anywhere in the documents, or you are not reasonably confident, respond with null for that field — never guess or fabricate a plausible-sounding answer.

Fields to fill (JSON):
${JSON.stringify(fieldsSpec)}

Respond with ONLY a single valid JSON object — no markdown code fences, no commentary — mapping every field's "key" to either a value (string) or null. Include every key exactly once.`;
}

function normalizeExtractedValue(field, raw) {
  if (raw === null || raw === undefined) return null;
  let value = String(raw).trim();
  if (!value || value.toLowerCase() === 'null' || value.toLowerCase() === 'n/a') return null;
  if (field.type === 'select') {
    const allowed = (field.options || []).map((o) => o.value);
    return allowed.includes(value) ? value : null;
  }
  const cap = field.type === 'textarea' ? 2000 : 300;
  return value.slice(0, cap);
}

async function handler(req, res) {
  const origin = req.headers.origin;
  if (isAllowedOrigin(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }
  if (req.method !== 'POST') {
    return json(res, 405, { error: 'Method not allowed' });
  }

  const {
    ANTHROPIC_API_KEY,
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    SUPABASE_ANON_KEY,
    CLAUDE_MODEL,
    LLM_PROVIDER,
    GROQ_API_KEY,
    GROQ_MODEL,
    AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY,
    AWS_REGION,
    BEDROCK_MODEL_ID,
    LOCAL_LLM_BASE_URL,
    LOCAL_LLM_MODEL,
    LOCAL_LLM_API_KEY,
  } = process.env;

  const provider = (LLM_PROVIDER || 'anthropic').toLowerCase();
  const providerKeyMissing = provider === 'groq'
    ? !GROQ_API_KEY
    : provider === 'bedrock'
      ? (!AWS_ACCESS_KEY_ID || !AWS_SECRET_ACCESS_KEY)
      : provider === 'bedrock-mock'
        ? false
        : provider === 'local'
          ? !LOCAL_LLM_MODEL
          : !ANTHROPIC_API_KEY;
  if (providerKeyMissing || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY) {
    return json(res, 500, {
      error: `Server misconfigured: missing required environment variables (provider: ${provider}).`,
    });
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (e) {
    return json(res, 400, { error: 'Invalid JSON body' });
  }
  const { projectId } = body || {};
  const fields = Array.isArray(body && body.fields) ? body.fields.slice(0, MAX_FIELDS_PER_REQUEST) : [];
  if (!projectId) return json(res, 400, { error: 'projectId is required' });
  if (!fields.length) return json(res, 200, { ok: true, answers: {}, documentsUsed: [], skipped: [] });

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const extraHints = await getAgentHint('extract-template-data', { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
    const user = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!user || !user.id) return json(res, 401, { error: 'Invalid session' });
    const debugOn = await isDebugModeOn({ supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });

    const projects = await supabaseRest(`/projects?id=eq.${projectId}&select=id,user_id,assigned_advisor_id`, {
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });
    const project = projects && projects[0];
    if (!project) return json(res, 404, { error: 'Project not found' });
    const isOwner = project.user_id === user.id;
    const isAssignedAdvisor = !!project.assigned_advisor_id && project.assigned_advisor_id === user.id;
    if (!isOwner && !isAssignedAdvisor) return json(res, 403, { error: 'Not your project' });

    const documents = await supabaseRest(`/project_documents?project_id=eq.${projectId}&select=*`, {
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });

    const documentsUsed = [];
    const skipped = [];
    let combinedText = '';

    const docsToRead = provider === 'bedrock-mock' ? [] : (documents || []).slice(0, MAX_DOCUMENTS);
    for (const doc of docsToRead) {
      if (combinedText.length >= MAX_TOTAL_CHARS) {
        skipped.push(`${doc.file_name} (budget reached)`);
        continue;
      }
      const mediaType = guessMediaType(doc.file_name);
      if (!mediaType) {
        skipped.push(`${doc.file_name} (not text-readable — image or unsupported type)`);
        continue;
      }
      const fileBuffer = await downloadStorageFile(doc.storage_path, {
        supabaseUrl: SUPABASE_URL,
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      });
      if (!fileBuffer) { skipped.push(`${doc.file_name} (couldn't download)`); continue; }

      if (mediaType === 'application/pdf') {
        if (fileBuffer.length > 25 * 1024 * 1024) {
          skipped.push(`${doc.file_name} (too large)`);
          continue;
        }
        // require('pdf-parse') deliberately lazy — see file header and
        // api/analyze-project.js's matching comment (pinned to 1.1.4, the
        // pure-JS line with no @napi-rs/canvas native dependency, which is
        // what broke this on Vercel).
        let pdfParseFn = null;
        try {
          pdfParseFn = require('pdf-parse');
        } catch (loadErr) {
          skipped.push(`${doc.file_name} (PDF text extraction unavailable in this environment)`);
        }
        if (pdfParseFn) {
          try {
            const extracted = await pdfParseFn(fileBuffer);
            const text = (extracted.text || '').trim();
            if (text) {
              combinedText += `\n\n--- FILE: ${doc.file_name} ---\n${text.slice(0, MAX_CHARS_PER_DOC)}`;
              documentsUsed.push(doc.file_name);
            } else {
              skipped.push(`${doc.file_name} (no extractable text — likely scanned/image-only)`);
            }
          } catch (e) {
            skipped.push(`${doc.file_name} (couldn't parse PDF)`);
          }
        }
      } else if (mediaType === 'text/plain') {
        combinedText += `\n\n--- FILE: ${doc.file_name} ---\n${fileBuffer.toString('utf-8').slice(0, MAX_CHARS_PER_DOC)}`;
        documentsUsed.push(doc.file_name);
      }
    }

    if (!documentsUsed.length && provider !== 'bedrock-mock') {
      // Nothing readable — return early rather than spend a model call on
      // an empty prompt.
      return json(res, 200, { ok: true, answers: {}, documentsUsed: [], skipped });
    }

    const fieldsSpec = buildFieldsSpec(fields);
    const systemPrompt = buildSystemPrompt(fieldsSpec) + hintsSuffix(extraHints);
    const userContent = `PROJECT DOCUMENTS:\n${combinedText || '(none readable)'}`;

    let rawText;
    const _debugStart = Date.now();
    let _debugModel = null;
    let _debugUsage = null;
    if (provider === 'bedrock-mock') {
      // No model call, no fabricated values for a data-entry feature (see
      // file header) — every field simply comes back null/not found.
      rawText = JSON.stringify(Object.fromEntries(fields.map((f) => [f.key, null])));
    } else if (provider === 'groq') {
      const groqRes = await fetchGroqWithRetry({
        model: GROQ_MODEL || GROQ_MODEL_DEFAULT,
        max_tokens: 6000,
        temperature: 0,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userContent },
        ],
      }, { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` });
      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        console.error(`[extract-template-data] Groq request failed (status ${groqRes.status}):`, errText);
        return json(res, 502, { error: 'Extraction model request failed', detail: errText });
      }
      const groqData = await groqRes.json();
      rawText = (groqData.choices && groqData.choices[0] && groqData.choices[0].message && groqData.choices[0].message.content) || '';
      _debugModel = GROQ_MODEL || GROQ_MODEL_DEFAULT;
      _debugUsage = groqData.usage;
    } else if (provider === 'local') {
      // Same OpenAI-compatible shape as the Groq branch — see the matching
      // branch/comment in api/analyze-project.js for the full explanation,
      // including the important caveat that this function runs in Vercel's
      // cloud, not on your PC.
      const localRes = await fetch(`${(LOCAL_LLM_BASE_URL || LOCAL_LLM_BASE_URL_DEFAULT).replace(/\/$/, '')}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(LOCAL_LLM_API_KEY ? { Authorization: `Bearer ${LOCAL_LLM_API_KEY}` } : {}),
        },
        body: JSON.stringify({
          model: LOCAL_LLM_MODEL,
          max_tokens: 6000,
          temperature: 0,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!localRes.ok) {
        const errText = await localRes.text().catch(() => '');
        console.error(`[extract-template-data] local model request failed (status ${localRes.status}):`, errText);
        return json(res, 502, { error: 'Extraction model request failed (local model)', detail: errText });
      }
      const localData = await localRes.json();
      rawText = (localData.choices && localData.choices[0] && localData.choices[0].message && localData.choices[0].message.content) || '';
      _debugModel = LOCAL_LLM_MODEL;
      _debugUsage = localData.usage;
    } else if (provider === 'bedrock') {
      try {
        const { BedrockRuntimeClient, ConverseCommand } = require('@aws-sdk/client-bedrock-runtime');
        const bedrockClient = new BedrockRuntimeClient({
          region: AWS_REGION || BEDROCK_REGION_DEFAULT,
          credentials: { accessKeyId: AWS_ACCESS_KEY_ID, secretAccessKey: AWS_SECRET_ACCESS_KEY },
        });
        const bedrockRes = await bedrockClient.send(new ConverseCommand({
          modelId: BEDROCK_MODEL_ID || BEDROCK_MODEL_DEFAULT,
          system: [{ text: systemPrompt }],
          messages: [{ role: 'user', content: [{ text: userContent }] }],
          inferenceConfig: { maxTokens: 6000, temperature: 0 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
        _debugModel = BEDROCK_MODEL_ID || BEDROCK_MODEL_DEFAULT;
        _debugUsage = bedrockRes.usage;
      } catch (bedrockErr) {
        console.error('[extract-template-data] Bedrock request failed:', bedrockErr);
        return json(res, 502, {
          error: 'Extraction model request failed',
          detail: String((bedrockErr && bedrockErr.message) || bedrockErr),
        });
      }
    } else {
      const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01',
        },
        body: JSON.stringify({
          model: CLAUDE_MODEL || 'claude-sonnet-5',
          max_tokens: 6000,
          temperature: 0,
          system: systemPrompt,
          messages: [{ role: 'user', content: userContent }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        console.error(`[extract-template-data] Anthropic request failed (status ${anthropicRes.status}):`, errText);
        return json(res, 502, { error: 'Extraction model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
      _debugModel = CLAUDE_MODEL || 'claude-sonnet-5';
      _debugUsage = anthropicData.usage;
    }

    if (debugOn) {
      await logDebugAgentCall({
        supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY, userId: user.id,
        agentKey: 'extract-template-data', provider, model: _debugModel,
        durationMs: Date.now() - _debugStart, usage: _debugUsage,
        systemPrompt, userContent, rawResponse: rawText,
      });
    }

    let parsed;
    try {
      // Strip a leading <think>...</think> block — see the matching
      // comment/fix in api/analyze-project.js and
      // api/extract-business-card.js for why.
      const withoutThink = rawText.replace(/^\s*<think>[\s\S]*?<\/think>\s*/i, '');
      let cleaned = withoutThink.trim().replace(/^```json\s*/i, '').replace(/```$/, '').trim();
      // Defensive trim to the outer { ... } object even though the prompt
      // says "ONLY a single valid JSON object, no commentary" — some
      // providers/models still occasionally wrap it in a stray sentence
      // ("Here is the extracted data: {...}") that the code-fence strip
      // above doesn't catch. Slicing from the first "{" to the last "}"
      // recovers those without touching well-formed output at all (a
      // response that's already just "{...}" slices to itself).
      const firstBrace = cleaned.indexOf('{');
      const lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace !== -1 && lastBrace > firstBrace) {
        cleaned = cleaned.slice(firstBrace, lastBrace + 1);
      }
      parsed = JSON.parse(cleaned);
    } catch (e) {
      console.error('[extract-template-data] could not parse model output as JSON:', e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse extraction output', raw: rawText.slice(0, 2000) });
    }

    const answers = {};
    fields.forEach((f) => {
      const value = normalizeExtractedValue(f, parsed[f.key]);
      if (value !== null) answers[f.key] = value;
    });

    return json(res, 200, { ok: true, answers, documentsUsed, skipped });
  } catch (err) {
    console.error('[extract-template-data] unhandled error:', err);
    return json(res, 500, { error: 'Extraction failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 60 };
