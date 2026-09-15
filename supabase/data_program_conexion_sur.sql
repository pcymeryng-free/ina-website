-- ============================================================================
-- Alta de Programa de Financiación — "Conexión Sur" (BID)
--
-- QUÉ ES
-- "Conexión Sur" (South Connection) es un programa regional del BID,
-- presentado el 27 de marzo de 2025 durante las Reuniones Anuales de las
-- Asambleas de Gobernadores del BID y BID Invest en Santiago, Chile.
-- Gobernadores y representantes de Argentina, Bolivia, Brasil, Chile,
-- Colombia, Ecuador, Guyana, Paraguay, Perú, Surinam y Uruguay firmaron
-- junto al presidente del BID, Ilan Goldfajn, una declaración de apoyo al
-- programa. Se apoya en tres pilares: (1) conectividad — mejora de rutas,
-- puertos, vías navegables, redes eléctricas y DIGITALES; (2) cadenas de
-- valor regionales y globales; (3) fortalecimiento regulatorio e
-- institucional. Amplía la alianza "Rutas de Integración" (Acuerdo de
-- Brasilia, mayo 2023), con cofinanciamiento posible junto a FONPLATA,
-- BNDES y CAF.
--
-- Es, por lo tanto, un PROGRAMA DE FINANCIACIÓN real (program_role =
-- 'financing', ver migration_v43_program_role.sql) — no un agrupador
-- multi-proyecto — al que un proyecto de conectividad digital transfronteriza
-- (ej. cables submarinos, troncales de fibra, corredores digitales
-- ferroviarios/viales) podría aplicar como fuente de financiamiento, igual
-- que FSU, BID (línea general), CAF o USTDA. Aparecerá en
-- app/financing-programs.html, no en app/programs.html.
--
-- Fuentes:
-- https://www.iadb.org/en/news/idb-launches-south-connection-regional-program
-- https://cms.hacienda.cl/hacienda/assets/documento/descargar/e5f67f9518e76/1743263156
--
-- CÓMO USAR
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. Si todavía no corriste supabase/migration_v43_program_role.sql,
--    corrélo primero (agrega la columna program_role que este archivo usa).
-- 3. En la línea marcada "EDITAR" reemplazá el email por el de la cuenta
--    de la plataforma INA que va a figurar como propietaria del programa
--    (tiene que ser una cuenta advisor o admin, ya registrada en
--    public.profiles — la creación de Programas está restringida a esos
--    roles).
-- 4. Ejecutá el resto del script. Al final corre un SELECT que te muestra
--    el programa creado, para confirmar.
-- ============================================================================

insert into public.programs (
  user_id,
  name,
  organization,
  organization_type,
  financing_entity,
  funding_stage,
  program_role,
  description
)
values (
  -- EDITAR: email de la cuenta (advisor/admin) que debe figurar como dueña
  -- del programa.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'Conexión Sur',

  'Banco Interamericano de Desarrollo (BID)',

  'public',

  'Banco Interamericano de Desarrollo (BID)',

  'financing',

  'financing',

$pdesc$Programa regional del BID ("South Connection"), presentado el 27 de marzo de 2025 en las Reuniones Anuales de las Asambleas de Gobernadores del BID y BID Invest (Santiago, Chile), con el apoyo de Argentina, Bolivia, Brasil, Chile, Colombia, Ecuador, Guyana, Paraguay, Perú, Surinam y Uruguay. Tres pilares: (1) conectividad — rutas, puertos, vías navegables, redes eléctricas y digitales; (2) cadenas de valor regionales y globales; (3) fortalecimiento regulatorio e institucional. Amplía la alianza "Rutas de Integración" (Acuerdo de Brasilia, mayo 2023), con posible cofinanciamiento junto a FONPLATA, BNDES y CAF.

Fuente: IDB, "IDB Launches 'South Connection' Regional Program" (27/03/2025) — https://www.iadb.org/en/news/idb-launches-south-connection-regional-program$pdesc$
);

-- ============================================================================
-- Verificación
-- ============================================================================
select id, name, organization, financing_entity, funding_stage, program_role
from public.programs
where name = 'Conexión Sur';
