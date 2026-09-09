/**
 * INA Platform — /api/generate-proposal
 * Vercel serverless function (Node.js runtime, no external dependencies for
 * every path except pdf-parse — same lazy-require pattern as
 * api/analyze-project.js, see below).
 *
 * Drafts the four narrative chapters of the Investment Proposal document
 * (Introduction/Executive Summary, Technical Description, Benefits, and a
 * Planning/Implementation narrative) — the full, formal document meant to
 * be presented to financial institutions (multilateral development banks,
 * USTDA, DFC, Universal Service Funds, etc.) to request financing. This is
 * a SEPARATE, longer document from the existing "Descargar PDF" project
 * summary (generateProjectPdf() in app/project.html); this endpoint feeds
 * app/project.html's "Propuesta de Financiamiento" editor section and its
 * generateProposalPdf() PDF generator.
 *
 * Unlike /api/analyze-project.js, this endpoint does NOT write anything to
 * Supabase itself — Pablo's explicit choice: the AI produces an EDITABLE
 * DRAFT that the user reviews (and can rewrite freely) before an explicit
 * Save persists it via INAPlatform.updateProjectProposal(). So this
 * function is a pure "read project context → call the model → return the
 * draft" request; no projects.status side effects, no gating on
 * readiness_stage (drafting proposal text is a writing aid available at any
 * project stage, not part of the Investment Readiness workflow).
 *
 * Required environment variables — SAME as api/analyze-project.js (see that
 * file's header comment for the full walkthrough of every LLM_PROVIDER
 * option: 'anthropic' default, 'groq', 'bedrock', 'bedrock-mock', 'local').
 * Nothing new to configure if AI Analysis already works on this deployment.
 *   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY
 *   ANTHROPIC_API_KEY / CLAUDE_MODEL (default provider)
 *   LLM_PROVIDER, GROQ_API_KEY, GROQ_MODEL
 *   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, BEDROCK_MODEL_ID
 *   LOCAL_LLM_BASE_URL, LOCAL_LLM_MODEL, LOCAL_LLM_API_KEY
 */

const GROQ_MODEL_DEFAULT = 'openai/gpt-oss-120b';
const BEDROCK_MODEL_DEFAULT = 'meta.llama3-3-70b-instruct-v1:0';
const BEDROCK_REGION_DEFAULT = 'us-east-1';
const LOCAL_LLM_BASE_URL_DEFAULT = 'http://localhost:11434/v1';

const SYSTEM_PROMPT = `You are a senior infrastructure-finance writer at INA (International Network Advisors), drafting chapters of a formal Investment Proposal document. This document will be presented to financial institutions — multilateral development banks (e.g. IDB), development finance institutions (USTDA, DFC), Universal Service Funds, or commercial/institutional capital — to request financing for the project described to you. Write persuasively but honestly: ground every claim in the actual project data given, never invent figures, and flag genuine gaps as areas the sponsor should still address rather than glossing over them.

You will be given the project's core data (name, type, country, description, budget, duration), its financing mix so far, any Investment Readiness Index™ analysis on file (scores/rationale across 8 dimensions), its risk register, its active implementation roadmaps, and possibly supporting documents. Draft FOUR chapters:

1. INTRODUCTION / EXECUTIVE SUMMARY — 3-5 paragraphs. Frame the project, its strategic rationale, its sponsor, and why it merits financing. This is what a reviewer reads first — it should stand alone.
2. TECHNICAL DESCRIPTION — 3-5 paragraphs. Describe the technical scope, approach and key specifications, drawing on the project type and description given. Be specific to THIS project, not generic boilerplate about the sector.
3. BENEFITS — 2-4 paragraphs. Expected impact: beneficiaries reached, service improvement, economic/social value, alignment with public policy objectives where relevant. Use the beneficiary count if given.
4. PLANNING NARRATIVE — 2-3 paragraphs. Describe the implementation approach and phasing at a narrative level (the document will separately list the concrete roadmap steps already on file — don't repeat them verbatim, synthesize the approach instead).

INA's platform serves both Spanish- and English-speaking users, so every chapter must be written TWICE — once in Spanish (the "_es" field) and once in English (the "_en" field). Write natural, idiomatic prose in each language (not a literal translation of one from the other), but keep the underlying content and claims identical in both.

Respond with ONLY a single valid JSON object — no markdown code fences, no commentary before or after — matching exactly this shape:

{
  "introduction_es": "<...>", "introduction_en": "<...>",
  "technical_description_es": "<...>", "technical_description_en": "<...>",
  "benefits_es": "<...>", "benefits_en": "<...>",
  "planning_narrative_es": "<...>", "planning_narrative_en": "<...>"
}`;

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

/* Same allowlist as api/analyze-project.js — see that file's comment. */
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

/* Builds the plain-text project context block sent to the model — every
   piece of REAL data on file, so the draft is grounded rather than
   generic. Kept as one text blob (rather than Anthropic content blocks)
   even on the Anthropic path, unlike analyze-project.js, since attached
   documents here are optional supporting color, not the primary input. */
function buildContextText(project, { programs, fsu, risks, roadmaps, analysis }) {
  let text = `PROJECT NAME: ${project.name}\nPROJECT TYPE: ${project.project_type}\nCOUNTRY: ${project.country}\n\nDESCRIPTION:\n${project.description}`;

  if (project.beneficiary_count != null) text += `\n\nBENEFICIARY COUNT: ${project.beneficiary_count}`;
  if (project.budget_amount_usd != null) text += `\nTOTAL BUDGET (USD): ${project.budget_amount_usd}`;
  else if (project.budget_amount != null) text += `\nTOTAL BUDGET (ARS): ${project.budget_amount}`;
  if (project.duration_value != null) text += `\nESTIMATED DURATION: ${project.duration_value} ${project.duration_unit || ''}`;
  if (project.generating_entity_name) text += `\nGENERATING/SPONSORING ENTITY: ${project.generating_entity_name} (${project.generating_entity_type || 'n/a'})`;

  if (programs && programs.length) {
    text += '\n\nFINANCING PROGRAMS APPLIED TO:\n' + programs.map((r) => {
      const p = r.programs || {};
      const share = r.financing_percentage != null ? `${r.financing_percentage}%` : (r.financing_amount != null ? String(r.financing_amount) : 'share not specified');
      return `- ${p.name || 'Unnamed program'} (${p.funding_stage || 'n/a'}) — ${share}`;
    }).join('\n');
  }
  if (project.fsu_amount_usd != null || project.fsu_amount != null || project.fsu_scope) {
    text += `\n\nUNIVERSAL SERVICE FUND (FSU) FINANCING: amount ${project.fsu_amount_usd != null ? project.fsu_amount_usd + ' USD' : (project.fsu_amount != null ? project.fsu_amount + ' ARS' : 'n/a')}${project.fsu_scope ? `, scope: ${project.fsu_scope}` : ''}`;
  }
  if (fsu) {
    text += `\n\nFSU SCORING (Res. ENACOM 359/2025): total ${fsu.score_total}/100`;
  }

  if (analysis) {
    text += `\n\nINVESTMENT READINESS INDEX™ ANALYSIS ON FILE: overall score ${analysis.overall_score}/100, stage: ${analysis.stage}. Summary: ${analysis.summary || ''}`;
    const dims = analysis.dimensions || {};
    Object.keys(dims).forEach((k) => {
      const d = dims[k];
      if (d && d.rationale) text += `\n- ${k}: ${d.score}/100 — ${d.rationale}`;
    });
  }

  if (risks && risks.length) {
    text += '\n\nRISK REGISTER:\n' + risks.map((r) => `- [${r.category}, score ${r.risk_score}/25] ${r.title}${r.mitigation_measures ? ` — mitigation: ${r.mitigation_measures}` : ''}`).join('\n');
  }

  if (roadmaps && roadmaps.length) {
    text += '\n\nACTIVE IMPLEMENTATION ROADMAPS:\n' + roadmaps.map((g) => `- ${g.name} (performed by ${g.performing_entity_name}, status: ${g.status})`).join('\n');
  }

  return text;
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
    return json(res, 500, { error: `Server misconfigured: missing required environment variables (provider: ${provider}).` });
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
      serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
    });
    const project = projects && projects[0];
    if (!project) return json(res, 404, { error: 'Project not found' });

    let isAdminCaller = false;
    try {
      const callerProfiles = await supabaseRest(`/profiles?id=eq.${user.id}&select=role`, {
        serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL,
      });
      isAdminCaller = !!(callerProfiles && callerProfiles[0] && callerProfiles[0].role === 'admin');
    } catch (e) { isAdminCaller = false; }

    // Same allowed-callers rule as AI Analysis — owner, the advisor who has
    // taken this project, or any admin. No readiness_stage gate (see file
    // header comment): drafting proposal text is available at any stage.
    const isOwner = project.user_id === user.id;
    const isAssignedAdvisor = !!project.assigned_advisor_id && project.assigned_advisor_id === user.id;
    if (!isOwner && !isAssignedAdvisor && !isAdminCaller) return json(res, 403, { error: 'Not your project' });

    const [documents, programs, fsuRows, risks, roadmaps, analysisRows] = await Promise.all([
      supabaseRest(`/project_documents?project_id=eq.${projectId}&select=*`, { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL }).catch(() => []),
      supabaseRest(`/project_programs?project_id=eq.${projectId}&select=*,programs(name,funding_stage)`, { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL }).catch(() => []),
      supabaseRest(`/fsu_scoring?project_id=eq.${projectId}&select=*&limit=1`, { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL }).catch(() => []),
      supabaseRest(`/project_risks?project_id=eq.${projectId}&select=*`, { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL }).catch(() => []),
      supabaseRest(`/roadmap_instances?project_id=eq.${projectId}&select=name,performing_entity_name,status`, { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL }).catch(() => []),
      supabaseRest(`/framework_analysis?project_id=eq.${projectId}&select=*&order=created_at.desc&limit=1`, { serviceKey: SUPABASE_SERVICE_ROLE_KEY, supabaseUrl: SUPABASE_URL }).catch(() => []),
    ]);

    let contextText = buildContextText(project, {
      programs, fsu: fsuRows && fsuRows[0], risks, roadmaps, analysis: analysisRows && analysisRows[0],
    });

    // Up to 3 attached documents, text-extracted (PDFs) or inlined (plain
    // text) as supporting color — same pdf-parse 1.1.4, lazily-required
    // pattern as api/analyze-project.js (see that file's header comment for
    // why 1.1.4 specifically, not 2.x). Images aren't read here at all
    // (this endpoint doesn't need vision — the narrative chapters are
    // grounded in the structured data above first and foremost).
    const skippedNotes = [];
    for (const doc of (documents || []).slice(0, 3)) {
      const ext = (doc.file_name.split('.').pop() || '').toLowerCase();
      if (ext === 'pdf') {
        const fileBuffer = await downloadStorageFile(doc.storage_path, { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
        if (!fileBuffer) { skippedNotes.push(doc.file_name); continue; }
        if (fileBuffer.length > 25 * 1024 * 1024) { skippedNotes.push(`${doc.file_name} (too large)`); continue; }
        try {
          const pdfParseFn = require('pdf-parse');
          const extracted = await pdfParseFn(fileBuffer);
          const text = (extracted.text || '').trim();
          if (text) contextText += `\n\n--- ATTACHED FILE: ${doc.file_name} ---\n${text.slice(0, 3000)}`;
          else skippedNotes.push(`${doc.file_name} (no extractable text)`);
        } catch (e) { skippedNotes.push(`${doc.file_name} (couldn't parse PDF)`); }
      } else if (['txt', 'md', 'csv'].includes(ext)) {
        const fileBuffer = await downloadStorageFile(doc.storage_path, { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
        if (fileBuffer) contextText += `\n\n--- ATTACHED FILE: ${doc.file_name} ---\n${fileBuffer.toString('utf-8').slice(0, 6000)}`;
        else skippedNotes.push(doc.file_name);
      }
    }
    if (skippedNotes.length) contextText += `\n\n(Additional attached files not read for this draft: ${skippedNotes.join(', ')})`;

    let rawText;
    if (provider === 'bedrock-mock') {
      rawText = JSON.stringify({
        introduction_es: `[SIMULADO — no se llamó a ningún modelo] Borrador de introducción de ejemplo para "${project.name}".`,
        introduction_en: `[SIMULATED — no model was called] Placeholder introduction draft for "${project.name}".`,
        technical_description_es: '[SIMULADO] Descripción técnica de ejemplo.',
        technical_description_en: '[SIMULATED] Placeholder technical description.',
        benefits_es: '[SIMULADO] Beneficios de ejemplo.',
        benefits_en: '[SIMULATED] Placeholder benefits.',
        planning_narrative_es: '[SIMULADO] Narrativa de planificación de ejemplo.',
        planning_narrative_en: '[SIMULATED] Placeholder planning narrative.',
      });
    } else if (provider === 'groq' || provider === 'local') {
      const url = provider === 'groq'
        ? 'https://api.groq.com/openai/v1/chat/completions'
        : `${(LOCAL_LLM_BASE_URL || LOCAL_LLM_BASE_URL_DEFAULT).replace(/\/$/, '')}/chat/completions`;
      const apiKey = provider === 'groq' ? GROQ_API_KEY : LOCAL_LLM_API_KEY;
      const model = provider === 'groq' ? (GROQ_MODEL || GROQ_MODEL_DEFAULT) : LOCAL_LLM_MODEL;
      const chatRes = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...(apiKey ? { Authorization: `Bearer ${apiKey}` } : {}) },
        body: JSON.stringify({
          model, max_tokens: 4000, temperature: 0.4,
          messages: [{ role: 'system', content: SYSTEM_PROMPT }, { role: 'user', content: contextText }],
        }),
      });
      if (!chatRes.ok) {
        const errText = await chatRes.text().catch(() => '');
        console.error(`[generate-proposal] projectId=${projectId} ${provider} request failed (status ${chatRes.status}):`, errText);
        return json(res, 502, { error: 'Proposal draft model request failed', detail: errText });
      }
      const chatData = await chatRes.json();
      rawText = (chatData.choices && chatData.choices[0] && chatData.choices[0].message && chatData.choices[0].message.content) || '';
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
          messages: [{ role: 'user', content: [{ text: contextText }] }],
          inferenceConfig: { maxTokens: 4000, temperature: 0.4 },
        }));
        const outputContent = (bedrockRes.output && bedrockRes.output.message && bedrockRes.output.message.content) || [];
        rawText = outputContent.map((b) => b.text || '').join('');
      } catch (bedrockErr) {
        console.error(`[generate-proposal] projectId=${projectId} Bedrock request failed:`, bedrockErr);
        return json(res, 502, { error: 'Proposal draft model request failed', detail: String((bedrockErr && bedrockErr.message) || bedrockErr) });
      }
    } else {
      const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
        body: JSON.stringify({
          model: CLAUDE_MODEL || 'claude-sonnet-5',
          max_tokens: 4000,
          system: SYSTEM_PROMPT,
          messages: [{ role: 'user', content: contextText }],
        }),
      });
      if (!anthropicRes.ok) {
        const errText = await anthropicRes.text().catch(() => '');
        console.error(`[generate-proposal] projectId=${projectId} Anthropic request failed (status ${anthropicRes.status}):`, errText);
        return json(res, 502, { error: 'Proposal draft model request failed', detail: errText });
      }
      const anthropicData = await anthropicRes.json();
      rawText = (anthropicData.content || []).map((b) => (b.type === 'text' ? b.text : '')).join('');
    }

    let parsed;
    try {
      const withoutThink = rawText.replace(/^\s*<think>[\s\S]*?<\/think>\s*/i, '');
      const cleaned = withoutThink.trim().replace(/^```json\s*/i, '').replace(/```$/, '');
      parsed = JSON.parse(cleaned);
    } catch (e) {
      console.error(`[generate-proposal] projectId=${projectId} provider=${provider} could not parse model output as JSON:`, e, '\nraw output (first 2000 chars):', rawText.slice(0, 2000));
      return json(res, 502, { error: 'Could not parse proposal draft output', raw: rawText.slice(0, 2000) });
    }

    const field = (key) => String(parsed[key] || '').slice(0, 6000);
    return json(res, 200, {
      ok: true,
      introduction_es: field('introduction_es'),
      introduction_en: field('introduction_en'),
      technical_description_es: field('technical_description_es'),
      technical_description_en: field('technical_description_en'),
      benefits_es: field('benefits_es'),
      benefits_en: field('benefits_en'),
      planning_narrative_es: field('planning_narrative_es'),
      planning_narrative_en: field('planning_narrative_en'),
    });
  } catch (err) {
    console.error(`[generate-proposal] projectId=${projectId} unhandled error:`, err);
    return json(res, 500, { error: 'Proposal draft generation failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 60 };
