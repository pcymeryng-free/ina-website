-- ============================================================================
-- INA Platform — Migration v11: programs.types
--
-- Adds a declared, editable "program type" attribute: a list of one or
-- more infrastructure types (drawn from the same catalog as
-- projects.project_type) that a Program covers.
--
-- Unlike a project — always a single type, see migration_v10 — a Program
-- CAN be multiple types. This is a real, stored attribute set by the
-- program's owner (typically when creating it, before any projects exist
-- under it yet), separate from the informational "types spanned by this
-- program's actual member projects" that app/programs.html also computes
-- on the fly from projects.project_type. Both can be shown; this migration
-- only adds the declared one.
--
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
-- ============================================================================

alter table public.programs
  add column if not exists types text[] not null default '{}';

alter table public.programs
  drop constraint if exists programs_types_check;

alter table public.programs
  add constraint programs_types_check check (types <@ array[
    'submarine_cable',
    'fiber_backbone_last_mile',
    'fixed_wireless_access',
    'ai_datacenter',
    'satellite_constellation',
    'other'
  ]::text[]);
