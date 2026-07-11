-- ============================================================================
-- INA Platform — Supabase schema
-- Run this once in your Supabase project: Dashboard → SQL Editor → New query
-- → paste this whole file → Run.
--
-- NOTE: if you already ran an earlier version of this file (before the
-- advisor role / project grid feature existed), do NOT re-run this whole
-- file — run supabase/migration_v2_roles_and_grid.sql instead. This file
-- is for brand-new Supabase projects only.
-- ============================================================================

-- ---------- profiles ----------
-- One row per registered user, mirroring auth.users. Created automatically
-- by the trigger below whenever someone signs up.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  organization text not null,
  role_type text not null check (role_type in (
    'government_regulator',
    'development_finance_institution',
    'investor_infrastructure_fund',
    'technology_company',
    'other'
  )),
  -- Platform access role. 'user' (default) can only see/edit their own
  -- projects. 'advisor' can view every project on the platform. There is
  -- deliberately no self-service way to become an advisor — promote a
  -- user by editing this column directly in Dashboard → Table Editor →
  -- profiles, after they've signed up. Self-service selection at signup
  -- would let anyone grant themselves visibility into other users' data.
  role text not null default 'user' check (role in ('user', 'advisor')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

-- Auto-create a profile row when a new auth user is created, populating
-- full_name/organization/role_type from the signUp() options.data payload.
-- role always starts as 'user' regardless of signup payload.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, organization, role_type, role)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'organization', ''),
    coalesce(new.raw_user_meta_data->>'role_type', 'other'),
    'user'
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Small helper used by RLS policies below to check "is the current user
-- an advisor" without repeating the subquery everywhere.
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

-- ---------- projects ----------
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  -- References profiles(id) rather than auth.users(id) directly so that
  -- PostgREST/Supabase-js can embed the owner's profile in one query
  -- (`.select('*, profiles(full_name, organization)')`), which the
  -- advisor "all projects" grid relies on. profiles.id is itself FK'd
  -- 1:1 to auth.users(id), so referential integrity is unchanged.
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  project_type text not null check (project_type in (
    'submarine_cable',
    'fiber_backbone_last_mile',
    'fixed_wireless_access',
    'ai_datacenter',
    'satellite_constellation',
    'other'
  )),
  country text not null,
  description text not null,
  status text not null default 'submitted' check (status in (
    'submitted', 'analyzing', 'completed', 'error'
  )),
  -- Denormalized copy of the latest framework_analysis.stage (Concept
  -- Stage / Early Structuring / Advanced Structuring / Investment Ready),
  -- written by /api/analyze-project.js when an analysis completes. Lets
  -- the dashboard grid show/filter by framework-derived stage without an
  -- extra join per row. Null until the first analysis completes.
  readiness_stage text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.projects enable row level security;

-- Regular users see only their own projects; advisors see every project.
create policy "projects_select_own_or_advisor" on public.projects
  for select using (auth.uid() = user_id or public.is_advisor());

create policy "projects_insert_own" on public.projects
  for insert with check (auth.uid() = user_id);

-- Editing stays owner-only, even for advisors — the request is "advisors
-- can VIEW every project," not edit them.
create policy "projects_update_own" on public.projects
  for update using (auth.uid() = user_id);

create index if not exists projects_user_id_idx on public.projects(user_id);

-- ---------- project_documents ----------
create table if not exists public.project_documents (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  file_name text not null,
  storage_path text not null,
  uploaded_at timestamptz not null default now()
);

alter table public.project_documents enable row level security;

create policy "documents_select_own_or_advisor" on public.project_documents
  for select using (auth.uid() = user_id or public.is_advisor());

create policy "documents_insert_own" on public.project_documents
  for insert with check (auth.uid() = user_id);

create index if not exists project_documents_project_id_idx on public.project_documents(project_id);

-- ---------- framework_analysis ----------
-- One row per completed analysis run. Written by the server-side
-- /api/analyze-project function using the Supabase service role key
-- (never by the client directly).
create table if not exists public.framework_analysis (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  overall_score int,
  stage text,
  dimensions jsonb,
  gap_roadmap jsonb,
  financing_recommendations jsonb,
  summary text,
  raw_model_output text,
  created_at timestamptz not null default now()
);

alter table public.framework_analysis enable row level security;

create policy "analysis_select_own_or_advisor" on public.framework_analysis
  for select using (auth.uid() = user_id or public.is_advisor());

-- No insert/update policy for anon/authenticated: only the service role
-- key (used server-side in the Vercel function, which bypasses RLS) writes here.

create index if not exists framework_analysis_project_id_idx on public.framework_analysis(project_id);

-- ============================================================================
-- Storage bucket for uploaded project documents.
-- Run once: Dashboard → Storage → Create bucket → name it "project-documents"
-- → set Public: OFF. Then run the policies below (Dashboard → Storage →
-- project-documents → Policies, or just run this SQL — Supabase exposes
-- storage.objects as a regular table you can add RLS policies to).
-- ============================================================================

create policy "doc_upload_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "doc_read_own_folder_or_advisor" on storage.objects
  for select using (
    bucket_id = 'project-documents'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_advisor()
    )
  );

-- Expected storage path convention used by assets/platform.js:
--   {user_id}/{project_id}/{filename}
-- This is what makes the "own folder" policies above work correctly.
