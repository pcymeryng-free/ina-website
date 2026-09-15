-- ============================================================================
-- INA Platform — Migration v10: remove projects.secondary_types
--
-- ⚠️ READ BEFORE RUNNING — this migration DROPS a column and its data.
--
-- Why: the platform's model is now that a PROJECT is always a single type,
-- and a PROGRAM (see migration_v9_programs.sql) is what can span several
-- types — by containing several single-type projects, each financed and
-- analyzed independently (e.g. Chubut's "Hub Digital Patagónico" program
-- containing a submarine cable project, a backbone project and a
-- last-mile project, rather than one project tagged with three types).
-- The earlier `secondary_types` array directly on `projects` modeled
-- multi-component initiatives the wrong way for this — it's superseded by
-- Programs and removed here.
--
-- BEFORE running this: if you already submitted any project with one or
-- more secondary types set (check with the query below), decide whether
-- each secondary type should become its own separate project under a
-- shared Program — this migration does not do that split for you, it only
-- deletes the column and the data in it.
--
--   select id, name, project_type, secondary_types from public.projects
--   where secondary_types is not null and array_length(secondary_types, 1) > 0;
--
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
-- ============================================================================

alter table public.projects
  drop constraint if exists projects_secondary_types_check;

alter table public.projects
  drop column if exists secondary_types;
