-- ============================================================================
-- Migration v58: Investment Proposal document — Executive Summary chapter,
-- as its own field distinct from Introduction.
--
-- Pablo, sep 2026: restructuring the "Propuesta de Financiamiento" PDF
-- (generateProposalPdf() in app/investment-proposal.html) into a fixed
-- chapter order — cover page, índice, then "Resumen Ejecutivo" followed by
-- "Introducción" as two SEPARATE chapters on page 3. Until now the document
-- only had a single combined "Introducción y Resumen Ejecutivo" chapter
-- (migration_v50_investment_proposal.sql's proposal_introduction), with no
-- dedicated Executive Summary text. This migration adds that 5th narrative
-- field, following the exact same bilingual pattern as the other four
-- (proposal_introduction/_en, proposal_technical_description/_en,
-- proposal_benefits/_en, proposal_planning_narrative/_en).
--
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run. Safe to run more than once
-- ("if not exists" throughout).
-- ============================================================================

alter table public.projects
  add column if not exists proposal_executive_summary text,
  add column if not exists proposal_executive_summary_en text;

comment on column public.projects.proposal_executive_summary is 'Investment Proposal document — Executive Summary chapter (Spanish), shown on its own page BEFORE the Introduction chapter. AI-drafted (api/generate-proposal.js), user-editable before saving. See generateProposalPdf() in app/investment-proposal.html.';

-- No new RLS policies needed: plain columns on the existing public.projects
-- table, already covered by projects_update_own_or_assigned_advisor (owner
-- or the advisor who has taken the project) and the admin bypass policy —
-- see supabase/schema.sql's projects RLS block.
