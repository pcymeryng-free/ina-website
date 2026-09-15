-- ============================================================================
-- Migration v37: financiación en monto además de porcentaje
--
-- Hasta ahora, dos de los tres componentes de la mezcla de financiamiento
-- (migration_v35_financing_mix.sql) solo podían expresarse como % del
-- presupuesto total: la aplicación de un proyecto a un Programa
-- (project_programs.financing_percentage) y la fuente "otra"
-- (projects.other_financing_percentage). El tercer componente, el FSU
-- (projects.fsu_amount / fsu_percentage, migration_v33), ya admitía ambas
-- formas de forma independiente desde el principio — este cambio extiende
-- esa misma flexibilidad a los otros dos.
--
-- Convención: monto y porcentaje son independientes, ninguno excluye al
-- otro (igual que fsu_amount/fsu_percentage). INAPlatform.computeFinancing
-- Coverage() en assets/platform.js decide, para el resumen de cobertura,
-- cuál usar cuando ambos o ninguno están seteados: si hay % explícito lo
-- usa; si no, deriva un % a partir del monto y projects.budget_amount
-- (cuando ese presupuesto total está cargado); si no hay ninguno de los
-- dos, o no hay presupuesto total contra el cual convertir un monto, ese
-- componente no aporta nada al total.
--
-- CÓMO USAR
-- Ejecutar una sola vez en el SQL Editor de Supabase. Es seguro correrlo
-- más de una vez ("if not exists").
-- ============================================================================

alter table public.project_programs
  add column if not exists financing_amount numeric;

alter table public.project_programs
  drop constraint if exists project_programs_financing_amount_check;

alter table public.project_programs
  add constraint project_programs_financing_amount_check
  check (financing_amount is null or financing_amount >= 0);

comment on column public.project_programs.financing_amount is 'Monto (ARS) que esta aplicación a un Programa cubre del presupuesto del proyecto — alternativa o complemento a financing_percentage. Solo tiene sentido cuando el funding_stage del Programa embebido no es ''preparation'' (igual que financing_percentage). Ver INAPlatform.computeFinancingCoverage() en assets/platform.js.';

alter table public.projects
  add column if not exists other_financing_amount numeric;

alter table public.projects
  drop constraint if exists projects_other_financing_amount_check;

alter table public.projects
  add constraint projects_other_financing_amount_check
  check (other_financing_amount is null or other_financing_amount >= 0);

comment on column public.projects.other_financing_amount is 'Monto (ARS) cubierto por una fuente de financiamiento que no es el FSU ni un Programa registrado — alternativa o complemento a other_financing_percentage. Ver INAPlatform.computeFinancingCoverage() en assets/platform.js.';

-- ============================================================================
-- Verificación
-- ============================================================================
select table_name, column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public'
  and (
    (table_name = 'project_programs' and column_name = 'financing_amount')
    or (table_name = 'projects' and column_name = 'other_financing_amount')
  )
order by table_name, column_name;
