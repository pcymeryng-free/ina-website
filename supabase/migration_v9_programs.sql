-- ============================================================================
-- INA Platform — Migration v9: Programs
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
--
-- Why: several real submissions bundle more than one project under a single
-- umbrella initiative — e.g. Chubut's "Hub Digital Patagónico", which
-- combined a submarine cable landing, a regional backbone and last-mile
-- builds as separate projects, each financed independently, all presented
-- by the same sponsoring organization. INA's model had no way to group
-- projects like that or filter/report on the grouping.
--
-- What this adds:
--   - public.programs — one row per program (name, presenting organization,
--     public/private, description). A program can have many projects.
--   - public.projects.program_id — optional FK, null for standalone
--     projects. A project belongs to at most one program and is always of
--     a single project_type; program-level fields never duplicate anything
--     that belongs on the individual projects.
-- ============================================================================

create table if not exists public.programs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  organization text not null,
  organization_type text not null default 'public' check (organization_type in ('public', 'private')),
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.programs enable row level security;

drop policy if exists "programs_select_own_or_advisor" on public.programs;
create policy "programs_select_own_or_advisor" on public.programs
  for select using (auth.uid() = user_id or public.is_advisor());

drop policy if exists "programs_insert_own" on public.programs;
create policy "programs_insert_own" on public.programs
  for insert with check (auth.uid() = user_id);

drop policy if exists "programs_update_own" on public.programs;
create policy "programs_update_own" on public.programs
  for update using (auth.uid() = user_id);

create index if not exists programs_user_id_idx on public.programs(user_id);

alter table public.projects
  add column if not exists program_id uuid references public.programs(id) on delete set null;

create index if not exists projects_program_id_idx on public.projects(program_id);
