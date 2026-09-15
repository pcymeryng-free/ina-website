-- ============================================================================
-- Migration v33: nuevos atributos de proyecto
--   - Duración estimada (valor + unidad: días/meses)
--   - Prioridad (baja/media/alta)
--   - Criticidad técnica (baja/media/alta)
--   - Monto FSU solicitado/estimado
--   - Alcance FSU (texto libre)
--
-- Los 5 atributos son opcionales (nullable) — ninguno rompe proyectos ya
-- cargados. "Prioridad" y "Criticidad técnica" reutilizan la misma escala de
-- 3 niveles que framework_analysis.gap_roadmap[].priority (ver
-- PRIORITY_LABELS en assets/platform.js), para no introducir una escala
-- nueva. "Monto FSU" es un campo numérico separado de
-- shared_field_answers.monto_total_solicitado (Template de Sistema de Alerta
-- Temprana) — ese es el monto total del proyecto en general; este es
-- específicamente lo pedido/estimado al Fondo de Servicio Universal como
-- mecanismo de financiamiento (ver USF_SUGGESTION/FSU scoring). "Alcance
-- FSU" es texto libre (localidades/hogares/servicios cubiertos) — no hay un
-- listado cerrado de categorías en ninguna fuente normativa revisada hasta
-- ahora.
--
-- CÓMO USAR
-- Ejecutar una sola vez en el SQL Editor de Supabase. Es seguro correrlo más
-- de una vez (todas las cláusulas usan "if not exists").
-- ============================================================================

alter table public.projects
  add column if not exists duration_value integer check (duration_value is null or duration_value > 0),
  add column if not exists duration_unit text check (duration_unit is null or duration_unit in ('days', 'months')),
  add column if not exists priority text check (priority is null or priority in ('low', 'medium', 'high')),
  add column if not exists technical_criticality text check (technical_criticality is null or technical_criticality in ('low', 'medium', 'high')),
  add column if not exists fsu_amount numeric check (fsu_amount is null or fsu_amount >= 0),
  add column if not exists fsu_scope text;

comment on column public.projects.duration_value is 'Duración estimada del proyecto (número). Se interpreta junto con duration_unit.';
comment on column public.projects.duration_unit is 'Unidad de duration_value: days o months.';
comment on column public.projects.priority is 'Prioridad del proyecto para el organismo (low/medium/high) — misma escala que PRIORITY_LABELS en assets/platform.js.';
comment on column public.projects.technical_criticality is 'Criticidad técnica del proyecto (low/medium/high) — misma escala de 3 niveles que priority, pero eje distinto (impacto de una falla/demora técnica, no urgencia de gestión).';
comment on column public.projects.fsu_amount is 'Monto solicitado/estimado al Fondo de Servicio Universal (ARS, sin columna de moneda separada — documentar la moneda en fsu_scope o en la descripción si no es ARS).';
comment on column public.projects.fsu_scope is 'Alcance del financiamiento FSU en texto libre (localidades, hogares, servicios cubiertos, etc.) — no hay un listado cerrado de categorías definido en la normativa revisada.';

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'projects'
  and column_name in ('duration_value', 'duration_unit', 'priority', 'technical_criticality', 'fsu_amount', 'fsu_scope')
order by column_name;
