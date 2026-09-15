-- ============================================================================
-- INA Platform — Migration v31: edit locks (concurrent-edit prevention)
--
-- Pablo: "Cuando un usuario abre un proyecto, programa o roadmap en modo
-- edición, debería bloquearse para edición al resto de los usuarios." —
-- a hard lock: a second user can't enter edit mode at all while someone
-- else holds it. They see who's editing (when RLS lets them see that
-- person's name — see the profiles RLS note below) and since when, and
-- stay in read-only mode until the lock clears.
--
-- No manual "force unlock" — locks auto-expire on their own if the
-- editor's tab stops renewing them (closed, crashed, lost network), so
-- nobody can get permanently stuck. See LOCK_TIMEOUT_MINUTES in
-- assets/platform.js for the exact window (kept in sync with the
-- "interval '5 minutes'" below — change both together if it's ever
-- tuned).
--
-- Applies to the three record types that have a dedicated "edit mode"
-- form: projects, programs, roadmap_templates. Does NOT touch
-- roadmap_instances (the step-by-step tracker) — advancing a step there
-- isn't a form "edit mode" in the same sense, and multiple
-- advisors/admins being able to act on the same instance was already the
-- deliberate design (see supabase/migration_v27_gestion_instances.sql).
-- ============================================================================

alter table public.projects add column if not exists edit_locked_by uuid references public.profiles(id) on delete set null;
alter table public.projects add column if not exists edit_locked_at timestamptz;

alter table public.programs add column if not exists edit_locked_by uuid references public.profiles(id) on delete set null;
alter table public.programs add column if not exists edit_locked_at timestamptz;

alter table public.roadmap_templates add column if not exists edit_locked_by uuid references public.profiles(id) on delete set null;
alter table public.roadmap_templates add column if not exists edit_locked_at timestamptz;

-- ---------- projects ----------

-- Atomically claims the lock if it's free, already held by the caller
-- (a heartbeat renewal — see assets/platform.js), or stale (held longer
-- than 5 minutes, meaning the previous editor's tab almost certainly
-- closed/crashed without releasing it). No `security definer` — this
-- runs as the calling user, so the same RLS update policy that already
-- decides who can edit a project at all (owner or assigned advisor, see
-- projects_update_own_or_assigned_advisor) is exactly what decides who
-- can ever acquire its lock. Nothing new to grant, nothing new to lock
-- down separately.
--
-- locked_by_name comes from a join against profiles, which is subject to
-- ITS OWN RLS (profiles_select_own_or_privileged: a standard user can
-- only read their own profile row, not anyone else's) — so a project
-- owner blocked by an advisor's lock will see locked_by/locked_at but a
-- null locked_by_name; the app falls back to a generic "someone else is
-- editing" message in that case rather than showing a blank name.
create or replace function public.acquire_project_edit_lock(p_project_id uuid)
returns table (acquired boolean, locked_by uuid, locked_by_name text, locked_at timestamptz)
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.projects
  set edit_locked_by = auth.uid(), edit_locked_at = now()
  where id = p_project_id
    and (
      edit_locked_by is null
      or edit_locked_by = auth.uid()
      or edit_locked_at < now() - interval '5 minutes'
    );

  return query
    select
      (p.edit_locked_by = auth.uid()) as acquired,
      p.edit_locked_by as locked_by,
      pr.full_name as locked_by_name,
      p.edit_locked_at as locked_at
    from public.projects p
    left join public.profiles pr on pr.id = p.edit_locked_by
    where p.id = p_project_id;
end;
$$;

-- Only clears the lock if the caller is the one currently holding it —
-- a harmless no-op otherwise (e.g. a best-effort beforeunload release
-- firing after the lock had already expired and been claimed by someone
-- else; we must not let it steal that person's lock out from under them).
create or replace function public.release_project_edit_lock(p_project_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.projects
  set edit_locked_by = null, edit_locked_at = null
  where id = p_project_id and edit_locked_by = auth.uid();
end;
$$;

-- ---------- programs ----------

create or replace function public.acquire_program_edit_lock(p_program_id uuid)
returns table (acquired boolean, locked_by uuid, locked_by_name text, locked_at timestamptz)
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.programs
  set edit_locked_by = auth.uid(), edit_locked_at = now()
  where id = p_program_id
    and (
      edit_locked_by is null
      or edit_locked_by = auth.uid()
      or edit_locked_at < now() - interval '5 minutes'
    );

  return query
    select
      (p.edit_locked_by = auth.uid()) as acquired,
      p.edit_locked_by as locked_by,
      pr.full_name as locked_by_name,
      p.edit_locked_at as locked_at
    from public.programs p
    left join public.profiles pr on pr.id = p.edit_locked_by
    where p.id = p_program_id;
end;
$$;

create or replace function public.release_program_edit_lock(p_program_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.programs
  set edit_locked_by = null, edit_locked_at = null
  where id = p_program_id and edit_locked_by = auth.uid();
end;
$$;

-- ---------- roadmap_templates ----------

create or replace function public.acquire_roadmap_template_edit_lock(p_template_id uuid)
returns table (acquired boolean, locked_by uuid, locked_by_name text, locked_at timestamptz)
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.roadmap_templates
  set edit_locked_by = auth.uid(), edit_locked_at = now()
  where id = p_template_id
    and (
      edit_locked_by is null
      or edit_locked_by = auth.uid()
      or edit_locked_at < now() - interval '5 minutes'
    );

  return query
    select
      (t.edit_locked_by = auth.uid()) as acquired,
      t.edit_locked_by as locked_by,
      pr.full_name as locked_by_name,
      t.edit_locked_at as locked_at
    from public.roadmap_templates t
    left join public.profiles pr on pr.id = t.edit_locked_by
    where t.id = p_template_id;
end;
$$;

create or replace function public.release_roadmap_template_edit_lock(p_template_id uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  update public.roadmap_templates
  set edit_locked_by = null, edit_locked_at = null
  where id = p_template_id and edit_locked_by = auth.uid();
end;
$$;
