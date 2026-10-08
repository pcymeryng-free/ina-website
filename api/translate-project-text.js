/**
 * INA Platform — /api/translate-project-text
 * Vercel serverless function (Node.js runtime, no external dependencies).
 *
 * Pablo (oct 2026): "necesito que se traduzcan todos los textos ingresados
 * manualmente al idioma seleccionado. No quiero que en un reporte o en
 * pantalla haya mezcla de idiomas." Round 1 scope: app/project.html (every
 * tab) + its "Download PDF" export — see
 * supabase/migration_v72_bilingual_free_text.sql for the full field list
 * and the "translate once, cache the result" rationale this endpoint feeds.
 *
 * Takes a BATCH of {key, text} Spanish snippets (one call translates
 * everything a single project currently needs — description, each phase's
 * name/scope, each pending Datos Técnicos textarea answer — rather than one
 * model round-trip per field) and returns English translations keyed the
 * same way. Purely stateless — never reads or writes Supabase itself; the
 * caller (INAPlatform.ensureEnglishTranslations() in assets/platform.js)
 * owns deciding what to translate and where the result gets cached. Auth is
 * therefore just "reject anonymous callers" (no ownership/ RLS check needed,
 * since this endpoint never touches a specific project's data) — same
 * Bearer-token verifyUser() used by every other agent here.
 *
 * Same LLM_PROVIDER switch/credentials as every other agent (anthropic/
 * groq/bedrock/bedrock-mock/local — see api/analyze-project.js's file
 * header for what each env var does). Required environment variables: that
 * switch's per-provider credentials, plus SUPABASE_URL/SUPABASE_ANON_KEY
 * (session verification only — no SUPABASE_SERVICE_ROLE_KEY needed here,
 * unlike every other agent, since this one never touches the database).
 */

const GROQ_MODEL_DEFAULT = 'openai/gpt-oss-120b';
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

// Generous but bounded — a single project's in-scope free text (description,
// a handful of phases, a handful of Datos Técnicos textarea answers) is
// nowhere near this in practice; this is cheap insurance against a
// pathological/abusive request, same spirit as every other agent's MAX_*
// constants.
const MAX_ITEMS = 60;
const MAX_CHARS_PER_ITEM = 4000;
const MAX_TOTAL_CHARS = 40000;

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

// Same retry helper duplicated across every api/*.js that calls Groq — see
// api/extract-project-data.js's matching comment for the full rationale
// (shared account-wide tokens-per-minute budget, not a real failure).
async function fetchGroqWithRetry(body, headers) {
  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST', headers, body: JSON.stringify(body),
  });
  if (res.status !== 429) return res;
  const errBody = await res.clone().json().catch(() => null);
  if ((errBody && errBody.error && errBody.error.code) !== 'rate_limit_exceeded') return res;
  const match = /try again in ([\d.]+)s/i.exec((errBody.error && errBody.error.message) || '');
  const waitMs = Math.min(match ? Math.ceil(parseFloat(match[1]) * 1000) + 500 : 5000, 25000);
  console.warn(`[translate-project-text] Groq rate-limited, retrying once in ${waitMs}ms`);
  await new Promise((resolve) => setTimeout(resolve, waitMs));
  return fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST', headers, body: JSON.stringify(body),
  });
}

/* Same allowlist/CORS approach as every other agent — see
   api/analyze-project.js's comment for why this stays a small explicit
   list rather than '*'. */
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

// Per-agent hint (see migration_v71_agent_hints.sql / app/ai-hints.html) —
// a row of free text an admin can edit live from the platform, fetched
// fresh on every request. Unlike every other agent's copy of this helper,
// this one has no SUPABASE_SERVICE_ROLE_KEY to read with (this endpoint is
// otherwise fully stateless) — uses the anon key instead, which is enough
// since agent_hints' own RLS only gates WRITES to admins, not reads by any
// authenticated-looking request; a failed/unauthorized read just falls back
// to '' same as every other agent's try/catch already does.
async function getAgentHint(agentKey, { supabaseUrl, anonKey }) {
  try {
    const res = await fetch(
      `${supabaseUrl}/rest/v1/agent_hints?agent_key=eq.${agentKey}&select=hint_text`,
      { headers: { apikey: anonKey, Authorization: `Bearer ${anonKey}` } }
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
// rationale. This file has no SUPABASE_SERVICE_ROLE_KEY available (see
// file header — deliberately stateless), so unlike every other agent's
// copy of this helper, the debug_log insert here goes through with the
// CALLER's own access token (same RLS path assets/platform.js's client-
// side writeDebugLog() already uses: debug_log_insert_own checks
// auth.uid() = user_id) rather than the service-role key.
const AGENT_VERSION = '1.0';
async function isDebugModeOn({ supabaseUrl, anonKey }) {
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/app_settings?select=debug_mode&limit=1`, { headers: { apikey: anonKey } });
    if (!res.ok) return false;
    const rows = await res.json();
    return !!(rows[0] && rows[0].debug_mode);
  } catch (e) { return false; }
}
async function logDebugAgentCall({ supabaseUrl, anonKey, accessToken, userId, agentKey, provider, model, durationMs, usage, systemPrompt, userContent, rawResponse }) {
  try {
    await fetch(`${supabaseUrl}/rest/v1/debug_log`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', apikey: anonKey, Authorization: `Bearer ${accessToken}` },
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

const BASE_SYSTEM_PROMPT = `You are a professional translator for INA (International Network Advisors), translating content for formal digital-infrastructure/connectivity project documents (project descriptions, phase breakdowns, technical questionnaire answers) from Spanish into English.

You will be given a JSON object mapping arbitrary keys to Spanish text snippets. For EACH key, translate its text into natural, professional English suited to a formal investment/infrastructure document — accurate and faithful to the original meaning, not a literal word-for-word translation, preserving the original tone (technical, narrative, etc.) and any numbers/figures/proper nouns exactly as given (never translate a person's name, a company/organization name, or a product/brand name that appears inside the text — leave those exactly as written).

Respond with ONLY a single valid JSON object — no markdown code fences, no commentary — mapping each input key to its English translation (a string). Include every input key exactly once. If a given snippet is empty or already appears to be in English, return it unchanged.`;

function parseModelJson(rawText) {
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
  if (providerKeyMissing || !SUPABASE_URL || !SUPABASE_ANON_KEY) {
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
  const texts = Array.isArray(body && body.texts) ? body.texts.slice(0, MAX_ITEMS) : [];
  const items = texts
    .filter((t) => t && typeof t.key === 'string' && typeof t.text === 'string' && t.text.trim())
    .map((t) => ({ key: t.key, text: t.text.trim().slice(0, MAX_CHARS_PER_ITEM) }));
  if (!items.length) return json(res, 400, { error: 'texts (array of {key, text}) is required' });

  let runningTotal = 0;
  const batch = [];
  for (const item of items) {
    if (runningTotal + item.text.length > MAX_TOTAL_CHARS) break;
    runningTotal += item.text.length;
    batch.push(item);
  }

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const extraHints = await getAgentHint('translate-project-text', { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    const user = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!user || !user.id) return json(res, 401, { error: 'Invalid session' });
    const debugOn = await isDebugModeOn({ supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });

    if (provider === 'bedrock-mock') {
      // No model call — every key just echoes its Spanish input back
      // untranslated, same "no fabricated values" spirit as every other
      // agent's bedrock-mock branch.
      const translations = {};
      batch.forEach((item) => { translations[item.key] = item.text; });
      return json(res, 200, { ok: true, translations });
    }

    const systemPrompt = BASE_SYSTEM_PROMPT + hintsSuffix(extraHints);
    const inputObj = {};
    batch.forEach((item) => { inputObj[item.key] = item.text; });
    const userContent = JSON.stringify(inputObj);

    let rawText;
    const _debugStart = Date.now();
    let _debugModel = null;
    let _debugUsage = null;
    if (provider === 'groq') {
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
        console.error(`[translate-project-text] Groq request failed (status ${groqRes.status}):`, errText);
        return json(res, 502, { error: 'Translation model request failed', detail: errText });
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
        console.error(`[translate-project-text] local model request failed (status ${localRes.status}):`, errText);
        return json(res, 502, { error: 'Translation model request failed (local model)', detail: errText });
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
        console.error('[translate-project-text] Bedrock request failed:', bedrockErr);
        return json(res, 502, {
          error: 'Translation model request failed',
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
        console.error(`[translate-project-text] Anthropic request failed (status ${anthropicRes.status}):`, errText);
        return json(res, 502, { error: 'Translation model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
      _debugModel = CLAUDE_MODEL || 'claude-sonnet-5';
      _debugUsage = anthropicData.usage;
    }

    if (debugOn) {
      await logDebugAgentCall({
        supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY, accessToken, userId: user.id,
        agentKey: 'translate-project-text', provider, model: _debugModel,
        durationMs: Date.now() - _debugStart, usage: _debugUsage,
        systemPrompt, userContent, rawResponse: rawText,
      });
    }

    let parsed;
    try {
      parsed = parseModelJson(rawText);
    } catch (e) {
      console.error('[translate-project-text] could not parse model output as JSON:', e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse translation output', raw: rawText.slice(0, 2000) });
    }

    const translations = {};
    batch.forEach((item) => {
      const value = parsed[item.key];
      translations[item.key] = typeof value === 'string' && value.trim() ? value.trim() : item.text;
    });

    return json(res, 200, { ok: true, translations });
  } catch (err) {
    console.error('[translate-project-text] unhandled error:', err);
    return json(res, 500, { error: 'Translation failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 60 };
