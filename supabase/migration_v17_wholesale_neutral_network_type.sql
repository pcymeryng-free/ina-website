-- ============================================================================
-- INA Platform — Migration v17: wholesale_neutral_network project type
--
-- Adds a new project_type value, 'wholesale_neutral_network', for projects
-- under ENACOM's "Red Mayorista Neutral" Program (Resolución
-- RESOL-2025-951-APN-ENACOM#JGM, 4 de julio de 2025, y su Anexo I) — open-
-- access wholesale network deployment and/or 5G access in underserved
-- areas, financed by the Fondo del Servicio Universal.
--
-- This only widens the two existing CHECK constraints that enumerate valid
-- project_type / program type values (projects.project_type and
-- programs.types, see supabase/schema.sql) — no new columns or tables.
-- Postgres auto-names an unnamed column check constraint
-- "<table>_<column>_check", which is what's dropped/recreated below for
-- projects; programs.types already has an explicit name from migration_v11.
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
    'other'
  ]::text[]);
