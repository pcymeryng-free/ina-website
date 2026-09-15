-- ============================================================================
-- Analisis IA (Investment Readiness Index (TM)) para los 18 proyectos que
-- quedaron en status = 'submitted' tras cargar
-- supabase/data_pipeline_proyectos_planilla_ago2026.sql — inserta un
-- framework_analysis por proyecto y actualiza projects.status /
-- projects.readiness_stage. Mismo formato y motor de scoring que
-- supabase/data_ai_analysis_all_projects.sql.
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
-- proyecto (rollout_readiness para fibra, route_feasibility para cable
-- submarino, spectrum_site_readiness para FWA, neutrality_interconnection_
-- readiness para red mayorista neutral, power_cooling_readiness para
-- datacenter de IA, orbital_spectrum_coordination para satelital,
-- shared_access_readiness para infraestructura pasiva, type_specific_
-- readiness para 'other'). Cada dimension va de 0 a 100, el overall_score
-- es el promedio redondeado de las 9, y el stage se deriva del
-- overall_score exactamente como stageForScore() en platform.js (<=25
-- Concept Stage, <=50 Early Structuring, <=75 Advanced Structuring, >75
-- Investment Ready).
--
-- COMO SE HIZO — LEER ANTES DE CORRER (misma salvedad que el analisis
-- anterior)
-- Esto NO es una corrida real de /api/analyze-project.js. Es un analisis
-- generado por mi (Claude, en esta sesion de Cowork) leyendo el texto
-- completo de projects.description de cada uno de los 18 proyectos —
-- calificando honestamente cada dimension SOLO con lo que esta
-- documentado ahi, sin inventar datos. Uso el mismo formato de salida y
-- las mismas frases exactas de RECOMMENDATION_TIPS y
-- STAGE_FINANCING_SUGGESTION que ya estan en el codigo. Marque source='ai'
-- por el mismo motivo que el analisis anterior.
--
-- POR QUE LOS PUNTAJES SON BAJOS EN GENERAL
-- Los 18 proyectos vienen de una planilla de seguimiento (pipeline), no de
-- carpetas tecnicas — la mayoria tiene una sola descripcion corta, sin
-- diseño tecnico, modelo financiero, evaluacion ambiental ni registro de
-- riesgos documentados. Esto es honesto y esperable en esta etapa
-- temprana del pipeline — no es un error de carga. El ranking relativo
-- sigue una logica consistente: los sponsors con trayectoria real y
-- verificable (ARSAT, Starlink/SpaceX, CALF, EPECH, Etisalat) puntuan mas
-- alto en sponsor_capacity que los genericos ("Telcos", "Internet
-- Service"); los que ya aportan una cifra de presupuesto o un mecanismo
-- de financiamiento concreto (CALF con su Obligacion Negociable, ARSAT con
-- presupuesto + FSU) puntuan mejor en financial_robustness; y los
-- proyectos que reutilizan infraestructura o tecnologia ya existente
-- (ARSAT modernizando la REFEFO, Starlink con su constelacion ya operativa)
-- puntuan sensiblemente mejor en madurez tecnica y en su 9na dimension
-- especifica que los proyectos greenfield sin ningun dato tecnico.
--
-- REQUISITOS PARA CORRER ESTE SCRIPT
-- 1. Los 18 proyectos ya tienen que existir en public.projects — es decir,
--    ya corriste supabase/data_pipeline_proyectos_planilla_ago2026.sql en
--    este mismo proyecto de Supabase.
-- 2. EDITAR mas abajo si el email del dueno de los proyectos no es
--    'pcymeryng@gmail.com' (el que se uso por default en ese script).
-- 3. Ejecuta el script completo. Al final corre un SELECT de verificacion
--    que muestra los 18 proyectos con su score y stage nuevo.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- Atlántico-Pacífico — Troncal FO Región Andina (Futaleufú)-Trelew  (fiber_backbone_last_mile)
-- overall_score = 22  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Atlántico-Pacífico — Troncal FO Región Andina (Futaleufú)-Trelew'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  22,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 20, "rationale": "No hay permisos ni habilitaciones documentados para la traza; la planilla de origen no aclara el estado de derechos de paso."}, "technical_maturity": {"score": 30, "rationale": "Se define que la traza sigue el tendido eléctrico de EPECH, pero no hay conteo de fibras, capacidad ni proveedor especificados."}, "financial_robustness": {"score": 10, "rationale": "No se informa presupuesto propio para este tramo en la planilla de origen."}, "sponsor_capacity": {"score": 55, "rationale": "EPECH es una empresa provincial de energía con infraestructura de transporte eléctrico real y en operación, aunque sin trayectoria documentada como operador de telecomunicaciones."}, "market_demand": {"score": 20, "rationale": "No se documentan clientes ancla ni estudios de demanda para este tramo específico."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental y social."}, "risk_mitigation": {"score": 10, "rationale": "No se identifica un registro de riesgos."}, "governance_reporting": {"score": 15, "rationale": "No se documentan mecanismos de gobernanza o reporte específicos del proyecto."}, "rollout_readiness": {"score": 30, "rationale": "Aprovechar la traza de la línea eléctrica existente es una ventaja real de acceso, pero no hay cronograma ni acuerdos de derecho de paso confirmados."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 22/100 (Etapa de Concepto). El tramo aprovecha la traza de la línea de transporte eléctrico de EPECH como ventaja real de acceso, pero la planilla de origen no informa presupuesto propio, evaluación ambiental ni registro de riesgos para este componente. Foco prioritario: robustez del modelo financiero.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Atlántico-Pacífico — Troncal FO Región Andina (Futaleufú)-Trelew'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Atlántico-Pacífico — Tramo Terrestre Esquel-Chaitén-Puerto Montt  (fiber_backbone_last_mile)
-- overall_score = 22  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Atlántico-Pacífico — Tramo Terrestre Esquel-Chaitén-Puerto Montt'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  22,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 15, "rationale": "Cruza la cordillera hacia Chile; no se documentan permisos binacionales ni acuerdos de derecho de paso en ninguno de los dos países."}, "technical_maturity": {"score": 25, "rationale": "Se conoce la distancia (500 km) y el trazado, pero no hay especificación de cable ni proveedor."}, "financial_robustness": {"score": 25, "rationale": "La planilla informa un rango de USD 35M a 60M (se cargó el punto medio en budget_amount_usd), pero sin modelo financiero ni estructura de capital."}, "sponsor_capacity": {"score": 50, "rationale": "EPECH aporta experiencia real en infraestructura de transporte, aunque no en despliegues internacionales de fibra."}, "market_demand": {"score": 20, "rationale": "Sin estudios de demanda ni clientes ancla documentados para el tramo transcordillerano."}, "environmental_social": {"score": 10, "rationale": "El cruce de cordillera plantea consideraciones ambientales reales que no están abordadas en la fuente."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 15, "rationale": "No se definen estructuras de gobernanza para este tramo."}, "rollout_readiness": {"score": 25, "rationale": "No se confirma el estado de los acuerdos de derecho de paso binacionales necesarios para avanzar el cronograma."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 22/100 (Etapa de Concepto). Es un tramo transfronterizo (Argentina-Chile) con una estimación de presupuesto (USD 47,5M, punto medio del rango informado) pero sin permisos binacionales, evaluación ambiental ni registro de riesgos documentados. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Atlántico-Pacífico — Tramo Terrestre Esquel-Chaitén-Puerto Montt'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Atlántico-Pacífico — Cable Submarino Trelew (AR)-Punta del Este (UY)  (submarine_cable)
-- overall_score = 18  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Atlántico-Pacífico — Cable Submarino Trelew (AR)-Punta del Este (UY)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  18,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 15, "rationale": "Un cable submarino con estaciones de aterrizaje en dos países requiere habilitaciones marítimas y de telecomunicaciones en ambas jurisdicciones, ninguna documentada."}, "technical_maturity": {"score": 20, "rationale": "Solo se conoce la distancia (1.500 km); no hay especificación del sistema de cable, capacidad ni estaciones de aterrizaje."}, "financial_robustness": {"score": 25, "rationale": "La planilla informa un rango de USD 120M a 180M (se cargó el punto medio), sin modelo financiero."}, "sponsor_capacity": {"score": 30, "rationale": "EPECH es una empresa de energía provincial sin trayectoria documentada en cables submarinos, un tipo de proyecto que típicamente requiere un operador especializado."}, "market_demand": {"score": 20, "rationale": "No se documentan clientes ancla ni compromisos de capacidad para la salida internacional."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental de las obras marinas."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 15, "rationale": "No se definen estructuras de gobernanza."}, "route_feasibility": {"score": 15, "rationale": "No hay estudio de ruta marina ni selección de sitios de aterrizaje documentados."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Completá el estudio de ruta marina y asegurá los permisos de las estaciones de aterrizaje temprano — tienen plazos largos."}, {"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 18/100 (Etapa de Concepto), el más bajo de los cinco componentes del corredor Atlántico-Pacífico. Es el componente que más se aparta del perfil de su sponsor (EPECH, una empresa de energía sin trayectoria en cables submarinos) y carece de estudio de ruta marina, permisos binacionales y modelo financiero. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Atlántico-Pacífico — Cable Submarino Trelew (AR)-Punta del Este (UY)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Atlántico-Pacífico — Datacenter Tier IV en Tándem (2 sedes) + HW IA  (ai_datacenter)
-- overall_score = 21  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Atlántico-Pacífico — Datacenter Tier IV en Tándem (2 sedes) + HW IA'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  21,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 15, "rationale": "No se documentan habilitaciones de uso de suelo ni licencias específicas para las dos sedes propuestas."}, "technical_maturity": {"score": 35, "rationale": "Definir el estándar Tier IV como objetivo es un dato técnico concreto, pero no hay diseño de sitio, proveedor de hardware ni especificaciones de servidores."}, "financial_robustness": {"score": 25, "rationale": "La planilla informa un rango de USD 110M a 160M (se cargó el punto medio), sin estructura de financiamiento."}, "sponsor_capacity": {"score": 40, "rationale": "EPECH aporta experiencia real en gestión de infraestructura eléctrica — relevante para un datacenter — pero sin trayectoria operando centros de datos."}, "market_demand": {"score": 15, "rationale": "No se documentan clientes de cómputo/IA ni compromisos de capacidad."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 15, "rationale": "No se definen estructuras de gobernanza."}, "power_cooling_readiness": {"score": 25, "rationale": "El trasfondo de EPECH como empresa de energía es una ventaja potencial para esta dimensión específica, pero no hay capacidad eléctrica contratada ni diseño de refrigeración documentados."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 21/100 (Etapa de Concepto). El objetivo de estándar Tier IV y el trasfondo energético de EPECH son puntos de partida relevantes, pero el componente carece de diseño de sitio, capacidad eléctrica contratada y modelo financiero. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Atlántico-Pacífico — Datacenter Tier IV en Tándem (2 sedes) + HW IA'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Atlántico-Pacífico — Amarre: Obra Civil y Contingencia  (passive_infrastructure)
-- overall_score = 19  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Atlántico-Pacífico — Amarre: Obra Civil y Contingencia'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  19,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 15, "rationale": "No se documentan permisos de obra civil ni habilitaciones para las obras de amarre."}, "technical_maturity": {"score": 20, "rationale": "No hay ingeniería de detalle de las obras civiles ni de contingencia."}, "financial_robustness": {"score": 25, "rationale": "La planilla informa un rango de USD 40M a 70M (se cargó el punto medio), sin desglose de costos."}, "sponsor_capacity": {"score": 45, "rationale": "EPECH tiene capacidad real de ejecución de obra civil como empresa de infraestructura provincial."}, "market_demand": {"score": 15, "rationale": "La demanda de este componente depende enteramente del resto del corredor; no hay evaluación propia."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental de las obras de amarre."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos ni de contingencia, pese a que el componente se llama justamente contingencia."}, "governance_reporting": {"score": 15, "rationale": "No se definen estructuras de gobernanza."}, "shared_access_readiness": {"score": 15, "rationale": "No hay inventario de activos ni acuerdos de acceso compartido documentados."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Completá el inventario de activos y formalizá los acuerdos de acceso/comparticion (o el camino regulatorio hacia ellos) con cada propietario de infraestructura antes de comprometer un cronograma de despliegue."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 19/100 (Etapa de Concepto). Es infraestructura de soporte del corredor Atlántico-Pacífico, sin ingeniería de detalle ni registro de riesgos propio pese a estar nombrada como componente de contingencia. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Atlántico-Pacífico — Amarre: Obra Civil y Contingencia'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Cable Submarino PUMA (Argentina-Sudáfrica)  (submarine_cable)
-- overall_score = 14  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Cable Submarino PUMA (Argentina-Sudáfrica)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  14,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 10, "rationale": "No se documenta ningún avance regulatorio ni de permisos para las estaciones de aterrizaje en Argentina o Sudáfrica."}, "technical_maturity": {"score": 10, "rationale": "La descripción de la planilla es explícita en que no hay tecnología, presupuesto ni cronograma detallados todavía."}, "financial_robustness": {"score": 5, "rationale": "No hay ninguna cifra de presupuesto ni fuente de financiamiento documentada."}, "sponsor_capacity": {"score": 60, "rationale": "Etisalat es un operador de telecomunicaciones internacional de gran escala, con trayectoria real en despliegue de infraestructura — un sponsor de peso pese a la falta de detalle del proyecto en sí."}, "market_demand": {"score": 15, "rationale": "La ruta Argentina-Sudáfrica sugiere una intención estratégica de conectividad Sur-Sur, sin estudios de demanda documentados."}, "environmental_social": {"score": 5, "rationale": "No se documenta ninguna evaluación ambiental."}, "risk_mitigation": {"score": 5, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 10, "rationale": "No se documentan estructuras de gobernanza."}, "route_feasibility": {"score": 5, "rationale": "No hay estudio de ruta marina ni sitios de aterrizaje identificados."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Completá el estudio de ruta marina y asegurá los permisos de las estaciones de aterrizaje temprano — tienen plazos largos."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 14/100 (Etapa de Concepto) — el dato más notable es que el sponsor, Etisalat, es un operador internacional de telecomunicaciones con trayectoria real en despliegues de gran escala; sin embargo, la planilla de origen es explícita en que el proyecto en sí todavía no tiene tecnología, presupuesto ni cronograma definidos. Foco prioritario: robustez del modelo financiero.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Cable Submarino PUMA (Argentina-Sudáfrica)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Tramo Bioceánico Norte (Salta)  (fiber_backbone_last_mile)
-- overall_score = 16  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Tramo Bioceánico Norte (Salta)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  16,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 15, "rationale": "No se documentan permisos para el paso fronterizo de Jama ni habilitaciones locales."}, "technical_maturity": {"score": 15, "rationale": "No hay especificación de tecnología ni proveedor, más allá del propósito mayorista."}, "financial_robustness": {"score": 5, "rationale": "No se informa presupuesto ni fuente de financiamiento."}, "sponsor_capacity": {"score": 25, "rationale": "Comtec es un operador regional sin trayectoria documentada en la fuente disponible."}, "market_demand": {"score": 35, "rationale": "Nombrar 20 localidades salteñas y complejos mineros como beneficiarios es un dato de demanda concreto, aunque sin estudios formales ni cartas de intención."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 10, "rationale": "No se documentan estructuras de gobernanza."}, "rollout_readiness": {"score": 15, "rationale": "No hay cronograma ni acuerdos de derecho de paso documentados para el corredor hacia Chile."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 16/100 (Etapa de Concepto). Nombrar 20 localidades y complejos mineros como beneficiarios es el dato más sólido de la propuesta, pero no hay presupuesto, tecnología ni registro de riesgos documentados. Foco prioritario: robustez del modelo financiero.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Tramo Bioceánico Norte (Salta)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- CALF — Anillo Mayorista de Fibra Óptica (Neuquén)  (wholesale_neutral_network)
-- overall_score = 26  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'CALF — Anillo Mayorista de Fibra Óptica (Neuquén)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  26,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 20, "rationale": "No se documentan permisos específicos para el anillo, más allá del estatus regulado de CALF como cooperativa."}, "technical_maturity": {"score": 35, "rationale": "Nokia como proveedor de tecnología es un dato concreto, pero no hay diseño de topología ni dimensionamiento de red."}, "financial_robustness": {"score": 40, "rationale": "El presupuesto de USD 100M y un mecanismo de financiamiento concreto (Obligación Negociable) son dos señales financieras reales — más avanzado que una simple estimación, aunque sin modelo financiero completo."}, "sponsor_capacity": {"score": 55, "rationale": "CALF es una cooperativa eléctrica del Alto Valle con trayectoria real y consolidada en la región."}, "market_demand": {"score": 20, "rationale": "No se documentan estudios de demanda ni clientes mayoristas comprometidos."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental."}, "risk_mitigation": {"score": 15, "rationale": "No se documenta registro de riesgos formal, aunque contar con una Obligación Negociable ya implica cierto escrutinio financiero previo."}, "governance_reporting": {"score": 20, "rationale": "Como cooperativa, CALF tiene una estructura de gobernanza estatutaria, aunque no se documentan mecanismos de reporte específicos para este proyecto."}, "neutrality_interconnection_readiness": {"score": 15, "rationale": "No se documenta interconexión con la REFEFO ni un esquema de compartición de red (RAN sharing)."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Finalizá el diseño de topología/dimensionamiento de la red y asegurá la interconexión con la REFEFO y un esquema de compartición de red (RAN sharing) — son los criterios que ENACOM pondera con más peso para la elegibilidad de la Red Mayorista Neutral."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 26/100 (Estructuración Temprana) — el más alto entre los proyectos nuevos de la planilla. CALF es una cooperativa con trayectoria real, tecnología Nokia definida, presupuesto informado y un mecanismo de financiamiento concreto (Obligación Negociable), pero todavía sin evaluación ambiental, registro de riesgos ni esquema de interconexión con la REFEFO. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'CALF — Anillo Mayorista de Fibra Óptica (Neuquén)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Internet Service — Red Mayorista de Fibra Óptica (Entre Ríos)  (wholesale_neutral_network)
-- overall_score = 14  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Internet Service — Red Mayorista de Fibra Óptica (Entre Ríos)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  14,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 15, "rationale": "No se documentan permisos ni habilitaciones para la red mayorista."}, "technical_maturity": {"score": 25, "rationale": "Nokia como proveedor de tecnología es un dato concreto, pero sin diseño de topología ni dimensionamiento."}, "financial_robustness": {"score": 15, "rationale": "Se marca un mecanismo de financiamiento (Obligación Negociable) pero sin monto ni presupuesto total documentado."}, "sponsor_capacity": {"score": 20, "rationale": "Internet Service es un operador sin trayectoria documentada en la fuente disponible."}, "market_demand": {"score": 15, "rationale": "No se documentan estudios de demanda ni clientes mayoristas."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 10, "rationale": "No se documentan estructuras de gobernanza."}, "neutrality_interconnection_readiness": {"score": 10, "rationale": "No se documenta interconexión con la REFEFO ni esquema de compartición de red."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Finalizá el diseño de topología/dimensionamiento de la red y asegurá la interconexión con la REFEFO y un esquema de compartición de red (RAN sharing) — son los criterios que ENACOM pondera con más peso para la elegibilidad de la Red Mayorista Neutral."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 14/100 (Etapa de Concepto). A diferencia de CALF, esta red mayorista en Entre Ríos marca un mecanismo de financiamiento (Obligación Negociable) pero sin monto, presupuesto total ni trayectoria documentada del sponsor. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Internet Service — Red Mayorista de Fibra Óptica (Entre Ríos)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- ARSAT — Modernización REFEFO (Renovación Tecnológica)  (fiber_backbone_last_mile)
-- overall_score = 35  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'ARSAT — Modernización REFEFO (Renovación Tecnológica)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  35,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 40, "rationale": "Al modernizar una red ya operada por ARSAT bajo su marco regulatorio existente, el riesgo de permisos es menor que en un despliegue nuevo, aunque no se documentan habilitaciones específicas para esta renovación."}, "technical_maturity": {"score": 45, "rationale": "Nokia y Ciena como proveedores, y tratarse de una actualización de una red troncal ya construida y en operación, dan una base técnica concreta."}, "financial_robustness": {"score": 30, "rationale": "Se informa un presupuesto de USD 100M, pero sin estructura de financiamiento ni modelo documentado."}, "sponsor_capacity": {"score": 70, "rationale": "ARSAT es la empresa estatal de telecomunicaciones de Argentina, con una red federal de fibra óptica (REFEFO) real y en operación — el sponsor con mayor trayectoria comprobada de este lote."}, "market_demand": {"score": 35, "rationale": "La REFEFO ya sirve demanda real a nivel nacional; la modernización responde a una necesidad existente, no proyectada."}, "environmental_social": {"score": 15, "rationale": "Al ser una actualización de red existente, el impacto ambiental incremental es previsiblemente menor que un despliegue nuevo, aunque no hay evaluación documentada."}, "risk_mitigation": {"score": 15, "rationale": "No se documenta registro de riesgos para esta renovación específica."}, "governance_reporting": {"score": 25, "rationale": "Como empresa estatal, ARSAT tiene supervisión institucional inherente, aunque no se documentan mecanismos de reporte específicos para este proyecto."}, "rollout_readiness": {"score": 40, "rationale": "Modernizar una red ya desplegada es una ventaja de ejecución real frente a un proyecto greenfield, aunque no hay cronograma específico documentado."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "medium", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 35/100 (Estructuración Temprana). ARSAT es el sponsor con mayor trayectoria comprobada de los proyectos nuevos de la planilla — opera la REFEFO, la red federal de fibra ya existente — y esta es una modernización tecnológica sobre esa base, no un despliegue desde cero. Aun así, faltan modelo financiero, registro de riesgos y evaluación ambiental documentados. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'ARSAT — Modernización REFEFO (Renovación Tecnológica)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- ARSAT — Plan FWA 5G (1.000 localidades, 1a fase 100 localidades)  (fixed_wireless_access)
-- overall_score = 29  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'ARSAT — Plan FWA 5G (1.000 localidades, 1a fase 100 localidades)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  29,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 35, "rationale": "Como empresa estatal, ARSAT opera bajo el marco regulatorio de espectro existente, aunque no se documenta una asignación específica de espectro 5G para este plan."}, "technical_maturity": {"score": 35, "rationale": "Nokia como proveedor y un plan por fases (100 de 1.000 localidades en la primera etapa) son datos concretos, sin ingeniería de sitio específica."}, "financial_robustness": {"score": 35, "rationale": "Se informan dos cifras de financiamiento (USD 100M de presupuesto total y USD 15M de FSU), más avanzado que una sola estimación aislada."}, "sponsor_capacity": {"score": 65, "rationale": "ARSAT tiene trayectoria real como operador nacional de telecomunicaciones."}, "market_demand": {"score": 30, "rationale": "1.000 localidades objetivo es una meta de escala concreta, aunque sin sitios confirmados ni estudios de demanda formales."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 20, "rationale": "No se documentan mecanismos de reporte específicos para este plan."}, "spectrum_site_readiness": {"score": 20, "rationale": "No se documenta asignación confirmada de espectro ni estudios de línea de vista para los sitios."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Asegurá la asignación de espectro y completá los estudios de línea de vista antes de comprometer un cronograma de despliegue."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 29/100 (Estructuración Temprana). El plan de ARSAT define una meta de escala (1.000 localidades, primera fase de 100) y dos cifras de financiamiento (presupuesto total y monto FSU), pero carece de asignación de espectro confirmada, evaluación ambiental y registro de riesgos. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'ARSAT — Plan FWA 5G (1.000 localidades, 1a fase 100 localidades)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- ARSAT / Oracle — Datacenter de IA Distribuida (Mini Edge, 25 Sitios)  (ai_datacenter)
-- overall_score = 25  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'ARSAT / Oracle — Datacenter de IA Distribuida (Mini Edge, 25 Sitios)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  25,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 30, "rationale": "ARSAT opera bajo marco estatal existente, pero no se documentan habilitaciones específicas para los 25 sitios propuestos."}, "technical_maturity": {"score": 30, "rationale": "El formato mini edge/container y la asociación con Oracle son datos técnicos concretos, sin especificaciones por sitio."}, "financial_robustness": {"score": 20, "rationale": "Solo se informa el monto FSU (USD 25M) — no hay presupuesto total del proyecto documentado."}, "sponsor_capacity": {"score": 70, "rationale": "La combinación de ARSAT (operador estatal con trayectoria real) y Oracle (proveedor tecnológico global de primer nivel) es el sponsor conjunto más sólido de este lote."}, "market_demand": {"score": 20, "rationale": "No se documentan clientes de cómputo/IA ni compromisos de capacidad para los 25 sitios."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 20, "rationale": "No se documentan mecanismos de gobernanza específicos para la iniciativa conjunta."}, "power_cooling_readiness": {"score": 15, "rationale": "No hay capacidad eléctrica contratada ni diseño de refrigeración documentados para ninguno de los 25 sitios."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Contratá la capacidad eléctrica y finalizá el diseño de refrigeración temprano — suelen definir el camino crítico."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 25/100 (Etapa de Concepto). La asociación ARSAT/Oracle es el sponsor conjunto más fuerte del lote (operador estatal + proveedor tecnológico global), pero la iniciativa todavía no tiene presupuesto total, evaluación ambiental ni capacidad eléctrica contratada para ninguno de los 25 sitios mini edge propuestos. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'ARSAT / Oracle — Datacenter de IA Distribuida (Mini Edge, 25 Sitios)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Starlink — Conectividad Satelital para 6.000 Escuelas  (satellite_constellation)
-- overall_score = 35  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Starlink — Conectividad Satelital para 6.000 Escuelas'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  35,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 30, "rationale": "Starlink ya opera comercialmente en Argentina bajo licencia existente, aunque no se documentan habilitaciones específicas para el despliegue en 6.000 escuelas."}, "technical_maturity": {"score": 60, "rationale": "A diferencia de la mayoría de los proyectos de este lote, Starlink es una tecnología satelital ya operativa y probada a escala global — una base técnica sustancialmente más madura."}, "financial_robustness": {"score": 20, "rationale": "Solo se informa el monto FSU (USD 22M) — no hay presupuesto total del despliegue documentado."}, "sponsor_capacity": {"score": 80, "rationale": "SpaceX/Starlink es uno de los operadores satelitales más capaces a nivel global, con una constelación ya desplegada y operando — el sponsor de mayor solvencia técnica de todo el lote."}, "market_demand": {"score": 30, "rationale": "6.000 escuelas es una meta concreta y de escala nacional, aunque sin convenio formal documentado."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación de impacto ambiental."}, "risk_mitigation": {"score": 15, "rationale": "No se documenta registro de riesgos específico del despliegue, aunque la tecnología en sí ya está validada operativamente."}, "governance_reporting": {"score": 15, "rationale": "No se documentan mecanismos de gobernanza o reporte para el programa de 6.000 escuelas."}, "orbital_spectrum_coordination": {"score": 55, "rationale": "La constelación de Starlink ya tiene coordinación orbital y de espectro resuelta a nivel global — una ventaja real y sustancial frente a un proyecto satelital desde cero."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 35/100 (Estructuración Temprana). Starlink es el sponsor técnicamente más sólido del lote — una constelación satelital ya operativa, con coordinación orbital y de espectro resuelta — pero el programa de 6.000 escuelas todavía no tiene presupuesto total ni convenio formal documentado más allá del monto FSU. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Starlink — Conectividad Satelital para 6.000 Escuelas'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- ENACOM — Portales Conectados en Parques Nacionales  (satellite_constellation)
-- overall_score = 27  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'ENACOM — Portales Conectados en Parques Nacionales'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  27,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 40, "rationale": "ENACOM es el propio regulador impulsando la iniciativa — una posición regulatoria fuerte, aunque no se documentan los permisos específicos de instalación en Parques Nacionales (que involucran a otro organismo)."}, "technical_maturity": {"score": 30, "rationale": "Se apoya en tecnología satelital existente (Satelital/Starlink), pero sin lista de sitios ni ingeniería específica."}, "financial_robustness": {"score": 20, "rationale": "Solo se informa el monto FSU (USD 8M) — no hay presupuesto total documentado."}, "sponsor_capacity": {"score": 55, "rationale": "ENACOM como regulador nacional tiene capacidad institucional real, aunque no es un operador de infraestructura en sí mismo."}, "market_demand": {"score": 20, "rationale": "No se documenta la cantidad de portales o parques objetivo."}, "environmental_social": {"score": 15, "rationale": "El contexto de Parques Nacionales implica sensibilidad ambiental real que no está abordada en la fuente disponible."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 30, "rationale": "Al ser una iniciativa del propio regulador, hay una estructura de gobernanza institucional de base más fuerte que en un proyecto de un proponente privado, aunque sin mecanismos de reporte específicos documentados."}, "orbital_spectrum_coordination": {"score": 25, "rationale": "Depender de proveedores satelitales existentes reduce parte de la carga de coordinación propia, pero no hay presentaciones o acuerdos específicos documentados."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Avanzá las presentaciones de coordinación orbital/frecuencia y cerrá los términos con el proveedor de lanzamiento — ambos tienen plazos regulatorios largos."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 27/100 (Estructuración Temprana). Al ser impulsada por el propio regulador (ENACOM), la iniciativa parte de una posición institucional más sólida que otros proyectos del lote, pero todavía no define la cantidad de portales/parques objetivo, el presupuesto total ni una evaluación ambiental — relevante dado el contexto de áreas protegidas. Foco prioritario: cobertura de mitigación de riesgos.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'ENACOM — Portales Conectados en Parques Nacionales'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- YPF — Redes Privadas 5G  (other)
-- overall_score = 12  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'YPF — Redes Privadas 5G'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  12,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 10, "rationale": "No se documenta ningún dato regulatorio."}, "technical_maturity": {"score": 5, "rationale": "No hay ninguna especificación técnica más allá del nombre del proyecto."}, "financial_robustness": {"score": 5, "rationale": "No se informa presupuesto ni fuente de financiamiento."}, "sponsor_capacity": {"score": 50, "rationale": "YPF es una empresa nacional de energía de gran escala y solvencia, aunque no se documenta ningún dato del proyecto de redes 5G en sí."}, "market_demand": {"score": 10, "rationale": "No se documenta el uso previsto (interno/industrial) ni alcance."}, "environmental_social": {"score": 5, "rationale": "No se documenta evaluación ambiental."}, "risk_mitigation": {"score": 5, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 10, "rationale": "No se documentan estructuras de gobernanza."}, "type_specific_readiness": {"score": 5, "rationale": "No hay ningún requisito técnico específico documentado para esta iniciativa."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Documentá los requisitos técnicos específicos y los permisos especializados que requiere este tipo de proyecto."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 12/100 (Etapa de Concepto) — el dato de la planilla es prácticamente solo el nombre del proyecto y el sponsor. YPF aporta solvencia institucional real, pero no hay ningún otro dato documentado todavía. Foco prioritario: madurez del diseño técnico.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'YPF — Redes Privadas 5G'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- ENACOM — Modernización del Sistema de Control de Espectro  (other)
-- overall_score = 27  |  stage = Early Structuring
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'ENACOM — Modernización del Sistema de Control de Espectro'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  27,
  'Early Structuring',
$dims${"legal_regulatory": {"score": 45, "rationale": "Modernizar su propio sistema de control de espectro cae directamente dentro del mandato regulatorio de ENACOM — bajo riesgo de permisos externos, aunque sin detalle del proceso de contratación."}, "technical_maturity": {"score": 20, "rationale": "No se documenta proveedor ni especificación del sistema a modernizar."}, "financial_robustness": {"score": 30, "rationale": "Se informa un presupuesto de USD 60M, aunque la planilla no aclara la moneda con certeza para esta fila."}, "sponsor_capacity": {"score": 60, "rationale": "ENACOM tiene capacidad institucional real como regulador nacional para un proyecto de modernización de sus propios sistemas."}, "market_demand": {"score": 15, "rationale": "No aplica demanda de mercado en el sentido habitual — es una herramienta interna del regulador."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación ambiental."}, "risk_mitigation": {"score": 15, "rationale": "No se documenta registro de riesgos, aunque tratarse de un sistema regulatorio interno reduce parte del riesgo de ejecución típico de una obra de infraestructura."}, "governance_reporting": {"score": 35, "rationale": "Al ser un proyecto del propio regulador sobre sus propios sistemas, hay una gobernanza institucional de base más sólida que en un proyecto de un proponente externo."}, "type_specific_readiness": {"score": 15, "rationale": "No se documentan los requisitos técnicos específicos del sistema de control de espectro a modernizar."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Documentá los requisitos técnicos específicos y los permisos especializados que requiere este tipo de proyecto."}, {"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}]$gap$::jsonb,
$fin$[{"mechanism": "Blended Finance", "rationale": "El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala."}]$fin$::jsonb,
$sum$Puntaje de preparación 27/100 (Estructuración Temprana). Al modernizar su propio sistema de control de espectro, ENACOM parte de una posición regulatoria e institucional sólida, con un presupuesto informado (USD 60M, moneda a confirmar), pero sin proveedor ni especificación técnica del sistema todavía documentados. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'ENACOM — Modernización del Sistema de Control de Espectro'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- ENACOM — Marketplace de Espectro  (other)
-- overall_score = 19  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'ENACOM — Marketplace de Espectro'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  19,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 30, "rationale": "Un marketplace de espectro requiere su propio marco regulatorio habilitante; ENACOM tiene la potestad regulatoria pero el marco específico todavía no está documentado."}, "technical_maturity": {"score": 10, "rationale": "No se documenta ninguna especificación de la plataforma."}, "financial_robustness": {"score": 5, "rationale": "No se informa presupuesto ni alcance."}, "sponsor_capacity": {"score": 55, "rationale": "ENACOM tiene capacidad institucional real como regulador, aunque el proyecto en sí carece de casi todo detalle."}, "market_demand": {"score": 15, "rationale": "No se documenta demanda ni interesados en el mercado secundario de espectro."}, "environmental_social": {"score": 5, "rationale": "No aplica evaluación ambiental típica, pero tampoco hay ningún dato de alcance del proyecto."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 30, "rationale": "Como iniciativa regulatoria del propio ENACOM, parte de una base institucional más sólida, aunque sin mecanismos de reporte específicos documentados."}, "type_specific_readiness": {"score": 10, "rationale": "No se documentan los requisitos técnicos ni regulatorios específicos de un marketplace de espectro."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "No aplica evaluación ambiental típica, pero conviene documentar formalmente el alcance del proyecto."}, {"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Documentá los requisitos técnicos específicos y los permisos especializados que requiere este tipo de proyecto."}, {"priority": "high", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 19/100 (Etapa de Concepto). Es la iniciativa más preliminar del lote de ENACOM — apenas el nombre y el propósito general de un mercado secundario de espectro, sin presupuesto, alcance ni marco regulatorio específico documentados todavía. Foco prioritario: robustez del modelo financiero.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'ENACOM — Marketplace de Espectro'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ----------------------------------------------------------------------------
-- Telcos — Programa Play (Sitios Móviles)  (passive_infrastructure)
-- overall_score = 13  |  stage = Concept Stage
-- ----------------------------------------------------------------------------
insert into public.framework_analysis (
  project_id, user_id, overall_score, stage, dimensions, gap_roadmap,
  financing_recommendations, summary, raw_model_output, source
)
values (
  (select id from public.projects
     where name = 'Telcos — Programa Play (Sitios Móviles)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  13,
  'Concept Stage',
$dims${"legal_regulatory": {"score": 15, "rationale": "No se documentan permisos ni habilitaciones para el despliegue de sitios."}, "technical_maturity": {"score": 10, "rationale": "No se documenta cantidad de sitios ni especificación técnica."}, "financial_robustness": {"score": 10, "rationale": "Se marca financiamiento previsto vía FSU, pero sin monto definido en la planilla de origen."}, "sponsor_capacity": {"score": 20, "rationale": "Telcos es una referencia genérica a operadores móviles, sin un operador específico ni trayectoria documentada."}, "market_demand": {"score": 15, "rationale": "No se documenta la cantidad ni ubicación de los sitios a desplegar."}, "environmental_social": {"score": 10, "rationale": "No se documenta evaluación ambiental."}, "risk_mitigation": {"score": 10, "rationale": "No se documenta registro de riesgos."}, "governance_reporting": {"score": 10, "rationale": "No se documentan estructuras de gobernanza."}, "shared_access_readiness": {"score": 15, "rationale": "No hay inventario de sitios ni acuerdos de acceso compartido documentados."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "high", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "high", "action": "Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto."}]$gap$::jsonb,
$fin$[{"mechanism": "Development Finance Institutions", "rationale": "Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible."}]$fin$::jsonb,
$sum$Puntaje de preparación 13/100 (Etapa de Concepto). Es el proyecto menos definido del lote financiado por FSU: no identifica un operador específico, ni cantidad de sitios, ni monto FSU en la planilla de origen. Foco prioritario: madurez del diseño técnico.$sum$,
  'Generado por Claude (Cowork) a partir de projects.description (fuente: planilla de seguimiento de proyectos ENACOM, ago. 2026) — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed', readiness_stage = coalesce(readiness_stage, 'Concept Stage'), updated_at = now()
where name = 'Telcos — Programa Play (Sitios Móviles)'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');


-- ============================================================================
-- Verificacion: los 18 proyectos con su analisis recien insertado
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
where p.name in (
  'Atlántico-Pacífico — Troncal FO Región Andina (Futaleufú)-Trelew',
  'Atlántico-Pacífico — Tramo Terrestre Esquel-Chaitén-Puerto Montt',
  'Atlántico-Pacífico — Cable Submarino Trelew (AR)-Punta del Este (UY)',
  'Atlántico-Pacífico — Datacenter Tier IV en Tándem (2 sedes) + HW IA',
  'Atlántico-Pacífico — Amarre: Obra Civil y Contingencia',
  'Cable Submarino PUMA (Argentina-Sudáfrica)',
  'Tramo Bioceánico Norte (Salta)',
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
and p.user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')
order by fa.overall_score desc;

-- ============================================================================
-- NOTA sobre readiness_stage vs. framework_analysis.stage (misma que en
-- data_ai_analysis_all_projects.sql)
-- La app distingue el "score derivado" (framework_analysis.stage, lo que
-- califica este analisis) del "stage de flujo de trabajo"
-- (projects.readiness_stage, que solo un advisor mueve manualmente con
-- promote_project_workflow()/demote_project_workflow() en
-- app/project.html). Por eso este script solo mueve readiness_stage a
-- 'Concept Stage' la PRIMERA vez (si estaba null) y no lo salta
-- directamente a 'Early Structuring' aunque el score de algunos proyectos
-- (CALF, ARSAT REFEFO, ARSAT FWA, Starlink, ENACOM Parques, ENACOM Control
-- de Espectro) lo amerite. Si queres que alguno avance de etapa de flujo
-- de trabajo, hacelo desde app/project.html como advisor, o pedime el
-- UPDATE correspondiente.
-- ============================================================================
