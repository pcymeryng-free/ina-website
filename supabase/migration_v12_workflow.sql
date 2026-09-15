-- ============================================================================
-- INA Platform — Migration v12: Project workflow (advisor-driven stages)
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
--
-- Why: Pablo wants project.html to show a visible workflow — the project's
-- current stage, plus an advisor who can act to push it to the next one.
-- Rather than inventing a second, parallel "stage" concept, this reuses the
-- 4 stages that already exist as projects.readiness_stage / the Investment
-- Readiness Index™ (Concept Stage → Early Structuring → Advanced
-- Structuring → Investment Ready). What's new is that an advisor can now
-- manually push readiness_stage forward one step at a time — independent
-- of (and not overwritten by) a fresh AI/manual framework analysis, which
-- can still set readiness_stage on its own exactly as before.
--
-- What this adds:
--   - public.profiles.specialization — nullable (technical / financial /
--     administrative). Unused today: "por el momento el advisor puede
--     hacer todo," so every advisor stays null (general-purpose). Once
--     specialized advisor roles actually launch, assign this per advisor
--     (same manual admin-panel / Table Editor pattern as `role` itself)
--     and gate advance_project_workflow() below by it — that's a small
--     follow-up, not a new migration, because the column and the event
--     history already exist.
--   - public.projects.assigned_advisor_id — which advisor is currently
--     working the project (nullable, unrestricted — any advisor can take
--     or reassign any project for now).
--   - public.project_workflow_events — an append-only audit trail of every
--     stage transition (from/to/advisor/when), so project.html can render
--     a history, not just the current state.
--   - public.take_project(project_id) and
--     public.advance_project_workflow(project_id, note) — SECURITY DEFINER
--     functions that perform the actual writes. Deliberately NOT done via
--     a broad "advisors can UPDATE any project" RLS policy, which would
--     let an advisor edit name/description/etc. on someone else's project
--     — these two functions are the only path that can change
--     assigned_advisor_id or readiness_stage on a project you don't own.
-- ============================================================================

alter table public.profiles
  add column if not exists specialization text
  check (specialization is null or specialization in ('technical', 'financial', 'administrative'));

alter table public.projects
  add column if not exists assigned_advisor_id uuid references public.profiles(id) on delete set null;

create table if not exists public.project_workflow_events (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  from_stage text,
  to_stage text not null check (to_stage in (
    'Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'
  )),
  advisor_id uuid references public.profiles(id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);

alter table public.project_workflow_events enable row level security;

-- Same visibility as the project itself: its owner, or any advisor/admin.
-- No insert/update policy for regular clients on purpose — every row is
-- written by advance_project_workflow() below, never a direct client
-- insert, so a client can't fabricate a fake transition history.
drop policy if exists "workflow_events_select_own_or_advisor" on public.project_workflow_events;
create policy "workflow_events_select_own_or_advisor" on public.project_workflow_events
  for select using (
    public.is_advisor() or public.is_admin()
    or exists (
      select 1 from public.projects pr
      where pr.id = project_workflow_events.project_id and pr.user_id = auth.uid()
    )
  );

create index if not exists project_workflow_events_project_id_idx on public.project_workflow_events(project_id);

-- Claims a project for the calling advisor. Unrestricted for now: any
-- advisor/admin can take (or re-take, from someone else) any project —
-- matches "por el momento el advisor puede hacer todo."
--
-- NOTE: advance_project_workflow() further down this file is superseded by
-- promote_project_workflow()/demote_project_workflow()/
-- return_project_to_not_analyzed() in migration_v20_workflow_promote_demote.sql
-- (mandatory comments, bidirectional, and a dedicated "send back to the
-- owner" action) — that migration DROPs the old function. take_project()
-- itself is unchanged and still the one below.
create or replace function public.take_project(p_project_id uuid)
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can take a project.';
  end if;

  update public.projects
  set assigned_advisor_id = auth.uid(), updated_at = now()
  where id = p_project_id;

  if not found then
    raise exception 'Project not found.';
  end if;
end;
$$;

-- Advances a project exactly one step forward through the 4 framework
-- stages (never skips, never goes past 'Investment Ready'), claims the
-- project for the calling advisor, and logs the transition. A project
-- with no readiness_stage yet (no analysis has completed) is treated as
-- starting from 'Concept Stage'.
create or replace function public.advance_project_workflow(p_project_id uuid, p_note text default null)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_current text;
  v_next text;
  v_stage_order text[] := array['Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'];
  v_idx int;
  v_found boolean;
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can advance a project''s workflow stage.';
  end if;

  select true, coalesce(readiness_stage, 'Concept Stage') into v_found, v_current
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  v_idx := array_position(v_stage_order, v_current);
  if v_idx is null or v_idx = array_length(v_stage_order, 1) then
    raise exception 'Project is already at the final stage.';
  end if;

  v_next := v_stage_order[v_idx + 1];

  update public.projects
  set readiness_stage = v_next, assigned_advisor_id = auth.uid(), updated_at = now()
  where id = p_project_id;

  insert into public.project_workflow_events (project_id, from_stage, to_stage, advisor_id, note)
  values (p_project_id, v_current, v_next, auth.uid(), nullif(trim(p_note), ''));

  return v_next;
end;
$$;
