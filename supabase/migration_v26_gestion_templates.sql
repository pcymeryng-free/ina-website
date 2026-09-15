-- ============================================================================
-- INA Platform — Migration v26: "Gestiones" checklist system
--
-- New feature: a generic, reusable checklist of administrative/regulatory
-- procedures ("gestiones") that a project needs to work through — each step
-- naming the public and/or private entity involved, its status, a
-- responsible contact, dates and notes. First use case: a project of type
-- 'early_warning_system' (see migration_v25_early_warning_system_type.sql)
-- — e.g. "coordinar con el Servicio Meteorológico Nacional",
-- "solicitar autorización de uso de Cell Broadcast a los operadores
-- móviles", "firmar convenio con Defensa Civil" — but the structure isn't
-- tied to that type; any project type can have (or lack) a gestion
-- template, set by an advisor/admin from app/gestion-templates.html.
--
-- Three tables:
--
-- 1. gestion_templates — a named, reusable checklist definition. Optionally
--    scoped to one project_type (project_type is plain text, no CHECK
--    constraint tying it to assets/platform.js's PROJECT_TYPES enum — same
--    "no CHECK constraint" choice as programs.template_key, since the
--    dropdown that sets it is populated client-side and an unrecognized
--    value should just mean "doesn't show up as a suggested match" rather
--    than a rejected insert); left null, a template applies to any project
--    type and always shows as an option.
--
-- 2. gestion_template_steps — the ordered list of procedures within a
--    template (title, description, suggested entity name/type, whether
--    it's required). Purely a definition — editing a template's steps
--    later does NOT retroactively change project_gestiones rows already
--    instantiated from it (template_step_id is on delete set null, not
--    cascade-synced), same "instances are independent copies" spirit as
--    project-type/Program templates elsewhere in this schema.
--
-- 3. project_gestiones — the actual per-project checklist instance.
--    INAPlatform.instantiateGestionesFromTemplate() (assets/platform.js)
--    copies a template's steps into rows here when an advisor/admin first
--    loads a template onto a project (app/project.html's "Gestiones"
--    section); ad-hoc steps not tied to any template can also be added
--    directly. template_step_id is kept only as a soft "where this row
--    came from" reference.
--
-- RLS: gestion_templates/gestion_template_steps are visible to and
-- manageable only by advisor/admin — this is a regulator-facing tool, not
-- something project submitters browse directly (contrast with
-- public.programs, which is deliberately visible to everyone so any
-- submitter can associate their project with the right umbrella
-- initiative). Any advisor/admin can edit any template, same
-- "any advisor can act on any X" spirit as take_project()/
-- promote_project_workflow() below — templates are a shared regulatory
-- resource, not owned by whoever happened to create them first.
--
-- project_gestiones follows the project itself: visible to the project's
-- owner (read-only — see below) or any advisor/admin; INSERT/UPDATE/DELETE
-- are advisor/admin only, so the project owner always sees the checklist
-- but never edits it directly from their side, per the platform's current
-- regulatory-tool design for this feature.
--
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
-- ============================================================================

-- ---------- gestion_templates ----------
create table if not exists public.gestion_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  project_type text,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.gestion_templates enable row level security;

create policy "gestion_templates_select_advisor_or_admin" on public.gestion_templates
  for select using (public.is_advisor() or public.is_admin());

create policy "gestion_templates_insert_advisor_or_admin" on public.gestion_templates
  for insert with check (auth.uid() = user_id and (public.is_advisor() or public.is_admin()));

create policy "gestion_templates_update_advisor_or_admin" on public.gestion_templates
  for update using (public.is_advisor() or public.is_admin());

create policy "gestion_templates_delete_advisor_or_admin" on public.gestion_templates
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists gestion_templates_project_type_idx on public.gestion_templates(project_type);

-- ---------- gestion_template_steps ----------
create table if not exists public.gestion_template_steps (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.gestion_templates(id) on delete cascade,
  step_order integer not null default 0,
  title text not null,
  description text,
  -- Suggested entity for this step — free text (e.g. "Servicio
  -- Meteorológico Nacional", "Operadores móviles (Movistar/Personal/Claro)")
  -- rather than a link to any entities table; there's no shared entity
  -- registry in this schema, and the entity is often provisional/aspirational
  -- at template-design time anyway.
  entity_name text,
  entity_type text not null default 'public' check (entity_type in ('public', 'private', 'mixed')),
  required boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.gestion_template_steps enable row level security;

create policy "gestion_template_steps_select_advisor_or_admin" on public.gestion_template_steps
  for select using (public.is_advisor() or public.is_admin());

create policy "gestion_template_steps_insert_advisor_or_admin" on public.gestion_template_steps
  for insert with check (public.is_advisor() or public.is_admin());

create policy "gestion_template_steps_update_advisor_or_admin" on public.gestion_template_steps
  for update using (public.is_advisor() or public.is_admin());

create policy "gestion_template_steps_delete_advisor_or_admin" on public.gestion_template_steps
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists gestion_template_steps_template_id_idx on public.gestion_template_steps(template_id);

-- ---------- project_gestiones ----------
create table if not exists public.project_gestiones (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  -- Soft reference to where this row came from, if instantiated from a
  -- template step — kept even if the template step is later edited/deleted
  -- (on delete set null) since this row is an independent copy, not a live
  -- link. Null for ad-hoc steps added directly to a project without going
  -- through a template.
  template_step_id uuid references public.gestion_template_steps(id) on delete set null,
  step_order integer not null default 0,
  title text not null,
  description text,
  entity_name text,
  entity_type text not null default 'public' check (entity_type in ('public', 'private', 'mixed')),
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed', 'blocked')),
  responsible_name text,
  responsible_contact text,
  due_date date,
  completed_date date,
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.project_gestiones enable row level security;

-- Same visibility as project_workflow_events above: the project's owner
-- (read-only — see the insert/update/delete policies below, there is no
-- owner-write policy on purpose), or any advisor/admin.
create policy "project_gestiones_select_own_or_advisor" on public.project_gestiones
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = project_gestiones.project_id and pr.user_id = auth.uid()
    )
  );

create policy "project_gestiones_insert_advisor_or_admin" on public.project_gestiones
  for insert with check (public.is_advisor() or public.is_admin());

create policy "project_gestiones_update_advisor_or_admin" on public.project_gestiones
  for update using (public.is_advisor() or public.is_admin());

create policy "project_gestiones_delete_advisor_or_admin" on public.project_gestiones
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists project_gestiones_project_id_idx on public.project_gestiones(project_id);
create index if not exists project_gestiones_template_step_id_idx on public.project_gestiones(template_step_id);
