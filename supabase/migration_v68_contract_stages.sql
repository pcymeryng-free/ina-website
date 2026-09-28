-- ============================================================================
-- migration_v68_contract_stages.sql
--
-- QUÉ AGREGA
-- Un contrato (public.contracts) ya no es un documento suelto — es UNA
-- relación con un Proyecto o con una Entidad Financiera (public.programs),
-- que avanza a través de hasta 3 documentos/etapas independientes:
--   Proyecto  -> NDA (opcional, pero primero) -> SOW -> Contrato de Servicio
--   Programa  -> Acuerdo de Financiamiento (o "Otro")
-- Cada etapa tiene su propio estado, fechas, PDF generado y PDF firmado —
-- viven en la tabla nueva public.contract_stages, no en contracts.
--
-- Reutiliza el mismo bucket privado "project-documents" bajo
-- "{user_id}/contracts/{contract_id}/{stage_type}/..." (ver el comentario
-- sobre uploadGeneratedContractPdf() en assets/platform.js) — sigue
-- empezando con {user_id}, así que no hace falta ninguna policy de
-- Storage nueva.
--
-- QUÉ NO CAMBIA
-- No toca project_documents/program_documents. No agrega ningún flujo de
-- aprobación. Las políticas de contracts (advisor/admin-only) siguen
-- igual — contract_stages usa el mismo criterio directo, sin depender del
-- padre.
-- ============================================================================

create table public.contract_stages (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references public.contracts(id) on delete cascade,
  stage_type text not null
    check (stage_type in ('nda', 'sow', 'service_contract', 'financing_agreement', 'other')),
  status text not null default 'draft'
    check (status in ('draft', 'sent', 'signed', 'expired', 'terminated')),
  template_key text,
  generated_storage_path text,
  signed_storage_path text,
  signed_at timestamptz,
  effective_date date,
  expiration_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint contract_stages_unique_per_contract unique (contract_id, stage_type)
);

alter table public.contract_stages enable row level security;

create policy "contract_stages_select_advisor_or_admin" on public.contract_stages
  for select using (public.is_advisor() or public.is_admin());

create policy "contract_stages_insert_advisor_or_admin" on public.contract_stages
  for insert with check (public.is_advisor() or public.is_admin());

create policy "contract_stages_update_advisor_or_admin" on public.contract_stages
  for update using (public.is_advisor() or public.is_admin())
  with check (public.is_advisor() or public.is_admin());

create policy "contract_stages_delete_advisor_or_admin" on public.contract_stages
  for delete using (public.is_advisor() or public.is_admin());

create index contract_stages_contract_id_idx on public.contract_stages(contract_id);
create index contract_stages_stage_type_idx on public.contract_stages(stage_type);
create index contract_stages_status_idx on public.contract_stages(status);

-- ---------- carry forward existing contracts rows ----------

insert into public.contract_stages
  (contract_id, stage_type, status, template_key, generated_storage_path,
   signed_storage_path, signed_at, effective_date, expiration_date)
select id, contract_type, status, template_key, generated_storage_path,
       signed_storage_path, signed_at, effective_date, expiration_date
from public.contracts;

-- Project-linked contracts always have all 3 stage slots — add SOW /
-- Service Contract as empty drafts for any row that didn't already carry
-- one of those types forward above.
insert into public.contract_stages (contract_id, stage_type)
select c.id, s.stage_type
from public.contracts c
cross join (values ('sow'), ('service_contract')) as s(stage_type)
where c.project_id is not null
on conflict (contract_id, stage_type) do nothing;

alter table public.contracts
  drop column contract_type,
  drop column status,
  drop column template_key,
  drop column generated_storage_path,
  drop column signed_storage_path,
  drop column signed_at,
  drop column effective_date,
  drop column expiration_date;
