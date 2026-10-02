-- ============================================================================
-- migration_v70_project_phases.sql
--
-- QUÉ AGREGA
-- Fases de proyecto opcionales — cada una con su propio nombre, alcance,
-- presupuesto (ARS/USD) y duración. Una vez que un proyecto tiene al
-- menos una fase cargada, projects.budget_amount/budget_amount_usd/
-- duration_value/duration_unit dejan de cargarse a mano y pasan a
-- calcularse como la suma de sus fases (ver
-- recomputeProjectTotalsFromPhases() en assets/platform.js) — un proyecto
-- sin fases sigue funcionando exactamente igual que hoy.
--
-- Sin columna de orden propia — se listan por created_at, no hay pedido
-- de reordenarlas a mano.
--
-- QUÉ NO CAMBIA
-- No toca projects ni ninguna de sus políticas. En esta vuelta, la
-- extracción por PDF, el Análisis IA y la Propuesta de Financiamiento NO
-- leen project_phases — siguen funcionando igual porque las fases
-- escriben su suma en las mismas columnas de projects que ya usaban.
-- ============================================================================

create table public.project_phases (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  name text not null,
  scope text,
  budget_amount numeric check (budget_amount is null or budget_amount >= 0),
  budget_amount_usd numeric check (budget_amount_usd is null or budget_amount_usd >= 0),
  duration_value integer check (duration_value is null or duration_value > 0),
  duration_unit text check (duration_unit is null or duration_unit in ('days', 'months')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.project_phases enable row level security;

-- Mirrors projects_select_own_or_advisor exactly, via an exists subquery
-- against the parent project since a phase has no user_id of its own.
create policy "project_phases_select_own_or_advisor" on public.project_phases
  for select using (exists (
    select 1 from public.projects p where p.id = project_phases.project_id
    and (
      auth.uid() = p.user_id
      or auth.uid() = p.assigned_advisor_id
      or public.is_advisor()
      or public.is_admin()
      or public.has_entity_access(auth.uid(), 'projects', 'view', p.user_id)
    )
  ));

-- Mirrors projects_update_own_or_assigned_advisor — same condition covers
-- both insert and update, since creating/editing a phase is "editing the
-- project's financing", same as the budget fields themselves.
create policy "project_phases_insert_own_or_advisor" on public.project_phases
  for insert with check (exists (
    select 1 from public.projects p where p.id = project_phases.project_id
    and (
      auth.uid() = p.user_id
      or auth.uid() = p.assigned_advisor_id
      or public.has_entity_access(auth.uid(), 'projects', 'edit', p.user_id)
    )
  ));

create policy "project_phases_update_own_or_advisor" on public.project_phases
  for update using (exists (
    select 1 from public.projects p where p.id = project_phases.project_id
    and (
      auth.uid() = p.user_id
      or auth.uid() = p.assigned_advisor_id
      or public.has_entity_access(auth.uid(), 'projects', 'edit', p.user_id)
    )
  )) with check (exists (
    select 1 from public.projects p where p.id = project_phases.project_id
    and (
      auth.uid() = p.user_id
      or auth.uid() = p.assigned_advisor_id
      or public.has_entity_access(auth.uid(), 'projects', 'edit', p.user_id)
    )
  ));

-- Mirrors projects_delete_own_or_admin.
create policy "project_phases_delete_own_or_admin" on public.project_phases
  for delete using (exists (
    select 1 from public.projects p where p.id = project_phases.project_id
    and (auth.uid() = p.user_id or public.is_admin())
  ));

create index project_phases_project_id_idx on public.project_phases(project_id);
