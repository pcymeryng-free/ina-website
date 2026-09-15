-- ============================================================================
-- migration_v49_project_programs_update_policy.sql
--
-- BUG: "No se pudo guardar la aplicación: new row violates row-level
-- security policy (USING expression) for table 'project_programs'"
--
-- QUÉ PASÓ
-- La tabla project_programs (supabase/migration_v21_program_funding_stage_
-- and_applications.sql) siempre tuvo políticas RLS de SELECT, INSERT y
-- DELETE — pero nunca se creó una de UPDATE. Esto no se notaba mientras
-- INAPlatform.applyToProgram() (el "Aplicar" de project-template.html /
-- project.html) solo insertaba filas nuevas — pero es un upsert
-- (`.upsert(payload, { onConflict: 'project_id,program_id' })`): si la
-- aplicación a ese Programa YA existía (por ejemplo, reabrir "Completar
-- template" de un Programa al que el proyecto ya estaba aplicado, que es
-- justamente el flujo de "autocompletar y Guardar y Aplicar al programa"),
-- Postgres intenta un UPDATE por debajo — y sin política de UPDATE, RLS lo
-- bloquea. El mismo problema afecta a INAPlatform.updateProjectProgramFinancing()
-- (el botón "Guardar" del % / Monto de cada Programa en la solapa de
-- Financiamiento de project.html), que hace un .update() directo.
--
-- QUÉ HACE ESTE SCRIPT
-- Agrega la política de UPDATE que faltaba, con el mismo criterio que ya
-- usan las políticas de INSERT/DELETE de esta misma tabla (y el mismo
-- patrón que projects_update_own_or_assigned_advisor /
-- fsu_scoring_update_own_or_assigned_advisor en supabase/schema.sql): el
-- dueño del proyecto o el advisor actualmente asignado a él pueden
-- actualizar cualquier fila de project_programs de ese proyecto.
-- ============================================================================

create policy "project_programs_update_own_or_assigned_advisor" on public.project_programs
  for update using (
    exists (
      select 1 from public.projects pr
      where pr.id = project_programs.project_id
        and (pr.user_id = auth.uid() or pr.assigned_advisor_id = auth.uid())
    )
  );

-- Verificación (opcional): debería devolver la política recién creada.
-- select policyname, cmd from pg_policies where tablename = 'project_programs';
