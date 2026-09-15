-- ============================================================================
-- Migration v35: mezcla de fuentes de financiamiento (financing mix)
--
-- Hasta ahora la plataforma modelaba el financiamiento de un proyecto como
-- si viniera de UNA sola fuente a la vez: el monto pedido al FSU
-- (fsu_amount/fsu_scope, migration_v33) por un lado, y la lista de
-- Programas a los que un proyecto se "aplica" (project_programs,
-- migration_v21) por otro — pero sin ningún dato de CUÁNTO cubre cada uno.
--
-- En la práctica un proyecto puede financiarse con una combinación de
-- fuentes, cada una cubriendo una porción del presupuesto total
-- (projects.budget_amount, migration_v34), sin superar el 100%:
--   - El FSU puede cubrir una PRIMERA ETAPA o alcance parcial del proyecto
--     (ya había un campo de texto libre para esto: fsu_scope) — ahora
--     además se puede indicar qué PORCENTAJE del presupuesto total
--     representa esa etapa.
--   - Una o varias fuentes ADICIONALES (Programas ya registrados en la
--     plataforma — BID, CAF, TASU, líneas de crédito, etc., aplicados vía
--     project_programs) pueden cada una cubrir un porcentaje adicional.
--   - Puede quedar un resto financiado por una fuente NO registrada como
--     Programa en la plataforma (fondos propios del proponente, una línea
--     de crédito bancaria puntual, etc. — ver el caso real de CEPA Punta
--     Alta: crédito del Banco Nación + "fondos propios de la Cooperativa"
--     para el saldo). Se modela como un campo de texto + porcentaje suelto,
--     sin crear un Programa formal para algo que no lo es.
--
-- Qué agrega esta migración:
--   1. public.projects.fsu_percentage — % del presupuesto total que
--      cubriría el financiamiento FSU (complementa a fsu_amount/fsu_scope,
--      que ya existían).
--   2. public.project_programs.financing_percentage — % del presupuesto
--      total que cubre ESA aplicación a un Programa en particular. Solo
--      tiene sentido para aplicaciones en etapa 'financing' (programs.
--      funding_stage) — un Programa de preparación (ej. USTDA) financia
--      elaborar el proyecto, no una porción de su costo de implementación,
--      así que este campo queda sin usar en esas filas.
--   3. public.projects.other_financing_percentage +
--      other_financing_notes — el resto del presupuesto cubierto por una
--      fuente que NO es ni el FSU ni un Programa registrado (fondos
--      propios, una línea de crédito puntual, etc.), con una breve
--      descripción en texto libre.
--
-- No se agrega ninguna restricción de base de datos que obligue a que
-- fsu_percentage + suma(financing_percentage de las aplicaciones en etapa
-- 'financing') + other_financing_percentage sea <= 100 — esa suma cruza dos
-- tablas y se completa de a poco (un proyecto puede guardarse con la
-- mezcla todavía incompleta), así que la validación es informativa en la
-- UI (app/project.html), no un CHECK constraint. Cada porcentaje individual
-- sí queda acotado a 0-100.
--
-- CÓMO USAR
-- Ejecutar una sola vez en el SQL Editor de Supabase. Es seguro correrlo
-- más de una vez (todas las cláusulas usan "if not exists").
-- ============================================================================

alter table public.projects
  add column if not exists fsu_percentage numeric check (fsu_percentage is null or (fsu_percentage >= 0 and fsu_percentage <= 100)),
  add column if not exists other_financing_percentage numeric check (other_financing_percentage is null or (other_financing_percentage >= 0 and other_financing_percentage <= 100)),
  add column if not exists other_financing_notes text;

alter table public.project_programs
  add column if not exists financing_percentage numeric check (financing_percentage is null or (financing_percentage >= 0 and financing_percentage <= 100));

comment on column public.projects.fsu_percentage is '% del presupuesto total (budget_amount) que cubriría el financiamiento del FSU — complementa a fsu_amount (monto absoluto) y fsu_scope (descripción textual del alcance, ej. "primera etapa"). Todos opcionales e independientes entre sí.';
comment on column public.project_programs.financing_percentage is '% del presupuesto total del proyecto que cubre esta aplicación a un Programa. Solo relevante cuando programs.funding_stage de la fila embebida es distinto de ''preparation'' — un Programa de preparación financia elaborar el proyecto, no una porción de su costo de implementación.';
comment on column public.projects.other_financing_percentage is '% del presupuesto total cubierto por una fuente de financiamiento que NO es el FSU ni un Programa registrado en la plataforma (fondos propios, una línea de crédito puntual no modelada como Programa, etc.).';
comment on column public.projects.other_financing_notes is 'Descripción breve de la fuente de financiamiento "otra" (ej. "Fondos propios de la Cooperativa", "Línea de crédito Banco Nación no vinculada a un Programa registrado").';

-- ============================================================================
-- Verificación
-- ============================================================================
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'projects'
  and column_name in ('fsu_percentage', 'other_financing_percentage', 'other_financing_notes')
order by column_name;

select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'project_programs'
  and column_name = 'financing_percentage';
