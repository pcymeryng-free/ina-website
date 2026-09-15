-- ============================================================================
-- Migration v15 — Document categories for project attachments
--
-- Adds a document_type column to project_documents so uploads can be tagged
-- as one of four categories at upload time:
--   - technical       ("Carpeta técnica" — technical folder/dossier)
--   - financial        ("Documento económico-financiero")
--   - administrative    ("Documento administrativo")
--   - other             (anything else)
--
-- Context: the technical, financial and administrative documents are all
-- needed for the eventual evaluation of a project, but none of them should
-- be REQUIRED at upload time — a project can be submitted with none, some,
-- or all of them attached, and completed later. This migration only adds
-- the category field; it does NOT make any of the four sections mandatory
-- (see new-project.html, which keeps all four upload zones optional).
--
-- default 'other' so existing rows (uploaded before this migration, with no
-- category picked) don't end up in a NULL/invalid state — they just show up
-- under "Other attachments" until the owner re-uploads them under the right
-- category if they want to reclassify.
--
-- Run this whole file once in Supabase Dashboard → SQL Editor.
-- ============================================================================

alter table public.project_documents
  add column if not exists document_type text not null default 'other'
  check (document_type in ('technical', 'financial', 'administrative', 'other'));

create index if not exists project_documents_document_type_idx
  on public.project_documents(document_type);
