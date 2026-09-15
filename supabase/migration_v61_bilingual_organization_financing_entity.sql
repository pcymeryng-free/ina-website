-- migration_v61_bilingual_organization_financing_entity.sql
--
-- Pablo, sep 2026 (follow-up to migration_v60): "en la pantalla
-- financing_program también hay que traducir al inglés el contenido cuando
-- está seleccionado el idioma inglés." After migration_v60 covered
-- success_cases.title and programs.description, two more free-text fields on
-- Financing Programs were still single-language only and showed up
-- untranslated on financing-program.html / financing-programs.html /
-- initiatives.html regardless of the language toggle:
--
--   - programs.organization      — the entity presenting the program (almost
--                                   always entered in Spanish, e.g. "Ente
--                                   Nacional de Comunicaciones (ENACOM)").
--   - programs.financing_entity  — who actually finances it (sometimes
--                                   entered in Spanish, e.g. "Banco
--                                   Interamericano de Desarrollo (BID)",
--                                   sometimes already in English, e.g. "U.S.
--                                   International Development Finance
--                                   Corporation (DFC)").
--
-- Same optional-override-with-fallback convention as name_en
-- (migration_v57) and description_en (migration_v60): both new columns are
-- nullable; when null, the base-language column is shown in both languages
-- unchanged (no behavior change for existing rows until someone fills them
-- in). See INAPlatform.programDisplayOrganization() /
-- programDisplayFinancingEntity() in assets/platform.js.

alter table public.programs
  add column if not exists organization_en text,
  add column if not exists financing_entity_en text;

comment on column public.programs.organization_en is
  'Optional English override for organization, shown instead of it only when the viewer has the site in English. NULL falls back to organization in both languages.';

comment on column public.programs.financing_entity_en is
  'Optional English override for financing_entity, shown instead of it only when the viewer has the site in English. NULL falls back to financing_entity in both languages.';
