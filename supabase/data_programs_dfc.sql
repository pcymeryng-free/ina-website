-- ============================================================================
-- Alta de 4 Programas de Financiación — DFC (U.S. International Development
-- Finance Corporation, www.dfc.gov)
--
-- QUÉ ES DFC
-- DFC es la institución de financiamiento para el desarrollo del gobierno de
-- Estados Unidos (creada en 2019 por la BUILD Act, fusionando a OPIC — el
-- antiguo "Overseas Private Investment Corporation" — con el programa de
-- crédito para el desarrollo de USAID). Moviliza capital privado hacia
-- proyectos en mercados emergentes, con infraestructura digital y
-- telecomunicaciones como uno de sus 7 sectores prioritarios declarados
-- (junto con energía, minerales críticos, transporte, servicios
-- financieros, salud y agricultura). DFC no otorga subsidios ni
-- donaciones para construir infraestructura en sí — son instrumentos
-- financieros (deuda, capital, seguro) pensados para proyectos con
-- viabilidad comercial, más asistencia técnica/estudios de factibilidad
-- para prepararlos.
--
-- Se cargan como CUATRO Programas separados porque son instrumentos
-- distintos entre sí — con mecánica, actores y momento de aplicación
-- diferentes — que un proyecto puede combinar (p. ej. un préstamo DFC más
-- un Seguro de Riesgo Político sobre ese mismo préstamo), igual que se hizo
-- con los 3 instrumentos del BID ("Acceso a Crédito Telecom para ISPs",
-- ver supabase/data_programs_bid_acceso_credito_isp.sql, mismo criterio de
-- carga). financing_entity se fija en 'U.S. International Development
-- Finance Corporation (DFC)' — no 'ENACOM-FSU' — porque el fondeo real no
-- es una línea doméstica del FSU, así que estos 4 Programas quedan fuera de
-- la regla de "una sola línea de FSU por proyecto" (ver
-- migration_v48_single_fsu_program.sql) y un proyecto puede combinar
-- cualquiera de ellos con una línea de FSU genuina.
--
-- NOTA IMPORTANTE: los 4 instrumentos, límites de monto y plazos descriptos
-- abajo son los términos GENERALES que DFC publica en dfc.gov para
-- cualquier país elegible — no son (ni implican) una asignación,
-- pre-aprobación ni compromiso específico para Argentina o para ENACOM.
-- Cada instrumento requiere un proceso de aplicación propio directamente
-- ante DFC (ver dfc.gov), con debida diligencia de elegibilidad de país,
-- viabilidad comercial del proyecto e interés estratégico de EE.UU.
--
-- CÓMO USAR
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. En las 4 líneas marcadas "EDITAR" reemplazá el email por el de la
--    cuenta de la plataforma INA que va a figurar como propietaria de los
--    programas (tiene que ser una cuenta advisor o admin, ya registrada en
--    public.profiles — la creación de Programas está restringida a esos
--    roles).
-- 3. Ejecutá el resto del script. Al final corre un SELECT que te muestra
--    los 4 programas creados, para confirmar.
-- 4. Los 3 de financiamiento aparecerán en app/financing-programs.html
--    junto al resto de los programas de financiamiento; el de Asistencia
--    Técnica/Estudios de Factibilidad (funding_stage = 'preparation')
--    aparece en el selector de "Programa de preparación" de
--    new-project.html, igual que USTDA.
-- ============================================================================


-- ============================================================================
-- 1) Financiamiento de Deuda — Préstamos Directos y Garantías
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

  'DFC — Financiamiento de Deuda (Préstamos Directos y Garantías)',

  'Ente Nacional de Comunicaciones (ENACOM)',

  'public',

  'U.S. International Development Finance Corporation (DFC)',

  array['submarine_cable', 'fiber_backbone_last_mile', 'fixed_wireless_access', 'wholesale_neutral_network', 'ai_datacenter', 'satellite_constellation', 'passive_infrastructure']::text[],

  'financing',

  'financing',

$pdesc$Préstamos directos y garantías de préstamo de DFC (U.S. International Development Finance Corporation) para proyectos de infraestructura digital y telecomunicaciones en mercados emergentes — uno de los 7 sectores prioritarios declarados por DFC (junto con energía, minerales críticos, transporte, servicios financieros, salud y agricultura). DFC ha financiado explícitamente redes de fibra óptica, torres/conectividad inalámbrica y centros de datos en otros países de la región y de Asia bajo esta misma línea.

TÉRMINOS PUBLICADOS: montos de hasta US$ 1.000 millones por operación, con plazos ("tenors") de entre 5 y 25 años, sujeto a la ley de crédito federal de EE.UU. y a la debida diligencia propia de DFC (viabilidad comercial del proyecto, adicionalidad frente al mercado privado, e interés estratégico/de desarrollo de EE.UU.). Incluye modalidades de deuda estructurada y financiamiento de proyecto (project finance), pensadas tanto para operadores privados como para vehículos público-privados.

QUIÉNES PARTICIPAN: el desarrollador/operador del proyecto (prestatario), DFC (prestamista o garante), y —cuando la operación es garantía en vez de préstamo directo— una institución financiera comercial que otorga el crédito de base.

BENEFICIO: acceso a crédito de largo plazo en dólares con condiciones más favorables que el mercado local, sin necesidad de que el proyecto tenga un socio estadounidense. NECESIDAD PARA UN PROYECTO EN ARGENTINA: confirmar la elegibilidad de Argentina como país receptor al momento de aplicar (la lista de países elegibles de DFC puede variar), y preparar el caso de negocio/estructura financiera que DFC evalúa en su propio proceso de aplicación (no gestionado por ENACOM).

Fuente: DFC, "Debt Financing" — dfc.gov/what-we-offer/our-products/debt-financing (consultado 2026).$pdesc$
);


-- ============================================================================
-- 2) Inversión de Capital (Equity)
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

  'DFC — Inversión de Capital (Equity)',

  'Ente Nacional de Comunicaciones (ENACOM)',

  'public',

  'U.S. International Development Finance Corporation (DFC)',

  array['submarine_cable', 'fiber_backbone_last_mile', 'wholesale_neutral_network', 'ai_datacenter', 'satellite_constellation']::text[],

  'financing',

  'financing',

$pdesc$Inversiones directas de capital (equity) que realiza DFC en empresas o fondos que apoyen desafíos de desarrollo a la vez que avanzan intereses estratégicos de Estados Unidos — a diferencia de un préstamo, DFC pasa a ser accionista (típicamente minoritario) del vehículo del proyecto, alineando sus incentivos con el éxito comercial de largo plazo del operador.

APLICACIÓN TÍPICA EN INFRAESTRUCTURA DIGITAL: capitalización de operadores de red mayorista neutral, empresas de torres/infraestructura pasiva compartida, operadores de cable submarino o de centros de datos que necesitan robustecer su estructura de capital (no solo deuda) para escalar, especialmente en etapas de expansión donde el apalancamiento adicional ya no es viable sin más equity.

QUIÉNES PARTICIPAN: la empresa u operador que recibe la inversión, DFC como inversor de capital, y —frecuentemente— co-inversores privados que DFC busca movilizar junto con su propio aporte (su rol declarado es "catalizar" capital privado, no reemplazarlo).

BENEFICIO: fortalece la estructura de capital del proyecto sin agregar deuda, y la participación de DFC como accionista suele facilitar el acceso posterior a otros financistas (efecto "sello de calidad"/mitigación de riesgo percibido). NECESIDAD PARA UN PROYECTO EN ARGENTINA: contar con una estructura societaria y un plan de negocio que sostenga una salida de DFC en el mediano/largo plazo (DFC no es un socio permanente), y confirmar elegibilidad de país al momento de aplicar directamente ante DFC.

Fuente: DFC, "Equity" — dfc.gov/what-we-offer/our-products/equity (consultado 2026).$pdesc$
);


-- ============================================================================
-- 3) Seguro de Riesgo Político (Political Risk Insurance)
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

  'DFC — Seguro de Riesgo Político (Political Risk Insurance)',

  'Ente Nacional de Comunicaciones (ENACOM)',

  'public',

  'U.S. International Development Finance Corporation (DFC)',

  array['submarine_cable', 'fiber_backbone_last_mile', 'fixed_wireless_access', 'wholesale_neutral_network', 'ai_datacenter', 'satellite_constellation', 'passive_infrastructure']::text[],

  'financing',

  'financing',

$pdesc$A diferencia de los otros instrumentos de DFC, el Seguro de Riesgo Político NO desembolsa fondos al proyecto: cubre a inversores y prestamistas estadounidenses (o, en ciertos casos, a la institución financiera que participa de la operación) contra pérdidas derivadas de riesgos políticos en el país receptor — inconvertibilidad/imposibilidad de repatriar moneda, expropiación o interferencia gubernamental, y violencia política (incluyendo terrorismo). Al reducir el riesgo percibido, facilita que el proyecto acceda a MEJORES CONDICIONES de financiamiento privado tradicional (menor tasa, mayor apetito de los prestamistas), de forma análoga en su lógica al Mecanismo de Garantía del BID (ver data_programs_bid_acceso_credito_isp.sql) aunque cubre riesgos distintos (político vs. crediticio).

COBERTURA PUBLICADA: hasta US$ 1.000 millones por proyecto.

QUIÉNES PARTICIPAN: el inversor o prestamista asegurado (beneficiario de la póliza), DFC (asegurador), y el proyecto/operador en el país receptor cuya operación queda respaldada indirectamente por la cobertura.

BENEFICIO: es habitualmente el instrumento que más facilita atraer inversores y bancos privados de EE.UU./internacionales a un proyecto de infraestructura en un mercado emergente, al remover la incertidumbre política como obstáculo de decisión — relevante para un proyecto de telecomunicaciones de largo plazo de repago (fibra, cable submarino, centros de datos) donde el horizonte de inversión excede varios ciclos político-económicos. NECESIDAD PARA UN PROYECTO EN ARGENTINA: identificar qué inversor o prestamista (típicamente estadounidense) sería el asegurado de la póliza —no es una cobertura que el proyecto argentino contrata directamente para sí mismo— y confirmar elegibilidad de país al momento de aplicar ante DFC.

Fuente: DFC, "Political Risk Insurance" — dfc.gov/what-we-offer/our-products/political-risk-insurance (consultado 2026).$pdesc$
);


-- ============================================================================
-- 4) Asistencia Técnica y Estudios de Factibilidad
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

  'DFC — Asistencia Técnica y Estudios de Factibilidad',

  'Ente Nacional de Comunicaciones (ENACOM)',

  'public',

  'U.S. International Development Finance Corporation (DFC)',

  array['submarine_cable', 'fiber_backbone_last_mile', 'fixed_wireless_access', 'wholesale_neutral_network', 'ai_datacenter', 'satellite_constellation', 'passive_infrastructure']::text[],

  -- 'preparation': igual que USTDA, este Programa financia la ELABORACIÓN
  -- del proyecto (estudios/diseño), no su construcción — ver el comentario
  -- de projects.funding_stage en supabase/schema.sql.
  'preparation',

  'financing',

$pdesc$Donaciones (grants) de DFC para estudios de factibilidad, diseño de ingeniería de front-end (FEED), evaluaciones de impacto ambiental y social, estructuración de la transacción y otros trabajos de preparación de proyecto — bajo la autoridad de la BUILD Act (la ley que creó DFC en 2019). No es financiamiento de obra: es exactamente análogo, en su lógica, al Programa de USTDA ya cargado en la plataforma (Definitional Mission / Feasibility Study), pero desde DFC en vez de USTDA.

CÓMO FUNCIONA: DFC determina el alcance del trabajo de asistencia técnica, estudio de factibilidad o capacitación a financiar, y el receptor de la donación selecciona a la entidad con la experiencia relevante que efectivamente lo ejecuta. En la mayoría de los casos, estas donaciones están pensadas para proyectos que ya recibieron —o que razonablemente podrían recibir— financiamiento o seguro de DFC más adelante (Financiamiento de Deuda, Inversión de Capital o Seguro de Riesgo Político, los otros 3 Programas de DFC cargados en esta plataforma), es decir, funciona como el paso previo que habilita a aplicar a esos instrumentos con un proyecto mejor estructurado y de menor riesgo de ejecución.

QUIÉNES PARTICIPAN: el desarrollador/promotor del proyecto (receptor de la donación), DFC (otorgante), y la entidad consultora/técnica que ejecuta el estudio o trabajo de asistencia técnica.

BENEFICIO: reduce el riesgo de ejecución y mejora la "bancabilidad" del proyecto antes de buscar financiamiento de obra, sin comprometer capital propio del desarrollador en esa etapa temprana. NECESIDAD PARA UN PROYECTO EN ARGENTINA: identificar con precisión qué estudio/trabajo de preparación falta (factibilidad técnica, ambiental/social, estructuración financiera) y su vínculo con una eventual aplicación posterior a alguno de los otros 3 Programas de DFC.

Fuente: DFC, "Technical Assistance & Feasibility Studies" — dfc.gov/what-we-offer/our-products/technical-assistance-feasibility-studies (consultado 2026).$pdesc$
);


-- ============================================================================
-- Verificación
-- ============================================================================
select id, name, organization, financing_entity, types, funding_stage, program_role
from public.programs
where name like 'DFC —%'
order by name;
