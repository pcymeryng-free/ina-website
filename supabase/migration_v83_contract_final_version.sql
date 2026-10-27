-- ============================================================================
-- migration_v83_contract_final_version.sql
-- Run this ONCE in Supabase: Dashboard → SQL Editor → New query → paste →
-- Run. Safe to re-run.
--
-- QUÉ AGREGA
-- Pablo (oct 2026): "el manejo contractual de INA con un proyecto tiene los
-- siguientes pasos: primero se firma un NDA (...) Luego se firma un
-- Statement of Work (SOW) (...) Luego se firma el contrato. En todos los
-- casos INA debe ofrecer un template que se puede tomar y luego guardar la
-- versión final del documento que se va a firmar."
--
-- Cada etapa (contract_stages) ya tenía el borrador generado desde el
-- template (generated_storage_path) y la copia firmada
-- (signed_storage_path). Suma el paso intermedio: la versión final
-- acordada, lista para firmar (normalmente el borrador editado en Word).
--
--   contract_stages.final_storage_path  — archivo de la versión final
--   contract_stages.final_uploaded_at   — cuándo se subió
--
-- También actualiza public.project_storage_paths() (migration_v82) para
-- que al borrar un proyecto se borren estos archivos del Storage.
--
-- QUÉ NO CAMBIA
-- Ninguna policy: los archivos van al mismo bucket y carpeta
-- ({user_id}/contracts/{contract_id}/{stage_type}/...) que el borrador y la
-- copia firmada.
-- ============================================================================

alter table public.contract_stages
  add column if not exists final_storage_path text,
  add column if not exists final_uploaded_at timestamptz;

comment on column public.contract_stages.final_storage_path is 'Versión final acordada, lista para firmar. Ver migration_v83_contract_final_version.sql.';

create or replace function public.project_storage_paths(p_project_id uuid)
returns setof text
language sql
security definer set search_path = public
stable
as $$
  select path from (
    select d.storage_path as path
    from public.project_documents d
    where d.project_id = p_project_id
    union
    select unnest(array[s.generated_storage_path, s.final_storage_path, s.signed_storage_path])
    from public.contract_stages s
    join public.contracts c on c.id = s.contract_id
    where c.project_id = p_project_id
  ) x
  where path is not null
    and exists (
      select 1 from public.projects p
      where p.id = p_project_id
        and (p.user_id = auth.uid() or public.is_admin())
    );
$$;

grant execute on function public.project_storage_paths(uuid) to authenticated;

-- Verificación
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'contract_stages'
  and column_name in ('final_storage_path', 'final_uploaded_at');
