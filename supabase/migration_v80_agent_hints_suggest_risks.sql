-- ============================================================================
-- migration_v80_agent_hints_suggest_risks.sql
-- Run this ONCE in Supabase: Dashboard → SQL Editor → New query → paste →
-- Run. Safe to re-run (drop constraint if exists + add).
--
-- QUÉ AGREGA
-- Pablo (oct 2026): el proyecto HUB Digital Chubut tenía un documento con
-- su propia matriz de riesgos y nada de eso aparecía en la Matriz de
-- Riesgos de INA — project_risks solo se cargaba a mano. El nuevo agente
-- api/suggest-risks.js (botón "Sugerir riesgos desde documentos" en
-- app/risk-matrix.html) lee los documentos y propone riesgos que el
-- advisor revisa antes de guardarlos.
--
-- Esta migración solo suma 'suggest-risks' a las claves permitidas de
-- agent_hints, para que ese agente tenga su hint editable desde
-- app/ai-hints.html como los otros 9 (ver migration_v71_agent_hints.sql y
-- migration_v72_bilingual_free_text.sql). Sin esta migración el botón
-- funciona igual; solo falla guardar un hint para ese agente.
-- ============================================================================

alter table public.agent_hints drop constraint if exists agent_hints_agent_key_check;
alter table public.agent_hints add constraint agent_hints_agent_key_check check (agent_key in (
  'analyze-project', 'extract-project-data', 'extract-success-case',
  'extract-business-card', 'extract-template-data', 'recommend-financing',
  'generate-proposal', 'promotion-agent', 'translate-project-text',
  'suggest-risks'
));
