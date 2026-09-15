-- ============================================================================
-- migration_v62_roles_self_select.sql
--
-- QUÉ PASÓ (reporte de Pablo)
-- Pablo creó un usuario (skaplan.inaai.co), le asignó el rol configurable
-- "Master Data Management" (con "Ver"+"Editar" tildado en la entidad
-- 'master_data', vía app/roles.html) y confirmó que profiles.role sigue
-- siendo 'user' con profiles.custom_role_id apuntando a ese rol. Aun así,
-- al conectarse con esa cuenta:
--   - No aparece el menú Admin / la opción de Master Data en absoluto.
--   - canManageMasterData(profile) del lado del cliente (assets/platform.js)
--     da false, como si el usuario no tuviera ningún permiso asignado.
--
-- CAUSA RAÍZ
-- migration_v46_role_permissions.sql agregó la política RLS
-- "roles_select_user_management" sobre public.roles:
--
--   create policy "roles_select_user_management" on public.roles
--     for select using (public.has_entity_access(auth.uid(), 'user_management', 'view', null));
--
-- Es decir: SOLO puede hacer SELECT sobre la tabla roles quien YA tenga
-- permiso de ver la entidad 'user_management' (hoy: sólo Admin, o un rol
-- configurable al que se le haya dado ese permiso explícitamente). Un
-- usuario 'user' con un custom_role_id asignado que NO incluya
-- 'user_management' (como "Master Data Management", que sólo tiene
-- 'master_data') no puede leer ni siquiera SU PROPIA fila en roles.
--
-- Esto rompe el embed anidado que hace getProfile() en platform.js:
--   .select('*, custom_role:roles(id, name, role_permissions(entity, can_view, can_edit, scope))')
-- PostgREST filtra los recursos embebidos por RLS igual que cualquier
-- SELECT — no es un error, simplemente el embed resuelve custom_role: null
-- para ese usuario (como si no tuviera rol asignado), y entityPermission()
-- en platform.js entonces devuelve { can_view:false, can_edit:false } para
-- TODAS las entidades, sea cual sea el permiso real cargado en
-- role_permissions. Por eso ni Master Data ni ninguna otra entidad
-- gateada por rol configurable aparecía para este usuario.
--
-- El mismo problema existe en role_permissions: aunque roles se pudiera
-- leer, la fila de role_permissions para ese role_id tampoco es visible
-- sin permiso de 'user_management'.
--
-- FIX
-- Agrega DOS políticas SELECT adicionales (permisivas — en Postgres RLS,
-- múltiples políticas para el mismo comando se combinan con OR, así que
-- esto es un SUPERSET de lo que ya podía verse, nunca resta acceso):
--   1) roles_select_own_assigned_role: cualquier usuario autenticado puede
--      leer la fila de roles que coincide con SU PROPIO profiles.custom_role_id
--      (y sólo esa fila — no puede listar ni ver otros roles configurados).
--   2) role_permissions_select_own_assigned_role: idem, para las filas de
--      role_permissions cuyo role_id sea el rol propio asignado.
-- Con esto, cualquier usuario con un rol configurable asignado puede
-- calcular sus propios permisos del lado del cliente (el propósito
-- original del embed en getProfile()), sin necesitar acceso a
-- 'user_management'. La gestión (crear/renombrar/editar permisos de un
-- rol, ver TODOS los roles en app/roles.html) sigue exigiendo
-- 'user_management' exactamente como antes — esto no cambia.
--
-- CÓMO USAR
-- Ejecutar una sola vez en el SQL Editor de Supabase. Reversible/aditivo:
-- sólo agrega políticas, no toca ni reemplaza las que ya existían.
-- ============================================================================

drop policy if exists "roles_select_own_assigned_role" on public.roles;
create policy "roles_select_own_assigned_role" on public.roles
  for select using (
    id = (select custom_role_id from public.profiles where id = auth.uid())
  );

drop policy if exists "role_permissions_select_own_assigned_role" on public.role_permissions;
create policy "role_permissions_select_own_assigned_role" on public.role_permissions
  for select using (
    role_id = (select custom_role_id from public.profiles where id = auth.uid())
  );

-- ============================================================================
-- Verificación (ejecutar conectado como el usuario afectado no es posible
-- desde el SQL Editor con la service role, pero esto confirma que la fila
-- de rol y sus permisos existen y están bien cargados — si esto no
-- devuelve la fila esperada con master_data / can_view / can_edit en true,
-- el problema es de datos, no de RLS):
-- ============================================================================
select r.id, r.name, rp.entity, rp.can_view, rp.can_edit, rp.scope
from public.roles r
join public.role_permissions rp on rp.role_id = r.id
where r.name = 'Master Data Management'
order by rp.entity;
