-- ============================================================================
-- Prefijo "FSU — " en el nombre de los Programas de financiación de ENACOM
--
-- QUÉ PASÓ
-- Todas las líneas de financiamiento de ENACOM cargadas como Programa de
-- financiación (program_role = 'financing') salen en definitiva del Fondo
-- de Servicio Universal (FSU) — TASU, FATIC (general y Mercado de
-- Capitales/Res. 1191/25), Red Mayorista Neutral y Conectividad de Interés
-- Público (C.I.P.). Pablo pidió que el nombre de esos Programas lleve el
-- prefijo "FSU —" para que quede claro de un vistazo en
-- app/financing-programs.html, en el selector "Iniciativa"/financiamiento de
-- new-project.html y en la solapa de Financiamiento de project.html (todos
-- muestran directamente el campo `name`).
--
-- QUÉ NO SE TOCA
-- - "Asistencia ante Emergencias y Catástrofes" no es financiamiento (es
--   Iniciativa/agrupador, program_role = 'umbrella' — ver
--   data_fix_cip_emergencias_program_role.sql), así que este script no la
--   toca aunque su template_key exista en el catálogo.
-- - Cualquier Programa de financiación de USTDA (no es plata de ENACOM/FSU)
--   tampoco se toca.
-- - Si un Programa ya tiene el nombre empezando con "FSU" (sea cual sea la
--   combinación de mayúsculas), el UPDATE lo salta — así el script es
--   seguro de re-ejecutar sin duplicar el prefijo.
--
-- CÓMO SE IDENTIFICAN LOS PROGRAMAS
-- Por template_key (catálogo cerrado en PROGRAM_TEMPLATE_OPTIONS,
-- assets/platform.js) para los 5 that son líneas ENACOM/FSU conocidas, más
-- un OR de respaldo por financing_entity (convención 'ENACOM-FSU', ver
-- migration_v36_program_financing_entity.sql) por si algún Programa se
-- cargó sin completar template_key. Siempre restringido a
-- program_role = 'financing'.
--
-- CÓMO USAR
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. Corré primero el SELECT de la Parte 1 y confirmá que la lista son
--    efectivamente tus Programas de financiación de ENACOM/FSU (y que no
--    aparece ninguno que no debería) antes de seguir.
-- 3. Corré la Parte 2 (el UPDATE). Es seguro re-ejecutar el script entero
--    las veces que haga falta.
-- 4. Corré el SELECT final (Parte 3) para confirmar el resultado.
-- ============================================================================


-- ============================================================================
-- PARTE 1 — Revisar ANTES de actualizar: ¿son estos los Programas de FSU?
-- ============================================================================
select id, name, program_role, financing_entity, template_key
from public.programs
where program_role = 'financing'
  and name not ilike 'FSU%'
  and (
    template_key in (
      'capital_markets_debt_financing',
      'wholesale_neutral_network_program',
      'tasu_subsidized_rate_credit',
      'fatic_general_equipment_provision',
      'conectividad_interes_publico'
    )
    or financing_entity ilike '%FSU%'
    or financing_entity ilike '%ENACOM%'
  )
order by name;


-- ============================================================================
-- PARTE 2 — Agregar el prefijo "FSU — " al nombre
-- ============================================================================
update public.programs
set name = 'FSU — ' || name
where program_role = 'financing'
  and name not ilike 'FSU%'
  and (
    template_key in (
      'capital_markets_debt_financing',
      'wholesale_neutral_network_program',
      'tasu_subsidized_rate_credit',
      'fatic_general_equipment_provision',
      'conectividad_interes_publico'
    )
    or financing_entity ilike '%FSU%'
    or financing_entity ilike '%ENACOM%'
  );


-- ============================================================================
-- PARTE 3 — Verificación final (debería devolver 0 filas: todos los
-- Programas de FSU ya empiezan con "FSU —")
-- ============================================================================
select id, name, program_role, financing_entity, template_key
from public.programs
where program_role = 'financing'
  and name not ilike 'FSU%'
  and (
    template_key in (
      'capital_markets_debt_financing',
      'wholesale_neutral_network_program',
      'tasu_subsidized_rate_credit',
      'fatic_general_equipment_provision',
      'conectividad_interes_publico'
    )
    or financing_entity ilike '%FSU%'
    or financing_entity ilike '%ENACOM%'
  );
