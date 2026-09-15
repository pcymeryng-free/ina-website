-- ============================================================================
-- migration_v48_single_fsu_program.sql
--
-- REGLA DE NEGOCIO (Pablo, sep 2026):
-- "Si un proyecto aplica a una línea del FSU no puede aplicar a otra. Solo
-- puede recibir financiación de otros programas como podría ser el BID u
-- otros."
--
-- Es decir: un proyecto puede aplicar a UNA sola línea de financiamiento
-- del FSU a la vez — "FSU — Créditos a Tasa Subsidiada (TASU)", "FSU —
-- FATIC" (general y Mercado de Capitales/Res. 1191/25), "FSU — Red
-- Mayorista Neutral" y "FSU — Conectividad de Interés Público (C.I.P.)" son
-- las 5 líneas conocidas — cualquier Programa de financiación (program_role
-- = 'financing') con financing_entity = 'ENACOM-FSU' (convención de
-- migration_v36_program_financing_entity.sql). Puede combinarse esa única
-- línea de FSU con cuantos programas de OTROS financiadores quiera (BID,
-- CAF, USTDA, DFC...) — la restricción es solo "una línea de FSU por
-- proyecto", no "un solo programa por proyecto".
--
-- QUÉ HACE ESTE SCRIPT
-- Agrega un trigger en project_programs que bloquea, a nivel de base de
-- datos, aplicar un proyecto a una segunda línea de FSU — más robusto que
-- solo validarlo en la interfaz (app/new-project.html y app/project.html
-- también se actualizaron para no ofrecer la opción en la UI, pero este
-- trigger es la garantía real: cubre inserts directos por SQL, bugs de UI
-- futuros, etc.).
--
-- ANTES DE CORRER: revisá si ya tenés algún proyecto cargado con dos o más
-- líneas de FSU aplicadas (de las pruebas de esta funcionalidad) — el
-- trigger NO toca filas existentes al crearse, pero cualquier UPDATE futuro
-- sobre una fila que ya viole la regla (aunque sea no relacionado, como
-- guardar el % de otro programa del mismo proyecto) haría fallar ese
-- UPDATE hasta que se resuelva el conflicto. Corré este SELECT primero:
--
--   select pp.project_id, array_agg(p.name) as lineas_fsu_aplicadas
--   from public.project_programs pp
--   join public.programs p on p.id = pp.program_id
--   where p.funding_stage <> 'preparation'
--     and p.financing_entity is not null
--     and trim(lower(p.financing_entity)) = 'enacom-fsu'
--   group by pp.project_id
--   having count(*) > 1;
--
-- Si devuelve filas, para cada proyecto listado entrá a su página en
-- app/project.html → sección "Project financing" → grupo FSU, y quitá
-- (🗑) todas las líneas de FSU aplicadas menos la que corresponda antes de
-- correr la Parte 2 de este script.
-- ============================================================================


-- ============================================================================
-- PARTE 1 — función + trigger
-- ============================================================================
create or replace function public.enforce_single_fsu_program()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_program record;
  conflicting_name text;
begin
  select funding_stage, financing_entity
  into new_program
  from public.programs
  where id = new.program_id;

  -- Solo aplica a aplicaciones de FINANCIAMIENTO (no de preparación/
  -- elaboración) a un Programa que sea específicamente una línea de FSU.
  -- Todo lo demás (preparación, u otros financiadores como BID/CAF/USTDA)
  -- no tiene esta restricción.
  if new_program.funding_stage = 'preparation'
     or new_program.financing_entity is null
     or trim(lower(new_program.financing_entity)) <> 'enacom-fsu' then
    return new;
  end if;

  select p.name
  into conflicting_name
  from public.project_programs pp
  join public.programs p on p.id = pp.program_id
  where pp.project_id = new.project_id
    and pp.program_id <> new.program_id
    and p.funding_stage <> 'preparation'
    and p.financing_entity is not null
    and trim(lower(p.financing_entity)) = 'enacom-fsu'
  limit 1;

  if conflicting_name is not null then
    raise exception 'Este proyecto ya está aplicado a otra línea de financiamiento del FSU ("%"). Un proyecto solo puede recibir financiamiento de UNA línea del FSU a la vez — se puede combinar con financiamiento de otros organismos (BID, CAF, USTDA, etc.) sin límite. Quitá la aplicación anterior antes de aplicar a esta.', conflicting_name;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_enforce_single_fsu_program on public.project_programs;
create trigger trg_enforce_single_fsu_program
  before insert or update on public.project_programs
  for each row
  execute function public.enforce_single_fsu_program();


-- ============================================================================
-- PARTE 2 — verificación: probá que el trigger efectivamente bloquea una
-- segunda línea de FSU (reemplazá los uuid por un proyecto y dos Programas
-- de FSU reales de tu base; debería fallar con el mensaje de arriba en el
-- segundo insert). Opcional, solo para confirmar que quedó bien instalado.
-- ============================================================================
-- insert into public.project_programs (project_id, program_id, user_id)
-- values ('<project-id>', '<fsu-program-id-1>', '<user-id>');
-- insert into public.project_programs (project_id, program_id, user_id)
-- values ('<project-id>', '<fsu-program-id-2>', '<user-id>'); -- debería fallar
