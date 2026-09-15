-- ============================================================================
-- INA Platform — Migration v18: programs.template_key
--
-- Adds an optional pointer from a Program to a guided, program-specific
-- intake form — assets/platform.js's new PROGRAM_TEMPLATES registry
-- (parallel to the existing project-type-keyed PROJECT_TEMPLATES). First
-- use case: ENACOM's "Participación en Instrumentos de Deuda en el Mercado
-- de Capitales" financing line (Resolución 1191/2025 and its Annex, under
-- the Programa "FINANCIAMIENTO Y APOYO A PROVEEDORES DE SERVICIOS DE TIC",
-- Res. 950/25) isn't itself an infrastructure project type — it can fund
-- last-mile, wholesale-interconnection or TIC-applied-AI projects alike —
-- so its template is attached to the Program instead of to a project_type.
--
-- No CHECK constraint: template_key is purely a lookup key consumed by
-- INAPlatform.programTemplateFor() client-side. An unrecognized or stale
-- value just means the "Fill using template" button doesn't show up on
-- new-project.html — it never blocks a program insert/update the way
-- projects.project_type's CHECK constraint would.
--
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
-- ============================================================================

alter table public.programs
  add column if not exists template_key text;
