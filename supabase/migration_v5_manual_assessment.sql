-- ============================================================================
-- INA Platform — Migration v5: manual 9-dimension self-assessment
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
--
-- What this adds:
--   1. framework_analysis.source ('ai' default / 'manual') — distinguishes
--      results written by /api/analyze-project (Claude) from results
--      submitted by a project owner answering the questionnaire on
--      app/assessment.html by hand.
--   2. A new RLS policy letting a project owner insert their OWN
--      framework_analysis row directly from the browser, but ONLY when
--      source='manual' — the 'ai' path stays service-role-only exactly as
--      before, so a client can't fake an AI-sourced result.
--
-- Context: the questionnaire covers the same 8 Investment Readiness Index™
-- dimensions the AI analysis scores, plus a 9th dimension specific to the
-- project's type (e.g. "Route & Landing Feasibility" for a submarine
-- cable, "Power & Cooling Readiness" for an AI datacenter). Today the user
-- answers by hand; the plan is for an AI agent to eventually infer these
-- same answers from the project's uploaded documents instead.
-- ============================================================================

alter table public.framework_analysis
  add column if not exists source text not null default 'ai';

alter table public.framework_analysis
  drop constraint if exists framework_analysis_source_check;
alter table public.framework_analysis
  add constraint framework_analysis_source_check check (source in ('ai', 'manual'));

drop policy if exists "analysis_insert_own_manual" on public.framework_analysis;
create policy "analysis_insert_own_manual" on public.framework_analysis
  for insert with check (auth.uid() = user_id and source = 'manual');
