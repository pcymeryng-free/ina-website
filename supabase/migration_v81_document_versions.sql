-- ============================================================================
-- migration_v81_document_versions.sql
-- Run this ONCE in Supabase: Dashboard → SQL Editor → New query → paste →
-- Run. Safe to re-run.
--
-- QUÉ AGREGA
-- Pablo (oct 2026): "lo que tenemos que agregar al sistema es la
-- posibilidad de agregar un documento actualizado de un proyecto cargado y
-- como gestionar el cambio. El sistema debería mostrar las diferencias y el
-- usuario debería dar ok a esesos cambios." (Disparado por HUB Digital
-- Chubut, que terminó cargado dos veces — una por cada versión de su PDF.)
--
-- Flujo (app/project.html, pestaña Documentos → "Subir versión
-- actualizada"): la IA lee el documento nuevo con el mismo agente de
-- extracción del alta de proyectos (api/extract-project-data.js), la
-- plataforma muestra cada dato del proyecto que cambia (valor actual vs.
-- valor del documento nuevo) y el usuario aprueba cuáles aplicar. El
-- documento nuevo se guarda y el anterior NO se borra: queda como versión
-- anterior, marcado con superseded_by.
--
-- QUÉ CAMBIA
--   project_documents.superseded_by — id del documento que lo reemplazó
--     (null = versión vigente).
--   project_documents.superseded_at — cuándo se lo reemplazó.
--   Policy de UPDATE en project_documents — hasta ahora no existía
--     ninguna (los documentos solo se insertaban/borraban). Misma condición
--     que projects_update_own_or_assigned_advisor: puede marcar un documento
--     como reemplazado quien puede editar el proyecto.
--
-- Los agentes de IA (analyze-project, suggest-risks, generate-proposal,
-- extract-template-data, promotion-agent) filtran las versiones anteriores
-- en JS, no en la query, así que el código funciona igual antes y después
-- de correr esta migración.
-- ============================================================================

alter table public.project_documents
  add column if not exists superseded_by uuid references public.project_documents(id) on delete set null,
  add column if not exists superseded_at timestamptz;

drop policy if exists "documents_update_project_editor" on public.project_documents;
create policy "documents_update_project_editor" on public.project_documents
  for update using (
    exists (
      select 1 from public.projects p
      where p.id = project_documents.project_id
        and (
          auth.uid() = p.user_id
          or auth.uid() = p.assigned_advisor_id
          or public.has_entity_access(auth.uid(), 'projects', 'edit', p.user_id)
        )
    )
  );

comment on column public.project_documents.superseded_by is 'Documento que reemplazó a este (versión actualizada). Null = versión vigente. Ver migration_v81_document_versions.sql.';

-- Verificación
select column_name, data_type from information_schema.columns
where table_schema = 'public' and table_name = 'project_documents'
  and column_name in ('superseded_by', 'superseded_at');
