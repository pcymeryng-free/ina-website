-- ============================================================================
-- INA Platform — Migration v28: a Gestion is not necessarily tied to a project
--
-- Pablo's correction: a Gestion is often started BEFORE the project it
-- concerns even exists — e.g. an Early Warning System coordination process
-- a regulator kicks off with a municipality, which may or may not turn
-- into a submitted project later. gestion_instances.project_id was
-- originally "not null" (see migration_v27_gestion_instances.sql); this
-- relaxes it to nullable so a Gestion can be created standalone, with no
-- project selected at all, and optionally linked to one if/when it makes
-- sense.
--
-- No RLS change needed: gestion_instances_select_own_or_advisor already
-- falls through to "advisor/admin only" whenever the project-ownership
-- EXISTS subquery finds nothing to match (which is exactly what happens
-- when project_id is null) — there's simply no "project owner" to also
-- grant read access to for a project-less Gestion. Same for
-- gestion_instance_steps' matching policy, which joins through
-- gestion_instances.
--
-- Run this ONCE in your EXISTING Supabase project, AFTER migration_v27:
-- Dashboard → SQL Editor → New query → paste this whole file → Run.
-- ============================================================================

alter table public.gestion_instances
  alter column project_id drop not null;
