/**
 * INA Platform — /api/extract-business-card
 * Vercel serverless function (Node.js runtime, no external dependencies).
 *
 * Reads a business card photo (sent as base64 in the request body — the
 * card hasn't been uploaded to Storage yet at this point, uploading only
 * happens client-side AFTER the contact is saved, see
 * assets/platform.js's uploadContactBusinessCard()) and asks a vision model
 * to extract: full name, position/title, email, phone, and the name of the
 * company or public agency printed on the card (plus a best-effort guess
 * of which of those two it is). Used by app/master-data.html's "Upload
 * from business card" button (Contacts tab) to pre-fill the New Contact
 * form — Pablo always reviews/edits the pre-filled fields before hitting
 * Save, nothing is written to the database by this function itself (see
 * migration_v45_contact_business_card.sql's file header).
 *
 * TWO SUPPORTED PROVIDERS (set via LLM_PROVIDER, same switch used by
 * api/analyze-project.js and api/extract-template-data.js):
 *
 *   - LLM_PROVIDER='groq' (or unset GROQ_API_KEY-only setups) — uses Groq's
 *     free-tier cloud API with Llama 4 Scout (`meta-llama/llama-4-scout-
 *     17b-16e-instruct`), an open-weight Meta model that's natively
 *     multimodal (text + up to 5 images per request). Groq's free tier
 *     needs no credit card — see console.groq.com. This is the option to
 *     use if you want to test the whole platform's AI features, business
 *     cards included, without paying for API credits. Requires
 *     GROQ_API_KEY (same key already used for AI Analysis/Autocomplete on
 *     the groq path — nothing new to create if that's already set up).
 *     Uses a SEPARATE env var for the model, GROQ_VISION_MODEL, rather
 *     than reusing GROQ_MODEL — the model configured there for AI
 *     Analysis (`llama-3.3-70b-versatile` by default) is text-only and
 *     does not accept images.
 *   - Anything else (default 'anthropic', or bedrock/local/bedrock-mock
 *     left over from AI Analysis config) — uses Claude vision
 *     (ANTHROPIC_API_KEY). This was the only option before Groq added a
 *     vision-capable model to its free tier; kept as the default/fallback
 *     since it doesn't require picking a provider explicitly. The Bedrock
 *     Llama 3.3 model and a generic local model are NOT assumed to
 *     support vision, so LLM_PROVIDER='bedrock'/'local'/'bedrock-mock'
 *     still fall back to Anthropic here rather than silently failing or
 *     guessing wrong — set LLM_PROVIDER='groq' explicitly (it can differ
 *     from whatever AI Analysis uses) to get the free/open-source path
 *     instead.
 *
 * Required environment variables:
 *   Either GROQ_API_KEY (LLM_PROVIDER='groq') or ANTHROPIC_API_KEY
 *     (anything else) — see above. CLAUDE_MODEL / GROQ_VISION_MODEL are
 *     both optional overrides of the default model on each path.
 *   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY / SUPABASE_ANON_KEY — same
 *     three as api/analyze-project.js; used here only to verify the
 *     caller is signed in AND has the advisor/admin role (Master Data is
 *     gated to advisor/admin — see migration_v44's file header), via the
 *     service role key reading profiles.role server-side. Never used to
 *     write anything.
 */

const GROQ_VISION_MODEL_DEFAULT = 'meta-llama/llama-4-scout-17b-16e-instruct';

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

const ALLOWED_MEDIA_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
// Base64 is ~33% larger than the raw file; this caps the raw image at
// roughly 6MB, comfortably inside Vercel's request body limit and more
// than enough for a photographed business card.
const MAX_BASE64_LENGTH = 8 * 1024 * 1024;

const SYSTEM_PROMPT = `You are reading a photo of a business card (tarjeta de presentación) for INA (International Network Advisors)'s internal contact directory. Extract exactly these fields from the card:

- full_name: the person's full name.
- position_title: their job title / position (e.g. "Gerente de Infraestructura", "Director of Financing"). Not the company name.
- email: their email address, if printed.
- phone: their phone number, if printed (keep it as printed, don't reformat).
- org_name: the name of the company or public/government agency printed on the card (e.g. "Banco Interamericano de Desarrollo", "Telecom Argentina S.A.", "ENACOM"). Not the person's name or title.
- is_public_agency: true if org_name is a government body, regulator, ministry, or public/state agency; false if it's a private company. Best guess from the name/logo/context.

If a field isn't present on the card or you can't read it confidently, respond with null for that field — never guess or fabricate a value.

Respond with ONLY a single valid JSON object with exactly these keys: full_name, position_title, email, phone, org_name, is_public_agency. No markdown code fences, no commentary.`;

function cleanField(v) {
  if (v === null || v === undefined) return null;
  const s = String(v).trim();
  return (!s || s.toLowerCase() === 'null') ? null : s.slice(0, 300);
}

function parseModelJson(rawText) {
  const cleaned = (rawText || '').trim().replace(/^```json\s*/i, '').replace(/```$/, '');
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
    CLAUDE_MODEL,
    LLM_PROVIDER,
    GROQ_API_KEY,
    GROQ_VISION_MODEL,
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    SUPABASE_ANON_KEY,
  } = process.env;

  const provider = (LLM_PROVIDER || 'anthropic').toLowerCase() === 'groq' ? 'groq' : 'anthropic';
  const providerKeyMissing = provider === 'groq' ? !GROQ_API_KEY : !ANTHROPIC_API_KEY;

  if (providerKeyMissing || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY) {
    return json(res, 500, {
      error: provider === 'groq'
        ? 'Server misconfigured: missing GROQ_API_KEY (required when LLM_PROVIDER=groq — see file header) or Supabase environment variables.'
        : 'Server misconfigured: missing ANTHROPIC_API_KEY (required for this feature unless LLM_PROVIDER=groq — see file header) or Supabase environment variables.',
    });
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (e) {
    return json(res, 400, { error: 'Invalid JSON body' });
  }
  const { imageBase64, mediaType } = body || {};
  if (!imageBase64 || !mediaType) {
    return json(res, 400, { error: 'imageBase64 and mediaType are required' });
  }
  if (!ALLOWED_MEDIA_TYPES.includes(mediaType)) {
    return json(res, 400, { error: `Unsupported image type: ${mediaType}` });
  }
  if (imageBase64.length > MAX_BASE64_LENGTH) {
    return json(res, 400, { error: 'Image too large. Please use a smaller photo of the card.' });
  }

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const user = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!user || !user.id) return json(res, 401, { error: 'Invalid session' });

    const role = await getProfileRole(user.id, { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
    if (role !== 'advisor' && role !== 'admin') {
      return json(res, 403, { error: 'Master Data is restricted to advisor/admin users.' });
    }

    let rawText;
    if (provider === 'groq') {
      // OpenAI-compatible chat completions shape — image_url content block
      // with a data: URL, per Groq's vision docs (console.groq.com/docs/vision).
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` },
        body: JSON.stringify({
          model: GROQ_VISION_MODEL || GROQ_VISION_MODEL_DEFAULT,
          max_tokens: 500,
          temperature: 0,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            {
              role: 'user',
              content: [
                { type: 'text', text: 'Extract the contact info from this business card image, per the instructions.' },
                { type: 'image_url', image_url: { url: `data:${mediaType};base64,${imageBase64}` } },
              ],
            },
          ],
        }),
      });
      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        return json(res, 502, { error: 'Card reading request failed', detail: errText });
      }
      const groqData = await groqRes.json();
      rawText = (groqData.choices && groqData.choices[0] && groqData.choices[0].message && groqData.choices[0].message.content) || '';
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
          max_tokens: 500,
          temperature: 0,
          system: SYSTEM_PROMPT,
          messages: [{
            role: 'user',
            content: [
              { type: 'image', source: { type: 'base64', media_type: mediaType, data: imageBase64 } },
              { type: 'text', text: 'Extract the contact info from this business card image, per the instructions.' },
            ],
          }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        return json(res, 502, { error: 'Card reading request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
    }

    let parsed;
    try {
      parsed = parseModelJson(rawText);
    } catch (e) {
      return json(res, 502, { error: 'Could not parse card reading output', raw: rawText.slice(0, 1000) });
    }

    return json(res, 200, {
      ok: true,
      full_name: cleanField(parsed.full_name),
      position_title: cleanField(parsed.position_title),
      email: cleanField(parsed.email),
      phone: cleanField(parsed.phone),
      org_name: cleanField(parsed.org_name),
      is_public_agency: parsed.is_public_agency === true,
    });
  } catch (err) {
    return json(res, 500, { error: 'Card reading failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 30 };
