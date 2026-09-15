-- ============================================================================
-- INA Platform — Migration v20: promote/demote workflow with mandatory
-- comments, and the "return to Not Analyzed" action
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run.
--
-- Why: Pablo specified a precise state machine for app/project.html:
--
--   Not Analyzed (readiness_stage is null)
--     — the OWNER runs the self-assessment (app/assessment.html); doing so
--       moves the project to Concept Stage automatically. This is no longer
--       driven by the assessment's score/framework banding — see
--       submitManualAssessment() in assets/platform.js, updated in the same
--       session as this migration, which now only writes readiness_stage
--       when it's currently null instead of always overwriting it with the
--       computed stage. AI Analysis is not offered yet at this point
--       either (see api/analyze-project.js's new readiness_stage guard).
--   Concept Stage
--     — the owner can print the PDF verdict and re-run the self-assessment
--       (unchanged, no new SQL needed for either).
--     — an advisor who takes the project can: (1) send it back to Not
--       Analyzed with a mandatory comment (return_project_to_not_analyzed
--       below), (2) run AI Analysis (unchanged endpoint, now allowed since
--       readiness_stage is no longer null), or (3) promote it to Early
--       Structuring with a mandatory comment (promote_project_workflow).
--   Early Structuring / Advanced Structuring
--     — an advisor can promote to the next stage or demote to the previous
--       one, always with a mandatory comment (promote_project_workflow /
--       demote_project_workflow).
--   Investment Ready ("Listo para Inversión" in the UI)
--     — terminal: no promote (nothing beyond it) and, per Pablo's spec, no
--       demote either — the project has left this platform's internal
--       workflow for ENACOM's own formal evaluation.
--
-- What this changes:
--   1. project_workflow_events.to_stage's CHECK constraint gains a 5th
--      allowed value, 'Not Analyzed', so return_project_to_not_analyzed can
--      log that transition (from_stage was already unconstrained text).
--   2. advance_project_workflow() is replaced by promote_project_workflow()
--      — same one-step-forward behavior, but the comment is now mandatory
--      (raises if null/blank) and it no longer falls back to treating a
--      null readiness_stage as 'Concept Stage': promoting only works once
--      the project already has a stage (i.e. after the owner's first
--      self-assessment). The old function is dropped so nothing can call
--      the no-longer-correct version by accident.
--   3. demote_project_workflow() — new. One step backward through
--      STAGE_ORDER. Raises if the current stage is null, 'Concept Stage'
--      (use return_project_to_not_analyzed instead), or 'Investment Ready'
--      (terminal, no demote per spec).
--   4. return_project_to_not_analyzed() — new. Only callable from 'Concept
--      Stage' exactly. Resets readiness_stage to null and status back to
--      'submitted' (so project.html's results panel goes back to the
--      "not analyzed" empty state) and clears assigned_advisor_id (the
--      project goes back to the owner unclaimed), logging the transition
--      with the mandatory comment.
--
-- All three functions remain SECURITY DEFINER, same reasoning as
-- migration_v12: narrow, purpose-built writes instead of a broad "advisors
-- can update any project" RLS grant.
-- ============================================================================

alter table public.project_workflow_events
  drop constraint if exists project_workflow_events_to_stage_check;
alter table public.project_workflow_events
  add constraint project_workflow_events_to_stage_check check (to_stage in (
    'Not Analyzed', 'Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'
  ));

drop function if exists public.advance_project_workflow(uuid, text);

create or replace function public.promote_project_workflow(p_project_id uuid, p_note text)
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
    raise exception 'Only advisors can promote a project''s workflow stage.';
  end if;

  if p_note is null or trim(p_note) = '' then
    raise exception 'A comment explaining the promotion is required.';
  end if;

  select true, readiness_stage into v_found, v_current
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  if v_current is null then
    raise exception 'This project hasn''t completed the owner''s self-assessment yet — it can''t be promoted from Not Analyzed directly.';
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
  values (p_project_id, v_current, v_next, auth.uid(), trim(p_note));

  return v_next;
end;
$$;

create or replace function public.demote_project_workflow(p_project_id uuid, p_note text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_current text;
  v_prev text;
  v_stage_order text[] := array['Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'];
  v_idx int;
  v_found boolean;
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can demote a project''s workflow stage.';
  end if;

  if p_note is null or trim(p_note) = '' then
    raise exception 'A comment explaining the demotion is required.';
  end if;

  select true, readiness_stage into v_found, v_current
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  if v_current is null then
    raise exception 'Project is already at Not Analyzed.';
  end if;

  if v_current = 'Concept Stage' then
    raise exception 'Use return_project_to_not_analyzed() to send a Concept Stage project back to the owner.';
  end if;

  if v_current = 'Investment Ready' then
    raise exception 'A project at the final stage can''t be demoted.';
  end if;

  v_idx := array_position(v_stage_order, v_current);
  if v_idx is null or v_idx = 1 then
    raise exception 'Project is already at the earliest stage.';
  end if;

  v_prev := v_stage_order[v_idx - 1];

  update public.projects
  set readiness_stage = v_prev, assigned_advisor_id = auth.uid(), updated_at = now()
  where id = p_project_id;

  insert into public.project_workflow_events (project_id, from_stage, to_stage, advisor_id, note)
  values (p_project_id, v_current, v_prev, auth.uid(), trim(p_note));

  return v_prev;
end;
$$;

create or replace function public.return_project_to_not_analyzed(p_project_id uuid, p_note text)
returns text
language plpgsql
security definer set search_path = public
as $$
declare
  v_current text;
  v_found boolean;
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can return a project to Not Analyzed.';
  end if;

  if p_note is null or trim(p_note) = '' then
    raise exception 'A comment explaining the decision is required.';
  end if;

  select true, readiness_stage into v_found, v_current
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  if v_current is distinct from 'Concept Stage' then
    raise exception 'Only a project in Concept Stage can be returned to Not Analyzed.';
  end if;

  update public.projects
  set readiness_stage = null, status = 'submitted', assigned_advisor_id = null, updated_at = now()
  where id = p_project_id;

  insert into public.project_workflow_events (project_id, from_stage, to_stage, advisor_id, note)
  values (p_project_id, v_current, 'Not Analyzed', auth.uid(), trim(p_note));

  return 'Not Analyzed';
end;
$$;
