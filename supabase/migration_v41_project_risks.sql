-- ============================================================================
-- Migration v41: Matriz de Riesgos (Risk Register) por proyecto
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run. Es seguro correrlo más de una
-- vez ("if not exists" / "or replace" en todo lo que sigue).
--
-- Ítem 1 del horizonte "Mediano plazo (3–9 meses)" de la hoja de ruta
-- propuesta en INA_Project_Structuring_Framework_y_Plataforma.pdf
-- (sección 9.3).
--
-- PROBLEMA QUE RESUELVE
-- Hasta ahora el único lugar donde aparecían riesgos era como texto libre
-- dentro de framework_analysis.dimensions.risk_mitigation.rationale (un
-- párrafo redactado por el Análisis IA o la Autoevaluación) — no hay ningún
-- registro estructurado, con severidad y seguimiento, que un advisor pueda
-- mantener a lo largo de la vida del proyecto. Esta migración agrega ese
-- registro.
--
-- QUÉ CAMBIA
--   public.project_risks — un riesgo por fila: categoría, probabilidad e
--   impacto (escala 1-5 cada uno, estilo Likert — mismo lenguaje que la
--   Autoevaluación de 9 dimensiones), risk_score calculado automáticamente
--   (probability * impact, columna generada, rango 1-25), medidas de
--   mitigación, entidad responsable de monitorearlo, estado, fechas.
--
-- PERMISOS (decisión explícita de Pablo)
--   Solo advisor/admin pueden cargar/editar/eliminar riesgos — igual que el
--   Roadmap (project_roadmaps/roadmap_instances). El dueño del proyecto ve
--   la matriz de riesgos de su proyecto pero en solo lectura (misma lógica
--   que "project_roadmaps_select_own_or_advisor").
--
-- La banda de severidad (Low/Medium/High/Critical) a partir de risk_score
-- se calcula en el cliente (assets/platform.js: riskScoreBand()), no en la
-- base — mismo patrón ya usado para las bandas de color de los scores FSU/
-- Autoevaluación/IA en el dashboard (#418/#419).
-- ============================================================================

create table if not exists public.project_risks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  description text,
  category text not null default 'other' check (category in (
    'legal_regulatory', 'technical', 'financial', 'market_demand',
    'environmental_social', 'governance', 'operational', 'political', 'other'
  )),
  -- Escala 1 (muy baja/muy bajo) a 5 (muy alta/muy alto), mismo lenguaje
  -- Likert que assessment.html.
  probability int not null check (probability between 1 and 5),
  impact int not null check (impact between 1 and 5),
  -- Columna generada: 1 a 25. La banda (low/medium/high/critical) se
  -- deriva en el cliente — ver riskScoreBand() en assets/platform.js.
  risk_score int generated always as (probability * impact) stored,
  mitigation_measures text,
  owner_entity_name text,
  status text not null default 'open' check (status in (
    'open', 'mitigating', 'monitoring', 'closed'
  )),
  identified_date date not null default current_date,
  target_resolution_date date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.project_risks enable row level security;

-- Mismo patrón que project_roadmaps_select_own_or_advisor: el dueño del
-- proyecto puede VER (no escribir) los riesgos de su proyecto; advisor/
-- admin ven todos.
create policy "project_risks_select_own_or_advisor" on public.project_risks
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = project_risks.project_id and pr.user_id = auth.uid()
    )
  );
create policy "project_risks_insert_advisor_or_admin" on public.project_risks
  for insert with check (public.is_advisor() or public.is_admin());
create policy "project_risks_update_advisor_or_admin" on public.project_risks
  for update using (public.is_advisor() or public.is_admin());
create policy "project_risks_delete_advisor_or_admin" on public.project_risks
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists project_risks_project_id_idx on public.project_risks(project_id);
create index if not exists project_risks_status_idx on public.project_risks(status);

comment on table public.project_risks is 'Matriz de Riesgos por proyecto (registro estructurado, distinto del texto libre de framework_analysis.dimensions.risk_mitigation). Ver migration_v41_project_risks.sql.';
comment on column public.project_risks.risk_score is 'probability * impact, 1 a 25. La banda de severidad (low ≤4 / medium 5-9 / high 10-15 / critical ≥16) se calcula en el cliente — riskScoreBand() en assets/platform.js.';
comment on column public.project_risks.owner_entity_name is 'Entidad responsable de monitorear/mitigar este riesgo (texto libre, mismo concepto que entity_name en roadmap_template_steps) — no necesariamente el dueño del proyecto.';

-- updated_at se actualiza desde assets/platform.js en cada UPDATE (mismo
-- patrón que updateProject/updateProgram/etc. en este esquema — no hay
-- trigger genérico de base de datos para esto en el resto de las tablas).

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'project_risks'
order by ordinal_position;

select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'project_risks'
order by policyname;
