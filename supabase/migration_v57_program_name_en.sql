-- ============================================================================
-- migration_v57_program_name_en.sql
--
-- Pablo, sep 2026: "lo que no esta traducido son los titulos de los
-- programas de financiamiento" — flagged while reviewing the new
-- app/project-financing.html screen, but the root cause is platform-wide:
-- programs.name has always been a single plain-text field (entered once, in
-- whatever language, when the program is created via new-program.html), so
-- it never changes when a viewer toggles the site to English — everywhere
-- a program's name is shown (dashboard.html, project.html,
-- project-financing.html, financing-programs.html, financing-program.html,
-- the AI Financing Recommendation cards, program pickers) it stays in
-- whatever language it was typed in, regardless of the UI language.
--
-- Fix: add an OPTIONAL English name, same bilingual convention already used
-- for AI-generated content (framework_analysis.*_en, migration_v40) and
-- financing_recommendations.*_en (migration_v52) — an admin/advisor can fill
-- it in when creating or editing a Program; INAPlatform.programDisplayName()
-- in assets/platform.js picks name_en when the viewer is in English and it's
-- been filled in, and falls back to the original name otherwise (so nothing
-- breaks for the ~20 existing programs that don't have one yet).
--
-- Run this in Supabase SQL Editor. Re-running supabase/schema.sql afterwards
-- is NOT required — schema.sql has already been updated to include this
-- column for any FRESH database setup; existing databases need this
-- migration file run once.
-- ============================================================================

alter table public.programs
  add column if not exists name_en text;

comment on column public.programs.name_en is
  'Optional English name for this program — shown instead of name when the viewer has the site in English (see INAPlatform.programDisplayName() in assets/platform.js). NULL/empty falls back to name everywhere.';
