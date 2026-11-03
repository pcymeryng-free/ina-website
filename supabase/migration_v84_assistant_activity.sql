-- ============================================================================
-- migration_v84_assistant_activity.sql
-- Run this ONCE in Supabase: Dashboard → SQL Editor → New query → paste →
-- Run. Safe to re-run.
--
-- QUÉ AGREGA
-- Pablo (nov 2026): asistente tipo bot en la plataforma que responde en
-- lenguaje natural sobre funcionalidades y datos (api/_assistant.js, botón
-- "Asistente" en todas las páginas de app/).
--
-- Cada consulta al asistente se registra en activity_log con el nuevo
-- event_type 'assistant_query' (entity_label = la pregunta, details.tools =
-- las consultas que hizo). Esta migración solo amplía el CHECK de
-- event_type para permitirlo.
--
-- También suma 'assistant' a las claves válidas de agent_hints, para que un
-- admin pueda ajustar las instrucciones del asistente desde Hints de IA
-- (app/ai-hints.html), igual que con los demás agentes.
--
-- Si no se corre, el asistente funciona igual: el insert del log falla el
-- CHECK y se descarta en silencio (nunca bloquea la respuesta), y el hint
-- del asistente no se puede guardar.
--
-- QUÉ NO CAMBIA
-- Ninguna policy: la fila la inserta el propio usuario con su sesión, vía
-- la policy existente "activity_log_insert_own" (auth.uid() = user_id), y
-- solo Admin la puede leer, igual que el resto del log.
-- ============================================================================

do $$
declare
  c text;
begin
  -- The original CHECK was declared inline (migration_v63), so its name is
  -- Postgres' default; look it up instead of assuming it.
  for c in
    select con.conname
    from pg_constraint con
    join pg_attribute att on att.attrelid = con.conrelid and att.attnum = any (con.conkey)
    where con.conrelid = 'public.activity_log'::regclass
      and con.contype = 'c'
      and att.attname = 'event_type'
  loop
    execute format('alter table public.activity_log drop constraint %I', c);
  end loop;
end $$;

alter table public.activity_log
  add constraint activity_log_event_type_check check (event_type in (
    'page_view', 'login', 'logout', 'create', 'update', 'delete', 'assistant_query'
  ));

alter table public.agent_hints drop constraint if exists agent_hints_agent_key_check;
alter table public.agent_hints add constraint agent_hints_agent_key_check check (agent_key in (
  'analyze-project', 'extract-project-data', 'extract-success-case',
  'extract-business-card', 'extract-template-data', 'recommend-financing',
  'generate-proposal', 'promotion-agent', 'translate-project-text',
  'suggest-risks', 'assistant'
));
