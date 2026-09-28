-- ============================================================================
-- migration_v67_contracts.sql
--
-- QUÉ AGREGA
-- public.contracts — tracking de contratos/acuerdos legales que maneja
-- INA: NDA, SOW y Contratos de Servicio con quien presenta un proyecto
-- (project_id), o Acuerdos de Financiamiento con una entidad financiera
-- (program_id — la misma tabla public.programs que ya usa Financing
-- Programs/Initiatives). Exactamente uno de los dos, nunca ambos ni
-- ninguno — ver el constraint contracts_project_xor_program.
--
-- Reutiliza el mismo bucket privado "project-documents" que ya usan
-- project_documents/program_documents (ver el comentario sobre
-- uploadProgramDocument() en assets/platform.js), bajo un prefijo nuevo
-- "contracts/{user_id}/{contract_id}/..." — no hace falta un bucket ni
-- una policy de Storage nueva, las políticas existentes solo miran el
-- prefijo {user_id}.
--
-- La firma queda manual por decisión de Pablo (sep 2026): la plataforma
-- genera un PDF borrador a partir de una plantilla (generated_storage_path)
-- y el usuario sube el escaneo/PDF ya firmado por fuera de la plataforma
-- (signed_storage_path) — no hay integración con ningún proveedor de
-- firma electrónica en esta pasada.
--
-- QUÉ NO CAMBIA
-- No toca project_documents/program_documents ni sus policies — un
-- contrato es un registro aparte, aunque comparta el bucket de Storage.
-- No agrega ningún flujo de aprobación ni bloquea nada del workflow de
-- proyectos existente.
-- ============================================================================

create table if not exists public.contracts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  project_id uuid references public.projects(id) on delete cascade,
  program_id uuid references public.programs(id) on delete cascade,
  contract_type text not null default 'other'
    check (contract_type in ('nda', 'sow', 'service_contract', 'financing_agreement', 'other')),
  title text not null,
  -- Free text — the person/entity on the other side of the agreement.
  -- Often duplicates the linked project's owner/organization or the
  -- linked program's organization, but kept editable/overridable rather
  -- than derived, since the actual signatory can differ (e.g. a project
  -- submitted by one org but the NDA signed by its parent company).
  counterparty_name text,
  status text not null default 'draft'
    check (status in ('draft', 'sent', 'signed', 'expired', 'terminated')),
  -- Which entry of CONTRACT_TEMPLATES (assets/platform.js) generated the
  -- draft, if any — null for a contract that was only ever uploaded, never
  -- generated from a template on this platform.
  template_key text,
  generated_storage_path text,
  signed_storage_path text,
  signed_at timestamptz,
  effective_date date,
  expiration_date date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint contracts_project_xor_program check (
    (project_id is not null and program_id is null) or
    (project_id is null and program_id is not null)
  )
);

alter table public.contracts enable row level security;

-- Contracts are INA's internal legal/business records, not something the
-- person who submitted a project should see or manage for their own
-- project — advisor/admin only, unlike project_documents (owner-visible).
create policy "contracts_select_advisor_or_admin" on public.contracts
  for select using (public.is_advisor() or public.is_admin());

create policy "contracts_insert_advisor_or_admin" on public.contracts
  for insert with check (
    (public.is_advisor() or public.is_admin()) and auth.uid() = user_id
  );

create policy "contracts_update_advisor_or_admin" on public.contracts
  for update using (public.is_advisor() or public.is_admin())
  with check (public.is_advisor() or public.is_admin());

create policy "contracts_delete_advisor_or_admin" on public.contracts
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists contracts_project_id_idx on public.contracts(project_id);
create index if not exists contracts_program_id_idx on public.contracts(program_id);
create index if not exists contracts_status_idx on public.contracts(status);
create index if not exists contracts_contract_type_idx on public.contracts(contract_type);
