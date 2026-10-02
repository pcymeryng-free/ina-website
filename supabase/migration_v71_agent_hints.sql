-- ============================================================================
-- migration_v71_agent_hints.sql
--
-- QUÉ AGREGA
-- Reemplaza el mecanismo de api/<agente>.hints.js (archivos estáticos,
-- requeridos una sola vez al deployar) por una tabla — necesario para que
-- se puedan editar en vivo desde app/ai-hints.html sin un nuevo deploy:
-- Vercel no puede reescribir su propio código en producción, así que la
-- única forma de que la plataforma edite esto de verdad es que viva en la
-- base de datos. Cada agente (api/analyze-project.js, etc.) hace un GET a
-- esta tabla al recibir cada pedido y suma el texto a su prompt — ver
-- getAgentHint()/hintsSuffix() en cada archivo.
--
-- Sin filas precargadas — agent_key ausente simplemente significa "todavía
-- no hay hint cargado" (mismo comportamiento que el archivo vacío de
-- antes). app/ai-hints.html hace upsert solo cuando un admin guarda texto
-- para ese agente.
--
-- Admin-only en ambos sentidos (select y write) — a diferencia de la
-- mayoría de las tablas de la plataforma, esto es afinación interna del
-- comportamiento de los modelos de IA, no algo que un asesor necesite ver.
--
-- QUÉ NO CAMBIA
-- No toca ninguna otra tabla. Los 8 archivos api/<agente>.hints.js y sus
-- require() se eliminan en este mismo cambio — ver el commit de código
-- que acompaña a esta migración.
-- ============================================================================

create table public.agent_hints (
  agent_key text primary key check (agent_key in (
    'analyze-project', 'extract-project-data', 'extract-success-case',
    'extract-business-card', 'extract-template-data', 'recommend-financing',
    'generate-proposal', 'promotion-agent'
  )),
  hint_text text not null default '',
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

alter table public.agent_hints enable row level security;

create policy "agent_hints_select_admin" on public.agent_hints
  for select using (public.is_admin());

create policy "agent_hints_upsert_admin" on public.agent_hints
  for insert with check (public.is_admin());

create policy "agent_hints_update_admin" on public.agent_hints
  for update using (public.is_admin())
  with check (public.is_admin());
