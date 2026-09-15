-- ============================================================================
-- Migration v19 — Program creation restricted to Advisor/Admin, visible to all
--
-- Two RLS changes to public.programs (see supabase/migration_v9_programs.sql
-- for the original policies, later touched by migration_v14_delete_policies.sql):
--
-- 1. INSERT — was "any authenticated user, own row" (programs_insert_own).
--    Now requires the creator to also be an advisor or admin
--    (public.is_advisor() / public.is_admin(), same helpers used everywhere
--    else in the schema). A standard user can no longer create a Program,
--    from programs.html, new-program.html, or the "Create a new program"
--    shortcut inside new-project.html's Program field — all three now hide
--    that entry point in the UI too (see app/programs.html,
--    app/new-program.html, app/new-project.html), but this is the policy
--    that actually enforces it; the UI hiding is just to avoid someone
--    filling out the whole form and only then hitting a permission error.
--
-- 2. SELECT — was "owner, advisor, or admin" (programs_select_own_or_advisor),
--    same restrictive pattern as projects/documents/analysis. Programs are
--    different: they exist so ANY user submitting a project can associate it
--    with the right umbrella initiative (e.g. Chubut's "Hub Digital
--    Patagónico"), which only works if every user can see every Program,
--    not just their own. Now open to any authenticated user
--    (auth.uid() is not null) — same bar as "logged in", nothing more.
--
-- UPDATE (programs_update_own) and DELETE (programs_delete_own_or_admin) are
-- UNCHANGED — a Program is still only editable by its owner (who, going
-- forward, is always an advisor or admin at creation time, though role
-- changes after the fact aren't retroactively enforced) or deletable by its
-- owner or an admin. Nothing about editing/deleting programs changes here.
--
-- Run this whole file once in Supabase Dashboard → SQL Editor.
-- ============================================================================

drop policy if exists "programs_insert_own" on public.programs;
create policy "programs_insert_advisor_or_admin" on public.programs
  for insert with check (auth.uid() = user_id and (public.is_advisor() or public.is_admin()));

drop policy if exists "programs_select_own_or_advisor" on public.programs;
create policy "programs_select_all_authenticated" on public.programs
  for select using (auth.uid() is not null);
