-- ============================================================================
-- INA Platform — Migration v2: advisor role + all-projects grid
-- Run this ONCE in your EXISTING Supabase project (the one where you already
-- ran the original schema.sql and have real signups): Dashboard → SQL Editor
-- → New query → paste this whole file → Run.
--
-- What this adds:
--   1. profiles.role ('user' default / 'advisor') — advisors can view every
--      project on the platform; regular users only see/edit their own.
--   2. projects.readiness_stage — denormalized copy of the latest analysis
--      stage, so the dashboard grid can show/filter it without extra joins.
--   3. projects.user_id / project_documents.user_id / framework_analysis.
--      user_id now reference profiles(id) instead of auth.users(id) directly
--      — same integrity guarantee (profiles.id is 1:1 with auth.users.id),
--      but it lets Supabase-js embed the owner's profile in one query
--      (needed for the "user" column in the advisor grid).
--   4. Updated RLS SELECT policies so advisors see all rows; INSERT/UPDATE
--      stay owner-only (advisors can view, not edit, other users' projects).
-- ============================================================================

-- 1. Add role to profiles.
alter table public.profiles
  add column if not exists role text not null default 'user' check (role in ('user', 'advisor'));

-- 2. Add denormalized readiness_stage to projects.
alter table public.projects
  add column if not exists readiness_stage text;

-- 3. Helper function used by the new policies.
create or replace function public.is_advisor()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'advisor'
  );
$$;

-- 4. Repoint the user_id foreign keys at profiles(id) so profile data can
--    be embedded in project queries. Safe: profiles.id already equals
--    auth.users.id 1:1 for every existing row (enforced since profiles was
--    created), so no data changes, just the FK target table.
alter table public.projects
  drop constraint if exists projects_user_id_fkey;
alter table public.projects
  add constraint projects_user_id_fkey foreign key (user_id) references public.profiles(id) on delete cascade;

alter table public.project_documents
  drop constraint if exists project_documents_user_id_fkey;
alter table public.project_documents
  add constraint project_documents_user_id_fkey foreign key (user_id) references public.profiles(id) on delete cascade;

alter table public.framework_analysis
  drop constraint if exists framework_analysis_user_id_fkey;
alter table public.framework_analysis
  add constraint framework_analysis_user_id_fkey foreign key (user_id) references public.profiles(id) on delete cascade;

-- 5. Replace the "own rows only" SELECT policies with "own rows, or any
--    row if you're an advisor" versions. INSERT/UPDATE policies are left
--    untouched (still owner-only).
drop policy if exists "projects_select_own" on public.projects;
create policy "projects_select_own_or_advisor" on public.projects
  for select using (auth.uid() = user_id or public.is_advisor());

drop policy if exists "documents_select_own" on public.project_documents;
create policy "documents_select_own_or_advisor" on public.project_documents
  for select using (auth.uid() = user_id or public.is_advisor());

drop policy if exists "analysis_select_own" on public.framework_analysis;
create policy "analysis_select_own_or_advisor" on public.framework_analysis
  for select using (auth.uid() = user_id or public.is_advisor());

drop policy if exists "doc_read_own_folder" on storage.objects;
create policy "doc_read_own_folder_or_advisor" on storage.objects
  for select using (
    bucket_id = 'project-documents'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_advisor()
    )
  );

-- ============================================================================
-- After running this: to make someone an advisor, go to Dashboard → Table
-- Editor → profiles, find their row, and change role from "user" to
-- "advisor". There is no in-app way to self-select this role, by design.
-- ============================================================================
