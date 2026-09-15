-- ============================================================================
-- Migration v21: program funding_stage + multi-program applications
-- Run once in Supabase SQL Editor.
--
-- Adds a distinction between programs that fund the ELABORATION of a
-- project (e.g. USTDA Feasibility Study / Definitional Mission grants) and
-- programs that fund the project itself (FSU, BID, capital markets debt,
-- TASU, etc.), and lets a single project apply to MULTIPLE financing
-- programs at once (e.g. FSU + BID), independent of the pre-existing
-- projects.program_id "umbrella" grouping (Chubut Hub Digital-style), which
-- this migration does not touch.
-- ============================================================================

alter table public.programs
  add column if not exists funding_stage text not null default 'financing'
    check (funding_stage in ('preparation', 'financing'));

comment on column public.programs.funding_stage is
  'preparation = funds the ELABORATION/structuring of the project itself (e.g. USTDA Feasibility Study / Definitional Mission grants). financing = funds the project''s implementation (FSU, BID, capital markets debt, TASU, etc.). Default financing for all pre-existing programs.';

-- ---------- project_programs ----------
-- A project can apply to MANY financing/preparation programs at once (e.g.
-- FSU + BID for implementation financing, plus USTDA for elaboration
-- funding) — distinct from projects.program_id, which is the single
-- "umbrella" program a project may have been submitted under. Each row is
-- one (project, program) application; template_answers/notes hold the
-- program's guided-template intake (see PROGRAM_TEMPLATES in
-- assets/platform.js) filled in specifically for that application, when the
-- program has one — both null for programs with no template_key, where
-- applying is just a plain association.
create table if not exists public.project_programs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  program_id uuid not null references public.programs(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  template_answers jsonb,
  notes text,
  applied_at timestamptz not null default now(),
  unique (project_id, program_id)
);

alter table public.project_programs enable row level security;

-- Same visibility as the parent project: its owner, the advisor currently
-- assigned to it, or any advisor/admin (matches fsu_scoring's pattern).
create policy "project_programs_select_own_or_advisor" on public.project_programs
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = project_programs.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

create policy "project_programs_insert_own_or_assigned_advisor" on public.project_programs
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.projects pr
      where pr.id = project_programs.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

-- Lets the owner or assigned advisor withdraw an application (picked the
-- wrong program, wants to redo the template answers, etc.).
create policy "project_programs_delete_own_or_assigned_advisor" on public.project_programs
  for delete using (
    exists (
      select 1 from public.projects pr
      where pr.id = project_programs.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

create index if not exists project_programs_project_id_idx on public.project_programs(project_id);
create index if not exists project_programs_program_id_idx on public.project_programs(program_id);
