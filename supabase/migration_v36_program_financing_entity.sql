-- ============================================================================
-- Migration v36: entidad que financia un Programa (financing_entity)
--
-- public.programs.organization ya existía, pero significa otra cosa: "la
-- entidad pública o privada que PRESENTA el programa" (ej. una cooperativa,
-- un gobierno provincial) — el proponente, no necesariamente quien pone la
-- plata. Esta migración agrega financing_entity: la institución que
-- efectivamente FINANCIA el programa (ej. "Banco Interamericano de
-- Desarrollo (BID)", "CAF", "Banco de la Nación Argentina", o, para
-- programas vinculados al Fondo de Servicio Universal, "ENACOM-FSU" —
-- convención acordada con Pablo).
--
-- Texto libre, igual que organization — no hay un registro cerrado de
-- entidades financiadoras en la plataforma. Se usa en app/project.html
-- para agrupar, en la solapa de Financiamiento, todo lo relacionado al FSU
-- (el bloque de monto/alcance/porcentaje FSU del proyecto, más cualquier
-- aplicación a un Programa cuyo financing_entity sea "ENACOM-FSU") en un
-- bloque común, separado del resto de las fuentes de financiamiento — ver
-- INAPlatform.isFsuFinancingEntity() en assets/platform.js.
--
-- CÓMO USAR
-- Ejecutar una sola vez en el SQL Editor de Supabase. Es seguro correrlo
-- más de una vez ("if not exists").
-- ============================================================================

alter table public.programs
  add column if not exists financing_entity text;

comment on column public.programs.financing_entity is 'Institución que efectivamente financia este Programa (ej. "BID", "CAF", "Banco de la Nación Argentina") — distinto de organization (quien PRESENTA el programa). Para programas vinculados al Fondo de Servicio Universal, usar el valor "ENACOM-FSU" (ver INAPlatform.isFsuFinancingEntity()), que agrupa estos programas junto con el financiamiento FSU directo del proyecto en app/project.html.';

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'programs'
  and column_name = 'financing_entity';
