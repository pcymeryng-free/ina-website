-- ============================================================================
-- Migration v59: Casos de Éxito (Success Cases)
--
-- Pablo (sep 2026): "quiero que agregues otra dimensión a la plataforma que
-- es Casos de éxito. Te adjunto unos documentos con casos de exito de
-- starlink y quiero que los incorpores conceptualmente para que un proyecto
-- nuevo se puede basar en un caso de éxito, o bien, lo tome como
-- referencia." Seeded from "Starlink Impact Use Cases LATAM ESP.pdf" (see
-- supabase/data_success_cases_starlink.sql), but the model is intentionally
-- generic — "provider" is free text, not a Starlink-only enum — so future
-- success cases from any technology/vendor (fibra, torres, etc.) fit the
-- same table.
--
-- QUÉ AGREGA
--   - public.success_cases — one row per case study: title, provider/
--     technology, country, region, sector (closed taxonomy — see check
--     below), bilingual summary, optional beneficiaries_count/metrics/
--     source. A shared reference library, same permission shape as
--     Financing Programs (migration_v19_program_permissions.sql): visible
--     to every authenticated user, but only an advisor/admin can create,
--     edit or delete one — see app/success-cases.html /
--     app/new-success-case.html and INAPlatform.canManageSuccessCases().
--   - public.project_success_cases — join table: a project can reference
--     MANY success cases as inspiration/precedent, and a success case can
--     be referenced by many projects. Modeled directly on project_programs
--     (migration_v21) — same owner-or-assigned-advisor manage policy, same
--     "everyone who can see the project can see its linked cases" select
--     policy (plus advisor/admin, matching every other project-child
--     table).
--
-- Run this whole file once in Supabase Dashboard → SQL Editor.
-- ============================================================================

-- ---------- success_cases ----------
create table if not exists public.success_cases (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  -- Free text on purpose (see header note) — "Starlink" for the seeded
  -- cases, but any provider/technology name works for future entries.
  provider text not null default 'Starlink',
  country text not null,
  -- Optional finer-grained location within the country, e.g. "Amazonía",
  -- "La Araucanía" — matches how the source PDF labels each case.
  region text,
  -- Closed taxonomy matching the 5 categories the source PDF groups cases
  -- into, plus two forward-looking buckets ('financial_inclusion' is
  -- mentioned in the PDF's intro with no concrete case yet; 'other' is the
  -- catch-all for future non-Starlink submissions that don't fit the rest).
  sector text not null check (sector in (
    'education', 'health', 'emergency_response', 'agriculture',
    'government', 'financial_inclusion', 'other'
  )),
  summary_es text not null,
  summary_en text,
  beneficiaries_count integer,
  -- Free-form extra quantitative highlights or a direct quote from the
  -- source material (e.g. "un cambio radical..." in the Bahía agriculture
  -- case) — kept separate from summary so the UI can style it distinctly.
  metrics_es text,
  metrics_en text,
  source_label text,
  source_url text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.success_cases enable row level security;

-- Same shape as programs_select_all_authenticated (migration_v19): any
-- logged-in user can browse the library so it's useful as reference while
-- drafting a new project, regardless of role.
create policy "success_cases_select_all_authenticated" on public.success_cases
  for select using (auth.uid() is not null);

create policy "success_cases_insert_advisor_or_admin" on public.success_cases
  for insert with check (
    auth.uid() = created_by and (public.is_advisor() or public.is_admin())
  );
create policy "success_cases_update_advisor_or_admin" on public.success_cases
  for update using (public.is_advisor() or public.is_admin());
create policy "success_cases_delete_advisor_or_admin" on public.success_cases
  for delete using (public.is_advisor() or public.is_admin());

create index if not exists success_cases_sector_idx on public.success_cases(sector);
create index if not exists success_cases_country_idx on public.success_cases(country);

-- ---------- project_success_cases ----------
-- A project can cite MANY success cases as the precedent/inspiration it's
-- basing itself on (e.g. a rural-fiber project pointing at the Colombia
-- "2.000 instituciones educativas" case) — see migration_v21's
-- project_programs for the identical shape this mirrors.
create table if not exists public.project_success_cases (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  success_case_id uuid not null references public.success_cases(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  -- Optional free text: why this case is relevant to this project.
  note text,
  linked_at timestamptz not null default now(),
  unique (project_id, success_case_id)
);

alter table public.project_success_cases enable row level security;

create policy "project_success_cases_select_own_or_advisor" on public.project_success_cases
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = project_success_cases.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

create policy "project_success_cases_insert_own_or_assigned_advisor" on public.project_success_cases
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.projects pr
      where pr.id = project_success_cases.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

create policy "project_success_cases_delete_own_or_assigned_advisor" on public.project_success_cases
  for delete using (
    exists (
      select 1 from public.projects pr
      where pr.id = project_success_cases.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

create index if not exists project_success_cases_project_id_idx on public.project_success_cases(project_id);
create index if not exists project_success_cases_success_case_id_idx on public.project_success_cases(success_case_id);
