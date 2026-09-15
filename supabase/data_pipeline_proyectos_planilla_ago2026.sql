-- ============================================================================
-- Pipeline de proyectos — planilla "proyectos INACOM - Hoja 1 (1).pdf"
-- Fuente: planilla de seguimiento de proyectos subida por Pablo, ago. 2026
--         (19 filas: cruces/corredores de fibra, cables submarinos, FWA 5G,
--         datacenters de IA, satelital, espectro).
--
-- QUÉ HACE ESTE ARCHIVO
-- 1) Completa el proyecto YA CARGADO que aparece en la fila 1 de la planilla
--    (Proyecto Cruce Transandino / Cirion), cargando su presupuesto en USD.
-- 2) Crea el Programa "Atlántico-Pacífico" (EPECH) y sus 5 proyectos
--    componentes (filas 4 a 8 de la planilla) — mismo patrón que otros
--    corredores multi-componente de la plataforma (un Programa agrupando
--    varios proyectos de un mismo proponente, cada uno financiado por
--    separado).
-- 3) Carga los 13 proyectos nuevos restantes de la planilla como proyectos
--    independientes (filas 2, 3, 9-19).
--
-- IMPORTANTE — MONEDA (leer antes de correr)
-- Todos los montos de la planilla de origen están en DÓLARES (USD, columnas
-- "FSU Monto" y "USD Total"). Este archivo usa las columnas nuevas
-- budget_amount_usd / fsu_amount_usd (ver
-- supabase/migration_v38_usd_amounts.sql) para cargarlos tal cual vienen,
-- en vez de convertirlos "a ojo" a los campos en pesos (budget_amount /
-- fsu_amount) — eso hubiera arriesgado un error de escala de ~3 órdenes de
-- magnitud. La columna exchange_rate (ARS por USD, compartida por ambos
-- montos en dólares de cada proyecto) queda en null en todos los casos:
-- no hay un tipo de cambio confirmado para estas cifras. Si confirmás uno,
-- avisame y genero el UPDATE para completarlo — la plataforma entonces
-- muestra automáticamente un equivalente en pesos calculado (no lo
-- convierte ella sola, ni pisa budget_amount/fsu_amount).
--
-- Dos proyectos (CALF y Internet Service, filas 9 y 10) tienen una "F"
-- marcada como "ON" en la planilla en vez de "FSU" — se interpretó como
-- financiamiento vía Obligación Negociable y se cargó en
-- other_financing_notes en vez de en los campos FSU.
--
-- Rangos de presupuesto: cuando la planilla da un rango en vez de un
-- número (filas 5-8, el corredor Atlántico-Pacífico), se cargó el punto
-- medio en budget_amount_usd y el rango completo queda documentado en la
-- descripción, para no perder esa información.
--
-- OTRA SALVEDAD — filas muy escuetas
-- Las filas 2, 3, 10, 16, 17, 18 y 19 de la planilla casi no tienen datos
-- (sin tecnología, sin presupuesto, sin geografía detallada en varios
-- casos) — se cargaron igual para no perder el lugar en el pipeline, con
-- la información mínima disponible y una nota aclarando que falta carpeta
-- técnica. Convendría que Pablo/los proponentes las completen después
-- desde app/new-project.html.
--
-- CÓMO USAR ESTE ARCHIVO
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. Corré primero supabase/migration_v38_usd_amounts.sql si todavía no lo
--    corriste (agrega las columnas budget_amount_usd/fsu_amount_usd/
--    exchange_rate/exchange_rate_date que este archivo usa).
-- 3. En cada línea marcada "EDITAR" reemplazá el email por el de la cuenta
--    de la plataforma INA que va a figurar como propietaria de estos
--    proyectos/programa (tiene que ser una cuenta advisor o admin, ya
--    registrada en public.profiles — la creación de Programas está
--    restringida a esos roles).
-- 4. Ejecutá el resto del script. Al final corre un SELECT que te muestra
--    todo lo tocado/creado, para confirmar.
-- ============================================================================


-- ============================================================================
-- PARTE 1 — Completar proyecto ya cargado: Proyecto Cruce Transandino
-- (fila 1 de la planilla: "Andres" / Cirion / Cruce Trasandino / FO / 70M usd)
-- ============================================================================
update public.projects
set budget_amount_usd = 70000000
where name = 'Proyecto Cruce Transandino (Andean Crossing Project)';


-- ============================================================================
-- PARTE 2 — Programa "Atlántico-Pacífico" (EPECH)
-- Agrupa las filas 4 a 8 de la planilla: troncal FO Región Andina-Trelew,
-- tramo terrestre hacia Chile, cable submarino a Uruguay, datacenter en
-- tándem y obra de amarre — cada uno presentado como componente
-- independiente y financiado por separado, mismo criterio que otros
-- corredores multi-componente ya modelados en la plataforma.
-- ============================================================================
insert into public.programs (
  user_id,
  name,
  organization,
  organization_type,
  types,
  description,
  funding_stage
)
values (
  -- EDITAR: email de la cuenta (advisor/admin) que debe figurar como dueña
  -- del programa.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'Atlántico-Pacífico',

  'EPECH (Empresa Provincial de Energía de Chubut)',

  'public',

  array['fiber_backbone_last_mile','submarine_cable','ai_datacenter','passive_infrastructure']::text[],

$pdesc$Programa que agrupa el corredor de infraestructura digital "Atlántico-Pacífico" impulsado por EPECH (Empresa Provincial de Energía de Chubut): un troncal de fibra óptica entre la Región Andina y Trelew que sigue la traza de la línea de transporte eléctrico provincial, un tramo terrestre hacia Chile (Esquel-Chaitén-Puerto Montt), un cable submarino de salida atlántica hacia Uruguay (Trelew-Punta del Este), un datacenter en tándem con hardware de IA, y la obra de amarre/civil asociada — cinco componentes presentados por separado y financiados de forma independiente bajo un mismo programa.

Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$pdesc$,

  'financing'
);


-- ============================================================================
-- PARTE 3 — Los 5 proyectos del Programa "Atlántico-Pacífico" (filas 4-8)
-- ============================================================================
insert into public.projects (
  user_id,
  name,
  project_type,
  program_id,
  country,
  description,
  generating_entity_name,
  generating_entity_type,
  budget_amount_usd
)
values

-- Fila 4: Troncal FO Región Andina (Futaleufú) - Trelew — sin presupuesto
-- propio informado en la planilla (el monto está en los otros 4 tramos).
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Atlántico-Pacífico — Troncal FO Región Andina (Futaleufú)-Trelew',
  'fiber_backbone_last_mile',
  (select id from public.programs where name = 'Atlántico-Pacífico'),
  'Argentina',
$d4$Troncal mayorista de fibra óptica entre la Región Andina (Futaleufú) y Trelew, siguiendo la traza de la línea de transporte de energía eléctrica de EPECH. Primer tramo del corredor "Atlántico-Pacífico", que conecta el ancla submarina de Trelew con el cruce terrestre hacia Chile por Esquel/Chaitén.

Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d4$,
  'EPECH (Empresa Provincial de Energía de Chubut)',
  'provincial_gov',
  null
),

-- Fila 5: Tramo terrestre Esquel-Chaitén-Puerto Montt — planilla: USD 35M
-- a 60M; se cargó el punto medio (USD 47,5M).
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Atlántico-Pacífico — Tramo Terrestre Esquel-Chaitén-Puerto Montt',
  'fiber_backbone_last_mile',
  (select id from public.programs where name = 'Atlántico-Pacífico'),
  'Argentina',
$d5$Tramo terrestre de fibra óptica de 500 km entre Esquel (Argentina), Chaitén y Puerto Montt (Chile), cruzando la cordillera — segundo tramo del corredor "Atlántico-Pacífico".

Presupuesto: la planilla de origen informa un rango de USD 35M a 60M; el campo estructurado carga el punto medio (USD 47,5M). Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d5$,
  'EPECH (Empresa Provincial de Energía de Chubut)',
  'provincial_gov',
  47500000
),

-- Fila 6: Cable submarino Trelew (AR) - Punta del Este (UY) — planilla:
-- USD 120M a 180M; se cargó el punto medio (USD 150M).
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Atlántico-Pacífico — Cable Submarino Trelew (AR)-Punta del Este (UY)',
  'submarine_cable',
  (select id from public.programs where name = 'Atlántico-Pacífico'),
  'Argentina',
$d6$Cable submarino de 1.500 km entre Trelew (Argentina) y Punta del Este (Uruguay) — salida atlántica del corredor "Atlántico-Pacífico".

Presupuesto: la planilla de origen informa un rango de USD 120M a 180M; el campo estructurado carga el punto medio (USD 150M). Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d6$,
  'EPECH (Empresa Provincial de Energía de Chubut)',
  'provincial_gov',
  150000000
),

-- Fila 7: Datacenter en tándem Tier IV (2 sedes) + HW IA — planilla:
-- USD 110M a 160M; se cargó el punto medio (USD 135M).
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Atlántico-Pacífico — Datacenter Tier IV en Tándem (2 sedes) + HW IA',
  'ai_datacenter',
  (select id from public.programs where name = 'Atlántico-Pacífico'),
  'Argentina',
$d7$Datacenter en tándem Tier IV, en dos sedes, con hardware de IA — componente de cómputo del corredor "Atlántico-Pacífico", aprovechando la salida internacional del cable submarino y el troncal terrestre del mismo programa.

Presupuesto: la planilla de origen informa un rango de USD 110M a 160M; el campo estructurado carga el punto medio (USD 135M). Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d7$,
  'EPECH (Empresa Provincial de Energía de Chubut)',
  'provincial_gov',
  135000000
),

-- Fila 8: Amarre - obra civil y contingencia — planilla: USD 40M a 70M;
-- se cargó el punto medio (USD 55M).
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Atlántico-Pacífico — Amarre: Obra Civil y Contingencia',
  'passive_infrastructure',
  (select id from public.programs where name = 'Atlántico-Pacífico'),
  'Argentina',
$d8$Obra civil de amarre (landing) y contingencia asociada al cable submarino y al resto del corredor "Atlántico-Pacífico" — infraestructura pasiva de soporte, presentada como componente presupuestario independiente en la planilla de origen.

Presupuesto: la planilla de origen informa un rango de USD 40M a 70M; el campo estructurado carga el punto medio (USD 55M). Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d8$,
  'EPECH (Empresa Provincial de Energía de Chubut)',
  'provincial_gov',
  55000000
);


-- ============================================================================
-- PARTE 4 — 13 proyectos nuevos independientes (filas 2, 3, 9-19)
-- ============================================================================
insert into public.projects (
  user_id,
  name,
  project_type,
  country,
  description,
  generating_entity_name,
  generating_entity_type,
  budget_amount_usd,
  fsu_scope,
  fsu_amount_usd,
  other_financing_notes
)
values

-- Fila 2: Puma (Etisalat) — cable submarino Argentina-Sudáfrica
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Cable Submarino PUMA (Argentina-Sudáfrica)',
  'submarine_cable',
  'Argentina',
$d2$Proyecto de cable submarino de fibra óptica entre Argentina y Sudáfrica, impulsado por Etisalat.

Dato preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin tecnología, presupuesto ni cronograma detallados todavía; pendiente de carpeta técnica.$d2$,
  'Etisalat',
  'isp',
  null,
  null,
  null,
  null
),

-- Fila 3: Tramo bioceánico Norte (Comtec, Salta)
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Tramo Bioceánico Norte (Salta)',
  'fiber_backbone_last_mile',
  'Argentina',
$d3$Red de fibra óptica que brinda conectividad mayorista y salida a Chile por el Paso de Jama, conectando 20 localidades salteñas y complejos mineros de la región. Impulsado por Comtec.

Dato preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin presupuesto ni tecnología detallados todavía.$d3$,
  'Comtec',
  'isp',
  null,
  null,
  null,
  null
),

-- Fila 9: CALF — anillo mayorista FO Neuquén — planilla: USD 100M
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'CALF — Anillo Mayorista de Fibra Óptica (Neuquén)',
  'wholesale_neutral_network',
  'Argentina',
$d9$Anillo mayorista de fibra óptica en la provincia de Neuquén, con tecnología Nokia. Impulsado por CALF.

Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d9$,
  'CALF',
  'isp',
  100000000,
  null,
  null,
  'Obligación Negociable (ON) — CALF. Marcada así en la planilla de origen en vez de FSU.'
),

-- Fila 10: Internet Service — red mayorista FO Entre Ríos
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Internet Service — Red Mayorista de Fibra Óptica (Entre Ríos)',
  'wholesale_neutral_network',
  'Argentina',
$d10$Red mayorista de fibra óptica en la provincia de Entre Ríos, con tecnología Nokia. Impulsado por Internet Service.

Dato preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin presupuesto detallado.$d10$,
  'Internet Service',
  'isp',
  null,
  null,
  null,
  'Obligación Negociable (ON) — Internet Service. Marcada así en la planilla de origen en vez de FSU.'
),

-- Fila 11: ARSAT — Modernización REFEFO — planilla: USD 100M
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'ARSAT — Modernización REFEFO (Renovación Tecnológica)',
  'fiber_backbone_last_mile',
  'Argentina',
$d11$Modernización y renovación tecnológica de la Red Federal de Fibra Óptica (REFEFO) de ARSAT, con equipamiento Nokia/Ciena.

Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d11$,
  'ARSAT',
  'national_gov',
  100000000,
  null,
  null,
  null
),

-- Fila 12: ARSAT — Plan FWA 5G — planilla: USD 100M total, FSU USD 15M
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'ARSAT — Plan FWA 5G (1.000 localidades, 1a fase 100 localidades)',
  'fixed_wireless_access',
  'Argentina',
$d12$Plan de conectividad fija inalámbrica (FWA) 5G para 1.000 localidades, con una primera fase de 100 localidades. Tecnología Nokia.

Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d12$,
  'ARSAT',
  'national_gov',
  100000000,
  null,
  15000000,
  null
),

-- Fila 13: ARSAT/Oracle — Datacenter IA distribuida — planilla: FSU USD 25M
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'ARSAT / Oracle — Datacenter de IA Distribuida (Mini Edge, 25 Sitios)',
  'ai_datacenter',
  'Argentina',
$d13$Red distribuida de datacenters de IA en formato mini edge / container, en 25 sitios, con tecnología Oracle. Iniciativa conjunta ARSAT/Oracle.

Dato preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin presupuesto total detallado (solo el monto FSU).$d13$,
  'ARSAT / Oracle',
  'national_gov',
  null,
  null,
  25000000,
  null
),

-- Fila 14: Starlink — 6.000 escuelas — planilla: FSU USD 22M
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Starlink — Conectividad Satelital para 6.000 Escuelas',
  'satellite_constellation',
  'Argentina',
$d14$Conectividad satelital para 6.000 escuelas a través de Starlink.

Dato preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin presupuesto total detallado (solo el monto FSU).$d14$,
  'Starlink (SpaceX)',
  'isp',
  null,
  null,
  22000000,
  null
),

-- Fila 15: ENACOM — Portales conectados en Parques Nacionales — planilla:
-- FSU USD 8M
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'ENACOM — Portales Conectados en Parques Nacionales',
  'satellite_constellation',
  'Argentina',
$d15$Portales de conectividad satelital (Satelital/Starlink) en Parques Nacionales, impulsado por ENACOM.

Dato preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin presupuesto total detallado (solo el monto FSU).$d15$,
  'ENACOM',
  'regulator',
  null,
  null,
  8000000,
  null
),

-- Fila 16: YPF — Redes privadas 5G
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'YPF — Redes Privadas 5G',
  'other',
  'Argentina',
$d16$Redes privadas 5G impulsadas por YPF.

Dato muy preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin descripción, geografía ni presupuesto detallados todavía; se cargó con la información mínima disponible para no perder el registro del proyecto en el pipeline. Convendría completarlo desde app/new-project.html apenas haya más detalle.$d16$,
  'YPF',
  'other',
  null,
  null,
  null,
  null
),

-- Fila 17: ENACOM — Modernización del sistema de control de espectro —
-- planilla: USD 60M (moneda no aclarada explícitamente en esta fila; se
-- asumió USD por consistencia con el resto de la tabla, a confirmar).
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'ENACOM — Modernización del Sistema de Control de Espectro',
  'other',
  'Argentina',
$d17$Modernización del sistema de control de espectro radioeléctrico de ENACOM.

La planilla de origen no aclara explícitamente la moneda de esta cifra; se asumió USD por consistencia con el resto de la tabla — a confirmar. Fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026.$d17$,
  'ENACOM',
  'regulator',
  60000000,
  null,
  null,
  null
),

-- Fila 18: ENACOM — Marketplace de espectro
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'ENACOM — Marketplace de Espectro',
  'other',
  'Argentina',
$d18$Plataforma de mercado secundario (marketplace) para la comercialización de espectro radioeléctrico, impulsada por ENACOM.

Dato muy preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin presupuesto ni alcance detallados todavía.$d18$,
  'ENACOM',
  'regulator',
  null,
  null,
  null,
  null
),

-- Fila 19: Telcos — Programa Play (sitios móviles) — FSU marcado, sin
-- monto informado en la planilla.
(
  -- EDITAR
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  'Telcos — Programa Play (Sitios Móviles)',
  'passive_infrastructure',
  'Argentina',
$d19$Programa Play: despliegue de sitios móviles por parte de operadores de telecomunicaciones (telcos), con financiamiento previsto vía FSU.

Dato preliminar de la planilla de seguimiento de proyectos ENACOM (ago. 2026) — sin presupuesto ni cantidad de sitios detallados todavía.$d19$,
  'Telcos (operadores móviles) — Programa Play',
  'isp',
  null,
  'Financiamiento previsto vía FSU — monto aún no definido en la planilla de origen (ago. 2026).',
  null,
  null
);


-- ============================================================================
-- Verificación
-- ============================================================================
select p.id, p.name, p.project_type, p.budget_amount_usd, p.fsu_amount_usd, pr.name as programa, p.created_at
from public.projects p
left join public.programs pr on pr.id = p.program_id
where p.name in (
  'Cable Submarino PUMA (Argentina-Sudáfrica)',
  'Tramo Bioceánico Norte (Salta)',
  'Atlántico-Pacífico — Troncal FO Región Andina (Futaleufú)-Trelew',
  'Atlántico-Pacífico — Tramo Terrestre Esquel-Chaitén-Puerto Montt',
  'Atlántico-Pacífico — Cable Submarino Trelew (AR)-Punta del Este (UY)',
  'Atlántico-Pacífico — Datacenter Tier IV en Tándem (2 sedes) + HW IA',
  'Atlántico-Pacífico — Amarre: Obra Civil y Contingencia',
  'CALF — Anillo Mayorista de Fibra Óptica (Neuquén)',
  'Internet Service — Red Mayorista de Fibra Óptica (Entre Ríos)',
  'ARSAT — Modernización REFEFO (Renovación Tecnológica)',
  'ARSAT — Plan FWA 5G (1.000 localidades, 1a fase 100 localidades)',
  'ARSAT / Oracle — Datacenter de IA Distribuida (Mini Edge, 25 Sitios)',
  'Starlink — Conectividad Satelital para 6.000 Escuelas',
  'ENACOM — Portales Conectados en Parques Nacionales',
  'YPF — Redes Privadas 5G',
  'ENACOM — Modernización del Sistema de Control de Espectro',
  'ENACOM — Marketplace de Espectro',
  'Telcos — Programa Play (Sitios Móviles)'
)
order by p.created_at;

select id, name, budget_amount_usd, exchange_rate
from public.projects
where name = 'Proyecto Cruce Transandino (Andean Crossing Project)';
