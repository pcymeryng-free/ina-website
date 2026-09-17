-- ============================================================================
-- migration_v63_activity_log.sql
--
-- QUÉ AGREGA
-- Un log de actividad de la plataforma, pedido por Pablo para poder ver:
--   1. Quién se conectó al sitio público (institucional) y qué páginas
--      visitó — solo se puede capturar IP, país (vía el header de
--      Cloudflare, que ya está delante del sitio) y user-agent; un
--      visitante anónimo no tiene "identidad" real hasta que se loguea.
--   2. Si un usuario se logueó en la plataforma (app/), a qué páginas
--      accedió, y qué altas/bajas/cambios (create/update/delete) hizo
--      sobre las entidades principales (proyectos, master data,
--      programas, roadmaps, riesgos, etc.).
--
-- CÓMO SE ALIMENTA (ver también las dos piezas de código nuevas)
--   - Sitio público (anónimo): assets/script.js manda un fetch a
--     log-visit.php en cada carga de página; ese script PHP corre en
--     Bluehost (no hay Node ahí, mismo motivo que contact.php), lee la IP
--     real y el país desde los headers que agrega Cloudflare
--     (CF-Connecting-IP / CF-IPCountry) y escribe en esta tabla vía la
--     REST API de Supabase usando la Anon Key (la misma que ya está
--     hardcodeada en assets/platform.js — es pública por diseño, la
--     seguridad la da RLS, no el secreto). NO usa la Service Role Key a
--     propósito, para no tener que guardar ningún secreto server-side en
--     Bluehost: la política "activity_log_insert_anon_pageview" de abajo
--     solo permite insertar filas anónimas de tipo 'page_view', nada más
--     (no puede insertar un 'create'/'delete' ni atribuirse un user_id).
--   - Plataforma (logueado): assets/platform.js escribe directo con el
--     cliente de Supabase ya autenticado (INAPlatform.logActivity()),
--     tanto para vistas de página (llamado una vez desde requireAuth(),
--     que ya corre al principio de cada página autenticada) como para
--     cada create/update/delete de las entidades principales. Ahí hace
--     falta la política "activity_log_insert_own" de abajo (auth.uid() =
--     user_id). El IP/país de estas filas se obtiene de whoami.php (sin
--     secretos, solo devuelve esos dos datos) para no duplicar la lógica
--     de lectura de los headers de Cloudflare.
--
-- QUIÉN LO VE
-- Solo Admin (app/activity-log.html, gateado con requireAdmin() del lado
-- cliente y con la política de SELECT de abajo del lado del servidor —
-- la que realmente importa).
-- ============================================================================

create table if not exists public.activity_log (
  id uuid primary key default gen_random_uuid(),
  occurred_at timestamptz not null default now(),
  -- Null = visitante anónimo del sitio público (no logueado).
  user_id uuid references public.profiles(id) on delete set null,
  event_type text not null check (event_type in (
    'page_view', 'login', 'logout', 'create', 'update', 'delete'
  )),
  -- Nombre de tabla/entidad afectada (p. ej. 'project', 'contact',
  -- 'company'), sin CHECK constraint a propósito — la lista de entidades
  -- crece con la plataforma y no vale la pena migrar el constraint cada
  -- vez. Null para event_type in ('page_view','login','logout').
  entity_type text,
  entity_id uuid,
  -- Copia del nombre/título de la entidad al momento del evento, para que
  -- el log siga siendo legible aunque la entidad se borre después (por
  -- eso no hay FK a la fila real — apuntaría a nada tras un delete).
  entity_label text,
  -- Ruta de la página vista (page_view) o de la página desde la que se
  -- disparó la acción (create/update/delete), p. ej. '/app/dashboard.html'
  -- o '/knowledge.html'.
  path text,
  ip_address text,
  country text,
  user_agent text,
  -- Detalle libre opcional (p. ej. campos que cambiaron en un update).
  details jsonb,
  created_at timestamptz not null default now()
);

comment on table public.activity_log is 'Log de conexiones/páginas vistas (sitio público y plataforma) y de altas/bajas/cambios dentro de la plataforma. Solo Admin puede leerlo.';

alter table public.activity_log enable row level security;

-- Cualquier usuario autenticado puede insertar SUS PROPIAS filas (no las
-- de otro) — usado por INAPlatform.logActivity()/logPageView().
create policy "activity_log_insert_own" on public.activity_log
  for insert with check (auth.uid() = user_id);

-- Visitantes anónimos del sitio público (rol 'anon' de PostgREST) solo
-- pueden insertar filas de vista de página sin user_id — usado por
-- log-visit.php. No pueden insertar 'create'/'update'/'delete' ni
-- atribuirse un user_id ajeno.
create policy "activity_log_insert_anon_pageview" on public.activity_log
  for insert to anon
  with check (user_id is null and event_type = 'page_view');

-- Solo Admin puede leer el log — ni siquiera Advisor, a propósito: esto
-- es una herramienta de supervisión/seguridad, no un feed de actividad
-- para el equipo.
create policy "activity_log_select_admin" on public.activity_log
  for select using (public.is_admin());

create index if not exists activity_log_occurred_at_idx on public.activity_log(occurred_at desc);
create index if not exists activity_log_user_id_idx on public.activity_log(user_id);
create index if not exists activity_log_event_type_idx on public.activity_log(event_type);
create index if not exists activity_log_entity_type_idx on public.activity_log(entity_type);
