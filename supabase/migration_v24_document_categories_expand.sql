-- Migration v24: expand project_documents.document_type to 7 categories
-- Adds: economic, bylaws, licenses (alongside existing technical, financial, administrative, other)
-- Run manually in Supabase SQL Editor.

alter table public.project_documents
  drop constraint if exists project_documents_document_type_check;

alter table public.project_documents
  add constraint project_documents_document_type_check check (document_type in (
    'technical', 'economic', 'financial', 'bylaws', 'administrative', 'licenses', 'other'
  ));
