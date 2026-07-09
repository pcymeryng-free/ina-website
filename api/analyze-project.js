/**
 * INA Platform — /api/analyze-project
 * Vercel serverless function (Node.js runtime, no external dependencies —
 * uses built-in fetch so no `npm install` is required to deploy).
 *
 * Applies the INA Investment Readiness Index™ (Framework F2) and
 * Multilateral Finance Navigator™ (Framework F6) to a submitted project,
 * using the Anthropic Claude API, and writes the structured result to
 * Supabase (framework_analysis table).
 *
 * Required environment variables (set in Vercel → Project → Settings →
 * Environment Variables):
 *   ANTHROPIC_API_KEY        — your Anthropic API key
 *   SUPABASE_URL              — same value as in assets/platform.js
 *   SUPABASE_SERVICE_ROLE_KEY — Supabase service role key (server-only,
 *                               NEVER the anon key, NEVER exposed client-side)
 *   SUPABASE_ANON_KEY         — used only to validate the caller's session token
 *   CLAUDE_MODEL               — optional, defaults to "claude-sonnet-5"
 */

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
];

const SYSTEM_PROMPT = `You are the analysis engine behind two of INA's (International Network Advisors) proprietary frameworks, applied together to a single submitted project:

1. INVESTMENT READINESS INDEX™ (Framework F2): scores a digital infrastructure project 0–100 across 8 weighted dimensions: Legal & Regulatory Clarity, Technical Design Maturity, Financial Model Robustness, Sponsor Capacity, Market Demand Evidence, Environmental & Social Readiness, Risk Mitigation Coverage, and Governance & Reporting. Score bands: 0–25 Concept Stage, 26–50 Early Structuring, 51–75 Advanced Structuring, 76–100 Investment Ready.

2. MULTILATERAL FINANCE NAVIGATOR™ (Framework F6): reads the project's country, sector, size, maturity and risk profile, then recommends which financing mechanisms are the realistic fit, drawn ONLY from this list: Multilateral Development Banks, Development Finance Institutions, Project Finance, Public-Private Partnerships, Blended Finance, Guarantees & Credit Enhancement, Export Credit Agencies, Commercial & Institutional Capital.

You will be given a project's name, type, country and description, and possibly supporting documents. Assess honestly based only on the evidence provided — if information for a dimension is missing or unclear, score it conservatively low and say so in the rationale rather than assuming strength. Do not inflate scores. Be specific and reference concrete details from the project description in your rationales wherever possible, rather than generic boilerplate.

Respond with ONLY a single valid JSON object — no markdown code fences, no commentary before or after — matching exactly this shape:

{
  "overall_score": <integer 0-100>,
  "dimensions": {
    "legal_regulatory": {"score": <0-100>, "rationale": "<1-2 sentences, specific to this project>"},
    "technical_maturity": {"score": <0-100>, "rationale": "<...>"},
    "financial_robustness": {"score": <0-100>, "rationale": "<...>"},
    "sponsor_capacity": {"score": <0-100>, "rationale": "<...>"},
    "market_demand": {"score": <0-100>, "rationale": "<...>"},
    "environmental_social": {"score": <0-100>, "rationale": "<...>"},
    "risk_mitigation": {"score": <0-100>, "rationale": "<...>"},
    "governance_reporting": {"score": <0-100>, "rationale": "<...>"}
  },
  "gap_roadmap": [
    {"priority": "high|medium|low", "action": "<specific, actionable next step>"}
  ],
  "financing_recommendations": [
    {"mechanism": "<one of the 8 mechanisms listed above, verbatim>", "rationale": "<why it fits this specific project>"}
  ],
  "summary": "<2-3 sentence executive summary of overall readiness and the single most important next step>"
}

overall_score must be the weighted average of the 8 dimension scores (equal weighting is fine unless the project profile clearly warrants otherwise). gap_roadmap should have 3-6 items ordered by priority. financing_recommendations should have 2-4 items, each mechanism used at most once.`;

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
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

module.exports = async (req, res) => {
  if (req.method !== 'POST') {
    return json(res, 405, { error: 'Method not allowed' });
  }

  const {
    ANTHROPIC_API_KEY,
    SUPABASE_URL,
    SUPABASE_SERVICE_ROLE_KEY,
    SUPABASE_ANON_KEY,
    CLAUDE_MODEL,
  } = process.env;

  if (!ANTHROPIC_API_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY) {
    return json(res, 500, { error: 'Server misconfigured: missing required environment variables.' });
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
    if (project.user_id !== user.id) return json(res, 403, { error: 'Not your project' });

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

    // Build the Claude message content: project text + up to 5 documents
    // (PDFs/images sent natively, plain text files inlined, everything
    // else referenced by filename only).
    const contentBlocks = [];
    let projectText = `PROJECT NAME: ${project.name}\nPROJECT TYPE: ${project.project_type}\nCOUNTRY: ${project.country}\n\nDESCRIPTION:\n${project.description}`;

    const docsToInclude = (documents || []).slice(0, 5);
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
        if (fileBuffer.length <= 25 * 1024 * 1024) {
          contentBlocks.push({
            type: 'document',
            source: { type: 'base64', media_type: mediaType, data: fileBuffer.toString('base64') },
          });
        } else {
          skippedNotes.push(`${doc.file_name} (too large)`);
        }
      } else if (mediaType.startsWith('image/')) {
        contentBlocks.push({
          type: 'image',
          source: { type: 'base64', media_type: mediaType, data: fileBuffer.toString('base64') },
        });
      } else if (mediaType === 'text/plain') {
        projectText += `\n\n--- ATTACHED FILE: ${doc.file_name} ---\n${fileBuffer.toString('utf-8').slice(0, 8000)}`;
      }
    }

    if (skippedNotes.length) {
      projectText += `\n\n(Additional attached files not machine-readable in this analysis: ${skippedNotes.join(', ')})`;
    }

    contentBlocks.unshift({ type: 'text', text: projectText });

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
    const rawText = (anthropicData.content || [])
      .map((b) => (b.type === 'text' ? b.text : ''))
      .join('');

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

    // Normalize / validate before persisting.
    const dimensions = {};
    let sum = 0;
    DIMENSION_KEYS.forEach((key) => {
      const entry = (parsed.dimensions || {})[key] || {};
      const score = clampScore(entry.score);
      dimensions[key] = { score, rationale: String(entry.rationale || '').slice(0, 500) };
      sum += score;
    });
    const overallScore = parsed.overall_score != null
      ? clampScore(parsed.overall_score)
      : Math.round(sum / DIMENSION_KEYS.length);
    const stage = stageForScore(overallScore);

    const gapRoadmap = Array.isArray(parsed.gap_roadmap)
      ? parsed.gap_roadmap.slice(0, 6).map((it) => ({
          priority: ['high', 'medium', 'low'].includes((it.priority || '').toLowerCase()) ? it.priority.toLowerCase() : 'medium',
          action: String(it.action || '').slice(0, 300),
        }))
      : [];

    const financingRecommendations = Array.isArray(parsed.financing_recommendations)
      ? parsed.financing_recommendations.slice(0, 4).map((it) => ({
          mechanism: FINANCING_MECHANISMS.includes(it.mechanism) ? it.mechanism : String(it.mechanism || '').slice(0, 80),
          rationale: String(it.rationale || '').slice(0, 400),
        }))
      : [];

    const summary = String(parsed.summary || '').slice(0, 800);

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
        raw_model_output: rawText.slice(0, 10000),
      },
      serviceKey: SUPABASE_SERVICE_ROLE_KEY,
      supabaseUrl: SUPABASE_URL,
    });

    await supabaseRest(`/projects?id=eq.${projectId}`, {
      method: 'PATCH',
      // readiness_stage is denormalized onto projects (not just
      // framework_analysis) so the dashboard grid's status column/filter
      // can show the framework-derived stage without an extra join.
      body: { status: 'completed', readiness_stage: stage, updated_at: new Date().toISOString() },
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
};
