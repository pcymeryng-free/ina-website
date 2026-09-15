-- ============================================================================
-- migration_v46_role_permissions.sql
--
-- QUÉ ES
-- Agrega un sistema de roles configurables (más allá de Admin/Advisor/Usuario)
-- con permisos de VER y EDITAR por entidad de la plataforma, y un alcance
-- ("scope") todo / solo lo propio, configurable por rol y por entidad.
--
-- DISEÑO (confirmado con Pablo antes de escribir este archivo):
-- 1) Admin y Advisor NO cambian: siguen siendo "roles de sistema" hardcodeados
--    en profiles.role ('admin' | 'advisor' | 'user'). Admin puede editar
--    cualquier entidad. Advisor puede editar cualquier entidad EXCEPTO
--    "Gestión de Usuarios y Roles".
-- 2) Se agrega profiles.custom_role_id: sólo se consulta cuando
--    profiles.role = 'user'. Permite asignar, a un usuario "user", un rol
--    configurable (tabla roles) con permisos por entidad (tabla
--    role_permissions).
-- 3) El scope "own" (solo lo propio) es un flag general disponible para
--    cualquier combinación (rol, entidad), no sólo para Usuario+Proyectos.
-- 4) Entidades = los módulos actuales, como una sola lista (no se separa
--    Master Data en Contactos/Empresas/Organismos/Productos):
--      'initiatives'      -> Iniciativas       (programs, program_role='umbrella')
--      'financing'        -> Financiación       (programs, program_role<>'umbrella')
--      'projects'         -> Proyectos          (projects)
--      'roadmaps'         -> Roadmaps           (roadmap_templates + instancias)
--      'master_data'      -> Master Data        (companies/public_agencies/contacts/products)
--      'risks'            -> Matriz de Riesgos  (project_risks)
--      'user_management'  -> Gestión de Usuarios y Roles (profiles/roles/role_permissions)
-- 5) Rol por defecto al registrarse: "Usuario" (is_default_signup_role=true),
--    con permisos que replican el comportamiento ACTUAL de un usuario común:
--      initiatives: ver=sí, editar=no, scope=all
--      projects:    ver=sí, editar=sí, scope=own (sólo sus propios proyectos)
--    (el resto de las entidades queda sin fila = sin acceso, igual que hoy)
--
-- REGLA DE DISEÑO PARA MINIMIZAR RIESGO DE REGRESIÓN (plataforma en producción,
-- uso de ENACOM):
--   El nuevo sistema de permisos gobierna VER (select) y EDITAR (insert +
--   update). El BORRADO (delete) de cualquier entidad NO se toca: sigue
--   exactamente como está hoy en cada tabla (dueño y/o admin, según cada
--   caso ya existente). Así, aunque se cree un rol configurable con
--   editar=sí en una entidad, ese rol nunca gana la capacidad de borrar que
--   antes no tenía — sólo ver/crear/editar.
--   Tampoco se toca el flujo de "tomar un proyecto" (assigned_advisor_id):
--   un advisor sigue sin poder editar un proyecto de otro advisor que no
--   tomó, ese comportamiento es independiente de este sistema de roles.
--
-- REVERSIBLE: agrega tablas y columnas nuevas, y reemplaza políticas RLS
-- (drop + create) por versiones que son un SUPERSET de las anteriores
-- (agregan casos, no quitan los que ya existían), excepto donde se indica
-- explícitamente lo contrario (ver "Financiación", más abajo).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) Tabla roles (roles configurables, además de Admin/Advisor/Usuario)
-- ----------------------------------------------------------------------------
create table if not exists public.roles (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  description text,
  is_default_signup_role boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.roles is 'Roles configurables asignables a usuarios con profiles.role = ''user''. Admin y Advisor son roles de sistema y NO viven en esta tabla.';

-- Sólo puede haber un rol marcado como "rol por defecto al registrarse".
create unique index if not exists roles_single_default_signup
  on public.roles (is_default_signup_role)
  where is_default_signup_role;

alter table public.roles enable row level security;

-- ----------------------------------------------------------------------------
-- 2) Tabla role_permissions (permisos por rol y por entidad)
-- ----------------------------------------------------------------------------
create table if not exists public.role_permissions (
  id uuid primary key default gen_random_uuid(),
  role_id uuid not null references public.roles(id) on delete cascade,
  entity text not null check (entity in (
    'initiatives', 'projects', 'financing', 'roadmaps',
    'master_data', 'risks', 'user_management'
  )),
  can_view boolean not null default false,
  can_edit boolean not null default false,
  scope text not null default 'all' check (scope in ('all', 'own')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (role_id, entity)
);

comment on table public.role_permissions is 'Permisos de ver/editar por (rol, entidad). scope=''own'' limita a filas creadas por el propio usuario, cuando la entidad tiene noción de dueño.';

alter table public.role_permissions enable row level security;

-- ----------------------------------------------------------------------------
-- 3) profiles.custom_role_id
-- ----------------------------------------------------------------------------
alter table public.profiles
  add column if not exists custom_role_id uuid references public.roles(id) on delete set null;

comment on column public.profiles.custom_role_id is 'Sólo se consulta cuando profiles.role = ''user''. Rol configurable (tabla roles) asignado a este usuario. NULL = sin permisos adicionales (comportamiento actual: sin acceso a nada salvo lo suyo).';

-- ----------------------------------------------------------------------------
-- 4) Función central: public.has_entity_access(uid, entity, mode, owner_id)
--
--    mode: 'view' o 'edit'.
--    owner_id: dueño de la fila en cuestión (o NULL si la entidad no tiene
--              noción de dueño individual, p.ej. Master Data o Roadmaps).
--
--    admin        -> siempre true.
--    advisor      -> true para toda entidad EXCEPTO 'user_management'.
--    user (o sin  -> busca profiles.custom_role_id -> role_permissions para
--    profile)        esa entidad+modo; si scope='own', además exige
--                    owner_id = uid.
-- ----------------------------------------------------------------------------
create or replace function public.has_entity_access(
  p_uid uuid,
  p_entity text,
  p_mode text,
  p_owner_id uuid default null
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select case
    when p_uid is null then false
    when exists (select 1 from public.profiles where id = p_uid and role = 'admin') then true
    when exists (select 1 from public.profiles where id = p_uid and role = 'advisor') then (p_entity <> 'user_management')
    else coalesce((
      select case
        when p_mode = 'view' and not rp.can_view then false
        when p_mode = 'edit' and not rp.can_edit then false
        when rp.scope = 'own' then (p_owner_id is not null and p_owner_id = p_uid)
        else true
      end
      from public.profiles p
      join public.role_permissions rp
        on rp.role_id = p.custom_role_id and rp.entity = p_entity
      where p.id = p_uid
    ), false)
  end;
$$;

comment on function public.has_entity_access(uuid, text, text, uuid) is 'Chequeo central de permisos del sistema de roles configurables. Ver comentario al inicio de migration_v46_role_permissions.sql.';

-- Wrappers de conveniencia para entidades sin noción de dueño individual
-- (Master Data, Roadmaps, Riesgos a nivel función, Gestión de Usuarios).
create or replace function public.can_view_entity(p_uid uuid, p_entity text)
returns boolean language sql security definer set search_path = public stable as $$
  select public.has_entity_access(p_uid, p_entity, 'view', null);
$$;

create or replace function public.can_edit_entity(p_uid uuid, p_entity text)
returns boolean language sql security definer set search_path = public stable as $$
  select public.has_entity_access(p_uid, p_entity, 'edit', null);
$$;

-- ----------------------------------------------------------------------------
-- 5) RLS: roles y role_permissions (sólo quien tenga editar/ver en
--    'user_management' — hoy sólo Admin, salvo que se cree un rol
--    configurable con ese permiso).
-- ----------------------------------------------------------------------------
drop policy if exists "roles_select_user_management" on public.roles;
create policy "roles_select_user_management" on public.roles
  for select using (public.has_entity_access(auth.uid(), 'user_management', 'view', null));

drop policy if exists "roles_insert_user_management" on public.roles;
create policy "roles_insert_user_management" on public.roles
  for insert with check (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

drop policy if exists "roles_update_user_management" on public.roles;
create policy "roles_update_user_management" on public.roles
  for update using (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

drop policy if exists "roles_delete_user_management" on public.roles;
create policy "roles_delete_user_management" on public.roles
  for delete using (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

drop policy if exists "role_permissions_select_user_management" on public.role_permissions;
create policy "role_permissions_select_user_management" on public.role_permissions
  for select using (public.has_entity_access(auth.uid(), 'user_management', 'view', null));

drop policy if exists "role_permissions_insert_user_management" on public.role_permissions;
create policy "role_permissions_insert_user_management" on public.role_permissions
  for insert with check (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

drop policy if exists "role_permissions_update_user_management" on public.role_permissions;
create policy "role_permissions_update_user_management" on public.role_permissions
  for update using (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

drop policy if exists "role_permissions_delete_user_management" on public.role_permissions;
create policy "role_permissions_delete_user_management" on public.role_permissions
  for delete using (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

-- ----------------------------------------------------------------------------
-- 6) profiles: agregar visibilidad/edición vía 'user_management' además de
--    lo que ya existía (auth.uid()=id, is_advisor(), is_admin()).
-- ----------------------------------------------------------------------------
drop policy if exists "profiles_select_own_or_privileged" on public.profiles;
create policy "profiles_select_own_or_privileged" on public.profiles
  for select using (
    auth.uid() = id
    or public.is_advisor()
    or public.is_admin()
    or public.has_entity_access(auth.uid(), 'user_management', 'view', null)
  );

drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin" on public.profiles
  for update using (
    public.is_admin()
    or public.has_entity_access(auth.uid(), 'user_management', 'edit', null)
  );

-- profiles_update_own y profiles_insert_own quedan exactamente como están
-- (autoservicio de cada usuario sobre su propia fila, no es parte de este
-- sistema de permisos por entidad).

-- ----------------------------------------------------------------------------
-- 7) Guarda de auto-cambio: extender para bloquear también que un usuario
--    se auto-asigne un custom_role_id (evita escalar privilegios editando
--    su propio perfil), igual que ya bloquea el auto-cambio de role.
-- ----------------------------------------------------------------------------
create or replace function public.prevent_role_self_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() = old.id and new.role is distinct from old.role then
    raise exception 'You cannot change your own platform role.';
  end if;
  if auth.uid() = old.id and new.custom_role_id is distinct from old.custom_role_id then
    raise exception 'You cannot change your own custom role.';
  end if;
  return new;
end;
$$;
-- El trigger prevent_role_self_change_trigger ya existe y usa esta función
-- (create or replace la actualiza sin necesidad de recrear el trigger).

-- ----------------------------------------------------------------------------
-- 8) handle_new_user(): asignar el rol configurable por defecto
--    (is_default_signup_role = true) al crear el perfil, si existe alguno.
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, organization, role_type, role, email, custom_role_id)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'organization', ''),
    coalesce(new.raw_user_meta_data->>'role_type', 'other'),
    'user',
    new.email,
    (select id from public.roles where is_default_signup_role limit 1)
  );
  return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 9) Semilla: rol "Usuario" por defecto, con los permisos que replican el
--    comportamiento actual de un usuario común (ver comentario del punto 5
--    al inicio del archivo). Idempotente: no duplica si ya existe.
-- ----------------------------------------------------------------------------
insert into public.roles (name, description, is_default_signup_role)
select 'Usuario', 'Rol asignado automáticamente al registrarse. Puede ver Iniciativas y ver/editar únicamente los Proyectos que él mismo creó.', true
where not exists (select 1 from public.roles where name = 'Usuario');

insert into public.role_permissions (role_id, entity, can_view, can_edit, scope)
select r.id, v.entity, v.can_view, v.can_edit, v.scope
from public.roles r
cross join (values
  ('initiatives', true, false, 'all'),
  ('projects',    true, true,  'own')
) as v(entity, can_view, can_edit, scope)
where r.name = 'Usuario'
  and not exists (
    select 1 from public.role_permissions rp
    where rp.role_id = r.id and rp.entity = v.entity
  );

-- ----------------------------------------------------------------------------
-- 10) projects: agregar el sistema de permisos como refuerzo ADICIONAL a lo
--     que ya existía (nunca se quita capacidad existente). El flujo de
--     "tomar un proyecto" (assigned_advisor_id) y el borrado (owner o admin)
--     quedan intactos.
-- ----------------------------------------------------------------------------
drop policy if exists "projects_select_own_or_advisor" on public.projects;
create policy "projects_select_own_or_advisor" on public.projects
  for select using (
    auth.uid() = user_id
    or auth.uid() = assigned_advisor_id
    or public.is_advisor()
    or public.is_admin()
    or public.has_entity_access(auth.uid(), 'projects', 'view', user_id)
  );

-- Insert: se mantiene auth.uid() = user_id (autoservicio, cualquier usuario
-- autenticado puede crear su propio proyecto, como hoy). No se gatea por
-- permiso de entidad para no arriesgar bloquear a Usuario si faltara la fila
-- de permisos por algún motivo.
-- (projects_insert_own queda sin cambios.)

drop policy if exists "projects_update_own_or_assigned_advisor" on public.projects;
create policy "projects_update_own_or_assigned_advisor" on public.projects
  for update using (
    auth.uid() = user_id
    or auth.uid() = assigned_advisor_id
    or public.has_entity_access(auth.uid(), 'projects', 'edit', user_id)
  );

-- projects_delete_own_or_admin queda sin cambios (owner o admin, tal cual).

-- ----------------------------------------------------------------------------
-- 11) programs (Iniciativas = program_role 'umbrella', Financiación = resto):
--     ampliar creación/edición a Admin/Advisor/roles configurables con
--     permiso de editar sobre la entidad correspondiente. Esto es lo que
--     resuelve el pedido original de Pablo ("modifica los permisos para que
--     sólo el advisor y el admin puedan gestionar los datos de
--     Financiación..."): hoy un advisor sólo puede editar un programa que
--     él mismo creó; con este cambio, cualquier advisor/admin puede
--     gestionar cualquier Iniciativa/Financiación, no sólo la propia.
--     La VISIBILIDAD (select) no se toca: sigue abierta a todo usuario
--     autenticado, igual que hoy (nunca se pidió restringir ver, sólo
--     gestionar/editar). El borrado sigue owner-o-admin, sin cambios.
-- ----------------------------------------------------------------------------
-- programs_select_all_authenticated queda sin cambios.

drop policy if exists "programs_insert_advisor_or_admin" on public.programs;
create policy "programs_insert_advisor_or_admin" on public.programs
  for insert with check (
    auth.uid() = user_id
    and (
      public.is_advisor()
      or public.is_admin()
      or public.has_entity_access(
           auth.uid(),
           case when program_role = 'umbrella' then 'initiatives' else 'financing' end,
           'edit', user_id
         )
    )
  );

drop policy if exists "programs_update_own" on public.programs;
create policy "programs_update_own" on public.programs
  for update using (
    auth.uid() = user_id
    or public.is_advisor()
    or public.is_admin()
    or public.has_entity_access(
         auth.uid(),
         case when program_role = 'umbrella' then 'initiatives' else 'financing' end,
         'edit', user_id
       )
  );

-- programs_delete_own_or_admin queda sin cambios.

-- ----------------------------------------------------------------------------
-- 12) project_risks (Matriz de Riesgos): el dueño del proyecto sigue viendo
--     (sólo lectura) los riesgos de su propio proyecto, sin cambios; se
--     amplía quién puede ver/crear/editar más allá de advisor/admin hacia
--     roles configurables con permiso en 'risks'. Borrado sin cambios
--     (advisor o admin, tal cual).
-- ----------------------------------------------------------------------------
drop policy if exists "project_risks_select_own_or_advisor" on public.project_risks;
create policy "project_risks_select_own_or_advisor" on public.project_risks
  for select using (
    public.is_advisor()
    or public.is_admin()
    or public.has_entity_access(auth.uid(), 'risks', 'view', null)
    or exists (
      select 1 from public.projects pr
      where pr.id = project_risks.project_id and pr.user_id = auth.uid()
    )
  );

drop policy if exists "project_risks_insert_advisor_or_admin" on public.project_risks;
create policy "project_risks_insert_advisor_or_admin" on public.project_risks
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'risks', 'edit', null)
  );

drop policy if exists "project_risks_update_advisor_or_admin" on public.project_risks;
create policy "project_risks_update_advisor_or_admin" on public.project_risks
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'risks', 'edit', null)
  );

-- project_risks_delete_advisor_or_admin queda sin cambios.

-- ----------------------------------------------------------------------------
-- 13) Roadmaps: roadmap_templates / roadmap_template_steps / roadmap_step_raci
--     (biblioteca de plantillas, sin dueño individual) y
--     project_roadmaps (legacy) / roadmap_instances / roadmap_instance_steps /
--     roadmap_instance_step_raci (instancias, con lectura del dueño del
--     proyecto ya existente, sin cambios). Borrado sin cambios en todas.
-- ----------------------------------------------------------------------------
-- 13a) Plantillas: hoy 100% advisor/admin, sin visibilidad para 'user'. Se
--      amplía a roles configurables con permiso en 'roadmaps'. Por defecto
--      el rol "Usuario" NO tiene fila en 'roadmaps', así que no hay cambio
--      de comportamiento salvo que un admin cree un rol que sí lo tenga.
drop policy if exists "roadmap_templates_select_advisor_or_admin" on public.roadmap_templates;
create policy "roadmap_templates_select_advisor_or_admin" on public.roadmap_templates
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
  );

drop policy if exists "roadmap_templates_insert_advisor_or_admin" on public.roadmap_templates;
create policy "roadmap_templates_insert_advisor_or_admin" on public.roadmap_templates
  for insert with check (
    auth.uid() = user_id
    and (public.is_advisor() or public.is_admin()
         or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null))
  );

drop policy if exists "roadmap_templates_update_advisor_or_admin" on public.roadmap_templates;
create policy "roadmap_templates_update_advisor_or_admin" on public.roadmap_templates
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
-- roadmap_templates_delete_advisor_or_admin queda sin cambios.

drop policy if exists "roadmap_template_steps_select_advisor_or_admin" on public.roadmap_template_steps;
create policy "roadmap_template_steps_select_advisor_or_admin" on public.roadmap_template_steps
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
  );

drop policy if exists "roadmap_template_steps_insert_advisor_or_admin" on public.roadmap_template_steps;
create policy "roadmap_template_steps_insert_advisor_or_admin" on public.roadmap_template_steps
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );

drop policy if exists "roadmap_template_steps_update_advisor_or_admin" on public.roadmap_template_steps;
create policy "roadmap_template_steps_update_advisor_or_admin" on public.roadmap_template_steps
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
-- roadmap_template_steps_delete_advisor_or_admin queda sin cambios.

drop policy if exists "roadmap_step_raci_select_advisor_or_admin" on public.roadmap_step_raci;
create policy "roadmap_step_raci_select_advisor_or_admin" on public.roadmap_step_raci
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
  );

drop policy if exists "roadmap_step_raci_insert_advisor_or_admin" on public.roadmap_step_raci;
create policy "roadmap_step_raci_insert_advisor_or_admin" on public.roadmap_step_raci
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );

drop policy if exists "roadmap_step_raci_update_advisor_or_admin" on public.roadmap_step_raci;
create policy "roadmap_step_raci_update_advisor_or_admin" on public.roadmap_step_raci
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
-- roadmap_step_raci_delete_advisor_or_admin queda sin cambios.

-- 13b) Instancias vinculadas a un proyecto: el dueño del proyecto sigue
--      viendo su propio roadmap de sólo lectura, sin cambios; se amplía el
--      resto de accesos vía 'roadmaps'.
drop policy if exists "project_roadmaps_select_own_or_advisor" on public.project_roadmaps;
create policy "project_roadmaps_select_own_or_advisor" on public.project_roadmaps
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
    or exists (
      select 1 from public.projects pr
      where pr.id = project_roadmaps.project_id and pr.user_id = auth.uid()
    )
  );

drop policy if exists "project_roadmaps_insert_advisor_or_admin" on public.project_roadmaps;
create policy "project_roadmaps_insert_advisor_or_admin" on public.project_roadmaps
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );

drop policy if exists "project_roadmaps_update_advisor_or_admin" on public.project_roadmaps;
create policy "project_roadmaps_update_advisor_or_admin" on public.project_roadmaps
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
-- project_roadmaps_delete_advisor_or_admin queda sin cambios.

drop policy if exists "roadmap_instances_select_own_or_advisor" on public.roadmap_instances;
create policy "roadmap_instances_select_own_or_advisor" on public.roadmap_instances
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
    or exists (
      select 1 from public.projects pr
      where pr.id = roadmap_instances.project_id and pr.user_id = auth.uid()
    )
  );

drop policy if exists "roadmap_instances_insert_advisor_or_admin" on public.roadmap_instances;
create policy "roadmap_instances_insert_advisor_or_admin" on public.roadmap_instances
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );

drop policy if exists "roadmap_instances_update_advisor_or_admin" on public.roadmap_instances;
create policy "roadmap_instances_update_advisor_or_admin" on public.roadmap_instances
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
-- roadmap_instances_delete_advisor_or_admin queda sin cambios.

drop policy if exists "roadmap_instance_steps_select_own_or_advisor" on public.roadmap_instance_steps;
create policy "roadmap_instance_steps_select_own_or_advisor" on public.roadmap_instance_steps
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
    or exists (
      select 1 from public.roadmap_instances gi
      join public.projects pr on pr.id = gi.project_id
      where gi.id = roadmap_instance_steps.instance_id and pr.user_id = auth.uid()
    )
  );

drop policy if exists "roadmap_instance_steps_insert_advisor_or_admin" on public.roadmap_instance_steps;
create policy "roadmap_instance_steps_insert_advisor_or_admin" on public.roadmap_instance_steps
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );

drop policy if exists "roadmap_instance_steps_update_advisor_or_admin" on public.roadmap_instance_steps;
create policy "roadmap_instance_steps_update_advisor_or_admin" on public.roadmap_instance_steps
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
-- roadmap_instance_steps_delete_advisor_or_admin queda sin cambios.

drop policy if exists "roadmap_instance_step_raci_select_own_or_advisor" on public.roadmap_instance_step_raci;
create policy "roadmap_instance_step_raci_select_own_or_advisor" on public.roadmap_instance_step_raci
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
    or exists (
      select 1 from public.roadmap_instance_steps ris
      join public.roadmap_instances ri on ri.id = ris.instance_id
      join public.projects pr on pr.id = ri.project_id
      where ris.id = roadmap_instance_step_raci.instance_step_id and pr.user_id = auth.uid()
    )
  );

drop policy if exists "roadmap_instance_step_raci_insert_advisor_or_admin" on public.roadmap_instance_step_raci;
create policy "roadmap_instance_step_raci_insert_advisor_or_admin" on public.roadmap_instance_step_raci
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );

drop policy if exists "roadmap_instance_step_raci_update_advisor_or_admin" on public.roadmap_instance_step_raci;
create policy "roadmap_instance_step_raci_update_advisor_or_admin" on public.roadmap_instance_step_raci
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
-- roadmap_instance_step_raci_delete_advisor_or_admin queda sin cambios.

-- ----------------------------------------------------------------------------
-- 14) Master Data: companies / public_agencies / contacts / products.
--     Sin noción de dueño individual (created_by es sólo informativo, como
--     hoy). Se amplía select/insert/update vía 'master_data'. Borrado sin
--     cambios (advisor o admin, tal cual) en las 4 tablas.
-- ----------------------------------------------------------------------------
drop policy if exists "companies_select_advisor_or_admin" on public.companies;
create policy "companies_select_advisor_or_admin" on public.companies
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'view', null)
  );
drop policy if exists "companies_insert_advisor_or_admin" on public.companies;
create policy "companies_insert_advisor_or_admin" on public.companies
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
drop policy if exists "companies_update_advisor_or_admin" on public.companies;
create policy "companies_update_advisor_or_admin" on public.companies
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
-- companies_delete_advisor_or_admin queda sin cambios.

drop policy if exists "public_agencies_select_advisor_or_admin" on public.public_agencies;
create policy "public_agencies_select_advisor_or_admin" on public.public_agencies
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'view', null)
  );
drop policy if exists "public_agencies_insert_advisor_or_admin" on public.public_agencies;
create policy "public_agencies_insert_advisor_or_admin" on public.public_agencies
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
drop policy if exists "public_agencies_update_advisor_or_admin" on public.public_agencies;
create policy "public_agencies_update_advisor_or_admin" on public.public_agencies
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
-- public_agencies_delete_advisor_or_admin queda sin cambios.

drop policy if exists "contacts_select_advisor_or_admin" on public.contacts;
create policy "contacts_select_advisor_or_admin" on public.contacts
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'view', null)
  );
drop policy if exists "contacts_insert_advisor_or_admin" on public.contacts;
create policy "contacts_insert_advisor_or_admin" on public.contacts
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
drop policy if exists "contacts_update_advisor_or_admin" on public.contacts;
create policy "contacts_update_advisor_or_admin" on public.contacts
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
-- contacts_delete_advisor_or_admin queda sin cambios.

drop policy if exists "products_select_advisor_or_admin" on public.products;
create policy "products_select_advisor_or_admin" on public.products
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'view', null)
  );
drop policy if exists "products_insert_advisor_or_admin" on public.products;
create policy "products_insert_advisor_or_admin" on public.products
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
drop policy if exists "products_update_advisor_or_admin" on public.products;
create policy "products_update_advisor_or_admin" on public.products
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
-- products_delete_advisor_or_admin queda sin cambios.

-- ----------------------------------------------------------------------------
-- 15) Storage (bucket project-documents, prefijo master-data/): mismo
--     criterio, sólo se amplían lectura y subida; el borrado de archivos
--     queda sin cambios (advisor o admin, tal cual).
-- ----------------------------------------------------------------------------
drop policy if exists "master_data_upload_advisor_or_admin" on storage.objects;
create policy "master_data_upload_advisor_or_admin" on storage.objects
  for insert with check (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = 'master-data'
    and (public.is_advisor() or public.is_admin()
         or public.has_entity_access(auth.uid(), 'master_data', 'edit', null))
  );

drop policy if exists "master_data_read_advisor_or_admin" on storage.objects;
create policy "master_data_read_advisor_or_admin" on storage.objects
  for select using (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = 'master-data'
    and (public.is_advisor() or public.is_admin()
         or public.has_entity_access(auth.uid(), 'master_data', 'view', null))
  );
-- master_data_delete_advisor_or_admin queda sin cambios.

-- ============================================================================
-- Fin migration_v46_role_permissions.sql
--
-- Notas para Pablo:
-- - Ya podés crear roles configurables adicionales insertando en public.roles
--   y public.role_permissions directamente por SQL si querés arrancar antes
--   de que exista la pantalla de administración (app/roles.html, en camino).
-- - Para asignarle un rol configurable a un usuario 'user' existente:
--     update public.profiles set custom_role_id = '<id del rol>'
--     where email = '...' and role = 'user';
--   (esto lo tiene que ejecutar un admin desde el SQL Editor, o luego desde
--   app/roles.html — el propio usuario no puede cambiárselo a sí mismo, la
--   guarda prevent_role_self_change lo bloquea).
-- ============================================================================
