-- ============================================================================
-- Migration v42: Módulo RACI para los pasos del Roadmap
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run. Es seguro correrlo más de una
-- vez ("if not exists" en todo lo que sigue).
--
-- Ítem 2 del horizonte "Mediano plazo (3–9 meses)" de la hoja de ruta
-- propuesta en INA_Project_Structuring_Framework_y_Plataforma.pdf
-- (sección 9.3).
--
-- PROBLEMA QUE RESUELVE
-- Cada paso de un roadmap_template (y su copia en roadmap_instances) hoy
-- solo registra UNA entidad "responsable" (entity_name) y una lista libre
-- de "entidades involucradas" (involved_entities, migration_v29) sin
-- distinguir de qué manera participa cada una. Un RACI formal separa esos
-- roles: quién EJECUTA el paso (Responsible), quién lo APRUEBA/rinde
-- cuentas por él (Accountable — exactamente uno por paso, por convención),
-- a quién hay que CONSULTAR antes de avanzar (Consulted), y a quién solo
-- hay que INFORMAR una vez hecho (Informed).
--
-- QUÉ CAMBIA
--   1. public.roadmap_step_raci — un rol por fila para cada paso de
--      template: (template_step_id, entity_name, role). Único por
--      (template_step_id, entity_name) — cada entidad tiene un solo rol
--      por paso, siguiendo la convención estándar de una matriz RACI.
--   2. public.roadmap_instance_step_raci — la misma idea, copiada a cada
--      paso de una instancia concreta al crearla (independiente del
--      template desde ese momento, mismo patrón de copia que el resto de
--      roadmap_instance_steps).
--   3. roadmap_template_steps.entity_name/entity_type/involved_entities y
--      su equivalente en roadmap_instance_steps NO se eliminan — quedan
--      como resumen de compatibilidad hacia atrás (entity_name = las
--      entidades con rol "responsible", involved_entities = el resto),
--      derivados automáticamente por assets/platform.js al guardar. Así
--      cualquier vista que todavía no lea las tablas RACI (por ejemplo, un
--      PDF exportado con una versión vieja de la página) sigue mostrando
--      algo sensato en vez de quedar vacía.
--
-- PERMISOS: mismo criterio que roadmap_template_steps/roadmap_instance_
-- steps — solo advisor/admin escriben; el select sigue la misma
-- visibilidad que la tabla padre (roadmap_templates es advisor/admin-only
-- para ver; roadmap_instance_steps la ve también el dueño del proyecto,
-- de forma read-only, vía su roadmap_instance).
-- ============================================================================

create table if not exists public.roadmap_step_raci (
  id uuid primary key default gen_random_uuid(),
  template_step_id uuid not null references public.roadmap_template_steps(id) on delete cascade,
  entity_name text not null,
  role text not null check (role in ('responsible', 'accountable', 'consulted', 'informed')),
  created_at timestamptz not null default now(),
  unique (template_step_id, entity_name)
);

alter table public.roadmap_step_raci enable row level security;

-- Misma visibilidad que roadmap_template_steps (advisor/admin-only) —
-- roadmap_templates/roadmap_template_steps no tienen una política de
-- "dueño del proyecto" porque no están ligados a ningún proyecto todavía
-- (son solo definiciones reutilizables).
create policy "roadmap_step_raci_select_advisor_or_admin" on public.roadmap_step_raci
  for select using (public.is_advisor() or public.is_admin());
create policy "roadmap_step_raci_insert_advisor_or_admin" on public.roadmap_step_raci
  for insert with check (public.is_advisor() or public.is_admin());
create policy "roadmap_step_raci_update_advisor_or_admin" on public.roadmap_step_raci
  for update using (public.is_advisor() or public.is_admin());
create policy "roadmap_step_raci_delete_advisor_or_admin" on public.roadmap_step_raci
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists roadmap_step_raci_template_step_id_idx on public.roadmap_step_raci(template_step_id);

create table if not exists public.roadmap_instance_step_raci (
  id uuid primary key default gen_random_uuid(),
  instance_step_id uuid not null references public.roadmap_instance_steps(id) on delete cascade,
  entity_name text not null,
  role text not null check (role in ('responsible', 'accountable', 'consulted', 'informed')),
  created_at timestamptz not null default now(),
  unique (instance_step_id, entity_name)
);

alter table public.roadmap_instance_step_raci enable row level security;

-- Same visibility as roadmap_instance_steps: advisor/admin, or the owner
-- of the project the instance is linked to (read-only — no owner
-- insert/update/delete policy on purpose, same as the parent table).
create policy "roadmap_instance_step_raci_select_own_or_advisor" on public.roadmap_instance_step_raci
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.roadmap_instance_steps ris
      join public.roadmap_instances ri on ri.id = ris.instance_id
      join public.projects pr on pr.id = ri.project_id
      where ris.id = roadmap_instance_step_raci.instance_step_id and pr.user_id = auth.uid()
    )
  );
create policy "roadmap_instance_step_raci_insert_advisor_or_admin" on public.roadmap_instance_step_raci
  for insert with check (public.is_advisor() or public.is_admin());
create policy "roadmap_instance_step_raci_update_advisor_or_admin" on public.roadmap_instance_step_raci
  for update using (public.is_advisor() or public.is_admin());
create policy "roadmap_instance_step_raci_delete_advisor_or_admin" on public.roadmap_instance_step_raci
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists roadmap_instance_step_raci_instance_step_id_idx on public.roadmap_instance_step_raci(instance_step_id);

comment on table public.roadmap_step_raci is 'RACI role (Responsible/Accountable/Consulted/Informed) per entity for a roadmap_template_steps row. See migration_v42_roadmap_raci.sql. roadmap_template_steps.entity_name/involved_entities are kept as a derived backward-compatibility summary.';
comment on table public.roadmap_instance_step_raci is 'Same as roadmap_step_raci but for a live roadmap_instance_steps row — copied from the template at instance-creation time, then independently editable.';

-- ============================================================================
-- Verificación
-- ============================================================================
select table_name, column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name in ('roadmap_step_raci', 'roadmap_instance_step_raci')
order by table_name, ordinal_position;

select policyname, cmd, tablename
from pg_policies
where schemaname = 'public'
  and tablename in ('roadmap_step_raci', 'roadmap_instance_step_raci')
order by tablename, policyname;
