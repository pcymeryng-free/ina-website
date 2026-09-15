-- ============================================================================
-- INA Platform — Migration v27: entity taxonomy + sequential Gestion
-- instances (replaces the free-form project_gestiones checklist UI)
--
-- Three changes:
--
-- 1. projects gets generating_entity_name / generating_entity_type — who
--    submitted/generated the project and what kind of organization they
--    are (Ente regulador, Gobierno nacional/provincial/municipal, ISP,
--    Fabricante, Integrador, Otro). Purely descriptive/informational,
--    same "text, no FK" spirit as everything else that names an outside
--    organization in this schema (gestion_template_steps.entity_name,
--    programs.organization, etc.) — there's no shared entities registry.
--
-- 2. gestion_templates gets allowed_entity_type — an OPTIONAL restriction
--    on which kind of entity is allowed to carry out the whole checklist
--    (e.g. the "Alerta Temprana" gestion template can be restricted to
--    'regulator' only). Null = any entity type may perform it. This is a
--    template-level restriction (not per-step) — deliberately simple,
--    matching the single example that motivated it.
--
--    gestion_template_steps gets expected_result — free text describing
--    what "done" looks like for that step (used by the new sequential
--    tracker below to show the user what they're confirming when they
--    advance past a step).
--
-- 3. Two new tables replace project_gestiones as the per-project tracking
--    mechanism: gestion_instances and gestion_instance_steps.
--
--    Where project_gestiones was a flat, freely-editable checklist (every
--    step visible and editable at once, status set independently per
--    row), a gestion_instance is a single sequential workflow: one named
--    "instance" of a gestion_template, tied to a specific project AND to
--    the specific entity actually carrying it out (which may not be the
--    project's owner — e.g. the regulator runs the Alerta Temprana
--    coordination steps, not the applicant). Its steps are copied from
--    the template at creation time (same "instances are independent
--    copies" pattern as project_gestiones/PROJECT_TEMPLATES elsewhere —
--    template_step_id is on delete set null, not cascade-synced) and are
--    worked through IN ORDER: current_step_index on gestion_instances
--    points at the active step; the user explicitly decides whether to
--    advance past it (INAPlatform.advanceGestionInstanceStep()) or not.
--
--    project_gestiones itself is left in place (not dropped) in case any
--    data was already entered under the old free-form checklist UI, but
--    the app no longer reads or writes it — app/project.html's
--    "Gestiones" section now lists gestion_instances instead.
--
-- RLS follows the exact same shape as project_gestiones: the project
-- owner can SELECT (read-only, no owner write policy) or any advisor/
-- admin; INSERT/UPDATE/DELETE are advisor/admin only.
--
-- Run this ONCE in your EXISTING Supabase project, AFTER migration_v26:
-- Dashboard → SQL Editor → New query → paste this whole file → Run.
-- ============================================================================

-- ---------- 1. projects: generating entity ----------
alter table public.projects
  add column if not exists generating_entity_name text,
  add column if not exists generating_entity_type text check (generating_entity_type is null or generating_entity_type in (
    'regulator', 'national_gov', 'provincial_gov', 'municipal_gov', 'isp', 'manufacturer', 'integrator', 'other'
  ));

-- ---------- 2. gestion_templates / gestion_template_steps additions ----------
alter table public.gestion_templates
  add column if not exists allowed_entity_type text check (allowed_entity_type is null or allowed_entity_type in (
    'regulator', 'national_gov', 'provincial_gov', 'municipal_gov', 'isp', 'manufacturer', 'integrator', 'other'
  ));

alter table public.gestion_template_steps
  add column if not exists expected_result text;

-- ---------- 3. gestion_instances ----------
create table if not exists public.gestion_instances (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  -- Soft reference — kept for audit/display ("created from template X")
  -- even if the template is later edited or deleted.
  template_id uuid references public.gestion_templates(id) on delete set null,
  name text not null,
  performing_entity_name text not null,
  performing_entity_type text not null check (performing_entity_type in (
    'regulator', 'national_gov', 'provincial_gov', 'municipal_gov', 'isp', 'manufacturer', 'integrator', 'other'
  )),
  -- 0-based index into this instance's ordered gestion_instance_steps.
  -- The step at this index is the "current" one the tracker page shows as
  -- active; steps before it are completed, steps after it are locked.
  current_step_index integer not null default 0,
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'abandoned')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.gestion_instances enable row level security;

create policy "gestion_instances_select_own_or_advisor" on public.gestion_instances
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = gestion_instances.project_id and pr.user_id = auth.uid()
    )
  );

create policy "gestion_instances_insert_advisor_or_admin" on public.gestion_instances
  for insert with check (public.is_advisor() or public.is_admin());

create policy "gestion_instances_update_advisor_or_admin" on public.gestion_instances
  for update using (public.is_advisor() or public.is_admin());

create policy "gestion_instances_delete_advisor_or_admin" on public.gestion_instances
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists gestion_instances_project_id_idx on public.gestion_instances(project_id);
create index if not exists gestion_instances_template_id_idx on public.gestion_instances(template_id);

-- ---------- 4. gestion_instance_steps ----------
create table if not exists public.gestion_instance_steps (
  id uuid primary key default gen_random_uuid(),
  instance_id uuid not null references public.gestion_instances(id) on delete cascade,
  template_step_id uuid references public.gestion_template_steps(id) on delete set null,
  step_order integer not null default 0,
  title text not null,
  description text,
  expected_result text,
  entity_name text,
  entity_type text not null default 'public' check (entity_type in ('public', 'private', 'mixed')),
  required boolean not null default true,
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed', 'skipped', 'blocked')),
  decision_note text,
  completed_at timestamptz,
  completed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.gestion_instance_steps enable row level security;

-- Same visibility as the parent instance: the project owner sees it
-- read-only via a join back to projects; advisor/admin manage it.
create policy "gestion_instance_steps_select_own_or_advisor" on public.gestion_instance_steps
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.gestion_instances gi
      join public.projects pr on pr.id = gi.project_id
      where gi.id = gestion_instance_steps.instance_id and pr.user_id = auth.uid()
    )
  );

create policy "gestion_instance_steps_insert_advisor_or_admin" on public.gestion_instance_steps
  for insert with check (public.is_advisor() or public.is_admin());

create policy "gestion_instance_steps_update_advisor_or_admin" on public.gestion_instance_steps
  for update using (public.is_advisor() or public.is_admin());

create policy "gestion_instance_steps_delete_advisor_or_admin" on public.gestion_instance_steps
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists gestion_instance_steps_instance_id_idx on public.gestion_instance_steps(instance_id);
create index if not exists gestion_instance_steps_template_step_id_idx on public.gestion_instance_steps(template_step_id);
