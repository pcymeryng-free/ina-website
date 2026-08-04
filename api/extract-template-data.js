/**
 * INA Platform — /api/extract-template-data
 * Vercel serverless function (Node.js runtime, no external dependencies for
 * the request/response path itself — pdf-parse and the Bedrock SDK are
 * lazily require()'d, same pattern as api/analyze-project.js, see the
 * comment there for why).
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

const GROQ_MODEL_DEFAULT = 'llama-3.3-70b-versatile';
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

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
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
    const user = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!user || !user.id) return json(res, 401, { error: 'Invalid session' });

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
        // api/analyze-project.js's matching comment.
        let PDFParseCtor = null;
        try {
          ({ PDFParse: PDFParseCtor } = require('pdf-parse'));
        } catch (loadErr) {
          skipped.push(`${doc.file_name} (PDF text extraction unavailable in this environment)`);
        }
        if (PDFParseCtor) {
          const parser = new PDFParseCtor({ data: fileBuffer });
          try {
            const extracted = await parser.getText();
            const text = (extracted.text || '').trim();
            if (text) {
              combinedText += `\n\n--- FILE: ${doc.file_name} ---\n${text.slice(0, MAX_CHARS_PER_DOC)}`;
              documentsUsed.push(doc.file_name);
            } else {
              skipped.push(`${doc.file_name} (no extractable text — likely scanned/image-only)`);
            }
          } catch (e) {
            skipped.push(`${doc.file_name} (couldn't parse PDF)`);
          } finally {
            await parser.destroy().catch(() => {});
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
    const systemPrompt = buildSystemPrompt(fieldsSpec);
    const userContent = `PROJECT DOCUMENTS:\n${combinedText || '(none readable)'}`;

    let rawText;
    if (provider === 'bedrock-mock') {
      // No model call, no fabricated values for a data-entry feature (see
      // file header) — every field simply comes back null/not found.
      rawText = JSON.stringify(Object.fromEntries(fields.map((f) => [f.key, null])));
    } else if (provider === 'groq') {
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` },
        body: JSON.stringify({
          model: GROQ_MODEL || GROQ_MODEL_DEFAULT,
          max_tokens: 2000,
          temperature: 0,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        return json(res, 502, { error: 'Extraction model request failed', detail: errText });
      }
      const groqData = await groqRes.json();
      rawText = (groqData.choices && groqData.choices[0] && groqData.choices[0].message && groqData.choices[0].message.content) || '';
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
          max_tokens: 2000,
          temperature: 0,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!localRes.ok) {
        const errText = await localRes.text().catch(() => '');
        return json(res, 502, { error: 'Extraction model request failed (local model)', detail: errText });
      }
      const localData = await localRes.json();
      rawText = (localData.choices && localData.choices[0] && localData.choices[0].message && localData.choices[0].message.content) || '';
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
          inferenceConfig: { maxTokens: 2000, temperature: 0 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
      } catch (bedrockErr) {
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
          max_tokens: 2000,
          temperature: 0,
          system: systemPrompt,
          messages: [{ role: 'user', content: userContent }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        return json(res, 502, { error: 'Extraction model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
    }

    let parsed;
    try {
      const cleaned = rawText.trim().replace(/^```json\s*/i, '').replace(/```$/, '');
      parsed = JSON.parse(cleaned);
    } catch (e) {
      return json(res, 502, { error: 'Could not parse extraction output', raw: rawText.slice(0, 2000) });
    }

    const answers = {};
    fields.forEach((f) => {
      const value = normalizeExtractedValue(f, parsed[f.key]);
      if (value !== null) answers[f.key] = value;
    });

    return json(res, 200, { ok: true, answers, documentsUsed, skipped });
  } catch (err) {
    return json(res, 500, { error: 'Extraction failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 60 };
