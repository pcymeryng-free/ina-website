-- ============================================================================
-- Analisis IA (Investment Readiness Index (TM)) para el proyecto
-- "Sistema de Alerta Temprana - AlertAR"
-- ============================================================================
--
-- Mismo motor de 9 dimensiones (8 genericas + alert_dissemination_readiness,
-- la novena dimension especifica de early_warning_system) que uso para los
-- 6 proyectos anteriores en supabase/data_ai_analysis_all_projects.sql —
-- ver ese archivo para la explicacion completa de la metodologia y el
-- disclaimer de que esto lo generé yo (Claude) leyendo el pliego completo,
-- no una corrida real de /api/analyze-project.js.
--
-- PARTICULARIDAD DE ESTE PROYECTO
-- A diferencia de los 6 anteriores (propuestas de terceros dirigidas a
-- ENACOM), este es el propio pliego de licitacion que ENACOM emite. Eso
-- se nota en el perfil de scoring: muy fuerte en legal_regulatory (85) y
-- technical_maturity (85) porque el pliego tiene 94 paginas de
-- especificaciones tecnicas excluyentes y respaldo normativo ya vigente
-- desde 2018, pero financial_robustness queda bajo (25) porque -a
-- diferencia de un proyecto de inversion privada- una licitacion publica
-- no publica presupuesto ni modelo financiero: el precio surge recien de
-- la oferta economica de cada participante. La sugerencia de
-- financiamiento "Public-Private Partnerships" que arroja la regla
-- determinista por etapa (Estructuracion Avanzada) es la misma que se
-- aplicaria a cualquier proyecto en esa etapa sin importar el tipo — no
-- necesariamente el mecanismo mas relevante para una contratacion publica
-- domestica financiada con presupuesto nacional. Lo dejo tal cual arroja
-- la regla para ser consistente con el resto de los analisis, pero
-- señalo la salvedad aca.
--
-- REQUISITOS PARA CORRER ESTE SCRIPT
-- El proyecto "Sistema de Alerta Temprana - AlertAR" ya tiene que existir
-- en public.projects (corriste supabase/data_alertar.sql antes, o lo
-- creaste manualmente).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Sistema de Alerta Temprana - AlertAR  (project_type = early_warning_system)
-- overall_score = 59  |  stage = Advanced Structuring
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
     where name = 'Sistema de Alerta Temprana - AlertAR'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),
  59,
  'Advanced Structuring',
$dims${"legal_regulatory": {"score": 85, "rationale": "Base legal solida y ya vigente: Resolucion RESOL-2018-51-APN-SGM#JGM (Plan Nacional de Contingencia) obliga a los PRESTADORES a disponer de medios de multidifusion desde 2018; el proyecto especifico que origina esta licitacion (IF-2025-117577290-APN-DNPYD#ENACOM) ya fue aprobado por Resolucion RESOL-2025-1387-APN-ENACOM#JGM, con multiples convenios antecedentes ya firmados (CONVE-2025-133062984-APN-MSG y cuatro informes IF-2025-...-APN-SRI#ENACOM)."}, "technical_maturity": {"score": 85, "rationale": "Diseño tecnico muy avanzado y detallado en el pliego: arquitectura CBE/CBC completa, estandar CAP 1.2, especificaciones de interfaces, funcionalidades, seguridad (Common Criteria EAL4+) y capacidad de almacenamiento, con requisitos tecnicos excluyentes para los oferentes."}, "financial_robustness": {"score": 25, "rationale": "El pliego no publica un presupuesto oficial ni un modelo financiero: el valor economico surge recien de la oferta de cada oferente en un proceso licitatorio de una sola etapa, sin proyecciones de costos ni estructura de financiamiento documentadas en la fuente."}, "sponsor_capacity": {"score": 80, "rationale": "ENACOM es el organismo contratante: un regulador nacional con trayectoria comprobada regulando el sector desde antes de 2018 y que ya coordino exitosamente convenios previos (SRI, MSG) para este mismo proyecto especifico."}, "market_demand": {"score": 65, "rationale": "Demanda institucional solida (no comercial): mandato legal desde 2018, mision estatutaria del SINAGIR (Ley 27.287), y coordinacion ya en curso con el Ministerio de Seguridad Nacional y los tres PRESTADORES, aunque no aplica el concepto de clientes ancla/estudios de mercado propios de un proyecto comercial."}, "environmental_social": {"score": 15, "rationale": "No se documenta una evaluacion de impacto ambiental y social ni consulta con la comunidad en el pliego (una licitacion de plataforma de software/equipamiento de alerta, sin obra civil, dificilmente la requeriria, pero no hay evidencia documentada de todos modos)."}, "risk_mitigation": {"score": 55, "rationale": "Mitigacion de riesgo operativo bien cubierta: redundancia doble del CBE (local y geografica) y doble CBC por PRESTADOR, garantia minima de hardware/software de 36 meses, periodo de pruebas de 60 dias antes de la aceptacion final, y un regimen de penalidades economicas por incumplimiento de TMA/TMR. No se documenta un registro de riesgos financieros/politicos/cambiarios (no aplican a una contratacion publica domestica)."}, "governance_reporting": {"score": 55, "rationale": "Gobernanza definida para la etapa de adjudicacion e implementacion: comite de evaluacion, requisitos tecnicos excluyentes, ratificacion tecnica obligatoria de PRESTADORES y SINAGIR, y KPIs de soporte (TMA/TMR) para los 36 meses de servicio. No se detallan mecanismos de reporte/monitoreo (dashboards, informes periodicos) mas alla de la resolucion de incidencias."}, "alert_dissemination_readiness": {"score": 65, "rationale": "Tecnologia y estandar de difusion totalmente definidos (Cell Broadcast Service 3GPP + CAP 1.2) y coordinacion con fuentes de deteccion de riesgo (acceso multientidad del CBE a Defensa Civil, meteorologia, salud, seguridad) y con los operadores moviles (los tres PRESTADORES, ya obligados por normativa desde 2018) muy avanzada. Persisten brechas: no se fija un tiempo objetivo de difusion en segundos/minutos, y el pliego no describe un plan de pruebas periodicas POST-implementacion ni una campaña de concientizacion publica (solo define el periodo de pruebas previo a la aceptacion)."}}$dims$::jsonb,
$gap$[{"priority": "high", "action": "Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas."}, {"priority": "high", "action": "Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado."}, {"priority": "medium", "action": "Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía."}, {"priority": "medium", "action": "Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión."}, {"priority": "low", "action": "Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos."}, {"priority": "low", "action": "Definí la tecnología/estándar de difusión y formalizá temprano los convenios de coordinación con las fuentes de detección de riesgo y los operadores móviles/radiodifusores — trackealos en el checklist de Hojas de ruta del proyecto."}]$gap$::jsonb,
$fin$[{"mechanism": "Public-Private Partnerships", "rationale": "Los proyectos en estructuración avanzada suelen estar bien posicionados para una estructura de APP una vez cerradas las brechas restantes."}]$fin$::jsonb,
$sum$Puntaje de preparación 59/100 (Estructuración Avanzada) — el segundo más alto de los siete proyectos cargados en la plataforma, después de la Cooperativa Eléctrica de Punta Alta. A diferencia de las propuestas de terceros analizadas antes, este es el propio pliego de licitación de ENACOM: tiene respaldo legal ya vigente (Resolución RESOL-2018-51-APN-SGM#JGM y el proyecto específico aprobado por Resolución RESOL-2025-1387-APN-ENACOM#JGM) y una arquitectura técnica CBE/CBC completamente definida, con redundancia doble y los tres PRESTADORES de telefonía móvil ya coordinados por mandato normativo desde 2018. Sus principales brechas son la falta de un modelo financiero público (el presupuesto surge recién de la oferta económica de cada oferente, no está publicado en el pliego) y la ausencia de una evaluación de impacto ambiental y social documentada. Foco prioritario: preparación ambiental y social.$sum$,
  'Generado por Claude (Cowork) a partir de la lectura completa del pliego PLIEG-2026-63921688-APN-DNIERYSTIYC%ENACOM.pdf y de projects.description — no es una corrida del endpoint /api/analyze-project.js.',
  'ai'
);

update public.projects
set status = 'completed',
    readiness_stage = coalesce(readiness_stage, 'Concept Stage'),
    updated_at = now()
where name = 'Sistema de Alerta Temprana - AlertAR'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ============================================================================
-- Verificacion
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
where p.name = 'Sistema de Alerta Temprana - AlertAR'
  and p.user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')
order by fa.created_at desc;
