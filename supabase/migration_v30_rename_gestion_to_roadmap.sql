-- ============================================================================
-- INA Platform — Migration v30: rename "Gestión" → "Roadmap" everywhere
--
-- Pablo: "cambiar el término gestión por Roadmap (Hoja de ruta)." Full scope
-- (per his explicit choice): user-facing text AND file names AND the
-- database. This migration is the database half — renames every table,
-- index and RLS policy that had "gestion" in its name to the equivalent
-- "roadmap" name. Column names, data, and every foreign-key relationship
-- are untouched (Postgres tracks FKs by OID internally, not by name, so
-- renaming a table never breaks a reference to/from it — safe to run these
-- in any order).
--
-- Renamed:
--   gestion_templates        -> roadmap_templates
--   gestion_template_steps   -> roadmap_template_steps
--   gestion_instances        -> roadmap_instances
--   gestion_instance_steps   -> roadmap_instance_steps
--   project_gestiones        -> project_roadmaps   (legacy/unused table,
--                                renamed too for a consistent schema, even
--                                though nothing in the app reads/writes it)
--
-- Run this AFTER migration_v29_gestion_step_entities.sql. Application code
-- (assets/platform.js, the three renamed app/*.html pages, everything else)
-- must be deployed at the same time as this migration — the two are not
-- independently compatible (old code expects gestion_*, new code expects
-- roadmap_*).
-- ============================================================================

-- ---------- gestion_templates -> roadmap_templates ----------
alter table public.gestion_templates rename to roadmap_templates;
alter index public.gestion_templates_project_type_idx rename to roadmap_templates_project_type_idx;
alter policy "gestion_templates_select_advisor_or_admin" on public.roadmap_templates rename to "roadmap_templates_select_advisor_or_admin";
alter policy "gestion_templates_insert_advisor_or_admin" on public.roadmap_templates rename to "roadmap_templates_insert_advisor_or_admin";
alter policy "gestion_templates_update_advisor_or_admin" on public.roadmap_templates rename to "roadmap_templates_update_advisor_or_admin";
alter policy "gestion_templates_delete_advisor_or_admin" on public.roadmap_templates rename to "roadmap_templates_delete_advisor_or_admin";

-- ---------- gestion_template_steps -> roadmap_template_steps ----------
alter table public.gestion_template_steps rename to roadmap_template_steps;
alter index public.gestion_template_steps_template_id_idx rename to roadmap_template_steps_template_id_idx;
alter policy "gestion_template_steps_select_advisor_or_admin" on public.roadmap_template_steps rename to "roadmap_template_steps_select_advisor_or_admin";
alter policy "gestion_template_steps_insert_advisor_or_admin" on public.roadmap_template_steps rename to "roadmap_template_steps_insert_advisor_or_admin";
alter policy "gestion_template_steps_update_advisor_or_admin" on public.roadmap_template_steps rename to "roadmap_template_steps_update_advisor_or_admin";
alter policy "gestion_template_steps_delete_advisor_or_admin" on public.roadmap_template_steps rename to "roadmap_template_steps_delete_advisor_or_admin";

-- ---------- project_gestiones -> project_roadmaps (legacy/unused) ----------
alter table public.project_gestiones rename to project_roadmaps;
alter index public.project_gestiones_project_id_idx rename to project_roadmaps_project_id_idx;
alter index public.project_gestiones_template_step_id_idx rename to project_roadmaps_template_step_id_idx;
alter policy "project_gestiones_select_own_or_advisor" on public.project_roadmaps rename to "project_roadmaps_select_own_or_advisor";
alter policy "project_gestiones_insert_advisor_or_admin" on public.project_roadmaps rename to "project_roadmaps_insert_advisor_or_admin";
alter policy "project_gestiones_update_advisor_or_admin" on public.project_roadmaps rename to "project_roadmaps_update_advisor_or_admin";
alter policy "project_gestiones_delete_advisor_or_admin" on public.project_roadmaps rename to "project_roadmaps_delete_advisor_or_admin";

-- ---------- gestion_instances -> roadmap_instances ----------
alter table public.gestion_instances rename to roadmap_instances;
alter index public.gestion_instances_project_id_idx rename to roadmap_instances_project_id_idx;
alter index public.gestion_instances_template_id_idx rename to roadmap_instances_template_id_idx;
alter policy "gestion_instances_select_own_or_advisor" on public.roadmap_instances rename to "roadmap_instances_select_own_or_advisor";
alter policy "gestion_instances_insert_advisor_or_admin" on public.roadmap_instances rename to "roadmap_instances_insert_advisor_or_admin";
alter policy "gestion_instances_update_advisor_or_admin" on public.roadmap_instances rename to "roadmap_instances_update_advisor_or_admin";
alter policy "gestion_instances_delete_advisor_or_admin" on public.roadmap_instances rename to "roadmap_instances_delete_advisor_or_admin";

-- ---------- gestion_instance_steps -> roadmap_instance_steps ----------
alter table public.gestion_instance_steps rename to roadmap_instance_steps;
alter index public.gestion_instance_steps_instance_id_idx rename to roadmap_instance_steps_instance_id_idx;
alter index public.gestion_instance_steps_template_step_id_idx rename to roadmap_instance_steps_template_step_id_idx;
alter policy "gestion_instance_steps_select_own_or_advisor" on public.roadmap_instance_steps rename to "roadmap_instance_steps_select_own_or_advisor";
alter policy "gestion_instance_steps_insert_advisor_or_admin" on public.roadmap_instance_steps rename to "roadmap_instance_steps_insert_advisor_or_admin";
alter policy "gestion_instance_steps_update_advisor_or_admin" on public.roadmap_instance_steps rename to "roadmap_instance_steps_update_advisor_or_admin";
alter policy "gestion_instance_steps_delete_advisor_or_admin" on public.roadmap_instance_steps rename to "roadmap_instance_steps_delete_advisor_or_admin";
