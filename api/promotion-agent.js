/**
 * INA Platform — /api/promotion-agent
 * Vercel serverless function (Node.js runtime) — same lazy-require /
 * multi-provider pattern as api/analyze-project.js and
 * api/recommend-financing.js.
 *
 * Pablo (sep 2026): "estaría bueno que haya un agente de AI que analice los
 * datos del proyecto y que lo habilite a ser promovido o lo condicione
 * comentando cuales son los requisitos que no cumple." This is that agent.
 * "Reglas + LLM combinados" (Pablo's explicit choice, AskUserQuestion): the
 * agent first re-evaluates the SAME deterministic thresholds as
 * INAPlatform.evaluatePromotionRequirements() (public.promotion_requirements
 * — min_analysis_score / require_mandatory_documents /
 * min_financing_coverage_pct / require_risk_matrix), reimplemented here in
 * plain Node for the same reason computeFinancingCoverage() is duplicated in
 * api/recommend-financing.js (this file can't import the browser module).
 * Those deterministic checks are a hard floor: if any fails, the verdict is
 * NOT eligible no matter what the model thinks. If all deterministic checks
 * pass, the LLM then adds a qualitative pass — it can still CONDITION the
 * project (eligible=false) if it spots something the numeric thresholds
 * miss (e.g. a documented-but-clearly-inadequate risk matrix, a financing
 * mix that's numerically sufficient but structurally fragile), explaining
 * why in unmet-style notes. This makes the rules a necessary-but-not-
 * sufficient gate, matching "reglas + LLM combinados" rather than either
 * one alone.
 *
 * Every run is persisted to public.promotion_agent_runs (never overwritten
 * — project.html shows the run history), unlike financing_recommendations'
 * single-row-per-project upsert.
 *
 * Required environment variables: same as api/recommend-financing.js
 * (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY, LLM_PROVIDER
 * + per-provider credentials) — no new env vars if AI Analysis / Financing
 * Recommendation are already configured.
 */

const GROQ_MODEL_DEFAULT = 'openai/gpt-oss-120b';
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';
const MODEL_MAX_TOKENS = 2000;

// Mirrors assets/platform.js's STAGE_ORDER — kept duplicated here (Node
// can't import the browser module), same tradeoff already accepted for
// computeFinancingCoverage()/isFsuFinancingEntity() in recommend-financing.js.
const STAGE_ORDER = ['Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'];

// Mirrors assets/platform.js's MANDATORY_DOCUMENT_TYPES.
const MANDATORY_DOCUMENT_TYPES = ['technical', 'financial'];

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

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

// Re-implementation of INAPlatform.computeFinancingCoverage() — see
// api/recommend-financing.js's identical function for the full rationale
// (FSU double-counting fix, etc.). Kept in lockstep with that copy.
function isFsuFinancingEntity(value) {
  return !!value && String(value).trim().toLowerCase() === 'enacom-fsu';
}
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
      pct: effectivePct(row.financing_percentage, row.financing_amount),
      isFsu: isFsuFinancingEntity(row.programs.financing_entity),
    }));
  const fsuProgramShares = programShares.filter((s) => s.isFsu);
  const fsuProgramsPct = fsuProgramShares.reduce((sum, s) => sum + s.pct, 0);
  const fsuPct = fsuProgramShares.length
    ? fsuProgramsPct
    : (project ? effectivePct(project.fsu_percentage, project.fsu_amount) : 0);
  const programsPct = programShares.reduce((sum, s) => sum + (s.isFsu ? 0 : s.pct), 0);
  return { totalPct: fsuPct + otherPct + programsPct };
}

// Deterministic evaluation — mirrors INAPlatform.evaluatePromotionRequirements().
function evaluateRules(project, toStage, requirement, { analysis, documents, coverage, riskCount }) {
  const unmet = [];
  if (!requirement) return unmet; // no row configured for this transition = no requirements

  const score = analysis && analysis.overall_score != null ? Number(analysis.overall_score) : null;
  if (requirement.min_analysis_score != null && (score == null || score < requirement.min_analysis_score)) {
    unmet.push({ key: 'min_analysis_score', threshold: requirement.min_analysis_score, actual: score });
  }

  const docTypesPresent = new Set((documents || []).map((d) => d.document_type));
  const missingDocTypes = MANDATORY_DOCUMENT_TYPES.filter((t) => !docTypesPresent.has(t));
  if (requirement.require_mandatory_documents && missingDocTypes.length) {
    unmet.push({ key: 'require_mandatory_documents', missingDocumentTypes: missingDocTypes });
  }

  if (requirement.min_financing_coverage_pct != null && coverage.totalPct < requirement.min_financing_coverage_pct) {
    unmet.push({ key: 'min_financing_coverage_pct', threshold: requirement.min_financing_coverage_pct, actual: coverage.totalPct });
  }

  if (requirement.require_risk_matrix && riskCount === 0) {
    unmet.push({ key: 'require_risk_matrix' });
  }

  return unmet;
}

function buildSystemPrompt() {
  return `You are a project-structuring reviewer for INA (International Network Advisors), helping ENACOM Argentina's advisors decide whether a digital-infrastructure project is genuinely ready to be promoted to its next readiness stage (Concept Stage → Early Structuring → Advanced Structuring → Investment Ready).

You will be given the project's profile, its latest framework analysis score, its attached document categories, its financing coverage, its risk matrix, and the list of deterministic requirement checks that ALREADY failed (if any) according to the platform's configured thresholds.

Your task is NOT to re-check those deterministic thresholds — they're authoritative and already computed. Your task is to add a qualitative, structural judgment on top of them: even when every numeric threshold is met, is there something about this specific project that means it isn't really ready yet (e.g. a risk matrix that's present but clearly superficial for a project of this size/complexity, a financing mix that adds up numerically but relies on an instrument that doesn't fit this project type, a documented budget or scope that looks internally inconsistent)? Conversely, if a deterministic check failed only marginally and the rest of the project is very strong, you may still say so in your notes — but you cannot override eligibility from false to true (deterministic failures always block promotion regardless of your opinion).

Respond with ONLY a single valid JSON object — no markdown code fences, no commentary — in this exact shape:
{
  "qualitative_pass": <boolean — true unless you find a genuine structural concern beyond the deterministic checks>,
  "concerns_es": ["<spanish, one short sentence per concern, empty array if qualitative_pass is true>"],
  "concerns_en": ["<english, one short sentence per concern, empty array if qualitative_pass is true>"],
  "notes_es": "<1-3 sentences overall qualitative assessment, spanish>",
  "notes_en": "<1-3 sentences overall qualitative assessment, english>"
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

    // Same permission check as recommend-financing.js: owner, assigned
    // advisor, or any admin.
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

    const currentStage = project.readiness_stage;
    const idx = currentStage ? STAGE_ORDER.indexOf(currentStage) : -1;
    if (idx === -1 || idx === STAGE_ORDER.length - 1) {
      return json(res, 400, {
        error: currentStage
          ? 'Project is already at the final stage — nothing to promote.'
          : "Project hasn't completed the owner's self-assessment yet (readiness_stage is still null).",
      });
    }
    const fromStage = currentStage;
    const toStage = STAGE_ORDER[idx + 1];

    const [requirementsRows, analysisRows, documents, programRows, risks] = await Promise.all([
      supabaseRest(`/promotion_requirements?from_stage=eq.${encodeURIComponent(fromStage)}&to_stage=eq.${encodeURIComponent(toStage)}&select=*`, {
        serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
      }),
      supabaseRest(`/framework_analysis?project_id=eq.${projectId}&select=overall_score,source,created_at&order=created_at.desc&limit=1`, {
        serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
      }),
      supabaseRest(`/project_documents?project_id=eq.${projectId}&select=document_type`, {
        serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
      }),
      supabaseRest(`/project_programs?project_id=eq.${projectId}&select=financing_percentage,financing_amount,programs(funding_stage,financing_entity)`, {
        serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
      }),
      supabaseRest(`/project_risks?project_id=eq.${projectId}&select=id`, {
        serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
      }),
    ]);

    const requirement = (requirementsRows && requirementsRows[0]) || null;
    const analysis = (analysisRows && analysisRows[0]) || null;
    const coverage = computeFinancingCoverage(project, programRows || []);
    const riskCount = (risks || []).length;
    const docTypesPresent = new Set((documents || []).map((d) => d.document_type));
    const missingDocTypes = MANDATORY_DOCUMENT_TYPES.filter((t) => !docTypesPresent.has(t));

    const unmetRules = evaluateRules(project, toStage, requirement, { analysis, documents, coverage, riskCount });
    const rulesPass = unmetRules.length === 0;

    const projectSummary = {
      project_type: project.project_type,
      readiness_stage: fromStage,
      target_stage: toStage,
      budget_amount: project.budget_amount,
      complexity: project.complexity,
      technical_criticality: project.technical_criticality,
      analysis_overall_score: analysis ? analysis.overall_score : null,
      analysis_source: analysis ? analysis.source : null,
      document_types_present: Array.from(docTypesPresent),
      missing_mandatory_document_types: missingDocTypes,
      financing_coverage_pct: coverage.totalPct,
      risk_count: riskCount,
      requirement_thresholds: requirement ? {
        min_analysis_score: requirement.min_analysis_score,
        require_mandatory_documents: requirement.require_mandatory_documents,
        min_financing_coverage_pct: requirement.min_financing_coverage_pct,
        require_risk_matrix: requirement.require_risk_matrix,
      } : null,
      deterministic_unmet_requirements: unmetRules,
    };

    const systemPrompt = buildSystemPrompt();
    const userContent = `PROJECT + DETERMINISTIC CHECK RESULTS (JSON):\n${JSON.stringify(projectSummary)}`;

    let rawText;
    if (provider === 'bedrock-mock') {
      rawText = JSON.stringify({
        qualitative_pass: true,
        concerns_es: [],
        concerns_en: [],
        notes_es: '[SIMULADO] Evaluación cualitativa de ejemplo, sin llamada a un modelo real.',
        notes_en: '[SIMULATED] Example qualitative assessment, no real model call made.',
      });
    } else if (provider === 'groq') {
      const r = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${GROQ_API_KEY}` },
        body: JSON.stringify({
          model: GROQ_MODEL || GROQ_MODEL_DEFAULT,
          max_tokens: MODEL_MAX_TOKENS,
          temperature: 0,
          messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userContent }],
        }),
      });
      if (!r.ok) {
        const errText = await r.text().catch(() => '');
        console.error(`[promotion-agent] Groq request failed (status ${r.status}):`, errText);
        return json(res, 502, { error: 'Promotion agent model request failed', detail: errText });
      }
      const d = await r.json();
      rawText = (d.choices && d.choices[0] && d.choices[0].message && d.choices[0].message.content) || '';
    } else if (provider === 'local') {
      const r = await fetch(`${(LOCAL_LLM_BASE_URL || LOCAL_LLM_BASE_URL_DEFAULT).replace(/\/$/, '')}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(LOCAL_LLM_API_KEY ? { Authorization: `Bearer ${LOCAL_LLM_API_KEY}` } : {}),
        },
        body: JSON.stringify({
          model: LOCAL_LLM_MODEL,
          max_tokens: MODEL_MAX_TOKENS,
          temperature: 0,
          messages: [{ role: 'system', content: systemPrompt }, { role: 'user', content: userContent }],
        }),
      });
      if (!r.ok) {
        const errText = await r.text().catch(() => '');
        console.error(`[promotion-agent] local model request failed (status ${r.status}):`, errText);
        return json(res, 502, { error: 'Promotion agent model request failed (local model)', detail: errText });
      }
      const d = await r.json();
      rawText = (d.choices && d.choices[0] && d.choices[0].message && d.choices[0].message.content) || '';
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
        console.error('[promotion-agent] Bedrock request failed:', bedrockErr);
        return json(res, 502, { error: 'Promotion agent model request failed', detail: String((bedrockErr && bedrockErr.message) || bedrockErr) });
      }
    } else {
      const r = await fetch('https://api.anthropic.com/v1/messages', {
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
      if (!r.ok) {
        const errText = await r.text().catch(() => '');
        console.error(`[promotion-agent] Anthropic request failed (status ${r.status}):`, errText);
        return json(res, 502, { error: 'Promotion agent model request failed', detail: errText });
      }
      const d = await r.json();
      rawText = (d.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
    }

    let parsed;
    try {
      const withoutThink = rawText.replace(/^\s*<think>[\s\S]*?<\/think>\s*/i, '');
      let cleaned = withoutThink.trim().replace(/^```json\s*/i, '').replace(/```$/, '').trim();
      const firstBrace = cleaned.indexOf('{');
      const lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace !== -1 && lastBrace > firstBrace) {
        cleaned = cleaned.slice(firstBrace, lastBrace + 1);
      }
      parsed = JSON.parse(cleaned);
    } catch (e) {
      console.error('[promotion-agent] could not parse model output as JSON:', e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse promotion agent output', raw: rawText.slice(0, 2000) });
    }

    const qualitativePass = parsed.qualitative_pass !== false;
    // Deterministic failures always win — the LLM's qualitative_pass can
    // only ever CONDITION an otherwise-eligible project, never clear one
    // that already failed a hard threshold (see buildSystemPrompt()).
    const eligible = rulesPass && qualitativePass;

    const concernsEs = Array.isArray(parsed.concerns_es) ? parsed.concerns_es.map((c) => String(c).slice(0, 500)) : [];
    const concernsEn = Array.isArray(parsed.concerns_en) ? parsed.concerns_en.map((c) => String(c).slice(0, 500)) : [];
    const notesEs = [String(parsed.notes_es || '').slice(0, 1500), ...concernsEs].filter(Boolean).join(' ');
    const notesEn = [String(parsed.notes_en || parsed.notes_es || '').slice(0, 1500), ...concernsEn].filter(Boolean).join(' ');

    const payload = {
      project_id: projectId,
      from_stage: fromStage,
      to_stage: toStage,
      eligible,
      unmet_requirements: unmetRules.map((u) => u.key),
      notes: notesEs || null,
      notes_en: notesEn || null,
      raw_model_output: rawText.slice(0, 8000),
      run_by: user.id,
    };

    const saved = await supabaseRest('/promotion_agent_runs', {
      method: 'POST',
      body: payload,
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });

    return json(res, 200, { ok: true, run: (saved && saved[0]) || payload });
  } catch (err) {
    console.error('[promotion-agent] unhandled error:', err);
    return json(res, 500, { error: 'Promotion agent failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 60 };
