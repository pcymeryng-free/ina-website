-- ============================================================================
-- migration_v64_activity_log_retention.sql
--
-- QUÉ AGREGA
-- Una política de retención de 30 días para public.activity_log (ver
-- migration_v63_activity_log.sql): pasados los 30 días, cada fila se
-- mueve — no se borra sin más — a public.activity_log_archive, una tabla
-- espejo (mismas columnas) que sirve como backup. Pablo: "dejar los datos
-- del log durante 30 días. Luego hacer backup de los items que superan
-- los 30 días de antigüedad."
--
-- Por qué archivar en vez de solo borrar: activity_log acumula una fila
-- de tipo 'page_view' en CADA carga de página del sitio público (visitas
-- anónimas incluidas, vía log-visit.php) y de la plataforma logueada —
-- crece rápido y sin acotar. Mantener solo los últimos 30 días en la
-- tabla "caliente" que usa app/activity-log.html (índices más chicos,
-- consultas más rápidas) sin perder el historial completo, que queda
-- disponible en activity_log_archive para quien lo necesite consultar
-- directo por SQL más adelante.
--
-- CÓMO CORRE
-- pg_cron (extensión de Postgres ya disponible en Supabase) ejecuta
-- public.archive_old_activity_log() todos los días a las 03:00 UTC (medianoche
-- en Argentina). La función mueve en una sola transacción (DELETE ...
-- RETURNING * → INSERT) todo lo de activity_log con occurred_at de más
-- de 30 días, así no hay ventana donde una fila pueda perderse sin
-- llegar a archive ni quedar duplicada en ambas tablas.
--
-- CÓMO USAR
-- Corré este archivo completo en el SQL Editor de Supabase. Si el paso
-- de `create extension pg_cron` fallara por permisos, activalo primero
-- a mano desde el Dashboard → Database → Extensions (buscar "pg_cron",
-- togglear ON) y después corré el resto de este archivo.
-- ============================================================================

create extension if not exists pg_cron;

-- Misma estructura que activity_log (ver migration_v63) — sin las
-- políticas de INSERT que tiene esa (nada escribe acá directo salvo la
-- función de abajo, que corre con privilegios elevados vía SECURITY
-- DEFINER).
create table if not exists public.activity_log_archive (
  id uuid primary key,
  occurred_at timestamptz not null,
  user_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  entity_type text,
  entity_id uuid,
  entity_label text,
  path text,
  ip_address text,
  country text,
  user_agent text,
  details jsonb,
  created_at timestamptz not null,
  archived_at timestamptz not null default now()
);

comment on table public.activity_log_archive is 'Backup de filas de activity_log con más de 30 días de antigüedad — ver public.archive_old_activity_log() y el cron job "archive-old-activity-log".';

alter table public.activity_log_archive enable row level security;

-- Mismo criterio que activity_log: solo Admin puede leer.
create policy "activity_log_archive_select_admin" on public.activity_log_archive
  for select using (public.is_admin());

create index if not exists activity_log_archive_occurred_at_idx on public.activity_log_archive(occurred_at desc);
create index if not exists activity_log_archive_user_id_idx on public.activity_log_archive(user_id);

-- Mueve (no copia) todo lo de activity_log con más de 30 días de
-- antigüedad a activity_log_archive, en una sola transacción. Devuelve
-- la cantidad de filas movidas, solo para que el log del cron job
-- (visible en Supabase → Database → Cron Jobs → Run history) sea legible.
create or replace function public.archive_old_activity_log()
returns integer
language plpgsql
security definer set search_path = public
as $$
declare
  moved_count integer;
begin
  with moved as (
    delete from public.activity_log
    where occurred_at < now() - interval '30 days'
    returning *
  )
  insert into public.activity_log_archive (
    id, occurred_at, user_id, event_type, entity_type, entity_id,
    entity_label, path, ip_address, country, user_agent, details, created_at
  )
  select
    id, occurred_at, user_id, event_type, entity_type, entity_id,
    entity_label, path, ip_address, country, user_agent, details, created_at
  from moved;

  get diagnostics moved_count = row_count;
  return moved_count;
end;
$$;

-- Reemplaza el job si ya existe (para poder re-correr este archivo sin
-- duplicar la programación).
select cron.unschedule('archive-old-activity-log')
where exists (select 1 from cron.job where jobname = 'archive-old-activity-log');

select cron.schedule(
  'archive-old-activity-log',
  '0 3 * * *', -- todos los días 03:00 UTC = medianoche en Argentina (UTC-3)
  $$select public.archive_old_activity_log();$$
);
