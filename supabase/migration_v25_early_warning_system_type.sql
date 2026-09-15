-- ============================================================================
-- INA Platform — Migration v25: early_warning_system project type
--
-- Adds a new project_type value, 'early_warning_system', for public-interest
-- projects that develop/deploy broadcast-based early warning solutions —
-- alerting the population to risk events (earthquake, storm, hurricane,
-- tsunami, etc.) via Cell Broadcast / SMS-CB, EAS-style radio/TV interrupt,
-- or similar mass-notification channels. This is the first project type
-- built together with the new "Gestiones" checklist system (see
-- supabase/migration_v26_gestion_templates.sql) — a regulator-defined list
-- of administrative/regulatory procedures (with public and/or private
-- entities involved) that a project of this kind needs to work through,
-- distinct from and complementary to the free-text guided template in
-- assets/platform.js's EARLY_WARNING_TEMPLATE.
--
-- Same pattern as supabase/migration_v17_wholesale_neutral_network_type.sql:
-- only widens the two existing CHECK constraints that enumerate valid
-- project_type / program type values (projects.project_type and
-- programs.types, see supabase/schema.sql) — no new columns or tables here.
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
    'other'
  ]::text[]);
