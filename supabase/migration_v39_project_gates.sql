-- ============================================================================
-- Migration v39: Gates formales del Project Structuring Framework™ (F1)
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run. Es seguro correrlo más de una
-- vez ("if not exists" / "or replace" en todo lo que sigue).
--
-- Ítem A de la hoja de ruta de corto plazo propuesta en
-- INA_Project_Structuring_Framework_y_Plataforma.pdf (sección 9.3).
--
-- PROBLEMA QUE RESUELVE
-- Hoy el avance de un proyecto se resuelve con readiness_stage (los 4
-- estadios del Investment Readiness Index™, F2) promovido/degradado por un
-- advisor vía promote_project_workflow()/demote_project_workflow()
-- (migration_v12/v20). Eso es un buen registro de F2, pero no es lo mismo
-- que un Gate del Project Structuring Framework™ (F1): F1 define 4 gates
-- ligados a cada una de sus 5 fases (Gate 1 = go/no-go tras el
-- Diagnóstico, Gate 2 = decisión de inversión tras el Business Case,
-- Gate 3 = autorización para lanzar la contratación tras el diseño de
-- Gobernanza, Gate 4 = aceptación de la solución tras la Implementación),
-- y hasta ahora la plataforma no tenía ningún objeto que registrara "quién
-- aprobó qué gate, cuándo, con qué entregables completos en ese momento".
--
-- QUÉ CAMBIA
--   1. public.project_workflow_events se extiende con dos columnas nuevas:
--      gate_number (1 a 4) y deliverables_checked (los entregables que el
--      advisor marcó como completos al aprobar ese gate). to_stage pasa a
--      ser nullable, porque esta tabla ahora registra DOS tipos de evento
--      distintos — una transición de readiness_stage (to_stage con valor,
--      gate_number null) o una aprobación de gate (gate_number con valor,
--      to_stage null) — nunca ambos a la vez ni ninguno de los dos. Las
--      filas existentes (todas transiciones de stage) no se tocan.
--   2. public.projects gana current_gate (0 a 4, default 0 = "ningún gate
--      aprobado todavía").
--   3. approve_project_gate(project_id, gate_number, note,
--      deliverables_checked) — nueva función, calco de
--      promote_project_workflow(): solo advisor/admin, nota obligatoria,
--      exige aprobar los gates en orden (no se puede saltar del Gate 1 al
--      Gate 3), actualiza projects.current_gate y deja el registro
--      auditable en project_workflow_events. A propósito NO hay
--      "reject_project_gate" todavía — igual que promote/demote, un gate
--      solo avanza; si hace falta volver atrás, es una decisión de
--      producto para una migración futura, no algo que se necesitaba para
--      el corto plazo.
--
-- Esta migración es puramente de datos/gates — no toca la UI. La sección B
-- de la hoja de ruta (project.html: sección "Gates" en el stepper con el
-- botón "Aprobar Gate N") es el paso siguiente, separado de este SQL.
-- ============================================================================

-- ---------- 1. project_workflow_events: gate_number + deliverables_checked ----------

alter table public.project_workflow_events
  alter column to_stage drop not null;

alter table public.project_workflow_events
  drop constraint if exists project_workflow_events_kind_check;
alter table public.project_workflow_events
  add constraint project_workflow_events_kind_check
  check (
    (to_stage is not null and gate_number is null)
    or (to_stage is null and gate_number is not null)
  );

alter table public.project_workflow_events
  add column if not exists gate_number int;

alter table public.project_workflow_events
  drop constraint if exists project_workflow_events_gate_number_check;
alter table public.project_workflow_events
  add constraint project_workflow_events_gate_number_check
  check (gate_number is null or gate_number between 1 and 4);

alter table public.project_workflow_events
  add column if not exists deliverables_checked text[] not null default '{}'::text[];

comment on column public.project_workflow_events.gate_number is 'Gate del Project Structuring Framework™ (F1) aprobado en este evento (1 a 4), o null si la fila es una transición de readiness_stage (F2). Exactamente uno de gate_number/to_stage es no-null — ver project_workflow_events_kind_check. Escrito solo por approve_project_gate(). Ver migration_v39_project_gates.sql.';
comment on column public.project_workflow_events.deliverables_checked is 'Entregables de la fase que el advisor marcó como completos al aprobar este gate (texto libre, p. ej. "Business Case", "Modelo Financiero a 5 años"). Vacío en las filas de transición de readiness_stage. Ver migration_v39_project_gates.sql.';

-- ---------- 2. projects.current_gate ----------

alter table public.projects
  add column if not exists current_gate int not null default 0;

alter table public.projects
  drop constraint if exists projects_current_gate_check;
alter table public.projects
  add constraint projects_current_gate_check
  check (current_gate between 0 and 4);

comment on column public.projects.current_gate is 'Último Gate del Project Structuring Framework™ (F1) aprobado (0 a 4; 0 = ningún gate aprobado todavía). Independiente de readiness_stage (F2). Escrito solo por approve_project_gate(). Ver migration_v39_project_gates.sql.';

-- ---------- 3. approve_project_gate() ----------
-- Aprueba el próximo gate en orden (current_gate + 1) para el proyecto,
-- deja el registro auditable, y devuelve el nuevo current_gate. `p_note` es
-- obligatorio, igual que en promote_project_workflow()/
-- demote_project_workflow(). `p_deliverables_checked` es opcional (default
-- array vacío) por si el advisor todavía no usa esa parte del formulario.
create or replace function public.approve_project_gate(
  p_project_id uuid,
  p_gate_number int,
  p_note text,
  p_deliverables_checked text[] default '{}'::text[]
)
returns int
language plpgsql
security definer set search_path = public
as $$
declare
  v_current_gate int;
  v_found boolean;
begin
  if not (public.is_advisor() or public.is_admin()) then
    raise exception 'Only advisors can approve a project gate.';
  end if;

  if p_note is null or trim(p_note) = '' then
    raise exception 'A comment explaining the gate approval is required.';
  end if;

  if p_gate_number is null or p_gate_number not between 1 and 4 then
    raise exception 'gate_number must be between 1 and 4.';
  end if;

  select true, current_gate into v_found, v_current_gate
  from public.projects where id = p_project_id;

  if not v_found then
    raise exception 'Project not found.';
  end if;

  if v_current_gate = 4 then
    raise exception 'This project has already completed all 4 gates.';
  end if;

  if p_gate_number <> v_current_gate + 1 then
    raise exception 'Gates must be approved in order — this project is at gate %, expected gate % next.',
      v_current_gate, v_current_gate + 1;
  end if;

  update public.projects
  set current_gate = p_gate_number, assigned_advisor_id = auth.uid(), updated_at = now()
  where id = p_project_id;

  insert into public.project_workflow_events (
    project_id, from_stage, to_stage, advisor_id, note, gate_number, deliverables_checked
  )
  values (
    p_project_id, null, null, auth.uid(), trim(p_note), p_gate_number,
    coalesce(p_deliverables_checked, '{}'::text[])
  );

  return p_gate_number;
end;
$$;

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and (
    (table_name = 'projects' and column_name = 'current_gate')
    or (table_name = 'project_workflow_events' and column_name in ('to_stage', 'gate_number', 'deliverables_checked'))
  )
order by table_name, column_name;

select proname, pg_get_function_identity_arguments(oid) as args
from pg_proc
where proname = 'approve_project_gate' and pronamespace = 'public'::regnamespace;
