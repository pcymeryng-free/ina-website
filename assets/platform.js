/* ============================================================================
   INA Platform — Supabase client + auth/data helpers
   Shared by register.html, login.html, dashboard.html, new-project.html
   and project.html. Vanilla JS, no build step, loaded via <script> tag
   after the Supabase CDN script.
   ============================================================================ */

/* ---------- Configuration ----------
   Fill these in with your own Supabase project's values (Dashboard →
   Project Settings → API). The anon/public key is safe to expose in
   client-side code — Row Level Security policies (see supabase/schema.sql)
   are what actually protect the data, not secrecy of this key. */
const INA_PLATFORM_CONFIG = {
  SUPABASE_URL: 'https://lyyuxoltyyckfppfjbyn.supabase.co',
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5eXV4b2x0eXlja2ZwcGZqYnluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1MDYyNzIsImV4cCI6MjA5OTA4MjI3Mn0.2Ggj03wA2GILf-26PhDT4ZQx2g9ePI8u1WBLwMN774s',
};

// .trim() guards against accidental stray whitespace/newlines inside the
// quotes above (an easy paste mistake with long keys) breaking the client.
const SUPABASE_URL_CLEAN = (INA_PLATFORM_CONFIG.SUPABASE_URL || '').trim();
const SUPABASE_ANON_KEY_CLEAN = (INA_PLATFORM_CONFIG.SUPABASE_ANON_KEY || '').trim();

const supabaseClient = (SUPABASE_URL_CLEAN !== 'YOUR_SUPABASE_URL' && SUPABASE_URL_CLEAN && window.supabase)
  ? window.supabase.createClient(SUPABASE_URL_CLEAN, SUPABASE_ANON_KEY_CLEAN)
  : null;

/* ---------- Reference data (bilingual) ---------- */

const ROLE_TYPES = [
  { value: 'government_regulator', en: 'Government / Regulator', es: 'Gobierno / Regulador' },
  { value: 'development_finance_institution', en: 'Development Finance Institution', es: 'Institución de Financiamiento para el Desarrollo' },
  { value: 'investor_infrastructure_fund', en: 'Investor / Infrastructure Fund', es: 'Inversor / Fondo de Infraestructura' },
  { value: 'technology_company', en: 'Technology Company', es: 'Empresa Tecnológica' },
  { value: 'other', en: 'Other', es: 'Otro' },
];

const PROJECT_TYPES = [
  { value: 'submarine_cable', en: 'Submarine Cable System', es: 'Sistema de Cable Submarino' },
  { value: 'fiber_backbone_last_mile', en: 'Fiber Backbone / Last Mile', es: 'Backbone de Fibra / Última Milla' },
  { value: 'fixed_wireless_access', en: 'Fixed Wireless Access (FWA)', es: 'Acceso Inalámbrico Fijo (FWA)' },
  { value: 'ai_datacenter', en: 'Datacenter for AI Workloads', es: 'Datacenter para Cargas de IA' },
  { value: 'satellite_constellation', en: 'Satellite Constellation', es: 'Constelación Satelital' },
  { value: 'other', en: 'Other', es: 'Otro' },
];

const PROJECT_STATUS_LABELS = {
  submitted: { en: 'Submitted', es: 'Enviado' },
  analyzing: { en: 'Analyzing', es: 'Analizando' },
  completed: { en: 'Completed', es: 'Completado' },
  error: { en: 'Error', es: 'Error' },
};

const PLATFORM_ROLE_LABELS = {
  user: { en: 'User', es: 'Usuario' },
  advisor: { en: 'Advisor', es: 'Asesor' },
  admin: { en: 'Admin', es: 'Admin' },
};

const READINESS_STAGE_LABELS = {
  'Concept Stage': { en: 'Concept Stage', es: 'Etapa de Concepto' },
  'Early Structuring': { en: 'Early Structuring', es: 'Estructuración Temprana' },
  'Advanced Structuring': { en: 'Advanced Structuring', es: 'Estructuración Avanzada' },
  'Investment Ready': { en: 'Investment Ready', es: 'Listo para Inversión' },
};

/* Investment Readiness Index™ (F2) — the 8 scoring dimensions, matching
   framework.html #f2 exactly, keyed to match the AI analysis JSON output. */
const DIMENSION_LABELS = {
  legal_regulatory: { en: 'Legal & Regulatory Clarity', es: 'Claridad Legal y Regulatoria' },
  technical_maturity: { en: 'Technical Design Maturity', es: 'Madurez del Diseño Técnico' },
  financial_robustness: { en: 'Financial Model Robustness', es: 'Robustez del Modelo Financiero' },
  sponsor_capacity: { en: 'Sponsor Capacity', es: 'Capacidad del Patrocinador' },
  market_demand: { en: 'Market Demand Evidence', es: 'Evidencia de Demanda de Mercado' },
  environmental_social: { en: 'Environmental & Social Readiness', es: 'Preparación Ambiental y Social' },
  risk_mitigation: { en: 'Risk Mitigation Coverage', es: 'Cobertura de Mitigación de Riesgos' },
  governance_reporting: { en: 'Governance & Reporting', es: 'Gobernanza y Reportes' },
};
const DIMENSION_ORDER = Object.keys(DIMENSION_LABELS);

const PRIORITY_LABELS = {
  high: { en: 'High Priority', es: 'Prioridad Alta' },
  medium: { en: 'Medium Priority', es: 'Prioridad Media' },
  low: { en: 'Low Priority', es: 'Prioridad Baja' },
};

/* ---------- Manual 9-dimension self-assessment (app/assessment.html) ----------
   The questionnaire covers the 8 generic Investment Readiness Index™
   dimensions above, PLUS one 9th dimension specific to the project's type
   (e.g. "Route & Landing Feasibility" for a submarine cable). Today the
   user answers 3 Likert (1–5) statements per dimension by hand; the
   answers/scoring shape intentionally mirrors what /api/analyze-project.js
   (Claude) produces so both sources render identically on project.html —
   the plan is for an AI agent to eventually fill these same 27 answers in
   automatically from the project's uploaded documents. */

// project_type value -> the key used for that type's 9th dimension.
const TYPE_DIMENSION_KEY = {
  submarine_cable: 'route_feasibility',
  fiber_backbone_last_mile: 'rollout_readiness',
  fixed_wireless_access: 'spectrum_site_readiness',
  ai_datacenter: 'power_cooling_readiness',
  satellite_constellation: 'orbital_spectrum_coordination',
  other: 'type_specific_readiness',
};

// Bilingual labels for each type-specific 9th dimension. Kept separate
// from DIMENSION_LABELS (which stays exactly the 8 canonical F2 keys, in
// order — used elsewhere as the fixed AI dimension-grid order) so nothing
// that depends on DIMENSION_ORDER having length 8 breaks.
const TYPE_DIMENSION_LABELS = {
  route_feasibility: { en: 'Route & Landing Feasibility', es: 'Viabilidad de Ruta y Estaciones de Aterrizaje' },
  rollout_readiness: { en: 'Network Rollout Readiness', es: 'Preparación para el Despliegue de Red' },
  spectrum_site_readiness: { en: 'Spectrum & Site Readiness', es: 'Preparación de Espectro y Sitios' },
  power_cooling_readiness: { en: 'Power & Cooling Readiness', es: 'Preparación de Energía y Refrigeración' },
  orbital_spectrum_coordination: { en: 'Orbital & Spectrum Coordination', es: 'Coordinación Orbital y de Espectro' },
  type_specific_readiness: { en: 'Project-Specific Technical Readiness', es: 'Preparación Técnica Específica del Proyecto' },
};

function dimLabelLookup(key, lang) {
  const entry = DIMENSION_LABELS[key] || TYPE_DIMENSION_LABELS[key];
  return entry ? entry[lang] : key;
}

// 3 Likert statements (1 = strongly disagree, 5 = strongly agree) per
// generic dimension.
const ASSESSMENT_QUESTIONS = {
  legal_regulatory: [
    { en: 'The project has the necessary regulatory permits and licenses, or a clear path to obtain them.', es: 'El proyecto cuenta con los permisos y licencias regulatorias necesarias, o un camino claro para obtenerlos.' },
    { en: 'Land access, rights-of-way, and any spectrum or frequency rights are secured or well understood.', es: 'El acceso a terrenos, los derechos de paso y los derechos de espectro o frecuencia (si aplica) están asegurados o bien comprendidos.' },
    { en: 'There are no unresolved legal disputes or regulatory uncertainties that could block the project.', es: 'No existen disputas legales sin resolver ni incertidumbres regulatorias que puedan bloquear el proyecto.' },
  ],
  technical_maturity: [
    { en: 'The technical design (architecture, route/site selection, capacity planning) is complete or well advanced.', es: 'El diseño técnico (arquitectura, selección de ruta/sitio, planificación de capacidad) está completo o muy avanzado.' },
    { en: 'Technology and equipment vendors have been identified and technically vetted.', es: 'Se identificaron y evaluaron técnicamente los proveedores de tecnología y equipamiento.' },
    { en: 'A technical and feasibility study has been conducted for this project.', es: 'Se realizó un estudio técnico y de factibilidad para este proyecto.' },
  ],
  financial_robustness: [
    { en: 'A detailed financial model (CAPEX, OPEX, revenue projections) exists and has been stress-tested.', es: 'Existe un modelo financiero detallado (CAPEX, OPEX, proyecciones de ingresos) y fue sometido a pruebas de estrés.' },
    { en: 'Revenue assumptions are grounded in market data or signed offtake/anchor agreements.', es: 'Los supuestos de ingresos se basan en datos de mercado o en acuerdos firmados de compra/ancla.' },
    { en: 'The project has a clear capital structure (debt/equity mix) and funding plan.', es: 'El proyecto tiene una estructura de capital clara (mezcla de deuda/capital) y un plan de financiamiento.' },
  ],
  sponsor_capacity: [
    { en: "The sponsor/promoter has a track record of executing similar infrastructure projects.", es: 'El sponsor/promotor tiene experiencia comprobada ejecutando proyectos de infraestructura similares.' },
    { en: 'The sponsor has adequate financial and technical capacity to complete the project.', es: 'El sponsor cuenta con capacidad financiera y técnica adecuada para completar el proyecto.' },
    { en: 'Key management and project team roles are staffed with qualified personnel.', es: 'Los roles clave de gestión y del equipo del proyecto están cubiertos con personal calificado.' },
  ],
  market_demand: [
    { en: "There is documented market research or demand studies supporting the project's viability.", es: 'Existe investigación de mercado o estudios de demanda documentados que respaldan la viabilidad del proyecto.' },
    { en: 'Anchor customers, off-takers, or letters of intent exist for this project.', es: 'Existen clientes ancla, compradores o cartas de intención para este proyecto.' },
    { en: 'The competitive landscape and pricing strategy are well understood.', es: 'El panorama competitivo y la estrategia de precios están bien comprendidos.' },
  ],
  environmental_social: [
    { en: 'An environmental and social impact assessment (ESIA) has been completed or is underway.', es: 'Se completó o está en curso una evaluación de impacto ambiental y social (ESIA).' },
    { en: 'Community and stakeholder consultation has taken place.', es: 'Se llevó a cabo consulta con la comunidad y las partes interesadas.' },
    { en: 'Mitigation plans for environmental and social risks are documented.', es: 'Los planes de mitigación de riesgos ambientales y sociales están documentados.' },
  ],
  risk_mitigation: [
    { en: 'Key project risks (technical, financial, political, currency) have been identified and assessed.', es: 'Se identificaron y evaluaron los riesgos clave del proyecto (técnicos, financieros, políticos, cambiarios).' },
    { en: 'Mitigation measures or insurance/guarantee mechanisms are in place for major risks.', es: 'Existen medidas de mitigación o mecanismos de seguro/garantía para los riesgos principales.' },
    { en: 'A risk monitoring and governance process exists for the project.', es: 'Existe un proceso de monitoreo y gobernanza de riesgos para el proyecto.' },
  ],
  governance_reporting: [
    { en: 'The project has clear governance structures (board, steering committee, decision rights).', es: 'El proyecto cuenta con estructuras de gobernanza claras (directorio, comité directivo, derechos de decisión).' },
    { en: 'Reporting and monitoring mechanisms (KPIs, dashboards) are defined.', es: 'Están definidos los mecanismos de reporte y monitoreo (KPIs, tableros).' },
    { en: 'Compliance and audit processes are in place or planned.', es: 'Los procesos de cumplimiento y auditoría están implementados o planificados.' },
  ],
};

// 3 Likert statements per project type's 9th (type-specific) dimension.
const TYPE_DIMENSION_QUESTIONS = {
  submarine_cable: [
    { en: 'A marine route survey (bathymetric/geotechnical) has been completed or is scheduled.', es: 'Se completó o está programado un estudio de ruta marina (batimétrico/geotécnico).' },
    { en: 'Cable landing station sites and the required permits are secured.', es: 'Los sitios de las estaciones de aterrizaje del cable y los permisos requeridos están asegurados.' },
    { en: 'Redundancy and capacity plans account for competing or complementary regional cable systems.', es: 'Los planes de redundancia y capacidad consideran los sistemas de cable regionales competidores o complementarios.' },
  ],
  fiber_backbone_last_mile: [
    { en: 'Right-of-way agreements and duct/pole access have been secured along the planned route.', es: 'Los acuerdos de derecho de paso y el acceso a ductos/postes están asegurados a lo largo de la ruta planificada.' },
    { en: 'The last-mile distribution and customer connection strategy is defined.', es: 'La estrategia de distribución de última milla y conexión de clientes está definida.' },
    { en: 'Network redundancy and interconnection points are planned.', es: 'Están planificados los puntos de redundancia e interconexión de la red.' },
  ],
  fixed_wireless_access: [
    { en: 'Spectrum licenses or frequency allocation are secured or in process.', es: 'Las licencias de espectro o la asignación de frecuencia están aseguradas o en trámite.' },
    { en: 'Tower/site locations and line-of-sight studies are complete.', es: 'Las ubicaciones de torres/sitios y los estudios de línea de vista están completos.' },
    { en: 'Customer premises equipment (CPE) sourcing and deployment plan exist.', es: 'Existe un plan de abastecimiento y despliegue de equipos de cliente (CPE).' },
  ],
  ai_datacenter: [
    { en: 'Power supply capacity (grid connection or on-site generation) is secured or contracted.', es: 'La capacidad de suministro eléctrico (conexión a la red o generación en sitio) está asegurada o contratada.' },
    { en: 'The cooling system design accounts for projected compute density and local climate.', es: 'El diseño del sistema de refrigeración considera la densidad de cómputo proyectada y el clima local.' },
    { en: 'Redundancy (N+1/2N) and uptime SLAs are defined for critical infrastructure.', es: 'La redundancia (N+1/2N) y los SLA de disponibilidad están definidos para la infraestructura crítica.' },
  ],
  satellite_constellation: [
    { en: 'Orbital slot / frequency coordination filings (ITU or national) have been submitted or secured.', es: 'Las presentaciones de coordinación orbital/frecuencia (UIT o nacional) fueron enviadas o aseguradas.' },
    { en: 'The launch provider and manufacturing timeline are contracted or well defined.', es: 'El proveedor de lanzamiento y el cronograma de fabricación están contratados o bien definidos.' },
    { en: 'The ground station network and gateway infrastructure plan is in place.', es: 'El plan de red de estaciones terrestres e infraestructura de gateway está definido.' },
  ],
  other: [
    { en: 'Technical specifications and requirements specific to this project type are documented.', es: 'Las especificaciones técnicas y requisitos específicos de este tipo de proyecto están documentados.' },
    { en: 'Specialized permits or certifications required for this project type are identified.', es: 'Se identificaron los permisos o certificaciones especializadas que requiere este tipo de proyecto.' },
    { en: 'Key technology or vendor dependencies specific to this project are understood.', es: 'Se comprenden las dependencias clave de tecnología o proveedores específicas de este proyecto.' },
  ],
};

// One bilingual improvement tip per dimension (8 generic + 6 type-specific
// keys) — used as the gap roadmap "action" text for any dimension that
// scores low enough to be flagged.
const RECOMMENDATION_TIPS = {
  legal_regulatory: { en: 'Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage.', es: 'Priorizá cerrar las brechas regulatorias y de permisos — suele ser el mayor bloqueo para avanzar más allá de la Etapa de Concepto.' },
  technical_maturity: { en: 'Advance the technical design and vet equipment vendors to reduce execution risk.', es: 'Avanzá el diseño técnico y evaluá proveedores de equipamiento para reducir el riesgo de ejecución.' },
  financial_robustness: { en: 'Build or refine a stress-tested financial model backed by real market data.', es: 'Construí o refiná un modelo financiero sometido a pruebas de estrés y respaldado por datos reales de mercado.' },
  sponsor_capacity: { en: "Strengthen the sponsor's track record documentation or bring in an experienced co-sponsor/EPC partner.", es: 'Reforzá la documentación de experiencia del sponsor o sumá un co-sponsor/socio EPC con trayectoria.' },
  market_demand: { en: 'Commission demand studies or secure anchor customer commitments to de-risk the revenue case.', es: 'Encargá estudios de demanda o asegurá compromisos de clientes ancla para reducir el riesgo del caso de ingresos.' },
  environmental_social: { en: 'Complete the environmental and social impact assessment and document stakeholder consultation.', es: 'Completá la evaluación de impacto ambiental y social y documentá la consulta con las partes interesadas.' },
  risk_mitigation: { en: 'Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms.', es: 'Formalizá un registro de riesgos con medidas de mitigación y, cuando corresponda, mecanismos de seguro o garantía.' },
  governance_reporting: { en: 'Establish clear governance structures and reporting/monitoring mechanisms before seeking investment.', es: 'Establecé estructuras de gobernanza claras y mecanismos de reporte/monitoreo antes de buscar inversión.' },
  route_feasibility: { en: 'Complete the marine route survey and secure landing station permits early — these have long lead times.', es: 'Completá el estudio de ruta marina y asegurá los permisos de las estaciones de aterrizaje temprano — tienen plazos largos.' },
  rollout_readiness: { en: 'Lock down right-of-way and duct/pole access agreements before finalizing the rollout schedule.', es: 'Asegurá los acuerdos de derecho de paso y acceso a ductos/postes antes de finalizar el cronograma de despliegue.' },
  spectrum_site_readiness: { en: 'Secure spectrum allocation and complete line-of-sight studies before committing to a deployment timeline.', es: 'Asegurá la asignación de espectro y completá los estudios de línea de vista antes de comprometer un cronograma de despliegue.' },
  power_cooling_readiness: { en: 'Contract power capacity and finalize the cooling design early — these typically drive the critical path.', es: 'Contratá la capacidad eléctrica y finalizá el diseño de refrigeración temprano — suelen definir el camino crítico.' },
  orbital_spectrum_coordination: { en: 'Advance orbital/frequency coordination filings and lock in launch provider terms — both have long regulatory lead times.', es: 'Avanzá las presentaciones de coordinación orbital/frecuencia y cerrá los términos con el proveedor de lanzamiento — ambos tienen plazos regulatorios largos.' },
  type_specific_readiness: { en: 'Document the project-specific technical requirements and specialized permits this project type requires.', es: 'Documentá los requisitos técnicos específicos y los permisos especializados que requiere este tipo de proyecto.' },
};

const BAND_RATIONALE = {
  strong: { en: 'Strong self-assessed readiness in this dimension.', es: 'Alta preparación autoevaluada en esta dimensión.' },
  moderate: { en: 'Reasonable readiness, with some room to strengthen.', es: 'Preparación razonable, con margen de mejora.' },
  early: { en: 'Early-stage readiness — meaningful gaps remain.', es: 'Preparación incipiente — quedan brechas importantes.' },
  limited: { en: 'Limited readiness — this dimension needs significant work.', es: 'Preparación limitada — esta dimensión necesita trabajo significativo.' },
};

function bandRationale(score, lang) {
  const band = score >= 80 ? 'strong' : score >= 60 ? 'moderate' : score >= 40 ? 'early' : 'limited';
  return BAND_RATIONALE[band][lang];
}

// One deterministic financing suggestion per readiness stage — a light
// rule-based stand-in for the AI-only Multilateral Finance Navigator™,
// reusing the same mechanism names api/analyze-project.js draws from.
const STAGE_FINANCING_SUGGESTION = {
  'Concept Stage': {
    mechanism: 'Development Finance Institutions',
    rationale: { en: 'Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available.', es: 'Los proyectos en etapa de concepto suelen necesitar apoyo de asesoría y financiamiento concesional o de subvención en etapa temprana antes de que el capital comercial esté disponible.' },
  },
  'Early Structuring': {
    mechanism: 'Blended Finance',
    rationale: { en: 'Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors.', es: 'El financiamiento combinado puede reducir el riesgo de proyectos en estructuración temprana lo suficiente como para atraer coinversores comerciales de mayor escala.' },
  },
  'Advanced Structuring': {
    mechanism: 'Public-Private Partnerships',
    rationale: { en: 'Advanced-structuring projects are often well positioned for a PPP structure once remaining gaps are closed.', es: 'Los proyectos en estructuración avanzada suelen estar bien posicionados para una estructura de APP una vez cerradas las brechas restantes.' },
  },
  'Investment Ready': {
    mechanism: 'Project Finance',
    rationale: { en: 'Investment-ready projects are typically well suited to standard non-recourse project finance structures.', es: 'Los proyectos listos para inversión suelen ser aptos para estructuras estándar de financiamiento de proyectos sin recurso.' },
  },
};

// Suggested whenever a last-mile project reports a beneficiary_count —
// regulator-administered Universal Service Funds (e.g. ENACOM's Fondo de
// Servicio Universal in Argentina) specifically fund underserved-area
// buildout measured by exactly this metric, and are a much more likely
// fit than the generic stage-based suggestion below for that profile.
const USF_SUGGESTION = {
  mechanism: 'Universal Service Funds',
  rationale: {
    en: 'This project reports a concrete number of beneficiaries reached in an underserved area — a strong fit for a national Universal Service Fund’s subsidized-rate credit or grant line (e.g. ENACOM’s Fondo de Servicio Universal in Argentina).',
    es: 'Este proyecto reporta una cantidad concreta de beneficiarios alcanzados en una zona desatendida — un buen candidato para una línea de crédito a tasa subsidiada o subsidio de un Fondo de Servicio Universal nacional (por ejemplo, el Fondo de Servicio Universal de ENACOM en Argentina).',
  },
};
const USF_ELIGIBLE_TYPES = ['fiber_backbone_last_mile', 'fixed_wireless_access'];

function stageForScore(score) {
  if (score <= 25) return 'Concept Stage';
  if (score <= 50) return 'Early Structuring';
  if (score <= 75) return 'Advanced Structuring';
  return 'Investment Ready';
}

/* Ordered list of the 9 dimensions (8 generic + 1 type-specific) for a
   given project_type, each with its 3 bilingual Likert questions. This is
   what app/assessment.html renders as the questionnaire. */
function assessmentQuestionSet(projectType) {
  const typeKey = TYPE_DIMENSION_KEY[projectType] || TYPE_DIMENSION_KEY.other;
  const typeQuestions = TYPE_DIMENSION_QUESTIONS[projectType] || TYPE_DIMENSION_QUESTIONS.other;
  const generic = DIMENSION_ORDER.map((key) => ({ key, questions: ASSESSMENT_QUESTIONS[key] }));
  return [...generic, { key: typeKey, questions: typeQuestions }];
}

/* Scores a completed questionnaire. `answers` is { [dimensionKey]: [1-5, 1-5, 1-5] }
   for all 9 dimensions returned by assessmentQuestionSet(). Returns the
   same shape framework_analysis rows use (overall_score/stage/dimensions/
   gap_roadmap/financing_recommendations/summary), so project.html renders
   a manual result exactly like an AI one. */
function computeManualAssessment(projectType, answers, { beneficiaryCount } = {}) {
  const lang = currentLang();
  const set = assessmentQuestionSet(projectType);

  const dimensions = {};
  let sum = 0;
  set.forEach(({ key }) => {
    const vals = (answers[key] || []).map(Number).filter((n) => n >= 1 && n <= 5);
    const score = vals.length ? Math.round((vals.reduce((a, b) => a + b, 0) / (vals.length * 5)) * 100) : 0;
    dimensions[key] = { score, rationale: bandRationale(score, lang) };
    sum += score;
  });
  const overallScore = Math.round(sum / set.length);
  const stage = stageForScore(overallScore);

  const gapRoadmap = set
    .map(({ key }) => ({ key, score: dimensions[key].score }))
    .filter((d) => d.score < 70)
    .sort((a, b) => a.score - b.score)
    .slice(0, 6)
    .map((d) => ({
      priority: d.score < 40 ? 'high' : d.score < 60 ? 'medium' : 'low',
      action: (RECOMMENDATION_TIPS[d.key] && RECOMMENDATION_TIPS[d.key][lang]) || '',
    }));

  const financingRecommendations = [];
  if (Number(beneficiaryCount) > 0 && USF_ELIGIBLE_TYPES.includes(projectType)) {
    financingRecommendations.push({ mechanism: USF_SUGGESTION.mechanism, rationale: USF_SUGGESTION.rationale[lang] });
  }
  const financeSuggestion = STAGE_FINANCING_SUGGESTION[stage];
  if (financeSuggestion) {
    financingRecommendations.push({ mechanism: financeSuggestion.mechanism, rationale: financeSuggestion.rationale[lang] });
  }

  const lowest = set
    .map(({ key }) => ({ key, score: dimensions[key].score }))
    .sort((a, b) => a.score - b.score)[0];
  const lowestLabel = lowest ? dimLabelLookup(lowest.key, lang) : '';
  const stageLabel = READINESS_STAGE_LABELS[stage] ? READINESS_STAGE_LABELS[stage][lang] : stage;
  const summary = lang === 'es'
    ? `Puntaje de preparación autoevaluado de ${overallScore}/100 (${stageLabel}), según tus respuestas al cuestionario de 9 dimensiones. Foco prioritario: ${lowestLabel}.`
    : `Self-assessed readiness score of ${overallScore}/100 (${stageLabel}), based on your answers to the 9-dimension questionnaire. Priority focus: ${lowestLabel}.`;

  return { overall_score: overallScore, stage, dimensions, gap_roadmap: gapRoadmap, financing_recommendations: financingRecommendations, summary };
}

/* ---------- FSU Scoring (ENACOM Resolución 359/2025) ----------
   A separate, deterministic, ENACOM-specific 100-point selection-scoring
   matrix — distinct from the Investment Readiness Index™ above — published
   in ENACOM's "Manual Estratégico de Elaboración de Proyectos: Obtención
   del Certificado de Elegibilidad ENACOM" for MiPyME/Cooperativa projects
   applying to the Fondo de Servicio Universal (FSU). Only offered for
   fiber-to-the-home / last-mile projects: the criteria (GPON/XGS-PON,
   splitter ratios, fiber-penetration math) only make sense for FTTx. See
   the fsu_scoring table comment in supabase/schema.sql for the full
   citation and rationale. */

const FSU_SCORING_ELIGIBLE_TYPE = 'fiber_backbone_last_mile';

const FSU_MODELO_NEGOCIO_OPTIONS = [
  { value: 'mayorista_neutral', en: 'Wholesale Open Access (fine even if it also sells retail)', es: 'Mayorista Neutral / Open Access (puede además vender minorista)' },
  { value: 'minorista_exclusiva', en: 'Retail-exclusive network', es: 'Red Minorista Exclusiva' },
];

const FSU_TECNOLOGIA_OPTIONS = [
  { value: 'xgs_pon', en: 'XGS-PON (10G symmetric)', es: 'XGS-PON (10G Simétrico)' },
  { value: 'gpon', en: 'Standard GPON', es: 'GPON estándar' },
];

const FSU_SALTO_TECNOLOGICO_OPTIONS = [
  { value: 'area_blanca', en: 'White area (no prior fixed-line network)', es: 'Área Blanca (sin red fija previa)' },
  { value: 'migracion_cobre_wireless', en: 'Migration from copper/wireless to fiber', es: 'Migración de Cobre/Wireless a Fibra' },
];

const FSU_CAPACIDAD_TECNICA_OPTIONS = [
  { value: 'mas_5', en: '5+ years operating in TIC', es: '+5 años en TIC' },
  { value: 'entre_2_y_5', en: '2 to 5 years operating in TIC', es: '+2 años y menos de 5 años en TIC' },
  { value: 'menos_2', en: 'Less than 2 years operating in TIC', es: 'Menos de 2 años en TIC' },
];

// Bilingual per-criterion label + point cap, in the manual's table order —
// used to render the live breakdown in app/fsu-scoring.html.
const FSU_CRITERIA_META = [
  { key: 'score_penetracion', max: 20, en: 'Low Fiber Penetration', es: 'Baja Penetración de Fibra' },
  { key: 'score_modelo_negocio', max: 20, en: 'Business Model', es: 'Modelo de Negocio' },
  { key: 'score_tecnologia', max: 15, en: 'Technology Edge', es: 'Vanguardia Tecnológica' },
  { key: 'score_velocidad', max: 15, en: 'Average Speed Uplift', es: 'Mejora de Velocidad Media' },
  { key: 'score_salto_tecnologico', max: 10, en: 'Technology Leap', es: 'Salto Tecnológico' },
  { key: 'score_densidad', max: 10, en: 'Population Density', es: 'Densidad Poblacional' },
  { key: 'score_capacidad_tecnica', max: 10, en: 'Technical Track Record', es: 'Capacidad Técnica' },
];

/* Pure function — replicates the manual's published point table exactly.
   `inputs` uses the same camelCase field names app/fsu-scoring.html's form
   collects; returns the snake_case shape the fsu_scoring table stores
   (score_* columns + score_total + the two computed percentages), so the
   caller can spread the result straight into an upsert() payload. */
function computeFsuScore(inputs) {
  const {
    totalHogares, accesosFibra,
    modeloNegocio,
    tecnologia,
    velocidadActualMbps, velocidadPropuestaMbps,
    saltoTecnologico,
    poblacionLocalidad,
    anosCapacidadTecnica,
  } = inputs || {};

  // 1. Baja Penetración de Fibra (max 20) — < 15%: 20, 15%–38%: 15, > 38%: 0
  let penetracionPct = null;
  let scorePenetracion = 0;
  const hogares = Number(totalHogares);
  const accesos = Number(accesosFibra);
  if (hogares > 0 && accesos >= 0) {
    penetracionPct = (accesos / hogares) * 100;
    if (penetracionPct < 15) scorePenetracion = 20;
    else if (penetracionPct <= 38) scorePenetracion = 15;
    else scorePenetracion = 0;
  }

  // 2. Modelo de Negocio (max 20) — Mayorista Neutral: 20, Minorista Exclusiva: 5
  const scoreModeloNegocio = modeloNegocio === 'mayorista_neutral' ? 20 : modeloNegocio === 'minorista_exclusiva' ? 5 : 0;

  // 3. Vanguardia Tecnológica (max 15) — XGS-PON: 15, GPON: 5
  const scoreTecnologia = tecnologia === 'xgs_pon' ? 15 : tecnologia === 'gpon' ? 5 : 0;

  // 4. Mejora de Velocidad Media (max 15) — manual defines a single tier:
  // elevación > 300% => 15 pts (no partial credit specified below that).
  let mejoraVelocidadPct = null;
  let scoreVelocidad = 0;
  const v1 = Number(velocidadActualMbps);
  const v2 = Number(velocidadPropuestaMbps);
  if (v1 > 0 && v2 >= 0) {
    mejoraVelocidadPct = ((v2 - v1) / v1) * 100;
    scoreVelocidad = mejoraVelocidadPct > 300 ? 15 : 0;
  }

  // 5. Salto Tecnológico (max 10) — Área Blanca: 10, Migración Cobre/Wireless: 5
  const scoreSaltoTecnologico = saltoTecnologico === 'area_blanca' ? 10 : saltoTecnologico === 'migracion_cobre_wireless' ? 5 : 0;

  // 6. Densidad Poblacional (max 10) — <= 50.000 hab: 10, 50.001–100.000: 5, > 100.000: 0
  let scoreDensidad = 0;
  const poblacion = Number(poblacionLocalidad);
  if (poblacion > 0) {
    if (poblacion <= 50000) scoreDensidad = 10;
    else if (poblacion <= 100000) scoreDensidad = 5;
    else scoreDensidad = 0;
  }

  // 7. Capacidad Técnica (max 10) — +5 años: 10, 2–5 años: 5, < 2 años: 0
  const scoreCapacidadTecnica = anosCapacidadTecnica === 'mas_5' ? 10 : anosCapacidadTecnica === 'entre_2_y_5' ? 5 : 0;

  const scoreTotal = scorePenetracion + scoreModeloNegocio + scoreTecnologia + scoreVelocidad
    + scoreSaltoTecnologico + scoreDensidad + scoreCapacidadTecnica;

  return {
    penetracion_pct: penetracionPct != null ? Math.round(penetracionPct * 10) / 10 : null,
    mejora_velocidad_pct: mejoraVelocidadPct != null ? Math.round(mejoraVelocidadPct * 10) / 10 : null,
    score_penetracion: scorePenetracion,
    score_modelo_negocio: scoreModeloNegocio,
    score_tecnologia: scoreTecnologia,
    score_velocidad: scoreVelocidad,
    score_salto_tecnologico: scoreSaltoTecnologico,
    score_densidad: scoreDensidad,
    score_capacidad_tecnica: scoreCapacidadTecnica,
    score_total: scoreTotal,
  };
}

// Purely a UX aid for coloring/labeling the total score badge — NOT an
// official ENACOM eligibility cutoff (the manual publishes the point table
// but no pass/fail threshold for the Certificado de Elegibilidad itself).
function fsuScoreBand(score) {
  if (score >= 80) return 'strong';
  if (score >= 60) return 'moderate';
  if (score >= 40) return 'early';
  return 'limited';
}

function currentLang() {
  return document.documentElement.getAttribute('lang') === 'es' ? 'es' : 'en';
}

function labelFor(list, value, lang) {
  const item = list.find((i) => i.value === value);
  if (!item) return value;
  return item[lang] || item.en;
}

/* ---------- Framework-derived status (dashboard grid + filters) ----------
   While a project is still in the analysis pipeline, the "status" shown is
   the pipeline state (Submitted / Analyzing / Error). Once the analysis
   completes, the grid shows the actual Investment Readiness Index™ stage
   (Concept Stage / Early Structuring / Advanced Structuring / Investment
   Ready) instead of a generic "Completed" label — that's what makes the
   dashboard's status column and filter "framework-based." */

function effectiveStatusValue(project) {
  if (project.status === 'completed') {
    return project.readiness_stage || 'completed';
  }
  return project.status;
}

function effectiveStatusLabel(project) {
  const value = effectiveStatusValue(project);
  if (READINESS_STAGE_LABELS[value]) return READINESS_STAGE_LABELS[value][currentLang()];
  if (PROJECT_STATUS_LABELS[value]) return PROJECT_STATUS_LABELS[value][currentLang()];
  return value;
}

function effectiveStatusClass(project) {
  if (project.status !== 'completed') return project.status;
  const stage = project.readiness_stage;
  if (stage === 'Investment Ready') return 'stage-ready';
  if (stage === 'Advanced Structuring') return 'stage-advanced';
  if (stage === 'Early Structuring') return 'stage-early';
  if (stage === 'Concept Stage') return 'stage-concept';
  return 'completed';
}

/* Full set of values the status filter dropdown offers — pipeline states
   plus the four framework stages, in the order they should be listed. */
const STATUS_FILTER_VALUES = [
  'submitted', 'analyzing',
  'Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready',
  'error',
];

function statusFilterLabel(value) {
  if (READINESS_STAGE_LABELS[value]) return READINESS_STAGE_LABELS[value][currentLang()];
  if (PROJECT_STATUS_LABELS[value]) return PROJECT_STATUS_LABELS[value][currentLang()];
  return value;
}

/* ---------- Auth helpers ---------- */

const INAPlatform = {
  ROLE_TYPES,
  PROJECT_TYPES,
  PROJECT_STATUS_LABELS,
  READINESS_STAGE_LABELS,
  DIMENSION_LABELS,
  DIMENSION_ORDER,
  TYPE_DIMENSION_LABELS,
  TYPE_DIMENSION_KEY,
  PRIORITY_LABELS,
  STATUS_FILTER_VALUES,
  PLATFORM_ROLE_LABELS,
  currentLang,

  dimensionLabel(key) {
    return dimLabelLookup(key, currentLang());
  },
  assessmentQuestionSet,
  computeManualAssessment,
  priorityLabel(value) {
    const entry = PRIORITY_LABELS[(value || '').toLowerCase()];
    return entry ? entry[currentLang()] : value;
  },

  // FSU Scoring (ENACOM Resolución 359/2025) reference data + pure scoring
  // function — see the section above for full documentation.
  FSU_SCORING_ELIGIBLE_TYPE,
  FSU_MODELO_NEGOCIO_OPTIONS,
  FSU_TECNOLOGIA_OPTIONS,
  FSU_SALTO_TECNOLOGICO_OPTIONS,
  FSU_CAPACIDAD_TECNICA_OPTIONS,
  FSU_CRITERIA_META,
  computeFsuScore,
  fsuScoreBand,
  fsuOptionLabel(list, value) { return labelFor(list, value, currentLang()); },
  fsuCriterionLabel(key) {
    const entry = FSU_CRITERIA_META.find((c) => c.key === key);
    return entry ? entry[currentLang()] : key;
  },

  isConfigured() {
    return !!supabaseClient;
  },

  /* Platform access role — 'advisor' can view every project on the
     platform; 'user' (default) only sees/edits their own. Assigned
     manually by an admin via the Supabase Table Editor, never at signup. */
  isAdvisor(profile) {
    return !!profile && profile.role === 'advisor';
  },

  /* Full platform administrator — can view every project (same as
     advisor) plus change any user's role from app/admin.html. Assigned
     the same way advisors are: an existing admin promotes someone from
     the admin panel, or (for the very first admin) via the Supabase
     Table Editor / SQL Editor. */
  isAdmin(profile) {
    return !!profile && profile.role === 'admin';
  },

  platformRoleLabel(value) {
    const entry = PLATFORM_ROLE_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },

  roleTypeLabel(value) { return labelFor(ROLE_TYPES, value, currentLang()); },
  projectTypeLabel(value) { return labelFor(PROJECT_TYPES, value, currentLang()); },
  statusLabel(value) {
    const entry = PROJECT_STATUS_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },
  stageLabel(value) {
    const entry = READINESS_STAGE_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },
  effectiveStatusValue,
  effectiveStatusLabel,
  effectiveStatusClass,
  statusFilterLabel,

  async signUp({ email, password, fullName, organization, roleType }) {
    if (!supabaseClient) throw new Error('Platform not configured yet.');
    const { data, error } = await supabaseClient.auth.signUp({
      email,
      password,
      options: {
        data: { full_name: fullName, organization, role_type: roleType },
      },
    });
    if (error) throw error;
    return data;
  },

  async signIn({ email, password }) {
    if (!supabaseClient) throw new Error('Platform not configured yet.');
    const { data, error } = await supabaseClient.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return data;
  },

  async signOut() {
    if (!supabaseClient) return;
    await supabaseClient.auth.signOut();
  },

  async getSession() {
    if (!supabaseClient) return null;
    const { data } = await supabaseClient.auth.getSession();
    return data.session;
  },

  /* Call at the top of any authenticated page. Redirects to login.html
     (preserving a ?next= return path) if there's no active session, and to
     mfa-challenge.html if the session exists but hasn't completed a pending
     two-factor step-up yet (e.g. a token refresh restored an aal1 session
     for a user who has 2FA enabled). */
  async requireAuth() {
    const session = await this.getSession();
    if (!session) {
      const next = encodeURIComponent(location.pathname + location.search);
      location.href = `login.html?next=${next}`;
      return null;
    }
    if (await this.needsMfaStepUp()) {
      const next = encodeURIComponent(location.pathname + location.search);
      location.href = `mfa-challenge.html?next=${next}`;
      return null;
    }
    return session;
  },

  /* Call at the top of app/admin.html. Does everything requireAuth() does,
     then also checks the signed-in user's profile.role and redirects
     non-admins to dashboard.html — the RLS policies would block the actual
     data access anyway, this just avoids showing the page shell first. */
  async requireAdmin() {
    const session = await this.requireAuth();
    if (!session) return null;
    const profile = await this.getProfile(session.user.id);
    if (!this.isAdmin(profile)) {
      location.href = 'dashboard.html';
      return null;
    }
    return session;
  },

  /* ---------- Password reset ---------- */

  /* Sends a password-reset email. The link inside it lands the user on
     reset-password.html with a temporary recovery session already
     established by the Supabase client. Requires reset-password.html's
     full URL to be added to Supabase's Redirect URLs allowlist
     (Authentication → URL Configuration) — see PLATFORM_SETUP.md. */
  async requestPasswordReset(email) {
    if (!supabaseClient) throw new Error('Platform not configured yet.');
    const redirectTo = `${location.origin}/app/reset-password.html`;
    const { error } = await supabaseClient.auth.resetPasswordForEmail(email, { redirectTo });
    if (error) throw error;
  },

  /* Sets a new password for the current session — used both by
     reset-password.html (recovery session from an emailed link) and
     profile.html's "Change password" form (a normal logged-in session). */
  async updatePassword(newPassword) {
    if (!supabaseClient) throw new Error('Platform not configured yet.');
    const { error } = await supabaseClient.auth.updateUser({ password: newPassword });
    if (error) throw error;
  },

  /* ---------- Two-factor authentication (TOTP) ----------
     Uses Supabase Auth's built-in MFA API — no extra backend or QR-code
     library needed, Supabase returns a ready-to-render QR code SVG.
     Must be enabled once in Supabase: Authentication → Providers →
     Multi-Factor Authentication → Authenticator App (TOTP). */

  async mfaListFactors() {
    if (!supabaseClient) return { totp: [] };
    const { data, error } = await supabaseClient.auth.mfa.listFactors();
    if (error) throw error;
    return data;
  },

  /* Starts enrollment of a new authenticator-app factor. Returns
     { id: factorId, totp: { qr_code, secret, uri } } — qr_code is already
     a data: URI SVG image, usable directly as an <img src>. The factor is
     "unverified" until verifyMfaEnrollment() succeeds. */
  async mfaEnroll() {
    if (!supabaseClient) throw new Error('Platform not configured yet.');
    const { data, error } = await supabaseClient.auth.mfa.enroll({ factorType: 'totp' });
    if (error) throw error;
    return data;
  },

  /* Completes enrollment (or a login step-up) by checking a 6-digit code
     against a factor. challenge() then verify() is the required 2-step
     Supabase flow — this helper does both in one call. */
  async mfaVerifyCode(factorId, code) {
    if (!supabaseClient) throw new Error('Platform not configured yet.');
    const { data: challenge, error: challengeError } = await supabaseClient.auth.mfa.challenge({ factorId });
    if (challengeError) throw challengeError;
    const { data, error } = await supabaseClient.auth.mfa.verify({
      factorId,
      challengeId: challenge.id,
      code,
    });
    if (error) throw error;
    return data;
  },

  async mfaUnenroll(factorId) {
    if (!supabaseClient) return;
    const { error } = await supabaseClient.auth.mfa.unenroll({ factorId });
    if (error) throw error;
  },

  /* { currentLevel, nextLevel, currentAuthenticationMethods } — nextLevel
     is 'aal2' when the account has a verified 2FA factor. If it doesn't
     match currentLevel, this session still needs the 2FA challenge. */
  async mfaAssurance() {
    if (!supabaseClient) return { currentLevel: 'aal1', nextLevel: 'aal1' };
    const { data, error } = await supabaseClient.auth.mfa.getAuthenticatorAssuranceLevel();
    if (error) throw error;
    return data;
  },

  async needsMfaStepUp() {
    if (!supabaseClient) return false;
    try {
      const { currentLevel, nextLevel } = await this.mfaAssurance();
      return nextLevel === 'aal2' && currentLevel !== nextLevel;
    } catch (e) {
      return false;
    }
  },

  async getProfile(userId) {
    if (!supabaseClient) return null;
    const { data, error } = await supabaseClient
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    if (error) throw error;
    return data;
  },

  /* Updates the current user's own personal info. Deliberately never
     accepts a `role` field — the platform access role (user/advisor) is
     admin-assigned only, and a database trigger (see
     supabase/migration_v3_profile_self_update_guard.sql) rejects any
     attempt to change it via a self-update even if this were bypassed. */
  async updateProfile({ fullName, organization, roleType }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const { data, error } = await supabaseClient
      .from('profiles')
      .update({
        full_name: fullName,
        organization,
        role_type: roleType,
      })
      .eq('id', session.user.id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  /* ---------- Manual self-assessment (app/assessment.html) ----------
     Scores the questionnaire client-side (computeManualAssessment above),
     writes it as a framework_analysis row tagged source='manual' (allowed
     by the analysis_insert_own_manual RLS policy — see
     supabase/migration_v5_manual_assessment.sql), and updates the
     project's status/readiness_stage the same way a completed AI analysis
     would, so the dashboard grid and project.html treat both identically. */
  async submitManualAssessment(projectId, projectType, answers, { beneficiaryCount } = {}) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const result = computeManualAssessment(projectType, answers, { beneficiaryCount });

    const { error: insertError } = await supabaseClient
      .from('framework_analysis')
      .insert({
        project_id: projectId,
        user_id: session.user.id,
        overall_score: result.overall_score,
        stage: result.stage,
        dimensions: result.dimensions,
        gap_roadmap: result.gap_roadmap,
        financing_recommendations: result.financing_recommendations,
        summary: result.summary,
        raw_model_output: JSON.stringify(answers),
        source: 'manual',
      });
    if (insertError) throw insertError;

    const { error: updateError } = await supabaseClient
      .from('projects')
      .update({
        status: 'completed',
        readiness_stage: result.stage,
        updated_at: new Date().toISOString(),
      })
      .eq('id', projectId);
    if (updateError) throw updateError;

    return result;
  },

  /* ---------- FSU Scoring (ENACOM Resolución 359/2025) ----------
     app/fsu-scoring.html only offers this for FSU_SCORING_ELIGIBLE_TYPE
     projects. computeFsuScore() is exported separately (pure, synchronous)
     so the page can show a live-updating breakdown as the user fills the
     form, before ever saving — these two methods are the persistence
     layer on top of it. */

  async getFsuScoring(projectId) {
    const { data, error } = await supabaseClient
      .from('fsu_scoring')
      .select('*')
      .eq('project_id', projectId)
      .maybeSingle();
    if (error) throw error;
    return data;
  },

  /* `inputs` uses the camelCase field names the form collects (see
     computeFsuScore's doc comment). Recomputes the full breakdown from
     scratch every save and upserts by project_id — one FSU scoring record
     per project, always reflecting the latest inputs. */
  async upsertFsuScoring(projectId, inputs) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const computed = computeFsuScore(inputs);
    const numOrNull = (v) => (v === '' || v == null ? null : Number(v));
    const { data, error } = await supabaseClient
      .from('fsu_scoring')
      .upsert({
        project_id: projectId,
        user_id: session.user.id,
        total_hogares: numOrNull(inputs.totalHogares),
        accesos_fibra: numOrNull(inputs.accesosFibra),
        modelo_negocio: inputs.modeloNegocio || null,
        tecnologia: inputs.tecnologia || null,
        velocidad_actual_mbps: numOrNull(inputs.velocidadActualMbps),
        velocidad_propuesta_mbps: numOrNull(inputs.velocidadPropuestaMbps),
        salto_tecnologico: inputs.saltoTecnologico || null,
        poblacion_localidad: numOrNull(inputs.poblacionLocalidad),
        anos_capacidad_tecnica: inputs.anosCapacidadTecnica || null,
        ...computed,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'project_id' })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  /* ---------- Admin: user management ----------
     All admin-only in practice: RLS (profiles_select_own_or_privileged /
     profiles_update_admin, see supabase/migration_v4_admin_role.sql) is
     what actually enforces this — a non-admin calling these gets an empty
     result / a rejected update, not just a hidden button. */

  async listAllProfiles() {
    const { data, error } = await supabaseClient
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  },

  /* Changes another user's platform role. Deliberately does nothing to
     stop an admin from calling this on their OWN id from devtools — the
     prevent_role_self_change_trigger rejects that at the database level
     regardless of what the client sends. */
  async updateUserRole(userId, role) {
    const { data, error } = await supabaseClient
      .from('profiles')
      .update({ role })
      .eq('id', userId)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  /* ---------- Projects ---------- */

  /* Lists projects visible to the current user. Row Level Security does
     the actual scoping server-side: a regular user's policy only returns
     their own rows, an advisor's policy returns every row — this query is
     identical for both, no client-side role branching needed. The embedded
     `profiles(full_name, organization)` is what lets the advisor grid show
     who submitted each project. */
  async listProjects() {
    const { data, error } = await supabaseClient
      .from('projects')
      .select('*, profiles(full_name, organization)')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  },

  async getProject(id) {
    const { data, error } = await supabaseClient
      .from('projects')
      .select('*, profiles(full_name, organization)')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  /* secondaryTypes is optional — additional infrastructure components
     beyond the single PRIMARY projectType (e.g. a datacenter project that
     also involves a new submarine cable landing and a terrestrial
     backbone). Purely informational/filtering: it doesn't affect scoring
     or which 9th dimension the self-assessment questionnaire uses — that
     always follows the primary projectType. See
     supabase/migration_v6_secondary_project_types.sql. */
  /* beneficiaryCount is optional — households/beneficiaries reached (the
     key impact metric for Universal Service Fund-style submissions, see
     supabase/migration_v7_beneficiary_count.sql). Null/undefined is
     stored as null. */
  async createProject({ name, projectType, secondaryTypes, country, description, beneficiaryCount }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const { data, error } = await supabaseClient
      .from('projects')
      .insert({
        user_id: session.user.id,
        name,
        project_type: projectType,
        secondary_types: (secondaryTypes || []).filter((t) => t !== projectType),
        country,
        description,
        beneficiary_count: beneficiaryCount === '' || beneficiaryCount == null ? null : Number(beneficiaryCount),
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  /* Edits an existing project (owner only — enforced by the
     projects_update_own RLS policy, so this silently fails for anyone
     else even if called). Resets status/readiness_stage so the caller can
     re-trigger analysis against the updated description. */
  async updateProject(id, { name, projectType, secondaryTypes, country, description, beneficiaryCount }) {
    const { data, error } = await supabaseClient
      .from('projects')
      .update({
        name,
        project_type: projectType,
        secondary_types: (secondaryTypes || []).filter((t) => t !== projectType),
        country,
        description,
        beneficiary_count: beneficiaryCount === '' || beneficiaryCount == null ? null : Number(beneficiaryCount),
        status: 'submitted',
        readiness_stage: null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async updateProjectStatus(projectId, status) {
    const { error } = await supabaseClient
      .from('projects')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', projectId);
    if (error) throw error;
  },

  /* ---------- Documents ---------- */

  async uploadDocument(projectId, file) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const userId = session.user.id;
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = `${userId}/${projectId}/${Date.now()}_${safeName}`;

    const { error: uploadError } = await supabaseClient
      .storage
      .from('project-documents')
      .upload(storagePath, file);
    if (uploadError) throw uploadError;

    const { data, error } = await supabaseClient
      .from('project_documents')
      .insert({
        project_id: projectId,
        user_id: userId,
        file_name: file.name,
        storage_path: storagePath,
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async listDocuments(projectId) {
    const { data, error } = await supabaseClient
      .from('project_documents')
      .select('*')
      .eq('project_id', projectId)
      .order('uploaded_at', { ascending: true });
    if (error) throw error;
    return data;
  },

  /* ---------- Framework analysis ---------- */

  async getAnalysis(projectId) {
    const { data, error } = await supabaseClient
      .from('framework_analysis')
      .select('*')
      .eq('project_id', projectId)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error) throw error;
    return data;
  },

  /* Calls the Vercel serverless function that runs the AI analysis.
     This is a POST to a same-origin /api route, so no CORS setup is
     needed — it works automatically once deployed on Vercel. */
  async requestAnalysis(projectId) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const res = await fetch('/api/analyze-project', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ projectId }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(body.error || 'Analysis request failed.');
    return body;
  },
};

window.INAPlatform = INAPlatform;
window.supabaseClient = supabaseClient;
