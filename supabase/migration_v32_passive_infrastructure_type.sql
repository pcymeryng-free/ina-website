-- ============================================================================
-- INA Platform — Migration v32: passive_infrastructure project type
--
-- Adds a new project_type value, 'passive_infrastructure', for projects
-- centered on sharing/opening access to existing passive infrastructure
-- (electrical poles, ducts, chambers, towers, dark fiber, shelters,
-- technical spaces) between operators — e.g. CAPPI's "Programa Nacional de
-- Infraestructura Compartida y Acceso Abierto" proposal to ENACOM (June
-- 2026), modeled on Colombia's and Brazil's shared-access regulatory
-- frameworks. Distinct from 'wholesale_neutral_network' (a specific 5G/FWA
-- open-access network deployment) and from 'fiber_backbone_last_mile' (a
-- concrete fiber build) — this type is about the sharing/access regime
-- itself, which may or may not involve building any new network.
--
-- Same pattern as supabase/migration_v17_wholesale_neutral_network_type.sql
-- and supabase/migration_v25_early_warning_system_type.sql: only widens the
-- two existing CHECK constraints that enumerate valid project_type /
-- program type values (projects.project_type and programs.types, see
-- supabase/schema.sql) — no new columns or tables. Also adds a matching
-- 9th self-assessment dimension ("Shared Access & Interoperability
-- Readiness" / shared_access_readiness) in assets/platform.js — no DB
-- change needed for that part, since framework_analysis.dimensions is
-- already a free-form jsonb column.
--
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
-- ============================================================================

alter table public.projects
  drop constraint if exists projects_project_type_check;

alter table public.projects
  add constraint projects_project_type_check check (project_type in (
    'submarine_cable',
    'fiber_backbone_last_mile',
    'fixed_wireless_access',
    'wholesale_neutral_network',
    'ai_datacenter',
    'satellite_constellation',
    'early_warning_system',
    'passive_infrastructure',
    'other'
  ));

alter table public.programs
  drop constraint if exists programs_types_check;

alter table public.programs
  add constraint programs_types_check check (types <@ array[
    'submarine_cable',
    'fiber_backbone_last_mile',
    'fixed_wireless_access',
    'wholesale_neutral_network',
    'ai_datacenter',
    'satellite_constellation',
    'early_warning_system',
    'passive_infrastructure',
    'other'
  ]::text[]);
