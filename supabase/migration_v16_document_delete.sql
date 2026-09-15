-- ============================================================================
-- Migration v16: allow deleting/replacing individual project & program
-- attachments.
--
-- Until now, project_documents and program_documents only had SELECT and
-- INSERT RLS policies — a submitter could add files but never remove a
-- mistaken upload or swap one out for a corrected version without deleting
-- the whole project/program. This adds owner-only DELETE policies for both
-- tables, plus a matching DELETE policy on storage.objects for the
-- "project-documents" bucket (the existing bucket policies only cover
-- INSERT/SELECT — see the bottom of schema.sql).
--
-- "Replace" isn't a separate operation: the UI (new-project.html /
-- new-program.html) just deletes the old row/file and lets the submitter
-- drop a new file into the same category's upload zone, which uploads as a
-- brand new project_documents/program_documents row.
--
-- Run this once in the Supabase SQL Editor. Safe to re-run (drops the
-- policy first if it already exists).
-- ============================================================================

drop policy if exists "documents_delete_own" on public.project_documents;
create policy "documents_delete_own" on public.project_documents
  for delete using (auth.uid() = user_id);

drop policy if exists "program_documents_delete_own" on public.program_documents;
create policy "program_documents_delete_own" on public.program_documents
  for delete using (auth.uid() = user_id);

drop policy if exists "doc_delete_own_folder" on storage.objects;
create policy "doc_delete_own_folder" on storage.objects
  for delete using (
    bucket_id = 'project-documents'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
