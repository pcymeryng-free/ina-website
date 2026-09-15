-- ============================================================================
-- migration_v56_financing_required_percentage.sql
--
-- Pablo, sep 2026: "en la edición de un proyecto, en la parte de Financing,
-- incluir solo el monto total del proyecto en pesos y dólares y el %
-- requerido de financiación. La gestión de financiación separarla de la
-- edición del proyecto." Financing management (FSU, applying to Programs,
-- "other source", the AI recommendation) moves out of new-project.html into
-- its own page, app/project-financing.html, reached from a new nav entry on
-- project.html. All that's left in the project edit form's Financing step
-- is budget_amount/budget_amount_usd (already existed) plus this one new
-- column.
--
-- projects.financing_required_percentage — % of budget_amount that actually
-- needs to be raised through external financing (the rest assumed already
-- covered by confirmed own capital/equity). NULL means "not specified",
-- which every caller treats as 100 — see
-- INAPlatform.effectiveFinancingRequiredPercentage() in assets/platform.js.
-- This is the TARGET the financing-management page tries to reach with FSU +
-- Program shares + "other source" combined — distinct from
-- INAPlatform.computeFinancingCoverage()'s totalPct, which is simply how
-- much is CURRENTLY allocated regardless of the target.
--
-- Run this in Supabase SQL Editor. Re-running supabase/schema.sql afterwards
-- is NOT required — schema.sql has already been updated to include this
-- column for any FRESH database setup; existing databases need this
-- migration file run once.
-- ============================================================================

alter table public.projects
  add column if not exists financing_required_percentage numeric
    check (financing_required_percentage is null or (financing_required_percentage >= 0 and financing_required_percentage <= 100));

comment on column public.projects.financing_required_percentage is
  '% of budget_amount that needs external financing (rest assumed covered by own capital) — NULL treated as 100 by every caller. Target for app/project-financing.html''s coverage bar; distinct from computeFinancingCoverage()''s totalPct (how much is currently allocated).';
