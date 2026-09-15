-- ============================================================================
-- Migration v14 — Allow deleting projects and programs (owner or admin only)
--
-- Neither public.projects nor public.programs has ever had a DELETE RLS
-- policy — Postgres RLS defaults to denying an operation entirely when no
-- policy grants it, regardless of table ownership, so deleting either has
-- been silently impossible from the client (Supabase-js) since day one.
-- This adds that policy for both, scoped to the row's own owner OR a
-- platform admin (public.is_admin(), same helper already used elsewhere —
-- see schema.sql). Deliberately NOT opened to advisors — "advisors can
-- view every project" was the original design intent (see projects_update_own's
-- comment in schema.sql); deleting is more destructive than editing, so it
-- stays owner-or-admin only, same bar as changing a user's role.
--
-- What deleting cascades to (already defined by existing foreign keys —
-- nothing new needed here):
--   Deleting a PROJECT cascades to (all "on delete cascade"):
--     project_documents, framework_analysis, fsu_scoring,
--     project_workflow_events.
--   Deleting a PROGRAM does NOT delete its member projects — projects.program_id
--     is "on delete set null", so they're simply unlinked, matching the
--     existing "a program is just an optional grouping" design (see the
--     comment on public.programs in schema.sql). program_documents for that
--     program IS cascade-deleted along with the program itself.
--
-- Run this whole file once in Supabase Dashboard → SQL Editor.
-- ============================================================================

create policy "projects_delete_own_or_admin" on public.projects
  for delete using (auth.uid() = user_id or public.is_admin());

create policy "programs_delete_own_or_admin" on public.programs
  for delete using (auth.uid() = user_id or public.is_admin());

-- ----------------------------------------------------------------------------
-- Bonus fix, uncovered while wiring up the above: every *_select_own_or_advisor
-- policy across the schema (projects, programs, project_documents,
-- program_documents, framework_analysis, fsu_scoring) only ever checked
-- public.is_advisor() — never public.is_admin() too, unlike
-- project_workflow_events (which correctly checks both) and profiles
-- (profiles_select_own_or_privileged, also both). role is a single value
-- ('user' | 'advisor' | 'admin', see the check constraint on
-- public.profiles.role) — an admin is NOT also an advisor, so a pure admin
-- account couldn't actually SEE another user's project or program at all,
-- which would make the delete policies above a dead end for them: RLS
-- filters rows out of SELECT silently (no error), so admin.html's user
-- list worked fine, but a project/program dashboard would just look empty
-- for anyone else's data. Extending these six SELECT policies to match
-- projects_delete_own_or_admin's bar (owner OR advisor OR admin) is what
-- actually makes "admin can delete any project/program" work end to end.
-- ----------------------------------------------------------------------------

drop policy if exists "projects_select_own_or_advisor" on public.projects;
create policy "projects_select_own_or_advisor" on public.projects
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

drop policy if exists "programs_select_own_or_advisor" on public.programs;
create policy "programs_select_own_or_advisor" on public.programs
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

drop policy if exists "documents_select_own_or_advisor" on public.project_documents;
create policy "documents_select_own_or_advisor" on public.project_documents
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

drop policy if exists "program_documents_select_own_or_advisor" on public.program_documents;
create policy "program_documents_select_own_or_advisor" on public.program_documents
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

drop policy if exists "analysis_select_own_or_advisor" on public.framework_analysis;
create policy "analysis_select_own_or_advisor" on public.framework_analysis
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

drop policy if exists "fsu_scoring_select_own_or_advisor" on public.fsu_scoring;
create policy "fsu_scoring_select_own_or_advisor" on public.fsu_scoring
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());
