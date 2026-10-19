/**
 * INA Platform — /api/update-news
 * Vercel serverless function, triggered once a day by Vercel Cron (see
 * vercel.json's "crons" entry) — NOT called from any browser page. Builds
 * the public news.html feed (Pablo, oct 2026: "agregarle al sitio una
 * pagina de noticias relevantes del mercado de las telecomunicaciones...
 * que todos los dias se actualice", "con el filtro de IA"):
 *
 *   1. Fetch a curated list of Argentina + international telecom/digital-
 *      infrastructure RSS feeds (FEEDS below).
 *   2. Drop anything older than CANDIDATE_WINDOW_DAYS, and anything whose
 *      link is already in public.market_news (so a feed's rolling backlog
 *      never gets re-curated, and never costs a second model call, once
 *      it's already been seen on an earlier run).
 *   3. Ask the configured LLM provider to keep only what's genuinely
 *      relevant to the sector, and write a bilingual (ES/EN) title +
 *      one-sentence summary + category for each kept item — same filter
 *      step Pablo asked for, rather than dumping the raw feeds as-is.
 *   4. Insert the result into public.market_news with the SERVICE ROLE key
 *      (see supabase/migration_v75_market_news.sql — that table has no
 *      anon/authenticated write policy at all, only public read).
 *
 * Auth: a single shared secret, NOT a per-user Supabase session (there's no
 * user initiating this — it's cron-triggered). Vercel automatically sends
 * `Authorization: Bearer $CRON_SECRET` on every Cron invocation once the
 * CRON_SECRET env var is set (https://vercel.com/docs/cron-jobs/manage-cron-jobs#securing-cron-jobs)
 * — set CRON_SECRET in the Vercel project's env vars and nothing else is
 * needed for the schedule to authenticate itself. The same header also
 * lets you trigger a run manually (`curl -X POST .../api/update-news -H
 * "Authorization: Bearer $CRON_SECRET"`) to test or force a refresh.
 *
 * Required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 * SUPABASE_ANON_KEY (for the debug-mode check only), CRON_SECRET, plus the
 * SAME LLM_PROVIDER switch and per-provider credentials every other AI
 * endpoint already uses — see api/analyze-project.js's file header for
 * what each one does.
 *
 * FEEDS below is a first pass, not a verified-forever list — RSS feed
 * paths do move when a publisher redesigns its site. A feed that starts
 * 404ing or returning empty just gets silently skipped for that run (see
 * fetchFeed()'s try/catch) rather than failing the whole job, but it's
 * still worth spot-checking this list every so often (the easiest check:
 * app/debug-log.html with debug mode on, or just read market_news for a
 * sudden drop in rows from one source_name).
 */

const Parser = require('rss-parser');

// Deliberately NOT 'openai/gpt-oss-120b' (every other endpoint's Groq
// default) — that's a reasoning model, and its hidden chain-of-thought
// counts against the same max_tokens budget as the visible answer. Third
// production run (MODEL_MAX_TOKENS=3000) came back with a genuinely empty
// message.content: reasoning alone consumed the whole budget, leaving
// nothing for the actual JSON. Curating/translating/categorizing a list
// of short news items doesn't need that reasoning depth — a fast,
// non-reasoning model has no hidden-thinking tax at all, so the full
// token budget goes straight to the answer. Only applies to this file;
// GROQ_MODEL (if ever set) stays the shared default for every other
// endpoint, deliberately not read here.
const GROQ_MODEL_DEFAULT = 'llama-3.1-8b-instant';
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

// How far back a feed item can be and still be considered "new" — a feed
// that's been down for a few days shouldn't dump a week of backlog once it
// comes back, but this is generous enough that a once-daily cron run never
// misses something published since yesterday's run.
const CANDIDATE_WINDOW_DAYS = 3;
// Hard cap on how many candidates go INTO the model call (prompt-size/cost
// guard — see MAX_DESC_CHARS_PER_PROGRAM's identical reasoning in
// api/recommend-financing.js), and on how many curated items it may KEEP.
// Kept deliberately small: Groq's free "on_demand" tier (the production
// LLM_PROVIDER as of oct 2026) caps a single request at 8000 tokens/minute
// — a first run at 70 candidates × up to 500-char snippets came out to
// ~9300 requested tokens and 502'd outright ("Request too large... Limit
// 8000, Requested 9343"). 45 candidates × a 200-char snippet (see
// fetchFeed() below) comes out to roughly half that, with headroom for a
// heavier news day.
const MAX_CANDIDATES = 45;
// A non-reasoning model (see GROQ_MODEL_DEFAULT above) writes its answer
// directly with no hidden-thinking tax, so 3000 tokens is comfortable
// headroom for up to 15 short bilingual items — not a tight limit like
// MAX_CANDIDATES above, just a sane ceiling.
const MAX_KEPT = 15;
const MODEL_MAX_TOKENS = 3000;
const FEED_FETCH_TIMEOUT_MS = 10000;

// Argentina-market feeds, then international — `scope` is the default
// public.market_news.country_scope for anything from that feed; the model
// is told it may override it (buildSystemPrompt() below) for the rare item
// that's actually about the other scope (e.g. an international outlet
// covering an ENACOM decision).
const FEEDS = [
  { url: 'https://www.telesemana.com/feed/', sourceName: 'TeleSemana', scope: 'argentina' },
  { url: 'https://www.iprofesional.com/rss/tecnologia', sourceName: 'iProfesional - Tecnología', scope: 'argentina' },
  // General-interest tech, not telecom-specific — included anyway because
  // it's a high-volume, reliable Argentina feed and the AI filter step
  // (buildSystemPrompt() below) is exactly what's supposed to pick the
  // genuinely relevant handful out of everything else.
  { url: 'https://www.infobae.com/arc/outboundfeeds/rss/category/tecno/?outputType=xml', sourceName: 'Infobae - Tecno', scope: 'argentina' },
  { url: 'https://www.lightreading.com/rss.xml', sourceName: 'Light Reading', scope: 'international' },
  { url: 'https://www.capacitymedia.com/rss', sourceName: 'Capacity Media', scope: 'international' },
  { url: 'https://www.rcrwireless.com/feed', sourceName: 'RCR Wireless News', scope: 'international' },
];

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

// "Today" in Argentina local time, not the server's (Vercel runs in UTC) —
// a run just after midnight UTC (21:00 ART the day before) would otherwise
// file items under tomorrow's date from an Argentine reader's point of
// view. Matches the YYYY-MM-DD shape a Postgres `date` column expects.
function argentinaDateString(date) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'America/Argentina/Buenos_Aires', year: 'numeric', month: '2-digit', day: '2-digit',
  }).formatToParts(date);
  const get = (type) => parts.find((p) => p.type === type).value;
  return `${get('year')}-${get('month')}-${get('day')}`;
}
function argentinaTodayDate() {
  return argentinaDateString(new Date());
}

// A handful of feeds in the wild emit a bare, unescaped `&` (should be
// `&amp;`) — invalid XML that otherwise makes the whole feed unparseable.
// Cheap to fix generically: escape any `&` not already starting a real
// entity reference, before handing the XML to the parser.
function sanitizeXmlEntities(xml) {
  return xml.replace(/&(?!amp;|lt;|gt;|quot;|apos;|#\d+;|#x[0-9a-fA-F]+;)/g, '&amp;');
}

async function fetchFeed(feed, parser) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FEED_FETCH_TIMEOUT_MS);
  try {
    // rss-parser has no built-in timeout/fetch-options support in its
    // parseURL() — fetch the body ourselves (with the abort signal) and
    // hand the raw XML to parseString() instead.
    const res = await fetch(feed.url, { signal: controller.signal, headers: { 'User-Agent': 'INA-Platform-NewsBot/1.0' } });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const xml = await res.text();
    const parsed = await parser.parseString(sanitizeXmlEntities(xml));
    return (parsed.items || []).map((item) => ({
      title: (item.title || '').trim(),
      link: (item.link || '').trim(),
      publishedAt: item.isoDate || item.pubDate || null,
      snippet: (item.contentSnippet || item.content || item.summary || '').trim().slice(0, 200),
      sourceName: feed.sourceName,
      scope: feed.scope,
    })).filter((item) => item.title && item.link);
  } catch (e) {
    console.warn(`[update-news] feed failed, skipping (${feed.sourceName}):`, e && e.message ? e.message : e);
    return [];
  } finally {
    clearTimeout(timeout);
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

// Admin-only debug mode (migration_v74_debug_mode.sql / app/debug-log.html)
// — same pattern every other AI endpoint uses, duplicated here per this
// codebase's usual convention (no shared module bundling between these
// standalone Vercel functions). user_id is null throughout this file —
// unlike every other agent, there's no human initiating this call.
async function isDebugModeOn({ supabaseUrl, anonKey }) {
  try {
    const res = await fetch(`${supabaseUrl}/rest/v1/app_settings?select=debug_mode&limit=1`, { headers: { apikey: anonKey } });
    if (!res.ok) return false;
    const rows = await res.json();
    return !!(rows[0] && rows[0].debug_mode);
  } catch (e) { return false; }
}
async function logDebugAgentCall({ supabaseUrl, serviceKey, provider, model, durationMs, usage, systemPrompt, userContent, rawResponse }) {
  try {
    await fetch(`${supabaseUrl}/rest/v1/debug_log`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
      body: JSON.stringify({
        log_type: 'ai_agent',
        user_id: null,
        agent_key: 'update-news',
        agent_version: '1.0',
        provider,
        model,
        duration_ms: durationMs,
        prompt_tokens: (usage && (usage.prompt_tokens ?? usage.input_tokens ?? usage.inputTokens)) ?? null,
        completion_tokens: (usage && (usage.completion_tokens ?? usage.output_tokens ?? usage.outputTokens)) ?? null,
        total_tokens: (usage && (usage.total_tokens ?? usage.totalTokens ?? (((usage.input_tokens ?? usage.inputTokens) || 0) + ((usage.output_tokens ?? usage.outputTokens) || 0)))) ?? null,
        details: { systemPrompt, userContent, usage, rawResponse },
      }),
    });
  } catch (e) { /* swallow — see every other endpoint's matching comment */ }
}

function buildSystemPrompt() {
  return `You are a news curator for INA (International Network Advisors), a digital-infrastructure advisory firm. You will be given a JSON array of recent candidate news items (title, link, source, a short snippet, and a default scope of "argentina" or "international"), pulled automatically from RSS feeds — many will be irrelevant noise (unrelated consumer tech, gadget reviews, generic business news with no telecom/infrastructure angle).

Your task: select ONLY the items genuinely relevant to the telecommunications / digital-infrastructure sector — spectrum and regulatory decisions, fiber/mobile/5G network deployment, submarine cables, datacenters and AI infrastructure, satellite connectivity, universal-service/public funding programs, infrastructure financing and M&A, major operator or equipment-vendor news. When in doubt, lean toward excluding rather than keeping — a shorter, genuinely relevant list is better than a padded one.

For each item you keep, write:
- title_es / title_en: a clear, concise headline (can closely follow the original title, translated/tightened as needed — not necessarily a verbatim translation).
- summary_es / summary_en: ONE concise sentence capturing what happened and why it matters to this sector, not a generic restatement of the headline. Keep it short — this is a feed item, not an article.
- category: a short tag, one of: "Regulación", "Infraestructura", "Financiamiento", "Satelital", "Datacenters/IA", "5G/Espectro", "Cable submarino", "M&A", "Otro".
- country_scope: "argentina" or "international" — normally just echo the item's given default scope, but override it if the content is clearly about the other one (e.g. an international outlet reporting specifically on an ENACOM decision is "argentina").

Keep at most ${MAX_KEPT} items, ordered by relevance/importance (most important first). Respond with ONLY a single valid JSON object — no markdown code fences, no commentary — in this exact shape:
{
  "items": [
    { "link": "<exact link from the candidate list>", "title_es": "...", "title_en": "...", "summary_es": "...", "summary_en": "...", "category": "...", "country_scope": "argentina" | "international" }
  ]
}`;
}

async function fetchGroqWithRetry(body, headers) {
  const res = await fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST', headers, body: JSON.stringify(body),
  });
  if (res.status !== 429) return res;
  const errBody = await res.clone().json().catch(() => null);
  if ((errBody && errBody.error && errBody.error.code) !== 'rate_limit_exceeded') return res;
  const match = /try again in ([\d.]+)s/i.exec((errBody.error && errBody.error.message) || '');
  const waitMs = Math.min(match ? Math.ceil(parseFloat(match[1]) * 1000) + 500 : 5000, 25000);
  console.warn(`[update-news] Groq rate-limited, retrying once in ${waitMs}ms`);
  await new Promise((resolve) => setTimeout(resolve, waitMs));
  return fetch('https://api.groq.com/openai/v1/chat/completions', {
    method: 'POST', headers, body: JSON.stringify(body),
  });
}

async function handler(req, res) {
  if (req.method === 'OPTIONS') { res.status(204).end(); return; }
  if (req.method !== 'GET' && req.method !== 'POST') {
    return json(res, 405, { error: 'Method not allowed' });
  }

  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  const {
    CRON_SECRET,
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

  if (!CRON_SECRET || token !== CRON_SECRET) {
    return json(res, 401, { error: 'Unauthorized' });
  }

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

  try {
    const parser = new Parser({ timeout: FEED_FETCH_TIMEOUT_MS });
    const feedResults = await Promise.all(FEEDS.map((f) => fetchFeed(f, parser)));
    const allItems = feedResults.flat();

    const cutoff = Date.now() - CANDIDATE_WINDOW_DAYS * 24 * 60 * 60 * 1000;
    const recentItems = allItems.filter((it) => {
      if (!it.publishedAt) return true; // no date on the item — keep it rather than silently drop it
      const t = new Date(it.publishedAt).getTime();
      return Number.isNaN(t) || t >= cutoff;
    });

    // Dedup against links already stored (checked BEFORE the model call so
    // an already-seen item never costs a second curation pass). Pulls every
    // source_url from the last CANDIDATE_WINDOW_DAYS+7 days rather than
    // filtering by the exact candidate links themselves — building a
    // PostgREST `or=`/`in.()` filter out of ~dozens of arbitrary article
    // URLs (commas, parens and quotes in a query string, any one of which
    // could appear in a URL) is needlessly fragile compared to just
    // fetching a bounded recent window and checking membership in JS.
    const dedupCutoff = argentinaDateString(new Date(Date.now() - (CANDIDATE_WINDOW_DAYS + 7) * 24 * 60 * 60 * 1000));
    const existingRows = await supabaseRest(`/market_news?select=source_url&published_date=gte.${dedupCutoff}`, {
      serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
    });
    const existingLinks = new Set((existingRows || []).map((r) => r.source_url));
    const freshItems = recentItems.filter((it) => !existingLinks.has(it.link));

    // De-dupe by link within this run too (a story can appear in more than
    // one feed) before capping to MAX_CANDIDATES — most-recent-first so the
    // cap drops the oldest rather than an arbitrary slice.
    const seen = new Set();
    const candidates = [];
    freshItems
      .sort((a, b) => new Date(b.publishedAt || 0) - new Date(a.publishedAt || 0))
      .forEach((it) => {
        if (seen.has(it.link)) return;
        seen.add(it.link);
        candidates.push(it);
      });
    const capped = candidates.slice(0, MAX_CANDIDATES);

    if (!capped.length) {
      return json(res, 200, { ok: true, feeds: FEEDS.length, candidates: 0, inserted: 0, message: 'Nothing new to curate.' });
    }

    const candidatesByLink = new Map(capped.map((it) => [it.link, it]));
    const systemPrompt = buildSystemPrompt();
    const userContent = JSON.stringify(capped.map((it) => ({
      link: it.link, title: it.title, source: it.sourceName, scope: it.scope, snippet: it.snippet,
    })));

    let rawText;
    const _debugStart = Date.now();
    let _debugModel = null;
    let _debugUsage = null;
    if (provider === 'bedrock-mock') {
      // Simulated result — no model call, no external cost — same spirit as
      // api/analyze-project.js's bedrock-mock branch: keeps the first few
      // candidates verbatim, labeled SIMULATED, so a dry run still exercises
      // the dedup/insert path end to end.
      const top = capped.slice(0, Math.min(5, capped.length));
      rawText = JSON.stringify({
        items: top.map((it) => ({
          link: it.link,
          title_es: `[SIMULADO] ${it.title}`,
          title_en: `[SIMULATED] ${it.title}`,
          summary_es: '[SIMULADO] Resumen de ejemplo, sin llamada a un modelo real.',
          summary_en: '[SIMULATED] Example summary, no real model call made.',
          category: 'Otro',
          country_scope: it.scope,
        })),
      });
    } else if (provider === 'groq') {
      const groqRes = await fetchGroqWithRetry({
        model: GROQ_MODEL_DEFAULT,
        max_tokens: MODEL_MAX_TOKENS,
        temperature: 0,
        messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userContent }],
      }, { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` });
      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        console.error(`[update-news] Groq request failed (status ${groqRes.status}):`, errText);
        return json(res, 502, { error: 'Curation model request failed', detail: errText });
      }
      const groqData = await groqRes.json();
      rawText = (groqData.choices && groqData.choices[0] && groqData.choices[0].message && groqData.choices[0].message.content) || '';
      _debugModel = GROQ_MODEL_DEFAULT;
      _debugUsage = groqData.usage;
    } else if (provider === 'local') {
      const localRes = await fetch(`${(LOCAL_LLM_BASE_URL || LOCAL_LLM_BASE_URL_DEFAULT).replace(/\/$/, '')}/chat/completions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...(LOCAL_LLM_API_KEY ? { Authorization: `Bearer ${LOCAL_LLM_API_KEY}` } : {}) },
        body: JSON.stringify({
          model: LOCAL_LLM_MODEL, max_tokens: MODEL_MAX_TOKENS, temperature: 0,
          messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userContent }],
        }),
      });
      if (!localRes.ok) {
        const errText = await localRes.text().catch(() => '');
        console.error(`[update-news] local model request failed (status ${localRes.status}):`, errText);
        return json(res, 502, { error: 'Curation model request failed (local model)', detail: errText });
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
          inferenceConfig: { maxTokens: MODEL_MAX_TOKENS, temperature: 0 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
        _debugModel = BEDROCK_MODEL_ID || BEDROCK_MODEL_DEFAULT;
        _debugUsage = bedrockRes.usage;
      } catch (bedrockErr) {
        console.error('[update-news] Bedrock request failed:', bedrockErr);
        return json(res, 502, { error: 'Curation model request failed', detail: String((bedrockErr && bedrockErr.message) || bedrockErr) });
      }
    } else {
      const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
        body: JSON.stringify({
          model: CLAUDE_MODEL || 'claude-sonnet-5',
          max_tokens: MODEL_MAX_TOKENS,
          temperature: 0,
          system: systemPrompt,
          messages: [{ role: 'user', content: userContent }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        console.error(`[update-news] Anthropic request failed (status ${anthropicRes.status}):`, errText);
        return json(res, 502, { error: 'Curation model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
      _debugModel = CLAUDE_MODEL || 'claude-sonnet-5';
      _debugUsage = anthropicData.usage;
    }

    const debugOn = await isDebugModeOn({ supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (debugOn) {
      await logDebugAgentCall({
        supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY,
        provider, model: _debugModel, durationMs: Date.now() - _debugStart, usage: _debugUsage,
        systemPrompt, userContent, rawResponse: rawText,
      });
    }

    let parsed;
    try {
      // Same defensive parsing as every other AI endpoint here (see
      // api/extract-template-data.js's comment + PLATFORM_SETUP.md's
      // "Could not parse extraction output" fix for why all three steps
      // are needed): strip a leading <think> block, strip a code fence,
      // then slice to the outer {...}.
      const withoutThink = rawText.replace(/^\s*<think>[\s\S]*?<\/think>\s*/i, '');
      let cleaned = withoutThink.trim().replace(/^```json\s*/i, '').replace(/```$/, '').trim();
      const firstBrace = cleaned.indexOf('{');
      const lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace !== -1 && lastBrace > firstBrace) cleaned = cleaned.slice(firstBrace, lastBrace + 1);
      parsed = JSON.parse(cleaned);
    } catch (e) {
      console.error('[update-news] could not parse model output as JSON:', e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse curation output', raw: rawText.slice(0, 2000) });
    }

    // Never trust the model's title/source/scope for a link it didn't
    // actually see — resolve every kept item against the real candidate
    // map (same "only the id is trusted, everything else is re-derived"
    // discipline as api/recommend-financing.js). A link that doesn't match
    // any candidate (a hallucinated/altered one) is silently dropped.
    const publishedDate = argentinaTodayDate();
    const rawItems = Array.isArray(parsed.items) ? parsed.items : [];
    const rows = [];
    const usedLinks = new Set();
    rawItems.slice(0, MAX_KEPT).forEach((it) => {
      const candidate = it && candidatesByLink.get(it.link);
      if (!candidate || usedLinks.has(it.link)) return;
      usedLinks.add(it.link);
      const scope = (it.country_scope === 'argentina' || it.country_scope === 'international') ? it.country_scope : candidate.scope;
      rows.push({
        published_date: publishedDate,
        title: String(it.title_es || candidate.title).slice(0, 300),
        title_en: String(it.title_en || it.title_es || candidate.title).slice(0, 300),
        summary: String(it.summary_es || '').slice(0, 1000),
        summary_en: String(it.summary_en || it.summary_es || '').slice(0, 1000),
        source_name: candidate.sourceName,
        source_url: candidate.link,
        country_scope: scope,
        category: it.category ? String(it.category).slice(0, 60) : null,
      });
    });

    let inserted = [];
    if (rows.length) {
      inserted = await supabaseRest('/market_news', {
        method: 'POST', body: rows, serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
      }) || [];
    }

    return json(res, 200, {
      ok: true,
      feeds: FEEDS.length,
      candidates: capped.length,
      kept: rows.length,
      inserted: inserted.length,
      published_date: publishedDate,
    });
  } catch (err) {
    console.error('[update-news] unhandled error:', err);
    return json(res, 500, { error: 'News update failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
