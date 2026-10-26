-- ============================================================================
-- migration_v82_project_delete_storage_cleanup.sql
-- Run this ONCE in Supabase: Dashboard → SQL Editor → New query → paste →
-- Run. Safe to re-run.
--
-- PROBLEMA QUE RESUELVE
-- Pablo (oct 2026): al borrar el proyecto duplicado "Hub Chubut AI Hub", su
-- PDF quedó suelto en Storage. Borrar un proyecto elimina en cascada las
-- filas de project_documents / contracts / contract_stages, pero NO los
-- archivos a los que apuntan (Postgres no puede borrar objetos de Storage).
-- INAPlatform.deleteProject() (assets/platform.js) ahora borra esos
-- archivos antes de borrar el proyecto; esta migración le da lo que
-- necesita para hacerlo:
--
--   1. public.project_storage_paths(project_id) — devuelve todas las rutas
--      de Storage del proyecto (documentos, incluidas versiones anteriores,
--      y PDFs de contratos ligados al proyecto). SECURITY DEFINER porque el
--      dueño no puede leer por RLS las filas de documentos que subió un
--      advisor. Solo responde a quien puede borrar el proyecto (mismo
--      criterio que projects_delete_own_or_admin: dueño o admin).
--
--   2. Policy "doc_delete_project_owner_or_admin" en storage.objects — hasta
--      ahora solo se podía borrar dentro de la carpeta propia
--      ({auth.uid()}/...). Suma: un admin puede borrar cualquier archivo del
--      bucket, y el dueño de un proyecto puede borrar los archivos de ese
--      proyecto aunque los haya subido otro usuario:
--        {uploader}/{project_id}/...               (documentos)
--        {uploader}/contracts/{contract_id}/...     (contratos del proyecto)
--
-- Sin esta migración, deleteProject() igual borra los archivos que el
-- usuario puede borrar hoy (los de su propia carpeta) y sigue adelante.
-- ============================================================================

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
    select unnest(array[s.generated_storage_path, s.signed_storage_path])
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

drop policy if exists "doc_delete_project_owner_or_admin" on storage.objects;
create policy "doc_delete_project_owner_or_admin" on storage.objects
  for delete using (
    bucket_id = 'project-documents'
    and (
      public.is_admin()
      or exists (
        select 1 from public.projects p
        where p.id::text = (storage.foldername(name))[2]
          and p.user_id = auth.uid()
      )
      or (
        (storage.foldername(name))[2] = 'contracts'
        and exists (
          select 1 from public.contracts c
          join public.projects p on p.id = c.project_id
          where c.id::text = (storage.foldername(name))[3]
            and p.user_id = auth.uid()
        )
      )
    )
  );

-- Verificación
select policyname from pg_policies
where schemaname = 'storage' and tablename = 'objects' and policyname like 'doc_delete%';
