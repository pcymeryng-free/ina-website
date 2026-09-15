-- ============================================================================
-- INA Platform — Migration v19: advisor can edit/assess/FSU-score a project
-- they've taken
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
--
-- Why: migration_v12 deliberately kept editing/re-analysis owner-only even
-- for advisors ("the request is 'advisors can VIEW every project,' not edit
-- them") and routed the one exception it did want (Take/Advance) through
-- narrow SECURITY DEFINER RPCs rather than a broad RLS grant, specifically
-- to avoid handing an advisor blanket write access to every project's
-- columns. Pablo has since asked for more: once an advisor has explicitly
-- taken a project (projects.assigned_advisor_id = their id, set only by
-- take_project()/advance_project_workflow() — never by a plain client
-- update), they should be able to edit it, run/re-run its AI analysis
-- (already done in a prior session — see api/analyze-project.js and
-- app/project.html's isAssignedAdvisor), submit its manual self-assessment,
-- and fill in its FSU Scoring, exactly as the owner can. This migration is
-- the RLS side of that: every write path a project owner has today that
-- goes through a direct client .update()/.insert() (not a SECURITY DEFINER
-- RPC) now also accepts the project's assigned_advisor_id.
--
-- What this changes:
--   1. projects_update_own → projects_update_own_or_assigned_advisor:
--      lets the assigned advisor update the project row directly (needed
--      for app/new-project.html's edit form, and for
--      submitManualAssessment()'s projects.status/readiness_stage update).
--      Note this is a genuinely broader grant than take_project()/
--      advance_project_workflow() ever gave — those RPCs only ever touch
--      assigned_advisor_id/readiness_stage themselves; an advisor who's
--      taken a project can now edit any of its columns via
--      app/new-project.html, same as the owner could already. Deliberate,
--      per Pablo's request — not a bug.
--   2. fsu_scoring_insert_own / fsu_scoring_update_own →
--      *_own_or_assigned_advisor: lets the assigned advisor save an
--      fsu_scoring row for the project even though its own user_id column
--      (see migration_v8) records whoever last saved it, which may not be
--      the project's assigned_advisor_id. Checks assigned_advisor_id on
--      the parent projects row instead of/in addition to fsu_scoring's own
--      user_id column.
--
-- Not touched: projects_delete_own_or_admin (deleting stays owner-or-admin
-- only — not part of this request), and analysis_insert_own_manual
-- (migration_v5) already has no project-ownership check at all — it only
-- verifies the inserted row's own user_id/source, so it already allows
-- this without changes.
-- ============================================================================

drop policy if exists "projects_update_own" on public.projects;
drop policy if exists "projects_update_own_or_assigned_advisor" on public.projects;
create policy "projects_update_own_or_assigned_advisor" on public.projects
  for update using (auth.uid() = user_id or auth.uid() = assigned_advisor_id);

drop policy if exists "fsu_scoring_insert_own" on public.fsu_scoring;
drop policy if exists "fsu_scoring_insert_own_or_assigned_advisor" on public.fsu_scoring;
create policy "fsu_scoring_insert_own_or_assigned_advisor" on public.fsu_scoring
  for insert with check (
    auth.uid() = user_id
    or exists (
      select 1 from public.projects pr
      where pr.id = fsu_scoring.project_id and pr.assigned_advisor_id = auth.uid()
    )
  );

drop policy if exists "fsu_scoring_update_own" on public.fsu_scoring;
drop policy if exists "fsu_scoring_update_own_or_assigned_advisor" on public.fsu_scoring;
create policy "fsu_scoring_update_own_or_assigned_advisor" on public.fsu_scoring
  for update using (
    auth.uid() = user_id
    or exists (
      select 1 from public.projects pr
      where pr.id = fsu_scoring.project_id and pr.assigned_advisor_id = auth.uid()
    )
  );
