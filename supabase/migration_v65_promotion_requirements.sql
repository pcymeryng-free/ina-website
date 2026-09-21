-- ============================================================================
-- migration_v65_promotion_requirements.sql
--
-- QUÉ AGREGA
-- Pablo: "Me gustaría que hubiera ciertos requisitos para que un proyecto
-- pueda pasar de un estado al siguiente." Dos tablas nuevas:
--
-- 1. public.promotion_requirements — un renglón de umbrales mínimos por
--    cada transición de readiness_stage (from_stage → to_stage). Configurable
--    desde una pantalla de administración nueva (app/promotion-requirements.html,
--    ver tarea #737) — NO hardcodeado en el código, por eso es tabla y no
--    constante en platform.js. Se siembran las 3 transiciones reales del
--    stepper (Concept Stage→Early Structuring, Early Structuring→Advanced
--    Structuring, Advanced Structuring→Investment Ready) con umbrales
--    progresivos sensatos, editables después desde el admin.
--
--    Los 4 requisitos elegidos por Pablo (AskUserQuestion, sep 2026):
--      - min_analysis_score: puntaje mínimo del último análisis (IA o
--        autoevaluación — public.framework_analysis.overall_score, 0-100).
--      - require_mandatory_documents: si es true, exige al menos un
--        documento adjunto en cada categoría de project_documents.document_type
--        considerada "obligatoria" (constante MANDATORY_DOCUMENT_TYPES en
--        platform.js — ver tarea #733; no existe un flag "obligatorio" en
--        el catálogo de tipos de documento hoy, así que se define ahí).
--      - min_financing_coverage_pct: % mínimo de cobertura de financiamiento
--        ya definida (INAPlatform.computeFinancingCoverage().totalPct).
--      - require_risk_matrix: si es true, exige al menos una fila cargada
--        en public.project_risks para el proyecto.
--
-- 2. public.promotion_agent_runs — historial de cada corrida del "agente de
--    IA de promoción" (ver api/promotion-agent.js, tarea #734): guarda el
--    veredicto (eligible boolean), la lista de requisitos incumplidos, y
--    las notas cualitativas del modelo, para que el asesor pueda ver
--    corridas anteriores en project.html (igual que financing_recommendations
--    o framework_analysis persisten su propio historial/última corrida).
--
-- QUÉ NO CAMBIA
-- Esto es una capa nueva y complementaria al "Project Structuring
-- Framework™" (projects.current_gate + approve_project_gate(), ver
-- migration_v39_project_gates.sql) — ese es un checklist manual de
-- entregables por gate, no está atado a readiness_stage ni a datos
-- cuantitativos del proyecto, y sigue funcionando exactamente igual. Los
-- requisitos de acá tampoco bloquean promote_project_workflow() a nivel
-- de base de datos: por decisión de Pablo ("avisar pero permitir
-- continuar"), el chequeo es responsabilidad de la capa de aplicación
-- (project.html llama a evaluatePromotionRequirements() ANTES de invocar
-- el RPC existente, y si hay requisitos incumplidos simplemente se lo
-- muestra al usuario, que igual puede confirmar con el comentario
-- obligatorio ya existente). promote_project_workflow()/
-- demote_project_workflow() no se tocan en esta migración.
-- ============================================================================

create table if not exists public.promotion_requirements (
  id uuid primary key default gen_random_uuid(),
  from_stage text not null check (from_stage in (
    'Concept Stage', 'Early Structuring', 'Advanced Structuring'
  )),
  to_stage text not null check (to_stage in (
    'Early Structuring', 'Advanced Structuring', 'Investment Ready'
  )),
  -- Puntaje mínimo (0-100) del último framework_analysis.overall_score
  -- (fuente 'ai' o 'manual', el más reciente — ver INAPlatform.getAnalysis()).
  -- Null = no se exige puntaje mínimo para esta transición.
  min_analysis_score int check (min_analysis_score is null or min_analysis_score between 0 and 100),
  -- Si es true, exige al menos un documento adjunto en cada categoría de
  -- MANDATORY_DOCUMENT_TYPES (platform.js).
  require_mandatory_documents boolean not null default false,
  -- % mínimo (0-100) de INAPlatform.computeFinancingCoverage().totalPct.
  -- Null = no se exige cobertura mínima para esta transición.
  min_financing_coverage_pct int check (min_financing_coverage_pct is null or min_financing_coverage_pct between 0 and 100),
  -- Si es true, exige al menos una fila en project_risks para el proyecto.
  require_risk_matrix boolean not null default false,
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now(),
  unique (from_stage, to_stage)
);

comment on table public.promotion_requirements is 'Umbrales mínimos configurables (admin) por transición de readiness_stage, evaluados por evaluatePromotionRequirements() en platform.js y por api/promotion-agent.js — ver migration_v65_promotion_requirements.sql.';

alter table public.promotion_requirements enable row level security;

-- Lectura: cualquier usuario autenticado (project.html necesita mostrar los
-- requisitos al advisor/admin que va a promover, y el owner puede querer
-- ver qué le falta a su propio proyecto). Escritura: solo admin, desde
-- app/promotion-requirements.html.
create policy "promotion_requirements_select_authenticated" on public.promotion_requirements
  for select using (auth.role() = 'authenticated');

create policy "promotion_requirements_write_admin" on public.promotion_requirements
  for all using (public.is_admin()) with check (public.is_admin());

-- Semilla: las 3 transiciones reales del stepper, con umbrales progresivos
-- (más exigente cuanto más avanzada la etapa destino). Editable después
-- desde el admin — estos son valores de arranque razonables, no una regla
-- de negocio fija.
insert into public.promotion_requirements (from_stage, to_stage, min_analysis_score, require_mandatory_documents, min_financing_coverage_pct, require_risk_matrix)
values
  ('Concept Stage', 'Early Structuring', 40, false, null, false),
  ('Early Structuring', 'Advanced Structuring', 55, true, 30, true),
  ('Advanced Structuring', 'Investment Ready', 70, true, 80, true)
on conflict (from_stage, to_stage) do nothing;

-- ----------------------------------------------------------------------------
-- Historial de corridas del agente de IA de promoción (api/promotion-agent.js).
-- Un row por corrida (no se sobrescribe, a diferencia de
-- financing_recommendations) — el asesor puede querer ver el historial de
-- veredictos de un proyecto a lo largo del tiempo, igual que
-- project_workflow_events guarda cada transición real.
-- ----------------------------------------------------------------------------
create table if not exists public.promotion_agent_runs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  from_stage text not null,
  to_stage text not null,
  -- Veredicto final combinando reglas + LLM (ver api/promotion-agent.js):
  -- true = habilitado para promover, false = condicionado.
  eligible boolean not null,
  -- Requisitos determinísticos incumplidos (evaluados por reglas, no por el
  -- LLM) — ej. ["min_analysis_score", "min_financing_coverage_pct"]. Vacío
  -- si eligible=true o si todos los incumplimientos son solo cualitativos.
  unmet_requirements text[] not null default '{}'::text[],
  -- Notas cualitativas del LLM (bilingüe, mismo patrón que
  -- framework_analysis._en) — el juicio del modelo sobre la
  -- razonabilidad de promover más allá de lo que las reglas ya miden.
  notes text,
  notes_en text,
  raw_model_output text,
  run_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

comment on table public.promotion_agent_runs is 'Historial de veredictos del agente de IA de promoción (reglas + LLM) — ver api/promotion-agent.js y migration_v65_promotion_requirements.sql.';

alter table public.promotion_agent_runs enable row level security;

-- Misma visibilidad que project_workflow_events: dueño del proyecto, o
-- cualquier advisor/admin. Sin policy de insert/update para clientes — cada
-- fila la escribe api/promotion-agent.js con la service role key, nunca un
-- insert directo del cliente.
create policy "promotion_agent_runs_select_own_or_advisor" on public.promotion_agent_runs
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = promotion_agent_runs.project_id and pr.user_id = auth.uid()
    )
  );

create index if not exists promotion_agent_runs_project_id_idx on public.promotion_agent_runs(project_id);
