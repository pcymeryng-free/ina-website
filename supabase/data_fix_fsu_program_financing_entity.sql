-- ============================================================================
-- financing_entity = 'ENACOM-FSU' en los Programas de financiación del FSU
--
-- QUÉ PASÓ
-- Pablo reportó que, en la solapa de Financiamiento de un proyecto
-- (app/project.html), la aplicación al programa "FSU — Créditos a Tasa
-- Subsidiada (TASU)" aparece agrupada bajo "Other Financing Source" en vez
-- de bajo "Universal Service Fund (FSU)" — a pesar de que el nombre del
-- Programa dice explícitamente "FSU". El agrupamiento de la solapa de
-- Financiamiento NO mira el nombre del Programa: mira exclusivamente la
-- columna programs.financing_entity, comparándola (case/whitespace-
-- insensitive) contra el string exacto "ENACOM-FSU" — ver
-- INAPlatform.isFsuFinancingEntity() en assets/platform.js y
-- migration_v36_program_financing_entity.sql. Cuando se agregó el prefijo
-- "FSU — " al nombre de estos 5 Programas (ver
-- data_fix_fsu_program_names_prefix.sql) solo se tocó la columna `name`, no
-- `financing_entity` — por eso el nombre dice "FSU" pero el agrupamiento
-- (que corre en base a `financing_entity`) sigue tratándolos como "otra
-- fuente".
--
-- OJO — esto NO es lo mismo que el total de cobertura de financiamiento
-- (la barra "% del presupuesto cubierto" arriba de la lista de Programas).
-- Ese total SÍ suma el % de cada Programa financiero sin importar en qué
-- grupo visual aparezca (ver INAPlatform.computeFinancingCoverage()) — pero
-- solo si ese % (o Monto) ya fue guardado con el botón "Save" de la fila
-- del Programa. Si en tu proyecto el campo "% of budget"/"Amount (ARS)" de
-- TASU está vacío, hace falta completarlo y guardarlo aparte — este script
-- solo corrige el AGRUPAMIENTO visual (FSU vs. Otra fuente), no carga
-- ningún porcentaje por vos.
--
-- QUÉ NO SE TOCA
-- - "Asistencia ante Emergencias y Catástrofes" no es financiamiento (es
--   Iniciativa/agrupador, program_role = 'umbrella'), así que este script
--   no la toca.
-- - Cualquier Programa de financiación de USTDA (no es plata de ENACOM/FSU)
--   tampoco se toca.
-- - Si un Programa ya tiene financing_entity = 'ENACOM-FSU' (cualquier
--   combinación de mayúsculas/espacios), el UPDATE lo salta — así el
--   script es seguro de re-ejecutar sin romper nada.
--
-- CÓMO SE IDENTIFICAN LOS PROGRAMAS
-- Mismo criterio que data_fix_fsu_program_names_prefix.sql: los 5
-- template_key conocidos de líneas ENACOM/FSU (catálogo cerrado en
-- PROGRAM_TEMPLATE_OPTIONS, assets/platform.js), más un OR de respaldo por
-- nombre ("FSU —" al inicio, ya aplicado por el script anterior) por si
-- algún Programa se cargó sin completar template_key. Siempre restringido
-- a program_role = 'financing'.
--
-- CÓMO USAR
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. Corré primero el SELECT de la Parte 1 y confirmá que la lista son
--    efectivamente tus Programas de financiación de ENACOM/FSU (y que no
--    aparece ninguno que no debería) antes de seguir.
-- 3. Corré la Parte 2 (el UPDATE). Es seguro re-ejecutar el script entero
--    las veces que haga falta.
-- 4. Corré el SELECT final (Parte 3) para confirmar el resultado.
-- 5. Recargá app/project.html — "FSU — Créditos a Tasa Subsidiada (TASU)"
--    (y los otros 4, si tenían el mismo problema) debería pasar a aparecer
--    bajo "Universal Service Fund (FSU)". Si además querés que cuente en
--    el % de cobertura, completá y guardá su "% of budget" o "Amount
--    (ARS)" en esa misma fila.
-- ============================================================================


-- ============================================================================
-- PARTE 1 — Revisar ANTES de actualizar: ¿a estos Programas les falta
-- financing_entity = 'ENACOM-FSU'?
-- ============================================================================
select id, name, program_role, financing_entity, template_key
from public.programs
where program_role = 'financing'
  and (financing_entity is null or trim(lower(financing_entity)) <> 'enacom-fsu')
  and (
    template_key in (
      'capital_markets_debt_financing',
      'wholesale_neutral_network_program',
      'tasu_subsidized_rate_credit',
      'fatic_general_equipment_provision',
      'conectividad_interes_publico'
    )
    or name ilike 'FSU —%'
    or name ilike 'FSU -%'
  )
order by name;


-- ============================================================================
-- PARTE 2 — Setear financing_entity = 'ENACOM-FSU'
-- ============================================================================
update public.programs
set financing_entity = 'ENACOM-FSU'
where program_role = 'financing'
  and (financing_entity is null or trim(lower(financing_entity)) <> 'enacom-fsu')
  and (
    template_key in (
      'capital_markets_debt_financing',
      'wholesale_neutral_network_program',
      'tasu_subsidized_rate_credit',
      'fatic_general_equipment_provision',
      'conectividad_interes_publico'
    )
    or name ilike 'FSU —%'
    or name ilike 'FSU -%'
  );


-- ============================================================================
-- PARTE 3 — Verificación final (debería devolver 0 filas: todos los
-- Programas de FSU ya tienen financing_entity = 'ENACOM-FSU')
-- ============================================================================
select id, name, program_role, financing_entity, template_key
from public.programs
where program_role = 'financing'
  and (financing_entity is null or trim(lower(financing_entity)) <> 'enacom-fsu')
  and (
    template_key in (
      'capital_markets_debt_financing',
      'wholesale_neutral_network_program',
      'tasu_subsidized_rate_credit',
      'fatic_general_equipment_provision',
      'conectividad_interes_publico'
    )
    or name ilike 'FSU —%'
    or name ilike 'FSU -%'
  );
