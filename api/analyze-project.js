/**
 * INA Platform — /api/analyze-project
 * Vercel serverless function (Node.js runtime, no external dependencies —
 * uses built-in fetch so no `npm install` is required to deploy).
 *
 * Applies the INA Investment Readiness Index™ (Framework F2) and
 * Multilateral Finance Navigator™ (Framework F6) to a submitted project,
 * using an LLM (Anthropic Claude by default, or a free open-source model
 * via Groq — see LLM_PROVIDER below), and writes the structured result to
 * Supabase (framework_analysis table).
 *
 * Required environment variables (set in Vercel → Project → Settings →
 * Environment Variables):
 *   SUPABASE_URL              — same value as in assets/platform.js
 *   SUPABASE_SERVICE_ROLE_KEY — Supabase service role key (server-only,
 *                               NEVER the anon key, NEVER exposed client-side)
 *   SUPABASE_ANON_KEY         — used only to validate the caller's session token
 *
 * Model provider (pick ONE path — see LLM_PROVIDER below):
 *   ANTHROPIC_API_KEY   — required when LLM_PROVIDER is unset or 'anthropic'
 *                         (the default — this is what runs in production)
 *   CLAUDE_MODEL        — optional, defaults to "claude-sonnet-5"
 *   ------------------------------------------------------------------
 *   LLM_PROVIDER        — optional, defaults to 'anthropic'. Set to 'groq'
 *                         to use a free open-source model via Groq
 *                         (groq.com) instead — meant for the dev/test
 *                         environment only, to avoid burning Anthropic
 *                         credits while iterating. Scope this (and
 *                         GROQ_API_KEY below) to Vercel's Preview/
 *                         Development environments only, leaving
 *                         Production on Anthropic — see "Using a free
 *                         open-source model in development" in
 *                         PLATFORM_SETUP.md for the full walkthrough.
 *   GROQ_API_KEY        — required when LLM_PROVIDER='groq'. Free account
 *                         at console.groq.com, no credit card needed.
 *   GROQ_MODEL          — optional, defaults to 'llama-3.3-70b-versatile'.
 *   ------------------------------------------------------------------
 *   Set LLM_PROVIDER='bedrock' to run an open-weight model (Meta Llama
 *   3.3 70B by default) through AWS Bedrock instead — an open-source model
 *   with the same kind of enterprise no-training/no-retention data
 *   handling terms as Anthropic, at a fraction of the per-token cost. This
 *   is the recommended PRODUCTION option when the projects being analyzed
 *   contain confidential information and a managed (not self-hosted) open
 *   model is preferred. See "Using AWS Bedrock (open-source model,
 *   confidential-data-friendly)" in PLATFORM_SETUP.md for the full
 *   walkthrough (IAM user setup, enabling model access, etc.).
 *   AWS_ACCESS_KEY_ID     — required when LLM_PROVIDER='bedrock'. Use a
 *                           dedicated IAM user scoped to bedrock:Converse
 *                           only — never a root/admin key.
 *   AWS_SECRET_ACCESS_KEY — required when LLM_PROVIDER='bedrock'.
 *   AWS_REGION            — optional, defaults to 'us-east-1'. Must be a
 *                           region where the chosen model is enabled for
 *                           your account (Bedrock console → Model access).
 *   BEDROCK_MODEL_ID      — optional, defaults to
 *                           'meta.llama3-3-70b-instruct-v1:0'.
 *
 *   Set LLM_PROVIDER='bedrock-mock' to try the interface end-to-end
 *   WITHOUT an AWS account — no AWS_* variables are read or required on
 *   this path. It fabricates a plausible-looking result locally (random
 *   but bounded per-dimension scores, generic rationale text) instead of
 *   calling any model at all, and every piece of generated text is
 *   prefixed/labeled "SIMULATED" so it can never be mistaken for a real
 *   assessment if someone reads it later. Meant purely for demoing the
 *   submit → analyze → results flow before deciding whether to actually
 *   set up a paid AWS account — swap to 'bedrock' (see above) once ready.
 *   ------------------------------------------------------------------
 *   Set LLM_PROVIDER='local' to use a model running entirely on your own
 *   machine/infrastructure (Ollama, LM Studio, llama.cpp server, vLLM —
 *   anything that exposes an OpenAI-compatible /v1/chat/completions
 *   endpoint) instead of any cloud provider. No project data ever leaves
 *   your own network on this path — the strongest confidentiality option
 *   available here, at zero per-token cost, at the price of needing that
 *   machine to be running and reachable whenever an analysis is requested.
 *   See "Using a local/on-premise model (Ollama, LM Studio, etc.)" in
 *   PLATFORM_SETUP.md for the full walkthrough, including the important
 *   caveat that this Vercel function runs in Vercel's cloud, NOT on your
 *   PC — reaching a model on your own machine from a deployed site
 *   requires either running the whole platform locally too (recommended
 *   for personal/dev use) or exposing your local model through a tunnel
 *   (Cloudflare Tunnel recommended) if you want the live production site
 *   to use it.
 *   LOCAL_LLM_BASE_URL — optional, defaults to 'http://localhost:11434/v1'
 *                         (Ollama's default OpenAI-compatible endpoint).
 *                         Point this at whatever your local server's
 *                         OpenAI-compatible base URL is (e.g. LM Studio
 *                         defaults to http://localhost:1234/v1).
 *   LOCAL_LLM_MODEL     — required when LLM_PROVIDER='local'. No safe
 *                         default — the model name your local server has
 *                         loaded (e.g. 'llama3.1:8b', 'qwen2.5:14b-instruct').
 *   LOCAL_LLM_API_KEY   — optional. Most local servers need no auth at
 *                         all; set this only if yours is protected (e.g.
 *                         sitting behind a tunnel with a bearer token).
 *
 *   The Groq, Bedrock and local-model paths all talk to a plain chat-style
 *   endpoint rather than Anthropic's native-document Messages API, and —
 *   unlike Claude — none of them read PDFs/images natively here, so for all
 *   three this function extracts PDF text itself first (via the `pdf-parse` package)
 *   and skips images rather than sending them; see "Build the model input"
 *   below.
 *
 * IMPORTANT — function timeout: Vercel kills serverless functions after a
 * plan-dependent limit (10s by default on the Hobby plan unless raised).
 * Large attached PDFs (multi-page, image-heavy carpetas técnicas, etc.)
 * can easily make the Claude call take longer than that default, and if
 * Vercel kills the function AFTER it already PATCHed the project to
 * status='analyzing' but BEFORE it could write the result or set
 * status='error', the project is left stuck in "analyzing" forever from
 * the client's point of view (see project.html's staleness check, which
 * papers over this from the UI side, but raising this limit is the real
 * fix). `maxDuration` below asks Vercel for up to 60s, the maximum the
 * Hobby plan allows — on Pro/Enterprise you can raise it further for
 * very large documents. (Set on module.exports at the bottom of this
 * file, not here — module.exports gets reassigned to the handler
 * function further down, which would wipe out a config property set
 * this early.)
 */

// NOTE: pdf-parse and @aws-sdk/client-bedrock-runtime are deliberately
// require()'d LAZILY, at their actual point of use further down (the PDF
// text-extraction branch, and the 'bedrock' model-call branch,
// respectively) — NOT unconditionally up here. Learned the hard way:
// pdf-parse pulls in an optional native dependency (@napi-rs/canvas) that
// doesn't install cleanly on Vercel's serverless runtime, and when that
// happens pdf-parse throws a fatal `ReferenceError: DOMMatrix is not
// defined` the moment it's require()'d — not when it's actually used. A
// top-level require() here meant that crash happened on EVERY invocation
// of this function regardless of which LLM_PROVIDER was active, including
// providers ('anthropic', 'bedrock-mock') that never touch pdf-parse at
// all. Lazy requires wrapped in try/catch (see below) mean a broken
// optional dependency degrades to "that one PDF couldn't be read" instead
// of taking down the whole endpoint.

const GROQ_MODEL_DEFAULT = 'llama-3.3-70b-versatile';
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

const DIMENSION_KEYS = [
  'legal_regulatory',
  'technical_maturity',
  'financial_robustness',
  'sponsor_capacity',
  'market_demand',
  'environmental_social',
  'risk_mitigation',
  'governance_reporting',
];

const FINANCING_MECHANISMS = [
  'Multilateral Development Banks',
  'Development Finance Institutions',
  'Project Finance',
  'Public-Private Partnerships',
  'Blended Finance',
  'Guarantees & Credit Enhancement',
  'Export Credit Agencies',
  'Commercial & Institutional Capital',
  'Universal Service Funds',
];

const SYSTEM_PROMPT = `You are the analysis engine behind two of INA's (International Network Advisors) proprietary frameworks, applied together to a single submitted project:

1. INVESTMENT READINESS INDEX™ (Framework F2): scores a digital infrastructure project 0–100 across 8 weighted dimensions: Legal & Regulatory Clarity, Technical Design Maturity, Financial Model Robustness, Sponsor Capacity, Market Demand Evidence, Environmental & Social Readiness, Risk Mitigation Coverage, and Governance & Reporting. Score bands: 0–25 Concept Stage, 26–50 Early Structuring, 51–75 Advanced Structuring, 76–100 Investment Ready.

2. MULTILATERAL FINANCE NAVIGATOR™ (Framework F6): reads the project's country, sector, size, maturity and risk profile, then recommends which financing mechanisms are the realistic fit, drawn ONLY from this list: Multilateral Development Banks, Development Finance Institutions (e.g. the U.S. International Development Finance Corporation/DFC for direct loans, equity and political risk insurance, and the U.S. Trade and Development Agency/USTDA for early-stage feasibility study grants — favor these when the project has a plausible U.S. company/technology nexus), Project Finance, Public-Private Partnerships, Blended Finance, Guarantees & Credit Enhancement, Export Credit Agencies, Commercial & Institutional Capital, Universal Service Funds (national/regulator-administered funds — e.g. ENACOM's Fondo de Servicio Universal in Argentina — offering subsidized-rate credit or grants for underserved-area buildout; favor this when the project targets last-mile/universal-access coverage in underserved areas, especially for cooperatives or small/regional operators).

You will be given a project's name, type, country and description, and possibly supporting documents. Assess honestly based only on the evidence provided — if information for a dimension is missing or unclear, score it conservatively low and say so in the rationale rather than assuming strength. Do not inflate scores. Be specific and reference concrete details from the project description in your rationales wherever possible, rather than generic boilerplate.

INA's platform serves both Spanish- and English-speaking users, so every rationale/action/summary field below must be written TWICE — once in Spanish (the "_es" field) and once in English (the "_en" field). Write natural, idiomatic prose in each language (not a literal word-for-word translation of one from the other), but keep the underlying assessment identical in both: the same scores, the same priorities, the same recommended mechanisms.

Respond with ONLY a single valid JSON object — no markdown code fences, no commentary before or after — matching exactly this shape:

{
  "overall_score": <integer 0-100>,
  "dimensions": {
    "legal_regulatory": {"score": <0-100>, "rationale_es": "<1-2 sentences, specific to this project, in Spanish>", "rationale_en": "<same content, in English>"},
    "technical_maturity": {"score": <0-100>, "rationale_es": "<...>", "rationale_en": "<...>"},
    "financial_robustness": {"score": <0-100>, "rationale_es": "<...>", "rationale_en": "<...>"},
    "sponsor_capacity": {"score": <0-100>, "rationale_es": "<...>", "rationale_en": "<...>"},
    "market_demand": {"score": <0-100>, "rationale_es": "<...>", "rationale_en": "<...>"},
    "environmental_social": {"score": <0-100>, "rationale_es": "<...>", "rationale_en": "<...>"},
    "risk_mitigation": {"score": <0-100>, "rationale_es": "<...>", "rationale_en": "<...>"},
    "governance_reporting": {"score": <0-100>, "rationale_es": "<...>", "rationale_en": "<...>"}
  },
  "gap_roadmap": [
    {"priority": "high|medium|low", "action_es": "<specific, actionable next step, in Spanish>", "action_en": "<same content, in English>"}
  ],
  "financing_recommendations": [
    {"mechanism": "<one of the mechanisms listed above, verbatim — this field is not translated>", "rationale_es": "<why it fits this specific project, in Spanish>", "rationale_en": "<same content, in English>"}
  ],
  "summary_es": "<2-3 sentence executive summary of overall readiness and the single most important next step, in Spanish>",
  "summary_en": "<same content, in English>"
}

overall_score must be the weighted average of the 8 dimension scores (equal weighting is fine unless the project profile clearly warrants otherwise). gap_roadmap should have 3-6 items ordered by priority. financing_recommendations should have 2-4 items, each mechanism used at most once.`;

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

/* CORS — needed once the site moved to Bluehost for production (see
   MIGRACION_BLUEHOST.md Parte 3/4): this function stays on Vercel
   permanently (Bluehost has no Node.js support), reachable from the
   Bluehost site via api.international-network-advisors.com, which is no
   longer the same origin as the page making the request. Allows the
   production domain (with and without www) plus any *.vercel.app
   deployment so the Vercel copy keeps working as the dev/test
   environment. Deliberately NOT a wildcard '*' — this endpoint reads the
   caller's Supabase session token from the Authorization header. */
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
  if (['png'].includes(ext)) return 'image/png';
  if (['jpg', 'jpeg'].includes(ext)) return 'image/jpeg';
  if (['txt', 'md', 'csv'].includes(ext)) return 'text/plain';
  return null;
}

function clampScore(n) {
  const v = Math.round(Number(n));
  if (Number.isNaN(v)) return 0;
  return Math.max(0, Math.min(100, v));
}

function stageForScore(score) {
  if (score <= 25) return 'Concept Stage';
  if (score <= 50) return 'Early Structuring';
  if (score <= 75) return 'Advanced Structuring';
  return 'Investment Ready';
}

/* Only used on the LLM_PROVIDER='bedrock-mock' path — see file header
   comment. Builds a JSON string in EXACTLY the same shape the real
   models are prompted to return, so it flows through the existing
   parse/normalize/persist code below completely unchanged. Every score is
   randomized-but-bounded (40-85, comfortably mid-range — never a
   suspiciously perfect or suspiciously terrible result) purely so a demo
   with several test projects doesn't look identical every time; none of it
   is derived from actually reading the project's description or
   documents. That's why "SIMULATED" is baked into the summary and every
   rationale string rather than left to a UI badge alone — this data can
   end up read out of context (exported, screenshotted, quoted in an
   email) long after anyone remembers which provider generated it. */
function buildMockAnalysis(project) {
  const rand = (min, max) => Math.floor(min + Math.random() * (max - min + 1));

  const dimensions = {};
  let sum = 0;
  DIMENSION_KEYS.forEach((key) => {
    const score = rand(40, 85);
    sum += score;
    dimensions[key] = {
      score,
      rationale_es: `[SIMULADO — no se llamó a ningún modelo] Justificación de ejemplo para ${key.replace(/_/g, ' ')}.`,
      rationale_en: `[SIMULATED — no model was called] Placeholder rationale for ${key.replace(/_/g, ' ')}.`,
    };
  });
  const overallScore = Math.round(sum / DIMENSION_KEYS.length);
  const stage = stageForScore(overallScore);

  const lowestThree = DIMENSION_KEYS
    .map((key) => ({ key, score: dimensions[key].score }))
    .sort((a, b) => a.score - b.score)
    .slice(0, 3);
  const gapRoadmap = lowestThree.map((d, i) => ({
    priority: i === 0 ? 'high' : i === 1 ? 'medium' : 'low',
    action_es: `[SIMULADO] Próximo paso de ejemplo para ${d.key.replace(/_/g, ' ')} — no es una recomendación real.`,
    action_en: `[SIMULATED] Example next step for ${d.key.replace(/_/g, ' ')} — not a real recommendation.`,
  }));

  const shuffledMechanisms = [...FINANCING_MECHANISMS].sort(() => Math.random() - 0.5);
  const financingRecommendations = shuffledMechanisms.slice(0, 2).map((mechanism) => ({
    mechanism,
    rationale_es: '[SIMULADO] Mecanismo de financiamiento de ejemplo — no es una recomendación real.',
    rationale_en: '[SIMULATED] Example financing mechanism — not a real recommendation.',
  }));

  const summaryEs = `⚠️ RESULTADO SIMULADO — no se llamó a ningún modelo de IA (LLM_PROVIDER=bedrock-mock). Estos son datos de prueba para probar el flujo de carga de "${project.name}", no una evaluación real de este proyecto. Configurá LLM_PROVIDER como 'anthropic' o 'bedrock' para un análisis real.`;
  const summaryEn = `⚠️ SIMULATED RESULT — no AI model was called (LLM_PROVIDER=bedrock-mock). This is placeholder data for trying out the "${project.name}" submission flow, not a real assessment of this project. Set LLM_PROVIDER to 'anthropic' or 'bedrock' for a real analysis.`;

  return JSON.stringify({
    overall_score: overallScore,
    dimensions,
    gap_roadmap: gapRoadmap,
    financing_recommendations: financingRecommendations,
    summary_es: summaryEs,
    summary_en: summaryEn,
  });
}

async function handler(req, res) {
  const origin = req.headers.origin;
  if (isAllowedOrigin(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  // Browsers send a preflight OPTIONS request before the real POST for a
  // cross-origin call with a custom Authorization header — no body/auth
  // to check yet, just confirm the CORS headers above and stop here.
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

  // 'anthropic' (production default), 'groq' (free, dev-only), 'bedrock'
  // (open-source model via AWS Bedrock — recommended production option for
  // confidential data), 'local' (a model running on your own machine/
  // infrastructure — see file header comment), or 'bedrock-mock' (no model
  // call at all, no credentials needed). Whichever real-model path is
  // active still needs the same three Supabase vars; only the
  // model-provider credentials differ.
  const provider = (LLM_PROVIDER || 'anthropic').toLowerCase();
  const providerKeyMissing = provider === 'groq'
    ? !GROQ_API_KEY
    : provider === 'bedrock'
      ? (!AWS_ACCESS_KEY_ID || !AWS_SECRET_ACCESS_KEY)
      : provider === 'bedrock-mock'
        ? false
        : provider === 'local'
          // No API key required — a local server typically has none. Only
          // the model name is required (no safe default, unlike
          // LOCAL_LLM_BASE_URL below); the base URL falls back to Ollama's
          // default if unset.
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

    // Full platform admins can run AI Analysis on ANY project, at any
    // stage, without owning it or having "taken" it as an advisor first —
    // unlike isAssignedAdvisor (below), this isn't derived from a trusted
    // column on the project row, so it needs its own lookup against
    // profiles.role. Fails closed (isAdminCaller stays false) if the
    // lookup errors or the profile row is missing, rather than throwing —
    // a broken admin check should just fall through to the normal
    // owner/advisor rules, never silently grant access.
    let isAdminCaller = false;
    try {
      const callerProfiles = await supabaseRest(`/profiles?id=eq.${user.id}&select=role`, {
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
        supabaseUrl: SUPABASE_URL,
      });
      isAdminCaller = !!(callerProfiles && callerProfiles[0] && callerProfiles[0].role === 'admin');
    } catch (e) { isAdminCaller = false; }

    // Allowed to run analysis: the project owner, the advisor who has
    // "taken" it (projects.assigned_advisor_id, set only via the
    // advisor/admin-only take_project()/promote_project_workflow()/
    // demote_project_workflow() RPCs — see supabase/migration_v12_workflow.sql
    // and migration_v20_workflow_promote_demote.sql — so trusting this
    // column here doesn't need a separate role re-check), or any admin.
    const isOwner = project.user_id === user.id;
    const isAssignedAdvisor = !!project.assigned_advisor_id && project.assigned_advisor_id === user.id;
    if (!isOwner && !isAssignedAdvisor && !isAdminCaller) return json(res, 403, { error: 'Not your project' });

    // Workflow guard (migration_v20_workflow_promote_demote.sql), owner
    // path only: for the OWNER, AI Analysis isn't offered while the
    // project is still Not Analyzed (readiness_stage null) — it only
    // becomes available once their own self-assessment has moved it to
    // Concept Stage. An assigned ADVISOR, or any ADMIN (regardless of
    // assignment), is exempt from this guard: either can run AI Analysis
    // at any stage, including before any self-assessment exists, since for
    // them it's a decision-support tool independent of whether the owner
    // has self-assessed yet (see the matching client-side gate in
    // app/project.html's canRunAnalysis and PLATFORM_SETUP.md's "AI
    // Analysis at any stage (advisor/admin)" note).
    if (!project.readiness_stage && !isAssignedAdvisor && !isAdminCaller) {
      return json(res, 409, { error: 'This project needs the owner’s self-assessment before AI Analysis can run.' });
    }

    await supabaseRest(`/projects?id=eq.${projectId}`, {
      method: 'PATCH',
      body: { status: 'analyzing', updated_at: new Date().toISOString() },
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });

    const documents = await supabaseRest(`/project_documents?project_id=eq.${projectId}&select=*`, {
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });

    // Build the model input: project text + up to 5 documents. On the
    // Anthropic path, PDFs/images are sent natively (Claude reads them
    // directly) via `contentBlocks`; plain text files are always inlined
    // into `projectText` either way. On the Groq and Bedrock paths (see
    // LLM_PROVIDER in the file header comment), there's no native
    // document/image support wired up here, so PDFs are text-extracted
    // instead (via `pdf-parse`) and images are simply skipped — noted in
    // `skippedNotes` like anything else that couldn't be read.
    const textOnlyProvider = provider === 'groq' || provider === 'bedrock' || provider === 'local';
    const contentBlocks = [];
    let projectText = `PROJECT NAME: ${project.name}\nPROJECT TYPE: ${project.project_type}\nCOUNTRY: ${project.country}\n\nDESCRIPTION:\n${project.description}`;

    // bedrock-mock never reads any of this — skip the Storage
    // downloads/PDF parsing entirely rather than doing pointless work.
    const docsToInclude = provider === 'bedrock-mock' ? [] : (documents || []).slice(0, 5);
    const skippedNotes = [];

    for (const doc of docsToInclude) {
      const mediaType = guessMediaType(doc.file_name);
      if (!mediaType) {
        skippedNotes.push(doc.file_name);
        continue;
      }
      const fileBuffer = await downloadStorageFile(doc.storage_path, {
        supabaseUrl: SUPABASE_URL,
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      });
      if (!fileBuffer) { skippedNotes.push(doc.file_name); continue; }

      if (mediaType === 'application/pdf') {
        if (fileBuffer.length > 25 * 1024 * 1024) {
          skippedNotes.push(`${doc.file_name} (too large)`);
        } else if (textOnlyProvider) {
          // Text-extract rather than send the raw PDF — see comment above.
          // Truncated fairly aggressively (4000 chars/doc): Groq's free
          // tier is rate-limited at 6K tokens/minute total, so several
          // large PDFs here would blow that budget in a single request
          // (Bedrock has no such hard cap, but the same truncation keeps
          // behavior/cost predictable across both text-only providers).
          //
          // require('pdf-parse') is deliberately done HERE, not at the top
          // of the file, and wrapped in its own try/catch — see the
          // comment at the top of the file. If pdf-parse itself can't even
          // load in this environment, this document is just skipped rather
          // than crashing every analysis regardless of provider.
          let PDFParseCtor = null;
          try {
            ({ PDFParse: PDFParseCtor } = require('pdf-parse'));
          } catch (loadErr) {
            skippedNotes.push(`${doc.file_name} (PDF text extraction unavailable in this environment)`);
          }
          if (PDFParseCtor) {
            const parser = new PDFParseCtor({ data: fileBuffer });
            try {
              const extracted = await parser.getText();
              const text = (extracted.text || '').trim();
              if (text) {
                projectText += `\n\n--- ATTACHED FILE (text extracted from PDF): ${doc.file_name} ---\n${text.slice(0, 4000)}`;
              } else {
                skippedNotes.push(`${doc.file_name} (no extractable text — likely scanned/image-only)`);
              }
            } catch (e) {
              skippedNotes.push(`${doc.file_name} (couldn't parse PDF)`);
            } finally {
              await parser.destroy().catch(() => {});
            }
          }
        } else {
          contentBlocks.push({
            type: 'document',
            source: { type: 'base64', media_type: mediaType, data: fileBuffer.toString('base64') },
          });
        }
      } else if (mediaType.startsWith('image/')) {
        if (textOnlyProvider) {
          // No image input wired up on the Groq/Bedrock paths — see file
          // header comment. Noted so the model at least knows it exists.
          skippedNotes.push(`${doc.file_name} (image — not analyzed with this model provider)`);
        } else {
          contentBlocks.push({
            type: 'image',
            source: { type: 'base64', media_type: mediaType, data: fileBuffer.toString('base64') },
          });
        }
      } else if (mediaType === 'text/plain') {
        projectText += `\n\n--- ATTACHED FILE: ${doc.file_name} ---\n${fileBuffer.toString('utf-8').slice(0, 8000)}`;
      }
    }

    if (skippedNotes.length) {
      projectText += `\n\n(Additional attached files not machine-readable in this analysis: ${skippedNotes.join(', ')})`;
    }

    contentBlocks.unshift({ type: 'text', text: projectText });

    let rawText;
    if (provider === 'bedrock-mock') {
      rawText = buildMockAnalysis(project);
    } else if (provider === 'groq') {
      // OpenAI-compatible chat completions endpoint — see
      // https://console.groq.com/docs/api-reference#chat-create. Only
      // `projectText` is sent (no contentBlocks/vision — see above), as a
      // plain string user message rather than Anthropic's content-block
      // array shape.
      const groqRes = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${GROQ_API_KEY}`,
        },
        body: JSON.stringify({
          model: GROQ_MODEL || GROQ_MODEL_DEFAULT,
          max_tokens: 3000,
          temperature: 0.2,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user', content: projectText },
          ],
        }),
      });

      if (!groqRes.ok) {
        const errText = await groqRes.text().catch(() => '');
        await supabaseRest(`/projects?id=eq.${projectId}`, {
          method: 'PATCH',
          body: { status: 'error', updated_at: new Date().toISOString() },
          serviceKey: SUPABASE_SERVICE_ROLE_KEY,
          supabaseUrl: SUPABASE_URL,
        });
        return json(res, 502, { error: 'Analysis model request failed', detail: errText });
      }

      const groqData = await groqRes.json();
      rawText = (groqData.choices && groqData.choices[0] && groqData.choices[0].message && groqData.choices[0].message.content) || '';
    } else if (provider === 'local') {
      // Same OpenAI-compatible chat completions shape as the Groq branch
      // above — Ollama, LM Studio, llama.cpp's server (--api) and vLLM's
      // OpenAI server all speak this, so this one branch works regardless
      // of which of them you're running. IMPORTANT: this code runs inside
      // this Vercel function, i.e. in Vercel's cloud, NOT on your PC — for
      // this fetch() to reach a model on your own machine, LOCAL_LLM_BASE_URL
      // must be a URL Vercel's servers can actually reach (a tunnel, e.g.
      // Cloudflare Tunnel, if you want the deployed site to use it; plain
      // localhost only works if you're also running this function locally
      // via `vercel dev` — see "Using a local/on-premise model" in
      // PLATFORM_SETUP.md). No Authorization header is sent unless
      // LOCAL_LLM_API_KEY is set — most local servers don't check for one.
      const localRes = await fetch(`${(LOCAL_LLM_BASE_URL || LOCAL_LLM_BASE_URL_DEFAULT).replace(/\/$/, '')}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(LOCAL_LLM_API_KEY ? { Authorization: `Bearer ${LOCAL_LLM_API_KEY}` } : {}),
        },
        body: JSON.stringify({
          model: LOCAL_LLM_MODEL,
          max_tokens: 3000,
          temperature: 0.2,
          messages: [
            { role: 'system', content: SYSTEM_PROMPT },
            { role: 'user', content: projectText },
          ],
        }),
      });

      if (!localRes.ok) {
        const errText = await localRes.text().catch(() => '');
        await supabaseRest(`/projects?id=eq.${projectId}`, {
          method: 'PATCH',
          body: { status: 'error', updated_at: new Date().toISOString() },
          serviceKey: SUPABASE_SERVICE_ROLE_KEY,
          supabaseUrl: SUPABASE_URL,
        });
        return json(res, 502, { error: 'Analysis model request failed (local model)', detail: errText });
      }

      const localData = await localRes.json();
      rawText = (localData.choices && localData.choices[0] && localData.choices[0].message && localData.choices[0].message.content) || '';
    } else if (provider === 'bedrock') {
      // AWS Bedrock's Converse API — a unified request/response shape that
      // works the same way across every model family Bedrock hosts
      // (Llama, Mistral, Claude, etc.), so this doesn't need a
      // model-specific request body the way raw InvokeModel would. The SDK
      // handles AWS SigV4 request signing from AWS_ACCESS_KEY_ID/
      // AWS_SECRET_ACCESS_KEY — see the file header comment for the IAM
      // setup this needs.
      try {
        // require()'d here rather than at the top of the file, same
        // reasoning as pdf-parse above — a broken/missing dependency on
        // this path should only break the 'bedrock' provider, not every
        // provider. This one is a well-behaved pure-JS AWS package with no
        // native/optional dependencies, so it's a low-risk require, but
        // there's no upside to risking it at module-load time regardless.
        const { BedrockRuntimeClient, ConverseCommand } = require('@aws-sdk/client-bedrock-runtime');
        const bedrockClient = new BedrockRuntimeClient({
          region: AWS_REGION || BEDROCK_REGION_DEFAULT,
          credentials: { accessKeyId: AWS_ACCESS_KEY_ID, secretAccessKey: AWS_SECRET_ACCESS_KEY },
        });
        const bedrockRes = await bedrockClient.send(new ConverseCommand({
          modelId: BEDROCK_MODEL_ID || BEDROCK_MODEL_DEFAULT,
          system: [{ text: SYSTEM_PROMPT }],
          messages: [{ role: 'user', content: [{ text: projectText }] }],
          inferenceConfig: { maxTokens: 3000, temperature: 0.2 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
      } catch (bedrockErr) {
        await supabaseRest(`/projects?id=eq.${projectId}`, {
          method: 'PATCH',
          body: { status: 'error', updated_at: new Date().toISOString() },
          serviceKey: SUPABASE_SERVICE_ROLE_KEY,
          supabaseUrl: SUPABASE_URL,
        });
        return json(res, 502, {
          error: 'Analysis model request failed',
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
          system: SYSTEM_PROMPT,
          messages: [{ role: 'user', content: contentBlocks }],
        }),
      });

      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        await supabaseRest(`/projects?id=eq.${projectId}`, {
          method: 'PATCH',
          body: { status: 'error', updated_at: new Date().toISOString() },
          serviceKey: SUPABASE_SERVICE_ROLE_KEY,
          supabaseUrl: SUPABASE_URL,
        });
        return json(res, 502, { error: 'Analysis model request failed', detail: errText });
      }

      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || [])
        .map((b) => (b.type === 'text' ? b.text : ''))
        .join('');
    }

    let parsed;
    try {
      const cleaned = rawText.trim().replace(/^```json\s*/i, '').replace(/```$/, '');
      parsed = JSON.parse(cleaned);
    } catch (e) {
      await supabaseRest(`/projects?id=eq.${projectId}`, {
        method: 'PATCH',
        body: { status: 'error', updated_at: new Date().toISOString() },
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
        supabaseUrl: SUPABASE_URL,
      });
      return json(res, 502, { error: 'Could not parse analysis output', raw: rawText.slice(0, 2000) });
    }

    // Normalize / validate before persisting. Every text field comes in a
    // bilingual pair (_es/_en) since the SYSTEM_PROMPT above asks the model
    // for both at once — see migration_v40_bilingual_analysis.sql. dimensions/
    // gap_roadmap/financing_recommendations/summary (unsuffixed) are always
    // the Spanish version, matching every other row already on this
    // platform; the *_en variables are the English translation, persisted
    // to framework_analysis's _en columns so app/project.html can show
    // either one depending on the UI language (see
    // INAPlatform.localizeAnalysis() in assets/platform.js).
    const dimensions = {};
    const dimensionsEn = {};
    let sum = 0;
    DIMENSION_KEYS.forEach((key) => {
      const entry = (parsed.dimensions || {})[key] || {};
      const score = clampScore(entry.score);
      dimensions[key] = { score, rationale: String(entry.rationale_es || '').slice(0, 500) };
      dimensionsEn[key] = { score, rationale: String(entry.rationale_en || '').slice(0, 500) };
      sum += score;
    });
    const overallScore = parsed.overall_score != null
      ? clampScore(parsed.overall_score)
      : Math.round(sum / DIMENSION_KEYS.length);
    const stage = stageForScore(overallScore);

    const gapRoadmapSource = Array.isArray(parsed.gap_roadmap) ? parsed.gap_roadmap.slice(0, 6) : [];
    const gapRoadmap = gapRoadmapSource.map((it) => ({
      priority: ['high', 'medium', 'low'].includes((it.priority || '').toLowerCase()) ? it.priority.toLowerCase() : 'medium',
      action: String(it.action_es || '').slice(0, 300),
    }));
    const gapRoadmapEn = gapRoadmapSource.map((it) => ({
      priority: ['high', 'medium', 'low'].includes((it.priority || '').toLowerCase()) ? it.priority.toLowerCase() : 'medium',
      action: String(it.action_en || '').slice(0, 300),
    }));

    const financingSource = Array.isArray(parsed.financing_recommendations) ? parsed.financing_recommendations.slice(0, 4) : [];
    const financingRecommendations = financingSource.map((it) => ({
      mechanism: FINANCING_MECHANISMS.includes(it.mechanism) ? it.mechanism : String(it.mechanism || '').slice(0, 80),
      rationale: String(it.rationale_es || '').slice(0, 400),
    }));
    const financingRecommendationsEn = financingSource.map((it) => ({
      mechanism: FINANCING_MECHANISMS.includes(it.mechanism) ? it.mechanism : String(it.mechanism || '').slice(0, 80),
      rationale: String(it.rationale_en || '').slice(0, 400),
    }));

    const summary = String(parsed.summary_es || '').slice(0, 800);
    const summaryEn = String(parsed.summary_en || '').slice(0, 800);

    await supabaseRest('/framework_analysis', {
      method: 'POST',
      body: {
        project_id: projectId,
        user_id: user.id,
        overall_score: overallScore,
        stage,
        dimensions,
        gap_roadmap: gapRoadmap,
        financing_recommendations: financingRecommendations,
        summary,
        dimensions_en: dimensionsEn,
        gap_roadmap_en: gapRoadmapEn,
        financing_recommendations_en: financingRecommendationsEn,
        summary_en: summaryEn,
        raw_model_output: rawText.slice(0, 10000),
      },
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });

    // Since migration_v20_workflow_promote_demote.sql, projects.
    // readiness_stage is the workflow stage (Not Analyzed → Concept →
    // Early/Advanced Structuring → Investment Ready), moved only by
    // explicit entry/promote/demote/return actions — NOT by re-running
    // this analysis on a project that already has a stage. `stage` here
    // (the score-derived band) is always stored on the framework_analysis
    // row as a suggestion (app/project.html surfaces it to the advisor
    // next to the current stage — see renderAnalysis()'s stage-suggestion
    // notice); it's only ever written back onto the project itself in the
    // one case below, which mirrors submitManualAssessment()'s existing
    // "first time only" rule in assets/platform.js: if this project was
    // still Not Analyzed (readiness_stage null — only possible here when
    // an assigned advisor ran AI Analysis before any self-assessment, per
    // the guard above), completing its very first analysis is what enters
    // it into the pipeline, same as a first self-assessment would. It
    // always lands on Concept Stage (not the AI's suggested `stage`) so an
    // advisor still moves it forward deliberately, one step at a time,
    // using the suggestion as a guide rather than an auto-jump.
    const projectUpdate = { status: 'completed', updated_at: new Date().toISOString() };
    if (!project.readiness_stage) {
      projectUpdate.readiness_stage = 'Concept Stage';
    }
    await supabaseRest(`/projects?id=eq.${projectId}`, {
      method: 'PATCH',
      body: projectUpdate,
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });

    return json(res, 200, { ok: true, overall_score: overallScore, stage });
  } catch (err) {
    try {
      await supabaseRest(`/projects?id=eq.${projectId}`, {
        method: 'PATCH',
        body: { status: 'error', updated_at: new Date().toISOString() },
        serviceKey: SUPABASE_SERVICE_ROLE_KEY,
        supabaseUrl: SUPABASE_URL,
      });
    } catch (e2) { /* best effort */ }
    return json(res, 500, { error: 'Analysis failed', detail: String(err && err.message || err) });
  }
}

module.exports = handler;
// Vercel-specific per-function config — see the comment near the top of
// this file for why this matters (large-document analysis timing out).
module.exports.config = { maxDuration: 60 };
