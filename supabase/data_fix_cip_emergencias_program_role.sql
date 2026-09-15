-- ============================================================================
-- Corrección de rol — Conectividad de Interés Público (C.I.P.) y
-- Asistencia ante Emergencias y Catástrofes
--
-- QUÉ PASÓ
-- Estos dos Programas de ENACOM quedaron con el program_role cruzado
-- respecto de lo que Pablo indicó (ver migration_v43_program_role.sql):
--
-- - "Conectividad de Interés Público" (C.I.P., Res. 1072/24) — es una
--   FUENTE DE FINANCIAMIENTO real (habilita servicios TIC como insumo de
--   planes de educación, salud, seguridad, etc. de organismos nacionales,
--   provinciales, municipales o del propio ENACOM) → debería tener
--   program_role = 'financing' y aparecer en app/financing-programs.html.
--   Quedó como 'umbrella', apareciendo en app/programs.html.
--
-- - "Asistencia ante Emergencias y Catástrofes" (Res. 449/21, act. Res.
--   323/25) — según lo indicado por Pablo, debería tratarse como Iniciativa/
--   agrupador (program_role = 'umbrella') y aparecer en app/programs.html,
--   no en app/financing-programs.html.
--   Quedó como 'financing'.
--
-- CÓMO SE IDENTIFICAN LOS PROGRAMAS
-- Ambos Programas se dan de alta a través de app/new-program.html eligiendo
-- su template_key (catálogo cerrado en PROGRAM_TEMPLATE_OPTIONS,
-- assets/platform.js) — 'conectividad_interes_publico' y
-- 'emergencias_catastrofes' respectivamente. El WHERE de este script
-- filtra por ese template_key exacto, más un OR de respaldo por nombre
-- (con "_" como comodín de un carácter, para cubrir variantes con/sin
-- tilde) por si el Programa se cargó sin completar ese campo.
--
-- CÓMO USAR
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. Corré primero el SELECT de la Parte 1 y confirmá que devuelve
--    exactamente los dos Programas esperados (uno por nombre) antes de
--    seguir — si no aparece alguno, avisame el nombre exacto que tiene en
--    la plataforma y ajusto el filtro.
-- 3. Corré la Parte 2 (los dos UPDATE). Es seguro re-ejecutar el script
--    entero las veces que haga falta.
-- 4. Corré el SELECT final (Parte 3) para confirmar el resultado.
-- ============================================================================


-- ============================================================================
-- PARTE 1 — Revisar ANTES de actualizar: ¿son estos los dos Programas?
-- ============================================================================
select id, name, program_role, funding_stage, template_key
from public.programs
where template_key in ('conectividad_interes_publico', 'emergencias_catastrofes')
   or name ilike '%Conectividad%de%Inter_s%P_blico%'
   or name ilike '%Emergencias%y%Cat_strofes%'
order by name;


-- ============================================================================
-- PARTE 2 — Corregir el rol de cada uno
-- ============================================================================

-- Conectividad de Interés Público (C.I.P.) → es financiamiento real.
update public.programs
set program_role = 'financing'
where template_key = 'conectividad_interes_publico'
   or name ilike '%Conectividad%de%Inter_s%P_blico%';

-- Asistencia ante Emergencias y Catástrofes → es Iniciativa/agrupador.
update public.programs
set program_role = 'umbrella'
where template_key = 'emergencias_catastrofes'
   or name ilike '%Emergencias%y%Cat_strofes%';


-- ============================================================================
-- PARTE 3 — Verificación final
-- ============================================================================
select id, name, program_role, funding_stage, template_key
from public.programs
where template_key in ('conectividad_interes_publico', 'emergencias_catastrofes')
   or name ilike '%Conectividad%de%Inter_s%P_blico%'
   or name ilike '%Emergencias%y%Cat_strofes%'
order by name;
