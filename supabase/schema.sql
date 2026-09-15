-- ============================================================================
-- INA Platform — Supabase schema
-- Run this once in your Supabase project: Dashboard → SQL Editor → New query
-- → paste this whole file → Run.
--
-- NOTE: if you already ran an earlier version of this file (before the
-- advisor role / project grid feature existed), do NOT re-run this whole
-- file — run supabase/migration_v2_roles_and_grid.sql instead. This file
-- is for brand-new Supabase projects only.
-- ============================================================================

-- ---------- profiles ----------
-- One row per registered user, mirroring auth.users. Created automatically
-- by the trigger below whenever someone signs up.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  organization text not null,
  -- Mirrors auth.users.email, kept in sync by handle_new_user() below.
  -- Lets the admin user-management panel list/search users without
  -- needing service-role access to auth.users from the client.
  email text,
  role_type text not null check (role_type in (
    'government_regulator',
    'development_finance_institution',
    'investor_infrastructure_fund',
    'technology_company',
    'other'
  )),
  -- Platform access role. 'user' (default) can only see/edit their own
  -- projects. 'advisor' can view every project on the platform. 'admin'
  -- can view every project AND change any user's role via app/admin.html.
  -- There is deliberately no self-service way to become an advisor/admin
  -- at signup — an existing admin promotes a user from the admin panel
  -- (or, for the very first admin, via Table Editor), after they've
  -- signed up normally. Self-service selection would let anyone grant
  -- themselves visibility into other users' data.
  role text not null default 'user' check (role in ('user', 'advisor', 'admin')),
  -- Advisor specialization — nullable/unused today (see the workflow
  -- section near the end of this file). Every advisor is general-purpose
  -- right now, so this stays null for all of them until specialized
  -- technical/financial/administrative advisor roles actually launch.
  specialization text check (specialization is null or specialization in ('technical', 'financial', 'administrative')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Small helpers used by RLS policies below to check the current user's
-- role without repeating the subquery everywhere. Defined before any
-- policy that calls them.
create or replace function public.is_advisor()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'advisor'
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- ---------- roles / role_permissions (configurable roles) ----------
-- See supabase/migration_v46_role_permissions.sql for the full rationale.
-- Admin and Advisor stay hardcoded system roles on profiles.role; this pair
-- of tables lets a 'user' profile additionally be assigned a configurable
-- role (profiles.custom_role_id below) with per-entity view/edit permissions
-- and an "own"/"all" scope.
--
-- NOTE on ordering: roles.created_by references profiles(id), and
-- profiles.custom_role_id (added further below) references roles(id) — a
-- circular dependency between the two tables. That's why custom_role_id is
-- added to profiles via ALTER TABLE (after both tables independently
-- exist) instead of being inlined into the profiles CREATE TABLE above, and
-- why public.has_entity_access() (a `language sql` function, validated
-- against the catalog at CREATE FUNCTION time) is defined below, only once
-- role_permissions and profiles.custom_role_id both exist.
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

-- Seed data (default "Usuario" role + its permissions) lives in migration_v46_role_permissions.sql, not here.

-- profiles.custom_role_id — only consulted when profiles.role = 'user'.
-- NULL means no additional permissions (today's behavior: no access to
-- anything beyond the user's own rows). See public.has_entity_access()
-- below.
alter table public.profiles
  add column if not exists custom_role_id uuid references public.roles(id) on delete set null;

comment on column public.profiles.custom_role_id is 'Sólo se consulta cuando profiles.role = ''user''. Rol configurable (tabla roles) asignado a este usuario. NULL = sin permisos adicionales (comportamiento actual: sin acceso a nada salvo lo suyo).';

-- ---------- configurable role permissions: central check function ----------
-- Central permission check for the configurable-roles system:
--   mode: 'view' or 'edit'.
--   owner_id: the row's owner (or NULL if the entity has no notion of an
--             individual owner, e.g. Master Data or Roadmaps).
--
--   admin        -> always true.
--   advisor      -> true for every entity EXCEPT 'user_management'.
--   user (or no  -> looks up profiles.custom_role_id -> role_permissions for
--   profile)        that entity+mode; if scope='own', also requires
--                    owner_id = uid.
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

-- Convenience wrappers for entities with no notion of an individual owner
-- (Master Data, Roadmaps, Risks at the function level, User Management).
create or replace function public.can_view_entity(p_uid uuid, p_entity text)
returns boolean language sql security definer set search_path = public stable as $$
  select public.has_entity_access(p_uid, p_entity, 'view', null);
$$;

create or replace function public.can_edit_entity(p_uid uuid, p_entity text)
returns boolean language sql security definer set search_path = public stable as $$
  select public.has_entity_access(p_uid, p_entity, 'edit', null);
$$;

-- ---------- roles / role_permissions RLS ----------
-- Only whoever has edit/view on 'user_management' (today, only Admin,
-- unless a configurable role is created with that permission).
create policy "roles_select_user_management" on public.roles
  for select using (public.has_entity_access(auth.uid(), 'user_management', 'view', null));

create policy "roles_insert_user_management" on public.roles
  for insert with check (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

create policy "roles_update_user_management" on public.roles
  for update using (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

create policy "roles_delete_user_management" on public.roles
  for delete using (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

create policy "role_permissions_select_user_management" on public.role_permissions
  for select using (public.has_entity_access(auth.uid(), 'user_management', 'view', null));

create policy "role_permissions_insert_user_management" on public.role_permissions
  for insert with check (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

create policy "role_permissions_update_user_management" on public.role_permissions
  for update using (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

create policy "role_permissions_delete_user_management" on public.role_permissions
  for delete using (public.has_entity_access(auth.uid(), 'user_management', 'edit', null));

-- Additive SELECT policies (see supabase/migration_v62_roles_self_select.sql):
-- any authenticated user can read the ONE roles/role_permissions row that
-- corresponds to their own profiles.custom_role_id, even without
-- 'user_management' access. Without this, the nested `custom_role:roles(...)`
-- embed in getProfile() (assets/platform.js) resolves to null for a user
-- whose custom role only grants some other entity (e.g. 'master_data'),
-- which silently breaks entityPermission() for that user on every entity —
-- not just user_management. Multiple SELECT policies on the same table are
-- OR'd together in Postgres RLS, so this only adds visibility, never removes
-- it.
create policy "roles_select_own_assigned_role" on public.roles
  for select using (
    id = (select custom_role_id from public.profiles where id = auth.uid())
  );

create policy "role_permissions_select_own_assigned_role" on public.role_permissions
  for select using (
    role_id = (select custom_role_id from public.profiles where id = auth.uid())
  );

-- Regular users see only their own profile row; advisors and admins can
-- see every profile (advisors need this so the "all projects" grid can
-- show who submitted each project; admins need it for the user list in
-- app/admin.html). Also visible to anyone with 'user_management' view
-- access via a configurable role — see supabase/migration_v46_role_permissions.sql.
create policy "profiles_select_own_or_privileged" on public.profiles
  for select using (
    auth.uid() = id
    or public.is_advisor()
    or public.is_admin()
    or public.has_entity_access(auth.uid(), 'user_management', 'view', null)
  );

create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);

-- Lets an admin change any user's role (or other fields) from
-- app/admin.html. The prevent_role_self_change_trigger below still blocks
-- an admin from changing their OWN role this way, by design — promoting
-- the very first admin, or an admin stepping down, still goes through
-- Table Editor. Also lets anyone with 'user_management' edit access via a
-- configurable role — see supabase/migration_v46_role_permissions.sql.
create policy "profiles_update_admin" on public.profiles
  for update using (
    public.is_admin()
    or public.has_entity_access(auth.uid(), 'user_management', 'edit', null)
  );

create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

-- profiles_update_own above allows a user to update their own row, but
-- says nothing about which COLUMNS — without this trigger, a user could
-- call the same update() a profile-editing UI uses to also set their own
-- role to 'advisor'/'admin' and see every project on the platform, or
-- change other users' roles. This trigger blocks that specific case
-- (self-edit changing role) for EVERYONE including admins — role changes
-- always have to be someone else editing your row (the admin panel, or
-- Table Editor for the very first admin). Also blocks a user from
-- self-assigning a custom_role_id (privilege escalation via their own
-- profile edit) — see supabase/migration_v46_role_permissions.sql.
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

drop trigger if exists prevent_role_self_change_trigger on public.profiles;
create trigger prevent_role_self_change_trigger
  before update on public.profiles
  for each row execute procedure public.prevent_role_self_change();

-- Auto-create a profile row when a new auth user is created, populating
-- full_name/organization/role_type from the signUp() options.data payload,
-- and mirroring the auth email. role always starts as 'user' regardless
-- of signup payload. custom_role_id is set to whichever role (if any) is
-- marked is_default_signup_role — see supabase/migration_v46_role_permissions.sql.
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

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------- programs ----------
-- A Program groups several related projects under one umbrella — e.g.
-- Chubut's "Hub Digital Patagónico" program, which bundled a submarine
-- cable landing, a regional backbone and last-mile builds as separate
-- projects, each financed independently, all presented by the same
-- sponsoring organization. A project belongs to at most one program
-- (projects.program_id below); a program can have many projects.
-- Program-level fields are deliberately minimal — the substantive data
-- (type, country, description, financing, analysis) always lives on the
-- individual projects, never duplicated here.
create table if not exists public.programs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  -- Optional English name, shown instead of name when the viewer has the
  -- site in English — see INAPlatform.programDisplayName() in
  -- assets/platform.js. NULL/empty falls back to name everywhere. See
  -- migration_v57_program_name_en.sql.
  name_en text,
  -- The public or private entity presenting the program (e.g. a
  -- provincial government, a cooperative, a private operator).
  organization text not null,
  -- Optional English override for organization, same fallback convention
  -- as name_en above — see INAPlatform.programDisplayOrganization() in
  -- assets/platform.js and
  -- migration_v61_bilingual_organization_financing_entity.sql.
  organization_en text,
  organization_type text not null default 'public' check (organization_type in ('public', 'private')),
  -- The institution that actually FINANCES this program (e.g. "Banco
  -- Interamericano de Desarrollo (BID)", "CAF", "Banco de la Nación
  -- Argentina") — distinct from organization above, which is who PRESENTS
  -- the program (the proponent). Free text, same convention as
  -- organization. For programs tied to the Universal Service Fund, the
  -- agreed value is "ENACOM-FSU" — see
  -- INAPlatform.isFsuFinancingEntity() in assets/platform.js, which groups
  -- these together with the project's direct FSU financing fields in
  -- app/project.html's Financing tab. See
  -- migration_v36_program_financing_entity.sql.
  financing_entity text,
  -- Optional English override for financing_entity, same fallback
  -- convention as name_en above — see
  -- INAPlatform.programDisplayFinancingEntity() in assets/platform.js and
  -- migration_v61_bilingual_organization_financing_entity.sql.
  financing_entity_en text,
  -- Unlike a project (always single-type, see the comment on
  -- projects.project_type below), a Program CAN be multiple types — it's a
  -- declared, editable attribute of the program itself (set when creating
  -- it, independent of which projects have been submitted under it yet),
  -- drawn from the same catalog as projects.project_type. Purely
  -- informational/filtering, same spirit as the rest of the program-level
  -- fields. See supabase/migration_v11_program_types.sql.
  types text[] not null default '{}' check (types <@ array[
    'submarine_cable',
    'fiber_backbone_last_mile',
    'fixed_wireless_access',
    'wholesale_neutral_network',
    'ai_datacenter',
    'satellite_constellation',
    'early_warning_system',
    'passive_infrastructure',
    'other'
  ]::text[]),
  description text,
  -- Optional English description, same fallback convention as name_en
  -- above — see INAPlatform.programDisplayDescription() in
  -- assets/platform.js and migration_v60_bilingual_title_description.sql.
  description_en text,
  -- Optional pointer into assets/platform.js's PROGRAM_TEMPLATES registry
  -- (e.g. 'capital_markets_debt_financing') — lets a submitter applying to
  -- this Program get a guided, program-specific intake form on top of any
  -- project-type template. No CHECK constraint: it's purely a JS-side
  -- lookup key, so an unrecognized value just means no template shows up,
  -- never a rejected insert. See supabase/migration_v18_program_template_key.sql.
  template_key text,
  -- 'preparation' = this Program funds the ELABORATION/structuring of the
  -- project itself (e.g. a USTDA Feasibility Study / Definitional Mission
  -- grant) — filled in early, before the project has a finished design.
  -- 'financing' (default) = this Program funds the project's actual
  -- implementation (FSU, BID, capital markets debt, TASU, etc.) — what
  -- every pre-existing Program means. A project can apply to at most one
  -- preparation Program plus any number of financing Programs at once (see
  -- public.project_programs below) — e.g. USTDA for elaboration, then FSU
  -- + BID together for the build-out. See
  -- supabase/migration_v21_program_funding_stage_and_applications.sql.
  funding_stage text not null default 'financing' check (funding_stage in ('preparation', 'financing')),
  -- 'financing' (default) = the Program IS a funding source itself (what
  -- funding_stage above further splits into preparation vs. financing) —
  -- selectable in a project's preparation/financing pickers. 'umbrella' =
  -- the Program only GROUPS several independently-financed projects under
  -- one sponsoring initiative — e.g. EPECH's "Atlántico-Pacífico", which
  -- bundles a fiber backbone, a submarine cable, a datacenter and passive
  -- infrastructure as four separate, separately-financed projects. An
  -- umbrella Program is never itself a funding source, so it's excluded
  -- from the preparation/financing pickers and is the only kind offered in
  -- the "Program" (umbrella) field when creating a project. See
  -- supabase/migration_v43_program_role.sql.
  program_role text not null default 'financing' check (program_role in ('financing', 'umbrella')),
  -- Edit-mode concurrency lock — see migration_v31_edit_locks.sql and
  -- acquire_program_edit_lock()/release_program_edit_lock() below.
  edit_locked_by uuid references public.profiles(id) on delete set null,
  edit_locked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.programs enable row level security;

-- Unlike projects/documents/analysis, Programs are visible to EVERY
-- authenticated user, not just their owner/advisor/admin — any user
-- submitting a project needs to be able to see and pick every Program to
-- associate it with, not just their own. See
-- supabase/migration_v19_program_permissions.sql.
create policy "programs_select_all_authenticated" on public.programs
  for select using (auth.uid() is not null);

-- Creating a Program is restricted to advisors/admins (a standard user can
-- still see and use every Program when submitting a project — see the
-- SELECT policy above — just not create one). See
-- supabase/migration_v19_program_permissions.sql. Also open to anyone with
-- 'edit' access to the corresponding entity ('initiatives' for umbrella
-- programs, 'financing' for the rest) via a configurable role — see
-- supabase/migration_v46_role_permissions.sql.
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

-- Any advisor/admin, or anyone with 'edit' access to the corresponding
-- entity via a configurable role, can manage ANY Iniciativa/Financiación —
-- not just their own. See supabase/migration_v46_role_permissions.sql.
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

-- Owner or admin only — see supabase/migration_v14_delete_policies.sql for
-- the full rationale (advisors deliberately excluded; deleting is more
-- destructive than the view-only access they get elsewhere). Deleting a
-- program does NOT delete its member projects (program_id is "on delete
-- set null" below) — they're just unlinked.
create policy "programs_delete_own_or_admin" on public.programs
  for delete using (auth.uid() = user_id or public.is_admin());

create index if not exists programs_user_id_idx on public.programs(user_id);

-- ---------- program_documents ----------
-- Supporting documents (PDFs, images, etc.) attached to a Program itself —
-- same shape/RLS pattern as project_documents below, just scoped to
-- public.programs. See supabase/migration_v13_program_documents.sql for the
-- full rationale, including why no new Storage bucket is needed (reuses
-- "project-documents", path convention {user_id}/programs/{program_id}/{filename}).
create table if not exists public.program_documents (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  file_name text not null,
  storage_path text not null,
  uploaded_at timestamptz not null default now()
);

alter table public.program_documents enable row level security;

create policy "program_documents_select_own_or_advisor" on public.program_documents
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

create policy "program_documents_insert_own" on public.program_documents
  for insert with check (auth.uid() = user_id);

-- Owner-only — see supabase/migration_v16_document_delete.sql. Lets the
-- program owner remove a mistaken upload or delete-then-reupload to
-- "replace" a file; the UI never offers this to anyone but the owner.
create policy "program_documents_delete_own" on public.program_documents
  for delete using (auth.uid() = user_id);

create index if not exists program_documents_program_id_idx on public.program_documents(program_id);

-- ---------- projects ----------
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  -- References profiles(id) rather than auth.users(id) directly so that
  -- PostgREST/Supabase-js can embed the owner's profile in one query
  -- (`.select('*, profiles(full_name, organization)')`), which the
  -- advisor "all projects" grid relies on. profiles.id is itself FK'd
  -- 1:1 to auth.users(id), so referential integrity is unchanged.
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  project_type text not null check (project_type in (
    'submarine_cable',
    'fiber_backbone_last_mile',
    'fixed_wireless_access',
    'wholesale_neutral_network',
    'ai_datacenter',
    'satellite_constellation',
    'early_warning_system',
    'passive_infrastructure',
    'other'
  )),
  -- A project is always a single type — it's what drives the 9th,
  -- type-specific dimension in the self-assessment questionnaire and the
  -- dashboard's type icon. Multi-component initiatives (e.g. a submarine
  -- cable landing, a regional backbone and last-mile builds presented
  -- together) are modeled as a Program containing several single-type
  -- projects (see public.programs above), not as one project with several
  -- types — that's what program_id below is for. (An earlier iteration
  -- had a `secondary_types` array directly on projects for this same
  -- multi-component case; it was removed in migration v10 once Programs
  -- existed to model it correctly.)
  program_id uuid references public.programs(id) on delete set null,
  country text not null,
  description text not null,
  -- Households/beneficiaries reached — the key impact metric for
  -- Universal Service Fund-style submissions (ENACOM's Fondo de Servicio
  -- Universal "carpeta técnica" format has a dedicated section for this).
  -- Optional and purely informational: null for projects where it doesn't
  -- apply (e.g. a submarine cable or datacenter with no direct household
  -- count).
  beneficiary_count integer check (beneficiary_count is null or beneficiary_count >= 0),
  -- Who submitted/generated this project and what kind of organization
  -- they are — see migration_v27_gestion_instances.sql. Purely
  -- informational (no FK — there's no shared entities registry in this
  -- schema); also used to suggest matching Roadmap templates whose
  -- allowed_entity_type matches.
  generating_entity_name text,
  generating_entity_type text check (generating_entity_type is null or generating_entity_type in (
    'regulator', 'national_gov', 'provincial_gov', 'municipal_gov', 'isp', 'manufacturer', 'integrator', 'other'
  )),
  status text not null default 'submitted' check (status in (
    'submitted', 'analyzing', 'completed', 'error'
  )),
  -- Denormalized copy of the latest framework_analysis.stage (Concept
  -- Stage / Early Structuring / Advanced Structuring / Investment Ready),
  -- written by /api/analyze-project.js when an analysis completes. Lets
  -- the dashboard grid show/filter by framework-derived stage without an
  -- extra join per row. Null until the first analysis completes.
  readiness_stage text,
  -- Which advisor is currently working this project (see the workflow
  -- section near the end of this file). Nullable, unrestricted — any
  -- advisor can take or reassign any project for now. Normally written by
  -- take_project()/promote_project_workflow()/demote_project_workflow()/
  -- return_project_to_not_analyzed(), not a direct client update — though
  -- note that since migration_v19_advisor_edit_taken_project.sql broadened
  -- projects_update_own to projects_update_own_or_assigned_advisor (so an
  -- advisor can edit a project they've taken), a client-side .update() call
  -- from the owner or the currently-assigned advisor COULD also touch this
  -- column directly; RLS only gates who can update a row, not which
  -- columns. Nothing in the current UI does that, but it's no longer
  -- structurally prevented the way it was before that migration.
  assigned_advisor_id uuid references public.profiles(id) on delete set null,
  -- Flat {field_key: value} pool of facts already known about this project,
  -- shared across every guided template (project-type, umbrella Program,
  -- preparation-funding Program, financing Program templates) so the same
  -- fact isn't re-entered/re-extracted for each one — see
  -- migration_v23_project_shared_field_answers.sql and
  -- INAPlatform.mergeSharedFieldAnswers()/autofillTemplateAnswers() in
  -- assets/platform.js. Purely a convenience cache, never the source of
  -- truth for any individual template's own answers/description.
  shared_field_answers jsonb not null default '{}'::jsonb,
  -- Edit-mode concurrency lock — see migration_v31_edit_locks.sql and
  -- acquire_project_edit_lock()/release_project_edit_lock() below.
  edit_locked_by uuid references public.profiles(id) on delete set null,
  edit_locked_at timestamptz,
  -- Estimated project duration (value + unit) — see migration_v33_project_attributes.sql.
  duration_value integer check (duration_value is null or duration_value > 0),
  duration_unit text check (duration_unit is null or duration_unit in ('days', 'months')),
  -- Priority for the implementing organization (not the same axis as
  -- technical_criticality below — this is about management urgency).
  -- Reuses the same 3-tier scale as framework_analysis.gap_roadmap[].priority
  -- (see PRIORITY_LABELS in assets/platform.js) for vocabulary consistency.
  priority text check (priority is null or priority in ('low', 'medium', 'high')),
  -- Technical criticality (impact of a technical failure/delay) — same
  -- 3-tier scale as priority above, but a distinct axis.
  technical_criticality text check (technical_criticality is null or technical_criticality in ('low', 'medium', 'high')),
  -- Amount requested/estimated from the Universal Service Fund (FSU) as a
  -- financing mechanism — distinct from shared_field_answers.monto_total_solicitado
  -- (a guided template's total project budget). Assumed ARS, no separate
  -- currency column.
  fsu_amount numeric check (fsu_amount is null or fsu_amount >= 0),
  -- Same FSU amount expressed in USD instead of ARS — see
  -- migration_v38_usd_amounts.sql. Independent of fsu_amount above; both
  -- can be loaded at once (e.g. a source document quotes a figure in
  -- dollars, and the ARS figure is derived later via exchange_rate). Not
  -- auto-synced with fsu_amount — see exchange_rate below.
  fsu_amount_usd numeric check (fsu_amount_usd is null or fsu_amount_usd >= 0),
  -- Free-form description of what the FSU financing would cover (localities,
  -- households, services) — no closed category list defined in reviewed
  -- regulation.
  fsu_scope text,
  -- % of budget_amount the FSU financing would cover — see
  -- migration_v35_financing_mix.sql. Complements fsu_amount (absolute
  -- amount) and fsu_scope (free-form description) above.
  fsu_percentage numeric check (fsu_percentage is null or (fsu_percentage >= 0 and fsu_percentage <= 100)),
  -- Total estimated project cost, independent of financing source — see
  -- migration_v34_project_budget_complexity.sql. Distinct from fsu_amount
  -- above (specifically the FSU-mechanism slice of financing).
  budget_amount numeric check (budget_amount is null or budget_amount >= 0),
  -- Same total budget expressed in USD instead of ARS — see
  -- migration_v38_usd_amounts.sql. Many source documents (pliegos,
  -- carpetas técnicas, planillas de seguimiento) quote figures in dollars;
  -- this column keeps that figure intact instead of forcing a guessed ARS
  -- conversion into budget_amount. Independent of budget_amount above —
  -- not auto-synced. Use exchange_rate below to compute an ARS-equivalent
  -- on demand (see INAPlatform.usdToArs() in assets/platform.js).
  budget_amount_usd numeric check (budget_amount_usd is null or budget_amount_usd >= 0),
  -- ARS-per-USD exchange rate used to convert budget_amount_usd /
  -- fsu_amount_usd into pesos when needed — see
  -- migration_v38_usd_amounts.sql. A single shared rate for both USD
  -- fields on this project (loading it once and reusing it is simpler
  -- than tracking two independently, and in practice both figures tend to
  -- come from the same source document/date). Never written
  -- automatically — always a manual, explicit figure the user enters.
  exchange_rate numeric check (exchange_rate is null or exchange_rate > 0),
  -- Date the exchange_rate above was captured/quoted — lets a reviewer
  -- judge how stale the rate is before trusting the ARS-equivalent shown
  -- in the UI (the peso/dollar rate in Argentina can move significantly
  -- week to week).
  exchange_rate_date date,
  -- Financing mix: the remainder of budget_amount covered by a source that
  -- is neither the FSU nor a Program registered on the platform (own
  -- funds, a one-off credit line, etc.) — see
  -- migration_v35_financing_mix.sql. Both optional and independent of each
  -- other; other_financing_notes is free text describing the source.
  other_financing_percentage numeric check (other_financing_percentage is null or (other_financing_percentage >= 0 and other_financing_percentage <= 100)),
  -- Same "other" bucket, expressed as an absolute amount (ARS) instead of a
  -- percentage — see migration_v37_financing_amounts.sql. Independent of
  -- other_financing_percentage above (same convention as fsu_amount/
  -- fsu_percentage); INAPlatform.computeFinancingCoverage() decides which
  -- one to use for the coverage summary.
  other_financing_amount numeric check (other_financing_amount is null or other_financing_amount >= 0),
  other_financing_notes text,
  -- % of budget_amount that actually NEEDS external financing — e.g. 70 if
  -- the proponent already has 30% confirmed as own capital/equity, so only
  -- the remaining 70% needs to be raised. NULL means "not specified", which
  -- every caller treats as 100 (the whole budget needs financing) — see
  -- INAPlatform.effectiveFinancingRequiredPercentage() in assets/platform.js.
  -- This is the TARGET app/project-financing.html tries to reach with FSU +
  -- Program shares + "other source" — distinct from
  -- computeFinancingCoverage()'s totalPct, which is simply how much is
  -- CURRENTLY allocated regardless of the target. See
  -- migration_v56_financing_required_percentage.sql. Added when financing
  -- management (FSU/Programs/other source/AI recommendation) was split out
  -- of new-project.html into its own dedicated page (Pablo, sep 2026): the
  -- project edit form now only asks for budget_amount/budget_amount_usd and
  -- this field — everything else about HOW the budget gets financed is
  -- decided afterward, on project-financing.html.
  financing_required_percentage numeric check (financing_required_percentage is null or (financing_required_percentage >= 0 and financing_required_percentage <= 100)),
  -- Intrinsic project complexity (moving parts, interdependencies, unproven
  -- technology) — a distinct axis from priority (management urgency) and
  -- technical_criticality (impact of a technical failure), but reuses the
  -- same 3-tier scale as both for visual consistency.
  complexity text check (complexity is null or complexity in ('low', 'medium', 'high')),
  -- Last Gate of the Project Structuring Framework™ (F1) approved (0 to 4;
  -- 0 = no gate approved yet). Independent of readiness_stage above (that's
  -- F2, the Investment Readiness Index™ stage) — see
  -- migration_v39_project_gates.sql and approve_project_gate() below.
  -- Written only by approve_project_gate(), never a direct client update.
  current_gate int not null default 0 check (current_gate between 0 and 4),
  -- Investment Proposal document — editable, AI-draftable narrative
  -- chapters for the formal financing proposal presented to financial
  -- institutions (IDB, USTDA, DFC, FSU, etc.), distinct from the shorter
  -- internal "Descargar PDF" project summary — see
  -- migration_v50_investment_proposal.sql, api/generate-proposal.js and
  -- generateProposalPdf() in app/project.html. Bilingual pair per chapter,
  -- same pattern as framework_analysis's _en columns.
  -- Executive Summary chapter — added in migration_v58, shown as its OWN
  -- chapter before Introduction in the PDF (see generateProposalPdf() in
  -- app/investment-proposal.html).
  proposal_executive_summary text,
  proposal_executive_summary_en text,
  proposal_introduction text,
  proposal_introduction_en text,
  proposal_technical_description text,
  proposal_technical_description_en text,
  proposal_benefits text,
  proposal_benefits_en text,
  proposal_planning_narrative text,
  proposal_planning_narrative_en text,
  proposal_updated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.projects enable row level security;

-- Regular users see only their own projects; advisors and admins see every
-- project. Also visible to anyone with 'view' access to 'projects' via a
-- configurable role (scope='own' further restricts that to their own
-- projects) — see supabase/migration_v46_role_permissions.sql.
create policy "projects_select_own_or_advisor" on public.projects
  for select using (
    auth.uid() = user_id
    or auth.uid() = assigned_advisor_id
    or public.is_advisor()
    or public.is_admin()
    or public.has_entity_access(auth.uid(), 'projects', 'view', user_id)
  );

create policy "projects_insert_own" on public.projects
  for insert with check (auth.uid() = user_id);

-- Editing is owner-only, OR the advisor who has taken the project
-- (assigned_advisor_id, set only by take_project()/
-- promote_project_workflow()/demote_project_workflow() above) — see
-- supabase/migration_v19_advisor_edit_taken_project.sql for the full
-- rationale (originally owner-only; broadened once an advisor could take
-- a project and needed to edit/re-analyze/self-assess it). Also editable
-- by anyone with 'edit' access to 'projects' via a configurable role — see
-- supabase/migration_v46_role_permissions.sql.
create policy "projects_update_own_or_assigned_advisor" on public.projects
  for update using (
    auth.uid() = user_id
    or auth.uid() = assigned_advisor_id
    or public.has_entity_access(auth.uid(), 'projects', 'edit', user_id)
  );

-- Owner or admin only — see supabase/migration_v14_delete_policies.sql.
-- Cascades to project_documents, framework_analysis, fsu_scoring and
-- project_workflow_events via their existing "on delete cascade" FKs.
create policy "projects_delete_own_or_admin" on public.projects
  for delete using (auth.uid() = user_id or public.is_admin());

create index if not exists projects_user_id_idx on public.projects(user_id);
create index if not exists projects_program_id_idx on public.projects(program_id);

-- ---------- project_programs ----------
-- A project can apply to MANY financing/preparation Programs at once — e.g.
-- FSU + BID together for implementation financing, plus USTDA separately
-- for elaboration funding — independent of the single "umbrella"
-- projects.program_id above (which groups related projects the way Chubut's
-- "Hub Digital Patagónico" does, and is untouched by this table). Each row
-- is one (project, program) application; template_answers/notes hold that
-- Program's guided-template intake (see PROGRAM_TEMPLATES in
-- assets/platform.js), filled in specifically for this application when the
-- Program has a template_key — both null for a Program with none, where
-- applying is just a plain association. See
-- supabase/migration_v21_program_funding_stage_and_applications.sql.
create table if not exists public.project_programs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  program_id uuid not null references public.programs(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  template_answers jsonb,
  notes text,
  -- % of the project's total budget (projects.budget_amount) this specific
  -- application covers — see migration_v35_financing_mix.sql. Only
  -- meaningful when the embedded programs.funding_stage isn't
  -- 'preparation' (a preparation-stage Program funds elaborating the
  -- project, not a share of its implementation cost).
  financing_percentage numeric check (financing_percentage is null or (financing_percentage >= 0 and financing_percentage <= 100)),
  -- Same share, expressed as an absolute amount (ARS) instead of a
  -- percentage — see migration_v37_financing_amounts.sql. Independent of
  -- financing_percentage above; INAPlatform.computeFinancingCoverage()
  -- decides which one to use for the coverage summary.
  financing_amount numeric check (financing_amount is null or financing_amount >= 0),
  applied_at timestamptz not null default now(),
  unique (project_id, program_id)
);

alter table public.project_programs enable row level security;

-- Same visibility as the parent project: its owner, the advisor currently
-- assigned to it, or any advisor/admin (matches fsu_scoring's pattern).
create policy "project_programs_select_own_or_advisor" on public.project_programs
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = project_programs.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

create policy "project_programs_insert_own_or_assigned_advisor" on public.project_programs
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.projects pr
      where pr.id = project_programs.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

-- Lets the owner or assigned advisor withdraw an application (picked the
-- wrong program, wants to redo the template answers, etc.).
create policy "project_programs_delete_own_or_assigned_advisor" on public.project_programs
  for delete using (
    exists (
      select 1 from public.projects pr
      where pr.id = project_programs.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

-- Missing until migration_v49_project_programs_update_policy.sql — without
-- it, INAPlatform.applyToProgram()'s upsert failed with "new row violates
-- row-level security policy (USING expression)" whenever the application
-- already existed (its upsert falls through to an UPDATE on conflict), and
-- so did updateProjectProgramFinancing()'s direct .update() (the %/Monto
-- "Guardar" button on project.html's Financing tab). Same owner-or-
-- assigned-advisor criterion as the INSERT/DELETE policies above.
create policy "project_programs_update_own_or_assigned_advisor" on public.project_programs
  for update using (
    exists (
      select 1 from public.projects pr
      where pr.id = project_programs.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

create index if not exists project_programs_project_id_idx on public.project_programs(project_id);
create index if not exists project_programs_program_id_idx on public.project_programs(program_id);

-- Business rule (Pablo, sep 2026 — see migration_v48_single_fsu_program.sql):
-- a project can apply to only ONE Universal Service Fund (FSU) financing
-- line at a time — any Program with financing_entity = 'ENACOM-FSU' (TASU,
-- FATIC, Red Mayorista Neutral, Conectividad de Interés Público...). It can
-- still combine that one FSU line with any number of OTHER financiers (BID,
-- CAF, USTDA, DFC...) — the restriction is "one FSU line", not "one
-- program". Enforced at the DB level (not just in the UI — see
-- app/new-project.html's renderFinancingProgramOptions() and
-- app/project.html's updateApplyPickers(), which also prevent this from the
-- UI side) so a stray insert can't slip past it either.
create or replace function public.enforce_single_fsu_program()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_program record;
  conflicting_name text;
begin
  select funding_stage, financing_entity
  into new_program
  from public.programs
  where id = new.program_id;

  if new_program.funding_stage = 'preparation'
     or new_program.financing_entity is null
     or trim(lower(new_program.financing_entity)) <> 'enacom-fsu' then
    return new;
  end if;

  select p.name
  into conflicting_name
  from public.project_programs pp
  join public.programs p on p.id = pp.program_id
  where pp.project_id = new.project_id
    and pp.program_id <> new.program_id
    and p.funding_stage <> 'preparation'
    and p.financing_entity is not null
    and trim(lower(p.financing_entity)) = 'enacom-fsu'
  limit 1;

  if conflicting_name is not null then
    raise exception 'Este proyecto ya está aplicado a otra línea de financiamiento del FSU ("%"). Un proyecto solo puede recibir financiamiento de UNA línea del FSU a la vez — se puede combinar con financiamiento de otros organismos (BID, CAF, USTDA, etc.) sin límite. Quitá la aplicación anterior antes de aplicar a esta.', conflicting_name;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_single_fsu_program on public.project_programs;
create trigger trg_enforce_single_fsu_program
  before insert or update on public.project_programs
  for each row
  execute function public.enforce_single_fsu_program();

-- ---------- project_documents ----------
-- document_type categorizes each upload as one of seven buckets a project
-- evaluation eventually needs (technical / economic / financial / bylaws /
-- administrative / licenses / other) — originally 4 categories via
-- supabase/migration_v15_document_categories.sql, widened to 7 by
-- supabase/migration_v24_document_categories_expand.sql. None are required
-- at upload time; the UI (new-project.html's creation wizard) offers seven
-- optional drop zones instead of one, uploading immediately so evaluators
-- (and the AI document-scanning agent) can find/use things without forcing
-- the submitter to have everything ready up front.
create table if not exists public.project_documents (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  file_name text not null,
  storage_path text not null,
  document_type text not null default 'other'
    check (document_type in ('technical', 'economic', 'financial', 'bylaws', 'administrative', 'licenses', 'other')),
  uploaded_at timestamptz not null default now()
);

alter table public.project_documents enable row level security;

create policy "documents_select_own_or_advisor" on public.project_documents
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

create policy "documents_insert_own" on public.project_documents
  for insert with check (auth.uid() = user_id);

-- Owner-only — see supabase/migration_v16_document_delete.sql. Lets the
-- project owner remove a mistaken upload or delete-then-reupload to
-- "replace" a file; the UI never offers this to anyone but the owner.
create policy "documents_delete_own" on public.project_documents
  for delete using (auth.uid() = user_id);

create index if not exists project_documents_project_id_idx on public.project_documents(project_id);
create index if not exists project_documents_document_type_idx on public.project_documents(document_type);

-- ---------- framework_analysis ----------
-- One row per completed analysis run — either written server-side by
-- /api/analyze-project (source='ai', using the service role key, never by
-- the client directly) or submitted by the project owner from
-- app/assessment.html's 9-dimension questionnaire (source='manual', a
-- plain client insert allowed by the policy below). Today the manual path
-- is answered by hand; eventually the same questionnaire's answers are
-- meant to be deduced automatically from the project's uploaded
-- documents, at which point it becomes another 'ai'-sourced write.
create table if not exists public.framework_analysis (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  overall_score int,
  stage text,
  -- dimensions/gap_roadmap/financing_recommendations/summary are always
  -- Spanish — every row loaded on this platform so far (hand-authored via
  -- SQL or produced by /api/analyze-project.js) uses Spanish as the
  -- canonical language. The _en columns below are the English translation,
  -- nullable — see migration_v40_bilingual_analysis.sql and
  -- INAPlatform.localizeAnalysis() in assets/platform.js, which falls back
  -- to these unsuffixed (Spanish) columns whenever the _en counterpart is
  -- null (not translated yet).
  dimensions jsonb,
  gap_roadmap jsonb,
  financing_recommendations jsonb,
  summary text,
  -- English translations — same shape as their unsuffixed counterparts
  -- above (dimensions_en: {key: {score, rationale}}, gap_roadmap_en:
  -- [{priority, action}], financing_recommendations_en: [{mechanism,
  -- rationale}]). Written by /api/analyze-project.js in the same request
  -- as the Spanish version for any NEW AI Analysis run after
  -- migration_v40; backfilled by hand for analyses loaded before it. Null
  -- means "no English version yet" — the UI falls back to Spanish, it
  -- never shows a blank/broken field.
  dimensions_en jsonb,
  gap_roadmap_en jsonb,
  financing_recommendations_en jsonb,
  summary_en text,
  raw_model_output text,
  source text not null default 'ai' check (source in ('ai', 'manual')),
  created_at timestamptz not null default now()
);

alter table public.framework_analysis enable row level security;

create policy "analysis_select_own_or_advisor" on public.framework_analysis
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

-- The AI path has no insert/update policy for anon/authenticated: only the
-- service role key (used server-side in the Vercel function, which
-- bypasses RLS) writes those rows. This policy only opens the door for
-- self-assessment rows, and only when correctly attributed to the caller
-- and explicitly tagged 'manual' — a client can't use it to fake an
-- 'ai'-sourced result.
create policy "analysis_insert_own_manual" on public.framework_analysis
  for insert with check (auth.uid() = user_id and source = 'manual');

create index if not exists framework_analysis_project_id_idx on public.framework_analysis(project_id);

-- ---------- fsu_scoring ----------
-- One row per project — the 100-point selection-scoring matrix from
-- ENACOM's "Manual Estratégico de Elaboración de Proyectos: Obtención del
-- Certificado de Elegibilidad ENACOM" (Resolución 359/2025), used to rank
-- projects applying to the Fondo de Servicio Universal (FSU). This is a
-- separate, deterministic, ENACOM-specific formula — distinct from
-- framework_analysis (INA's own Investment Readiness Index™) — covering 7
-- named criteria that sum to 100 points. The criteria (GPON/XGS-PON
-- technology, splitter/fiber-penetration math) are specific to
-- fiber-to-the-home / last-mile builds, so app/fsu-scoring.html only
-- offers this for projects with project_type = 'fiber_backbone_last_mile'.
-- Scores are computed client-side (assets/platform.js computeFsuScore(),
-- mirroring the manual's published point table exactly) and written here
-- alongside the raw inputs, the same pattern framework_analysis's manual
-- source uses.
create table if not exists public.fsu_scoring (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,

  -- Raw inputs (project owner enters these in app/fsu-scoring.html) ------
  total_hogares integer check (total_hogares is null or total_hogares >= 0),
  accesos_fibra integer check (accesos_fibra is null or accesos_fibra >= 0),
  modelo_negocio text check (modelo_negocio in ('mayorista_neutral', 'minorista_exclusiva')),
  tecnologia text check (tecnologia in ('xgs_pon', 'gpon')),
  velocidad_actual_mbps numeric check (velocidad_actual_mbps is null or velocidad_actual_mbps >= 0),
  velocidad_propuesta_mbps numeric check (velocidad_propuesta_mbps is null or velocidad_propuesta_mbps >= 0),
  salto_tecnologico text check (salto_tecnologico in ('area_blanca', 'migracion_cobre_wireless')),
  poblacion_localidad integer check (poblacion_localidad is null or poblacion_localidad >= 0),
  anos_capacidad_tecnica text check (anos_capacidad_tecnica in ('mas_5', 'entre_2_y_5', 'menos_2')),

  -- Computed breakdown, 0 to each criterion's max (recomputed and
  -- overwritten by computeFsuScore() on every save, never hand-edited) --
  score_penetracion int not null default 0,
  score_modelo_negocio int not null default 0,
  score_tecnologia int not null default 0,
  score_velocidad int not null default 0,
  score_salto_tecnologico int not null default 0,
  score_densidad int not null default 0,
  score_capacidad_tecnica int not null default 0,
  score_total int not null default 0,
  penetracion_pct numeric,
  mejora_velocidad_pct numeric,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- One scoring record per project — re-saving updates it in place rather
  -- than accumulating a history (the manual's formula is deterministic, so
  -- there's no value in keeping old computations around like there is for
  -- framework_analysis's AI re-runs).
  unique (project_id)
);

alter table public.fsu_scoring enable row level security;

-- Same visibility pattern as framework_analysis/projects: owner or advisor.
create policy "fsu_scoring_select_own_or_advisor" on public.fsu_scoring
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

-- Owner, OR the advisor who has taken the parent project — see
-- supabase/migration_v19_advisor_edit_taken_project.sql. fsu_scoring's own
-- user_id column just records whoever last saved it (may not be the
-- project's assigned_advisor_id), so these check the parent projects row
-- instead of/in addition to it.
create policy "fsu_scoring_insert_own_or_assigned_advisor" on public.fsu_scoring
  for insert with check (
    auth.uid() = user_id
    or exists (
      select 1 from public.projects pr
      where pr.id = fsu_scoring.project_id and pr.assigned_advisor_id = auth.uid()
    )
  );

create policy "fsu_scoring_update_own_or_assigned_advisor" on public.fsu_scoring
  for update using (
    auth.uid() = user_id
    or exists (
      select 1 from public.projects pr
      where pr.id = fsu_scoring.project_id and pr.assigned_advisor_id = auth.uid()
    )
  );

create index if not exists fsu_scoring_project_id_idx on public.fsu_scoring(project_id);

-- ---------- financing_recommendations ----------
-- One row per project (unique constraint — re-running overwrites in place,
-- same convention as fsu_scoring above, not an append-only history like
-- framework_analysis): the AI-picked best COMBINATION of financing
-- instruments/Programs already registered on the platform (BID, DFC, FSU/
-- TASU/FATIC/CIP/USTDA/Capital Markets/etc. — the full public.programs
-- catalog) for this specific project, given its type, budget, country and
-- stage. See supabase/migration_v55_financing_recommendations.sql for the
-- full design rationale and api/recommend-financing.js for how it's
-- populated.
create table if not exists public.financing_recommendations (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  recommended jsonb not null default '[]'::jsonb,
  recommended_en jsonb not null default '[]'::jsonb,
  summary text,
  summary_en text,
  raw_model_output text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (project_id)
);

alter table public.financing_recommendations enable row level security;

-- Entirely AI-generated (no manual variant) — same "AI path has no insert/
-- update policy for anon/authenticated" convention as framework_analysis
-- above: only the service role (api/recommend-financing.js) writes these
-- rows, enforcing its own owner/assigned-advisor/admin check server-side.
create policy "financing_recommendations_select_own_or_advisor" on public.financing_recommendations
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

create index if not exists financing_recommendations_project_id_idx on public.financing_recommendations(project_id);

-- ---------- project_workflow_events ----------
-- Append-only audit trail of project stage transitions (see the comment on
-- projects.assigned_advisor_id above, and supabase/migration_v12_workflow.sql
-- for the full rationale). Reuses the same 4 Investment Readiness Index™
-- stages as projects.readiness_stage as the workflow's states — an advisor
-- viewing a project can manually push it one stage forward when they judge
-- the engagement ready to move on, independent of (and not overwritten by)
-- whatever a separate AI/manual framework analysis concludes.
create table if not exists public.project_workflow_events (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  from_stage text,
  -- 'Not Analyzed' added by migration_v20_workflow_promote_demote.sql, for
  -- return_project_to_not_analyzed()'s transitions. Nullable since
  -- migration_v39_project_gates.sql — this table now logs two kinds of
  -- event: a readiness_stage transition (to_stage set, gate_number null)
  -- or a Project Structuring Framework™ gate approval (gate_number set,
  -- to_stage null) — see project_workflow_events_kind_check below.
  to_stage text check (to_stage is null or to_stage in (
    'Not Analyzed', 'Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'
  )),
  advisor_id uuid references public.profiles(id) on delete set null,
  note text,
  -- Gate (1 to 4) approved in this event — see migration_v39_project_gates.sql
  -- and approve_project_gate() below. Exactly one of gate_number/to_stage is
  -- non-null per row (project_workflow_events_kind_check).
  gate_number int check (gate_number is null or gate_number between 1 and 4),
  -- Deliverables the advisor marked complete when approving this gate
  -- (free text, e.g. "Business Case", "Modelo Financiero a 5 años"). Empty
  -- on readiness_stage transition rows. See migration_v39_project_gates.sql.
  deliverables_checked text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  constraint project_workflow_events_kind_check check (
    (to_stage is not null and gate_number is null)
    or (to_stage is null and gate_number is not null)
  )
);

alter table public.project_workflow_events enable row level security;

-- Same visibility as the project itself: its owner, or any advisor/admin.
-- No insert/update policy for regular clients on purpose — every row is
-- written by promote_project_workflow()/demote_project_workflow()/
-- return_project_to_not_analyzed() below, never a direct client insert, so
-- a client can't fabricate a fake transition history.
create policy "workflow_events_select_own_or_advisor" on public.project_workflow_events
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = project_workflow_events.project_id and pr.user_id = auth.uid()
    )
  );

create index if not exists project_workflow_events_project_id_idx on public.project_workflow_events(project_id);

-- Claims a project for the calling advisor. Unrestricted for now: any
-- advisor/admin can take (or re-take, from someone else) any project —
-- matches "por el momento el advisor puede hacer todo."
create or replace function public.take_project(p_project_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can take a project.';
  end if;

  update public.projects
  set assigned_advisor_id = auth.uid(), updated_at = now()
  where id = p_project_id;

  if not found then
    raise exception 'Project not found.';
  end if;
end;
$$;

-- Workflow state machine (see migration_v20_workflow_promote_demote.sql
-- for the full rationale):
--   Not Analyzed (readiness_stage null) → owner's self-assessment moves it
--   to Concept Stage → advisor can promote forward, demote backward
--   (mandatory comment on both), or (Concept Stage only) send it back to
--   Not Analyzed → ... → Investment Ready (terminal, no promote/demote).

-- Pushes a project exactly one stage forward (Concept Stage → Early
-- Structuring → Advanced Structuring → Investment Ready), claims it for
-- the calling advisor, and logs the transition. `p_note` is mandatory.
-- Throws if readiness_stage is still null (must self-assess first) or
-- already at the final stage.
create or replace function public.promote_project_workflow(p_project_id uuid, p_note text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_current text;
  v_next text;
  v_stage_order text[] := array['Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'];
  v_idx int;
  v_found boolean;
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can promote a project''s workflow stage.';
  end if;

  if p_note is null or trim(p_note) = '' then
    raise exception 'A comment explaining the promotion is required.';
  end if;

  select true, readiness_stage into v_found, v_current
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  if v_current is null then
    raise exception 'This project hasn''t completed the owner''s self-assessment yet — it can''t be promoted from Not Analyzed directly.';
  end if;

  v_idx := array_position(v_stage_order, v_current);
  if v_idx is null or v_idx = array_length(v_stage_order, 1) then
    raise exception 'Project is already at the final stage.';
  end if;

  v_next := v_stage_order[v_idx + 1];

  update public.projects
  set readiness_stage = v_next, assigned_advisor_id = auth.uid(), updated_at = now()
  where id = p_project_id;

  insert into public.project_workflow_events (project_id, from_stage, to_stage, advisor_id, note)
  values (p_project_id, v_current, v_next, auth.uid(), trim(p_note));

  return v_next;
end;
$$;

-- Mirror of promote_project_workflow, one stage backward. Throws if
-- readiness_stage is null, 'Concept Stage' (use
-- return_project_to_not_analyzed instead), or 'Investment Ready'
-- (terminal — no demote per spec). `p_note` is mandatory.
create or replace function public.demote_project_workflow(p_project_id uuid, p_note text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_current text;
  v_prev text;
  v_stage_order text[] := array['Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'];
  v_idx int;
  v_found boolean;
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can demote a project''s workflow stage.';
  end if;

  if p_note is null or trim(p_note) = '' then
    raise exception 'A comment explaining the demotion is required.';
  end if;

  select true, readiness_stage into v_found, v_current
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  if v_current is null then
    raise exception 'Project is already at Not Analyzed.';
  end if;

  if v_current = 'Concept Stage' then
    raise exception 'Use return_project_to_not_analyzed() to send a Concept Stage project back to the owner.';
  end if;

  if v_current = 'Investment Ready' then
    raise exception 'A project at the final stage can''t be demoted.';
  end if;

  v_idx := array_position(v_stage_order, v_current);
  if v_idx is null or v_idx = 1 then
    raise exception 'Project is already at the earliest stage.';
  end if;

  v_prev := v_stage_order[v_idx - 1];

  update public.projects
  set readiness_stage = v_prev, assigned_advisor_id = auth.uid(), updated_at = now()
  where id = p_project_id;

  insert into public.project_workflow_events (project_id, from_stage, to_stage, advisor_id, note)
  values (p_project_id, v_current, v_prev, auth.uid(), trim(p_note));

  return v_prev;
end;
$$;

-- Sends a Concept Stage project all the way back to Not Analyzed and
-- un-claims it (assigned_advisor_id → null) — back in the owner's hands to
-- redo the self-assessment. Only callable from Concept Stage exactly.
-- `p_note` is mandatory (the reason shown to the owner).
create or replace function public.return_project_to_not_analyzed(p_project_id uuid, p_note text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_current text;
  v_found boolean;
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can return a project to Not Analyzed.';
  end if;

  if p_note is null or trim(p_note) = '' then
    raise exception 'A comment explaining the decision is required.';
  end if;

  select true, readiness_stage into v_found, v_current
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  if v_current is distinct from 'Concept Stage' then
    raise exception 'Only a project in Concept Stage can be returned to Not Analyzed.';
  end if;

  update public.projects
  set readiness_stage = null, status = 'submitted', assigned_advisor_id = null, updated_at = now()
  where id = p_project_id;

  insert into public.project_workflow_events (project_id, from_stage, to_stage, advisor_id, note)
  values (p_project_id, v_current, 'Not Analyzed', auth.uid(), trim(p_note));

  return 'Not Analyzed';
end;
$$;

-- Approves the next Gate in order (current_gate + 1) of the Project
-- Structuring Framework™ (F1) for a project — distinct from the
-- readiness_stage (F2) promote/demote functions above. See
-- migration_v39_project_gates.sql. `p_note` is mandatory, same convention
-- as promote/demote_project_workflow(). `p_deliverables_checked` is
-- optional (default empty array).
create or replace function public.approve_project_gate(
  p_project_id uuid,
  p_gate_number int,
  p_note text,
  p_deliverables_checked text[] default '{}'::text[]
)
returns int
language plpgsql
security definer set search_path = public
as $$
declare
  v_current_gate int;
  v_found boolean;
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can approve a project gate.';
  end if;

  if p_note is null or trim(p_note) = '' then
    raise exception 'A comment explaining the gate approval is required.';
  end if;

  if p_gate_number is null or p_gate_number not between 1 and 4 then
    raise exception 'gate_number must be between 1 and 4.';
  end if;

  select true, current_gate into v_found, v_current_gate
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  if v_current_gate = 4 then
    raise exception 'This project has already completed all 4 gates.';
  end if;

  if p_gate_number <> v_current_gate + 1 then
    raise exception 'Gates must be approved in order — this project is at gate %, expected gate % next.',
      v_current_gate, v_current_gate + 1;
  end if;

  update public.projects
  set current_gate = p_gate_number, assigned_advisor_id = auth.uid(), updated_at = now()
  where id = p_project_id;

  insert into public.project_workflow_events (
    project_id, from_stage, to_stage, advisor_id, note, gate_number, deliverables_checked
  )
  values (
    p_project_id, null, null, auth.uid(), trim(p_note), p_gate_number,
    coalesce(p_deliverables_checked, '{}'::text[])
  );

  return p_gate_number;
end;
$$;

-- ---------- roadmap_templates / roadmap_template_steps / project_roadmaps ----------
-- "Roadmaps" checklist system (named "Gestiones" before migration_v30_
-- rename_gestion_to_roadmap.sql — see that file for the rename itself) —
-- see supabase/migration_v26_gestion_templates.sql for the full original
-- rationale and RLS design notes. Regulator-facing: a roadmap_template is a
-- reusable, named checklist of administrative/regulatory procedures (each
-- step naming a public and/or private entity involved), optionally scoped
-- to a project_type; project_roadmaps is the actual per-project instance,
-- populated by copying a template's steps (INAPlatform.
-- instantiateRoadmapsFromTemplate() in assets/platform.js) and/or adding
-- ad-hoc steps directly.
create table if not exists public.roadmap_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  project_type text,
  name text not null,
  description text,
  -- Optional restriction on which kind of entity may carry out this whole
  -- checklist (e.g. "Alerta Temprana" restricted to 'regulator') — see
  -- migration_v27_gestion_instances.sql. Null = any entity type.
  allowed_entity_type text check (allowed_entity_type is null or allowed_entity_type in (
    'regulator', 'national_gov', 'provincial_gov', 'municipal_gov', 'isp', 'manufacturer', 'integrator', 'other'
  )),
  -- Edit-mode concurrency lock — see migration_v31_edit_locks.sql and
  -- acquire_roadmap_template_edit_lock()/release_roadmap_template_edit_lock()
  -- below.
  edit_locked_by uuid references public.profiles(id) on delete set null,
  edit_locked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.roadmap_templates enable row level security;

create policy "roadmap_templates_select_advisor_or_admin" on public.roadmap_templates
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
  );
create policy "roadmap_templates_insert_advisor_or_admin" on public.roadmap_templates
  for insert with check (
    auth.uid() = user_id
    and (public.is_advisor() or public.is_admin()
         or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null))
  );
create policy "roadmap_templates_update_advisor_or_admin" on public.roadmap_templates
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_templates_delete_advisor_or_admin" on public.roadmap_templates
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists roadmap_templates_project_type_idx on public.roadmap_templates(project_type);

create table if not exists public.roadmap_template_steps (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.roadmap_templates(id) on delete cascade,
  step_order integer not null default 0,
  title text not null,
  description text,
  -- The one entity RESPONSIBLE for carrying out this step. See
  -- involved_entities below for the (possibly several) other entities that
  -- participate in it — see migration_v29_gestion_step_entities.sql.
  entity_name text,
  entity_type text not null default 'public' check (entity_type in ('public', 'private', 'mixed')),
  required boolean not null default true,
  -- What "done" looks like for this step — shown by the sequential
  -- roadmap_instances tracker (see migration_v27_gestion_instances.sql)
  -- when the user is deciding whether to advance past it.
  expected_result text,
  -- Free-form names of the OTHER entities that participate in this step,
  -- besides the one responsible for it (entity_name above) — e.g. a
  -- spectrum-authorization step might be the applicant's responsibility but
  -- involve the regulator, a mobile operator, and civil protection all at
  -- once. See migration_v29_gestion_step_entities.sql.
  involved_entities text[] not null default '{}'::text[],
  created_at timestamptz not null default now()
);

alter table public.roadmap_template_steps enable row level security;

create policy "roadmap_template_steps_select_advisor_or_admin" on public.roadmap_template_steps
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
  );
create policy "roadmap_template_steps_insert_advisor_or_admin" on public.roadmap_template_steps
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_template_steps_update_advisor_or_admin" on public.roadmap_template_steps
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_template_steps_delete_advisor_or_admin" on public.roadmap_template_steps
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists roadmap_template_steps_template_id_idx on public.roadmap_template_steps(template_id);

-- ---------- roadmap_step_raci (RACI per template step) ----------
-- See migration_v42_roadmap_raci.sql. entity_name/entity_type/
-- involved_entities on roadmap_template_steps above are kept as a derived
-- backward-compatibility summary (entity_name = entities with role
-- 'responsible', involved_entities = the rest) — this table is the source
-- of truth for the full R/A/C/I breakdown going forward.
create table if not exists public.roadmap_step_raci (
  id uuid primary key default gen_random_uuid(),
  template_step_id uuid not null references public.roadmap_template_steps(id) on delete cascade,
  entity_name text not null,
  role text not null check (role in ('responsible', 'accountable', 'consulted', 'informed')),
  created_at timestamptz not null default now(),
  unique (template_step_id, entity_name)
);

alter table public.roadmap_step_raci enable row level security;

create policy "roadmap_step_raci_select_advisor_or_admin" on public.roadmap_step_raci
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
  );
create policy "roadmap_step_raci_insert_advisor_or_admin" on public.roadmap_step_raci
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_step_raci_update_advisor_or_admin" on public.roadmap_step_raci
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_step_raci_delete_advisor_or_admin" on public.roadmap_step_raci
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists roadmap_step_raci_template_step_id_idx on public.roadmap_step_raci(template_step_id);

create table if not exists public.project_roadmaps (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  template_step_id uuid references public.roadmap_template_steps(id) on delete set null,
  step_order integer not null default 0,
  title text not null,
  description text,
  entity_name text,
  entity_type text not null default 'public' check (entity_type in ('public', 'private', 'mixed')),
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed', 'blocked')),
  responsible_name text,
  responsible_contact text,
  due_date date,
  completed_date date,
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.project_roadmaps enable row level security;

-- Same visibility as project_workflow_events above: the project's owner
-- (read-only — no owner insert/update/delete policy on purpose), or any
-- advisor/admin.
create policy "project_roadmaps_select_own_or_advisor" on public.project_roadmaps
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
    or exists (
      select 1 from public.projects pr
      where pr.id = project_roadmaps.project_id and pr.user_id = auth.uid()
    )
  );
create policy "project_roadmaps_insert_advisor_or_admin" on public.project_roadmaps
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "project_roadmaps_update_advisor_or_admin" on public.project_roadmaps
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "project_roadmaps_delete_advisor_or_admin" on public.project_roadmaps
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists project_roadmaps_project_id_idx on public.project_roadmaps(project_id);
create index if not exists project_roadmaps_template_step_id_idx on public.project_roadmaps(template_step_id);

-- ---------- roadmap_instances / roadmap_instance_steps ----------
-- Replaces project_roadmaps as the per-project tracking UI (the table
-- above is left in place, unused, in case it already held data) — see
-- migration_v27_gestion_instances.sql for the full rationale. Where
-- project_roadmaps was a flat, freely-editable checklist, a
-- roadmap_instance is a single named, sequential workflow: one run of a
-- roadmap_template against a specific project AND a specific performing
-- entity (which may not be the project's owner). Its steps are copied
-- from the template at creation time; current_step_index points at the
-- active step, and the user explicitly decides whether to advance past it
-- (INAPlatform.advanceRoadmapInstanceStep()) or not.
create table if not exists public.roadmap_instances (
  id uuid primary key default gen_random_uuid(),
  -- Nullable — a Roadmap is often started BEFORE the project it concerns
  -- even exists (see migration_v28_gestion_instance_optional_project.sql)
  -- and can be optionally linked to one later. RLS falls through to
  -- "advisor/admin only" for a project-less Roadmap, same as any Roadmap
  -- whose linked project the viewer doesn't own.
  project_id uuid references public.projects(id) on delete cascade,
  template_id uuid references public.roadmap_templates(id) on delete set null,
  name text not null,
  performing_entity_name text not null,
  performing_entity_type text not null check (performing_entity_type in (
    'regulator', 'national_gov', 'provincial_gov', 'municipal_gov', 'isp', 'manufacturer', 'integrator', 'other'
  )),
  current_step_index integer not null default 0,
  status text not null default 'in_progress' check (status in ('in_progress', 'completed', 'abandoned')),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.roadmap_instances enable row level security;

create policy "roadmap_instances_select_own_or_advisor" on public.roadmap_instances
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'view', null)
    or exists (
      select 1 from public.projects pr
      where pr.id = roadmap_instances.project_id and pr.user_id = auth.uid()
    )
  );
create policy "roadmap_instances_insert_advisor_or_admin" on public.roadmap_instances
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_instances_update_advisor_or_admin" on public.roadmap_instances
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_instances_delete_advisor_or_admin" on public.roadmap_instances
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists roadmap_instances_project_id_idx on public.roadmap_instances(project_id);
create index if not exists roadmap_instances_template_id_idx on public.roadmap_instances(template_id);

create table if not exists public.roadmap_instance_steps (
  id uuid primary key default gen_random_uuid(),
  instance_id uuid not null references public.roadmap_instances(id) on delete cascade,
  template_step_id uuid references public.roadmap_template_steps(id) on delete set null,
  step_order integer not null default 0,
  title text not null,
  description text,
  expected_result text,
  -- Same meaning as roadmap_template_steps.entity_name/entity_type/
  -- involved_entities (responsible entity + other participating entities)
  -- — copied verbatim at instance creation. See
  -- migration_v29_gestion_step_entities.sql.
  entity_name text,
  entity_type text not null default 'public' check (entity_type in ('public', 'private', 'mixed')),
  involved_entities text[] not null default '{}'::text[],
  required boolean not null default true,
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed', 'skipped', 'blocked')),
  decision_note text,
  completed_at timestamptz,
  completed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.roadmap_instance_steps enable row level security;

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
create policy "roadmap_instance_steps_insert_advisor_or_admin" on public.roadmap_instance_steps
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_instance_steps_update_advisor_or_admin" on public.roadmap_instance_steps
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_instance_steps_delete_advisor_or_admin" on public.roadmap_instance_steps
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists roadmap_instance_steps_instance_id_idx on public.roadmap_instance_steps(instance_id);
create index if not exists roadmap_instance_steps_template_step_id_idx on public.roadmap_instance_steps(template_step_id);

-- ---------- roadmap_instance_step_raci (RACI per instance step) ----------
-- See migration_v42_roadmap_raci.sql. Copied from roadmap_step_raci at
-- instance-creation time, then independently editable — same soft-copy
-- pattern as roadmap_instance_steps itself.
create table if not exists public.roadmap_instance_step_raci (
  id uuid primary key default gen_random_uuid(),
  instance_step_id uuid not null references public.roadmap_instance_steps(id) on delete cascade,
  entity_name text not null,
  role text not null check (role in ('responsible', 'accountable', 'consulted', 'informed')),
  created_at timestamptz not null default now(),
  unique (instance_step_id, entity_name)
);

alter table public.roadmap_instance_step_raci enable row level security;

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
create policy "roadmap_instance_step_raci_insert_advisor_or_admin" on public.roadmap_instance_step_raci
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_instance_step_raci_update_advisor_or_admin" on public.roadmap_instance_step_raci
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'roadmaps', 'edit', null)
  );
create policy "roadmap_instance_step_raci_delete_advisor_or_admin" on public.roadmap_instance_step_raci
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists roadmap_instance_step_raci_instance_step_id_idx on public.roadmap_instance_step_raci(instance_step_id);

-- ---------- project_risks (Matriz de Riesgos) ----------
-- See migration_v41_project_risks.sql for the full rationale. A structured
-- risk register per project, distinct from the freeform text in
-- framework_analysis.dimensions.risk_mitigation.rationale. Only
-- advisor/admin can write; the project owner has read-only visibility on
-- their own project's risks.
create table if not exists public.project_risks (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  description text,
  category text not null default 'other' check (category in (
    'legal_regulatory', 'technical', 'financial', 'market_demand',
    'environmental_social', 'governance', 'operational', 'political', 'other'
  )),
  probability int not null check (probability between 1 and 5),
  impact int not null check (impact between 1 and 5),
  -- 1 to 25. Severity band (low/medium/high/critical) computed client-side
  -- — riskScoreBand() in assets/platform.js.
  risk_score int generated always as (probability * impact) stored,
  mitigation_measures text,
  owner_entity_name text,
  status text not null default 'open' check (status in (
    'open', 'mitigating', 'monitoring', 'closed'
  )),
  identified_date date not null default current_date,
  target_resolution_date date,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.project_risks enable row level security;

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
create policy "project_risks_insert_advisor_or_admin" on public.project_risks
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'risks', 'edit', null)
  );
create policy "project_risks_update_advisor_or_admin" on public.project_risks
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'risks', 'edit', null)
  );
create policy "project_risks_delete_advisor_or_admin" on public.project_risks
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists project_risks_project_id_idx on public.project_risks(project_id);
create index if not exists project_risks_status_idx on public.project_risks(status);

-- ---------- Master Data: companies, public_agencies, contacts, products ----------
-- See migration_v44_master_data.sql for the full rationale. A standalone
-- internal directory (advisor/admin only, same access pattern as
-- roadmap_templates below) — NOT yet wired into programs.financing_entity,
-- projects.organization or profiles.organization, which remain free text.
create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  -- Deprecated as of migration_v52 — read-only legacy data now, kept only
  -- for history. Multi-tag on purpose at the time — a company could be
  -- e.g. both a financial_entity and a service_provider at once. Superseded
  -- by the single-select `industry` column below.
  types text[] not null default '{}' check (types <@ array[
    'manufacturer',
    'service_provider',
    'financial_entity',
    'technology',
    'telecommunications',
    'consulting',
    'infrastructure_construction',
    'energy',
    'investor_fund'
  ]::text[]),
  -- Single-select industry classification (migration_v52), replacing the
  -- `types` checkbox model above in the UI. Pablo supplied a ~22-item
  -- sector list (KYC/sanctions-screening style) merged with the original 9
  -- `types` values; see assets/platform.js's COMPANY_INDUSTRIES for the
  -- full list and the note on the one de-duplicated entry
  -- ("Telecommunications", which appeared identically in both lists).
  -- Alphabetized by English label (migration_v53); 'government_non_military'
  -- ("Sector público") was removed in that same migration.
  industry text check (industry is null or industry in (
    'aerospace',
    'banking_finance_insurance',
    'broadcasting_entertainment',
    'chemicals_petrochemicals',
    'colocation_hosting_cloud',
    'construction_engineering',
    'consulting',
    'education',
    'energy',
    'financial_entity',
    'fire_alarms_security',
    'healthcare_non_pharma',
    'infrastructure_construction',
    'investor_fund',
    'manufacturer',
    'manufacturing',
    'maritime',
    'military_defense',
    'mining_metals',
    'nuclear_energy',
    'oil_gas_non_petrochemical',
    'power_gas_transmission_distribution',
    'power_generation_non_nuclear',
    'professional_services',
    'retail_wholesale',
    'service_provider',
    'technology',
    'telecommunications',
    'transportation',
    'other'
  )),
  country text,
  website text,
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.companies enable row level security;

create policy "companies_select_advisor_or_admin" on public.companies
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'view', null)
  );
create policy "companies_insert_advisor_or_admin" on public.companies
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
create policy "companies_update_advisor_or_admin" on public.companies
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
create policy "companies_delete_advisor_or_admin" on public.companies
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists companies_name_idx on public.companies(name);

create table if not exists public.public_agencies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  jurisdiction text not null default 'national' check (jurisdiction in (
    'national', 'provincial', 'municipal', 'international'
  )),
  country text not null default 'Argentina',
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.public_agencies enable row level security;

create policy "public_agencies_select_advisor_or_admin" on public.public_agencies
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'view', null)
  );
create policy "public_agencies_insert_advisor_or_admin" on public.public_agencies
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
create policy "public_agencies_update_advisor_or_admin" on public.public_agencies
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
create policy "public_agencies_delete_advisor_or_admin" on public.public_agencies
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists public_agencies_name_idx on public.public_agencies(name);

-- A contact's current position lives directly on the row (position_title +
-- company_id/public_agency_id) rather than a history table — Pablo's
-- explicit choice: only the current affiliation matters, editing the same
-- row is fine if a contact changes jobs.
create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text,
  phone text,
  position_title text,
  company_id uuid references public.companies(id) on delete set null,
  public_agency_id uuid references public.public_agencies(id) on delete set null,
  notes text,
  -- Storage path (bucket project-documents, prefix master-data/contacts/)
  -- of the uploaded business card image, if this contact was created (or
  -- later had one attached) via the "Upload from business card" flow — see
  -- migration_v45_contact_business_card.sql. Null for contacts entered by
  -- hand with no card attached.
  business_card_path text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- A contact's current position is at a Company OR a Public Agency,
  -- never both at once (may also have neither yet).
  constraint contacts_single_affiliation check (
    company_id is null or public_agency_id is null
  )
);

alter table public.contacts enable row level security;

create policy "contacts_select_advisor_or_admin" on public.contacts
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'view', null)
  );
create policy "contacts_insert_advisor_or_admin" on public.contacts
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
create policy "contacts_update_advisor_or_admin" on public.contacts
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
create policy "contacts_delete_advisor_or_admin" on public.contacts
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists contacts_full_name_idx on public.contacts(full_name);
create index if not exists contacts_company_id_idx on public.contacts(company_id);
create index if not exists contacts_public_agency_id_idx on public.contacts(public_agency_id);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  -- The manufacturer/provider company. Optional — a product can be
  -- entered without pinning it to a specific Company yet.
  company_id uuid references public.companies(id) on delete set null,
  category text,
  description text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products enable row level security;

create policy "products_select_advisor_or_admin" on public.products
  for select using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'view', null)
  );
create policy "products_insert_advisor_or_admin" on public.products
  for insert with check (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
create policy "products_update_advisor_or_admin" on public.products
  for update using (
    public.is_advisor() or public.is_admin()
    or public.has_entity_access(auth.uid(), 'master_data', 'edit', null)
  );
create policy "products_delete_advisor_or_admin" on public.products
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists products_name_idx on public.products(name);
create index if not exists products_company_id_idx on public.products(company_id);

-- ---------- Casos de Éxito (Success Cases) — see migration_v59 ----------
-- A shared reference library (visible to everyone, managed by
-- advisor/admin — same shape as Financing Programs) that a new or existing
-- project can cite as precedent/inspiration via project_success_cases.
-- "provider" is free text on purpose: seeded from Starlink LATAM case
-- studies, but built to hold any technology/vendor's success cases.
create table if not exists public.success_cases (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  -- Optional English title, same fallback convention as programs.name_en
  -- — see INAPlatform.successCaseDisplayTitle() in assets/platform.js and
  -- migration_v60_bilingual_title_description.sql.
  title_en text,
  provider text not null default 'Starlink',
  country text not null,
  region text,
  sector text not null check (sector in (
    'education', 'health', 'emergency_response', 'agriculture',
    'government', 'financial_inclusion', 'other'
  )),
  summary_es text not null,
  summary_en text,
  beneficiaries_count integer,
  metrics_es text,
  metrics_en text,
  source_label text,
  source_url text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.success_cases enable row level security;

create policy "success_cases_select_all_authenticated" on public.success_cases
  for select using (auth.uid() is not null);
create policy "success_cases_insert_advisor_or_admin" on public.success_cases
  for insert with check (
    auth.uid() = created_by and (public.is_advisor() or public.is_admin())
  );
create policy "success_cases_update_advisor_or_admin" on public.success_cases
  for update using (public.is_advisor() or public.is_admin());
create policy "success_cases_delete_advisor_or_admin" on public.success_cases
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists success_cases_sector_idx on public.success_cases(sector);
create index if not exists success_cases_country_idx on public.success_cases(country);

create table if not exists public.project_success_cases (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  success_case_id uuid not null references public.success_cases(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  note text,
  linked_at timestamptz not null default now(),
  unique (project_id, success_case_id)
);

alter table public.project_success_cases enable row level security;

create policy "project_success_cases_select_own_or_advisor" on public.project_success_cases
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = project_success_cases.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );
create policy "project_success_cases_insert_own_or_assigned_advisor" on public.project_success_cases
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.projects pr
      where pr.id = project_success_cases.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );
create policy "project_success_cases_delete_own_or_assigned_advisor" on public.project_success_cases
  for delete using (
    exists (
      select 1 from public.projects pr
      where pr.id = project_success_cases.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

create index if not exists project_success_cases_project_id_idx on public.project_success_cases(project_id);
create index if not exists project_success_cases_success_case_id_idx on public.project_success_cases(success_case_id);

-- ============================================================================
-- Storage bucket for uploaded project documents.
-- Run once: Dashboard → Storage → Create bucket → name it "project-documents"
-- → set Public: OFF. Then run the policies below (Dashboard → Storage →
-- project-documents → Policies, or just run this SQL — Supabase exposes
-- storage.objects as a regular table you can add RLS policies to).
-- ============================================================================

create policy "doc_upload_own_folder" on storage.objects
  for insert with check (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "doc_read_own_folder_or_advisor" on storage.objects
  for select using (
    bucket_id = 'project-documents'
    and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.is_advisor()
    )
  );

-- Owner-only — see supabase/migration_v16_document_delete.sql. Lets a
-- project/program owner delete (or delete-then-reupload to "replace") one
-- of their own attachments from new-project.html / new-program.html.
create policy "doc_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Expected storage path convention used by assets/platform.js:
--   {user_id}/{project_id}/{filename}
-- This is what makes the "own folder" policies above work correctly.

-- ---------- Master Data business cards — see migration_v45 ----------
-- Reuses the same "project-documents" bucket under a "master-data/" prefix
-- (same convention as programs/ for program_documents below) instead of a
-- new bucket. Gated to advisor/admin (Master Data has no "owner" concept,
-- so the "own folder" policies above don't apply to this prefix).
create policy "master_data_upload_advisor_or_admin" on storage.objects
  for insert with check (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = 'master-data'
    and (public.is_advisor() or public.is_admin()
         or public.has_entity_access(auth.uid(), 'master_data', 'edit', null))
  );

create policy "master_data_read_advisor_or_admin" on storage.objects
  for select using (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = 'master-data'
    and (public.is_advisor() or public.is_admin()
         or public.has_entity_access(auth.uid(), 'master_data', 'view', null))
  );

create policy "master_data_delete_advisor_or_admin" on storage.objects
  for delete using (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = 'master-data'
    and (public.is_advisor() or public.is_admin())
  );

-- Path convention used by assets/platform.js for this prefix:
--   master-data/contacts/{contact_id}/{timestamp}_{filename}

-- ============================================================================
-- Edit locks (concurrent-edit prevention) — see migration_v31_edit_locks.sql
-- for the full rationale. Hard lock, no manual force-unlock: a second user
-- can't enter edit mode on a project/program/roadmap_template while someone
-- else holds the lock, but it auto-expires after 5 minutes without a
-- heartbeat renewal so nobody gets stuck.
-- ============================================================================

create or replace function public.acquire_project_edit_lock(p_project_id uuid)
returns table (acquired boolean, locked_by uuid, locked_by_name text, locked_at timestamptz)
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.projects
  set edit_locked_by = auth.uid(), edit_locked_at = now()
  where id = p_project_id
    and (
      edit_locked_by is null
      or edit_locked_by = auth.uid()
      or edit_locked_at < now() - interval '5 minutes'
    );

  return query
    select
      (p.edit_locked_by = auth.uid()) as acquired,
      p.edit_locked_by as locked_by,
      pr.full_name as locked_by_name,
      p.edit_locked_at as locked_at
    from public.projects p
    left join public.profiles pr on pr.id = p.edit_locked_by
    where p.id = p_project_id;
end;
$$;

create or replace function public.release_project_edit_lock(p_project_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.projects
  set edit_locked_by = null, edit_locked_at = null
  where id = p_project_id and edit_locked_by = auth.uid();
end;
$$;

create or replace function public.acquire_program_edit_lock(p_program_id uuid)
returns table (acquired boolean, locked_by uuid, locked_by_name text, locked_at timestamptz)
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.programs
  set edit_locked_by = auth.uid(), edit_locked_at = now()
  where id = p_program_id
    and (
      edit_locked_by is null
      or edit_locked_by = auth.uid()
      or edit_locked_at < now() - interval '5 minutes'
    );

  return query
    select
      (p.edit_locked_by = auth.uid()) as acquired,
      p.edit_locked_by as locked_by,
      pr.full_name as locked_by_name,
      p.edit_locked_at as locked_at
    from public.programs p
    left join public.profiles pr on pr.id = p.edit_locked_by
    where p.id = p_program_id;
end;
$$;

create or replace function public.release_program_edit_lock(p_program_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.programs
  set edit_locked_by = null, edit_locked_at = null
  where id = p_program_id and edit_locked_by = auth.uid();
end;
$$;

create or replace function public.acquire_roadmap_template_edit_lock(p_template_id uuid)
returns table (acquired boolean, locked_by uuid, locked_by_name text, locked_at timestamptz)
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.roadmap_templates
  set edit_locked_by = auth.uid(), edit_locked_at = now()
  where id = p_template_id
    and (
      edit_locked_by is null
      or edit_locked_by = auth.uid()
      or edit_locked_at < now() - interval '5 minutes'
    );

  return query
    select
      (t.edit_locked_by = auth.uid()) as acquired,
      t.edit_locked_by as locked_by,
      pr.full_name as locked_by_name,
      t.edit_locked_at as locked_at
    from public.roadmap_templates t
    left join public.profiles pr on pr.id = t.edit_locked_by
    where t.id = p_template_id;
end;
$$;

create or replace function public.release_roadmap_template_edit_lock(p_template_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.roadmap_templates
  set edit_locked_by = null, edit_locked_at = null
  where id = p_template_id and edit_locked_by = auth.uid();
end;
$$;
