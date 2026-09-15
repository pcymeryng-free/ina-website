-- ============================================================================
-- Migration v43: Rol de Programa — financiación vs. agrupador multi-proyecto
-- Run this ONCE in your EXISTING Supabase project: Dashboard → SQL Editor →
-- New query → paste this whole file → Run. Es seguro correrlo más de una
-- vez ("if not exists" / valores por defecto en todo lo que sigue).
--
-- PROBLEMA QUE RESUELVE
-- Hoy public.programs tiene un solo campo de clasificación, funding_stage
-- ('preparation' | 'financing'), pensado exclusivamente para programas que
-- SON una fuente de financiamiento (FSU, BID, CAF, USTDA, DFC, TASU...).
-- Pero desde el principio (ver el propio comentario histórico en
-- INAPlatform.listPrograms) un Programa también se usa para agrupar varios
-- proyectos financiados de forma independiente bajo una misma iniciativa —
-- por ejemplo "Atlántico-Pacífico" (EPECH), que reúne un troncal de fibra,
-- un cable submarino, un datacenter y la obra de amarre como CUATRO
-- proyectos separados, cada uno con su propio financiamiento. Ese programa
-- quedó cargado con funding_stage = 'financing' por default (ver
-- supabase/data_pipeline_proyectos_planilla_ago2026.sql), lo que hace que
-- hoy aparezca — incorrectamente — en el selector de "Financiamiento del
-- proyecto" de new-project.html, como si Atlántico-Pacífico en sí mismo
-- pusiera plata, cuando en realidad no financia nada: solo agrupa.
--
-- QUÉ CAMBIA
--   1. public.programs.program_role — nueva columna: 'financing' (default,
--      el comportamiento que ya tenían todos los programas existentes) o
--      'umbrella' (agrupador multi-proyecto, no es en sí una fuente de
--      financiamiento).
--   2. Reclasifica 'Atlántico-Pacífico' como 'umbrella' — es el único caso
--      real cargado hoy en la plataforma. También reclasifica, como red de
--      seguridad, cualquier otro programa que ya esté siendo usado como
--      "programa paraguas" (projects.program_id) de 2 o más proyectos —
--      la señal más fuerte de que un programa cumple ese rol y no el de
--      financiar.
--   3. assets/platform.js / app/new-project.html / app/project.html filtran
--      ahora los selectores de financiamiento (preparación y ejecución)
--      para excluir programas 'umbrella', y el selector de "Programa"
--      (paraguas) de new-project.html para mostrar SOLO programas
--      'umbrella' — ver comentarios en esos archivos.
--
-- QUÉ NO CAMBIA
-- funding_stage se mantiene tal cual (preparation/financing) — sigue
-- siendo relevante para programas con program_role = 'financing'. Para un
-- programa 'umbrella', funding_stage queda en su valor por default pero
-- se ignora en toda la UI (un agrupador no financia nada él mismo).
-- ============================================================================

alter table public.programs
  add column if not exists program_role text not null default 'financing'
    check (program_role in ('financing', 'umbrella'));

comment on column public.programs.program_role is
  '''financing'' (default) = el programa es en sí una fuente de financiamiento (FSU, BID, CAF, USTDA...), seleccionable en los pickers de preparación/financiamiento de un proyecto. ''umbrella'' = el programa solo agrupa varios proyectos financiados de forma independiente bajo una misma iniciativa (ej. Atlántico-Pacífico: fibra + cable submarino + datacenter), y por lo tanto NO aparece como opción de financiamiento — solo como "Programa" (paraguas) al dar de alta un proyecto. Ver migration_v43_program_role.sql.';

-- ----------------------------------------------------------------------------
-- Backfill — reclasifica los programas que hoy ya cumplen el rol de
-- agrupador, para que la UI actualizada los siga mostrando donde
-- corresponde en vez de hacerlos desaparecer de golpe del selector de
-- "Programa" (paraguas).
-- ----------------------------------------------------------------------------

-- Caso conocido: Atlántico-Pacífico (EPECH) — ver
-- supabase/data_pipeline_proyectos_planilla_ago2026.sql.
update public.programs
set program_role = 'umbrella'
where name = 'Atlántico-Pacífico';

-- Red de seguridad: cualquier programa ya usado como "programa paraguas"
-- (projects.program_id) por 2 o más proyectos casi con certeza cumple ese
-- rol, no el de financiar — se reclasifica automáticamente aunque no se
-- lo haya nombrado arriba explícitamente. Un programa usado como paraguas
-- de un solo proyecto se deja como estaba (podría ser, en cambio, un
-- programa de financiamiento al que ese único proyecto también aplicó).
update public.programs
set program_role = 'umbrella'
where program_role = 'financing'
  and id in (
    select program_id
    from public.projects
    where program_id is not null
    group by program_id
    having count(*) >= 2
  );

-- ============================================================================
-- Verificación
-- ============================================================================
select id, name, program_role, funding_stage
from public.programs
order by program_role, name;
