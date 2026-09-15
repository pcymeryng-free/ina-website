-- ============================================================================
-- Analisis IA (Investment Readiness Index (TM)) para los 6 proyectos
-- cargados en la plataforma INA — inserta un framework_analysis por
-- proyecto y actualiza projects.status / projects.readiness_stage
-- ============================================================================
--
-- QUE ES ESTO
-- Aplica el mismo motor de scoring de 9 dimensiones que usa
-- app/assessment.html (computeManualAssessment en assets/platform.js) y
-- que /api/analyze-project.js corre automaticamente con Claude cuando un
-- usuario sube documentos: 8 dimensiones genericas (legal_regulatory,
-- technical_maturity, financial_robustness, sponsor_capacity,
-- market_demand, environmental_social, risk_mitigation,
-- governance_reporting) + 1 novena dimension especifica del tipo de
-- proyecto (rollout_readiness para fibra, power_cooling_readiness para
-- datacenter de IA, type_specific_readiness para 'other'). Cada dimension
-- va de 0 a 100, el overall_score es el promedio redondeado de las 9, y el
-- stage se deriva del overall_score exactamente como stageForScore() en
-- platform.js (<=25 Concept Stage, <=50 Early Structuring, <=75 Advanced
-- Structuring, >75 Investment Ready).
--
-- COMO SE HIZO — LEER ANTES DE CORRER
-- Esto NO es una corrida real de /api/analyze-project.js (ese endpoint
-- necesita una API key de Anthropic configurada del lado del servidor en
-- Vercel, a la que este asistente no tiene acceso). Es un analisis
-- generado por mi (Claude, en esta sesion de Cowork) leyendo el texto
-- completo de cada PDF fuente y de las descripciones que ya cargue en
-- projects.description, y calificando honestamente cada una de las 9
-- dimensiones SOLO con hechos que estan documentados en esas fuentes —
-- nunca inventando datos. Uso exactamente el mismo formato de salida
-- (dimensions/gap_roadmap/financing_recommendations/summary) que usaria el
-- endpoint real, y las mismas frases exactas de RECOMMENDATION_TIPS y
-- STAGE_FINANCING_SUGGESTION que ya estan en el codigo, para que se vea
-- identico en pantalla a un analisis corrido por la app. Marque
-- source='ai' porque el analisis lo hizo una IA (yo), no porque haya
-- pasado por ese endpoint especifico — dejalo en 'manual' en vez de 'ai'
-- si preferis reservar ese tag solo para corridas del endpoint real.
--
-- Si en el futuro configuras la API key de Anthropic en el endpoint real,
-- correrlo sobre estos mismos proyectos generaria un resultado
-- probablemente distinto en el detalle (otro modelo, quizas mas contexto),
-- aunque conceptualmente deberia rankearlos de forma similar: Punta Alta
-- (el unico operador ya en funcionamiento con carpeta de credito bancario)
-- muy por delante de los demas, y el analisis de oportunidad de Ciena
-- (sin sponsor ejecutor ni sitio elegido) en el ultimo lugar.
--
-- REQUISITOS PARA CORRER ESTE SCRIPT
-- 1. Los 6 proyectos ya tienen que existir en public.projects — es decir,
--    ya corriste los 6 scripts data_*.sql anteriores en este mismo
--    proyecto de Supabase.
-- 2. EDITAR mas abajo si el email del dueno de los proyectos no es
--    'pcymeryng@gmail.com' (el que se uso por default en los 6 scripts
--    anteriores).
-- 3. Ejecuta el script completo. Al final corre un SELECT de verificacion
--    que muestra los 6 proyectos con su score y stage nuevo.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Proyecto Cruce Transandino (Andean Crossing Project)  (project_type = fiber_backbone_last_mile)
-- overall_score = 47  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id,
  user_id,
  overall_score,
  stage,
  dimensions,
  gap_roadmap,
  financing_recommendations,
  summary,
  raw_model_output,
  source
)
values (
  (select id from public.projects
     where name = 'Proyecto Cruce Transandino (Andean Crossing Project)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  47,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 45, "rationale": "El documento no confirma el estado de los permisos binacionales (Argentina-Chile) para el cruce andino ni de los derechos de paso en los 21 tramos; hay un camino de ruta definido pero sin evidencia de habilitaciones cerradas."}, "technical_maturity": {"score": 80, "rationale": "Diseño técnico avanzado y específico: 4 ductos PEAD, cable de 144 fibras G.652D, capacidad inicial de 2,4 Tbps a lo largo de 1.170 km en Argentina (2.300 km de traza total)."}, "financial_robustness": {"score": 35, "rationale": "No se documenta un modelo financiero (CAPEX/OPEX, proyecciones de ingresos) para el tramo argentino en la fuente disponible."}, "sponsor_capacity": {"score": 85, "rationale": "Cirion Technologies es un operador de infraestructura de telecomunicaciones de trayectoria consolidada en la región, con redes de fibra internacionales ya operando."}, "market_demand": {"score": 50, "rationale": "Se menciona la demanda de capacidad transandina y +20 localidades beneficiadas, pero no hay clientes ancla ni cartas de intención documentadas."}, "environmental_social": {"score": 20, "rationale": "No se documenta una evaluación de impacto ambiental y social ni consulta con comunidades a lo largo de la traza."}, "risk_mitigation": {"score": 30, "rationale": "No se identifica un registro de riesgos ni mecanismos de mitigación (técnicos, financieros, cambiarios) en la fuente."}, "governance_reporting": {"score": 25, "rationale": "No se documentan estructuras de gobernanza ni mecanismos de reporte/monitoreo del proyecto."}, "rollout_readiness": {"score": 55, "rationale": "La traza ya está segmentada en 21 tramos con cronograma H2 2026–H2 2028, pero no se confirma el cierre de acuerdos de derecho de paso en cada tramo."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "medium", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "medium", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 47/100 (Estructuración Temprana). El proyecto combina alta madurez técnica (traza de 21 tramos, cable de 144 fibras G.652D, 2,4 Tbps de capacidad inicial) con un sponsor de trayectoria comprobada (Cirion Technologies), pero todavía carece de un modelo financiero documentado, una evaluación de impacto ambiental y social, y un registro de riesgos — brechas típicas de un cruce internacional que aún no cierra sus permisos binacionales. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de la lectura completa del documento fuente y de projects.description — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed',
    readiness_stage = coalesce(readiness_stage, 'Concept Stage'),
    updated_at = now()
where name = 'Proyecto Cruce Transandino (Andean Crossing Project)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ----------------------------------------------------------------------------
-- Red Federal de Centros Regionales de IA y Datos  (project_type = ai_datacenter)
-- overall_score = 26  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id,
  user_id,
  overall_score,
  stage,
  dimensions,
  gap_roadmap,
  financing_recommendations,
  summary,
  raw_model_output,
  source
)
values (
  (select id from public.projects
     where name = 'Red Federal de Centros Regionales de IA y Datos'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  26,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 25, "rationale": "Es una propuesta institucional presentada a ENACOM, pero no se documentan permisos, habilitaciones de uso de suelo ni licencias específicas para los nodos propuestos."}, "technical_maturity": {"score": 40, "rationale": "Define parámetros iniciales (datacenter edge/micro, refrigeración por aire forzado, escala menor a 1 MW) pero sin selección de proveedores ni especificaciones de servidores concretas."}, "financial_robustness": {"score": 20, "rationale": "No se documenta un modelo financiero (CAPEX/OPEX, estructura de capital) para ninguna de las tres etapas de despliegue propuestas."}, "sponsor_capacity": {"score": 25, "rationale": "CAPPI es una cámara que agrupa a pequeños proveedores de Internet, sin track record documentado en la construcción u operación de datacenters."}, "market_demand": {"score": 30, "rationale": "Se proyecta demanda de cómputo en la nube e IA a nivel regional, pero no hay clientes institucionales o empresariales con compromisos firmados."}, "environmental_social": {"score": 15, "rationale": "No se documenta evaluación de impacto ambiental y social para los nodos propuestos."}, "risk_mitigation": {"score": 15, "rationale": "No se identifica un registro de riesgos ni mecanismos de mitigación en la propuesta."}, "governance_reporting": {"score": 30, "rationale": "El plan escalonado en 3 etapas (piloto de 10 ISP a 12 meses, 50 nodos a 24 meses, 100+ nodos a 60 meses) aporta cierta estructura de hitos, pero sin gobernanza ni reportes definidos."}, "power_cooling_readiness": {"score": 30, "rationale": "El tipo de refrigeración está definido (aire forzado) pero no hay capacidad de suministro eléctrico contratada o asegurada para ningún nodo."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Reforzá la documentación de experiencia del sponsor o sumá un co-sponsor/socio EPC con trayectoria."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 26/100 (Estructuración Temprana, en el límite con Etapa de Concepto). La propuesta define un plan de despliegue en 3 etapas (piloto de 10 ISP, 50 nodos, 100+ nodos) y parámetros técnicos iniciales, pero como iniciativa institucional de una cámara de ISPs — no de un operador individual con track record de datacenters — todavía no cuenta con modelo financiero, evaluación ambiental/social ni capacidad de suministro eléctrico contratada. Foco prioritario: preparación ambiental y social, y mitigación de riesgos.$sum$,
  'Generado por Claude (Cowork) a partir de la lectura completa del documento fuente y de projects.description — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed',
    readiness_stage = coalesce(readiness_stage, 'Concept Stage'),
    updated_at = now()
where name = 'Red Federal de Centros Regionales de IA y Datos'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ----------------------------------------------------------------------------
-- Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal  (project_type = other)
-- overall_score = 22  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id,
  user_id,
  overall_score,
  stage,
  dimensions,
  gap_roadmap,
  financing_recommendations,
  summary,
  raw_model_output,
  source
)
values (
  (select id from public.projects
     where name = 'Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  22,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 45, "rationale": "Es una propuesta de marco regulatorio que toma como referencia explícita los regímenes de acceso compartido de Colombia y Brasil — buena base conceptual, aunque todavía no existe un instrumento regulatorio argentino sancionado."}, "technical_maturity": {"score": 10, "rationale": "No aplica un diseño técnico propio: es una propuesta de política/regulación, no una obra de infraestructura con especificaciones técnicas."}, "financial_robustness": {"score": 10, "rationale": "No se documenta un modelo financiero — la propuesta no involucra CAPEX/OPEX de una obra específica."}, "sponsor_capacity": {"score": 20, "rationale": "CAPPI actúa como impulsor institucional/de policy advocacy, no como ejecutor de infraestructura, por lo que no aplica una evaluación de capacidad de obra."}, "market_demand": {"score": 40, "rationale": "Identifica múltiples actores interesados en el acceso compartido (cooperativas eléctricas, distribuidoras provinciales, PyMEs, operadores regionales, organismos públicos), lo que respalda la demanda del marco propuesto."}, "environmental_social": {"score": 10, "rationale": "No aplica evaluación ambiental y social directa al tratarse de una propuesta regulatoria."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta un registro de riesgos para la implementación del marco propuesto."}, "governance_reporting": {"score": 25, "rationale": "La propuesta esboza roles institucionales de forma general, pero sin un mecanismo de gobernanza o reporte específico definido."}, "type_specific_readiness": {"score": 25, "rationale": "Los requisitos técnicos específicos de una implementación de acceso compartido (inventario de activos, metodología tarifaria) todavía no están desarrollados para el caso argentino."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Reforzá la documentación de experiencia del sponsor o sumá un co-sponsor/socio EPC con trayectoria."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 22/100 (Etapa de Concepto). Es una propuesta de marco regulatorio — no una obra física — que toma como referencia los regímenes de Colombia y Brasil; su punto más fuerte es la claridad regulatoria conceptual y la variedad de actores interesados identificados, pero al no tratarse de un proyecto de infraestructura no aplica un diseño técnico, modelo financiero ni evaluación ambiental propios. Foco prioritario: madurez técnica específica del proyecto.$sum$,
  'Generado por Claude (Cowork) a partir de la lectura completa del documento fuente y de projects.description — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed',
    readiness_stage = coalesce(readiness_stage, 'Concept Stage'),
    updated_at = now()
where name = 'Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ----------------------------------------------------------------------------
-- Plan Argentina Digital Federal 2040 - Corredores Digitales Ferroviarios  (project_type = fiber_backbone_last_mile)
-- overall_score = 31  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id,
  user_id,
  overall_score,
  stage,
  dimensions,
  gap_roadmap,
  financing_recommendations,
  summary,
  raw_model_output,
  source
)
values (
  (select id from public.projects
     where name = 'Plan Argentina Digital Federal 2040 - Corredores Digitales Ferroviarios'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  31,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 45, "rationale": "Se apoya en servidumbres y trazas ferroviarias ya existentes (ventaja real de acceso a terrenos), pero no se documenta un acuerdo formal con la autoridad ferroviaria ni permisos específicos por corredor."}, "technical_maturity": {"score": 55, "rationale": "Define opciones técnicas concretas (cables de 96/144/288 fibras, compatibilidad DWDM) con distintos escenarios de capacidad."}, "financial_robustness": {"score": 15, "rationale": "No se documenta un modelo financiero ni presupuesto para el despliegue troncal nacional propuesto."}, "sponsor_capacity": {"score": 20, "rationale": "Es una propuesta institucional de CAPPI, sin un sponsor ejecutor individual con track record de despliegue de backbone a escala nacional."}, "market_demand": {"score": 45, "rationale": "Se plantea como complemento de la REFEFO y menciona municipios y localidades a lo largo de las trazas ferroviarias como beneficiarios potenciales, sin estudios de demanda formales."}, "environmental_social": {"score": 20, "rationale": "No se documenta evaluación de impacto ambiental y social, aunque el uso de trazas ferroviarias existentes podría reducir el impacto respecto de una traza nueva."}, "risk_mitigation": {"score": 15, "rationale": "No se identifica un registro de riesgos para el despliegue propuesto."}, "governance_reporting": {"score": 20, "rationale": "No se definen estructuras de gobernanza ni mecanismos de reporte para la ejecución del plan."}, "rollout_readiness": {"score": 40, "rationale": "Las servidumbres ferroviarias preexistentes facilitan el acceso a la traza, pero la estrategia de distribución de última milla y conexión de clientes en cada corredor no está detallada."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Reforzá la documentación de experiencia del sponsor o sumá un co-sponsor/socio EPC con trayectoria."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "medium", "action": "Asegurá los acuerdos de derecho de paso y acceso a ductos/postes antes de finalizar el cronograma de despliegue."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 31/100 (Estructuración Temprana). Aprovecha servidumbres y trazas ferroviarias ya existentes en todo el país (ventaja real para el acceso a terrenos) y define opciones técnicas de 96/144/288 fibras compatibles con DWDM, pero — igual que otras propuestas institucionales de CAPPI — todavía no tiene modelo financiero, evaluación ambiental/social ni un sponsor ejecutor individual con track record. Foco prioritario: robustez financiera.$sum$,
  'Generado por Claude (Cowork) a partir de la lectura completa del documento fuente y de projects.description — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed',
    readiness_stage = coalesce(readiness_stage, 'Concept Stage'),
    updated_at = now()
where name = 'Plan Argentina Digital Federal 2040 - Corredores Digitales Ferroviarios'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ----------------------------------------------------------------------------
-- Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta  (project_type = fiber_backbone_last_mile)
-- overall_score = 61  |  stage = Advanced Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id,
  user_id,
  overall_score,
  stage,
  dimensions,
  gap_roadmap,
  financing_recommendations,
  summary,
  raw_model_output,
  source
)
values (
  (select id from public.projects
     where name = 'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  61,
  'Advanced Structuring',
$dims${"legal_regulatory": {"score": 70, "rationale": "CEPA es una cooperativa eléctrica ya regulada que presta servicios de telecomunicaciones — la carpeta técnica no reporta disputas legales ni incertidumbres regulatorias pendientes."}, "technical_maturity": {"score": 85, "rationale": "Diseño técnico GPON detallado con equipamiento específico (OLT/ONT Huawei MA5800-X7/EA5800-X7, fibra y hardware Furukawa, splitters 1:64)."}, "financial_robustness": {"score": 65, "rationale": "Presupuesto de inversión desglosado por categoría (USD 457.780,07 / $650.047.693,72 ARS) con fuente de financiamiento identificada (línea de crédito de Banco Nación más fondos propios), aunque sin proyecciones de ingresos/tarifas ni pruebas de estrés documentadas."}, "sponsor_capacity": {"score": 80, "rationale": "CEPA ya opera una red HFC/FTTH existente — track record comprobado como prestador, no un sponsor nuevo sin historial."}, "market_demand": {"score": 75, "rationale": "Reporta 13.500 hogares como base concreta de suscriptores HFC en migración a FTTH — demanda ya demostrada, no proyectada."}, "environmental_social": {"score": 30, "rationale": "No se documenta una evaluación de impacto ambiental y social formal ni consulta con la comunidad en la carpeta técnica."}, "risk_mitigation": {"score": 25, "rationale": "No se documenta un registro de riesgos formal ni mecanismos de mitigación en la carpeta técnica."}, "governance_reporting": {"score": 40, "rationale": "Como cooperativa regulada existe gobernanza estatutaria (asamblea de socios), pero la carpeta técnica no documenta mecanismos de reporte/monitoreo específicos para este proyecto."}, "rollout_readiness": {"score": 75, "rationale": "Equipamiento ya especificado y proyecto dividido en 4 etapas, construyendo sobre una red HFC existente — alta preparación para el despliegue."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "medium", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "low", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}]$gap$::jsonb,
$fin$[{"mechanism": "Universal Service Funds", "rationale": "Este proyecto reporta una cantidad concreta de beneficiarios alcanzados en una zona desatendida — un buen candidato para una línea de crédito a tasa subsidiada o subsidio de un Fondo de Servicio Universal nacional (por ejemplo, el Fondo de Servicio Universal de ENACOM en Argentina)."}, {"mechanism": "Public-Private Partnerships", "rationale": "Los proyectos en estructuración avanzada suelen estar bien posicionados para una estructura de APP una vez cerradas las brechas restantes."}]$fin$::jsonb,
$sum$Puntaje de preparación 61/100 (Estructuración Avanzada) — el más alto de los seis proyectos cargados. Es la única carpeta técnica de un operador ya en funcionamiento (Cooperativa Eléctrica de Punta Alta), con diseño técnico GPON detallado, presupuesto de inversión desglosado (USD 457.780,07) y una línea de crédito de Banco Nación ya identificada como fuente de financiamiento — además reporta 13.500 hogares beneficiarios concretos, lo que la habilita para el Fondo de Servicio Universal. Las brechas principales son la falta de un registro formal de riesgos y de una evaluación de impacto ambiental y social documentada. Foco prioritario: cobertura de mitigación de riesgos.$sum$,
  'Generado por Claude (Cowork) a partir de la lectura completa del documento fuente y de projects.description — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed',
    readiness_stage = coalesce(readiness_stage, 'Concept Stage'),
    updated_at = now()
where name = 'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ----------------------------------------------------------------------------
-- Patagonia - Hub de Infraestructura de IA para el Sur Global  (project_type = ai_datacenter)
-- overall_score = 23  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id,
  user_id,
  overall_score,
  stage,
  dimensions,
  gap_roadmap,
  financing_recommendations,
  summary,
  raw_model_output,
  source
)
values (
  (select id from public.projects
     where name = 'Patagonia - Hub de Infraestructura de IA para el Sur Global'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  23,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 30, "rationale": "Menciona el régimen RIGI (estabilidad regulatoria a 30 años) como marco habilitante general, pero no hay un beneficio RIGI solicitado o aprobado para un proyecto concreto; el propio documento señala la inestabilidad macroeconómica y los controles de cambio como riesgo regulatorio abierto."}, "technical_maturity": {"score": 35, "rationale": "Da parámetros de referencia de la industria (PUE 1,15-1,25, refrigeración DLC, densidad 50-200 kW/rack) como objetivos, pero sin un diseño técnico específico para un sitio elegido entre los tres corredores candidatos."}, "financial_robustness": {"score": 20, "rationale": "Solo presenta rangos comparativos de CAPEX/OPEX de la industria (USD 4-8 M/MW, USD 15-30/MWh) — no hay un modelo financiero propio del proyecto ni estructura de capital definida."}, "sponsor_capacity": {"score": 10, "rationale": "No hay un sponsor ejecutor nombrado: Ciena Corporation es un fabricante de equipamiento de redes que publica el análisis de oportunidad, no un desarrollador o inversor comprometido con la obra."}, "market_demand": {"score": 25, "rationale": "Describe cualitativamente un público objetivo (operadores de nube/IA globales que buscan jurisdicciones no alineadas) sin clientes ancla ni cartas de intención."}, "environmental_social": {"score": 5, "rationale": "No se documenta evaluación de impacto ambiental y social para ninguno de los tres corredores candidatos."}, "risk_mitigation": {"score": 45, "rationale": "Es el punto más desarrollado del documento: un mapa explícito de riesgos y habilitadores en 5 categorías (energía, conectividad, regulatorio, logística, talento) con mitigantes identificados para cada una."}, "governance_reporting": {"score": 5, "rationale": "No se documentan estructuras de gobernanza ni mecanismos de reporte — coherente con que el documento es un análisis de oportunidad, no la carpeta de un proyecto en ejecución."}, "power_cooling_readiness": {"score": 30, "rationale": "Define un enfoque de refrigeración (DLC, independiente de la humedad) y una estrategia de mix energético (eólico + gas + almacenamiento futuro) a nivel conceptual, pero sin suministro eléctrico contratado para ningún sitio específico."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Reforzá la documentación de experiencia del sponsor o sumá un co-sponsor/socio EPC con trayectoria."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 23/100 (Etapa de Concepto). Es un análisis de oportunidad estratégica de un proveedor de tecnología (Ciena Corporation), no la carpeta de un proyecto con sponsor ejecutor, sitio único ni presupuesto comprometido: evalúa tres corredores candidatos (Neuquén-Cipolletti, Puerto Madryn-Comodoro, Río Grande-Ushuaia) con parámetros de referencia de la industria en vez de un diseño específico de sitio. Su mapa de riesgos y habilitadores (energía, conectividad, regulatorio, logística, talento) es, paradójicamente, el aspecto más desarrollado del documento. Foco prioritario: gobernanza y reportes.$sum$,
  'Generado por Claude (Cowork) a partir de la lectura completa del documento fuente y de projects.description — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed',
    readiness_stage = coalesce(readiness_stage, 'Concept Stage'),
    updated_at = now()
where name = 'Patagonia - Hub de Infraestructura de IA para el Sur Global'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ============================================================================
-- Verificacion: los 6 proyectos con su analisis recien insertado
-- ============================================================================
select
  p.name,
  p.project_type,
  p.status,
  p.readiness_stage as workflow_stage,
  fa.overall_score,
  fa.stage as score_derived_stage,
  fa.source,
  fa.created_at
from public.projects p
join public.framework_analysis fa on fa.project_id = p.id
where p.user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')
order by fa.overall_score desc;

-- ============================================================================
-- NOTA sobre readiness_stage vs. framework_analysis.stage
-- La app distingue el "score derivado" (framework_analysis.stage, lo que
-- califica este analisis) del "stage de flujo de trabajo"
-- (projects.readiness_stage, que solo un advisor mueve manualmente con
-- promote_project_workflow()/demote_project_workflow() en
-- app/project.html). Por eso este script solo mueve readiness_stage a
-- 'Concept Stage' la PRIMERA vez (si estaba null) y no lo salta
-- directamente a 'Advanced Structuring' aunque el score de Punta Alta
-- (61/100) lo amerite — exactamente el mismo comportamiento que
-- submitManualAssessment() en assets/platform.js. Si queres que Punta Alta
-- (o cualquier otro) avance de etapa de flujo de trabajo, hacelo desde
-- app/project.html como advisor, o pedime el UPDATE correspondiente.
-- ============================================================================
