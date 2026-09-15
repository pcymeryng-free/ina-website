-- ============================================================================
-- INA Platform — Migration v7: beneficiary count + Universal Service Funds
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
--
-- Why: ENACOM's Fondo de Servicio Universal "carpeta técnica" format (the
-- official technical-file structure for the "Financiamiento y Apoyo a
-- Proveedores de Servicios de TIC" program, Resolución ENACOM N° 950/25)
-- has a dedicated section for "cantidad de hogares, comercios y
-- establecimientos públicos potencialmente beneficiados" — the key impact
-- metric for evaluating a Universal Service submission. INA's project
-- model had no equivalent field.
--
-- What this adds:
--   projects.beneficiary_count (integer, nullable) — households/
--   beneficiaries reached. Optional and purely informational/filterable;
--   doesn't affect scoring.
--
-- Note: "Universal Service Funds" as a 9th financing mechanism (alongside
-- the existing 8 in the Multilateral Finance Navigator™) doesn't require
-- a schema change — it only touches api/analyze-project.js's prompt and
-- assets/platform.js's suggestion logic, both deployed via the website
-- files, not the database.
-- ============================================================================

alter table public.projects
  add column if not exists beneficiary_count integer;

alter table public.projects
  drop constraint if exists projects_beneficiary_count_check;
alter table public.projects
  add constraint projects_beneficiary_count_check check (beneficiary_count is null or beneficiary_count >= 0);
