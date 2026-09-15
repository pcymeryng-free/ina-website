-- ============================================================================
-- INA Platform — Migration v29: distinguish the entity RESPONSIBLE for a
-- gestión step from the (possibly several) entities INVOLVED in it
--
-- Pablo: "cada gestión tiene una entidad responsable de la gestión y
-- entidades involucradas en ese paso de la gestión."
--
-- gestion_template_steps.entity_name / entity_type already existed (added
-- by migration_v26_gestion_templates.sql) and now formally take on that
-- meaning — "the one entity that owns/drives this step" — no column
-- rename, just a clarified comment, so every existing place that already
-- reads/writes those two columns (replaceGestionTemplateSteps(),
-- createGestionInstance(), new-gestion-template.html, gestion-instance.html)
-- keeps working unchanged.
--
-- New: involved_entities (text[]) — a free-form list of the OTHER entities
-- that participate in the step alongside the responsible one (e.g. a
-- spectrum-authorization step might be the applicant's responsibility, but
-- involve the regulator, a mobile operator, and civil protection all at
-- once). Mirrored onto gestion_instance_steps too, since steps are copied
-- there verbatim at instance-creation time — see
-- migration_v27_gestion_instances.sql / createGestionInstance().
-- ============================================================================

alter table public.gestion_template_steps
  add column if not exists involved_entities text[] not null default '{}'::text[];

alter table public.gestion_instance_steps
  add column if not exists involved_entities text[] not null default '{}'::text[];

comment on column public.gestion_template_steps.entity_name is
  'The entity responsible for carrying out this step (was described as "entity involved" before migration_v29 — same column, clarified meaning). See involved_entities for other participating entities.';
comment on column public.gestion_template_steps.entity_type is
  'Nature (public/private/mixed) of the responsible entity in entity_name above.';
comment on column public.gestion_template_steps.involved_entities is
  'Free-form names of other entities that participate in this step, besides the one responsible for it (entity_name). Added by migration_v29.';

comment on column public.gestion_instance_steps.entity_name is
  'Same meaning as gestion_template_steps.entity_name (the responsible entity) — copied at instance creation.';
comment on column public.gestion_instance_steps.entity_type is
  'Same meaning as gestion_template_steps.entity_type — copied at instance creation.';
comment on column public.gestion_instance_steps.involved_entities is
  'Same meaning as gestion_template_steps.involved_entities — copied at instance creation. Added by migration_v29.';
