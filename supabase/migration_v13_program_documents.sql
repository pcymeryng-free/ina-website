-- ============================================================================
-- Migration v13 — Program documents
--
-- Lets a program owner attach supporting documents (PDFs, images, etc.) when
-- creating or editing a Program — same idea as project_documents, just
-- scoped to public.programs instead of public.projects. Mirrors that table's
-- shape and RLS pattern exactly.
--
-- Reuses the EXISTING "project-documents" Supabase Storage bucket rather
-- than creating a new one — its upload/read policies only key off the first
-- path segment being the uploader's own auth.uid(), so they work unchanged
-- for program uploads too. Storage path convention for these uploads:
--   {user_id}/programs/{program_id}/{filename}
-- (the "programs/" segment just keeps them visually separate from
-- {user_id}/{project_id}/{filename} project uploads in the bucket browser —
-- it has no effect on the RLS policies themselves.)
--
-- Run this whole file once in Supabase Dashboard → SQL Editor. No new
-- Storage bucket or bucket policies to create — those already exist from
-- the original setup (see the bottom of schema.sql).
-- ============================================================================

create table if not exists public.program_documents (
  id uuid primary key default gen_random_uuid(),
  program_id uuid not null references public.programs(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  file_name text not null,
  storage_path text not null,
  uploaded_at timestamptz not null default now()
);

alter table public.program_documents enable row level security;

-- Same visibility pattern as project_documents: owner or advisor.
create policy "program_documents_select_own_or_advisor" on public.program_documents
  for select using (auth.uid() = user_id or public.is_advisor());

create policy "program_documents_insert_own" on public.program_documents
  for insert with check (auth.uid() = user_id);

create index if not exists program_documents_program_id_idx on public.program_documents(program_id);
