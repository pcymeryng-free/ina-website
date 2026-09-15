-- ============================================================================
-- INA Platform — Migration v6: secondary project types
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
--
-- Why: real-world submissions often bundle more than one infrastructure
-- component — e.g. the Chubut "Hub Digital Patagónico" concept (two Tier 4
-- datacenters + a new submarine cable landing + a terrestrial backbone
-- through the Andes) is a datacenter, a submarine cable AND a fiber
-- backbone project at once. Until now projects.project_type could only
-- hold one value, forcing an artificial single choice.
--
-- What this adds:
--   projects.secondary_types (text[], default '{}') — any additional
--   component types beyond the single PRIMARY project_type. Purely
--   informational/filtering: the primary project_type is still what
--   drives the self-assessment questionnaire's 9th (type-specific)
--   dimension and the dashboard's type icon, unchanged.
-- ============================================================================

alter table public.projects
  add column if not exists secondary_types text[] not null default '{}';

alter table public.projects
  drop constraint if exists projects_secondary_types_check;
alter table public.projects
  add constraint projects_secondary_types_check check (secondary_types <@ array[
    'submarine_cable',
    'fiber_backbone_last_mile',
    'fixed_wireless_access',
    'ai_datacenter',
    'satellite_constellation',
    'other'
  ]::text[]);
