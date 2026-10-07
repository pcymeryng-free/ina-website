-- ============================================================================
-- migration_v72_bilingual_free_text.sql
--
-- QUÉ AGREGA
-- Pablo: "necesito que se traduzcan todos los textos ingresados manualmente
-- al idioma seleccionado. No quiero que en un reporte o en pantalla haya
-- mezcla de idiomas." Primera tanda (app/project.html + su "Download PDF"
-- — otras pantallas como risk-matrix.html/roadmap-instance.html quedan
-- para una próxima vuelta).
--
-- Mismo patrón "traducir una vez y guardar" que ya usa framework_analysis
-- desde migration_v40_bilingual_analysis.sql: la columna sin sufijo sigue
-- siendo la fuente de verdad en español; la columna _en es nullable y
-- queda vacía hasta que INAPlatform.ensureEnglishTranslations() (ver
-- assets/platform.js) la complete la primera vez que alguien ve el
-- proyecto en inglés — ver api/translate-project-text.js. Null en _en
-- siempre cae de vuelta al texto en español (nunca un campo vacío).
--
-- shared_field_answers_en es el equivalente de shared_field_answers pero
-- solo para los campos 'textarea' de la plantilla Datos Técnicos del tipo
-- de proyecto (texto libre real) — los campos 'text' se excluyen a
-- propósito porque mezclan cifras, nombres propios y frases cortas sin
-- ninguna señal de tipo que permita distinguirlos de forma automática.
--
-- Invalidación de caché: INAPlatform.updateProject()/updateProjectFinancing()/
-- updateProjectPhase()/mergeSharedFieldAnswers() en assets/platform.js
-- limpian la(s) columna(s) _en correspondiente(s) cada vez que se guarda
-- el texto en español de origen, para que se retraduzca solo en la
-- próxima vista en inglés — no hace falta ningún trigger de Postgres (no
-- hay ninguno en esta base para tablas de contenido, y esta migración no
-- rompe esa convención).
--
-- QUÉ NO CAMBIA
-- No toca project_risks ni roadmap_instances (próxima vuelta). No agrega
-- traducción para projects.name/generating_entity_name ni ningún otro
-- nombre propio/identificador — esos se muestran tal cual se escribieron,
-- a propósito.
-- ============================================================================

alter table public.projects add column if not exists description_en text;
alter table public.projects add column if not exists fsu_scope_en text;
alter table public.projects add column if not exists other_financing_notes_en text;
alter table public.projects add column if not exists shared_field_answers_en jsonb;

alter table public.project_phases add column if not exists name_en text;
alter table public.project_phases add column if not exists scope_en text;

-- Un noveno agente de IA ('translate-project-text') se suma al catálogo de
-- migration_v71_agent_hints.sql — mismo mecanismo de hint editable en vivo
-- desde app/ai-hints.html que los otros 8.
alter table public.agent_hints drop constraint if exists agent_hints_agent_key_check;
alter table public.agent_hints add constraint agent_hints_agent_key_check check (agent_key in (
  'analyze-project', 'extract-project-data', 'extract-success-case',
  'extract-business-card', 'extract-template-data', 'recommend-financing',
  'generate-proposal', 'promotion-agent', 'translate-project-text'
));
