-- ============================================================================
-- Migration v38: montos en USD + tipo de cambio para presupuesto y FSU
--
-- Problema que resuelve: budget_amount y fsu_amount asumen pesos argentinos
-- (no tienen columna de moneda propia — ver comentarios originales en
-- schema.sql). Muchos documentos de origen (pliegos, carpetas técnicas,
-- planillas de seguimiento de proyectos) cotizan sus cifras en dólares.
-- Hasta ahora, cargar esas cifras exigía convertirlas a pesos "a ojo" (con
-- el riesgo de cargar un monto en USD como si fuera ARS, un error de
-- escala de ~3 órdenes de magnitud) o dejarlas afuera de los campos
-- estructurados, documentándolas solo como texto libre en la descripción.
--
-- Esta migración agrega 4 columnas a public.projects:
--   - budget_amount_usd numeric   — presupuesto total, en USD
--   - fsu_amount_usd numeric      — monto FSU, en USD
--   - exchange_rate numeric       — tipo de cambio ARS por USD (compartido
--                                    entre los dos campos USD de arriba)
--   - exchange_rate_date date     — fecha en que se tomó ese tipo de cambio
--
-- Convención: los campos USD y los campos ARS existentes (budget_amount,
-- fsu_amount) son independientes — ninguno se calcula ni se sobreescribe
-- automáticamente a partir del otro. exchange_rate solo se usa para
-- mostrar en la interfaz un equivalente en pesos "de referencia" (ver
-- INAPlatform.usdToArs() en assets/platform.js); si el usuario quiere que
-- ese equivalente quede persistido en budget_amount/fsu_amount, tiene que
-- guardarlo explícitamente (la plataforma no lo hace sola).
--
-- CÓMO USAR
-- Ejecutar una sola vez en el SQL Editor de Supabase. Es seguro correrlo
-- más de una vez ("if not exists").
-- ============================================================================

alter table public.projects
  add column if not exists fsu_amount_usd numeric;

alter table public.projects
  drop constraint if exists projects_fsu_amount_usd_check;

alter table public.projects
  add constraint projects_fsu_amount_usd_check
  check (fsu_amount_usd is null or fsu_amount_usd >= 0);

comment on column public.projects.fsu_amount_usd is 'Monto FSU en USD — independiente de fsu_amount (ARS). Ver migration_v38_usd_amounts.sql.';

alter table public.projects
  add column if not exists budget_amount_usd numeric;

alter table public.projects
  drop constraint if exists projects_budget_amount_usd_check;

alter table public.projects
  add constraint projects_budget_amount_usd_check
  check (budget_amount_usd is null or budget_amount_usd >= 0);

comment on column public.projects.budget_amount_usd is 'Presupuesto total en USD — independiente de budget_amount (ARS). Ver migration_v38_usd_amounts.sql.';

alter table public.projects
  add column if not exists exchange_rate numeric;

alter table public.projects
  drop constraint if exists projects_exchange_rate_check;

alter table public.projects
  add constraint projects_exchange_rate_check
  check (exchange_rate is null or exchange_rate > 0);

comment on column public.projects.exchange_rate is 'Tipo de cambio ARS por USD, usado para calcular en la interfaz un equivalente en pesos de budget_amount_usd/fsu_amount_usd. Compartido entre ambos campos USD. Nunca se escribe automáticamente. Ver migration_v38_usd_amounts.sql.';

alter table public.projects
  add column if not exists exchange_rate_date date;

comment on column public.projects.exchange_rate_date is 'Fecha en que se tomó el exchange_rate cargado — para juzgar cuán desactualizado está. Ver migration_v38_usd_amounts.sql.';

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and table_name = 'projects'
  and column_name in ('budget_amount_usd', 'fsu_amount_usd', 'exchange_rate', 'exchange_rate_date')
order by column_name;
