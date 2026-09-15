-- ============================================================================
-- INA Platform — Migration v8: FSU Scoring (ENACOM Resolución 359/2025)
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
--
-- Why: ENACOM's "Manual Estratégico de Elaboración de Proyectos: Obtención
-- del Certificado de Elegibilidad ENACOM" (Resolución 359/2025) publishes a
-- 100-point selection-scoring matrix (Matriz de Autoevaluación) that MiPyME/
-- Cooperativa applicants use to self-score their fiber-to-the-home project
-- before submitting to the Fondo de Servicio Universal (FSU). It covers 7
-- named criteria: fiber penetration (20 pts), business model — wholesale
-- open access vs retail-only (20 pts), technology — XGS-PON vs GPON (15
-- pts), average speed uplift (15 pts), technology leap — greenfield vs
-- copper/wireless migration (10 pts), population density (10 pts), and the
-- applicant's track record in TIC (10 pts).
--
-- This is a separate, deterministic, ENACOM-specific formula — distinct
-- from framework_analysis (INA's own Investment Readiness Index™) — so it
-- gets its own table rather than being force-fit into the 8/9-dimension
-- shape framework_analysis uses.
--
-- What this adds: the fsu_scoring table (one row per project, upsert on
-- every save from app/fsu-scoring.html), computed client-side by
-- assets/platform.js's computeFsuScore() mirroring the manual's point
-- table exactly.
-- ============================================================================

create table if not exists public.fsu_scoring (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,

  -- Raw inputs (project owner enters these in app/fsu-scoring.html) ------
  total_hogares integer check (total_hogares is null or total_hogares >= 0),
  accesos_fibra integer check (accesos_fibra is null or accesos_fibra >= 0),
  modelo_negocio text check (modelo_negocio in ('mayorista_neutral', 'minorista_exclusiva')),
  tecnologia text check (tecnologia in ('xgs_pon', 'gpon')),
  velocidad_actual_mbps numeric check (velocidad_actual_mbps is null or velocidad_actual_mbps >= 0),
  velocidad_propuesta_mbps numeric check (velocidad_propuesta_mbps is null or velocidad_propuesta_mbps >= 0),
  salto_tecnologico text check (salto_tecnologico in ('area_blanca', 'migracion_cobre_wireless')),
  poblacion_localidad integer check (poblacion_localidad is null or poblacion_localidad >= 0),
  anos_capacidad_tecnica text check (anos_capacidad_tecnica in ('mas_5', 'entre_2_y_5', 'menos_2')),

  -- Computed breakdown, 0 to each criterion's max (recomputed and
  -- overwritten by computeFsuScore() on every save, never hand-edited) --
  score_penetracion int not null default 0,
  score_modelo_negocio int not null default 0,
  score_tecnologia int not null default 0,
  score_velocidad int not null default 0,
  score_salto_tecnologico int not null default 0,
  score_densidad int not null default 0,
  score_capacidad_tecnica int not null default 0,
  score_total int not null default 0,
  penetracion_pct numeric,
  mejora_velocidad_pct numeric,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (project_id)
);

alter table public.fsu_scoring enable row level security;

drop policy if exists "fsu_scoring_select_own_or_advisor" on public.fsu_scoring;
create policy "fsu_scoring_select_own_or_advisor" on public.fsu_scoring
  for select using (auth.uid() = user_id or public.is_advisor());

drop policy if exists "fsu_scoring_insert_own" on public.fsu_scoring;
create policy "fsu_scoring_insert_own" on public.fsu_scoring
  for insert with check (auth.uid() = user_id);

drop policy if exists "fsu_scoring_update_own" on public.fsu_scoring;
create policy "fsu_scoring_update_own" on public.fsu_scoring
  for update using (auth.uid() = user_id);

create index if not exists fsu_scoring_project_id_idx on public.fsu_scoring(project_id);
