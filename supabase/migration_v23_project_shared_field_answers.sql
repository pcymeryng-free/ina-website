-- ============================================================================
-- Migration v23: shared field-answer pool per project
-- Run once in Supabase SQL Editor.
--
-- A project can have several guided templates filled in over its lifetime
-- (its own project-type template, an umbrella Program template, a
-- preparation-funding Program template, one or more financing Program
-- templates — see migration_v21_program_funding_stage_and_applications.sql).
-- Several of those templates ask for the same underlying facts (applicant/
-- organization name, contact email, total requested amount, country, etc.).
-- This adds a single flat jsonb "pool" of field_key -> value on the project
-- itself, populated two ways:
--   1. Whenever the submitter fills in ANY template for this project, every
--      answer they typed is merged into the pool (see
--      INAPlatform.mergeSharedFieldAnswers() in assets/platform.js).
--   2. Whenever the submitter clicks "Autocomplete from documents" on a
--      template (app/project-template.html), fields not already in the pool
--      are extracted from the project's uploaded documents by
--      /api/extract-template-data.js and merged in.
-- Opening a LATER template for the same project (e.g. the FSU financing
-- template after the USTDA preparation template) then pre-fills whatever the
-- pool already has for matching field keys — same key name, same value,
-- typed/extracted once — instead of asking the submitter to enter it again.
--
-- No RLS changes needed: this column lives on public.projects, and the
-- existing projects_update_own_or_assigned_advisor policy already covers
-- writes to it the same way it already covers every other project field.
-- ============================================================================

alter table public.projects
  add column if not exists shared_field_answers jsonb not null default '{}'::jsonb;

comment on column public.projects.shared_field_answers is
  'Flat {field_key: value} pool of facts already known about this project, shared across every template (project-type, umbrella Program, preparation-funding Program, financing Program templates) so the same fact is not re-entered for each one. Populated by INAPlatform.mergeSharedFieldAnswers() on every template submit, and by /api/extract-template-data.js when the submitter uses "Autocomplete from documents". Purely a convenience cache — never the source of truth for any individual template''s own template_answers/description.';
