-- ============================================================================
-- Migration v47: permiso de VISUALIZACIÓN de Roadmaps para el rol por defecto
-- ============================================================================
-- Contexto: migration_v46 sembró permisos de 'initiatives' y 'projects' para
-- el rol de registro automático (is_default_signup_role = true, "Usuario" en
-- la instalación original), pero no incluyó una fila para la entidad
-- 'roadmaps'. Sin una fila, has_entity_access()/entityPermission() devuelven
-- {can_view: false, can_edit: false} por defecto, lo que bloqueaba incluso la
-- visualización de Roadmaps a usuarios estándar.
--
-- Pedido del usuario: "Los usuarios que no son advisor ni admin, no pueden
-- editar roadmap, financing, solo visualizar." Financing (programs) ya tenía
-- una policy RLS previa que permite SELECT a todo usuario autenticado
-- (programs_select_all_authenticated), por lo que ese caso ya estaba
-- resuelto. Este migration cubre el caso de Roadmaps: agrega can_view=true,
-- can_edit=false para el rol marcado como is_default_signup_role.
--
-- Nota de diseño: se busca el rol por is_default_signup_role = true, NO por
-- name = 'Usuario', porque un admin pudo haber renombrado el rol desde
-- app/roles.html después de que corrió migration_v46 en producción.
--
-- Idempotente: no duplica si la fila ya existe para ese rol/entidad.
-- ============================================================================

insert into public.role_permissions (role_id, entity, can_view, can_edit, scope)
select r.id, 'roadmaps', true, false, 'all'
from public.roles r
where r.is_default_signup_role = true
  and not exists (
    select 1 from public.role_permissions rp
    where rp.role_id = r.id and rp.entity = 'roadmaps'
  );
