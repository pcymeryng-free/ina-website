/**
 * INA Platform — /api/extract-success-case
 * Vercel serverless function (Node.js runtime, no external dependencies for
 * the request/response path itself — pdf-parse is lazily require()'d, same
 * pattern as api/analyze-project.js/api/extract-template-data.js, see those
 * files' headers for why. Pinned to pdf-parse 1.1.4, pure JS, no native
 * @napi-rs/canvas dependency).
 *
 * Reads a case-study PDF sent directly in the request body as base64 —
 * nothing has been saved to Storage yet at this point, same shape as
 * api/extract-business-card.js's imageBase64/mediaType (there is no
 * success_cases row yet either, unlike api/extract-template-data.js which
 * reads documents already attached to an existing project) — and asks the
 * LLM to propose values for the New Success Case form's fields: title,
 * provider/technology, country, region, sector (must be one of the closed
 * taxonomy values — see migration_v59_success_cases.sql's check
 * constraint), a bilingual summary, beneficiaries reached, an extra
 * metrics/quote field, and a source label.
 *
 * Pablo (sep 2026): "El alta de un nuevo Success case se debería poder
 * cargar a partir de un documento pdf subido a la plataforma. Luego
 * completar los datos restantes, si fuera necesario, a mano." — so this
 * endpoint is deliberately a PROPOSAL, not a write: it never touches
 * Supabase, and every field it returns lands in ordinary editable form
 * inputs on app/new-success-case.html (assets/platform.js's
 * extractSuccessCase()) for the advisor to review/correct before saving.
 *
 * Text-only extraction (pdf-parse), no vision call — so this reuses the
 * SAME LLM_PROVIDER switch/credentials as AI Analysis/Autocomplete
 * (anthropic/groq/bedrock/bedrock-mock/local — see api/analyze-project.js's
 * file header for what each env var does), unlike
 * api/extract-business-card.js which specifically needs a vision-capable
 * model for a photographed card.
 *
 * Gated to advisor/admin, read server-side via the service role key —
 * matches migration_v59_success_cases.sql's insert policy (only an
 * advisor/admin can ever save a Success Case), so this endpoint enforces
 * the same bar rather than leaving it to the client.
 *
 * Required environment variables: same LLM_PROVIDER switch + per-provider
 * credentials as api/analyze-project.js, plus SUPABASE_URL/
 * SUPABASE_SERVICE_ROLE_KEY/SUPABASE_ANON_KEY (used only to verify the
 * caller's session + role — never to write anything).
 */

const GROQ_MODEL_DEFAULT = 'openai/gpt-oss-120b'; // see api/analyze-project.js's header — Groq deprecated the previous default 08/16/26
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

// A case-study PDF is meant to be short (a few pages at most) — generous
// relative to api/analyze-project.js's per-project budget, but no need for
// api/extract-template-data.js's much larger multi-document ceiling.
const MAX_CHARS_FROM_PDF = 15000;
// Base64 is ~33% larger than the raw file; this caps the raw PDF at
// roughly 12MB, comfortably inside Vercel's request body limit.
const MAX_BASE64_LENGTH = 16 * 1024 * 1024;

// Must match migration_v59_success_cases.sql's `sector` check constraint
// exactly (also mirrored client-side in assets/platform.js's
// SUCCESS_CASE_SECTORS — duplicated here rather than imported since this
// file runs standalone on Vercel with no shared module bundling).
const ALLOWED_SECTORS = [
  'education', 'health', 'emergency_response', 'agriculture',
  'government', 'financial_inclusion', 'other',
];

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

async function getProfileRole(userId, { supabaseUrl, serviceKey }) {
  const res = await fetch(
    `${supabaseUrl}/rest/v1/profiles?id=eq.${userId}&select=role`,
    { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } }
  );
  if (!res.ok) return null;
  const rows = await res.json();
  return (rows && rows[0] && rows[0].role) || null;
}

const SYSTEM_PROMPT = `You are a form-filling assistant for INA (International Network Advisors)'s project intake platform. You will be given the extracted text of a case-study document (a real-world example of digital infrastructure or connectivity technology reaching a community, sector or region) and must propose values for a "Success Case" library entry.

Extract these fields:
- title: a short, specific case title (e.g. "Conectividad satelital en escuelas rurales de la Amazonía").
- provider: the company/technology/vendor behind the case (e.g. "Starlink"). If not stated, use null.
- country: the country the case took place in.
- region: a finer-grained location within the country if mentioned (a province, state or named region) — null if not stated.
- sector: EXACTLY one of these codes based on what the case is mainly about — education, health, emergency_response, agriculture, government, financial_inclusion, other. Never invent a code outside this list.
- summary_es: a factual 2-5 sentence summary IN SPANISH of what the case is and what it achieved. Always fill this — write it yourself in Spanish even if the source document is in English.
- summary_en: the same summary IN ENGLISH. Always fill this too — translate it yourself if the source document is in Spanish.
- beneficiaries_count: a single integer if the document states (or lets you reasonably compute) a number of people/institutions/students/patients reached — null if no number is stated.
- metrics_es: an optional short IN SPANISH highlight of extra quantitative results or a direct notable quote from the document — null if there's nothing beyond the summary worth calling out separately.
- metrics_en: the English version of metrics_es — null if metrics_es is null.
- source_label: a short citation label for the document itself (e.g. "Starlink — Impacto en América Latina (2026)") if a title/author/date can be inferred — null otherwise.

If the document actually describes MULTIPLE distinct cases, extract only the FIRST/most prominent one — never merge several cases into one entry.

Respond with ONLY a single valid JSON object with exactly these keys: title, provider, country, region, sector, summary_es, summary_en, beneficiaries_count, metrics_es, metrics_en, source_label. Use null for any field you can't confidently fill — never fabricate a plausible-sounding value. No markdown code fences, no commentary.`;

function cleanText(v, cap) {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  return (!s || s.toLowerCase() === 'null' || s.toLowerCase() === 'n/a') ? null : s.slice(0, cap);
}

function cleanSector(v) {
  const s = cleanText(v, 40);
  return s && ALLOWED_SECTORS.includes(s) ? s : null;
}

function cleanInt(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = parseInt(v, 10);
  return Number.isFinite(n) && n >= 0 ? n : null;
}

function parseModelJson(rawText) {
  // Strip a leading <think>...</think> block — same reasoning-model guard
  // as api/analyze-project.js/api/extract-template-data.js.
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
  const { pdfBase64, fileName } = body || {};
  if (!pdfBase64) return json(res, 400, { error: 'pdfBase64 is required' });
  if (pdfBase64.length > MAX_BASE64_LENGTH) {
    return json(res, 400, { error: 'PDF too large. Please use a smaller file.' });
  }

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const user = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!user || !user.id) return json(res, 401, { error: 'Invalid session' });

    const role = await getProfileRole(user.id, { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
    if (role !== 'advisor' && role !== 'admin') {
      return json(res, 403, { error: 'Success Cases are restricted to advisor/admin users.' });
    }

    if (provider === 'bedrock-mock') {
      // No model call, no fabricated values for a data-entry feature (see
      // file header) — every field simply comes back null/not found.
      return json(res, 200, {
        ok: true,
        fields: { title: null, provider: null, country: null, region: null, sector: null, summary_es: null, summary_en: null, beneficiaries_count: null, metrics_es: null, metrics_en: null, source_label: null },
        documentUsed: null,
      });
    }

    let pdfBuffer;
    try {
      pdfBuffer = Buffer.from(pdfBase64, 'base64');
    } catch (e) {
      return json(res, 400, { error: 'Could not decode pdfBase64.' });
    }
    if (pdfBuffer.length > 25 * 1024 * 1024) {
      return json(res, 400, { error: 'PDF too large. Please use a smaller file.' });
    }

    // require('pdf-parse') deliberately lazy — see file header and
    // api/analyze-project.js's matching comment (pinned to 1.1.4, the pure-
    // JS line with no @napi-rs/canvas native dependency).
    let pdfParseFn = null;
    try {
      pdfParseFn = require('pdf-parse');
    } catch (loadErr) {
      return json(res, 500, { error: 'PDF text extraction is unavailable in this environment.' });
    }

    let extractedText = '';
    try {
      const extracted = await pdfParseFn(pdfBuffer);
      extractedText = (extracted.text || '').trim();
    } catch (e) {
      return json(res, 400, { error: "Couldn't parse this PDF." });
    }
    if (!extractedText) {
      return json(res, 400, { error: 'No extractable text found in this PDF — it may be a scanned image with no text layer.' });
    }

    const userContent = `SOURCE DOCUMENT${fileName ? ` (${fileName})` : ''}:\n${extractedText.slice(0, MAX_CHARS_FROM_PDF)}`;

    let rawText;
    if (provider === 'groq') {
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` },
        body: JSON.stringify({
          model: GROQ_MODEL || GROQ_MODEL_DEFAULT,
          max_tokens: 2000,
          temperature: 0,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        console.error(`[extract-success-case] Groq request failed (status ${groqRes.status}):`, errText);
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
          max_tokens: 2000,
          temperature: 0,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!localRes.ok) {
        const errText = await localRes.text().catch(() => '');
        console.error(`[extract-success-case] local model request failed (status ${localRes.status}):`, errText);
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
          system: [{ text: SYSTEM_PROMPT }],
          messages: [{ role: 'user', content: [{ text: userContent }] }],
          inferenceConfig: { maxTokens: 2000, temperature: 0 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
      } catch (bedrockErr) {
        console.error('[extract-success-case] Bedrock request failed:', bedrockErr);
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
          system: SYSTEM_PROMPT,
          messages: [{ role: 'user', content: userContent }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        console.error(`[extract-success-case] Anthropic request failed (status ${anthropicRes.status}):`, errText);
        return json(res, 502, { error: 'Extraction model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
    }

    let parsed;
    try {
      parsed = parseModelJson(rawText);
    } catch (e) {
      console.error('[extract-success-case] could not parse model output as JSON:', e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse extraction output', raw: rawText.slice(0, 2000) });
    }

    const fields = {
      title: cleanText(parsed.title, 300),
      provider: cleanText(parsed.provider, 150),
      country: cleanText(parsed.country, 150),
      region: cleanText(parsed.region, 150),
      sector: cleanSector(parsed.sector),
      summary_es: cleanText(parsed.summary_es, 2000),
      summary_en: cleanText(parsed.summary_en, 2000),
      beneficiaries_count: cleanInt(parsed.beneficiaries_count),
      metrics_es: cleanText(parsed.metrics_es, 1000),
      metrics_en: cleanText(parsed.metrics_en, 1000),
      source_label: cleanText(parsed.source_label, 300),
    };

    return json(res, 200, { ok: true, fields, documentUsed: fileName || null });
  } catch (err) {
    console.error('[extract-success-case] unhandled error:', err);
    return json(res, 500, { error: 'Extraction failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 45 };
