/**
 * INA Platform — /api/extract-project-data
 * Vercel serverless function (Node.js runtime, no external dependencies for
 * the request/response path itself — pdf-parse is lazily require()'d, same
 * pattern as every other extraction endpoint, see their headers for why.
 * Pinned to pdf-parse 1.1.4, pure JS, no native @napi-rs/canvas dependency).
 *
 * Pablo (sep 2026): "En forma similar [a Success Cases], cuando se carga un
 * proyecto nuevo se debe tener la opción de hacerlo desde uno o varios PDF
 * y que un agente lea los documentos y obtenga todos los atributos
 * posibles. Luego, permitir la edición de los datos como hasta ahora."
 *
 * Reads ONE OR SEVERAL documents (technical folders, terms of reference,
 * project briefs, feasibility studies, etc.) that the client has ALREADY
 * uploaded to Supabase Storage (project-documents bucket, under
 * `${userId}/tmp-extractions/{timestamp}_{filename}` per file — see
 * assets/platform.js's uploadTempExtractionFile()) — the request body only
 * carries `files: [{storagePath, fileName}, ...]`, never the files' bytes.
 * This replaced an earlier design that sent every PDF directly as base64 in
 * the POST body, which broke in real production with a "413 Content Too
 * Large" on Vercel: Vercel's Node.js serverless functions enforce a hard
 * ~4.5MB request body ceiling that no app-level config can raise, and
 * several small PDFs together crossed it easily. Each file is downloaded
 * server-side via the service-role key (same pattern as
 * api/extract-template-data.js's downloadStorageFile()) and their text is
 * concatenated (same multi-document concatenation approach
 * api/extract-template-data.js already uses for documents already attached
 * to an EXISTING project). There's no project row yet to attach documents
 * to — every storagePath is a TEMPORARY one, deleted by the client right
 * after extraction via deleteTempExtractionFile(), best-effort. Because the
 * service-role key bypasses Storage RLS entirely, this handler manually
 * re-verifies that EACH storagePath's first two segments are
 * `${user.id}/tmp-extractions/` before ever downloading it. Proposes values for
 * every extractable field on app/new-project.html's creation wizard step 1
 * (identity/attributes) and step 3 (budget) — see that file's comment
 * block above its own document-upload zones (step 2) for why FSU/program/
 * other-financing fields are NOT part of this list: those were moved out
 * of project creation entirely and now live on app/project-financing.html,
 * reachable only once the project already exists, so there is nothing here
 * for this endpoint to target for them.
 *
 * Unlike api/extract-template-data.js (a generic engine driven by a
 * caller-supplied field list, since guided templates vary per program),
 * this endpoint's field list is FIXED — new-project.html's creation wizard
 * is the same shape for every project — so the spec lives here as a
 * constant rather than being sent by the client on every call.
 *
 * This is deliberately a PROPOSAL, not a write: it never touches Supabase,
 * every field it returns lands in ordinary editable wizard inputs
 * (assets/platform.js's extractProjectData(), app/new-project.html's
 * "Cargar desde uno o varios PDF" box) for the user to review/correct —
 * "permitir la edición de los datos como hasta ahora" — before Step 1's
 * usual "Continue" button actually calls createProject().
 *
 * NOT gated to advisor/admin (unlike extract-success-case.js/
 * extract-business-card.js) — creating a project has never required a
 * special role (see app/new-project.html's init(), just requireAuth()), so
 * this endpoint only verifies the caller has a valid session.
 *
 * Text-only extraction (pdf-parse), no vision call — same LLM_PROVIDER
 * switch/credentials as AI Analysis/Autocomplete (anthropic/groq/bedrock/
 * bedrock-mock/local — see api/analyze-project.js's file header for what
 * each env var does).
 *
 * Required environment variables: same LLM_PROVIDER switch + per-provider
 * credentials as api/analyze-project.js, plus SUPABASE_URL/
 * SUPABASE_SERVICE_ROLE_KEY/SUPABASE_ANON_KEY (used only to verify the
 * caller's session — never to write anything).
 */

const GROQ_MODEL_DEFAULT = 'openai/gpt-oss-120b'; // see api/analyze-project.js's header — Groq deprecated the previous default 08/16/26
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

const MAX_FILES = 5;
const MAX_CHARS_PER_DOC = 8000;
const MAX_TOTAL_CHARS = 30000;

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

async function verifyUser(accessToken, { supabaseUrl, anonKey }) {
  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: anonKey, Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) return null;
  return res.json();
}

// Same pattern as api/extract-template-data.js's downloadStorageFile() —
// server-side read of the project-documents bucket via the service-role
// key, so the request body never has to carry any file's bytes.
async function downloadStorageFile(storagePath, { supabaseUrl, serviceKey }) {
  const res = await fetch(
    `${supabaseUrl}/storage/v1/object/project-documents/${storagePath}`,
    { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } }
  );
  if (!res.ok) return null;
  const arrayBuffer = await res.arrayBuffer();
  return Buffer.from(arrayBuffer);
}

/* Fixed field spec for app/new-project.html's wizard — step 1 (identity/
   attributes) + step 3 (budget). Kept in the exact same {key,label,type,
   options} shape api/extract-template-data.js uses, and select
   allowed_values copied verbatim from assets/platform.js's PROJECT_TYPES/
   ENTITY_TYPES/COUNTRIES_AMERICAS/PRIORITY_LABELS/CRITICALITY_LABELS/
   COMPLEXITY_LABELS/DURATION_UNIT_LABELS constants — duplicated here
   (rather than imported) since this file runs standalone on Vercel with no
   shared module bundling, same reasoning as extract-success-case.js's
   ALLOWED_SECTORS. Keep this list in sync if those taxonomies ever change,
   and if new-project.html ever grows new step-1/3 fields. */
const PROJECT_TYPE_VALUES = [
  'submarine_cable', 'fiber_backbone_last_mile', 'fixed_wireless_access',
  'wholesale_neutral_network', 'ai_datacenter', 'satellite_constellation',
  'early_warning_system', 'passive_infrastructure', 'other',
];
const ENTITY_TYPE_VALUES = [
  'regulator', 'national_gov', 'provincial_gov', 'municipal_gov',
  'isp', 'manufacturer', 'integrator', 'other',
];
const COUNTRY_VALUES = [
  'Antigua and Barbuda', 'Argentina', 'Bahamas', 'Barbados', 'Belize', 'Bolivia', 'Brazil',
  'Canada', 'Chile', 'Colombia', 'Costa Rica', 'Cuba', 'Dominica', 'Dominican Republic',
  'Ecuador', 'El Salvador', 'Grenada', 'Guatemala', 'Guyana', 'Haiti', 'Honduras', 'Jamaica',
  'Mexico', 'Nicaragua', 'Panama', 'Paraguay', 'Peru', 'Saint Kitts and Nevis', 'Saint Lucia',
  'Saint Vincent and the Grenadines', 'Suriname', 'Trinidad and Tobago', 'United States',
  'Uruguay', 'Venezuela',
];
const TIER_VALUES = ['low', 'medium', 'high'];
const DURATION_UNIT_VALUES = ['days', 'months'];

const FIELDS = [
  { key: 'name', label: 'Project name', type: 'text' },
  { key: 'projectType', label: 'Project type', type: 'select', options: PROJECT_TYPE_VALUES.map((v) => ({ value: v })) },
  { key: 'generatingEntityName', label: 'Name of the entity/organization behind the project', type: 'text' },
  { key: 'generatingEntityType', label: 'Type of that entity', type: 'select', options: ENTITY_TYPE_VALUES.map((v) => ({ value: v })) },
  { key: 'description', label: 'Project description', type: 'textarea' },
  { key: 'country', label: 'Country', type: 'select', options: COUNTRY_VALUES.map((v) => ({ value: v })) },
  { key: 'beneficiaryCount', label: 'Number of beneficiaries (people/institutions reached)', type: 'text' },
  { key: 'durationValue', label: 'Project duration — the number only (e.g. "18")', type: 'text' },
  { key: 'durationUnit', label: 'Unit for the duration number — days or months', type: 'select', options: DURATION_UNIT_VALUES.map((v) => ({ value: v })) },
  { key: 'priority', label: 'Management priority/urgency of the project', type: 'select', options: TIER_VALUES.map((v) => ({ value: v })) },
  { key: 'technicalCriticality', label: 'Technical criticality (impact if this project fails or is delayed)', type: 'select', options: TIER_VALUES.map((v) => ({ value: v })) },
  { key: 'complexity', label: 'Intrinsic complexity of the project (moving parts, interdependencies, unproven technology)', type: 'select', options: TIER_VALUES.map((v) => ({ value: v })) },
  { key: 'budgetAmount', label: 'Total project budget, in Argentine pesos (ARS) — the number only', type: 'text' },
  { key: 'budgetAmountUsd', label: 'Total project budget, in US dollars (USD) — the number only', type: 'text' },
  { key: 'exchangeRate', label: 'ARS/USD exchange rate used for the budget, if stated', type: 'text' },
  { key: 'financingRequiredPercentage', label: 'Percentage (0-100) of the total budget that still needs external financing', type: 'text' },
];

function buildFieldsSpec() {
  return FIELDS.map((f) => {
    const spec = { key: f.key, label: f.label, type: f.type };
    if (f.type === 'select') spec.allowed_values = f.options.map((o) => o.value);
    return spec;
  });
}

function buildSystemPrompt(fieldsSpec) {
  return `You are a form-filling assistant for INA (International Network Advisors)'s project intake platform. You will be given the text of one or more documents describing a proposed digital-infrastructure/connectivity project (a technical folder, terms of reference, project brief, feasibility study, etc.) and a list of form fields that need values to help create a new project record.

For EACH field in the list, look for a clearly stated or directly inferable value in the documents. If you find one:
- For a "select" field, respond with EXACTLY one of that field's allowed_values — never invent a value outside that list. If nothing in the documents clearly matches one of the allowed values, respond null rather than guessing the closest one.
- For a "text" field that is actually a plain number (duration, budget, exchange rate, percentage, beneficiary count), respond with just the number, no currency symbols, no thousands separators, no unit text.
- For "description", write a factual 3-6 sentence summary in the SAME LANGUAGE the source documents are mostly written in, covering what the project is and its main objective — do not just copy a long passage verbatim.
- For "name", propose a short, specific project name/title (a few words) — not a full sentence.

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
  const cap = field.type === 'textarea' ? 3000 : 300;
  return value.slice(0, cap);
}

function guessMediaType(fileName) {
  const ext = ((fileName || '').split('.').pop() || '').toLowerCase();
  return ext === 'pdf' ? 'application/pdf' : null;
}

function parseModelJson(rawText) {
  // Strip a leading <think>...</think> block — same reasoning-model guard
  // as every other extraction endpoint here.
  const withoutThink = (rawText || '').replace(/^\s*<think>[\s\S]*?<\/think>\s*/i, '');
  let cleaned = withoutThink.trim().replace(/^```json\s*/i, '').replace(/```$/, '').trim();
  const firstBrace = cleaned.indexOf('{');
  const lastBrace = cleaned.lastIndexOf('}');
  if (firstBrace !== -1 && lastBrace > firstBrace) {
    cleaned = cleaned.slice(firstBrace, lastBrace + 1);
  }
  return JSON.parse(cleaned);
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
  const files = Array.isArray(body && body.files) ? body.files.slice(0, MAX_FILES) : [];
  if (!files.length) return json(res, 400, { error: 'files (array of {storagePath, fileName}) is required' });

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const user = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!user || !user.id) return json(res, 401, { error: 'Invalid session' });

    // Security-critical: SUPABASE_SERVICE_ROLE_KEY bypasses Storage RLS
    // entirely, so this check is the ONLY thing standing between an
    // authenticated user and someone else's file. uploadTempExtractionFile()
    // in assets/platform.js always writes under `${userId}/tmp-
    // extractions/...`, so refuse any storagePath that doesn't match the
    // CALLING user's own id in that first segment.
    const ownPrefix = `${user.id}/tmp-extractions/`;
    const invalidPath = files.find((f) => !(f && typeof f.storagePath === 'string' && f.storagePath.startsWith(ownPrefix)));
    if (invalidPath) return json(res, 403, { error: 'Invalid storagePath.' });

    const fieldsSpec = buildFieldsSpec();

    if (provider === 'bedrock-mock') {
      // No model call, no fabricated values for a data-entry feature (see
      // file header) — every field simply comes back null/not found.
      return json(res, 200, {
        ok: true,
        fields: Object.fromEntries(FIELDS.map((f) => [f.key, null])),
        documentsUsed: [],
        skipped: files.map((f) => (f && f.fileName) || 'file'),
      });
    }

    const documentsUsed = [];
    const skipped = [];
    let combinedText = '';

    for (const file of files) {
      const fileName = (file && file.fileName) || 'document.pdf';
      if (!file || !file.storagePath) { skipped.push(`${fileName} (no storagePath)`); continue; }
      if (combinedText.length >= MAX_TOTAL_CHARS) {
        skipped.push(`${fileName} (budget reached)`);
        continue;
      }
      if (guessMediaType(fileName) !== 'application/pdf') {
        skipped.push(`${fileName} (not a PDF)`);
        continue;
      }
      const pdfBuffer = await downloadStorageFile(file.storagePath, {
        supabaseUrl: SUPABASE_URL,
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      });
      if (!pdfBuffer) { skipped.push(`${fileName} (couldn't download)`); continue; }
      // Raised from 25MB to 40MB per file (sep 2026, same round as the
      // storagePath rewrite above) — see extract-success-case.js's matching
      // comment: this cap no longer needs to sit under Vercel's request-body
      // ceiling now that files arrive via Storage download, not the body.
      if (pdfBuffer.length > 40 * 1024 * 1024) {
        skipped.push(`${fileName} (too large)`);
        continue;
      }
      // require('pdf-parse') deliberately lazy — see file header and
      // api/analyze-project.js's matching comment (pinned to 1.1.4, the
      // pure-JS line with no @napi-rs/canvas native dependency).
      let pdfParseFn = null;
      try {
        pdfParseFn = require('pdf-parse');
      } catch (loadErr) {
        skipped.push(`${fileName} (PDF text extraction unavailable in this environment)`);
        continue;
      }
      try {
        const extracted = await pdfParseFn(pdfBuffer);
        const text = (extracted.text || '').trim();
        if (text) {
          combinedText += `\n\n--- FILE: ${fileName} ---\n${text.slice(0, MAX_CHARS_PER_DOC)}`;
          documentsUsed.push(fileName);
        } else {
          skipped.push(`${fileName} (no extractable text — likely scanned/image-only)`);
        }
      } catch (e) {
        skipped.push(`${fileName} (couldn't parse PDF)`);
      }
    }

    if (!documentsUsed.length) {
      return json(res, 200, {
        ok: true,
        fields: Object.fromEntries(FIELDS.map((f) => [f.key, null])),
        documentsUsed: [],
        skipped,
      });
    }

    const systemPrompt = buildSystemPrompt(fieldsSpec);
    const userContent = `PROJECT DOCUMENTS:\n${combinedText}`;

    let rawText;
    if (provider === 'groq') {
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` },
        body: JSON.stringify({
          model: GROQ_MODEL || GROQ_MODEL_DEFAULT,
          max_tokens: 3000,
          temperature: 0,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        console.error(`[extract-project-data] Groq request failed (status ${groqRes.status}):`, errText);
        return json(res, 502, { error: 'Extraction model request failed', detail: errText });
      }
      const groqData = await groqRes.json();
      rawText = (groqData.choices && groqData.choices[0] && groqData.choices[0].message && groqData.choices[0].message.content) || '';
    } else if (provider === 'local') {
      const localRes = await fetch(`${(LOCAL_LLM_BASE_URL || LOCAL_LLM_BASE_URL_DEFAULT).replace(/\/$/, '')}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(LOCAL_LLM_API_KEY ? { Authorization: `Bearer ${LOCAL_LLM_API_KEY}` } : {}),
        },
        body: JSON.stringify({
          model: LOCAL_LLM_MODEL,
          max_tokens: 3000,
          temperature: 0,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!localRes.ok) {
        const errText = await localRes.text().catch(() => '');
        console.error(`[extract-project-data] local model request failed (status ${localRes.status}):`, errText);
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
          inferenceConfig: { maxTokens: 3000, temperature: 0 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
      } catch (bedrockErr) {
        console.error('[extract-project-data] Bedrock request failed:', bedrockErr);
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
          max_tokens: 3000,
          temperature: 0,
          system: systemPrompt,
          messages: [{ role: 'user', content: userContent }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        console.error(`[extract-project-data] Anthropic request failed (status ${anthropicRes.status}):`, errText);
        return json(res, 502, { error: 'Extraction model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
    }

    let parsed;
    try {
      parsed = parseModelJson(rawText);
    } catch (e) {
      console.error('[extract-project-data] could not parse model output as JSON:', e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse extraction output', raw: rawText.slice(0, 2000) });
    }

    const fields = {};
    FIELDS.forEach((f) => {
      fields[f.key] = normalizeExtractedValue(f, parsed[f.key]);
    });

    return json(res, 200, { ok: true, fields, documentsUsed, skipped });
  } catch (err) {
    console.error('[extract-project-data] unhandled error:', err);
    return json(res, 500, { error: 'Extraction failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 60 };
