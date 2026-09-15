-- ============================================================================
-- Migration v44: Módulo de Master Data (Contactos, Empresas, Productos,
-- Organismos Públicos)
--
-- QUÉ AGREGA
-- Hasta ahora la plataforma no tenía un registro cerrado de personas ni
-- organizaciones externas — "organization" en profiles/projects y
-- "financing_entity" en programs son todos texto libre (ver comentario en
-- migration_v36_program_financing_entity.sql: "no hay un registro cerrado
-- de entidades financiadoras en la plataforma"). Este módulo agrega ese
-- registro cerrado, como catálogo interno independiente:
--
--   • public.companies        — empresas (fabricantes, proveedores de
--                                servicios, entidades financieras — una
--                                empresa puede tener varias etiquetas a la
--                                vez, ver "types" abajo).
--   • public.public_agencies  — organismos públicos (ENACOM, ministerios,
--                                entes reguladores, gobiernos
--                                provinciales/municipales, etc.).
--   • public.contacts         — personas de contacto. Un contacto puede
--                                tener un cargo vigente en una Empresa O en
--                                un Organismo Público (no ambos a la vez) —
--                                se guarda directamente en la fila del
--                                contacto (company_id/public_agency_id +
--                                position_title), sin tabla de historial:
--                                si el contacto cambia de trabajo, se
--                                edita el mismo registro. Ver la nota sobre
--                                el CHECK que impide setear ambas FKs a la
--                                vez.
--   • public.products         — catálogo de productos, opcionalmente
--                                asociados a la Empresa fabricante/
--                                proveedora (company_id).
--
-- QUÉ NO TOCA (por ahora)
-- Esta es una entrega standalone — decisión explícita de Pablo. NO
-- modifica programs.financing_entity, projects.organization ni
-- profiles.organization (siguen siendo texto libre). Conectar esos campos
-- a este nuevo catálogo (por ejemplo, que financing_entity pase a ser un
-- selector contra companies con types @> array['financial_entity']) queda
-- para una migración futura, si Pablo lo pide.
--
-- PERMISOS
-- Igual que roadmap_templates (ver schema.sql): las 4 tablas son visibles
-- y editables SOLO por advisor/admin. No hay noción de "dueño" — es un
-- directorio interno de la plataforma, no datos de un usuario en
-- particular. Un usuario estándar ni siquiera ve el link "Master Data" en
-- la nav (gateado en el JS por INAPlatform.canManageMasterData()), y la
-- RLS lo hace cumplir igual del lado del servidor.
--
-- CÓMO USAR
-- Ejecutar una sola vez en el SQL Editor de Supabase. Usa "if not exists"
-- en las 4 tablas, así que es seguro correrlo más de una vez.
-- ============================================================================

-- ---------- companies ----------
create table if not exists public.companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  -- Multi-etiqueta a propósito: una empresa real puede ser, por ejemplo,
  -- un banco (financial_entity) que también presta asistencia técnica
  -- (service_provider) — no tiene sentido forzar una sola categoría.
  types text[] not null default '{}' check (types <@ array[
    'manufacturer',
    'service_provider',
    'financial_entity'
  ]::text[]),
  country text,
  website text,
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.companies enable row level security;

create policy "companies_select_advisor_or_admin" on public.companies
  for select using (public.is_advisor() or public.is_admin());
create policy "companies_insert_advisor_or_admin" on public.companies
  for insert with check (public.is_advisor() or public.is_admin());
create policy "companies_update_advisor_or_admin" on public.companies
  for update using (public.is_advisor() or public.is_admin());
create policy "companies_delete_advisor_or_admin" on public.companies
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists companies_name_idx on public.companies(name);

-- ---------- public_agencies ----------
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
  for select using (public.is_advisor() or public.is_admin());
create policy "public_agencies_insert_advisor_or_admin" on public.public_agencies
  for insert with check (public.is_advisor() or public.is_admin());
create policy "public_agencies_update_advisor_or_admin" on public.public_agencies
  for update using (public.is_advisor() or public.is_admin());
create policy "public_agencies_delete_advisor_or_admin" on public.public_agencies
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists public_agencies_name_idx on public.public_agencies(name);

-- ---------- contacts ----------
create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text,
  phone text,
  -- El cargo vigente del contacto (ej. "Gerente de Infraestructura",
  -- "Director de Financiamiento"). Solo tiene sentido junto con
  -- company_id o public_agency_id — ver el CHECK debajo.
  position_title text,
  company_id uuid references public.companies(id) on delete set null,
  public_agency_id uuid references public.public_agencies(id) on delete set null,
  notes text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Un contacto tiene su cargo vigente en una Empresa O en un Organismo
  -- Público, nunca en ambos a la vez (puede no tener ninguno todavía).
  constraint contacts_single_affiliation check (
    company_id is null or public_agency_id is null
  )
);

alter table public.contacts enable row level security;

create policy "contacts_select_advisor_or_admin" on public.contacts
  for select using (public.is_advisor() or public.is_admin());
create policy "contacts_insert_advisor_or_admin" on public.contacts
  for insert with check (public.is_advisor() or public.is_admin());
create policy "contacts_update_advisor_or_admin" on public.contacts
  for update using (public.is_advisor() or public.is_admin());
create policy "contacts_delete_advisor_or_admin" on public.contacts
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists contacts_full_name_idx on public.contacts(full_name);
create index if not exists contacts_company_id_idx on public.contacts(company_id);
create index if not exists contacts_public_agency_id_idx on public.contacts(public_agency_id);

-- ---------- products ----------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  -- Empresa fabricante/proveedora del producto. Opcional: puede cargarse
  -- un producto genérico sin asociarlo todavía a una Empresa puntual.
  company_id uuid references public.companies(id) on delete set null,
  category text,
  description text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products enable row level security;

create policy "products_select_advisor_or_admin" on public.products
  for select using (public.is_advisor() or public.is_admin());
create policy "products_insert_advisor_or_admin" on public.products
  for insert with check (public.is_advisor() or public.is_admin());
create policy "products_update_advisor_or_admin" on public.products
  for update using (public.is_advisor() or public.is_admin());
create policy "products_delete_advisor_or_admin" on public.products
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists products_name_idx on public.products(name);
create index if not exists products_company_id_idx on public.products(company_id);

-- ============================================================================
-- Verificación
-- ============================================================================
select table_name from information_schema.tables
where table_schema = 'public'
  and table_name in ('companies', 'public_agencies', 'contacts', 'products')
order by table_name;
