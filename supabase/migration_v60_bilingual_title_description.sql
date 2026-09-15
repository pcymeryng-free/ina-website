-- ============================================================================
-- migration_v60_bilingual_title_description.sql
--
-- Pablo, sep 2026: "tanto en Success Cases como en Financing Programs hay
-- que poner en inglés todo el contenido cuando el idioma seleccionado es
-- el inglés y en español cuando el idioma seleccionado es el español."
--
-- Two remaining single-language free-text fields found by audit (every
-- other field already had an _en counterpart or is a proper name that
-- isn't meant to be translated, e.g. provider/organization/financing_entity):
--
-- 1. success_cases.title — summary_es/summary_en and metrics_es/metrics_en
--    already existed (migration_v59), but the case TITLE itself
--    ("Conexión de 2.000 instituciones educativas", etc.) was Spanish-only
--    and shown as-is regardless of the viewer's selected language.
-- 2. programs.description — name/name_en already existed
--    (migration_v57_program_name_en.sql), but the free-text description
--    shown on app/financing-program.html was single-language.
--
-- Both follow the exact same optional/fallback convention as
-- programs.name_en: NULL means "not provided", and every display path
-- falls back to the base-language field so nothing breaks for existing
-- rows until someone fills in the English text. See
-- INAPlatform.successCaseDisplayTitle() / programDisplayDescription() in
-- assets/platform.js.
--
-- Run this in Supabase SQL Editor. Re-running supabase/schema.sql
-- afterwards is NOT required — schema.sql has already been updated to
-- include these columns for any FRESH database setup; existing databases
-- need this migration file run once.
-- ============================================================================

alter table public.success_cases
  add column if not exists title_en text;

comment on column public.success_cases.title_en is
  'Optional English title — shown instead of title only when the viewer has the site in English. NULL/blank means "not provided", falls back to title in both languages. See INAPlatform.successCaseDisplayTitle().';

alter table public.programs
  add column if not exists description_en text;

comment on column public.programs.description_en is
  'Optional English description — shown instead of description only when the viewer has the site in English. NULL/blank means "not provided", falls back to description in both languages. See INAPlatform.programDisplayDescription().';
