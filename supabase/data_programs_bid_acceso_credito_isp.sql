-- ============================================================================
-- Alta de 3 Programas de Financiación — "Acceso a Crédito Telecom para ISPs"
-- (adaptación del programa BID BR-L1619 "Programa Acceso a Crédito Telecom",
-- Brasil, a la Argentina)
--
-- QUÉ ES EL PROGRAMA ORIGINAL (fuente: "20260626_Case Brasil_Programa de
-- Crédito para ISPs_vESP.pdf", presentación del BID)
-- El BID diagnosticó en Brasil que los proveedores regionales de internet
-- (ISPs) — que en 2022 tenían el 93% de participación de mercado en
-- municipios de menos de 30 mil habitantes — no logran acceder a crédito de
-- largo plazo y bajo costo para expandir sus redes de banda ancha fija,
-- pese a ser actores clave para cerrar la brecha de cobertura ("dividendo
-- digital" aún pendiente: 25,7% de brecha de cobertura en esos municipios
-- en 2022). Los ISPs pequeños (Tiers 2 y 3, entre ~1.900 y ~430 empresas)
-- terminan financiándose con crédito personal o plazos cortísimos
-- (3-6 meses) a tasas de 9-30 puntos por sobre la tasa de referencia —
-- muy por encima de lo que pagan otros sectores de infraestructura
-- (rutas, aeropuertos, telecom grande) por asimetría de información,
-- costos de transacción y débil gobernanza/garantías de los ISPs chicos.
--
-- La operación de crédito BR-L1619 (US$ 98,5M del BID para el Componente 1
-- de financiamiento, + US$ 3M para el Componente 2 de información/
-- monitoreo) propone TRES instrumentos complementarios, todos canalizados
-- a través del FUST (Fundo de Universalização dos Serviços de
-- Telecomunicações, el fondo de servicio universal brasileño) con al
-- Ministério das Comunicações (MCOM) como promotor de la política pública:
-- 1) Crédito bancario (indirecto, vía bancos acreditados),
-- 2) FIDC — Fundo de Investimento em Direitos Creditórios (crédito no
--    bancario, financiando la compra de equipos a proveedores/fabricantes),
-- 3) Mecanismos de garantía (que abaratan el crédito bancario tradicional
--    sin desembolsar fondos directamente).
-- Se complementa con SisCred-ISP, un sistema de información/scoring que
-- ataca la causa raíz de asimetría de información — no es en sí mismo un
-- instrumento de financiamiento, así que no se modela como Programa acá.
--
-- ADAPTACIÓN A ARGENTINA
-- La estructura institucional se traduce 1 a 1: el FUST brasileño equivale
-- al FSU argentino (Fondo del Servicio Universal, administrado por
-- ENACOM); el MCOM (promotor de política pública) equivale a ENACOM como
-- Órgano Ejecutor; el Banco Central do Brasil (que autoriza a las
-- Instituciones Financieras Acreditadas) equivale al BCRA. El segmento
-- objetivo — ISPs/cooperativas y pymes de telecomunicaciones regionales,
-- muy numerosas en el interior argentino y con el mismo problema
-- estructural de acceso a crédito de largo plazo — es directamente
-- comparable.
--
-- Los montos (US$ 98,5M + US$ 3M) y los umbrales de tamaño de ISP
-- (200.000 accesos, tiers por facturación en BRL) fueron dimensionados
-- para el mercado brasileño (20M de habitantes sin cobertura, miles de
-- ISPs) y NO se trasladan tal cual — quedan como referencia/benchmark en
-- la descripción de cada Programa; el dimensionamiento para Argentina
-- (montos del FSU a afectar, techo de accesos elegible, segmentación por
-- facturación en ARS) requiere un diagnóstico propio, análogo al que el
-- BID hizo con Teleco/Pilotage para Brasil, antes de reglamentar cada
-- instrumento.
--
-- Se cargan como TRES Programas separados (program_role = 'financing',
-- financing_entity = 'Banco Interamericano de Desarrollo (BID)' — no
-- 'ENACOM-FSU', porque aunque el FSU es el canal doméstico, el fondeo real
-- es un préstamo del BID; así no quedan sujetos a la regla de "una sola
-- línea de FSU por proyecto" que sí aplica a TASU/FATIC/etc., y un
-- proyecto puede combinar uno de estos instrumentos con una línea de FSU
-- doméstica genuina) porque son mecanismos con actores y flujos de fondos
-- distintos entre sí — un ISP aplicaría al que mejor se ajuste a su
-- situación (o a más de uno, si el diseño final del programa lo permite).
--
-- CÓMO USAR
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. En las 3 líneas marcadas "EDITAR" reemplazá el email por el de la
--    cuenta de la plataforma INA que va a figurar como propietaria de los
--    programas (tiene que ser una cuenta advisor o admin, ya registrada en
--    public.profiles — la creación de Programas está restringida a esos
--    roles).
-- 3. Ejecutá el resto del script. Al final corre un SELECT que te muestra
--    los 3 programas creados, para confirmar.
-- 4. Los 3 aparecerán en app/financing-programs.html (no en
--    app/programs.html, que es solo para Iniciativas/agrupadores).
-- ============================================================================


-- ============================================================================
-- 1) Crédito Bancario
-- ============================================================================
insert into public.programs (
  user_id,
  name,
  organization,
  organization_type,
  financing_entity,
  types,
  funding_stage,
  program_role,
  description
)
values (
  -- EDITAR: email de la cuenta (advisor/admin) que debe figurar como dueña
  -- del programa.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'BID — Acceso a Crédito Telecom para ISPs: Línea de Crédito Bancario',

  'Ente Nacional de Comunicaciones (ENACOM)',

  'public',

  'Banco Interamericano de Desarrollo (BID)',

  array['fiber_backbone_last_mile', 'fixed_wireless_access']::text[],

  'financing',

  'financing',

$pdesc$Adaptación a la Argentina del Componente 1 (instrumento de crédito bancario) del "Programa Acceso a Crédito Telecom" del BID para Brasil (BR-L1619). Financia, mediante préstamos de mediano/largo plazo y tasa reducida, la expansión de redes de banda ancha fija por parte de proveedores regionales de internet (ISPs) — cooperativas y pymes de telecomunicaciones — que hoy solo acceden a crédito personal o financiación de cortísimo plazo (3-6 meses) a tasas muy por encima de las de otros sectores de infraestructura.

FLUJO DE FONDOS (adaptado de FUST/MCOM/Banco Central do Brasil a sus equivalentes argentinos):
BID otorga un préstamo al Tesoro Nacional → se canaliza al FSU (Fondo del Servicio Universal, administrado por ENACOM, equivalente al FUST brasileño) → el FSU transfiere recursos a un Agente Financiero designado (banco de fomento) → el Agente Financiero presta a tasa reducida a Instituciones Financieras Acreditadas (autorizadas por el BCRA y acreditadas ante el Agente Financiero, equivalente al esquema del Banco Central do Brasil) → esas instituciones otorgan crédito directo o indirecto a los ISPs elegibles (submutuarios).

QUIÉNES PARTICIPAN (adaptado): ISP elegible (prestador de servicios de telecomunicaciones/internet, con un techo de accesos a definir — en Brasil se usó 200.000 accesos), Agente Financiero (institución elegible para operar los recursos del FSU, con contrato con ENACOM como Órgano Ejecutor), Instituciones Financieras Acreditadas (autorizadas por el BCRA).

BENEFICIO: instrumento con antecedentes de implementación exitosa en Brasil (CG-Fust). NECESIDAD PARA ADAPTAR A ARGENTINA: modelización financiera que permita el acceso al crédito de los ISPs pequeños, definición del Agente Financiero y del criterio de acreditación de Instituciones Financieras.

Referencia de magnitud en Brasil (no trasladable 1 a 1): US$ 98,5M del BID para el Componente 1 completo (los 3 instrumentos), dirigido a ISPs Tier 2 (~430, facturación 5M-50M) y Tier 3 (~1.900, facturación 1M-5M) principalmente. El dimensionamiento para Argentina requiere diagnóstico propio.

Fuente: BID, "Programa Acceso a Crédito Telecom (BR-L1619)" — presentación "Case Brasil", adjunta al proyecto INA (26/06/2026).$pdesc$
);


-- ============================================================================
-- 2) Fondo de Inversión en Derechos Crediticios (FIDC) — crédito no bancario
-- ============================================================================
insert into public.programs (
  user_id,
  name,
  organization,
  organization_type,
  financing_entity,
  types,
  funding_stage,
  program_role,
  description
)
values (
  -- EDITAR: email de la cuenta (advisor/admin) que debe figurar como dueña
  -- del programa.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'BID — Acceso a Crédito Telecom para ISPs: Fondo de Inversión en Derechos Crediticios (FIDC)',

  'Ente Nacional de Comunicaciones (ENACOM)',

  'public',

  'Banco Interamericano de Desarrollo (BID)',

  array['fiber_backbone_last_mile', 'fixed_wireless_access']::text[],

  'financing',

  'financing',

$pdesc$Adaptación a la Argentina del Componente 1 (instrumento de crédito NO bancario, FIDC) del "Programa Acceso a Crédito Telecom" del BID para Brasil (BR-L1619). Financia la ADQUISICIÓN DE EQUIPOS de red por parte de ISPs, evitando el pago al contado o la financiación de cortísimo plazo que hoy ofrecen los distribuidores — sin pasar por un banco.

ESTRUCTURA (el FIDC brasileño se adapta como un Fideicomiso Financiero o Fondo Común de Inversión Cerrado bajo la normativa de la CNV, la estructura equivalente disponible en Argentina):
1. Un fabricante o distribuidor de equipos de redes ("Proveedor Acreditado") le vende equipamiento a un ISP con financiación, y cede los derechos de cobro de esas facturas/pagarés al Fondo.
2. El Fondo emite dos clases de cuotas: Cuota Senior (suscripta con aportes del FSU/BID) y Cuota Subordinada (suscripta por el propio Proveedor Acreditado, como compromiso de "skin in the game" — absorbe primero cualquier pérdida). Inversores calificados/profesionales pueden suscribir cuotas adicionales, apalancando así los recursos públicos con capital privado.
3. El Fondo le paga al Proveedor Acreditado al contado (o a plazo corto) por los derechos cedidos, y cobra al ISP en cuotas de mediano/largo plazo — el ISP termina pagando el crédito al Fondo, no al Proveedor.

QUIÉNES PARTICIPAN (adaptado): ISP elegible, Proveedor Acreditado (fabricante/distribuidor de equipos de redes o prestador mayorista de telecomunicaciones), Inversores Autorizados (calificados/profesionales según la normativa CNV aplicable a Fideicomisos Financieros/FCI cerrados), Gestor/Administrador del Fondo.

BENEFICIO: atiende ISPs de todos los tamaños (no depende de que un banco los evalúe crediticiamente) y permite atraer inversores privados, apalancando los recursos del FSU/BID más allá del monto aportado directamente. NECESIDAD PARA ADAPTAR A ARGENTINA: identificar proveedores/fabricantes de equipos de redes interesados en ceder derechos crediticios, y gestores/administradores (sociedades gerentes de FCI o fiduciarios financieros) dispuestos a estructurar el vehículo bajo normativa CNV.

Fuente: BID, "Programa Acceso a Crédito Telecom (BR-L1619)" — presentación "Case Brasil", adjunta al proyecto INA (26/06/2026).$pdesc$
);


-- ============================================================================
-- 3) Mecanismo de Garantía
-- ============================================================================
insert into public.programs (
  user_id,
  name,
  organization,
  organization_type,
  financing_entity,
  types,
  funding_stage,
  program_role,
  description
)
values (
  -- EDITAR: email de la cuenta (advisor/admin) que debe figurar como dueña
  -- del programa.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'BID — Acceso a Crédito Telecom para ISPs: Mecanismo de Garantía',

  'Ente Nacional de Comunicaciones (ENACOM)',

  'public',

  'Banco Interamericano de Desarrollo (BID)',

  array['fiber_backbone_last_mile', 'fixed_wireless_access']::text[],

  'financing',

  'financing',

$pdesc$Adaptación a la Argentina del Componente 1 (mecanismo de garantía) del "Programa Acceso a Crédito Telecom" del BID para Brasil (BR-L1619). A diferencia de los otros dos instrumentos, NO desembolsa fondos al ISP directamente: reduce el riesgo percibido por el prestamista para que el ISP acceda a MEJORES CONDICIONES de crédito bancario tradicional (tasa más baja, plazos más largos).

ESTRUCTURA (adaptada de FUST/MCOM/Banco Central do Brasil a sus equivalentes argentinos): BID otorga un préstamo al Tesoro Nacional → se canaliza al FSU (administrado por ENACOM) → el FSU constituye, a través de un Agente Financiero, un Mecanismo Garantidor de Crédito (fiduciario emisor de garantías) → las Instituciones Financieras Acreditadas (autorizadas por el BCRA) prestan a ISPs elegibles bajo condiciones de mercado, pero con garantía individual del fondo por cada operación — el ISP es beneficiario de la garantía, la institución financiera es acreedor garantizado.

QUIÉNES PARTICIPAN (adaptado): ISP elegible (beneficiario de la garantía), Instituciones Financieras Acreditadas (mutuante/acreedor garantizado), Agente Financiero (contrata al fiduciario emisor de las garantías), ENACOM (define los criterios de elegibilidad de proyectos para obtener financiamiento garantizado, como promotor de la política pública).

BENEFICIO: es el instrumento que permite el MÁXIMO APALANCAMIENTO de los recursos del FSU/BID entre los tres propuestos — una garantía cubre un múltiplo del crédito garantizado, a diferencia de fondear un préstamo directo o comprar derechos de cobro. NECESIDAD PARA ADAPTAR A ARGENTINA: identificar el interés de entidades financieras en operar bajo este esquema, y desarrollar la modelización financiera que demuestre el impacto esperado en la reducción de la tasa de interés ofrecida a los ISPs.

Fuente: BID, "Programa Acceso a Crédito Telecom (BR-L1619)" — presentación "Case Brasil", adjunta al proyecto INA (26/06/2026).$pdesc$
);


-- ============================================================================
-- Verificación
-- ============================================================================
select id, name, organization, financing_entity, types, funding_stage, program_role
from public.programs
where name like 'BID — Acceso a Crédito Telecom para ISPs%'
order by name;
