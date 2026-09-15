-- ============================================================================
-- Migration v40: framework_analysis bilingüe (columnas _en)
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run. Es seguro correrlo más de una
-- vez ("if not exists").
--
-- PROBLEMA QUE RESUELVE
-- app/project.html, sección "Framework Analysis Results": cuando el
-- Autoevaluación (source='manual') cambia de idioma, el texto se
-- recalcula al vuelo en el idioma activo (usa las respuestas Likert
-- crudas guardadas en raw_model_output). Pero el Análisis IA
-- (source='ai') no tenía ningún mecanismo equivalente: dimensions,
-- gap_roadmap, financing_recommendations y summary son texto libre
-- generado una sola vez y guardado tal cual — si se generó/cargó en
-- español, se muestra en español sin importar el idioma que el usuario
-- tenga seleccionado en la interfaz.
--
-- QUÉ CAMBIA
-- Agrega 4 columnas nuevas, todas nullable, a framework_analysis:
--   - dimensions_en jsonb
--   - gap_roadmap_en jsonb
--   - financing_recommendations_en jsonb
--   - summary_en text
-- Las columnas SIN sufijo (dimensions, gap_roadmap,
-- financing_recommendations, summary) siguen siendo la fuente en
-- español — así quedó cargado hasta ahora todo el contenido de la
-- plataforma — y las nuevas columnas _en son la traducción al inglés,
-- null hasta que exista.
--
-- Este SQL solo toca el esquema. El resto del fix son 3 cambios de
-- código, ya hechos en esta misma sesión:
--   1. api/analyze-project.js: el prompt le pide al modelo devolver texto
--      en ambos idiomas en una sola respuesta, y el endpoint persiste las
--      4 columnas _en junto con las de siempre en cada Análisis IA nuevo.
--   2. assets/platform.js: INAPlatform.localizeAnalysis(a, lang) — dado
--      un row de framework_analysis y un idioma, arma el objeto a
--      renderizar tomando el campo _en si existe, o el campo en español
--      si no (nunca deja un campo vacío).
--   3. app/project.html: tanto renderAnalysis() (vista en pantalla) como
--      el generador de PDF del proyecto pasan por localizeAnalysis() antes
--      de mostrar el resumen, la hoja de ruta de brechas y las
--      recomendaciones de financiamiento.
--
-- Los análisis ya cargados (Cruce Transandíno, AlertAR, y los 18 de la
-- planilla de pipeline) quedan con las columnas _en en null hasta que se
-- corra el SQL de backfill de traducción aparte (ver
-- supabase/data_ai_analysis_backfill_en_*.sql) — hasta entonces la
-- interfaz en inglés sigue mostrando el texto en español para esos
-- proyectos específicos (fallback, no un error).
-- ============================================================================

alter table public.framework_analysis
  add column if not exists dimensions_en jsonb;
comment on column public.framework_analysis.dimensions_en is 'English translation of dimensions (same shape: {key: {score, rationale}}). Null = not translated yet, UI falls back to dimensions (Spanish). See migration_v40_bilingual_analysis.sql.';

alter table public.framework_analysis
  add column if not exists gap_roadmap_en jsonb;
comment on column public.framework_analysis.gap_roadmap_en is 'English translation of gap_roadmap (same shape: [{priority, action}]). Null = not translated yet, UI falls back to gap_roadmap (Spanish). See migration_v40_bilingual_analysis.sql.';

alter table public.framework_analysis
  add column if not exists financing_recommendations_en jsonb;
comment on column public.framework_analysis.financing_recommendations_en is 'English translation of financing_recommendations (same shape: [{mechanism, rationale}]). Null = not translated yet, UI falls back to financing_recommendations (Spanish). See migration_v40_bilingual_analysis.sql.';

alter table public.framework_analysis
  add column if not exists summary_en text;
comment on column public.framework_analysis.summary_en is 'English translation of summary. Null = not translated yet, UI falls back to summary (Spanish). See migration_v40_bilingual_analysis.sql.';

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'framework_analysis'
  and column_name in ('dimensions', 'dimensions_en', 'gap_roadmap', 'gap_roadmap_en',
                       'financing_recommendations', 'financing_recommendations_en',
                       'summary', 'summary_en')
order by column_name;
