#!/usr/bin/env node
/**
 * INA Platform — fully local server (no Vercel involved at all).
 *
 * Serves the exact same static site (index.html, app/, assets/) AND the two
 * AI endpoints (api/analyze-project.js, api/extract-template-data.js) from
 * one plain Node/Express process running on this machine. Run it with:
 *
 *   npm install
 *   cp .env.local.example .env.local   (then fill in the values)
 *   npm run local
 *
 * ...then open http://localhost:5050/app/dashboard.html (or whatever PORT
 * you set) in a browser. See "Running everything locally, without Vercel"
 * in PLATFORM_SETUP.md for the full walkthrough.
 *
 * WHY THIS WORKS WITHOUT TOUCHING assets/platform.js: platform.js's
 * analyzeProjectUrl()/extractTemplateDataUrl() only use the absolute
 * api.international-network-advisors.com URL when the page is being served
 * FROM the production Bluehost hostnames; everywhere else (including
 * localhost) they already fall back to a plain relative path
 * ('/api/analyze-project', '/api/extract-template-data'). Serving the site
 * and these two endpoints from the SAME origin (this server) means those
 * relative paths just resolve back to this same process — no CORS
 * configuration, no rewrites, no code changes needed anywhere else.
 *
 * The two api/*.js files are require()'d as-is, completely unmodified —
 * their handler(req, res) signature is already Vercel-serverless-function
 * shaped, which is also exactly an Express route handler's shape, so they
 * plug in directly. They stay fully deployable to Vercel too; this file is
 * purely an additional, parallel way to run the same code, entirely on your
 * own machine. It never touches the live site at
 * international-network-advisors.com, which keeps running independently on
 * Vercel/Bluehost regardless of whether you ever run this.
 *
 * What this does NOT remove: Supabase (authentication, the Postgres
 * database, file Storage) stays a separate cloud service either way — this
 * only takes Vercel and whichever cloud AI provider out of the picture in
 * favor of a model running on this PC via Ollama (or any other
 * OpenAI-compatible local server). Fully self-hosting Supabase too is a
 * much bigger, separate undertaking (Supabase does offer a self-hosted
 * Docker setup) — not part of this.
 */

const path = require('path');

// Loads .env.local if present (see .env.local.example) — silently does
// nothing if the file doesn't exist yet, so `node local-server.js` still
// runs (and clearly reports what's missing below) even before it's been
// set up.
require('dotenv').config({ path: path.join(__dirname, '.env.local') });

const express = require('express');

// Defaults to the local-model provider for THIS server specifically —
// override in .env.local (LLM_PROVIDER=anthropic/groq/bedrock/bedrock-mock)
// if you'd rather this local server use a cloud model for some reason.
if (!process.env.LLM_PROVIDER) process.env.LLM_PROVIDER = 'local';

const analyzeProjectHandler = require('./api/analyze-project');
const extractTemplateDataHandler = require('./api/extract-template-data');

const app = express();
const PORT = Number(process.env.PORT) || 5050;

app.use(express.json({ limit: '2mb' }));

// Never statically serve source/config files that shouldn't be reachable
// over HTTP, even though this server is only ever meant to be bound to
// localhost — cheap safety net in case it's ever tunneled despite the
// caveats in PLATFORM_SETUP.md ("Using a local/on-premise model").
app.use((req, res, next) => {
  if (/^\/(\.env|\.git\/|supabase\/|node_modules\/|package(-lock)?\.json|local-server\.js)/.test(req.path)) {
    return res.status(404).end();
  }
  next();
});

// The AI endpoints — same paths platform.js already calls as a relative
// path on any non-production hostname (see file header above).
app.post('/api/analyze-project', analyzeProjectHandler);
app.post('/api/extract-template-data', extractTemplateDataHandler);

// A handful of the same top-level redirects vercel.json defines in
// production, so old-style bookmarks/links behave the same locally.
const LEGACY_REDIRECTS = {
  '/login.html': '/app/login.html',
  '/register.html': '/app/register.html',
  '/dashboard.html': '/app/dashboard.html',
  '/new-project.html': '/app/new-project.html',
  '/project.html': '/app/project.html',
  '/app/security.html': '/app/profile.html',
  '/app/gestion-templates.html': '/app/roadmap-templates.html',
  '/app/new-gestion-template.html': '/app/new-roadmap-template.html',
  '/app/gestion-instance.html': '/app/roadmap-instance.html',
  '/app': '/app/index.html',
};
app.get(Object.keys(LEGACY_REDIRECTS), (req, res) => {
  res.redirect(301, LEGACY_REDIRECTS[req.path]);
});

// The static site itself — index.html, app/*.html, assets/*, etc. — same
// folder layout as what gets uploaded to Bluehost.
app.use(express.static(__dirname, { extensions: ['html'] }));

function missingEnvVars() {
  const missing = [];
  ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_ANON_KEY'].forEach((k) => {
    if (!process.env[k]) missing.push(k);
  });
  const provider = process.env.LLM_PROVIDER.toLowerCase();
  if (provider === 'local' && !process.env.LOCAL_LLM_MODEL) missing.push('LOCAL_LLM_MODEL');
  if (provider === 'anthropic' && !process.env.ANTHROPIC_API_KEY) missing.push('ANTHROPIC_API_KEY');
  if (provider === 'groq' && !process.env.GROQ_API_KEY) missing.push('GROQ_API_KEY');
  if (provider === 'bedrock' && (!process.env.AWS_ACCESS_KEY_ID || !process.env.AWS_SECRET_ACCESS_KEY)) {
    missing.push('AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY');
  }
  return missing;
}

app.listen(PORT, () => {
  console.log('');
  console.log(`INA Platform — running fully locally at http://localhost:${PORT}`);
  console.log(`  App:          http://localhost:${PORT}/app/dashboard.html`);
  console.log(`  AI provider:  ${process.env.LLM_PROVIDER}` + (process.env.LLM_PROVIDER === 'local'
    ? ` (${process.env.LOCAL_LLM_BASE_URL || 'http://localhost:11434/v1'}, model: ${process.env.LOCAL_LLM_MODEL || '(not set!)'})`
    : ''));

  const missing = missingEnvVars();
  if (missing.length) {
    console.log('');
    console.log('  ⚠ Missing/incomplete configuration — set these in .env.local (copy');
    console.log('    .env.local.example if you haven\'t yet):');
    missing.forEach((k) => console.log(`      - ${k}`));
  }
  console.log('');
});
