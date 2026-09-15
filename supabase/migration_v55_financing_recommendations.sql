-- ============================================================================
-- migration_v55_financing_recommendations.sql
--
-- New feature (Pablo, sep 2026): "for any new or already-submitted project,
-- use AI to pick the best COMBINATION of financing instruments/Programs
-- already registered on the platform, and show them on the projects
-- dashboard." This migration adds the one new table the feature needs.
--
-- public.financing_recommendations — one row per project (unique
-- constraint, same "re-running overwrites" convention as fsu_scoring, not
-- an append-only history like framework_analysis: the model's combination
-- logic is meant to reflect the project's CURRENT attributes and the
-- CURRENT catalog of registered Programs, so an old recommendation has no
-- standing value once a newer one exists). Entirely AI-generated — there is
-- no manual/self-entered variant (unlike framework_analysis, which has both
-- an 'ai' and a 'manual' source) — so, mirroring framework_analysis's own
-- "AI path has no insert/update policy for anon/authenticated" comment (see
-- supabase/schema.sql), this table gets ONLY a select policy here. All
-- writes go through api/recommend-financing.js using the service role key,
-- which enforces its own owner/assigned-advisor/admin permission check
-- server-side (identical pattern to api/analyze-project.js).
--
-- Run this in Supabase SQL Editor, then re-run supabase/schema.sql (or just
-- this file) is NOT required afterwards — schema.sql has already been
-- updated to include this table for any FRESH database setup; existing
-- databases need this migration file run once.
-- ============================================================================

create table if not exists public.financing_recommendations (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  -- Whoever triggered this run (owner, assigned advisor, or an admin) — see
  -- the matching comment on framework_analysis.user_id in schema.sql for
  -- why this isn't necessarily the project owner.
  user_id uuid not null references public.profiles(id) on delete cascade,

  -- Ordered array of recommended instruments, Spanish text. Each element:
  -- { program_id, name, financing_entity, funding_stage, fit_score (0-100),
  --   suggested_percentage (0-100 or null), rationale, already_applied }.
  -- program_id/name/financing_entity/funding_stage/already_applied are
  -- resolved server-side against the real public.programs catalog right
  -- before saving (never trusted verbatim from the model) — see the
  -- catalog-resolution step in api/recommend-financing.js's handler, right
  -- after the model call. suggested_percentage (Pablo, sep 2026) is the
  -- AI's proposed % of the project's budget this instrument should cover —
  -- always null for a 'preparation'-stage instrument (mirrors
  -- computeFinancingCoverage()'s "preparation-stage rows never get a share"
  -- rule) — and is only a STARTING suggestion: the user edits it in
  -- app/project.html before/when clicking "Aplicar", and it's saved as that
  -- application's own project_programs.financing_percentage, not written
  -- back here.
  recommended jsonb not null default '[]'::jsonb,
  -- Same shape, English rationale text — same bilingual convention as
  -- framework_analysis's _en columns (migration_v40).
  recommended_en jsonb not null default '[]'::jsonb,

  -- Overall combination strategy explanation (how the recommended
  -- instruments work together — e.g. "preparation grant now, then debt +
  -- political risk insurance together once the design is finished").
  summary text,
  summary_en text,

  -- Raw model output, kept for diagnosing a bad/unparseable response later
  -- — same pattern as framework_analysis.raw_model_output.
  raw_model_output text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- One recommendation per project — re-running overwrites it in place
  -- (upsert on project_id), same convention as fsu_scoring.
  unique (project_id)
);

alter table public.financing_recommendations enable row level security;

-- Same visibility pattern as fsu_scoring/framework_analysis: whoever
-- triggered THIS row, any advisor, or any admin. (See the file-header
-- comment above for why there's no insert/update policy for
-- anon/authenticated — only the service role, from
-- api/recommend-financing.js, writes these rows.)
create policy "financing_recommendations_select_own_or_advisor" on public.financing_recommendations
  for select using (auth.uid() = user_id or public.is_advisor() or public.is_admin());

create index if not exists financing_recommendations_project_id_idx on public.financing_recommendations(project_id);
