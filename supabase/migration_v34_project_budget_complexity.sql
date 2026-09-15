-- ============================================================================
-- Migration v34: presupuesto total y complejidad del proyecto
--   - Presupuesto total (budget_amount) — costo total del proyecto,
--     independiente de la fuente de financiamiento.
--   - Complejidad (complexity) — baja/media/alta.
--
-- Por qué son campos nuevos y no una reutilización de los de
-- migration_v33_project_attributes.sql:
--   - budget_amount es DISTINTO de fsu_amount (que ya existía): fsu_amount
--     es específicamente lo pedido/estimado al Fondo de Servicio Universal
--     como mecanismo de financiamiento; budget_amount es el costo TOTAL del
--     proyecto sin importar de dónde sale la plata. Un proyecto puede tener
--     budget_amount sin tener fsu_amount (no todos son elegibles a FSU) —
--     por ejemplo AlertAR: budget_amount ≈ ARS 12.000.000.000, fsu_amount
--     null (no es financiamiento FSU).
--   - complexity es un eje nuevo, distinto de priority y de
--     technical_criticality (ambos de la migración v33): "complejidad" acá
--     se entiende como la dificultad/enredo del proyecto en sí (cantidad de
--     partes móviles, interdependencias, tecnología no probada, actores
--     involucrados), no la urgencia de gestión (priority) ni el impacto de
--     una falla técnica (technical_criticality). Reutiliza la misma escala
--     de 3 niveles (low/medium/high) que esos dos por consistencia visual
--     en toda la plataforma (mismos badges, mismos colores).
--
-- CÓMO USAR
-- Ejecutar una sola vez en el SQL Editor de Supabase. Es seguro correrlo más
-- de una vez (todas las cláusulas usan "if not exists").
-- ============================================================================

alter table public.projects
  add column if not exists budget_amount numeric check (budget_amount is null or budget_amount >= 0),
  add column if not exists complexity text check (complexity is null or complexity in ('low', 'medium', 'high'));

comment on column public.projects.budget_amount is 'Presupuesto/costo total estimado del proyecto (ARS, sin columna de moneda separada) — independiente de la fuente de financiamiento. Distinto de fsu_amount (migration_v33), que es específicamente el monto pedido al Fondo de Servicio Universal.';
comment on column public.projects.complexity is 'Complejidad del proyecto (low/medium/high) — dificultad/enredo intrínseco (partes móviles, interdependencias, tecnología no probada), eje distinto de priority (urgencia de gestión) y technical_criticality (impacto de una falla técnica). Misma escala de 3 niveles que esos dos por consistencia.';

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'projects'
  and column_name in ('budget_amount', 'complexity')
order by column_name;
