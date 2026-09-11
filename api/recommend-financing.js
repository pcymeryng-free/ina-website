/**
 * INA Platform — /api/recommend-financing
 * Vercel serverless function (Node.js runtime, no external dependencies for
 * the request/response path itself — same lazy-require pattern as
 * api/analyze-project.js/api/extract-template-data.js for provider-specific
 * SDKs).
 *
 * Given a project, asks the configured LLM provider to pick the best
 * COMBINATION of financing instruments/Programs already registered on the
 * platform (public.programs — BID, DFC, FSU/TASU/FATIC/CIP/Emergencias/
 * USTDA/Capital Markets/Red Mayorista Neutral/etc., the full catalog) for
 * that specific project, and writes the result to
 * public.financing_recommendations (one row per project, overwritten on
 * every re-run — see migration_v55_financing_recommendations.sql). Unlike
 * api/extract-template-data.js, this function DOES write to Supabase
 * (there's no client-side write path for this feature — the whole point is
 * a persisted, dashboard-visible recommendation, not a one-off in-memory
 * result like the autofill feature).
 *
 * Required environment variables: same three Supabase vars as
 * api/analyze-project.js (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 * SUPABASE_ANON_KEY), plus the SAME LLM_PROVIDER switch and per-provider
 * credentials (ANTHROPIC_API_KEY / GROQ_API_KEY / AWS_* / BEDROCK_MODEL_ID /
 * LOCAL_LLM_BASE_URL / LOCAL_LLM_MODEL / LOCAL_LLM_API_KEY — see
 * api/analyze-project.js's file header for what each does) — no new env
 * vars to set up here if AI Analysis is already configured.
 *
 * Deliberately does NOT read attached documents (unlike
 * api/extract-template-data.js) — the recommendation is based on the
 * project's own structured attributes (type, budget, country, financing
 * mix already entered, etc.) plus the Programs catalog, both already in the
 * database, so there's no PDF-parsing cost/latency/failure-mode to carry
 * here at all.
 */

const GROQ_MODEL_DEFAULT = 'openai/gpt-oss-120b';
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

// Programs catalog + project profile both go in the prompt every call, so
// cap how much of each Program's free-text description gets sent — the
// financing_recommendations descriptions written for BID/DFC alone run
// several paragraphs each, and with 20-40+ Programs in the catalog an
// uncapped dump would be an easy way to blow past a reasonable prompt size.
// A few hundred characters is enough for the model to judge fit (mechanism,
// eligible types, key terms) without the full legal-style prose.
const MAX_DESC_CHARS_PER_PROGRAM = 500;
const MAX_RECOMMENDED = 6;

// Same lesson learned as api/extract-template-data.js's "Could not parse
// extraction output" bug (see PLATFORM_SETUP.md): a catalog of 20-40
// Programs plus bilingual rationale for up to MAX_RECOMMENDED of them is a
// genuinely large JSON response, so this starts at a generous ceiling
// rather than the 2000 default that caused that earlier bug.
const MODEL_MAX_TOKENS = 6000;

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

/* Same allowlist/CORS approach as the other endpoints — see
   api/analyze-project.js's comment for why this stays a small explicit list
   rather than '*'. */
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

function buildProgramsCatalog(programs) {
  return (programs || []).map((p) => ({
    id: p.id,
    name: p.name,
    financing_entity: p.financing_entity || null,
    funding_stage: p.funding_stage, // 'preparation' | 'financing'
    types: p.types || [],
    description_excerpt: (p.description || '').slice(0, MAX_DESC_CHARS_PER_PROGRAM),
  }));
}

// Same rule as INAPlatform.isFsuFinancingEntity() in assets/platform.js —
// kept duplicated here (this file can't import a browser-oriented module)
// rather than factored out, same tradeoff already accepted for the
// <think>-strip/code-fence-strip JSON parsing logic shared with
// api/extract-template-data.js.
function isFsuFinancingEntity(value) {
  return !!value && String(value).trim().toLowerCase() === 'enacom-fsu';
}

// Re-implementation, in plain Node, of INAPlatform.computeFinancingCoverage()
// (assets/platform.js) — same inputs/outputs/arithmetic, including the FSU
// double-counting fix (an FSU-linked Program's own saved share, once any
// exists, supersedes the project's direct fsu_percentage/fsu_amount fields
// rather than adding on top of them). Needed here because the model has to
// be told the project's ACTUAL current financing coverage (not just a
// yes/no "has FSU" flag) to avoid recommending instruments that duplicate
// money already secured — see Pablo's bug report (Sep 2026) that the
// recommendation ignored FSU + already-loaded financing entirely.
function computeFinancingCoverage(project, projectPrograms) {
  const budget = project && project.budget_amount != null ? Number(project.budget_amount) : null;
  const pctOf = (amount) => (budget && budget > 0 && amount != null ? Math.round((Number(amount) / budget) * 100) : null);
  const effectivePct = (explicitPct, amount) => {
    if (explicitPct != null) return Number(explicitPct);
    const derived = pctOf(amount);
    return derived != null ? derived : 0;
  };

  const otherPct = project ? effectivePct(project.other_financing_percentage, project.other_financing_amount) : 0;
  const programShares = (projectPrograms || [])
    .filter((row) => row.programs && row.programs.funding_stage !== 'preparation' && (row.financing_percentage != null || row.financing_amount != null))
    .map((row) => ({
      program_id: row.program_id,
      name: row.programs.name,
      financing_entity: row.programs.financing_entity || null,
      pct: effectivePct(row.financing_percentage, row.financing_amount),
      isFsu: isFsuFinancingEntity(row.programs.financing_entity),
    }));
  const fsuProgramShares = programShares.filter((s) => s.isFsu);
  const fsuProgramsPct = fsuProgramShares.reduce((sum, s) => sum + s.pct, 0);
  const fsuPct = fsuProgramShares.length
    ? fsuProgramsPct
    : (project ? effectivePct(project.fsu_percentage, project.fsu_amount) : 0);
  const programsPct = programShares.reduce((sum, s) => sum + (s.isFsu ? 0 : s.pct), 0);
  return {
    fsuPct,
    otherPct,
    programShares,
    programsPct,
    totalPct: fsuPct + otherPct + programsPct,
  };
}

function buildProjectProfile(project, coverage, appliedProgramsDetail) {
  return {
    project_type: project.project_type,
    country: project.country,
    description_excerpt: (project.description || '').slice(0, 800),
    budget_amount_ars: project.budget_amount,
    budget_amount_usd: project.budget_amount_usd,
    duration: project.duration_value ? `${project.duration_value} ${project.duration_unit || ''}`.trim() : null,
    priority: project.priority,
    technical_criticality: project.technical_criticality,
    complexity: project.complexity,
    beneficiary_count: project.beneficiary_count,
    readiness_stage: project.readiness_stage || 'Not Analyzed',
    generating_entity_type: project.generating_entity_type,

    // Current financing coverage — the model must account for this instead
    // of treating the project as if no financing existed yet (Pablo's bug
    // report). Percent figures come from INAPlatform.computeFinancingCoverage's
    // server-side twin above: they already resolve the "% vs. absolute
    // amount" and "FSU direct field vs. FSU-linked Program share" precedence
    // rules, so these numbers are ready to reason with as-is.
    fsu_coverage_percent: coverage.fsuPct || 0,
    fsu_scope: project.fsu_scope || null,
    other_financing_coverage_percent: coverage.otherPct || 0,
    other_financing_notes: project.other_financing_notes || null,
    programs_coverage_percent: coverage.programsPct || 0,
    total_coverage_percent: coverage.totalPct || 0,
    remaining_financing_gap_percent: Math.max(0, 100 - (coverage.totalPct || 0)),

    // Every Program already applied to (financing-stage AND preparation-
    // stage), with its own saved share if one was entered, so the model can
    // see not just "financing already applied" but WHAT and HOW MUCH.
    financing_already_applied: appliedProgramsDetail,
    financing_already_applied_program_ids: appliedProgramsDetail.map((r) => r.program_id),
  };
}

function buildSystemPrompt() {
  return `You are a financing-structuring advisor for INA (International Network Advisors), helping ENACOM Argentina and digital-infrastructure project sponsors pick the best combination of financing instruments for a specific project.

You will be given: (1) a project's profile (type, country, budget, stage, financing already secured, etc.), and (2) the full catalog of financing/preparation Programs currently registered on the platform (multilateral development banks like BID and DFC, Argentina's own Fondo de Servicio Universal lines like TASU/FATIC/CIP/Emergencias/Red Mayorista Neutral, USTDA preparation grants, capital markets debt, etc.).

Your task: recommend the best COMBINATION of these registered Programs for this project — not just the single best one. A good combination often mixes instrument TYPES that serve different purposes (e.g. a preparation/feasibility-study grant now, PLUS a financing instrument for later; or a debt instrument PLUS a political-risk-insurance/guarantee instrument that makes that same debt cheaper/safer, since insurance and guarantee instruments don't compete with financing instruments — they de-risk them).

CRITICAL — account for financing already secured:
The project profile includes fsu_coverage_percent, other_financing_coverage_percent, programs_coverage_percent, total_coverage_percent, remaining_financing_gap_percent, and a financing_already_applied list (each with name, financing_entity, funding_stage, and its own financing_percentage/financing_amount already loaded on the project). Do NOT treat this project as if it had no financing yet:
- If total_coverage_percent is already high (e.g. 80%+) and remaining_financing_gap_percent is small, your recommendations and summary must reflect that most of the budget is already covered — recommend at most complementary/risk-mitigation instruments for the remaining gap, or explicitly say in the summary that the current mix is close to fully covering the budget and no major additional instrument is needed.
- If an FSU-linked instrument (fsu_coverage_percent > 0, or an FSU-linked entry already in financing_already_applied) is already covering part of the budget, do not recommend a second FSU-linked Program (the platform only allows one per project — see the FSU rule below) and do not describe the project as lacking FSU financing.
- Always reference the actual remaining_financing_gap_percent in summary_es/summary_en (e.g. "resta cubrir un X% del presupuesto") rather than a generic statement.

Rules:
- Only recommend Programs whose "types" array includes the project's project_type, OR whose types array is empty (generic/type-agnostic Programs).
- The platform enforces at most ONE FSU-linked financing-stage Program per project (any Program whose financing_entity contains "ENACOM-FSU", "FSU", or is itself an FSU-adjacent instrument like TASU/FATIC/CIP/Emergencias/Red Mayorista Neutral) — if fsu_coverage_percent > 0 or financing_already_applied already contains an FSU-linked Program, do NOT recommend any other FSU-linked Program at all; otherwise, if you do recommend one, recommend only the single best-fitting one.
- A Program already in financing_already_applied can still be recommended (e.g. to confirm it's a good fit, or to recommend adding a complementary one alongside it) — the caller will mark it as "already applied" for display. Use its already-loaded financing_percentage/financing_amount (if any) to judge whether topping it up or replacing it makes sense, rather than recommending a duplicate-purpose instrument.
- Recommend at most ${MAX_RECOMMENDED} Programs, ordered by fit_score descending (0-100, how well each one fits THIS specific project — consider type eligibility, budget size, country, stage of maturity, remaining_financing_gap_percent, and whether the instrument's purpose — preparation vs. implementation financing vs. risk mitigation — matches where this project actually is right now).
- If fewer than ${MAX_RECOMMENDED} Programs genuinely fit well, recommend fewer rather than padding the list with poor fits. If remaining_financing_gap_percent is 0 or very small, it is correct to recommend very few (or zero) additional financing-stage Programs.
- rationale_es / rationale_en: 1-3 concise sentences each, specific to why THIS Program fits THIS project (not generic boilerplate).
- summary_es / summary_en: 2-4 sentences explaining the overall combination strategy — how the recommended instruments work together as a set, and how they relate to what's already secured (total_coverage_percent / remaining_financing_gap_percent).

suggested_percentage (Pablo's request, sep 2026 — propose the % of budget for
each instrument too, not just pick it): for every recommended Program whose
funding_stage is "financing" (NOT "preparation" — a preparation/feasibility
grant doesn't fund a share of the implementation budget, so always use null
for those), propose an integer 0-100 = what % of the project's total budget
this specific instrument should realistically cover, given remaining_
financing_gap_percent and what the OTHER recommended financing-stage
instruments in the same list are also proposed to cover. When two or more
recommended financing-stage instruments are meant to be combined together
(complementary, e.g. debt + a guarantee that only covers part of the debt),
their suggested_percentage values should roughly sum to remaining_financing_
gap_percent or less — do not casually propose percentages that add up to far
more than 100% once total_coverage_percent is included. When two instruments
are alternatives to each other (recommend either one OR the other, not both),
say so explicitly in their rationale and it's fine for both to independently
propose a similar percentage covering most/all of the remaining gap. This is
a starting suggestion only — the user can edit it before applying.

Respond with ONLY a single valid JSON object — no markdown code fences, no commentary — in this exact shape:
{
  "recommended": [
    { "program_id": "<uuid from the catalog>", "fit_score": <integer 0-100>, "suggested_percentage": <integer 0-100 or null>, "rationale_es": "<spanish>", "rationale_en": "<english>" }
  ],
  "summary_es": "<spanish>",
  "summary_en": "<english>"
}`;
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
  if (!projectId) return json(res, 400, { error: 'projectId is required' });

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const user = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!user || !user.id) return json(res, 401, { error: 'Invalid session' });

    const projects = await supabaseRest(`/projects?id=eq.${projectId}&select=*`, {
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });
    const project = projects && projects[0];
    if (!project) return json(res, 404, { error: 'Project not found' });

    // Same permission check as api/analyze-project.js: owner, the advisor
    // currently assigned to the project, or any admin (no "take" required).
    // No workflow-stage guard, for the same reason AI Analysis/Self-
    // Assessment/FSU Scoring have none — see "Enable Self/AI/FSU analysis
    // at any workflow stage" in PLATFORM_SETUP.md.
    let isAdminCaller = false;
    try {
      const callerProfiles = await supabaseRest(`/profiles?id=eq.${user.id}&select=role`, {
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
        supabaseUrl: SUPABASE_URL,
      });
      isAdminCaller = !!(callerProfiles && callerProfiles[0] && callerProfiles[0].role === 'admin');
    } catch (e) { isAdminCaller = false; }
    const isOwner = project.user_id === user.id;
    const isAssignedAdvisor = !!project.assigned_advisor_id && project.assigned_advisor_id === user.id;
    if (!isOwner && !isAssignedAdvisor && !isAdminCaller) return json(res, 403, { error: 'Not your project' });

    // Full catalog of financing/preparation Programs — program_role='financing'
    // excludes umbrella Iniciativas (see programs.program_role in
    // schema.sql), which are never a funding source themselves.
    const programs = await supabaseRest(
      `/programs?program_role=eq.financing&select=id,name,name_en,financing_entity,funding_stage,types,description`,
      { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL }
    );
    const programsById = new Map((programs || []).map((p) => [p.id, p]));

    // Embed the linked program's name/financing_entity/funding_stage (not
    // just program_id) plus this application's own financing_percentage/
    // financing_amount — needed both for the applied-programs list AND to
    // feed computeFinancingCoverage() below, which needs the same shape
    // INAPlatform.computeFinancingCoverage() consumes client-side.
    const appliedRows = await supabaseRest(
      `/project_programs?project_id=eq.${projectId}&select=program_id,financing_percentage,financing_amount,programs(name,financing_entity,funding_stage)`,
      { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL }
    );
    const appliedProgramIds = new Set((appliedRows || []).map((r) => r.program_id));

    const coverage = computeFinancingCoverage(project, appliedRows || []);
    const appliedProgramsDetail = (appliedRows || []).map((r) => ({
      program_id: r.program_id,
      name: r.programs && r.programs.name,
      financing_entity: (r.programs && r.programs.financing_entity) || null,
      funding_stage: r.programs && r.programs.funding_stage,
      financing_percentage: r.financing_percentage != null ? Number(r.financing_percentage) : null,
      financing_amount: r.financing_amount != null ? Number(r.financing_amount) : null,
    }));

    const projectProfile = buildProjectProfile(project, coverage, appliedProgramsDetail);
    const catalog = buildProgramsCatalog(programs);

    const systemPrompt = buildSystemPrompt();
    const userContent = `PROJECT PROFILE (JSON):\n${JSON.stringify(projectProfile)}\n\nPROGRAMS CATALOG (JSON):\n${JSON.stringify(catalog)}`;

    let rawText;
    if (provider === 'bedrock-mock') {
      // Simulated result — no model call — same spirit as
      // api/analyze-project.js's bedrock-mock branch: every piece of
      // generated text is labeled SIMULATED so it's never mistaken for a
      // real recommendation.
      const top = catalog.slice(0, Math.min(3, catalog.length));
      rawText = JSON.stringify({
        recommended: top.map((p, i) => ({
          program_id: p.id,
          fit_score: 80 - i * 10,
          suggested_percentage: p.funding_stage === 'preparation' ? null : Math.max(10, 40 - i * 10),
          rationale_es: '[SIMULADO] Recomendación de ejemplo, sin llamada a un modelo real.',
          rationale_en: '[SIMULATED] Example recommendation, no real model call made.',
        })),
        summary_es: '[SIMULADO] Combinación de ejemplo.',
        summary_en: '[SIMULATED] Example combination.',
      });
    } else if (provider === 'groq') {
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` },
        body: JSON.stringify({
          model: GROQ_MODEL || GROQ_MODEL_DEFAULT,
          max_tokens: MODEL_MAX_TOKENS,
          temperature: 0,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        console.error(`[recommend-financing] Groq request failed (status ${groqRes.status}):`, errText);
        return json(res, 502, { error: 'Recommendation model request failed', detail: errText });
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
          max_tokens: MODEL_MAX_TOKENS,
          temperature: 0,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: userContent },
          ],
        }),
      });
      if (!localRes.ok) {
        const errText = await localRes.text().catch(() => '');
        console.error(`[recommend-financing] local model request failed (status ${localRes.status}):`, errText);
        return json(res, 502, { error: 'Recommendation model request failed (local model)', detail: errText });
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
          inferenceConfig: { maxTokens: MODEL_MAX_TOKENS, temperature: 0 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
      } catch (bedrockErr) {
        console.error('[recommend-financing] Bedrock request failed:', bedrockErr);
        return json(res, 502, {
          error: 'Recommendation model request failed',
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
          max_tokens: MODEL_MAX_TOKENS,
          temperature: 0,
          system: systemPrompt,
          messages: [{ role: 'user', content: userContent }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        console.error(`[recommend-financing] Anthropic request failed (status ${anthropicRes.status}):`, errText);
        return json(res, 502, { error: 'Recommendation model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
    }

    let parsed;
    try {
      // Same defensive parsing as api/extract-template-data.js (see that
      // file's comment + PLATFORM_SETUP.md's "Could not parse extraction
      // output" fix for why all three steps are needed): strip a leading
      // <think> block, strip a code fence, then slice to the outer {...}.
      const withoutThink = rawText.replace(/^\s*<think>[\s\S]*?<\/think>\s*/i, '');
      let cleaned = withoutThink.trim().replace(/^```json\s*/i, '').replace(/```$/, '').trim();
      const firstBrace = cleaned.indexOf('{');
      const lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace !== -1 && lastBrace > firstBrace) {
        cleaned = cleaned.slice(firstBrace, lastBrace + 1);
      }
      parsed = JSON.parse(cleaned);
    } catch (e) {
      console.error('[recommend-financing] could not parse model output as JSON:', e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse recommendation output', raw: rawText.slice(0, 2000) });
    }

    // Never trust the model's own program_id/name/financing_entity/
    // funding_stage verbatim — resolve every recommended entry against the
    // REAL catalog fetched above, and silently drop anything that doesn't
    // match a real id (a hallucinated uuid, most likely). fit_score and the
    // rationale text are the only fields taken from the model as-is.
    const rawRecommended = Array.isArray(parsed.recommended) ? parsed.recommended : [];
    const recommended = [];
    const recommendedEn = [];
    rawRecommended.slice(0, MAX_RECOMMENDED).forEach((r) => {
      const pg = r && programsById.get(r.program_id);
      if (!pg) return;
      const fitScore = Math.max(0, Math.min(100, Math.round(Number(r.fit_score) || 0)));
      const alreadyApplied = appliedProgramIds.has(pg.id);
      // Only financing-stage instruments get a meaningful % of budget — a
      // preparation/feasibility grant (funding_stage === 'preparation')
      // never gets one, same rule as computeFinancingCoverage()/
      // renderProgramApplicationRow() elsewhere on the platform, enforced
      // here regardless of what the model returned.
      const rawPct = pg.funding_stage === 'preparation' ? null : r.suggested_percentage;
      const suggestedPercentage = rawPct == null || rawPct === '' || Number.isNaN(Number(rawPct))
        ? null
        : Math.max(0, Math.min(100, Math.round(Number(rawPct))));
      recommended.push({
        program_id: pg.id,
        name: pg.name,
        financing_entity: pg.financing_entity || null,
        funding_stage: pg.funding_stage,
        fit_score: fitScore,
        suggested_percentage: suggestedPercentage,
        rationale: String(r.rationale_es || '').slice(0, 1000),
        already_applied: alreadyApplied,
      });
      recommendedEn.push({
        program_id: pg.id,
        // Optional programs.name_en (migration_v57_program_name_en.sql) —
        // falls back to the original name, same convention as
        // INAPlatform.programDisplayName() in assets/platform.js, kept
        // duplicated here since this file can't import that browser module.
        name: pg.name_en || pg.name,
        financing_entity: pg.financing_entity || null,
        funding_stage: pg.funding_stage,
        fit_score: fitScore,
        suggested_percentage: suggestedPercentage,
        rationale: String(r.rationale_en || r.rationale_es || '').slice(0, 1000),
        already_applied: alreadyApplied,
      });
    });

    const summaryEs = String(parsed.summary_es || '').slice(0, 2000) || null;
    const summaryEn = String(parsed.summary_en || parsed.summary_es || '').slice(0, 2000) || null;

    // Upsert by project_id: check for an existing row, then PATCH or POST —
    // simpler and just as safe as PostgREST's on_conflict header given this
    // is a single, low-frequency write per call (no concurrent-write race
    // to worry about beyond what the unique(project_id) constraint already
    // guards against).
    const existing = await supabaseRest(`/financing_recommendations?project_id=eq.${projectId}&select=id`, {
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });
    const payload = {
      project_id: projectId,
      user_id: user.id,
      recommended,
      recommended_en: recommendedEn,
      summary: summaryEs,
      summary_en: summaryEn,
      raw_model_output: rawText.slice(0, 8000),
      updated_at: new Date().toISOString(),
    };
    let saved;
    if (existing && existing[0]) {
      const rows = await supabaseRest(`/financing_recommendations?id=eq.${existing[0].id}`, {
        method: 'PATCH',
        body: payload,
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
        supabaseUrl: SUPABASE_URL,
      });
      saved = rows && rows[0];
    } else {
      const rows = await supabaseRest(`/financing_recommendations`, {
        method: 'POST',
        body: payload,
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
        supabaseUrl: SUPABASE_URL,
      });
      saved = rows && rows[0];
    }

    return json(res, 200, { ok: true, recommendation: saved });
  } catch (err) {
    console.error('[recommend-financing] unhandled error:', err);
    return json(res, 500, { error: 'Recommendation failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 60 };
