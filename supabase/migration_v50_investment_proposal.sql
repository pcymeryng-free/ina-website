-- ============================================================================
-- Migration v50: Investment Proposal document — editable AI-drafted
-- narrative chapters (Introduction, Technical Description, Benefits,
-- Planning) that feed the new "Propuesta de Financiamiento (PDF)" — the
-- full, formal document meant to be presented to financial institutions
-- (IDB, USTDA, DFC, Universal Service Fund, etc.) to request financing.
-- Distinct from the existing "Descargar PDF" (internal project summary
-- report, generateProjectPdf() in app/project.html) — this is a new,
-- separate, longer document (generateProposalPdf()).
--
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run. Safe to run more than once
-- ("if not exists" throughout).
--
-- Bilingual pattern: same as migration_v40_bilingual_analysis.sql — each
-- narrative field has an unsuffixed (Spanish) column and an "_en" (English)
-- column, both kept in sync from a single AI drafting call (see
-- api/generate-proposal.js), and both directly editable by the user
-- afterward (see app/project.html's Investment Proposal section). Plain
-- `text`, not JSON — this is free-form prose, not structured data.
-- ============================================================================

alter table public.projects
  add column if not exists proposal_introduction text,
  add column if not exists proposal_introduction_en text,
  add column if not exists proposal_technical_description text,
  add column if not exists proposal_technical_description_en text,
  add column if not exists proposal_benefits text,
  add column if not exists proposal_benefits_en text,
  add column if not exists proposal_planning_narrative text,
  add column if not exists proposal_planning_narrative_en text,
  -- Set whenever any of the 8 fields above is saved (AI draft accepted, or
  -- a manual edit) — shown in the UI ("Última actualización: ...") so it's
  -- clear whether the proposal content is stale relative to the project's
  -- other data (financing mix, risks, roadmap) that the PDF also pulls in
  -- live at download time.
  add column if not exists proposal_updated_at timestamptz;

comment on column public.projects.proposal_introduction is 'Investment Proposal document — Introduction/Executive Summary chapter (Spanish). AI-drafted (api/generate-proposal.js), user-editable before saving. See generateProposalPdf() in app/project.html.';
comment on column public.projects.proposal_technical_description is 'Investment Proposal document — Technical Description chapter (Spanish).';
comment on column public.projects.proposal_benefits is 'Investment Proposal document — Benefits/Impact chapter (Spanish).';
comment on column public.projects.proposal_planning_narrative is 'Investment Proposal document — Planning/Implementation narrative chapter (Spanish); the document''s Planning chapter also includes a live summary of the project''s active Roadmaps, pulled at PDF-generation time rather than stored here.';

-- No new RLS policies needed: these are plain columns on the existing
-- public.projects table, already covered by projects_update_own_or_
-- assigned_advisor (owner or the advisor who has taken the project) and
-- the admin bypass policy — see supabase/schema.sql's projects RLS block.
