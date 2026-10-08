-- ============================================================================
-- migration_v74_debug_mode.sql
--
-- QUÉ AGREGA
-- Pablo: "agregar un modo debug que solo lo puede setear el admin y que
-- cuando está seteado guarda en un log información de detalle como los
-- sql que se aplican a la base de datos, los prompts que se envían a los
-- agentes de IA, cuál es la versión de dichos agentes, el tiempo de
-- ejecución, los tokens que se usaron para generar la respuesta y
-- cualquier información que provea el modelo de lenguaje de IA."
--
-- app_settings: fila única (truco clásico de boolean PK forzado a true —
-- siempre existe exactamente una fila) para el flag global. Legible por
-- cualquiera (cada función de Vercel y cada sesión de browser necesita
-- poder chequearlo barato), solo el admin puede escribirlo.
--
-- debug_log: dos tipos de fila. 'db_write' — cada escritura (insert/
-- update/delete/upsert) hecha por el cliente vía supabase-js, capturada
-- envolviendo el fetch interno del cliente (ver assets/platform.js,
-- createClient()'s global.fetch) — no hay SQL textual en ningún lugar del
-- cliente (todo es PostgREST), así que lo que se guarda es la operación
-- real aplicada: tabla, tipo de operación, payload enviado y respuesta.
-- 'ai_agent' — cada llamada a un modelo de IA desde cualquiera de los
-- api/*.js (ver el header de cada uno): prompt completo, versión del
-- agente, proveedor/modelo, duración, tokens y la respuesta cruda.
--
-- Pesado a propósito (guarda prompts/respuestas completos) — por eso la
-- retención es mucho más corta que activity_log (7 días, borrado directo,
-- no archivo) en vez de los 30 días con archivo que usa esa tabla: esto es
-- una herramienta de diagnóstico temporal, no un registro de negocio.
-- ============================================================================

create table if not exists public.app_settings (
  id boolean primary key default true unique check (id),
  debug_mode boolean not null default false,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);
insert into public.app_settings (id) values (true) on conflict do nothing;

alter table public.app_settings enable row level security;

drop policy if exists "app_settings_select_all" on public.app_settings;
create policy "app_settings_select_all" on public.app_settings
  for select using (true);

drop policy if exists "app_settings_update_admin" on public.app_settings;
create policy "app_settings_update_admin" on public.app_settings
  for update using (public.is_admin()) with check (public.is_admin());

create table if not exists public.debug_log (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  log_type text not null check (log_type in ('db_write', 'ai_agent')),
  user_id uuid references public.profiles(id) on delete set null,
  -- 'db_write' fields
  table_name text,
  operation text check (operation is null or operation in ('insert', 'update', 'delete', 'upsert')),
  -- 'ai_agent' fields
  agent_key text,
  agent_version text,
  provider text,
  model text,
  duration_ms integer,
  prompt_tokens integer,
  completion_tokens integer,
  total_tokens integer,
  -- full detail blob: payload/response for db_write, system+user prompt
  -- and raw model response for ai_agent
  details jsonb,
  created_at timestamptz not null default now()
);

comment on table public.debug_log is 'Log de diagnóstico detallado (escrituras a la base + llamadas a agentes de IA), activo solo mientras app_settings.debug_mode está en true. Solo Admin puede leerlo. Retención: 7 días (ver purge_old_debug_log()).';

alter table public.debug_log enable row level security;

drop policy if exists "debug_log_insert_own" on public.debug_log;
create policy "debug_log_insert_own" on public.debug_log
  for insert with check (auth.uid() = user_id);

drop policy if exists "debug_log_select_admin" on public.debug_log;
create policy "debug_log_select_admin" on public.debug_log
  for select using (public.is_admin());

create index if not exists debug_log_occurred_at_idx on public.debug_log(occurred_at desc);
create index if not exists debug_log_log_type_idx on public.debug_log(log_type);
create index if not exists debug_log_user_id_idx on public.debug_log(user_id);

-- ---------- retention (7 days, straight delete) ----------
create extension if not exists pg_cron;

create or replace function public.purge_old_debug_log()
returns integer
language plpgsql
security definer set search_path = public
as $$
declare
  deleted_count integer;
begin
  delete from public.debug_log where occurred_at < now() - interval '7 days';
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

select cron.unschedule('purge-old-debug-log')
where exists (select 1 from cron.job where jobname = 'purge-old-debug-log');

select cron.schedule(
  'purge-old-debug-log',
  '0 4 * * *',
  $$select public.purge_old_debug_log();$$
);
