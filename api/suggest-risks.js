/**
 * INA Platform — /api/suggest-risks
 * Vercel serverless function (Node.js runtime).
 *
 * "Sugerir riesgos desde documentos" button on app/risk-matrix.html (Pablo,
 * oct 2026: HUB Digital Chubut had a full "Matriz de riesgos del proyecto"
 * inside its uploaded PDF, but project_risks stayed empty because the Risk
 * Matrix was only ever filled by hand — nothing read the documents into
 * it). Reads the project's description + attached documents and asks the
 * model for a list of risks shaped exactly like project_risks rows.
 *
 * NOTHING IS SAVED HERE. The endpoint only returns suggestions; the
 * advisor reviews them in risk-matrix.html and the ones they tick are
 * inserted client-side via INAPlatform.createProjectRisk() — same RLS
 * (advisor/admin insert only, migration_v41_project_risks.sql) and same
 * activity logging as a risk typed in by hand.
 *
 * Same env vars / LLM_PROVIDER switch as api/analyze-project.js (see its
 * file header for the full explanation of each provider): 'anthropic'
 * (default, reads PDFs natively), 'groq', 'bedrock', 'local' (PDF text
 * extracted with pdf-parse 1.1.4), 'bedrock-mock' (no model call, returns
 * one placeholder suggestion labeled SIMULADO). Helpers are duplicated
 * from analyze-project.js per this codebase's convention (no shared module
 * bundling between these standalone Vercel functions).
 *
 * NOTE: this is the 12th file in api/ — the Vercel Hobby plan's cap is 12
 * Serverless Functions per deployment (see the manageUserUrl() comment in
 * assets/platform.js). A 13th endpoint will need to be merged into an
 * existing one.
 */

const GROQ_MODEL_DEFAULT = 'openai/gpt-oss-120b';
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

// Must match the project_risks.category check constraint
// (migration_v41_project_risks.sql) and RISK_CATEGORIES in platform.js.
const RISK_CATEGORY_KEYS = [
  'legal_regulatory', 'technical', 'financial', 'market_demand',
  'environmental_social', 'governance', 'operational', 'political', 'other',
];

const MAX_SUGGESTIONS = 15;

// Text-only providers can't take whole PDFs. A plain head-truncation (what
// analyze-project.js does at 4000 chars) would miss exactly what this agent
// needs — in the HUB Digital Chubut deck the risk matrix was on page 17 of
// 18. So after a short opening for context, the budget goes to windows of
// lines around risk vocabulary, densest windows first (a risk table mentions
// "riesgo"/"mitigación" many times in a few lines), then re-emitted in
// document order. Line-based rather than paragraph-based: pdf-parse output
// of slide decks has few blank lines, so "paragraphs" can be whole pages.
const RISK_KEYWORDS = /riesg|risk|mitiga|amenaz|threat|contingen|vulnerab|sobrecost|overrun|demora|delay|incertidumbre|uncertaint|sensibilidad|sensitivity|garant[ií]a|guarantee|seguro|insurance/i;
function selectRiskPassages(text, budget) {
  if (text.length <= budget) return text;
  const head = text.slice(0, Math.min(1500, Math.floor(budget / 4)));
  const lines = text.slice(head.length).split('\n');
  const windows = [];
  lines.forEach((line, i) => {
    if (!RISK_KEYWORDS.test(line)) return;
    const start = Math.max(0, i - 2);
    const end = Math.min(lines.length, i + 15);
    const last = windows[windows.length - 1];
    if (last && start <= last.end) { last.end = end; last.hits += 1; } else windows.push({ start, end, hits: 1 });
  });
  let used = head.length;
  const picked = [];
  [...windows].sort((a, b) => b.hits - a.hits).forEach((w) => {
    const chunk = lines.slice(w.start, w.end).join('\n').trim();
    if (used + chunk.length + 6 > budget) return;
    used += chunk.length + 6;
    picked.push({ start: w.start, chunk });
  });
  return head + picked.sort((a, b) => a.start - b.start).map((p) => `\n[…]\n${p.chunk}`).join('');
}

function buildSystemPrompt(lang) {
  const language = lang === 'en' ? 'English' : 'Spanish (Argentina)';
  return `You are a senior project-finance risk analyst at INA (International Network Advisors), building the structured risk register ("Matriz de Riesgos") of a digital infrastructure project.

You will be given the project's name, type, country, description and its attached documents, plus the risks already registered (if any). Identify the project's risks:
1. FIRST, every risk the documents explicitly name — a risk matrix, risk table, sensitivity analysis, "riesgo principal", conditions for viability, etc. Keep the document's own wording for the title and its stated mitigation. These are the priority: never drop one.
2. THEN, only if clearly supported by the material, material risks the documents imply but don't list (e.g. a stated dependency on an anchor client, a permit not yet obtained). Do not invent generic boilerplate risks unrelated to this project.
Skip anything already in EXISTING RISKS (same risk under a different wording counts as already registered).

For each risk:
- probability and impact: integers 1-5 (1 = very low, 5 = very high). If the document gives a level or heat-map position, follow it; if it singles a risk out as the main/critical one or quantifies a severe effect, score it accordingly; otherwise estimate conservatively from the evidence and say so in "basis".
- category: exactly one of ${RISK_CATEGORY_KEYS.join(', ')}.
- source: the file name (and page/section if identifiable) the risk comes from, or "inferred" for type-2 risks.
- basis: one short sentence explaining the probability/impact you chose.

Write title, description, mitigation_measures and basis in ${language}. At most ${MAX_SUGGESTIONS} risks, most severe first.

Respond with ONLY a JSON object, no markdown fences, in this exact shape:
{"risks": [{"title": "<max 120 chars>", "description": "<the impact/consequence, max 400 chars>", "category": "<key>", "probability": <1-5>, "impact": <1-5>, "mitigation_measures": "<max 400 chars, empty string if none stated or inferable>", "owner_entity_name": "<entity responsible if the documents name one, else empty string>", "source": "<...>", "basis": "<...>"}]}`;
}

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

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

// See analyze-project.js's fetchGroqWithRetry() for the full rationale.
async function fetchGroqWithRetry(body, headers) {
  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST', headers, body: JSON.stringify(body),
  });
  if (res.status !== 429) return res;
  const errBody = await res.clone().json().catch(() => null);
  if ((errBody && errBody.error && errBody.error.code) !== 'rate_limit_exceeded') return res;
  const match = /try again in ([\d.]+)s/i.exec((errBody.error && errBody.error.message) || '');
  const waitMs = Math.min(match ? Math.ceil(parseFloat(match[1]) * 1000) + 500 : 5000, 25000);
  console.warn(`[suggest-risks] Groq rate-limited, retrying once in ${waitMs}ms`);
  await new Promise((resolve) => setTimeout(resolve, waitMs));
  return fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST', headers, body: JSON.stringify(body),
  });
}

// CORS — see analyze-project.js's matching comment.
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

async function supabaseRest(path, { method = 'GET', body, serviceKey, supabaseUrl } = {}) {
  const res = await fetch(`${supabaseUrl}/rest/v1${path}`, {
    method,
    headers: {
      apikey: serviceKey,
      Authorization: `Bearer ${serviceKey}`,
      'Content-Type': 'application/json',
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
  return Buffer.from(await res.arrayBuffer());
}

function guessMediaType(fileName) {
  const ext = (fileName.split('.').pop() || '').toLowerCase();
  if (ext === 'pdf') return 'application/pdf';
  if (['png'].includes(ext)) return 'image/png';
  if (['jpg', 'jpeg'].includes(ext)) return 'image/jpeg';
  if (['txt', 'md', 'csv'].includes(ext)) return 'text/plain';
  return null;
}

function clampLevel(n) {
  const v = Math.round(Number(n));
  if (Number.isNaN(v)) return 3;
  return Math.max(1, Math.min(5, v));
}

function normalizeSuggestions(parsed) {
  const list = Array.isArray(parsed && parsed.risks) ? parsed.risks : [];
  return list
    .filter((r) => r && String(r.title || '').trim())
    .slice(0, MAX_SUGGESTIONS)
    .map((r) => ({
      title: String(r.title).trim().slice(0, 120),
      description: String(r.description || '').trim().slice(0, 400),
      category: RISK_CATEGORY_KEYS.includes(r.category) ? r.category : 'other',
      probability: clampLevel(r.probability),
      impact: clampLevel(r.impact),
      mitigation_measures: String(r.mitigation_measures || '').trim().slice(0, 400),
      owner_entity_name: String(r.owner_entity_name || '').trim().slice(0, 120),
      source: String(r.source || '').trim().slice(0, 160),
      basis: String(r.basis || '').trim().slice(0, 300),
    }));
}

async function handler(req, res) {
  const origin = req.headers.origin;
  if (isAllowedOrigin(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') { res.status(204).end(); return; }
  if (req.method !== 'POST') return json(res, 405, { error: 'Method not allowed' });

  const {
    ANTHROPIC_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY, CLAUDE_MODEL,
    LLM_PROVIDER, GROQ_API_KEY, GROQ_MODEL, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION,
    BEDROCK_MODEL_ID, LOCAL_LLM_BASE_URL, LOCAL_LLM_MODEL, LOCAL_LLM_API_KEY,
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
    return json(res, 500, { error: `Server misconfigured: missing required environment variables (provider: ${provider}).` });
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (e) {
    return json(res, 400, { error: 'Invalid JSON body' });
  }
  const { projectId } = body || {};
  const lang = (body && body.lang) === 'en' ? 'en' : 'es';
  if (!projectId) return json(res, 400, { error: 'projectId is required' });

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  const sb = { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL };

  try {
    const user = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!user || !user.id) return json(res, 401, { error: 'Invalid session' });

    // Same gate as project_risks' insert RLS (is_advisor() or is_admin()):
    // no point suggesting risks to someone who can't save them.
    const callerProfiles = await supabaseRest(`/profiles?id=eq.${user.id}&select=role`, sb);
    const role = callerProfiles && callerProfiles[0] && callerProfiles[0].role;
    if (role !== 'advisor' && role !== 'admin') return json(res, 403, { error: 'Only advisors and admins can manage risks' });

    const projects = await supabaseRest(`/projects?id=eq.${projectId}&select=*`, sb);
    const project = projects && projects[0];
    if (!project) return json(res, 404, { error: 'Project not found' });

    const [documents, existingRisks] = await Promise.all([
      supabaseRest(`/project_documents?project_id=eq.${projectId}&select=*&order=uploaded_at.desc`, sb),
      supabaseRest(`/project_risks?project_id=eq.${projectId}&select=title,category`, sb),
    ]);
    if (!documents || !documents.length) {
      return json(res, 422, {
        error: lang === 'es'
          ? 'Este proyecto no tiene documentos cargados para analizar.'
          : 'This project has no uploaded documents to analyze.',
      });
    }

    const debugOn = await isDebugModeOn({ supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    const extraHints = await getAgentHint('suggest-risks', sb);
    const SYSTEM_PROMPT = buildSystemPrompt(lang) + hintsSuffix(extraHints);

    const textOnlyProvider = provider === 'groq' || provider === 'bedrock' || provider === 'local';
    // Groq's free tier is capped at ~6K tokens/minute shared across every
    // AI feature (see analyze-project.js) — keep its input much smaller.
    const perDocBudget = provider === 'groq' ? 6000 : 20000;
    const contentBlocks = [];
    let projectText = `PROJECT NAME: ${project.name}\nPROJECT TYPE: ${project.project_type}\nCOUNTRY: ${project.country}\n\nDESCRIPTION:\n${project.description || ''}`;
    projectText += `\n\nEXISTING RISKS (already registered — do not repeat):\n${
      (existingRisks || []).length ? existingRisks.map((r) => `- ${r.title} (${r.category})`).join('\n') : '(none)'
    }`;

    const docsToInclude = provider === 'bedrock-mock' ? [] : documents.slice(0, 5);
    const skippedNotes = [];
    for (const doc of docsToInclude) {
      const mediaType = guessMediaType(doc.file_name);
      if (!mediaType) { skippedNotes.push(doc.file_name); continue; }
      const fileBuffer = await downloadStorageFile(doc.storage_path, sb);
      if (!fileBuffer) { skippedNotes.push(doc.file_name); continue; }

      if (mediaType === 'application/pdf') {
        if (fileBuffer.length > 25 * 1024 * 1024) {
          skippedNotes.push(`${doc.file_name} (too large)`);
        } else if (textOnlyProvider) {
          // Lazy require — see analyze-project.js's header comment on
          // pdf-parse 1.1.4.
          let pdfParseFn = null;
          try { pdfParseFn = require('pdf-parse'); } catch (loadErr) {
            skippedNotes.push(`${doc.file_name} (PDF text extraction unavailable in this environment)`);
          }
          if (pdfParseFn) {
            try {
              const extracted = await pdfParseFn(fileBuffer);
              const text = (extracted.text || '').trim();
              if (text) {
                projectText += `\n\n--- ATTACHED FILE (text extracted from PDF): ${doc.file_name} ---\n${selectRiskPassages(text, perDocBudget)}`;
              } else {
                skippedNotes.push(`${doc.file_name} (no extractable text — likely scanned/image-only)`);
              }
            } catch (e) {
              skippedNotes.push(`${doc.file_name} (couldn't parse PDF)`);
            }
          }
        } else {
          // Title the block so the model can cite the file name in "source".
          contentBlocks.push({ type: 'text', text: `--- ATTACHED FILE: ${doc.file_name} ---` });
          contentBlocks.push({
            type: 'document',
            source: { type: 'base64', media_type: mediaType, data: fileBuffer.toString('base64') },
          });
        }
      } else if (mediaType.startsWith('image/')) {
        if (textOnlyProvider) {
          skippedNotes.push(`${doc.file_name} (image — not analyzed with this model provider)`);
        } else {
          contentBlocks.push({ type: 'text', text: `--- ATTACHED FILE: ${doc.file_name} ---` });
          contentBlocks.push({
            type: 'image',
            source: { type: 'base64', media_type: mediaType, data: fileBuffer.toString('base64') },
          });
        }
      } else if (mediaType === 'text/plain') {
        projectText += `\n\n--- ATTACHED FILE: ${doc.file_name} ---\n${selectRiskPassages(fileBuffer.toString('utf-8'), perDocBudget)}`;
      }
    }
    if (skippedNotes.length) {
      projectText += `\n\n(Attached files not machine-readable here: ${skippedNotes.join(', ')})`;
    }
    contentBlocks.unshift({ type: 'text', text: projectText });

    let rawText;
    const _debugStart = Date.now();
    let _debugModel = null;
    let _debugUsage = null;
    const chatMessages = [
      { role: 'system', content: SYSTEM_PROMPT },
      { role: 'user', content: projectText },
    ];

    if (provider === 'bedrock-mock') {
      rawText = JSON.stringify({ risks: [{
        title: '[SIMULADO] Riesgo de ejemplo — no se llamó a ningún modelo',
        description: 'Dato de prueba (LLM_PROVIDER=bedrock-mock). No es un riesgo real de este proyecto.',
        category: 'other', probability: 3, impact: 3, mitigation_measures: '', owner_entity_name: '',
        source: 'inferred', basis: 'SIMULADO',
      }] });
    } else if (provider === 'groq') {
      const groqRes = await fetchGroqWithRetry({
        model: GROQ_MODEL || GROQ_MODEL_DEFAULT, max_tokens: 4000, temperature: 0.2, messages: chatMessages,
      }, { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` });
      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        console.error(`[suggest-risks] projectId=${projectId} Groq request failed (status ${groqRes.status}):`, errText);
        return json(res, 502, { error: 'Risk suggestion model request failed', detail: errText });
      }
      const groqData = await groqRes.json();
      rawText = (groqData.choices && groqData.choices[0] && groqData.choices[0].message && groqData.choices[0].message.content) || '';
      _debugModel = GROQ_MODEL || GROQ_MODEL_DEFAULT;
      _debugUsage = groqData.usage;
    } else if (provider === 'local') {
      const localRes = await fetch(`${(LOCAL_LLM_BASE_URL || LOCAL_LLM_BASE_URL_DEFAULT).replace(/\/$/, '')}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(LOCAL_LLM_API_KEY ? { Authorization: `Bearer ${LOCAL_LLM_API_KEY}` } : {}),
        },
        body: JSON.stringify({ model: LOCAL_LLM_MODEL, max_tokens: 4000, temperature: 0.2, messages: chatMessages }),
      });
      if (!localRes.ok) {
        const errText = await localRes.text().catch(() => '');
        console.error(`[suggest-risks] projectId=${projectId} local model request failed (status ${localRes.status}):`, errText);
        return json(res, 502, { error: 'Risk suggestion model request failed (local model)', detail: errText });
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
          system: [{ text: SYSTEM_PROMPT }],
          messages: [{ role: 'user', content: [{ text: projectText }] }],
          inferenceConfig: { maxTokens: 4000, temperature: 0.2 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
        _debugModel = BEDROCK_MODEL_ID || BEDROCK_MODEL_DEFAULT;
        _debugUsage = bedrockRes.usage;
      } catch (bedrockErr) {
        console.error(`[suggest-risks] projectId=${projectId} Bedrock request failed:`, bedrockErr);
        return json(res, 502, { error: 'Risk suggestion model request failed', detail: String((bedrockErr && bedrockErr.message) || bedrockErr) });
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
          max_tokens: 4000,
          system: SYSTEM_PROMPT,
          messages: [{ role: 'user', content: contentBlocks }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        console.error(`[suggest-risks] projectId=${projectId} Anthropic request failed (status ${anthropicRes.status}):`, errText);
        return json(res, 502, { error: 'Risk suggestion model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
      _debugModel = CLAUDE_MODEL || 'claude-sonnet-5';
      _debugUsage = anthropicData.usage;
    }

    if (debugOn) {
      const attachmentCount = contentBlocks.filter((b) => b.type !== 'text').length;
      const attachmentNote = attachmentCount ? `\n\n(+${attachmentCount} document/image attachment(s) also sent to the model, not included here)` : '';
      await logDebugAgentCall({
        supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY, userId: user.id,
        agentKey: 'suggest-risks', provider, model: _debugModel,
        durationMs: Date.now() - _debugStart, usage: _debugUsage,
        systemPrompt: SYSTEM_PROMPT, userContent: projectText + attachmentNote, rawResponse: rawText,
      });
    }

    let parsed;
    try {
      const withoutThink = rawText.replace(/^\s*<think>[\s\S]*?<\/think>\s*/i, '');
      const cleaned = withoutThink.trim().replace(/^```json\s*/i, '').replace(/```$/, '');
      parsed = JSON.parse(cleaned);
    } catch (e) {
      console.error(`[suggest-risks] projectId=${projectId} provider=${provider} could not parse model output as JSON:`, e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse risk suggestions', raw: rawText.slice(0, 2000) });
    }

    return json(res, 200, { ok: true, suggestions: normalizeSuggestions(parsed), skipped: skippedNotes });
  } catch (err) {
    console.error(`[suggest-risks] projectId=${projectId} provider=${provider} unhandled error:`, err);
    return json(res, 500, { error: 'Risk suggestion failed', detail: String(err && err.message || err) });
  }
}

module.exports = handler;
// Large PDFs can take a while — see analyze-project.js's header comment.
module.exports.config = { maxDuration: 60 };
