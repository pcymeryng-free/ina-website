-- ============================================================================
-- Completa monto_total_solicitado en el Template de AlertAR
-- Fuente: Pasos para la ET.pdf (paso 5 - "Finalización y remisión para
-- licitación"), NO el pliego PLIEG-2026-63921688 (que no publica
-- presupuesto).
--
-- QUE HACE
-- 1. Mezcla (merge, sin tocar el resto) la clave "monto_total_solicitado"
--    en projects.shared_field_answers — el único campo del Template de
--    Sistema de Alerta Temprana que había quedado vacío por falta de dato
--    en el pliego original.
-- 2. Inserta la misma línea dentro de projects.description, justo después
--    de "Organismo ejecutor / contraparte" (el lugar exacto donde
--    aparecería si compileTemplateAnswers() regenerara la descripción
--    completa desde cero), usando un replace() de texto en vez de
--    reescribir toda la descripción — así no corre el riesgo de pisar
--    cambios que hayas hecho a mano en el medio. Si por algún motivo el
--    texto de referencia no aparece tal cual en tu description actual
--    (por ejemplo si ya la editaste), el replace() simplemente no hace
--    nada ahí y el UPDATE del punto 1 igual se aplica — en ese caso
--    agregá la línea a mano donde corresponda.
--
-- CÓMO USAR
-- EDITAR el email si no es 'pcymeryng@gmail.com'. El proyecto "Sistema de
-- Alerta Temprana - AlertAR" tiene que existir ya.
-- ============================================================================

update public.projects
set
  shared_field_answers = coalesce(shared_field_answers, '{}'::jsonb)
    || jsonb_build_object(
      'monto_total_solicitado',
      'ARS 12.000 millones (estimación presupuestaria basada en presupuestos de mercado previos, determinada al finalizar la elaboración de las ET; no publicada en el pliego de licitación PLIEG-2026-63921688)'
    ),

  description = replace(
    description,
    '- Roles y responsabilidades institucionales:',
    '- Monto total solicitado y moneda: ARS 12.000 millones (estimacion presupuestaria basada en presupuestos de mercado previos, determinada al finalizar la elaboracion de las ET; no publicada en el pliego de licitacion PLIEG-2026-63921688).' || chr(10)
    || '- Roles y responsabilidades institucionales:'
  ),

  updated_at = now()

where name = 'Sistema de Alerta Temprana - AlertAR'
  -- EDITAR: email de la cuenta dueña del proyecto, si no es esta.
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ============================================================================
-- Verificación
-- ============================================================================
select
  id,
  name,
  shared_field_answers -> 'monto_total_solicitado' as monto_total_solicitado,
  position('Monto total solicitado' in description) > 0 as description_actualizada,
  updated_at
from public.projects
where name = 'Sistema de Alerta Temprana - AlertAR'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ============================================================================
-- NOTA
-- Si "description_actualizada" da false en la verificación de arriba, el
-- replace() no encontró el texto exacto "- Roles y responsabilidades
-- institucionales:" en tu description actual (probablemente porque la
-- editaste desde la plataforma). shared_field_answers sí quedó
-- actualizado igual, así que la próxima vez que abras el Template de
-- Sistema de Alerta Temprana desde la plataforma vas a ver el monto ya
-- precargado — solo falta que la descripción libre lo refleje, a mano o
-- regenerando el template.
-- ============================================================================
