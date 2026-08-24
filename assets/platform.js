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

// storage: sessionStorage (not the Supabase default of localStorage) —
// Pablo: closing the platform without explicitly signing out should never
// let you back in silently; it should always go through login again. A
// sessionStorage-backed session survives page navigation and reloads
// within the same browser tab (so normal use isn't interrupted), but is
// cleared the moment that tab/window closes, forcing a fresh sign-in next
// time — and since sessionStorage is never shared across tabs/devices to
// begin with, each access point (a second PC, a second tab, a phone) is
// independent of the others by construction, nothing else to change there.
const supabaseClient = (SUPABASE_URL_CLEAN !== 'YOUR_SUPABASE_URL' && SUPABASE_URL_CLEAN && window.supabase)
  ? window.supabase.createClient(SUPABASE_URL_CLEAN, SUPABASE_ANON_KEY_CLEAN, {
      auth: { storage: window.sessionStorage },
    })
  : null;

/* ---------- AI analysis endpoint (Bluehost migration) ----------
   /api/analyze-project.js is a Vercel serverless function; Bluehost has
   no Node.js support, so it stays on Vercel permanently even once the
   site itself is served from Bluehost in production (see
   MIGRACION_BLUEHOST.md Parte 3/4). On the production domain the site and
   the function are no longer same-origin, so this needs an absolute URL
   to the api.* subdomain (CNAME'd to Vercel) instead of the plain
   relative path. Everywhere else — the Vercel dev/test copy, localhost —
   the site and function still share an origin, so the relative path
   keeps working exactly as before. */
const PRODUCTION_HOSTNAMES = ['international-network-advisors.com', 'www.international-network-advisors.com'];
const PRODUCTION_API_ORIGIN = 'https://api.international-network-advisors.com';
function analyzeProjectUrl() {
  if (typeof location !== 'undefined' && PRODUCTION_HOSTNAMES.includes(location.hostname)) {
    return `${PRODUCTION_API_ORIGIN}/analyze-project`;
  }
  return '/api/analyze-project';
}

/* Same reasoning/hosting split as analyzeProjectUrl() above — see
   api/extract-template-data.js, the "Autocomplete from documents" endpoint
   behind app/project-template.html's autofill button. */
function extractTemplateDataUrl() {
  if (typeof location !== 'undefined' && PRODUCTION_HOSTNAMES.includes(location.hostname)) {
    return `${PRODUCTION_API_ORIGIN}/extract-template-data`;
  }
  return '/api/extract-template-data';
}

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
  { value: 'wholesale_neutral_network', en: 'Neutral Wholesale Network (5G/FWA)', es: 'Red Mayorista Neutral (5G/FWA)' },
  { value: 'ai_datacenter', en: 'Datacenter for AI Workloads', es: 'Datacenter para Cargas de IA' },
  { value: 'satellite_constellation', en: 'Satellite Communications', es: 'Comunicaciones Satelitales' },
  { value: 'early_warning_system', en: 'Early Warning System', es: 'Sistema de Alerta Temprana' },
  { value: 'passive_infrastructure', en: 'Passive Infrastructure (poles, ducts, dark fiber)', es: 'Infraestructura Pasiva (postes, ductos, fibra oscura)' },
  { value: 'other', en: 'Other', es: 'Otro' },
];

/* The 7 project_documents.document_type categories (see
   supabase/migration_v15_document_categories.sql and
   supabase/migration_v24_document_categories_expand.sql). None are required
   at upload time — new-project.html offers seven optional drop zones so
   submitters can organize as they go, the AI document-scanning agent has
   clearly labeled source material, and evaluators can find things faster
   later. */
const DOCUMENT_TYPES = [
  { value: 'technical', en: 'Technical description', es: 'Descripción técnica' },
  { value: 'economic', en: 'Economic documentation', es: 'Documentación económica' },
  { value: 'financial', en: 'Financial documentation', es: 'Documentación financiera' },
  { value: 'bylaws', en: 'Bylaws / corporate charter', es: 'Estatuto' },
  { value: 'administrative', en: 'Administrative documentation', es: 'Documentación administrativa' },
  { value: 'licenses', en: 'Licenses', es: 'Licencias' },
  { value: 'other', en: 'Other attachments', es: 'Otros' },
];

/* ---------- Roadmaps (regulatory/administrative checklist) ----------
   See supabase/migration_v26_gestion_templates.sql for the full schema.
   roadmap_templates.entity_type / project_roadmaps.entity_type share this
   same 3-value catalog; project_roadmaps.status is separate. */
const ROADMAP_ENTITY_TYPES = [
  { value: 'public', en: 'Public', es: 'Pública' },
  { value: 'private', en: 'Private', es: 'Privada' },
  { value: 'mixed', en: 'Mixed (public + private)', es: 'Mixta (pública y privada)' },
];

const ROADMAP_STATUS = [
  { value: 'pending', en: 'Pending', es: 'Pendiente' },
  { value: 'in_progress', en: 'In progress', es: 'En curso' },
  { value: 'completed', en: 'Completed', es: 'Completada' },
  { value: 'blocked', en: 'Blocked', es: 'Bloqueada' },
];

/* ---------- Entity taxonomy (who generates a project / who performs a
   Roadmap) ----------
   See migration_v27_gestion_instances.sql. Used in three places: (1)
   projects.generating_entity_type — who submitted the project, (2)
   roadmap_templates.allowed_entity_type — an optional restriction on which
   kind of entity may run the whole checklist (e.g. Early Warning System's
   "Alerta Temprana" template is regulator-only), (3)
   roadmap_instances.performing_entity_type — the entity actually running a
   given instance. Deliberately a different, more specific catalog than
   ROADMAP_ENTITY_TYPES above (public/private/mixed), which just tags a
   template step's own general nature. */
const ENTITY_TYPES = [
  { value: 'regulator', en: 'Regulatory body', es: 'Ente regulador' },
  { value: 'national_gov', en: 'National government', es: 'Gobierno nacional' },
  { value: 'provincial_gov', en: 'Provincial government', es: 'Gobierno provincial' },
  { value: 'municipal_gov', en: 'Municipal government', es: 'Gobierno municipal' },
  { value: 'isp', en: 'ISP', es: 'ISP' },
  { value: 'manufacturer', en: 'Manufacturer', es: 'Fabricante' },
  { value: 'integrator', en: 'Integrator', es: 'Integrador' },
  { value: 'other', en: 'Other', es: 'Otro' },
];

/* Sequential status for one step inside a roadmap_instance (see
   ROADMAP_INSTANCE_STATUS below for the instance-level status). Distinct
   from ROADMAP_STATUS (used by the retired project_roadmaps free-form
   checklist) — adds 'skipped' since a sequential workflow lets the user
   decide NOT to complete an optional step and still move on. */
const ROADMAP_INSTANCE_STEP_STATUS = [
  { value: 'pending', en: 'Pending', es: 'Pendiente' },
  { value: 'in_progress', en: 'In progress', es: 'En curso' },
  { value: 'completed', en: 'Completed', es: 'Completado' },
  { value: 'skipped', en: 'Skipped', es: 'Omitido' },
  { value: 'blocked', en: 'Blocked', es: 'Bloqueado' },
];

const ROADMAP_INSTANCE_STATUS = [
  { value: 'in_progress', en: 'In progress', es: 'En curso' },
  { value: 'completed', en: 'Completed', es: 'Completada' },
  { value: 'abandoned', en: 'Abandoned', es: 'Abandonada' },
];

/* ---------- Project submission templates (app/project-template.html) ----------
   A structured, guided alternative to typing a project's description from
   scratch — for project types where INA/ENACOM maintains a standard
   attribute template (currently just Datacenter, based on ENACOM's July
   2026 "Template de Presentación de Propuestas — Proyectos de Construcción
   / Instalación de Datacenters"). new-project.html shows a "Fill using
   template" link only for project types with an entry here; the template
   page compiles whatever the submitter fills in into one structured text
   block that gets dropped into the project's free-text `description`
   field (there's no separate DB table for this — the template is purely a
   guided way to write a better description, not a new data model).
   PROJECT_TEMPLATES is keyed by the same project_type values as
   PROJECT_TYPES above; add more entries here (submarine_cable,
   fiber_backbone_last_mile, etc.) the same way to extend this to other
   project types later. */

const DATACENTER_TEMPLATE = {
  title: { en: 'Datacenter project template', es: 'Template de proyecto de Datacenter' },
  intro: {
    en: 'Based on ENACOM’s standard Datacenter proposal template (v3, July 2026) — covers traditional, edge/SME, hybrid and AI (inference/training) datacenters, for presentation to ENACOM and/or to multilateral lenders (CAF, IDB and similar). Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en el template estándar de propuestas de Datacenter de ENACOM (v3, julio 2026) — cubre datacenters tradicionales, edge/PyME, híbridos y de IA (inferencia/entrenamiento), para presentación ante ENACOM y/o ante organismos multilaterales de crédito (CAF, BID y similares). Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Applicant, project & institutional roles', es: '0. Datos generales del proponente y roles institucionales' },
      fields: [
        {
          key: 'destinatario_presentacion', type: 'select',
          label: { en: 'Presentation addressed to', es: 'Destinatario de la presentación' },
          options: [
            { value: 'enacom', en: 'ENACOM', es: 'ENACOM' },
            { value: 'organismo_multilateral', en: 'Multilateral organization (CAF, IDB, other — specify)', es: 'Organismo multilateral (CAF, BID u otro — especificar)' },
            { value: 'ambos', en: 'Both', es: 'Ambos' },
          ],
        },
        {
          key: 'organismo_ejecutor', type: 'text',
          label: { en: 'Executing agency / counterpart', es: 'Organismo ejecutor / contraparte' },
          placeholder: { en: 'Entity responsible for execution and accountability', es: 'Entidad responsable de la ejecución y rendición de cuentas' },
        },
        {
          key: 'monto_total_solicitado', type: 'text',
          label: { en: 'Total amount requested & currency', es: 'Monto total solicitado y moneda' },
        },
        {
          key: 'roles_institucionales', type: 'textarea',
          label: { en: 'Institutional roles & responsibilities', es: 'Roles y responsabilidades institucionales' },
          placeholder: { en: 'When more than one institutional actor is involved: public/regulatory body, proposing consortium/executor, financing institution, other actors (municipalities, universities, associated ISPs) and their proposed roles', es: 'Cuando el proyecto involucre más de un actor institucional: organismo público/regulador, proponente/consorcio ejecutor, organismo financiador, otros actores (municipios, universidades, ISPs asociados) y el rol propuesto de cada uno' },
        },
      ],
    },
    {
      key: 'classification',
      title: { en: '1. Classification', es: '1. Clasificación' },
      fields: [
        {
          key: 'tipo_datacenter', type: 'select',
          label: { en: 'Datacenter type', es: 'Tipo de datacenter' },
          options: [
            { value: 'edge_micro', en: 'Edge / Micro (distributed SME)', es: 'Edge / Micro (PyME distribuido)' },
            { value: 'tradicional', en: 'Traditional / Enterprise', es: 'Tradicional / Enterprise' },
            { value: 'colocation', en: 'Colocation', es: 'Colocation' },
            { value: 'hibrido', en: 'Hybrid (traditional + AI layer)', es: 'Híbrido (tradicional + capa IA)' },
            { value: 'ia_inferencia', en: 'AI — Inference', es: 'IA — Inferencia' },
            { value: 'ia_entrenamiento', en: 'AI — Training / Hyperscale', es: 'IA — Entrenamiento / Hyperscale' },
          ],
        },
        {
          key: 'escala_potencia', type: 'select',
          label: { en: 'Project scale (total power)', es: 'Escala del proyecto (potencia total)' },
          options: [
            { value: 'lt_1mw', en: '< 1 MW (Edge/Micro)', es: '< 1 MW (Edge/Micro)' },
            { value: '1_50mw', en: '1–50 MW (Traditional/Enterprise)', es: '1–50 MW (Tradicional/Enterprise)' },
            { value: '50_100mw', en: '50–100 MW (mid-size AI)', es: '50–100 MW (IA mediano)' },
            { value: '100mw_1gw', en: '100 MW – 1+ GW (AI Hyperscale)', es: '100 MW – 1+ GW (IA Hyperscale)' },
          ],
        },
        {
          key: 'topologia', type: 'select',
          label: { en: 'Topology', es: 'Topología' },
          options: [
            { value: 'sitio_unico', en: 'Single site', es: 'Sitio único' },
            { value: 'red_distribuida', en: 'Distributed network of N nodes', es: 'Red distribuida de N nodos' },
          ],
        },
        {
          key: 'topologia_detalle', type: 'text',
          label: { en: 'Topology detail (if distributed)', es: 'Detalle de topología (si es red distribuida)' },
          placeholder: { en: 'e.g. 6 nodes, 200–500 kW each', es: 'ej. 6 nodos, 200–500 kW cada uno' },
        },
        {
          key: 'uso_servicio', type: 'select',
          label: { en: 'Intended use / service model', es: 'Uso previsto / modelo de servicio' },
          options: [
            { value: 'hosting_propio', en: 'Own hosting / internal use', es: 'Hosting propio / uso interno' },
            { value: 'colocation', en: 'Colocation', es: 'Colocation' },
            { value: 'cloud_publico', en: 'General public cloud', es: 'Cloud público general' },
            { value: 'gpu_as_a_service', en: 'GPU-as-a-Service', es: 'GPU-as-a-Service' },
            { value: 'reserved_capacity', en: 'Reserved Capacity', es: 'Reserved Capacity' },
            { value: 'sovereign_ai_cloud', en: 'Sovereign AI Cloud', es: 'Sovereign AI Cloud' },
            { value: 'inference_endpoints', en: 'Inference Endpoints (API)', es: 'Inference Endpoints (API)' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
        {
          key: 'horizonte_despliegue', type: 'select',
          label: { en: 'Deployment horizon', es: 'Horizonte de despliegue' },
          options: [
            { value: 'greenfield', en: 'New (greenfield)', es: 'Nuevo (greenfield)' },
            { value: 'reconversion', en: 'Retrofit of existing site/infrastructure', es: 'Reconversión de sitio/infraestructura existente' },
          ],
        },
        {
          key: 'segmento_servicio', type: 'select',
          label: { en: 'Service segment / target audience', es: 'Segmentos de servicio / público objetivo' },
          options: [
            { value: 'municipios_comunas', en: 'Municipalities and local governments', es: 'Municipios y comunas' },
            { value: 'empresas_comercios', en: 'Businesses and commerce', es: 'Empresas y comercios' },
            { value: 'sector_agropecuario', en: 'Agricultural sector', es: 'Sector agropecuario' },
            { value: 'educacion', en: 'Education', es: 'Educación' },
            { value: 'salud', en: 'Health', es: 'Salud' },
            { value: 'organismos_publicos', en: 'Public agencies', es: 'Organismos públicos' },
            { value: 'consumidor_final', en: 'End consumer', es: 'Consumidor final' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
      ],
    },
    {
      key: 'site',
      title: { en: '2. Site & land', es: '2. Sitio y terreno' },
      fields: [
        {
          key: 'modalidad_sitio', type: 'select',
          label: { en: 'Site type', es: 'Modalidad del sitio' },
          options: [
            { value: 'terreno_propio', en: 'Own land, new build', es: 'Terreno propio, obra nueva' },
            { value: 'edificio_reconvertido', en: 'Retrofitted existing building', es: 'Edificio existente reconvertido' },
            { value: 'infra_isp', en: 'Reused ISP infrastructure (shelter / FTTH headend)', es: 'Infraestructura de ISP reutilizada (shelter / cabecera FTTH)' },
            { value: 'contenedor_modular', en: 'Prefabricated modular container', es: 'Contenedor modular prefabricado' },
          ],
        },
        {
          key: 'superficie_sitio', type: 'text',
          label: { en: 'Site area', es: 'Superficie del sitio' },
          placeholder: { en: 'e.g. 8 m² (edge/micro shelter) or per rack/aisle layout (traditional/AI)', es: 'ej. 8 m² (shelter edge/micro) o según layout de racks y pasillos (tradicional/IA)' },
        },
        {
          key: 'tenencia', type: 'select',
          label: { en: 'Land tenure', es: 'Tenencia' },
          options: [
            { value: 'propiedad', en: 'Owned', es: 'Propiedad' },
            { value: 'alquiler', en: 'Long-term lease/loan (specify years)', es: 'Alquiler / comodato a largo plazo (indicar años)' },
          ],
        },
        {
          key: 'uso_largo_plazo', type: 'select',
          label: { en: 'Long-term use secured', es: 'Uso a largo plazo asegurado' },
          options: [
            { value: 'si_documentado', en: 'Yes, documented', es: 'Sí, con documentación' },
            { value: 'parcial', en: 'Partial / in progress', es: 'Parcial / en trámite' },
            { value: 'no_definido', en: 'Not defined', es: 'No definido' },
          ],
        },
      ],
    },
    {
      key: 'energy',
      title: { en: '3. Power', es: '3. Energía' },
      fields: [
        {
          key: 'potencia_total', type: 'text',
          label: { en: 'Planned total power', es: 'Potencia total planificada' },
          placeholder: { en: 'e.g. 40 MW', es: 'ej. 40 MW' },
        },
        {
          key: 'densidad_rack', type: 'text',
          label: { en: 'Power density per rack', es: 'Densidad de energía por rack' },
          placeholder: { en: 'e.g. 80 kW/rack', es: 'ej. 80 kW/rack' },
        },
        {
          key: 'redundancia_energetica', type: 'select',
          label: { en: 'Power redundancy', es: 'Redundancia energética' },
          options: [
            { value: 'n', en: 'N (no redundancy)', es: 'N (sin redundancia)' },
            { value: 'n_plus_1', en: 'N+1', es: 'N+1' },
            { value: '2n', en: '2N', es: '2N' },
            { value: '2n_plus_1', en: '2N+1', es: '2N+1' },
          ],
        },
        {
          key: 'fuente_suministro', type: 'select',
          label: { en: 'Power source', es: 'Fuente de suministro' },
          options: [
            { value: 'red_distribuidora', en: 'Local utility grid', es: 'Red de distribuidora local' },
            { value: 'generacion_propia', en: 'Own generation', es: 'Generación propia' },
            { value: 'ppa_renovable', en: 'Renewable PPA', es: 'PPA renovable' },
            { value: 'mix', en: 'Mix', es: 'Mix' },
          ],
        },
        {
          key: 'respaldo_ups', type: 'text',
          label: { en: 'UPS backup (type & autonomy)', es: 'Respaldo (UPS): tipo y autonomía' },
        },
        {
          key: 'respaldo_generador', type: 'text',
          label: { en: 'Generator backup (fuel & autonomy)', es: 'Respaldo (generador): combustible y autonomía' },
        },
        {
          key: 'factibilidad_distribuidora', type: 'select',
          label: { en: 'Feasibility with local utility', es: 'Factibilidad con distribuidora local' },
          options: [
            { value: 'confirmada', en: 'Confirmed / documented', es: 'Confirmada / con documentación' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
            { value: 'no_verificada', en: 'Not verified', es: 'No verificada' },
          ],
        },
      ],
    },
    {
      key: 'cooling',
      title: { en: '4. Cooling', es: '4. Refrigeración' },
      fields: [
        {
          key: 'tipo_refrigeracion', type: 'select',
          label: { en: 'Cooling type', es: 'Tipo de refrigeración' },
          options: [
            { value: 'aire_forzado', en: 'Forced air (CRAC/CRAH)', es: 'Aire forzado (CRAC/CRAH)' },
            { value: 'dlc', en: 'Direct Liquid Cooling (back-plate or cold plate)', es: 'Direct Liquid Cooling (back-plate o cold plate)' },
            { value: 'inmersion', en: 'Dielectric immersion (single/two-phase)', es: 'Inmersión en dieléctrico (single/two-phase)' },
          ],
        },
        {
          key: 'pue_objetivo', type: 'text',
          label: { en: 'Target PUE', es: 'PUE objetivo declarado' },
          placeholder: { en: 'e.g. 1.25 (industry reference: traditional 1.4–2.0, new-build AI 1.1–1.3)', es: 'ej. 1.25 (referencia: tradicional 1.4–2.0, IA nueva instalación 1.1–1.3)' },
        },
      ],
    },
    {
      key: 'compute',
      title: { en: '5. Compute', es: '5. Cómputo' },
      fields: [
        {
          key: 'tipo_computo', type: 'select',
          label: { en: 'Primary compute type', es: 'Tipo principal de cómputo' },
          options: [
            { value: 'cpu_x86', en: 'General-purpose x86 CPU (Xeon, EPYC)', es: 'CPU x86 de propósito general (Xeon, EPYC)' },
            { value: 'gpu', en: 'GPU (NVIDIA H100/H200/B200, AMD MI300X)', es: 'GPU (NVIDIA H100/H200/B200, AMD MI300X)' },
            { value: 'tpu', en: 'TPU', es: 'TPU' },
            { value: 'npu_asic', en: 'NPU / ASIC (Trainium, Maia, MTIA)', es: 'NPU / ASIC (Trainium, Maia, MTIA)' },
            { value: 'mixto', en: 'Mixed', es: 'Mixto' },
          ],
        },
        {
          key: 'carga_trabajo', type: 'select',
          label: { en: 'Target workload', es: 'Carga de trabajo objetivo' },
          options: [
            { value: 'transaccional', en: 'Transactional / web / databases', es: 'Transaccional / web / bases de datos' },
            { value: 'inferencia', en: 'Inference (AI assistants/services)', es: 'Inferencia (asistentes, IA como servicio)' },
            { value: 'entrenamiento', en: 'Model training (LLMs)', es: 'Entrenamiento de modelos (LLMs)' },
          ],
        },
        {
          key: 'memoria_ancho_banda', type: 'text',
          label: { en: 'Memory / bandwidth', es: 'Memoria / ancho de banda' },
          placeholder: { en: 'e.g. HBM co-packaged, up to 3 TB/s', es: 'ej. HBM co-packaged, hasta 3 TB/s' },
        },
        {
          key: 'especificaciones_servidores', type: 'textarea',
          label: { en: 'Server specifications (compute & AI)', es: 'Especificaciones de servidores (cómputo e IA)' },
          placeholder: { en: 'Compute/virtualization servers: unit count, cores, RAM, local storage. AI servers: unit count, GPU/accelerator model, RAM, local NVMe/SSD storage', es: 'Servidor de cómputo/virtualización: cantidad de unidades, núcleos, RAM, almacenamiento local. Servidor de IA: cantidad de unidades, modelo de GPU/acelerador, RAM, almacenamiento local NVMe/SSD' },
        },
      ],
    },
    {
      key: 'network',
      title: { en: '6. Network & connectivity', es: '6. Red y conectividad' },
      fields: [
        {
          key: 'red_interna', type: 'select',
          label: { en: 'Internal network (within site)', es: 'Red interna (dentro del sitio)' },
          options: [
            { value: 'ethernet_10_25_100', en: 'Ethernet 10/25/100 GbE', es: 'Ethernet 10/25/100 GbE' },
            { value: 'infiniband_ndr', en: 'InfiniBand NDR 400 Gb/s', es: 'InfiniBand NDR 400 Gb/s' },
            { value: 'ethernet_400', en: 'Ethernet 400 GbE', es: 'Ethernet 400 GbE' },
          ],
        },
        {
          key: 'ancho_banda_externo', type: 'text',
          label: { en: 'Contracted external bandwidth', es: 'Ancho de banda externo contratado' },
          placeholder: { en: 'initial / recommended / max scalable (Gbps)', es: 'inicial / recomendado / máximo escalable (Gbps)' },
        },
        {
          key: 'redundancia_transito', type: 'select',
          label: { en: 'Transit redundancy', es: 'Redundancia de tránsito' },
          options: [
            { value: 'un_proveedor', en: 'Single provider', es: '1 proveedor único' },
            { value: 'dos_o_mas', en: '≥ 2 independent providers, route diversity', es: '≥ 2 proveedores independientes con diversidad de rutas' },
          ],
        },
      ],
    },
    {
      key: 'storage',
      title: { en: '7. Storage', es: '7. Almacenamiento' },
      fields: [
        {
          key: 'tipo_almacenamiento', type: 'select',
          label: { en: 'Storage type', es: 'Tipo de almacenamiento' },
          options: [
            { value: 'hdd_ssd_mixto', en: 'Mixed HDD/SSD (SAN/NAS)', es: 'HDD / SSD mixto (SAN/NAS)' },
            { value: 'nvme_all_flash', en: 'NVMe all-flash', es: 'NVMe all-flash' },
            { value: 'hbm_copackaged', en: 'HBM co-packaged (AI accelerators)', es: 'HBM co-packaged (asociado a aceleradores IA)' },
          ],
        },
        {
          key: 'capacidad_inicial_almacenamiento', type: 'text',
          label: { en: 'Initial capacity', es: 'Capacidad inicial' },
          placeholder: { en: 'e.g. 20–50 TB (edge/micro) or TB/PB per design (traditional/AI)', es: 'ej. 20–50 TB (edge/micro) o según diseño en TB/PB (tradicional/IA)' },
        },
        {
          key: 'escalabilidad_almacenamiento', type: 'text',
          label: { en: 'Storage scalability', es: 'Escalabilidad de almacenamiento' },
          placeholder: { en: 'e.g. up to 100 TB or more (edge/micro) or growth roadmap (traditional/AI)', es: 'ej. hasta 100 TB o más (edge/micro) o roadmap de crecimiento (tradicional/IA)' },
        },
      ],
    },
    {
      key: 'security',
      title: { en: '8. Physical security & Tier level', es: '8. Seguridad física y nivel Tier' },
      fields: [
        {
          key: 'nivel_tier', type: 'select',
          label: { en: 'Tier level (Uptime Institute)', es: 'Nivel Tier (Uptime Institute)' },
          options: [
            { value: 'tier_1', en: 'Tier I', es: 'Tier I' },
            { value: 'tier_2', en: 'Tier II', es: 'Tier II' },
            { value: 'tier_3', en: 'Tier III', es: 'Tier III' },
            { value: 'tier_4', en: 'Tier IV', es: 'Tier IV' },
            { value: 'no_aplica', en: 'Not applicable at this scale (explain in notes)', es: 'No aplica a esta escala (justificar en notas)' },
          ],
        },
        {
          key: 'controles_minimos', type: 'text',
          label: { en: 'Minimum controls', es: 'Controles mínimos' },
          placeholder: { en: 'e.g. access control, 24/7 CCTV, fire detection', es: 'ej. control de acceso, CCTV 24/7, detección de incendio' },
        },
      ],
    },
    {
      key: 'regulatory',
      title: { en: '9. Regulatory & fiscal framework', es: '9. Marco regulatorio y fiscal' },
      fields: [
        {
          key: 'licencia_tic', type: 'select',
          label: { en: 'TIC license (Law 27,078)', es: 'Licencia TIC (Ley 27.078)' },
          options: [
            { value: 'vigente', en: 'In force', es: 'Vigente' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
            { value: 'no_aplica', en: 'Not applicable (internal use only)', es: 'No aplica (uso interno, sin servicio a terceros)' },
            { value: 'no_contemplado', en: 'Not contemplated in this proposal', es: 'No contemplado en la propuesta' },
          ],
        },
        {
          key: 'habilitaciones', type: 'select',
          label: { en: 'Municipal / environmental permits', es: 'Habilitaciones municipales / ambientales' },
          options: [
            { value: 'vigentes', en: 'In force', es: 'Vigentes' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
            { value: 'no_iniciadas', en: 'Not started', es: 'No iniciadas' },
          ],
        },
        {
          key: 'uso_suelo', type: 'select',
          label: { en: 'Land-use conformity', es: 'Conformidad de uso de suelo' },
          options: [
            { value: 'si', en: 'Yes', es: 'Sí' },
            { value: 'no', en: 'No', es: 'No' },
            { value: 'en_verificacion', en: 'Being verified', es: 'En verificación' },
          ],
        },
      ],
    },
    {
      key: 'sustainability',
      title: { en: '10. Sustainability', es: '10. Sustentabilidad' },
      fields: [
        {
          key: 'fuente_energia_sustentable', type: 'select',
          label: { en: 'Energy source', es: 'Fuente de energía' },
          options: [
            { value: 'renovable', en: 'Renewable (10–20yr PPA)', es: 'Renovable (PPA 10–20 años)' },
            { value: 'red_convencional', en: 'Conventional grid', es: 'Red convencional' },
            { value: 'mixta', en: 'Mixed', es: 'Mixta' },
            { value: 'nuclear_smr', en: 'Nuclear / SMR (large-scale projects)', es: 'Nuclear / SMR (proyectos de gran escala)' },
          ],
        },
        {
          key: 'consumo_agua', type: 'text',
          label: { en: 'Estimated water consumption', es: 'Consumo de agua estimado' },
          placeholder: { en: 'liters/day, or "N/A — no significant water use"', es: 'litros/día, o "No aplica — sin consumo hídrico relevante"' },
        },
        {
          key: 'reuso_calor', type: 'select',
          label: { en: 'Waste heat reuse', es: 'Reuso de calor residual' },
          options: [
            { value: 'implementado', en: 'Yes, implemented', es: 'Sí, implementado' },
            { value: 'planificado', en: 'Planned', es: 'Planificado' },
            { value: 'no_contemplado', en: 'Not contemplated', es: 'No contemplado' },
          ],
        },
      ],
    },
    {
      key: 'financials',
      title: { en: '11. Business model & financials', es: '11. Modelo de negocio y financiero' },
      fields: [
        {
          key: 'etapa_propuesta', type: 'select',
          label: { en: 'Proposal stage', es: 'Etapa de la propuesta' },
          options: [
            { value: 'piloto', en: 'Pilot', es: 'Piloto' },
            { value: 'etapa_unica', en: 'Single stage', es: 'Etapa única' },
            { value: 'expansion', en: 'Expansion (specify stage #)', es: 'Expansión (indicar Nº de etapa)' },
          ],
        },
        {
          key: 'fuente_financiamiento_buscada', type: 'select',
          label: { en: 'Financing sought', es: 'Fuente de financiamiento buscada' },
          options: [
            { value: 'capital_propio', en: 'Own capital', es: 'Capital propio' },
            { value: 'prestamo_multilateral', en: 'Multilateral loan', es: 'Préstamo de organismo multilateral' },
            { value: 'donacion', en: 'Grant / technical cooperation', es: 'Donación / cooperación técnica' },
            { value: 'blended', en: 'Blended finance', es: 'Financiamiento mixto (blended finance)' },
            { value: 'bancario_local', en: 'Local bank financing', es: 'Financiamiento bancario local' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
        {
          key: 'capex_total', type: 'text',
          label: { en: 'Total CAPEX (and per MW/node, if known)', es: 'CAPEX total (y por MW/nodo, si se conoce)' },
          placeholder: { en: 'Reference: traditional USD 5–10M/MW, AI USD 15–30M/MW', es: 'Referencia: tradicional USD 5–10M/MW, IA USD 15–30M/MW' },
        },
        {
          key: 'opex_anual', type: 'text',
          label: { en: 'Estimated annual OPEX', es: 'OPEX anual estimado' },
        },
        {
          key: 'modelo_pricing', type: 'select',
          label: { en: 'Service pricing model', es: 'Modelo de pricing de servicios' },
          options: [
            { value: 'gpu_as_a_service', en: 'GPU-as-a-Service (USD/hr per GPU)', es: 'GPU-as-a-Service (USD/hora por GPU)' },
            { value: 'reserved_capacity', en: 'Reserved Capacity (take-or-pay)', es: 'Reserved Capacity (take-or-pay)' },
            { value: 'sovereign_ai_cloud', en: 'Sovereign AI Cloud (dedicated capacity)', es: 'Sovereign AI Cloud (capacidad dedicada)' },
            { value: 'inference_endpoints', en: 'Inference Endpoints (USD per 1K tokens)', es: 'Inference Endpoints (USD por 1K tokens)' },
            { value: 'colocation_hosting', en: 'Colocation / traditional hosting (per rack/kW)', es: 'Colocation / hosting tradicional (por rack/kW)' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
        {
          key: 'indicadores_rentabilidad', type: 'text',
          label: { en: 'Financial return indicators', es: 'Indicadores de rentabilidad financiera' },
          placeholder: { en: 'NPV, IRR, payback', es: 'VAN, TIR, payback' },
        },
        {
          key: 'tasa_retorno_economico', type: 'textarea',
          label: { en: 'Economic rate of return (ERR)', es: 'Tasa de retorno económico (ERR)' },
          placeholder: { en: 'Usually required by CAF/IDB to justify the use of public or concessional funds; include assumptions behind the quantified economic and social benefits', es: 'Requerido habitualmente por CAF/BID para justificar uso de fondos públicos o concesionales; incluir supuestos de beneficios económicos y sociales cuantificados' },
        },
        {
          key: 'analisis_sensibilidad', type: 'textarea',
          label: { en: 'Sensitivity analysis', es: 'Análisis de sensibilidad' },
          placeholder: { en: 'Critical variables assessed (exchange rate, energy price, service demand) and the range of variation considered', es: 'Variables críticas evaluadas (tipo de cambio, precio de energía, demanda de servicios) y rango de variación considerado' },
        },
        {
          key: 'moneda_cobertura_cambiaria', type: 'text',
          label: { en: 'Loan/investment currency & FX hedging', es: 'Moneda del préstamo/inversión y cobertura de riesgo cambiario' },
          placeholder: { en: 'Hedging mechanism, if applicable', es: 'Mecanismo de cobertura (hedging), si aplica' },
        },
        {
          key: 'cronograma_desembolsos', type: 'text',
          label: { en: 'Disbursement schedule', es: 'Cronograma de desembolsos' },
          placeholder: { en: 'By project stage/milestone', es: 'Por etapa/hito del proyecto' },
        },
        {
          key: 'estructura_financiamiento', type: 'select',
          label: { en: 'Proposed financing structure', es: 'Estructura de financiamiento propuesta' },
          options: [
            { value: 'deuda_concesional', en: 'Concessional debt / multilateral loan', es: 'Deuda concesional / préstamo de organismo multilateral' },
            { value: 'donacion', en: 'Non-reimbursable grant / technical cooperation', es: 'Donación / cooperación técnica no reembolsable' },
            { value: 'contrapartida_local', en: 'Local counterpart funds (ENACOM/Treasury/provinces)', es: 'Contrapartida local (ENACOM / Tesoro / provincias)' },
            { value: 'capital_privado', en: 'Private capital', es: 'Capital privado' },
            { value: 'blended', en: 'Blended finance', es: 'Financiamiento mixto (blended finance)' },
          ],
        },
      ],
    },
    {
      key: 'sizing',
      title: { en: '12. Sizing & estimated operating capacity', es: '12. Dimensionamiento y capacidad operativa estimada' },
      fields: [
        {
          key: 'servidores_virtuales_nodo', type: 'text',
          label: { en: 'Virtual servers supported (per node)', es: 'Servidores virtuales soportados (por nodo)' },
          placeholder: { en: 'Reference: 20–30 VPS with 2 Gbps initially', es: 'Referencia: 20–30 VPS con 2 Gbps iniciales' },
        },
        {
          key: 'dispositivos_iot_soportados', type: 'text',
          label: { en: 'IoT devices / IP cameras supported', es: 'Dispositivos IoT / cámaras IP soportadas' },
          placeholder: { en: 'Reference: 200–500 IP cameras', es: 'Referencia: 200–500 cámaras IP' },
        },
        {
          key: 'clientes_institucionales_estimados', type: 'text',
          label: { en: 'Estimated institutional clients (municipalities)', es: 'Clientes institucionales estimados (municipios)' },
          placeholder: { en: 'Reference: 5–10 small municipalities per node', es: 'Referencia: 5–10 municipios pequeños por nodo' },
        },
        {
          key: 'clientes_empresariales_estimados', type: 'text',
          label: { en: 'Estimated business clients', es: 'Clientes empresariales estimados' },
          placeholder: { en: 'Reference: 100+ businesses per node', es: 'Referencia: 100+ empresas por nodo' },
        },
        {
          key: 'volumen_consultas_ia_estimado', type: 'text',
          label: { en: 'Estimated AI query volume', es: 'Volumen de consultas de IA estimado' },
          placeholder: { en: 'e.g. thousands of monthly queries per node', es: 'ej. miles de consultas mensuales por nodo' },
        },
        {
          key: 'supuestos_dimensionamiento', type: 'textarea',
          label: { en: 'Sizing assumptions', es: 'Supuestos de dimensionamiento' },
          placeholder: { en: 'Relationship between contracted bandwidth, equipment and declared service capacity', es: 'Relación entre ancho de banda contratado, equipamiento y capacidad de servicio declarada' },
        },
      ],
    },
  ],
  // A free-text catch-all for anything not covered above by structured
  // fields — this is the release valve for anyone who wants to paste in
  // more from the source ENACOM template (v3, July 2026):
  //  - Section 4, Environmental & social safeguards — required whenever the
  //    proposal seeks multilateral financing (CAF/IDB): environmental &
  //    social categorization (A/B/C), EIAS/PGAS status, stakeholder
  //    consultation, indigenous peoples, involuntary resettlement, labor
  //    standards, e-waste management, grievance mechanism.
  //  - Section 5, Results framework / logframe — objectives, indicators,
  //    baselines and targets.
  //  - Section 6, Risk matrix — 7 categories: technical/execution,
  //    energy, financial, environmental & social, regulatory,
  //    market/demand, institutional/governance.
  //  - Section 7, Staged deployment plan — pilot/expansion/consolidation
  //    stages, quantitative pilot success KPIs (not just "validate the
  //    model" without metrics).
  //  - Section 8, Supporting documentation checklist.
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (environmental & social safeguards, results framework/logframe, 7-category risk matrix, staged deployment plan & pilot KPIs, supporting documentation checklist, etc.)', es: 'Notas adicionales (salvaguardas ambientales y sociales, marco de resultados/marco lógico, matriz de riesgos de 7 categorías, plan de despliegue por etapas y KPIs del piloto, checklist de documentación de respaldo, etc.)' },
  },
};

/* Based on ENACOM Advisory IT's "Template de Carga de Proyecto — Cable
   Submarino" (Julio 2026, v1.0) — its Bloques A–H map to the sections
   below. Bloque F (10-category risk matrix) and Bloque H (submission
   checklist) aren't modeled as individual fields — they're narrative/
   checklist content better suited to the free-text notesField than to
   dozens more inputs; the notes label points people there explicitly. */
/* Based on ENACOM's standard submarine cable project template, enriched with
   fields grounded in the recommendations of the International Advisory Body
   on Submarine Cable Resilience (IAB), "International Advisory Body on
   Submarine Cable Resilience" report, July 2026 — specifically: route
   diversity from existing chokepoints (Rec. 10), branching units for future
   connectivity (Rec. 7), multi-hazard vulnerability assessments (Rec. 12),
   CLS/OSP physical security and real-time DAS fronthaul monitoring (Rec.
   13), satellite/microwave failover protocols (Rec. 14), a designated SPOC
   for permitting (Recs. 1f/2), anchor-tenancy commitments (Recs. 3/8) and
   insurance mechanisms including parametric/cat-bond options (Rec. 4). */
const SUBMARINE_CABLE_TEMPLATE = {
  title: { en: 'Submarine cable project template', es: 'Template de proyecto de Cable Submarino' },
  intro: {
    en: 'Based on ENACOM’s standard submarine cable project template, enriched with international resilience and bankability best practices (IAB, 2026) — covers new cable systems, capacity expansions and new/upgraded landing stations. Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en el template estándar de proyectos de cable submarino de ENACOM, enriquecido con mejores prácticas internacionales de resiliencia y bancabilidad (IAB, 2026) — cubre sistemas de cable nuevos, ampliaciones de capacidad y estaciones de aterrizaje nuevas o mejoradas. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'diagnosis',
      title: { en: 'A. Identification & strategic diagnosis', es: 'A. Identificación y diagnóstico estratégico' },
      fields: [
        {
          key: 'sponsor_tipo', type: 'select',
          label: { en: 'Sponsor / promoting entity', es: 'Sponsor / entidad promotora' },
          options: [
            { value: 'operador_privado', en: 'Private operator', es: 'Operador privado' },
            { value: 'consorcio', en: 'Consortium', es: 'Consorcio' },
            { value: 'agencia_publica', en: 'Public agency', es: 'Agencia pública' },
            { value: 'vehiculo_mixto', en: 'Mixed vehicle (public-private)', es: 'Vehículo mixto (público-privado)' },
          ],
        },
        {
          key: 'tipo_iniciativa', type: 'select',
          label: { en: 'Type of initiative', es: 'Tipo de iniciativa' },
          options: [
            { value: 'nuevo_cable', en: 'New submarine cable', es: 'Nuevo cable submarino' },
            { value: 'ampliacion_capacidad', en: 'Capacity expansion', es: 'Ampliación de capacidad' },
            { value: 'nueva_landing', en: 'New landing station', es: 'Nueva estación de aterrizaje (landing station)' },
            { value: 'interconexion_landing', en: 'Interconnection with existing landing', es: 'Interconexión con landing existente' },
          ],
        },
        {
          key: 'sponsor_ejecutivo', type: 'text',
          label: { en: 'Designated executive sponsor', es: 'Sponsor ejecutivo designado' },
          placeholder: { en: 'Name and title', es: 'Nombre y cargo' },
        },
        {
          key: 'problema_necesidad', type: 'textarea',
          label: { en: 'Problem / need being addressed', es: 'Problema / necesidad a resolver' },
          placeholder: { en: 'e.g. lack of international redundancy, single point of failure, capacity saturation', es: 'ej. falta de redundancia internacional, punto único de falla, saturación de capacidad' },
        },
        {
          key: 'alineacion_estrategica', type: 'textarea',
          label: { en: 'Strategic alignment', es: 'Alineación estratégica' },
          placeholder: { en: 'Link to the National Connectivity Plan / ENACOM objectives', es: 'Vínculo con Plan Nacional de Conectividad / objetivos de ENACOM' },
        },
        {
          key: 'nivel_madurez', type: 'select',
          label: { en: 'Current maturity level', es: 'Nivel de madurez actual' },
          options: [
            { value: 'idea', en: 'Idea', es: 'Idea' },
            { value: 'prefactibilidad', en: 'Pre-feasibility', es: 'Prefactibilidad' },
            { value: 'factibilidad', en: 'Feasibility', es: 'Factibilidad' },
            { value: 'estructuracion', en: 'Structuring', es: 'Estructuración' },
            { value: 'listo_inversion', en: 'Investment ready', es: 'Listo para inversión' },
          ],
        },
      ],
    },
    {
      key: 'system',
      title: { en: 'B.1 Cable system — general data', es: 'B.1 Ficha técnica — datos generales del sistema' },
      fields: [
        {
          key: 'nombre_sistema', type: 'text',
          label: { en: 'Cable system name', es: 'Nombre del sistema de cable' },
        },
        {
          key: 'tipo_segmento', type: 'select',
          label: { en: 'Segment type', es: 'Tipo de segmento' },
          options: [
            { value: 'troncal_internacional', en: 'International trunk', es: 'Troncal internacional' },
            { value: 'regional', en: 'Regional', es: 'Regional' },
            { value: 'feston_nacional', en: 'National festoon', es: 'Festón nacional' },
          ],
        },
        {
          key: 'landing_argentina', type: 'text',
          label: { en: 'Landing point(s) in Argentina', es: 'Punto(s) de aterrizaje en Argentina' },
          placeholder: { en: 'Locality, province (e.g. Las Toninas, Buenos Aires)', es: 'Localidad, provincia (ej. Las Toninas, Buenos Aires)' },
        },
        {
          key: 'landing_exterior', type: 'text',
          label: { en: 'Landing point(s) abroad', es: 'Punto(s) de aterrizaje en el exterior' },
        },
        {
          key: 'longitud_km', type: 'text',
          label: { en: 'Estimated total length (km)', es: 'Longitud total estimada (km)' },
        },
        {
          key: 'profundidad_maxima', type: 'text',
          label: { en: 'Maximum lay depth', es: 'Profundidad máxima de tendido' },
        },
        {
          key: 'pares_fibra', type: 'text',
          label: { en: 'Number of fiber pairs', es: 'Número de pares de fibra' },
        },
        {
          key: 'capacidad_diseno', type: 'text',
          label: { en: 'Design capacity (Tbps)', es: 'Capacidad de diseño (Tbps)' },
        },
        {
          key: 'tecnologia_transmision', type: 'text',
          label: { en: 'Transmission technology', es: 'Tecnología de transmisión' },
          placeholder: { en: 'e.g. coherent 400G/800G, system vendor', es: 'ej. coherente 400G/800G, fabricante de sistema' },
        },
        {
          key: 'vida_util_estimada', type: 'text',
          label: { en: 'Estimated service life', es: 'Vida útil estimada' },
          placeholder: { en: 'Typically 20–25 years', es: 'Típico 20–25 años' },
        },
        {
          key: 'etapa_proyecto', type: 'select',
          label: { en: 'Project stage', es: 'Etapa del proyecto' },
          options: [
            { value: 'estudio_ruta', en: 'Route survey', es: 'Estudio de ruta' },
            { value: 'permisos', en: 'Permitting', es: 'Permisos' },
            { value: 'financiamiento', en: 'Financing', es: 'Financiamiento' },
            { value: 'construccion', en: 'Construction', es: 'Construcción' },
            { value: 'operacion', en: 'Operation', es: 'Operación' },
          ],
        },
        {
          key: 'diversidad_ruta_internacional', type: 'select',
          label: { en: 'International route diversity from existing chokepoints/corridors', es: 'Diversidad de ruta internacional respecto a corredores/cuellos de botella existentes' },
          options: [
            { value: 'diversidad_alta', en: 'High — avoids existing chokepoints/corridors', es: 'Alta — evita cuellos de botella/corredores existentes' },
            { value: 'diversidad_parcial', en: 'Partial — shares part of the route with existing systems', es: 'Parcial — comparte parte de la ruta con sistemas existentes' },
            { value: 'punto_unico_falla', en: 'Concentrated on an existing single point of failure', es: 'Concentrada sobre un punto único de falla existente' },
          ],
        },
        {
          key: 'unidades_ramificacion', type: 'select',
          label: { en: 'Branching units planned for future connectivity to underserved areas', es: 'Unidades de ramificación (branching units) previstas para futura conectividad a zonas desatendidas' },
          options: [
            { value: 'si_diseño', en: 'Yes, included in the initial design', es: 'Sí, incluidas en el diseño inicial' },
            { value: 'en_evaluacion', en: 'Under evaluation', es: 'En evaluación' },
            { value: 'no', en: 'Not planned', es: 'No previstas' },
          ],
        },
      ],
    },
    {
      key: 'landing_station',
      title: { en: 'B.2 Landing station', es: 'B.2 Estación de aterrizaje (landing station)' },
      fields: [
        {
          key: 'ubicacion_estacion', type: 'text',
          label: { en: 'Station location', es: 'Ubicación de la estación' },
        },
        {
          key: 'estacion_existente_nueva', type: 'select',
          label: { en: 'Existing or new station', es: 'Estación existente o nueva' },
          options: [
            { value: 'existente', en: 'Existing', es: 'Existente' },
            { value: 'nueva', en: 'New', es: 'Nueva' },
          ],
        },
        {
          key: 'propietario_operador_estacion', type: 'text',
          label: { en: 'Station owner / operator', es: 'Propietario / operador de la estación' },
        },
        {
          key: 'redundancia_bmh', type: 'select',
          label: { en: 'Beach manhole (BMH) redundancy', es: 'Redundancia del punto de anclaje en tierra (BMH)' },
          options: [
            { value: 'si', en: 'Yes', es: 'Sí' },
            { value: 'parcial', en: 'Partial', es: 'Parcial' },
            { value: 'no', en: 'No', es: 'No' },
          ],
        },
        {
          key: 'backhaul_terrestre', type: 'text',
          label: { en: 'Available terrestrial backhaul', es: 'Backhaul terrestre disponible' },
          placeholder: { en: 'Terrestrial fiber routes connecting the landing station to the rest of the national network', es: 'Rutas de fibra terrestre que conectan la landing station con el resto de la red nacional' },
        },
        {
          key: 'diversidad_ruta_terrestre', type: 'select',
          label: { en: 'Terrestrial route diversity', es: 'Diversidad de ruta terrestre' },
          options: [
            { value: 'diversidad_asegurada', en: 'Route diversity secured', es: 'Diversidad de ruta asegurada' },
            { value: 'punto_unico_falla', en: 'Single point of failure between beach and data center/POP', es: 'Punto único de falla entre la playa y el data center/POP' },
          ],
        },
        {
          key: 'seguridad_cls', type: 'select',
          label: { en: 'CLS physical security / critical infrastructure status', es: 'Seguridad física de la CLS / estatus de infraestructura crítica' },
          options: [
            { value: 'infraestructura_critica_designada', en: 'Designated critical infrastructure (guarded access, controlled entry)', es: 'Designada infraestructura crítica (acceso custodiado, entrada controlada)' },
            { value: 'medidas_reforzadas', en: 'Reinforced measures, not formally designated', es: 'Medidas reforzadas, sin designación formal' },
            { value: 'basico', en: 'Basic perimeter security only', es: 'Seguridad perimetral básica únicamente' },
            { value: 'no_definido', en: 'Not yet defined', es: 'Aún no definido' },
          ],
        },
        {
          key: 'monitoreo_das', type: 'select',
          label: { en: 'Real-time fronthaul monitoring (DAS/DFOS fiber sensing)', es: 'Monitoreo en tiempo real del fronthaul (sensado de fibra DAS/DFOS)' },
          options: [
            { value: 'implementado', en: 'Implemented', es: 'Implementado' },
            { value: 'planificado', en: 'Planned', es: 'Planificado' },
            { value: 'no_previsto', en: 'Not planned', es: 'No previsto' },
          ],
        },
      ],
    },
    {
      key: 'maintenance',
      title: { en: 'B.3 Maintenance & repair', es: 'B.3 Mantenimiento y reparación' },
      fields: [
        {
          key: 'acuerdo_mantenimiento', type: 'text',
          label: { en: 'Maintenance Zone Agreement', es: 'Acuerdo de mantenimiento (Maintenance Zone Agreement)' },
          placeholder: { en: 'e.g. South Atlantic maintenance zone / applicable repair consortium', es: 'ej. Zona de mantenimiento del Atlántico Sur / consorcio de reparación aplicable' },
        },
        {
          key: 'buque_reparacion', type: 'text',
          label: { en: 'Assigned repair vessel', es: 'Buque de reparación asignado' },
        },
        {
          key: 'mttr_estimado', type: 'text',
          label: { en: 'Estimated repair time (MTTR)', es: 'Tiempo estimado de reparación (MTTR)' },
        },
        {
          key: 'deposito_cable_repuesto', type: 'select',
          label: { en: 'Spare cable depot in Argentina', es: 'Depósito de cable de repuesto en Argentina' },
          options: [
            { value: 'si', en: 'Yes', es: 'Sí' },
            { value: 'no', en: 'No', es: 'No' },
            { value: 'en_gestion', en: 'Being arranged', es: 'En gestión' },
          ],
        },
        {
          key: 'respaldo_satelital_microondas', type: 'select',
          label: { en: 'Failover protocol to satellite/microwave during extended outages', es: 'Protocolo de respaldo satelital/microondas ante cortes prolongados' },
          options: [
            { value: 'si', en: 'Defined and agreed with operators', es: 'Definido y acordado con operadores' },
            { value: 'en_desarrollo', en: 'Under development', es: 'En desarrollo' },
            { value: 'no', en: 'Not defined', es: 'No definido' },
          ],
        },
      ],
    },
    {
      key: 'readiness_dimensions',
      title: { en: 'C. Investment Readiness Index™ — evidence by dimension', es: 'C. Investment Readiness Index™ — evidencia por dimensión' },
      fields: [
        {
          key: 'irr_regulatorio', type: 'textarea',
          label: { en: '1. Legal & regulatory clarity', es: '1. Claridad legal y regulatoria' },
          placeholder: { en: 'ENACOM license status, landing/cabotage authorization, applicable Universal Service framework, known regulatory restrictions', es: 'Estado de la licencia de ENACOM, autorización de landing/cabotaje, marco de servicio universal aplicable, restricciones regulatorias identificadas' },
        },
        {
          key: 'irr_diseno_tecnico', type: 'textarea',
          label: { en: '2. Technical design maturity', es: '2. Madurez del diseño técnico' },
          placeholder: { en: 'Marine route survey, seabed environmental study, detailed engineering, preselected system vendor, multi-hazard route assessment (climate, seismic, geopolitical, human activity)', es: 'Estudio de ruta marina, estudio ambiental de fondo marino, ingeniería de detalle disponible, proveedor de sistema submarino preseleccionado, evaluación multiamenaza de la ruta (clima, sísmica, geopolítica, actividad humana)' },
        },
        {
          key: 'irr_modelo_financiero', type: 'textarea',
          label: { en: '3. Financial model robustness', es: '3. Robustez del modelo financiero' },
          placeholder: { en: 'CAPEX/OPEX, revenue model (IRU, colocation, dark fiber leasing), payback horizon / estimated IRR', es: 'CAPEX/OPEX, modelo de ingresos (IRU, colocation, leasing de fibra oscura), horizonte de repago / TIR estimada' },
        },
        {
          key: 'irr_capacidad_sponsor', type: 'textarea',
          label: { en: '4. Sponsor capacity', es: '4. Capacidad del sponsor' },
          placeholder: { en: 'Prior sponsor experience, in-house technical execution capacity, sponsor financial strength', es: 'Experiencia previa del sponsor, capacidad de ejecución técnica propia, solidez financiera del sponsor' },
        },
        {
          key: 'irr_demanda_mercado', type: 'textarea',
          label: { en: '5. Market demand evidence', es: '5. Evidencia de demanda de mercado' },
          placeholder: { en: 'Operators/ISPs with confirmed interest, signed or negotiating IRU contracts, 5–10 year capacity demand projection', es: 'Operadores/ISPs con interés confirmado, contratos IRU firmados o en negociación, proyección de demanda de capacidad (5–10 años)' },
        },
        {
          key: 'irr_ambiental_social', type: 'textarea',
          label: { en: '6. Environmental & social readiness', es: '6. Preparación ambiental y social' },
          placeholder: { en: 'Environmental impact assessment status, consultation with coastal/fishing communities, facility environmental management plan, climate/seismic/tsunami hazard vulnerability assessment for the route and landing site', es: 'Estado de la evaluación de impacto ambiental, consulta con comunidades costeras/pesca, plan de gestión ambiental de la instalación, evaluación de vulnerabilidad ante riesgos climáticos/sísmicos/tsunami de la ruta y del punto de aterrizaje' },
        },
        {
          key: 'irr_riesgos', type: 'textarea',
          label: { en: '7. Risk mitigation coverage', es: '7. Cobertura de mitigación de riesgos' },
          placeholder: { en: 'Critical risks identified and mitigation plan per risk (see the 10-category risk matrix in the notes below)', es: 'Riesgos críticos identificados y plan de mitigación por riesgo (ver matriz de riesgos de 10 categorías en las notas más abajo)' },
        },
        {
          key: 'irr_gobernanza', type: 'textarea',
          label: { en: '8. Governance & reporting', es: '8. Gobernanza y reporting' },
          placeholder: { en: 'Steering committee constituted, designated PMO, reporting mechanism to ENACOM/stakeholders', es: 'Comité directivo/steering committee constituido, PMO designada, mecanismo de reporte a ENACOM/stakeholders' },
        },
      ],
    },
    {
      key: 'regulatory',
      title: { en: 'D. Regulatory framework & permits (Argentina)', es: 'D. Marco regulatorio y permisos (Argentina)' },
      fields: [
        {
          key: 'licencia_enacom', type: 'select',
          label: { en: 'ENACOM Telecommunications Services license', es: 'Licencia de Servicios de Telecomunicaciones (ENACOM)' },
          options: [
            { value: 'vigente', en: 'In force', es: 'Vigente' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
            { value: 'no_iniciada', en: 'Not started', es: 'No iniciada' },
          ],
        },
        {
          key: 'autorizacion_espectro', type: 'select',
          label: { en: 'Spectrum / associated resource authorization', es: 'Autorización de uso de espectro / recursos asociados' },
          options: [
            { value: 'si', en: 'Applicable, secured', es: 'Aplica, asegurada' },
            { value: 'en_tramite', en: 'Applicable, in progress', es: 'Aplica, en trámite' },
            { value: 'no_aplica', en: 'Not applicable', es: 'No aplica' },
          ],
        },
        {
          key: 'permiso_cruce_maritimo', type: 'select',
          label: { en: 'Maritime crossing / cabotage permit (Prefectura Naval, Armada)', es: 'Permiso de cruce de espacios marítimos / cabotaje (Prefectura Naval, Armada)' },
          options: [
            { value: 'vigente', en: 'In force', es: 'Vigente' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
            { value: 'no_iniciado', en: 'Not started', es: 'No iniciado' },
          ],
        },
        {
          key: 'intervencion_cancilleria', type: 'select',
          label: { en: 'Foreign Ministry (Cancillería) involvement', es: 'Intervención de Cancillería' },
          options: [
            { value: 'requerida_en_gestion', en: 'Required, in progress', es: 'Requerida, en gestión' },
            { value: 'requerida_completa', en: 'Required, completed', es: 'Requerida, completa' },
            { value: 'no_requerida', en: 'Not required (no international boundary/EEZ crossing)', es: 'No requerida (no cruza límites internacionales ni ZEE)' },
          ],
        },
        {
          key: 'permisos_ambientales_provinciales', type: 'text',
          label: { en: 'Provincial/municipal environmental permits', es: 'Permisos ambientales provinciales/municipales' },
          placeholder: { en: 'Province and municipality of the landing point', es: 'Provincia y municipio del punto de aterrizaje' },
        },
        {
          key: 'servidumbres_paso_terrestre', type: 'select',
          label: { en: 'Terrestrial easements / rights of way (beach to POP/data center)', es: 'Servidumbres y permisos de paso terrestres (playa al POP/datacenter)' },
          options: [
            { value: 'aseguradas', en: 'Secured', es: 'Aseguradas' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
            { value: 'no_iniciadas', en: 'Not started', es: 'No iniciadas' },
          ],
        },
        {
          key: 'otras_autorizaciones', type: 'text',
          label: { en: 'Other sectoral authorizations', es: 'Otras autorizaciones sectoriales' },
          placeholder: { en: 'Defense, Ports, Customs (cable/submarine equipment import)', es: 'Defensa, Puertos, Aduana (importación de cable y equipos submarinos)' },
        },
        {
          key: 'punto_focal_unico', type: 'text',
          label: { en: 'Single point of contact (SPOC) for this project', es: 'Punto focal único (SPOC) para este proyecto' },
          placeholder: { en: 'Designated agency/coordinator centralizing permitting across ENACOM, provinces, Prefectura, Cancillería, etc.', es: 'Agencia/coordinador designado que centraliza los permisos entre ENACOM, provincias, Prefectura, Cancillería, etc.' },
        },
      ],
    },
    {
      key: 'financing',
      title: { en: 'E. Financial structuring & financing', es: 'E. Estructuración financiera y financiamiento' },
      fields: [
        {
          key: 'capex_total', type: 'text',
          label: { en: 'Total CAPEX (USD)', es: 'CAPEX total (USD)' },
        },
        {
          key: 'moneda_ingresos', type: 'text',
          label: { en: 'Currency of projected revenue', es: 'Moneda de los ingresos proyectados' },
        },
        {
          key: 'fuente_financiamiento_buscada', type: 'select',
          label: { en: 'Financing sources under evaluation', es: 'Fuentes de financiamiento en evaluación' },
          options: [
            { value: 'multilateral', en: 'Multilateral (IDB, CAF, World Bank, FONPLATA)', es: 'Multilateral (BID, CAF, Banco Mundial, FONPLATA)' },
            { value: 'infra_privado', en: 'Private infrastructure funds / project finance', es: 'Fondos de infraestructura privados / project finance' },
            { value: 'eca_vendor', en: 'ECA / vendor financing', es: 'ECA / vendor financing' },
            { value: 'ustda_dfc', en: 'USTDA / DFC', es: 'USTDA / DFC' },
            { value: 'blended_ppp', en: 'Blended finance / PPP', es: 'Financiamiento mixto (blended finance) / PPP' },
            { value: 'capital_propio', en: 'Own capital', es: 'Capital propio' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
        {
          key: 'garantia_soberana', type: 'select',
          label: { en: 'Sovereign guarantee available', es: 'Garantía soberana disponible' },
          options: [
            { value: 'si', en: 'Yes', es: 'Sí' },
            { value: 'no', en: 'No', es: 'No' },
          ],
        },
        {
          key: 'compromiso_arrendatario_ancla', type: 'select',
          label: { en: 'Anchor-tenancy commitment (government/public-institution minimum capacity purchase)', es: 'Compromiso de arrendatario ancla (compra de capacidad mínima por el Estado/entidad pública)' },
          options: [
            { value: 'comprometido', en: 'Committed', es: 'Comprometido' },
            { value: 'en_negociacion', en: 'Under negotiation', es: 'En negociación' },
            { value: 'no_aplica', en: 'Not applicable / not pursued', es: 'No aplica / no se busca' },
          ],
        },
        {
          key: 'cobertura_seguro', type: 'select',
          label: { en: 'Insurance mechanism', es: 'Mecanismo de seguro' },
          options: [
            { value: 'tradicional', en: 'Traditional indemnity insurance', es: 'Seguro tradicional de indemnización' },
            { value: 'parametrico', en: 'Parametric insurance / catastrophe bond', es: 'Seguro paramétrico / bono catastrófico' },
            { value: 'en_evaluacion', en: 'Under evaluation', es: 'En evaluación' },
            { value: 'sin_cobertura', en: 'No coverage identified yet', es: 'Sin cobertura identificada aún' },
          ],
        },
        {
          key: 'contratos_ingresos_firmados', type: 'text',
          label: { en: 'Signed revenue contracts (IRU/colocation)', es: 'Contratos de ingresos ya firmados (IRU/colocation)' },
          placeholder: { en: 'As cash-flow backing for project finance', es: 'Como respaldo de flujo de caja para project finance' },
        },
        {
          key: 'estado_due_diligence', type: 'select',
          label: { en: 'Technical due diligence status', es: 'Estado de la due diligence técnica' },
          options: [
            { value: 'no_iniciada', en: 'Not started', es: 'No iniciada' },
            { value: 'en_curso', en: 'In progress', es: 'En curso' },
            { value: 'completa', en: 'Completed', es: 'Completa' },
          ],
        },
      ],
    },
    {
      key: 'governance',
      title: { en: 'G. Governance & contacts', es: 'G. Gobernanza y contactos' },
      fields: [
        {
          key: 'comite_directivo', type: 'text',
          label: { en: 'Steering committee', es: 'Comité directivo (Steering Committee)' },
        },
        {
          key: 'pmo_responsable', type: 'text',
          label: { en: 'Project Management Office (PMO) — lead', es: 'Project Management Office (PMO) — responsable' },
        },
        {
          key: 'comite_tecnico_responsable', type: 'text',
          label: { en: 'Technical committee — lead', es: 'Comité técnico — responsable' },
        },
        {
          key: 'contacto_enacom', type: 'text',
          label: { en: 'ENACOM follow-up contact', es: 'Contacto ENACOM de seguimiento' },
        },
        {
          key: 'contacto_tecnico_sponsor', type: 'text',
          label: { en: 'Sponsor technical contact', es: 'Contacto técnico del sponsor' },
        },
        {
          key: 'contacto_legal_regulatorio', type: 'text',
          label: { en: 'Legal / regulatory contact', es: 'Contacto legal / regulatorio' },
        },
      ],
    },
  ],
  // Covers Bloque F (10-category risk matrix: strategic, regulatory,
  // technical, financial, market, counterparty/vendor, operational,
  // environmental & social, governance, climate), Bloque H's supporting
  // documentation checklist, and — where applicable (capacity expansions,
  // interconnections with an existing landing) — decommissioning/redundancy
  // notes for any legacy cable being replaced (IAB Rec. 12: notice period,
  // regional impact assessment, potential repurposing as backup
  // infrastructure) — narrative/checklist content, better suited here than
  // as dozens more structured inputs.
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (10-category risk matrix, supporting documentation checklist, decommissioning/redundancy notes for any legacy cable being replaced, etc.)', es: 'Notas adicionales (matriz de riesgos de 10 categorías, checklist de documentación de respaldo, notas de desmantelamiento/redundancia de cables legados que se reemplacen, etc.)' },
  },
};

/* Based on ENACOM's "RED MAYORISTA NEUTRAL" Program — Resolución
   RESOL-2025-951-APN-ENACOM#JGM (4 de julio de 2025) and its Anexo I
   (IF-2025-71421520-APN-DNFYD#ENACOM) — financed by the FONDO DEL SERVICIO
   UNIVERSAL (up to ARS 60,000,000,000) within the PLAN NACIONAL DE
   INFRAESTRUCTURA CRÍTICA DE COMUNICACIONES (Res. 359/25). Sections map to
   the program's own structure: eligible recipients (Sec. III — SCM/STeFI/
   SVA-SVA-INT licensees with ≥2 years of service), scope (Sec. IV — neutral
   wholesale network and/or 5G access in underserved areas; retail-only
   networks are explicitly excluded), the 6 eligible funding destinations
   (Sec. V.1-6), technical design and open-access/interconnection —
   explicitly the two most heavily weighted evaluation criteria (Sec. VII.3
   and VII.4: topology/dimensioning/scalability, and open multi-operator
   access with REFEFO interconnection and RAN sharing) — eligible expense
   categories (Sec. VI.1.4 a-f) and resource-allocation modalities (Sec.
   VI.2), and the audit/monitoring obligations every financing line must
   carry (Sec. IX-X). */
const WHOLESALE_NEUTRAL_NETWORK_TEMPLATE = {
  title: { en: 'Neutral Wholesale Network project template', es: 'Template de proyecto de Red Mayorista Neutral' },
  intro: {
    en: 'Based on ENACOM’s “Red Mayorista Neutral” Program (Resolution 951/2025 and its Annex I) — for projects deploying open-access wholesale network infrastructure and/or 5G access in underserved or infrastructure-limited areas, financed by the Universal Service Fund. Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en el Programa “Red Mayorista Neutral” de ENACOM (Resolución 951/2025 y su Anexo I) — para proyectos de despliegue de infraestructura de red mayorista de acceso abierto y/o acceso 5G en zonas desatendidas o con infraestructura limitada, financiados por el Fondo del Servicio Universal. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Applicant & eligibility', es: '0. Datos generales del proponente y elegibilidad' },
      fields: [
        {
          key: 'licenciatario_razon_social', type: 'text',
          label: { en: 'Licensee name / corporate name', es: 'Nombre del licenciatario / razón social' },
        },
        {
          key: 'registro_tic', type: 'select',
          label: { en: 'Enabling TIC registration', es: 'Registro TIC habilitante' },
          options: [
            { value: 'scm', en: 'Mobile Communications Services (SCM)', es: 'Servicios de Comunicaciones Móviles (SCM)' },
            { value: 'stefi', en: 'Reliable & Intelligent Telecommunications Services (STeFI)', es: 'Servicio de Telecomunicaciones Fiables e Inteligentes (STeFI)' },
            { value: 'sva_sva_int', en: 'Value-Added Internet Access Service (SVA/SVA-INT)', es: 'Servicio de Valor Agregado de acceso a Internet (SVA/SVA-INT)' },
            { value: 'combinacion', en: 'Combination of the above', es: 'Combinación de los anteriores' },
          ],
        },
        {
          key: 'antiguedad_prestacion_servicio', type: 'select',
          label: { en: 'Track record providing the service', es: 'Antigüedad de prestación efectiva del servicio' },
          options: [
            { value: 'dos_anios_o_mas', en: '2 years or more (eligibility requirement)', es: '2 años o más (requisito de elegibilidad)' },
            { value: 'menos_dos_anios', en: 'Less than 2 years', es: 'Menos de 2 años' },
          ],
        },
        {
          key: 'tipo_operador', type: 'select',
          label: { en: 'Operator type', es: 'Tipo de operador' },
          options: [
            { value: 'operador_grande', en: 'Large operator', es: 'Operador grande' },
            { value: 'pyme_regional', en: 'Regional SME operator', es: 'Operador PyME regional' },
            { value: 'cooperativa', en: 'Cooperative', es: 'Cooperativa' },
            { value: 'mixto', en: 'Mixed / consortium', es: 'Mixto / consorcio' },
          ],
        },
        {
          key: 'monto_total_solicitado', type: 'text',
          label: { en: 'Total amount requested & currency', es: 'Monto total solicitado y moneda' },
        },
      ],
    },
    {
      key: 'scope',
      title: { en: '1. Scope & implementation modality', es: '1. Alcance y modalidad de implementación' },
      fields: [
        {
          key: 'rubro_financiamiento', type: 'select',
          label: { en: 'Funding destination (Program Sec. V)', es: 'Destino del financiamiento (Programa, Sec. V)' },
          options: [
            { value: 'refefo_transporte_mayorista', en: 'ReFeFO / other wholesale transport network deployment or expansion', es: 'Despliegue/extensión/ampliación de la ReFeFO u otras redes de transporte mayorista' },
            { value: 'nodos_core_red', en: 'Network node & core equipment installation/modernization', es: 'Instalación/modernización de nodos de red y equipamiento de core' },
            { value: 'equipamiento_ran_sharing', en: 'Active/passive equipment for 5G traffic distribution (RAN sharing)', es: 'Equipamiento activo/pasivo para distribución de tráfico 5G (RAN sharing)' },
            { value: 'acceso_fijo_5g_cpe', en: 'Fixed access via 5G — core, CPE, receiving antennas', es: 'Acceso fijo mediante 5G — core, CPE, antenas receptoras' },
            { value: 'distribucion_ultima_milla', en: 'Distribution boxes & network termination points for last mile (NID, CTO, splitters)', es: 'Cajas de distribución y puntos de terminación de red para última milla (NID, CTO, splitters)' },
            { value: 'interconexion_pymes_cooperativas', en: 'Interconnection of SME/cooperative networks to wholesale trunk networks', es: 'Interconexión de redes de PyMEs/cooperativas a redes mayoristas troncales' },
          ],
        },
        {
          key: 'modalidad_implementacion', type: 'select',
          label: { en: 'Implementation modality', es: 'Modalidad de implementación' },
          options: [
            { value: 'convocatoria_publica', en: 'Public competitive call', es: 'Convocatoria pública y competitiva' },
            { value: 'proyecto_especifico_enacom', en: 'ENACOM-designed specific project (strategic/urgent need)', es: 'Proyecto específico diseñado por ENACOM (necesidad estratégica/urgente)' },
          ],
        },
        {
          key: 'linea_financiamiento', type: 'text',
          label: { en: 'Specific financing line (if known)', es: 'Línea de financiamiento específica (si se conoce)' },
        },
        {
          key: 'tecnologia_objetivo', type: 'select',
          label: { en: 'Target technology', es: 'Tecnología objetivo' },
          options: [
            { value: '5g_movil', en: '5G mobile', es: '5G móvil' },
            { value: 'fwa_acceso_fijo', en: 'Fixed Wireless Access (FWA)', es: 'Acceso Inalámbrico Fijo (FWA)' },
            { value: 'fibra_ultima_milla', en: 'Last-mile fiber', es: 'Fibra de última milla' },
            { value: 'mixto', en: 'Mixed', es: 'Mixto' },
          ],
        },
      ],
    },
    {
      key: 'deployment_zone',
      title: { en: '2. Deployment zone', es: '2. Zona de despliegue' },
      fields: [
        {
          key: 'provincias_localidades', type: 'text',
          label: { en: 'Province(s) / locality(ies)', es: 'Provincia(s) / localidad(es)' },
        },
        {
          key: 'tipo_zona', type: 'select',
          label: { en: 'Zone type', es: 'Tipo de zona' },
          options: [
            { value: 'desatendida_sin_cobertura', en: 'Underserved, no coverage', es: 'Desatendida, sin cobertura' },
            { value: 'infraestructura_limitada', en: 'Limited infrastructure', es: 'Infraestructura limitada' },
            { value: 'baja_densidad', en: 'Low population density', es: 'Baja densidad poblacional' },
            { value: 'saturacion_red_existente', en: 'Existing network saturation', es: 'Saturación de red existente' },
          ],
        },
        {
          key: 'situacion_cobertura_actual', type: 'textarea',
          label: { en: 'Current coverage situation', es: 'Situación de cobertura actual' },
        },
        {
          key: 'poblacion_beneficiada_estimada', type: 'text',
          label: { en: 'Estimated population benefited', es: 'Población beneficiada estimada' },
        },
      ],
    },
    {
      key: 'technical_design',
      title: { en: '3. Technical network design', es: '3. Diseño técnico de red' },
      fields: [
        {
          key: 'topologia_dimensionamiento', type: 'textarea',
          label: { en: 'Topology, dimensioning & scalability', es: 'Topología, dimensionamiento y escalabilidad' },
          placeholder: { en: 'Explicitly weighed under evaluation criterion VII.3 (technical viability & operational sustainability)', es: 'Ponderado explícitamente en el criterio de evaluación VII.3 (viabilidad técnica y sostenibilidad operativa)' },
        },
        {
          key: 'tecnologia_acceso_detalle', type: 'text',
          label: { en: 'Access technology detail', es: 'Detalle de tecnología de acceso' },
          placeholder: { en: 'e.g. 5G NR bands, FWA standard', es: 'ej. bandas 5G NR, estándar FWA' },
        },
        {
          key: 'interconexion_refefo', type: 'select',
          label: { en: 'Interconnection with REFEFO', es: 'Interconexión con la REFEFO' },
          options: [
            { value: 'conectado', en: 'Connected / secured', es: 'Conectado / asegurada' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
            { value: 'no_aplica', en: 'Not applicable', es: 'No aplica' },
          ],
        },
        {
          key: 'esquema_comparticion', type: 'select',
          label: { en: 'Network sharing scheme', es: 'Esquema de compartición de red' },
          options: [
            { value: 'ran_sharing_activo', en: 'Active RAN sharing', es: 'RAN sharing activo' },
            { value: 'ran_sharing_pasivo', en: 'Passive RAN sharing', es: 'RAN sharing pasivo' },
            { value: 'sin_comparticion', en: 'No sharing scheme', es: 'Sin esquema de compartición' },
          ],
        },
        {
          key: 'equipamiento_core', type: 'textarea',
          label: { en: 'Core network equipment', es: 'Equipamiento de core de red' },
          placeholder: { en: 'Aggregation switches, edge routers, servers, virtualization software, network controllers', es: 'Switches de agregación, routers de borde, servidores, software de virtualización, controladores de red' },
        },
        {
          key: 'equipamiento_acceso_5g', type: 'textarea',
          label: { en: '5G access equipment', es: 'Equipamiento de acceso 5G' },
          placeholder: { en: 'Antennas, radios, baseband units, power', es: 'Antenas, radios, unidades de banda base, energía' },
        },
        {
          key: 'equipamiento_distribucion_ultima_milla', type: 'textarea',
          label: { en: 'Last-mile distribution equipment', es: 'Equipamiento de distribución de última milla' },
          placeholder: { en: 'NID, CTO, optical splitters, CPE terminals', es: 'NID, CTO, splitters ópticos, terminales CPE' },
        },
      ],
    },
    {
      key: 'open_access',
      title: { en: '4. Neutrality & open access', es: '4. Neutralidad y acceso abierto' },
      fields: [
        {
          key: 'modelo_neutralidad', type: 'select',
          label: { en: 'Neutrality model', es: 'Modelo de neutralidad' },
          options: [
            { value: 'acceso_abierto_multioperador', en: 'Open, multi-operator access (priority criterion)', es: 'Acceso abierto multioperador (criterio prioritario)' },
            { value: 'acceso_restringido_justificar', en: 'Restricted access (justify)', es: 'Acceso restringido (justificar)' },
          ],
        },
        {
          key: 'operadores_interesados_interconexion', type: 'textarea',
          label: { en: 'Operators/cooperatives/SMEs interested in interconnecting', es: 'Operadores/cooperativas/PyMEs interesados en interconectarse' },
        },
        {
          key: 'mecanismo_asignacion_capacidad', type: 'textarea',
          label: { en: 'Non-discriminatory capacity allocation mechanism', es: 'Mecanismo de asignación de capacidad no discriminatorio' },
        },
      ],
    },
    {
      key: 'beneficiaries',
      title: { en: '5. Beneficiaries', es: '5. Beneficiarios' },
      fields: [
        {
          key: 'cantidad_operadores_beneficiados', type: 'text',
          label: { en: 'Number of operators benefited', es: 'Cantidad de operadores beneficiados' },
        },
        {
          key: 'cantidad_usuarios_finales_beneficiados', type: 'text',
          label: { en: 'Number of end users benefited', es: 'Cantidad de usuarios finales beneficiados' },
        },
        {
          key: 'sectores_beneficiados', type: 'select',
          label: { en: 'Beneficiary sectors', es: 'Sectores beneficiados' },
          options: [
            { value: 'hogares', en: 'Households', es: 'Hogares' },
            { value: 'educacion', en: 'Education', es: 'Educación' },
            { value: 'salud', en: 'Health', es: 'Salud' },
            { value: 'seguridad_publica', en: 'Public safety', es: 'Seguridad pública' },
            { value: 'actividad_productiva', en: 'Productive activity', es: 'Actividad productiva' },
            { value: 'organismos_publicos', en: 'Public agencies', es: 'Organismos públicos' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
      ],
    },
    {
      key: 'financing',
      title: { en: '6. Eligible expenses & financing', es: '6. Gastos elegibles y financiamiento' },
      fields: [
        {
          key: 'rubros_elegibles', type: 'textarea',
          label: { en: 'Eligible expense items', es: 'Rubros elegibles' },
          placeholder: { en: 'Network equipment; distribution materials/CTOs/splitters; CPE/FWA devices; transport interconnection equipment (incl. REFEFO); minor civil works; engineering/design/supervision/testing', es: 'Equipamiento de red; materiales/CTOs/splitters de distribución; equipos CPE/FWA; equipamiento de interconexión a transporte (incl. REFEFO); obras civiles menores; ingeniería/diseño/supervisión/pruebas' },
        },
        {
          key: 'porcentaje_financiamiento_solicitado', type: 'text',
          label: { en: 'Financing percentage requested', es: 'Porcentaje de financiamiento solicitado' },
        },
        {
          key: 'modalidad_asignacion_recursos', type: 'select',
          label: { en: 'Resource allocation modality', es: 'Modalidad de asignación de recursos' },
          options: [
            { value: 'financiamiento_total_parcial', en: 'Total/partial financing of eligible expenses', es: 'Financiamiento total/parcial de gastos elegibles' },
            { value: 'provision_directa_equipamiento', en: 'Direct equipment/software provision by ENACOM', es: 'Provisión directa de equipamiento/software por ENACOM' },
            { value: 'credito_tasa_subsidiada', en: 'Subsidized-rate credit', es: 'Crédito a tasa subsidiada' },
            { value: 'combinacion', en: 'Combination', es: 'Combinación' },
          ],
        },
        {
          key: 'plazos_ejecucion', type: 'text',
          label: { en: 'Execution timeline', es: 'Plazos de ejecución' },
        },
        {
          key: 'cronograma_desembolsos', type: 'text',
          label: { en: 'Disbursement schedule', es: 'Cronograma de desembolsos' },
        },
      ],
    },
    {
      key: 'operation',
      title: { en: '7. Operation & sustainability', es: '7. Operación y sostenibilidad' },
      fields: [
        {
          key: 'plan_operacion_mantenimiento', type: 'textarea',
          label: { en: 'Operation & maintenance plan', es: 'Plan de operación y mantenimiento' },
        },
        {
          key: 'experiencia_tecnica_destinatario', type: 'textarea',
          label: { en: 'Technical experience of recipient / associated vendors', es: 'Experiencia y capacidad técnica del destinatario y/o proveedores asociados' },
        },
        {
          key: 'complementariedad_otros_programas', type: 'text',
          label: { en: 'Complementarity with other Plan Nacional programs', es: 'Complementariedad con otros programas del Plan Nacional' },
        },
      ],
    },
    {
      key: 'regulatory',
      title: { en: '8. Regulatory framework', es: '8. Marco regulatorio' },
      fields: [
        {
          key: 'licencia_tic_vigente', type: 'select',
          label: { en: 'TIC license status', es: 'Licencia TIC' },
          options: [
            { value: 'vigente', en: 'In force', es: 'Vigente' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
            { value: 'no_aplica', en: 'Not applicable', es: 'No aplica' },
          ],
        },
        {
          key: 'registro_scm_stefi_sva_vigente', type: 'select',
          label: { en: 'SCM/STeFI/SVA registration status', es: 'Registro SCM/STeFI/SVA' },
          options: [
            { value: 'vigente', en: 'In force', es: 'Vigente' },
            { value: 'en_tramite', en: 'In progress', es: 'En trámite' },
          ],
        },
        {
          key: 'autorizacion_espectro', type: 'select',
          label: { en: 'Spectrum authorization', es: 'Autorización de espectro' },
          options: [
            { value: 'aplica_asegurada', en: 'Applicable, secured', es: 'Aplica, asegurada' },
            { value: 'aplica_en_tramite', en: 'Applicable, in progress', es: 'Aplica, en trámite' },
            { value: 'no_aplica', en: 'Not applicable', es: 'No aplica' },
          ],
        },
      ],
    },
    {
      key: 'monitoring',
      title: { en: '9. Monitoring & audit', es: '9. Seguimiento, control y auditoría' },
      fields: [
        {
          key: 'indicadores_seguimiento_propuestos', type: 'textarea',
          label: { en: 'Proposed monitoring indicators', es: 'Indicadores de seguimiento propuestos' },
        },
        {
          key: 'mecanismos_auditoria_previstos', type: 'textarea',
          label: { en: 'Planned audit mechanisms', es: 'Mecanismos de auditoría previstos' },
          placeholder: { en: 'Documentary verification, independent certifications, etc. (Program Sec. X)', es: 'Verificación documental, certificaciones independientes, etc. (Programa, Sec. X)' },
        },
      ],
    },
  ],
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (scoring methodology specifics, additional eligibility conditions, complementary equipment/software requested from ENACOM, etc.)', es: 'Notas adicionales (particularidades de la metodología de scoring, condiciones de elegibilidad adicionales, equipamiento/software complementario solicitado a ENACOM, etc.)' },
  },
};

const EARLY_WARNING_TEMPLATE = {
  title: { en: 'Early Warning System project template', es: 'Template de proyecto de Sistema de Alerta Temprana' },
  intro: {
    en: 'For public-interest projects that develop and/or deploy a broadcast-based early warning solution — alerting the population to risk events (earthquake, severe storm, hurricane/cyclone, tsunami, flood, and similar) via Cell Broadcast, radio/TV interruption, sirens or app notifications. Fill in whatever you know; anything left blank is simply omitted from the generated description. The step-by-step administrative/regulatory procedures this kind of project needs (coordinating with the meteorological/seismological service, mobile operators, civil defense, broadcasters, etc.) are tracked separately, in the project\'s "Roadmaps" section, once the project exists.',
    es: 'Para proyectos de interés público que desarrollan y/o implementan una solución de alerta temprana vía broadcast — que avisa a la población ante situaciones de riesgo (sismo, tormenta severa, huracán/ciclón, tsunami, inundación y similares) mediante Cell Broadcast, interrupción de radio/TV, sirenas o notificaciones de app. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada. Las hojas de ruta administrativas/regulatorias paso a paso que este tipo de proyecto requiere (coordinar con el servicio meteorológico/sismológico, operadores móviles, defensa civil, radiodifusores, etc.) se trackean por separado, en la sección "Hojas de ruta" del proyecto, una vez que el proyecto existe.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Applicant, project & institutional roles', es: '0. Datos generales del proponente y roles institucionales' },
      fields: [
        {
          key: 'destinatario_presentacion', type: 'select',
          label: { en: 'Presentation addressed to', es: 'Destinatario de la presentación' },
          options: [
            { value: 'enacom', en: 'ENACOM', es: 'ENACOM' },
            { value: 'organismo_multilateral', en: 'Multilateral organization (CAF, IDB, other — specify)', es: 'Organismo multilateral (CAF, BID u otro — especificar)' },
            { value: 'ambos', en: 'Both', es: 'Ambos' },
          ],
        },
        {
          key: 'organismo_ejecutor', type: 'text',
          label: { en: 'Executing agency / counterpart', es: 'Organismo ejecutor / contraparte' },
        },
        {
          key: 'monto_total_solicitado', type: 'text',
          label: { en: 'Total amount requested & currency', es: 'Monto total solicitado y moneda' },
        },
        {
          key: 'roles_institucionales', type: 'textarea',
          label: { en: 'Institutional roles & responsibilities', es: 'Roles y responsabilidades institucionales' },
          placeholder: { en: 'Public/private entities expected to be involved: regulator, meteorological/seismological service, civil defense, mobile operators, broadcasters, and each one\'s proposed role', es: 'Entidades públicas/privadas que se prevé que participen: regulador, servicio meteorológico/sismológico, defensa civil, operadores móviles, radiodifusores, y el rol propuesto de cada una' },
        },
      ],
    },
    {
      key: 'hazard_scope',
      title: { en: '1. Hazard scope & coverage', es: '1. Alcance de riesgos y cobertura' },
      fields: [
        {
          key: 'riesgos_cubiertos', type: 'textarea',
          label: { en: 'Hazard types covered', es: 'Tipos de riesgo cubiertos' },
          placeholder: { en: 'e.g. earthquake, tsunami, severe storm, hurricane/cyclone, flood, volcanic eruption, wildfire, other', es: 'p. ej. sismo, tsunami, tormenta severa, huracán/ciclón, inundación, erupción volcánica, incendio forestal, otros' },
        },
        {
          key: 'zona_geografica_cobertura', type: 'text',
          label: { en: 'Geographic coverage area', es: 'Zona geográfica de cobertura' },
        },
        {
          key: 'poblacion_beneficiada_estimada', type: 'text',
          label: { en: 'Estimated population benefited', es: 'Población beneficiada estimada' },
        },
        {
          key: 'fuente_deteccion_alerta', type: 'select',
          label: { en: 'Hazard detection / trigger source', es: 'Fuente de detección/disparo de la alerta' },
          options: [
            { value: 'servicio_meteorologico', en: 'National meteorological service', es: 'Servicio meteorológico nacional' },
            { value: 'servicio_sismologico', en: 'National seismological institute', es: 'Instituto sismológico nacional' },
            { value: 'defensa_civil', en: 'Civil defense / emergency management', es: 'Defensa civil / gestión de emergencias' },
            { value: 'autoridad_maritima', en: 'Maritime/naval authority (tsunami)', es: 'Autoridad marítima/naval (tsunami)' },
            { value: 'combinacion', en: 'Combination of several sources', es: 'Combinación de varias fuentes' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
      ],
    },
    {
      key: 'dissemination',
      title: { en: '2. Alert dissemination technology & channels', es: '2. Tecnología y canales de difusión de la alerta' },
      fields: [
        {
          key: 'canal_difusion_principal', type: 'select',
          label: { en: 'Primary dissemination channel', es: 'Canal de difusión principal' },
          options: [
            { value: 'cell_broadcast', en: 'Cell Broadcast (SMS-CB / WEA-style)', es: 'Cell Broadcast (SMS-CB / estilo WEA)' },
            { value: 'interrupcion_radio_tv', en: 'Radio/TV interruption (EAS-style)', es: 'Interrupción de radio/TV (estilo EAS)' },
            { value: 'sirenas_altavoces', en: 'Sirens / loudspeakers', es: 'Sirenas / altavoces' },
            { value: 'app_notificaciones', en: 'App / push notifications', es: 'App / notificaciones push' },
            { value: 'combinacion', en: 'Combination of channels', es: 'Combinación de canales' },
          ],
        },
        {
          key: 'estandar_tecnico', type: 'select',
          label: { en: 'Technical standard', es: 'Estándar técnico' },
          options: [
            { value: 'cbs_3gpp', en: '3GPP Cell Broadcast Service (CBS)', es: 'Cell Broadcast Service (CBS) 3GPP' },
            { value: 'cap', en: 'Common Alerting Protocol (CAP)', es: 'Common Alerting Protocol (CAP)' },
            { value: 'propietario_otro', en: 'Proprietary / other', es: 'Propietario / otro' },
          ],
        },
        {
          key: 'operadores_moviles_involucrados', type: 'textarea',
          label: { en: 'Mobile operators expected to participate', es: 'Operadores móviles que se prevé que participen' },
        },
        {
          key: 'cobertura_dispositivos', type: 'select',
          label: { en: 'Device coverage', es: 'Cobertura de dispositivos' },
          options: [
            { value: 'universal', en: 'Universal — all compatible devices, no app needed', es: 'Universal — todos los dispositivos compatibles, sin necesidad de app' },
            { value: 'requiere_app', en: 'Requires app installation', es: 'Requiere instalación de app' },
            { value: 'mixto', en: 'Mixed', es: 'Mixto' },
          ],
        },
        {
          key: 'idiomas_soportados', type: 'text',
          label: { en: 'Languages supported', es: 'Idiomas soportados' },
        },
      ],
    },
    {
      key: 'architecture',
      title: { en: '3. Technical architecture & integration', es: '3. Arquitectura técnica e integración' },
      fields: [
        {
          key: 'arquitectura_propuesta', type: 'textarea',
          label: { en: 'Proposed system architecture', es: 'Arquitectura de sistema propuesta' },
          placeholder: { en: 'Alert origination gateway, Cell Broadcast Center (CBC), integration with each operator\'s Cell Broadcast Entity (CBE), etc.', es: 'Gateway de origen de la alerta, Cell Broadcast Center (CBC), integración con la Cell Broadcast Entity (CBE) de cada operador, etc.' },
        },
        {
          key: 'integracion_sistemas_existentes', type: 'textarea',
          label: { en: 'Integration with existing national alert systems, if any', es: 'Integración con sistemas nacionales de alerta existentes, si los hay' },
        },
        {
          key: 'tiempo_objetivo_difusion', type: 'text',
          label: { en: 'Target dissemination time (trigger to broadcast)', es: 'Tiempo objetivo de difusión (disparo a broadcast)' },
        },
        {
          key: 'redundancia_resiliencia', type: 'textarea',
          label: { en: 'Redundancy & resilience plan', es: 'Plan de redundancia y resiliencia' },
          placeholder: { en: 'Backup power, multiple dissemination paths, failover between origination points', es: 'Energía de respaldo, múltiples vías de difusión, failover entre puntos de origen' },
        },
      ],
    },
    {
      key: 'regulatory',
      title: { en: '4. Regulatory & institutional framework', es: '4. Marco regulatorio e institucional' },
      fields: [
        {
          key: 'marco_normativo_aplicable', type: 'textarea',
          label: { en: 'Applicable regulatory framework', es: 'Marco normativo aplicable' },
          placeholder: { en: 'Spectrum allocation, mandatory operator participation, data protection, etc.', es: 'Asignación de espectro, participación obligatoria de operadores, protección de datos, etc.' },
        },
        {
          key: 'autorizacion_espectro', type: 'select',
          label: { en: 'Spectrum authorization', es: 'Autorización de espectro' },
          options: [
            { value: 'aplica_asegurada', en: 'Applicable, secured', es: 'Aplica, asegurada' },
            { value: 'aplica_en_tramite', en: 'Applicable, in progress', es: 'Aplica, en trámite' },
            { value: 'no_aplica', en: 'Not applicable', es: 'No aplica' },
          ],
        },
        {
          key: 'acuerdos_institucionales_necesarios', type: 'textarea',
          label: { en: 'Institutional agreements needed', es: 'Convenios institucionales necesarios' },
          placeholder: { en: 'Summary here; the step-by-step tracking of each agreement/procedure lives in the project\'s "Roadmaps" section', es: 'Resumen acá; el seguimiento paso a paso de cada convenio/trámite vive en la sección "Hojas de ruta" del proyecto' },
        },
        {
          key: 'responsable_operacion_sistema', type: 'text',
          label: { en: 'Entity responsible for ongoing operation/maintenance', es: 'Entidad responsable de la operación/mantenimiento continuo' },
        },
      ],
    },
    {
      key: 'sustainability',
      title: { en: '5. Testing, public awareness & sustainability', es: '5. Pruebas, concientización pública y sostenibilidad' },
      fields: [
        {
          key: 'plan_pruebas_periodicas', type: 'textarea',
          label: { en: 'Periodic testing plan', es: 'Plan de pruebas periódicas' },
        },
        {
          key: 'campana_concientizacion_publica', type: 'textarea',
          label: { en: 'Public awareness campaign', es: 'Campaña de concientización pública' },
        },
        {
          key: 'modelo_sostenibilidad', type: 'textarea',
          label: { en: 'Financial/operational sustainability model post-implementation', es: 'Modelo de sostenibilidad financiera/operativa post-implementación' },
        },
      ],
    },
  ],
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes', es: 'Notas adicionales' },
  },
};

const PROJECT_TEMPLATES = {
  ai_datacenter: DATACENTER_TEMPLATE,
  submarine_cable: SUBMARINE_CABLE_TEMPLATE,
  wholesale_neutral_network: WHOLESALE_NEUTRAL_NETWORK_TEMPLATE,
  early_warning_system: EARLY_WARNING_TEMPLATE,
};

/* ---------- Program-level templates (app/project-template.html?ptpl=) ----------
   PROJECT_TEMPLATES above is keyed by project_type — it only makes sense
   for guided forms tied to a single infrastructure category. Not every
   standardized submission works that way: ENACOM's "Participación en
   Instrumentos de Deuda en el Mercado de Capitales" financing line (Res.
   ENACOM 1191/2025 and its Annex, under the Programa "FINANCIAMIENTO Y
   APOYO A PROVEEDORES DE SERVICIOS DE TIC", Res. 950/25) isn't itself an
   infrastructure type — it's a financing mechanism (FSU co-investment in
   Obligaciones Negociables) that can fund last-mile, wholesale-
   interconnection or TIC-applied-AI projects alike (see PROYECTOS
   ELEGIBLES, Sec. V of the Annex). So this template is attached to a
   *Program* instead (app/programs.html / app/new-program.html), via the
   optional programs.template_key column — see
   supabase/migration_v18_program_template_key.sql. A submitter who selects
   a Program with a registered template gets a second "Fill using
   [program]'s template" entry point on new-project.html, alongside (not
   instead of) any project-type template. */
const CAPITAL_MARKETS_TEMPLATE = {
  title: { en: 'Capital Markets Debt Financing — application template', es: 'Template de aplicación — Línea de Financiamiento Mercado de Capitales' },
  intro: {
    en: 'Based on ENACOM Resolución 1191/2025 and its Annex — the “Participación en Instrumentos de Deuda en el Mercado de Capitales” financing line under the Programa FATIC (Res. 950/25): the Fondo del Servicio Universal co-invests in Obligaciones Negociables issued by TIC licensees (excluding providers currently rendering SCM) to fund last-mile, wholesale-interconnection, coverage-expansion or TIC-applied-AI investment projects. Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en la Resolución ENACOM 1191/2025 y su Anexo — la línea de financiamiento “Participación en Instrumentos de Deuda en el Mercado de Capitales” en el marco del Programa FATIC (Res. 950/25): el Fondo del Servicio Universal coinvierte en Obligaciones Negociables emitidas por licenciatarias TIC (excluidas las que presten efectivamente SCM) para financiar proyectos de última milla, interconexión mayorista, expansión de cobertura o inversión en IA aplicada a Servicios de TIC. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Applicant data & eligibility (Carpeta Administrativa)', es: '0. Datos del solicitante y elegibilidad (Carpeta Administrativa)' },
      fields: [
        {
          key: 'licenciatario_razon_social', type: 'text',
          label: { en: 'Licensee name / corporate name', es: 'Nombre del licenciatario / razón social' },
        },
        {
          key: 'licenciatario_cuit', type: 'text',
          label: { en: 'CUIT', es: 'CUIT' },
        },
        {
          key: 'licencia_tic_resolucion', type: 'text',
          label: { en: 'TIC license / registration Resolution number', es: 'Número de Resolución de Licencia TIC y/o registros' },
        },
        {
          key: 'antiguedad_prestacion_servicio', type: 'select',
          label: { en: 'Track record providing the service', es: 'Antigüedad de prestación efectiva del servicio' },
          options: [
            { value: 'dos_anios_o_mas', en: '2 years or more (eligibility requirement)', es: '2 años o más (requisito de elegibilidad)' },
            { value: 'menos_dos_anios', en: 'Less than 2 years', es: 'Menos de 2 años' },
          ],
        },
        {
          key: 'presta_scm', type: 'select',
          label: { en: 'Currently rendering Mobile Communications Services (SCM)', es: 'Presta efectivamente Servicio de Comunicaciones Móviles (SCM)' },
          options: [
            { value: 'no', en: 'No (eligible)', es: 'No (elegible)' },
            { value: 'si', en: 'Yes (excluded from this line)', es: 'Sí (excluido de esta Línea)' },
          ],
        },
        {
          key: 'sin_deudas_enacom_estado', type: 'select',
          label: { en: 'No outstanding debts with ENACOM or the National State', es: 'Sin deudas exigibles con ENACOM ni con el Estado Nacional' },
          options: [
            { value: 'si', en: 'Confirmed', es: 'Confirmado' },
            { value: 'no', en: 'Has outstanding debts', es: 'Tiene deudas exigibles' },
          ],
        },
      ],
    },
    {
      key: 'scope',
      title: { en: '1. Eligible project category (Annex Sec. V)', es: '1. Categoría de proyecto elegible (Anexo, Sec. V)' },
      fields: [
        {
          key: 'categoria_proyecto_elegible', type: 'select',
          label: { en: 'Eligible project category', es: 'Categoría de proyecto elegible' },
          options: [
            { value: 'ultima_milla_renovacion', en: 'Last-mile network renewal & expansion', es: 'Renovación y ampliación de redes de última milla' },
            { value: 'interconexion_mayorista', en: 'Interconnection to wholesale networks', es: 'Interconexión a redes de servicio mayorista' },
            { value: 'despliegue_conectividad_calidad', en: 'Connectivity infrastructure deployment (accessibility/quality improvement)', es: 'Despliegue de infraestructura de conectividad (mejora de accesibilidad y calidad)' },
            { value: 'nuevos_despliegues_sin_cobertura', en: 'New deployments to uncovered areas', es: 'Nuevos despliegues hacia zonas sin cobertura' },
            { value: 'inversion_ia_servicios_tic', en: 'Investment in AI applied to TIC service delivery', es: 'Inversión en desarrollos de Inteligencia Artificial aplicada a Servicios de TIC' },
          ],
        },
        {
          key: 'descripcion_objetivo', type: 'textarea',
          label: { en: 'Objective & description', es: 'Objetivo y descripción' },
        },
      ],
    },
    {
      key: 'technical',
      title: { en: '2. Technical folder (Carpeta Técnica)', es: '2. Carpeta Técnica' },
      fields: [
        {
          key: 'estado_red_actual', type: 'textarea',
          label: { en: 'Current network status', es: 'Estado de la red actual' },
        },
        {
          key: 'caracteristicas_red_proyectada', type: 'textarea',
          label: { en: 'Projected network characteristics', es: 'Características de la red proyectada' },
        },
        {
          key: 'etapas_proyecto', type: 'textarea',
          label: { en: 'Project stages', es: 'Etapas del proyecto' },
        },
        {
          key: 'equipamiento_adquirir', type: 'textarea',
          label: { en: 'Equipment to be acquired', es: 'Equipamiento a adquirir' },
        },
        {
          key: 'tipo_proyecto_mayorista_minorista', type: 'select',
          label: { en: 'Wholesale or retail project', es: 'Proyecto mayorista o minorista' },
          options: [
            { value: 'mayorista', en: 'Wholesale (deployment map required)', es: 'Mayorista (requiere mapa de despliegue)' },
            { value: 'minorista', en: 'Retail (coverage map required)', es: 'Minorista (requiere mapa de cobertura)' },
          ],
        },
        {
          key: 'hogares_comercios_establecimientos_beneficiados', type: 'text',
          label: { en: 'Households, businesses & public establishments potentially benefited', es: 'Cantidad de hogares, comercios y establecimientos públicos potencialmente beneficiados' },
        },
        {
          key: 'monto_total_requerido', type: 'text',
          label: { en: 'Total amount required for execution', es: 'Monto total requerido para la ejecución' },
        },
        {
          key: 'composicion_financiacion', type: 'textarea',
          label: { en: 'Financing composition', es: 'Composición de la financiación' },
          placeholder: { en: 'How the total will be funded — ENACOM can never finance more than 80% of the project', es: 'Cómo se compondrá la financiación total — ENACOM nunca podrá financiar más del 80% del proyecto' },
        },
      ],
    },
    {
      key: 'debt_instrument',
      title: { en: '3. Debt instrument (Annex Sec. IV)', es: '3. Instrumento de deuda (Anexo, Sec. IV)' },
      fields: [
        {
          key: 'tipo_emision', type: 'select',
          label: { en: 'Type of issuance', es: 'Tipo de emisión' },
          options: [
            { value: 'ley_23576_social_verde', en: 'Ley 23.576 / Decreto 1087/93, meeting CNV social/green/sustainable guidelines (Res. CNV 896/21) — ENACOM up to 80%', es: 'Ley 23.576 / Decreto 1087/93, cumple lineamientos sociales/verdes/sustentables CNV (Res. CNV 896/21) — ENACOM hasta 80%' },
            { value: 'ley_23576_decreto_1087', en: 'Ley 23.576 / Decreto 1087/93 (no social/green label) — ENACOM up to 70%', es: 'Ley 23.576 / Decreto 1087/93 (sin etiquetado social/verde) — ENACOM hasta 70%' },
            { value: 'ley_23576_simple', en: 'Ley 23.576 only — ENACOM up to 70%', es: 'Solo Ley 23.576 — ENACOM hasta 70%' },
          ],
        },
        {
          key: 'monto_emision', type: 'text',
          label: { en: 'Issuance amount', es: 'Monto de la emisión' },
        },
        {
          key: 'moneda_integracion_repago', type: 'text',
          label: { en: 'Settlement & repayment currency', es: 'Moneda de integración y de repago' },
        },
        {
          key: 'plazos_vencimientos_tasa', type: 'textarea',
          label: { en: 'Payment periods, maturities & interest rate', es: 'Períodos de pago, vencimientos y tasa de interés' },
        },
        {
          key: 'metodo_colocacion', type: 'text',
          label: { en: 'Placement method', es: 'Método de colocación' },
          placeholder: { en: 'e.g. primary public bidding', es: 'ej. licitación pública primaria' },
        },
        {
          key: 'calificacion_riesgo', type: 'select',
          label: { en: 'Risk rating', es: 'Calificación de riesgo' },
          options: [
            { value: 'investment_grade_obtenida', en: 'Investment grade obtained', es: 'Investment grade obtenida' },
            { value: 'en_proceso', en: 'In process', es: 'En proceso' },
          ],
        },
        {
          key: 'etiquetado_social_cnv', type: 'select',
          label: { en: 'CNV social/green/sustainable label (Res. 896/21)', es: 'Etiquetado social/verde/sustentable CNV (Res. 896/21)' },
          options: [
            { value: 'si', en: 'Yes — qualifies for 80% financing & guarantee exemption', es: 'Sí — habilita financiamiento del 80% y exención de garantía' },
            { value: 'no', en: 'No', es: 'No' },
          ],
        },
      ],
    },
    {
      key: 'economic',
      title: { en: '4. Economic folder (Carpeta Económica)', es: '4. Carpeta Económica' },
      fields: [
        {
          key: 'prospecto_suscripcion_preliminar', type: 'textarea',
          label: { en: 'Preliminary subscription prospectus', es: 'Prospecto de suscripción preliminar' },
          placeholder: { en: 'Issuance amount, currency, payment periods, maturities, rate, placement method, parties involved, subscription classes, default terms, jurisdiction', es: 'Monto de la emisión, moneda, períodos de pago, vencimientos, tasa, método de colocación, actores intervinientes, clases de suscripción, condiciones por mora, jurisdicción' },
        },
        {
          key: 'informe_calificadora_riesgo', type: 'text',
          label: { en: 'Risk-rating agency report', es: 'Informe emitido por calificadora de riesgo' },
        },
        {
          key: 'balance_estados_contables', type: 'text',
          label: { en: 'Latest balance sheet & financial statements', es: 'Balance y Estados Contables del último ejercicio' },
        },
      ],
    },
    {
      key: 'guarantee',
      title: { en: '5. Performance guarantee (Annex Sec. X)', es: '5. Garantía de cumplimiento (Anexo, Sec. X)' },
      fields: [
        {
          key: 'garantia_requerida', type: 'select',
          label: { en: 'Guarantee form', es: 'Forma de la garantía' },
          options: [
            { value: 'fianza_bancaria', en: 'Bank guarantee (fianza bancaria)', es: 'Fianza bancaria' },
            { value: 'seguro_caucion', en: 'Surety bond (seguro de caución)', es: 'Seguro de caución' },
            { value: 'exenta_etiquetado_social', en: 'Exempt (CNV social/green/sustainable-labeled issuance)', es: 'Exenta (emisión con etiquetado social/verde/sustentable CNV)' },
          ],
        },
        {
          key: 'monto_garantia', type: 'text',
          label: { en: 'Guarantee amount', es: 'Monto de la garantía' },
          placeholder: { en: '10% of the approved project budget, unless exempt', es: '10% del monto presupuestado del proyecto aprobado, salvo exención' },
        },
      ],
    },
    {
      key: 'governance',
      title: { en: '6. Follow-up & audit', es: '6. Seguimiento y auditoría' },
      fields: [
        {
          key: 'contacto_enacom_seguimiento', type: 'text',
          label: { en: 'ENACOM follow-up contact', es: 'Contacto ENACOM de seguimiento' },
        },
        {
          key: 'mecanismos_auditoria_previstos', type: 'textarea',
          label: { en: 'Planned audit mechanisms', es: 'Mecanismos de auditoría previstos' },
        },
      ],
    },
  ],
  // Covers the rest of the Carpeta Administrativa's supporting
  // documentation (Annex Sec. VIII.1.1 — minutes of the last authorities
  // appointment, corporate bylaws and amendments, technical representative's
  // professional endorsement, power of attorney, latest CNC/ENACOM
  // informative filing, CUIT/ARCA registration) and any other detail of the
  // future ACUERDO DE SUSCRIPCIÓN DE INSTRUMENTOS DE DEUDA — narrative/
  // checklist content, better suited here than as dozens more inputs.
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (remaining Carpeta Administrativa documentation, debt subscription agreement details, etc.)', es: 'Notas adicionales (resto de la documentación de la Carpeta Administrativa, detalles del acuerdo de suscripción de instrumentos de deuda, etc.)' },
  },
};

/* ENACOM's Resolución RESOL-2025-951-APN-ENACOM#JGM (4 July 2025) and its
   Anexo I approve a full "PROGRAMA RED MAYORISTA NEUTRAL" — unlike the
   Mercado de Capitales financing *line* above, this really is a Program in
   its own right (it has its own budget, its own recipients, its own
   evaluation criteria) and it maps almost entirely onto the single
   `wholesale_neutral_network` project type, whose template
   (WHOLESALE_NEUTRAL_NETWORK_TEMPLATE, defined earlier) already covers the
   technical design, deployment zone, open-access/interconnection,
   beneficiaries, eligible-expense and regulatory content from the Anexo in
   depth. Rather than re-ask all of that a second time, this Program-level
   template is deliberately narrow and complementary: postulante identity
   and the specific línea/convocatoria, explicit narrative alignment with
   each of the Anexo's 4 evaluation criteria (Sec. VII — nothing else asks
   for this directly), budget/co-financing (the Resolución's "modelo
   híbrido público-privado"), and compliance/audit. A submitter applying
   under this Program would typically fill in *both* this template and the
   wholesale_neutral_network project-type one — the "Fill using template"
   button for each shows independently on new-project.html. */
const WHOLESALE_NEUTRAL_NETWORK_PROGRAM_TEMPLATE = {
  title: { en: 'Red Mayorista Neutral — Program application template', es: 'Template de postulación — Programa Red Mayorista Neutral' },
  intro: {
    en: 'Based on ENACOM Resolución 951/2025 and its Annex — the “Red Mayorista Neutral” Program, financed by the Fondo del Servicio Universal. Complements (doesn’t replace) the technical “Neutral Wholesale Network” project-type template — use both. Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en la Resolución ENACOM 951/2025 y su Anexo — el Programa “Red Mayorista Neutral”, financiado por el Fondo del Servicio Universal. Complementa (no reemplaza) el template técnico de proyecto tipo “Red Mayorista Neutral” — usá los dos. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Applicant & financing line', es: '0. Postulante y línea de financiamiento' },
      fields: [
        {
          key: 'postulante_razon_social_cuit', type: 'text',
          label: { en: 'Applicant name / corporate name & CUIT', es: 'Nombre del postulante / razón social y CUIT' },
        },
        {
          key: 'linea_o_convocatoria', type: 'text',
          label: { en: 'Specific financing line / call for proposals', es: 'Línea de financiamiento / convocatoria específica' },
          placeholder: { en: 'Name or number of the published línea, if known', es: 'Nombre o número de la línea publicada, si se conoce' },
        },
        {
          key: 'modalidad_postulacion', type: 'select',
          label: { en: 'Application modality', es: 'Modalidad de postulación' },
          options: [
            { value: 'convocatoria_publica', en: 'Public competitive call', es: 'Convocatoria pública y competitiva' },
            { value: 'proyecto_especifico_enacom', en: 'ENACOM-designed specific project', es: 'Proyecto específico diseñado por ENACOM' },
          ],
        },
      ],
    },
    {
      key: 'evaluation_criteria',
      title: { en: '1. Alignment with evaluation criteria (Annex Sec. VII)', es: '1. Alineación con los criterios de evaluación (Anexo, Sec. VII)' },
      fields: [
        {
          key: 'criterio_impacto_social_economico', type: 'textarea',
          label: { en: '1. Social & economic impact', es: '1. Impacto social y económico del proyecto' },
          placeholder: { en: 'Improvement in connectivity for underserved areas, contribution to productive/educational/health/safety activity, articulation with local/provincial policy', es: 'Mejora en conectividad de zonas desatendidas, contribución a actividad productiva/educativa/sanitaria/de seguridad, articulación con políticas locales/provinciales' },
        },
        {
          key: 'criterio_cantidad_usuarios_beneficiados', type: 'textarea',
          label: { en: '2. Number of users benefited', es: '2. Cantidad de usuarios beneficiados' },
          placeholder: { en: 'Volume and diversity of population reached, third-party service provision potential over the financed infrastructure, impact on end users/cooperatives/other operators', es: 'Volumen y diversidad de población alcanzada, potencial de prestación de servicios a terceros sobre la infraestructura financiada, impacto en usuarios finales/cooperativas/otros operadores' },
        },
        {
          key: 'criterio_viabilidad_tecnica_sostenibilidad', type: 'textarea',
          label: { en: '3. Technical viability & operational sustainability', es: '3. Viabilidad técnica y sostenibilidad operativa' },
          placeholder: { en: 'Network design quality, equipment fit for 5G/neutral-network objectives, O&M plan, technical experience of the applicant and/or associated vendors', es: 'Calidad del diseño de red, adecuación del equipamiento a los objetivos 5G/red neutral, plan de operación y mantenimiento, experiencia técnica del postulante y/o proveedores asociados' },
        },
        {
          key: 'criterio_neutralidad_interconexion', type: 'textarea',
          label: { en: '4. Neutrality & interconnection level', es: '4. Nivel de neutralidad e interconexión' },
          placeholder: { en: 'Open, multi-operator wholesale infrastructure, interconnection with REFEFO or other public/private networks, active/passive sharing schemes (RAN sharing), non-discriminatory access conditions', es: 'Infraestructura mayorista de uso abierto multioperador, interconexión con la REFEFO u otras redes públicas/privadas, esquemas de compartición activa/pasiva (RAN sharing), condiciones de acceso no discriminatorias' },
        },
      ],
    },
    {
      key: 'budget',
      title: { en: '2. Budget & co-financing', es: '2. Presupuesto y cofinanciamiento' },
      fields: [
        {
          key: 'monto_total_solicitado_fsu', type: 'text',
          label: { en: 'Total amount requested from the FSU', es: 'Monto total solicitado al FSU' },
        },
        {
          key: 'contraparte_cofinanciamiento_privado', type: 'text',
          label: { en: 'Private/operator co-financing (hybrid public-private model)', es: 'Cofinanciamiento privado / del operador (modelo híbrido público-privado)' },
        },
        {
          key: 'rubros_elegibles_priorizados', type: 'textarea',
          label: { en: 'Prioritized eligible expense items', es: 'Rubros elegibles priorizados' },
          placeholder: { en: 'Network equipment, distribution materials, CPE/FWA devices, transport interconnection equipment (incl. REFEFO)', es: 'Equipamiento de red, materiales de distribución, dispositivos CPE/FWA, equipamiento de interconexión a transporte (incl. REFEFO)' },
        },
      ],
    },
    {
      key: 'compliance',
      title: { en: '3. Compliance & follow-up', es: '3. Cumplimiento y seguimiento' },
      fields: [
        {
          key: 'mecanismos_auditoria_aceptados', type: 'textarea',
          label: { en: 'Accepted audit mechanisms', es: 'Mecanismos de auditoría aceptados' },
          placeholder: { en: 'Documentary verification, independent certifications, technical inspections (Annex Sec. X)', es: 'Verificación documental, certificaciones independientes, inspecciones técnicas (Anexo, Sec. X)' },
        },
        {
          key: 'contacto_enacom_seguimiento', type: 'text',
          label: { en: 'ENACOM follow-up contact', es: 'Contacto ENACOM de seguimiento' },
        },
      ],
    },
  ],
  // The Program's 36-month term (from publication in the Boletín Oficial or
  // until the budget is exhausted, whichever comes first — Anexo Sec. VIII)
  // is informational, not applicant data, so it isn't modeled as a field;
  // this is the place to note it or anything else from the Resolución/Anexo
  // not covered above.
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (Program term, other Resolución/Anexo details, etc.)', es: 'Notas adicionales (vigencia del Programa, otros detalles de la Resolución/Anexo, etc.)' },
  },
};

/* ENACOM Resolución 1385/2025 and its Annex approve the "CRÉDITOS A TASA
   SUBSIDIADA" (TASU) financing line, under the same Programa
   "FINANCIAMIENTO Y APOYO A PROVEEDORES DE SERVICIOS DE TIC" (FATIC, Res.
   950/25) as CAPITAL_MARKETS_TEMPLATE above — structurally the same kind of
   thing: a financing *line* (not an infrastructure category), so it belongs
   here as a Program-level template rather than a new project_type. Under
   TASU, ENACOM subsidizes up to 15 points of the interest rate on credits
   that BCRA-authorized financial entities grant to TIC licensees, funded
   from the Fondo del Servicio Universal (FSU), to finance the operation,
   upgrade and/or expansion of TIC infrastructure networks (Annex Secs. I,
   IV, XI). Mirrors the same Carpeta Administrativa / Carpeta Técnica /
   Carpeta Económica structure required by Art. 20 of the RGSU, plus the
   credit-specific terms (adherent financial entity, subsidized points,
   term up to 6 years) and the 1%-of-project performance guarantee (Sec.
   XIV) — unlike Mercado de Capitales, TASU has no guarantee-exemption
   case. */
const TASU_TEMPLATE = {
  title: { en: 'Subsidized Rate Credit (TASU) — application template', es: 'Template de aplicación — Línea de Financiamiento Créditos a Tasa Subsidiada (TASU)' },
  intro: {
    en: 'Based on ENACOM Resolución 1385/2025 and its Annex — the “Créditos a Tasa Subsidiada” financing line under the Programa FATIC (Res. 950/25): the Fondo del Servicio Universal subsidizes up to 15 points of the interest rate on credits granted by BCRA-authorized financial entities to TIC licensees, to fund the operation, upgrade and/or expansion of TIC infrastructure networks. Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en la Resolución ENACOM 1385/2025 y su Anexo — la línea de financiamiento “Créditos a Tasa Subsidiada” en el marco del Programa FATIC (Res. 950/25): el Fondo del Servicio Universal subsidia hasta 15 puntos de la tasa de interés de créditos otorgados por entidades financieras autorizadas por el BCRA a licenciatarios TIC, para financiar la operación, actualización y/o expansión de redes de infraestructura TIC. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Applicant data & eligibility (Carpeta Administrativa)', es: '0. Datos del solicitante y elegibilidad (Carpeta Administrativa)' },
      fields: [
        {
          key: 'licenciatario_razon_social', type: 'text',
          label: { en: 'Licensee name / corporate name', es: 'Nombre del licenciatario / razón social' },
        },
        {
          key: 'licenciatario_cuit', type: 'text',
          label: { en: 'CUIT', es: 'CUIT' },
        },
        {
          key: 'licencia_tic_resolucion', type: 'text',
          label: { en: 'TIC license / registration Resolution number', es: 'Número de Resolución de Licencia TIC y/o registros' },
        },
        {
          key: 'antiguedad_prestacion_servicio', type: 'select',
          label: { en: 'Track record providing the service', es: 'Antigüedad de prestación efectiva del servicio' },
          options: [
            { value: 'dos_anios_o_mas', en: '2 years or more (eligibility requirement)', es: '2 años o más (requisito de elegibilidad)' },
            { value: 'menos_dos_anios', en: 'Less than 2 years', es: 'Menos de 2 años' },
          ],
        },
        {
          key: 'sector_actividad_excluido', type: 'select',
          label: { en: 'Belongs to an excluded activity sector', es: 'Pertenece a un sector de actividad excluido' },
          options: [
            { value: 'no', en: 'No (eligible)', es: 'No (elegible)' },
            { value: 'si', en: 'Yes — financial intermediation, insurance, or legal/accounting/real-estate professional services (excluded)', es: 'Sí — intermediación financiera, seguros, o servicios profesionales jurídicos/contables/inmobiliarios (excluido)' },
          ],
        },
        {
          key: 'situacion_concurso_inhabilitacion_bcra', type: 'select',
          label: { en: 'Inhibited, disqualified, bankrupt, or BCRA-disqualified status', es: 'Situación de inhibición, inhabilitación, quiebra o inhabilitación BCRA' },
          options: [
            { value: 'sin_impedimentos', en: 'No impediments (eligible)', es: 'Sin impedimentos (elegible)' },
            { value: 'con_impedimentos', en: 'Has one or more of these impediments (excluded)', es: 'Registra alguno de estos impedimentos (excluido)' },
          ],
        },
        {
          key: 'sin_deudas_enacom_arca', type: 'select',
          label: { en: 'No outstanding debts with ENACOM or ARCA', es: 'Sin deudas exigibles con ENACOM ni con ARCA' },
          options: [
            { value: 'si', en: 'Confirmed', es: 'Confirmado' },
            { value: 'no', en: 'Has outstanding debts', es: 'Tiene deudas exigibles' },
          ],
        },
      ],
    },
    {
      key: 'scope',
      title: { en: '1. Eligible project (Annex Sec. V)', es: '1. Proyecto elegible (Anexo, Sec. V)' },
      fields: [
        {
          key: 'orientacion_proyecto', type: 'select',
          label: { en: 'Project orientation', es: 'Orientación del proyecto' },
          options: [
            { value: 'operacion', en: 'Network operation', es: 'Operación de red' },
            { value: 'actualizacion', en: 'Network upgrade', es: 'Actualización de red' },
            { value: 'expansion', en: 'Network expansion', es: 'Expansión de red' },
            { value: 'combinacion', en: 'Combination of the above', es: 'Combinación de las anteriores' },
          ],
        },
        {
          key: 'items_excluidos_verificados', type: 'select',
          label: { en: 'Confirms no excluded items are financed (staff/professional-service fees, existing financial-contract obligations)', es: 'Confirma que no se financian ítems excluidos (retribución de personal/servicios profesionales, obligaciones de contratos financieros vigentes)' },
          options: [
            { value: 'si', en: 'Confirmed', es: 'Confirmado' },
            { value: 'no', en: 'Not yet confirmed', es: 'Aún no confirmado' },
          ],
        },
        {
          key: 'descripcion_objetivo', type: 'textarea',
          label: { en: 'Objective & description', es: 'Objetivo y descripción' },
        },
      ],
    },
    {
      key: 'technical',
      title: { en: '2. Technical folder (Carpeta Técnica)', es: '2. Carpeta Técnica' },
      fields: [
        {
          key: 'etapas_proyecto', type: 'textarea',
          label: { en: 'Project stages', es: 'Etapas del proyecto' },
        },
        {
          key: 'estado_red_actual', type: 'textarea',
          label: { en: 'Current network status', es: 'Estado de la red actual' },
        },
        {
          key: 'caracteristicas_zona', type: 'textarea',
          label: { en: 'Zone characteristics', es: 'Características de la zona' },
          placeholder: { en: 'Geographic, socioeconomic or infrastructure peculiarities that may influence the deployment', es: 'Peculiaridades geográficas, socioeconómicas o de infraestructura que puedan influir en el despliegue' },
        },
        {
          key: 'caracteristicas_red_proyectada', type: 'textarea',
          label: { en: 'Projected network characteristics & technical quality', es: 'Características de la red proyectada y calidad técnica de la propuesta' },
        },
        {
          key: 'calidad_servicio_proyectada', type: 'text',
          label: { en: 'Projected service quality', es: 'Calidad de servicio proyectada' },
        },
        {
          key: 'equipamiento_adquirir', type: 'textarea',
          label: { en: 'Equipment to be acquired (with technical spec sheets)', es: 'Equipamiento a adquirir (con hojas de especificaciones técnicas)' },
        },
        {
          key: 'mapas_diagramas_despliegue', type: 'text',
          label: { en: 'Deployment/coverage maps & block diagrams', es: 'Mapas de despliegue/cobertura y diagramas en bloques' },
          placeholder: { en: 'Attach separately — deployment map for wholesale projects, coverage map for retail', es: 'Adjuntar por separado — mapa de despliegue para proyectos mayoristas, de cobertura para minoristas' },
        },
        {
          key: 'hogares_comercios_establecimientos_beneficiados', type: 'text',
          label: { en: 'Households, businesses & public establishments potentially benefited', es: 'Cantidad de hogares, comercios y establecimientos públicos potencialmente beneficiados' },
        },
        {
          key: 'monto_total_requerido', type: 'text',
          label: { en: 'Total amount required for execution', es: 'Monto total requerido para la ejecución' },
        },
        {
          key: 'composicion_financiacion', type: 'textarea',
          label: { en: 'Financing composition', es: 'Composición de la financiación total' },
        },
      ],
    },
    {
      key: 'economic',
      title: { en: '3. Economic folder (Carpeta Económica)', es: '3. Carpeta Económica' },
      fields: [
        {
          key: 'balance_estados_contables', type: 'text',
          label: { en: 'Latest balance sheet & financial statements (with external auditor report)', es: 'Balance y Estados Contables del último ejercicio (con informe de auditor externo)' },
        },
      ],
    },
    {
      key: 'credit_terms',
      title: { en: '4. Credit line terms (Annex Secs. IV, X, XI)', es: '4. Condiciones de la Línea de Crédito (Anexo, Secs. IV, X, XI)' },
      fields: [
        {
          key: 'entidad_financiera_adherente', type: 'text',
          label: { en: 'Adherent financial entity (BCRA-authorized)', es: 'Entidad financiera adherente (autorizada por el BCRA)' },
        },
        {
          key: 'monto_credito_solicitado', type: 'text',
          label: { en: 'Requested credit amount', es: 'Monto de crédito solicitado' },
        },
        {
          key: 'moneda_credito', type: 'text',
          label: { en: 'Credit currency', es: 'Moneda del crédito' },
        },
        {
          key: 'plazo_credito', type: 'select',
          label: { en: 'Credit term', es: 'Plazo del crédito' },
          options: [
            { value: 'hasta_2_anios', en: 'Up to 2 years', es: 'Hasta 2 años' },
            { value: '3_a_4_anios', en: '3 to 4 years', es: '3 a 4 años' },
            { value: '5_a_6_anios', en: '5 to 6 years (maximum)', es: '5 a 6 años (máximo)' },
          ],
        },
        {
          key: 'puntos_subsidio_tasa_solicitados', type: 'text',
          label: { en: 'Interest-rate subsidy points requested', es: 'Puntos de subsidio de tasa solicitados' },
          placeholder: { en: 'Up to 15 percentage points, subsidized by ENACOM with FSU funds', es: 'Hasta 15 puntos porcentuales, subsidiados por ENACOM con fondos del FSU' },
        },
        {
          key: 'tasa_interes_referencia_entidad', type: 'text',
          label: { en: 'Reference interest rate offered by the entity (pre-subsidy)', es: 'Tasa de interés de referencia ofrecida por la entidad (antes del subsidio)' },
        },
      ],
    },
    {
      key: 'guarantee',
      title: { en: '5. Performance guarantee (Annex Sec. XIV)', es: '5. Garantía de cumplimiento (Anexo, Sec. XIV)' },
      fields: [
        {
          key: 'forma_garantia', type: 'select',
          label: { en: 'Guarantee form', es: 'Forma de la garantía' },
          options: [
            { value: 'fianza_bancaria', en: 'Bank guarantee (fianza bancaria)', es: 'Fianza bancaria' },
            { value: 'seguro_caucion', en: 'Surety bond (seguro de caución)', es: 'Seguro de caución' },
          ],
        },
        {
          key: 'monto_garantia', type: 'text',
          label: { en: 'Guarantee amount', es: 'Monto de la garantía' },
          placeholder: { en: '1% of the total budgeted amount of the approved project', es: '1% del monto total presupuestado para el proyecto aprobado' },
        },
      ],
    },
    {
      key: 'governance',
      title: { en: '6. Follow-up & audit (Annex Secs. XV, XVI)', es: '6. Seguimiento y auditoría (Anexo, Secs. XV, XVI)' },
      fields: [
        {
          key: 'contacto_enacom_seguimiento', type: 'text',
          label: { en: 'ENACOM follow-up contact', es: 'Contacto ENACOM de seguimiento' },
        },
        {
          key: 'mecanismos_auditoria_previstos', type: 'textarea',
          label: { en: 'Planned audit mechanisms', es: 'Mecanismos de auditoría previstos' },
        },
      ],
    },
  ],
  // Covers the remaining Carpeta Administrativa supporting documentation
  // (Annex Sec. VII.1.1 — minutes of the last authorities appointment,
  // corporate bylaws and amendments, technical representative's
  // professional endorsement, power of attorney, latest CNC/ENACOM
  // informative filing, CUIT/ARCA registration), the single-active-credit
  // rule (a Destinatario may only hold one TASU credit at a time, though
  // this doesn't bar postulating under other Líneas/Programas), and the
  // mora/cese-de-subsidio conditions (Sec. XII) that aren't modeled as
  // fields since they describe post-award servicing, not the application.
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (remaining Carpeta Administrativa documentation, mora/subsidy-suspension conditions acknowledged, etc.)', es: 'Notas adicionales (resto de la documentación de la Carpeta Administrativa, condiciones de mora/cese de subsidio reconocidas, etc.)' },
  },
};

/* ENACOM Resolución 950/2025 and its Anexo approve the base Programa
   "FINANCIAMIENTO Y APOYO A PROVEEDORES DE SERVICIOS DE TIC" (FATIC) —
   the same parent Program as CAPITAL_MARKETS_TEMPLATE and TASU_TEMPLATE
   above, both of which correspond to specific approved Líneas de
   Financiamiento (Mercado de Capitales, Créditos a Tasa Subsidiada). This
   template instead covers the Program at its general level: the Carpeta
   Administrativa eligibility shared by every línea (Sec. V/VI of the
   Anexo — MiPyME/Cooperativa status, 2-year track record, no debts), plus
   the third línea the Anexo describes but that hasn't been formalized by
   its own dedicated Resolución yet — "Provisión Directa o Indirecta de
   Equipamiento Tecnológico" (Anexo Sec. IV.1.3) — and the scoring factors
   (Sec. VI.1) ENACOM uses to weigh any of the three líneas. A submitter
   who already knows they're applying under Mercado de Capitales or TASU
   should use those dedicated templates instead/in addition; this one is
   for the Equipment línea or for a general FATIC application before a
   specific línea is chosen. */
const FATIC_GENERAL_TEMPLATE = {
  title: { en: 'FATIC Program — general application & Equipment Provision', es: 'Programa FATIC — postulación general y Provisión de Equipamiento' },
  intro: {
    en: 'Based on ENACOM Resolución 950/2025 and its Annex — the base Programa “Financiamiento y Apoyo a Proveedores de Servicios de TIC” (FATIC), which funds Créditos a Tasa Subsidiada, Participación en Instrumentos de Deuda del Mercado de Capitales, and Provisión Directa o Indirecta de Equipamiento Tecnológico. Use this template for the Equipment línea, or as a general FATIC application before a specific línea is defined — use the dedicated Mercado de Capitales / TASU templates instead if you already know which of those two applies. Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en la Resolución ENACOM 950/2025 y su Anexo — el Programa base “Financiamiento y Apoyo a Proveedores de Servicios de TIC” (FATIC), que financia Créditos a Tasa Subsidiada, Participación en Instrumentos de Deuda del Mercado de Capitales, y Provisión Directa o Indirecta de Equipamiento Tecnológico. Usá este template para la línea de Equipamiento, o como postulación general al FATIC antes de definir la línea específica — si ya sabés que aplicás a Mercado de Capitales o TASU, usá esos templates dedicados. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Applicant data & eligibility (Carpeta Administrativa)', es: '0. Datos del solicitante y elegibilidad (Carpeta Administrativa)' },
      fields: [
        {
          key: 'destinatario_razon_social', type: 'text',
          label: { en: 'Applicant name / corporate name', es: 'Nombre del destinatario / razón social' },
        },
        {
          key: 'destinatario_cuit', type: 'text',
          label: { en: 'CUIT', es: 'CUIT' },
        },
        {
          key: 'tipo_destinatario', type: 'select',
          label: { en: 'Applicant type', es: 'Tipo de destinatario' },
          options: [
            { value: 'mipyme', en: 'Micro, Small or Medium Enterprise (MiPyME)', es: 'Micro, Pequeña o Mediana Empresa (MiPyME)' },
            { value: 'cooperativa', en: 'Cooperative', es: 'Cooperativa' },
          ],
        },
        {
          key: 'licencia_registro_resolucion', type: 'text',
          label: { en: 'TIC license / registration Resolution number', es: 'Número de Resolución de Licencia TIC y/o registros' },
        },
        {
          key: 'antiguedad_prestacion_servicio', type: 'select',
          label: { en: 'Track record providing the service', es: 'Antigüedad de prestación efectiva del servicio' },
          options: [
            { value: 'dos_anios_o_mas', en: '2 years or more (eligibility requirement)', es: '2 años o más (requisito de elegibilidad)' },
            { value: 'menos_dos_anios', en: 'Less than 2 years', es: 'Menos de 2 años' },
          ],
        },
        {
          key: 'sin_deudas_enacom_estado', type: 'select',
          label: { en: 'No outstanding debts with ENACOM or the National State', es: 'Sin deudas exigibles con ENACOM ni con el Estado Nacional' },
          options: [
            { value: 'si', en: 'Confirmed', es: 'Confirmado' },
            { value: 'no', en: 'Has outstanding debts', es: 'Tiene deudas exigibles' },
          ],
        },
      ],
    },
    {
      key: 'scope',
      title: { en: '1. Financing línea', es: '1. Línea de financiamiento' },
      fields: [
        {
          key: 'linea_financiamiento_seleccionada', type: 'select',
          label: { en: 'Selected financing línea', es: 'Línea de financiamiento seleccionada' },
          options: [
            { value: 'equipamiento_tecnologico', en: 'Direct/indirect Equipment Provision (this template)', es: 'Provisión Directa o Indirecta de Equipamiento Tecnológico (este template)' },
            { value: 'tasa_subsidiada', en: 'Subsidized Rate Credit — TASU (use dedicated template)', es: 'Créditos a Tasa Subsidiada — TASU (usar template dedicado)' },
            { value: 'mercado_capitales', en: 'Capital Markets Debt Instruments (use dedicated template)', es: 'Instrumentos de Deuda del Mercado de Capitales (usar template dedicado)' },
            { value: 'a_definir_convocatoria', en: 'Not yet defined — general FATIC application', es: 'Aún no definida — postulación general al FATIC' },
          ],
        },
        {
          key: 'descripcion_objetivo_general', type: 'textarea',
          label: { en: 'Objective & description', es: 'Objetivo y descripción' },
        },
      ],
    },
    {
      key: 'equipment',
      title: { en: '2. Equipment Provision línea (Annex Sec. IV.1.3)', es: '2. Línea de Provisión de Equipamiento Tecnológico (Anexo, Sec. IV.1.3)' },
      fields: [
        {
          key: 'tipo_equipamiento_solicitado', type: 'textarea',
          label: { en: 'Type of equipment requested', es: 'Tipo de equipamiento solicitado' },
        },
        {
          key: 'cantidad_estimada_unidades', type: 'text',
          label: { en: 'Estimated quantity of units', es: 'Cantidad estimada de unidades' },
        },
        {
          key: 'zona_instalacion_destino', type: 'text',
          label: { en: 'Installation zone / destination', es: 'Zona de instalación / destino' },
        },
        {
          key: 'objetivo_modernizacion_extension', type: 'select',
          label: { en: 'Equipment objective', es: 'Objetivo del equipamiento' },
          options: [
            { value: 'modernizar_infraestructura', en: 'Modernize already-deployed infrastructure', es: 'Modernizar infraestructura ya desplegada' },
            { value: 'extender_zona_sin_cobertura', en: 'Extend service to uncovered areas', es: 'Extender servicios a zonas sin cobertura' },
            { value: 'instalacion_nuevos_accesos', en: 'Enable installation of new user accesses', es: 'Facilitar la instalación de accesos de nuevos usuarios' },
          ],
        },
        {
          key: 'contraprestaciones_propuestas', type: 'textarea',
          label: { en: 'Proposed counter-performance', es: 'Contraprestaciones propuestas' },
          placeholder: { en: 'Deployment commitments with deadlines, affordable plans/pricing for end users, service provision in specific zones, sharing, etc.', es: 'Compromisos de despliegue en plazos determinados, planes y precios accesibles para usuarios finales, prestación de servicios en zonas específicas, compartición, etc.' },
        },
      ],
    },
    {
      key: 'scoring',
      title: { en: '3. Scoring factors (Annex Sec. VI.1)', es: '3. Factores de scoring (Anexo, Sec. VI.1)' },
      fields: [
        {
          key: 'cantidad_usuarios_potenciales_beneficiados', type: 'text',
          label: { en: 'Potential users to be benefited', es: 'Cantidad de usuarios potenciales a beneficiar' },
        },
        {
          key: 'tipo_tecnologia_red', type: 'text',
          label: { en: 'Network type & technology to deploy or upgrade', es: 'Tipo y tecnología de red a desplegar o mejorar' },
        },
        {
          key: 'caracteristicas_zona_geografica', type: 'textarea',
          label: { en: 'Project-specific & geographic-zone characteristics', es: 'Características específicas del proyecto y su ubicación geográfica' },
          placeholder: { en: 'Zones with lower coverage are prioritized', es: 'Se priorizan zonas con menor cobertura' },
        },
        {
          key: 'garantias_ofrecidas', type: 'text',
          label: { en: 'Guarantees offered', es: 'Garantías ofrecidas' },
        },
      ],
    },
    {
      key: 'governance',
      title: { en: '4. Follow-up & audit', es: '4. Seguimiento y auditoría' },
      fields: [
        {
          key: 'contacto_enacom_seguimiento', type: 'text',
          label: { en: 'ENACOM follow-up contact', es: 'Contacto ENACOM de seguimiento' },
        },
        {
          key: 'mecanismos_auditoria_previstos', type: 'textarea',
          label: { en: 'Planned audit mechanisms', es: 'Mecanismos de auditoría previstos' },
        },
      ],
    },
  ],
  // The Program's 36-month term (from Boletín Oficial publication or until
  // the $40.000.000.000 budget is exhausted, whichever comes first — Sec.
  // VII) and the possibility of new líneas being created in the future
  // (Sec. IV.2) are informational rather than applicant data.
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (Program term, future líneas, other Resolución/Anexo details, etc.)', es: 'Notas adicionales (vigencia del Programa, futuras líneas, otros detalles de la Resolución/Anexo, etc.)' },
  },
};

/* ENACOM Resolución 449/2021 approved the Programa "ASISTENCIA A
   PRESTADORES DE SERVICIOS TIC ANTE EMERGENCIAS Y CATÁSTROFES", most
   recently updated/extended by Resolución 323/2025 (new Anexo IF-2025-
   16522367-APN-DNFYD#ENACOM, $2.500.000.000 budget, up to $150.000.000
   ANR per project). Fully independent of the FATIC Program above — its
   own budget, destinatarios, and mechanics — so, like Red Mayorista
   Neutral and TASU, it's modeled as a Program-level template. Field
   labels for the Carpeta Administrativa and Carpeta Técnica sections are
   taken directly from ENACOM's own fillable forms for this Program
   (carpeta-administrativa.pdf / carpeta-tecnica.pdf), so the guided form
   here mirrors exactly what TAD will ask for; the Plan de Inversiones
   (Sec. 10.2.3) is summarized rather than itemized — it's an Excel
   workbook (plan-de-inversiones--pi-.xlsx) meant to be filled and
   attached separately, listing every budgeted item with its type
   (Financiable/No financiable) and currency (ARS/USD). */
const EMERGENCIAS_CATASTROFES_TEMPLATE = {
  title: { en: 'Assistance to TIC Providers facing Emergencies & Disasters — application template', es: 'Template de aplicación — Asistencia a Prestadores de Servicios TIC ante Emergencias y Catástrofes' },
  intro: {
    en: 'Based on ENACOM Resolución 449/2021 (updated by Resolución 323/2025) — the Programa “Asistencia a Prestadores de Servicios TIC ante Emergencias y Catástrofes”: up to 100% of financiable investments as a non-reimbursable contribution (ANR), up to $150,000,000 per project, to replace TIC network infrastructure damaged by a declared emergency or disaster. Field labels mirror ENACOM’s own Carpeta Administrativa / Carpeta Técnica forms for this Program. Remember to attach the Plan de Inversiones (PI) spreadsheet separately, itemizing every budgeted quote. Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en la Resolución ENACOM 449/2021 (actualizada por la Resolución 323/2025) — el Programa “Asistencia a Prestadores de Servicios TIC ante Emergencias y Catástrofes”: hasta el 100% de las inversiones financiables como Aporte No Reembolsable (ANR), hasta $150.000.000 por proyecto, para reponer infraestructura de red TIC afectada por una emergencia o catástrofe declarada. Las etiquetas de los campos siguen los propios formularios de Carpeta Administrativa / Carpeta Técnica de ENACOM para este Programa. Recordá adjuntar por separado la planilla de Plan de Inversiones (PI), detallando cada presupuesto ítem por ítem. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. General licensee/applicant data (Carpeta Administrativa)', es: '0. Datos generales del licenciatario/destinatario (Carpeta Administrativa)' },
      fields: [
        {
          key: 'nombre_destinatario', type: 'text',
          label: { en: 'Name', es: 'Nombre' },
        },
        {
          key: 'cuit', type: 'text',
          label: { en: 'CUIT', es: 'CUIT' },
        },
        {
          key: 'numero_resolucion_licencia', type: 'text',
          label: { en: 'Resolution number (TIC service license and/or registrations)', es: 'N° de Resolución (de su Licencia de Servicios de TIC y/o registros)' },
        },
        {
          key: 'telefono_fijo', type: 'text',
          label: { en: 'Landline phone', es: 'Teléfono fijo' },
        },
        {
          key: 'telefono_celular', type: 'text',
          label: { en: 'Cell phone', es: 'Teléfono celular' },
        },
        {
          key: 'correo_electronico_1', type: 'text',
          label: { en: 'Email address 1', es: 'Correo electrónico 1' },
        },
        {
          key: 'correo_electronico_2', type: 'text',
          label: { en: 'Email address 2', es: 'Correo electrónico 2' },
        },
        {
          key: 'tipo_solicitante', type: 'select',
          label: { en: 'Applicant type', es: 'Tipo de solicitante' },
          options: [
            { value: 'persona_humana', en: 'Individual (not registered under Monotributo/ARCA)', es: 'Persona humana (no inscripta en Monotributo/ARCA)' },
            { value: 'persona_juridica_2_anios_o_mas', en: 'Legal entity, 2+ years old', es: 'Persona jurídica, 2 años o más de antigüedad' },
            { value: 'persona_juridica_menos_2_anios', en: 'Legal entity, less than 2 years old', es: 'Persona jurídica, menos de 2 años de antigüedad' },
          ],
        },
        {
          key: 'declaracion_emergencia_catastrofe', type: 'text',
          label: { en: 'Emergency/disaster declaration (issuing authority & reference)', es: 'Declaración de Emergencia o Catástrofe (autoridad emisora y referencia)' },
          placeholder: { en: 'National, provincial or municipal authority that declared the emergency/disaster', es: 'Autoridad Nacional, Provincial o Municipal que declaró la emergencia/catástrofe' },
        },
      ],
    },
    {
      key: 'technical',
      title: { en: '1. Project descriptive memo (Carpeta Técnica)', es: '1. Memoria Descriptiva del Proyecto (Carpeta Técnica)' },
      fields: [
        {
          key: 'objetivo', type: 'textarea',
          label: { en: 'Objective', es: 'Objetivo' },
        },
        {
          key: 'descripcion_proyecto', type: 'textarea',
          label: { en: 'Project description', es: 'Descripción del Proyecto' },
        },
        {
          key: 'infraestructura_red_existente', type: 'textarea',
          label: { en: 'Existing network infrastructure at the time of the events that caused the disaster', es: 'Infraestructura de red existente al momento de los eventos que originaron la catástrofe' },
        },
        {
          key: 'descripcion_infraestructura_afectada', type: 'textarea',
          label: { en: 'Description of affected infrastructure', es: 'Descripción de la infraestructura afectada' },
          placeholder: { en: 'Detail of all affected elements and the reason replacement is needed', es: 'Detalle de todos los elementos afectados y la razón de la necesidad de reemplazo' },
        },
        {
          key: 'mapa_area_geografica_afectada', type: 'text',
          label: { en: 'Map of the affected geographic area', es: 'Mapa del área geográfica afectada' },
          placeholder: { en: 'Attach separately in TAD as “Presentación a Agregar”', es: 'Adjuntar por separado en TAD como “Presentación a Agregar”' },
        },
        {
          key: 'cantidad_usuarios_servicio_afectados', type: 'text',
          label: { en: 'Number of affected service users', es: 'Cantidad de usuarios del servicio afectados' },
        },
        {
          key: 'cronograma_trabajos', type: 'textarea',
          label: { en: 'Work schedule, incl. when the network will be operational again', es: 'Cronograma de trabajos, incluido el plazo en el que la red se encontrará operativa' },
        },
        {
          key: 'equipamiento_adquirir', type: 'textarea',
          label: { en: 'Equipment to be acquired (with manufacturer part numbers / vendor product codes)', es: 'Equipamiento a adquirir (con número de parte del fabricante / código de producto del proveedor)' },
        },
      ],
    },
    {
      key: 'economic',
      title: { en: '2. Economic folder & Plan de Inversiones (Sec. 10.2.3)', es: '2. Carpeta Económica y Plan de Inversiones (Sec. 10.2.3)' },
      fields: [
        {
          key: 'total_presupuestado_ars', type: 'text',
          label: { en: 'Total budgeted amount, ARS (excl. VAT)', es: 'Total presupuestado en pesos (sin IVA)' },
        },
        {
          key: 'total_presupuestado_usd', type: 'text',
          label: { en: 'Total budgeted amount, USD (excl. VAT)', es: 'Total presupuestado en dólares (sin IVA)' },
        },
        {
          key: 'total_gastos_no_financiables', type: 'text',
          label: { en: 'Total non-financiable expenses (ARS/USD)', es: 'Total de gastos no financiables presupuestados (pesos/dólares)' },
        },
        {
          key: 'estados_contables_certificacion_ingresos', type: 'text',
          label: { en: 'Financial statements (legal entities) or income certification, last 24 months (individuals)', es: 'Estados contables (personas jurídicas) o certificación de ingresos de los últimos 24 meses (personas humanas)' },
        },
        {
          key: 'patrimonio_neto_limite_2x', type: 'select',
          label: { en: 'Total investment within 2x net worth limit (individuals & entities <2 yrs old)', es: 'Inversión total dentro del límite de 2x el Patrimonio Neto (personas humanas y sociedades <2 años)' },
          options: [
            { value: 'no_aplica', en: 'Not applicable (entity 2+ years old)', es: 'No aplica (persona jurídica con 2 años o más)' },
            { value: 'si_cumple', en: 'Confirmed within limit', es: 'Confirmado, dentro del límite' },
          ],
        },
      ],
    },
    {
      key: 'financing',
      title: { en: '3. Requested ANR financing (Sec. 6)', es: '3. Financiamiento ANR solicitado (Sec. 6)' },
      fields: [
        {
          key: 'monto_anr_solicitado', type: 'text',
          label: { en: 'Requested ANR amount', es: 'Monto de ANR solicitado' },
          placeholder: { en: 'Up to 100% of financiable investments, capped at $150,000,000 per project', es: 'Hasta el 100% de las inversiones financiables, con un tope de $150.000.000 por proyecto' },
        },
        {
          key: 'esquema_anticipo_desembolso', type: 'select',
          label: { en: 'Disbursement scheme', es: 'Esquema de desembolso' },
          options: [
            { value: 'anticipo_30_mas_final', en: '30% advance + final disbursement after advance is accounted for', es: '30% de anticipo + desembolso final tras la rendición del anticipo' },
          ],
        },
      ],
    },
    {
      key: 'guarantee',
      title: { en: '4. Performance guarantee (Sec. 7)', es: '4. Garantía de cumplimiento (Sec. 7)' },
      fields: [
        {
          key: 'forma_garantia', type: 'select',
          label: { en: 'Guarantee form', es: 'Forma de la garantía' },
          options: [
            { value: 'fianza_bancaria', en: 'Bank guarantee (fianza bancaria)', es: 'Fianza bancaria' },
            { value: 'seguro_caucion', en: 'Surety bond (seguro de caución)', es: 'Seguro de caución' },
          ],
        },
        {
          key: 'monto_garantia', type: 'text',
          label: { en: 'Guarantee amount', es: 'Monto de la garantía' },
          placeholder: { en: '30% of the approved ANR amount', es: '30% del monto de ANR aprobado' },
        },
      ],
    },
    {
      key: 'governance',
      title: { en: '5. Follow-up, audit & closing (Secs. 17-20)', es: '5. Seguimiento, auditoría y cierre (Secs. 17-20)' },
      fields: [
        {
          key: 'contacto_enacom_seguimiento', type: 'text',
          label: { en: 'ENACOM follow-up contact', es: 'Contacto ENACOM de seguimiento' },
        },
        {
          key: 'mecanismos_auditoria_previstos', type: 'textarea',
          label: { en: 'Planned audit mechanisms', es: 'Mecanismos de auditoría previstos' },
        },
      ],
    },
  ],
  // Covers remaining Carpeta Administrativa items from Sec. 10.2.1 not
  // captured above (proof of damage, sworn statement of no insurance
  // coverage for this kind of event, technical representative's
  // professional endorsement, ENACOM debt-free certificate, latest CNC
  // 2220/12 filing, and — depending on applicant type — DNI/criminal
  // record certificate for individuals or bylaws/latest authorities
  // appointment minutes for legal entities), plus the exclusions (Sec.
  // 5.2 — no staff retribution, professional-service fees, or
  // vehicles/machinery financed).
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (remaining Carpeta Administrativa documentation, exclusions acknowledged, etc.)', es: 'Notas adicionales (resto de la documentación de la Carpeta Administrativa, exclusiones reconocidas, etc.)' },
  },
};

/* ENACOM Resolución 1072/2024 approved the Programa "CONECTIVIDAD DE
   INTERÉS PÚBLICO" (C.I.P.) — funded by the Fondo Fiduciario del Servicio
   Universal, distinct from and not a substitute/complement for any other
   ENACOM program. Unlike the financing-line templates above, its
   destinatarios are government bodies (national/provincial/municipal) or
   ENACOM itself, applying on behalf of a sectoral plan/project/program
   (education, health, safety, etc.) that needs TIC services as an input —
   not TIC licensees seeking to fund their own network. Modeled as a
   Program-level template since it isn't tied to a single infrastructure
   project_type (it can fund Conectividad, Pisos Tecnológicos, or
   Material/Equipamiento TIC alike — Anexo Sec. IV). */
const CIP_TEMPLATE = {
  title: { en: 'Public Interest Connectivity (C.I.P.) — application template', es: 'Template de aplicación — Programa Conectividad de Interés Público (C.I.P.)' },
  intro: {
    en: 'Based on ENACOM Resolución 1072/2024 — the Programa “Conectividad de Interés Público” (C.I.P.): enables TIC services (connectivity, network “pisos tecnológicos”, or equipment) as an input to education, health, safety or other sectoral plans/projects run by national, provincial or municipal government bodies, or by ENACOM itself. Fill in whatever you know; anything left blank is simply omitted from the generated description.',
    es: 'Basado en la Resolución ENACOM 1072/2024 — el Programa “Conectividad de Interés Público” (C.I.P.): posibilita el uso de Servicios de TIC (conectividad, “pisos tecnológicos” de red, o equipamiento) como insumo de planes/proyectos sectoriales de educación, salud, seguridad u otros, llevados adelante por organismos de gobierno nacional, provincial o municipal, o por el propio ENACOM. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Applicant & sectoral plan (Annex Sec. III)', es: '0. Solicitante y plan sectorial (Anexo, Sec. III)' },
      fields: [
        {
          key: 'organismo_solicitante', type: 'text',
          label: { en: 'Requesting government body / organization', es: 'Organismo / entidad solicitante' },
        },
        {
          key: 'nivel_gobierno', type: 'select',
          label: { en: 'Government level', es: 'Nivel de gobierno' },
          options: [
            { value: 'nacional', en: 'National', es: 'Nacional' },
            { value: 'provincial', en: 'Provincial', es: 'Provincial' },
            { value: 'municipal', en: 'Municipal', es: 'Municipal' },
            { value: 'iniciativa_enacom', en: 'ENACOM-driven initiative', es: 'Iniciativa del propio ENACOM' },
          ],
        },
        {
          key: 'ambito_sectorial', type: 'select',
          label: { en: 'Sectoral scope', es: 'Ámbito sectorial' },
          options: [
            { value: 'educacion', en: 'Education', es: 'Educación' },
            { value: 'salud', en: 'Health', es: 'Salud' },
            { value: 'seguridad', en: 'Safety/security', es: 'Seguridad' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
        {
          key: 'plan_proyecto_sectorial_asociado', type: 'text',
          label: { en: 'Associated sectoral plan/project/program', es: 'Plan, proyecto o programa sectorial asociado' },
          placeholder: { en: 'e.g. Plan Nacional de Alfabetización', es: 'ej. Plan Nacional de Alfabetización' },
        },
      ],
    },
    {
      key: 'scope',
      title: { en: '1. Type of request (Annex Sec. IV)', es: '1. Tipo de solicitud (Anexo, Sec. IV)' },
      fields: [
        {
          key: 'tipo_solicitud', type: 'select',
          label: { en: 'Request type', es: 'Tipo de solicitud' },
          options: [
            { value: 'conectividad', en: 'Connectivity (wired/wireless internet access)', es: 'Conectividad (acceso a internet alámbrico/inalámbrico)' },
            { value: 'pisos_tecnologicos', en: 'Technological floors (internal data/power network infrastructure)', es: 'Pisos tecnológicos (infraestructura de red de datos/eléctrica interna)' },
            { value: 'material_equipamiento_tic', en: 'TIC material & equipment', es: 'Material y equipamiento TIC' },
            { value: 'combinacion', en: 'Combination of the above', es: 'Combinación de las anteriores' },
          ],
        },
        {
          key: 'descripcion_necesidad', type: 'textarea',
          label: { en: 'Description of the need', es: 'Descripción de la necesidad' },
        },
        {
          key: 'instituciones_publicas_destino', type: 'textarea',
          label: { en: 'Target public institutions / sites', es: 'Instituciones públicas / sedes destino' },
        },
      ],
    },
    {
      key: 'allocation',
      title: { en: '2. Allocation mechanism (Annex Sec. V)', es: '2. Mecanismo de adjudicación (Anexo, Sec. V)' },
      fields: [
        {
          key: 'origen_proyecto', type: 'select',
          label: { en: 'Project origin', es: 'Origen del proyecto' },
          options: [
            { value: 'presentado_por_destinatario', en: 'Submitted directly by the government body', es: 'Presentado directamente por el organismo destinatario' },
            { value: 'iniciativa_enacom_convocatoria', en: 'ENACOM-driven — via public call for proposals', es: 'Por iniciativa de ENACOM — mediante convocatoria pública' },
          ],
        },
        {
          key: 'prestador_proveedor_propuesto', type: 'text',
          label: { en: 'Proposed service provider / equipment vendor, if any', es: 'Prestador de servicio / proveedor de equipamiento propuesto, si corresponde' },
          placeholder: { en: 'Selection must still ensure publicity, equal treatment and free competition among offerors', es: 'La selección debe igualmente asegurar publicidad, igualdad de oferentes y libre concurrencia' },
        },
      ],
    },
    {
      key: 'sizing',
      title: { en: '3. Sizing & justification', es: '3. Dimensionamiento y justificación' },
      fields: [
        {
          key: 'cantidad_beneficiarios_estimados', type: 'text',
          label: { en: 'Estimated number of beneficiaries', es: 'Cantidad estimada de beneficiarios' },
        },
        {
          key: 'justificacion_razonabilidad_costos', type: 'textarea',
          label: { en: 'Cost reasonableness justification', es: 'Justificación de razonabilidad de costos' },
        },
      ],
    },
    {
      key: 'governance',
      title: { en: '4. Follow-up & audit', es: '4. Seguimiento y auditoría' },
      fields: [
        {
          key: 'contacto_enacom_seguimiento', type: 'text',
          label: { en: 'ENACOM follow-up contact', es: 'Contacto ENACOM de seguimiento' },
        },
        {
          key: 'mecanismos_auditoria_previstos', type: 'textarea',
          label: { en: 'Planned audit mechanisms', es: 'Mecanismos de auditoría previstos' },
        },
      ],
    },
  ],
  // The Program's 24-month term and the fact that it's neither a
  // substitute for nor complementary to any other ENACOM program/project/
  // call (Sec. I) are informational rather than applicant data.
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (Program term, Convenio details, etc.)', es: 'Notas adicionales (vigencia del Programa, detalles del Convenio, etc.)' },
  },
};

/* STANDARD / PLACEHOLDER template — not based on an actual USTDA program
   document yet. Modeled on USTDA's publicly known Feasibility Study /
   Definitional Mission grant criteria (project sponsor eligibility, U.S.
   nexus requirement, scope of the requested study, follow-on financing)
   rather than a specific USTDA resolution or solicitation, the way every
   other Program-level template here is. Pablo is expected to share a real
   USTDA reference document later — when that happens, replace this
   constant's `sections`/fields with the actual requirements (see
   PLATFORM_SETUP.md's "Program-level templates" section) without needing
   to touch anything else (PROGRAM_TEMPLATES/PROGRAM_TEMPLATE_OPTIONS below
   just reference this constant by name). This is the 'preparation'-stage
   counterpart to the 'financing'-stage templates above — see
   PROGRAM_FUNDING_STAGE_LABELS and
   supabase/migration_v21_program_funding_stage_and_applications.sql: USTDA
   funds ELABORATING a project (a feasibility study or definitional
   mission), not its implementation. */
const USTDA_PREPARATION_TEMPLATE = {
  title: { en: 'USTDA Project Preparation Funding — application template (standard, pending final version)', es: 'Template de aplicación — Financiamiento USTDA para Elaboración de Proyecto (estándar, pendiente versión definitiva)' },
  intro: {
    en: 'Standard placeholder based on the U.S. Trade and Development Agency’s general Feasibility Study / Definitional Mission grant criteria — NOT yet based on a specific USTDA solicitation or program document. USTDA funds elaborating/structuring a project (the study itself), before it has a finished design — a different stage than every other financing line in this list, which fund the project’s actual implementation. Fill in whatever you know; anything left blank is simply omitted from the generated description. This template will be replaced once a definitive USTDA reference document is available.',
    es: 'Placeholder estándar basado en los criterios generales de USTDA (U.S. Trade and Development Agency) para grants de Estudio de Factibilidad / Misión Definicional — TODAVÍA NO está basado en una solicitud o documento de programa específico de USTDA. USTDA financia la elaboración/estructuración de un proyecto (el estudio en sí), antes de que tenga un diseño terminado — una etapa distinta de todas las demás líneas de financiamiento de esta lista, que financian la implementación del proyecto. Completá lo que sepas; lo que dejes en blanco simplemente no aparece en la descripción generada. Este template se va a reemplazar cuando esté disponible el documento de referencia definitivo de USTDA.',
  },
  sections: [
    {
      key: 'general',
      title: { en: '0. Requesting entity & sponsor eligibility', es: '0. Entidad solicitante y elegibilidad del sponsor' },
      fields: [
        {
          key: 'entidad_solicitante', type: 'text',
          label: { en: 'Requesting entity / project sponsor', es: 'Entidad solicitante / sponsor del proyecto' },
        },
        {
          key: 'naturaleza_entidad', type: 'select',
          label: { en: 'Nature of the requesting entity', es: 'Naturaleza de la entidad solicitante' },
          options: [
            { value: 'gobierno_nacional', en: 'National government body', es: 'Organismo de gobierno nacional' },
            { value: 'gobierno_provincial', en: 'Provincial government body', es: 'Organismo de gobierno provincial' },
            { value: 'gobierno_municipal', en: 'Municipal government body', es: 'Organismo de gobierno municipal' },
            { value: 'empresa_estatal', en: 'State-owned enterprise', es: 'Empresa de propiedad estatal' },
            { value: 'otro', en: 'Other public-sector entity', es: 'Otra entidad del sector público' },
          ],
        },
        {
          key: 'carta_apoyo_gobierno', type: 'select',
          label: { en: 'Letter of support/interest from the host government available', es: 'Carta de apoyo/interés del gobierno anfitrión disponible' },
          options: [
            { value: 'si', en: 'Yes', es: 'Sí' },
            { value: 'en_gestion', en: 'In progress', es: 'En gestión' },
            { value: 'no', en: 'Not yet', es: 'Todavía no' },
          ],
        },
      ],
    },
    {
      key: 'nexus',
      title: { en: '1. Project description & U.S. nexus', es: '1. Descripción del proyecto y nexo con EE.UU.' },
      fields: [
        {
          key: 'objetivo_proyecto', type: 'textarea',
          label: { en: 'Project objective and expected development impact', es: 'Objetivo del proyecto e impacto de desarrollo esperado' },
        },
        {
          key: 'sector_infraestructura', type: 'select',
          label: { en: 'Infrastructure sector', es: 'Sector de infraestructura' },
          options: [
            { value: 'submarine_cable', en: 'Submarine cable', es: 'Cable submarino' },
            { value: 'fiber_backbone_last_mile', en: 'Fiber backbone / last-mile', es: 'Backbone de fibra / última milla' },
            { value: 'fixed_wireless_access', en: 'Fixed wireless access', es: 'Acceso inalámbrico fijo' },
            { value: 'wholesale_neutral_network', en: 'Wholesale neutral network', es: 'Red mayorista neutral' },
            { value: 'ai_datacenter', en: 'AI / data center', es: 'Datacenter / IA' },
            { value: 'satellite_constellation', en: 'Satellite communications', es: 'Comunicaciones satelitales' },
            { value: 'passive_infrastructure', en: 'Passive infrastructure (poles/ducts sharing)', es: 'Infraestructura pasiva (compartición de postes/ductos)' },
            { value: 'otro', en: 'Other', es: 'Otro' },
          ],
        },
        {
          key: 'oportunidad_bienes_servicios_eeuu', type: 'textarea',
          label: { en: 'Opportunities for U.S. goods, services, or technology in the resulting project (USTDA’s core eligibility requirement)', es: 'Oportunidades para bienes, servicios o tecnología de EE.UU. en el proyecto resultante (requisito central de elegibilidad de USTDA)' },
        },
        {
          key: 'proponente_integrador_eeuu', type: 'text',
          label: { en: 'U.S. project proponent / systems integrator, if already identified', es: 'Proponente / integrador de sistemas de EE.UU., si ya está identificado' },
        },
      ],
    },
    {
      key: 'scope',
      title: { en: '2. Scope of the requested study or mission', es: '2. Alcance del estudio o misión solicitado' },
      fields: [
        {
          key: 'tipo_asistencia_solicitada', type: 'select',
          label: { en: 'Type of assistance requested', es: 'Tipo de asistencia solicitada' },
          options: [
            { value: 'feasibility_study', en: 'Feasibility study', es: 'Estudio de factibilidad' },
            { value: 'definitional_mission', en: 'Definitional mission', es: 'Misión definicional' },
            { value: 'technical_assistance', en: 'Technical assistance', es: 'Asistencia técnica' },
            { value: 'pilot_project', en: 'Pilot project', es: 'Proyecto piloto' },
            { value: 'reverse_trade_mission', en: 'Reverse trade mission', es: 'Misión comercial inversa' },
          ],
        },
        {
          key: 'alcance_tecnico', type: 'textarea',
          label: { en: 'Technical scope requested (engineering design review, technology options, siting, etc.)', es: 'Alcance técnico solicitado (revisión de diseño de ingeniería, opciones tecnológicas, localización, etc.)' },
        },
        {
          key: 'alcance_economico_financiero', type: 'textarea',
          label: { en: 'Economic & financial scope requested (cost-benefit analysis, tariff/revenue modeling, financing structure options)', es: 'Alcance económico y financiero solicitado (análisis costo-beneficio, modelado de tarifas/ingresos, opciones de estructura de financiamiento)' },
        },
        {
          key: 'alcance_ambiental_social', type: 'textarea',
          label: { en: 'Environmental & social scope requested (safeguards screening, community engagement)', es: 'Alcance ambiental y social solicitado (evaluación de salvaguardas, participación comunitaria)' },
        },
      ],
    },
    {
      key: 'costs',
      title: { en: '3. Estimated costs & counterpart', es: '3. Costos estimados y contraparte' },
      fields: [
        {
          key: 'costo_total_estimado_proyecto', type: 'text',
          label: { en: 'Estimated total project cost (implementation phase)', es: 'Costo total estimado del proyecto (etapa de implementación)' },
        },
        {
          key: 'monto_grant_ustda_solicitado', type: 'text',
          label: { en: 'USTDA grant amount requested (for the study/mission itself)', es: 'Monto de grant solicitado a USTDA (para el estudio/misión en sí)' },
        },
        {
          key: 'tipo_contraparte_local', type: 'select',
          label: { en: 'Local counterpart contribution available', es: 'Contraparte local disponible' },
          options: [
            { value: 'efectivo', en: 'Cash', es: 'Efectivo' },
            { value: 'especie', en: 'In-kind', es: 'En especie' },
            { value: 'ambas', en: 'Both', es: 'Ambas' },
            { value: 'ninguna_aun', en: 'None yet', es: 'Ninguna todavía' },
          ],
        },
        {
          key: 'descripcion_contraparte', type: 'textarea',
          label: { en: 'Description of the local counterpart contribution', es: 'Descripción de la contraparte local' },
        },
      ],
    },
    {
      key: 'followon',
      title: { en: '4. Anticipated follow-on financing', es: '4. Financiamiento de seguimiento previsto' },
      fields: [
        {
          key: 'fuentes_financiamiento_previstas', type: 'textarea',
          label: { en: 'Anticipated sources of financing for implementation (e.g. DFC, EXIM Bank, multilateral development banks, capital markets, private investment)', es: 'Fuentes de financiamiento previstas para la implementación (ej. DFC, EXIM Bank, bancos multilaterales de desarrollo, mercado de capitales, inversión privada)' },
        },
        {
          key: 'cronograma_estimado', type: 'text',
          label: { en: 'Estimated timeline (study + implementation)', es: 'Cronograma estimado (estudio + implementación)' },
        },
      ],
    },
    {
      key: 'governance',
      title: { en: '5. Contacts & follow-up', es: '5. Contactos y seguimiento' },
      fields: [
        {
          key: 'punto_contacto_entidad', type: 'text',
          label: { en: 'Point of contact at the requesting entity', es: 'Punto de contacto en la entidad solicitante' },
        },
        {
          key: 'punto_contacto_ustda', type: 'text',
          label: { en: 'USTDA regional office / point of contact, if known', es: 'Oficina regional / punto de contacto de USTDA, si se conoce' },
        },
        {
          key: 'mecanismos_seguimiento', type: 'textarea',
          label: { en: 'Planned monitoring/reporting mechanisms', es: 'Mecanismos de seguimiento/reporte previstos' },
        },
      ],
    },
  ],
  notesField: {
    key: 'notas_adicionales',
    label: { en: 'Additional notes (related USTDA activities in the region, specific eligibility conditions, etc.)', es: 'Notas adicionales (actividades de USTDA relacionadas en la región, condiciones de elegibilidad específicas, etc.)' },
  },
};

const PROGRAM_TEMPLATES = {
  capital_markets_debt_financing: CAPITAL_MARKETS_TEMPLATE,
  wholesale_neutral_network_program: WHOLESALE_NEUTRAL_NETWORK_PROGRAM_TEMPLATE,
  tasu_subsidized_rate_credit: TASU_TEMPLATE,
  fatic_general_equipment_provision: FATIC_GENERAL_TEMPLATE,
  emergencias_catastrofes: EMERGENCIAS_CATASTROFES_TEMPLATE,
  conectividad_interes_publico: CIP_TEMPLATE,
  ustda_project_preparation: USTDA_PREPARATION_TEMPLATE,
};

/* Bilingual catalog for the "Program template" dropdown on
   app/new-program.html — a Program owner can optionally tag their Program
   with one of these to make the matching guided form available to whoever
   submits a project under it. Kept as a short curated list (rather than
   letting anyone type a free-text key) so it only ever points at a
   template that actually exists in PROGRAM_TEMPLATES above. */
const PROGRAM_TEMPLATE_OPTIONS = [
  { value: 'capital_markets_debt_financing', en: 'Capital Markets Debt Financing (ENACOM FATIC — Res. 1191/25)', es: 'Financiamiento por Mercado de Capitales (ENACOM FATIC — Res. 1191/25)' },
  { value: 'wholesale_neutral_network_program', en: 'Red Mayorista Neutral (ENACOM — Res. 951/25)', es: 'Red Mayorista Neutral (ENACOM — Res. 951/25)' },
  { value: 'tasu_subsidized_rate_credit', en: 'Subsidized Rate Credit — TASU (ENACOM FATIC — Res. 1385/25)', es: 'Créditos a Tasa Subsidiada — TASU (ENACOM FATIC — Res. 1385/25)' },
  { value: 'fatic_general_equipment_provision', en: 'FATIC — General / Equipment Provision (ENACOM — Res. 950/25)', es: 'FATIC — General / Provisión de Equipamiento (ENACOM — Res. 950/25)' },
  { value: 'emergencias_catastrofes', en: 'Assistance for Emergencies & Disasters (ENACOM — Res. 449/21, updated Res. 323/25)', es: 'Asistencia ante Emergencias y Catástrofes (ENACOM — Res. 449/21, act. Res. 323/25)' },
  { value: 'conectividad_interes_publico', en: 'Public Interest Connectivity — C.I.P. (ENACOM — Res. 1072/24)', es: 'Conectividad de Interés Público — C.I.P. (ENACOM — Res. 1072/24)' },
  { value: 'ustda_project_preparation', en: 'USTDA Project Preparation Funding (standard, pending final version)', es: 'Financiamiento USTDA para Elaboración de Proyecto (estándar, pendiente versión definitiva)' },
];

/* The 35 sovereign states of the Americas — used by new-project.html's
   Country field (a <select>, not free text). `value` is always the
   canonical English name regardless of UI language, so projects.country
   stays consistent no matter which language a project was submitted in;
   countryLabel() below translates it back for display. */
const COUNTRIES_AMERICAS = [
  { value: 'Antigua and Barbuda', en: 'Antigua and Barbuda', es: 'Antigua y Barbuda' },
  { value: 'Argentina', en: 'Argentina', es: 'Argentina' },
  { value: 'Bahamas', en: 'Bahamas', es: 'Bahamas' },
  { value: 'Barbados', en: 'Barbados', es: 'Barbados' },
  { value: 'Belize', en: 'Belize', es: 'Belice' },
  { value: 'Bolivia', en: 'Bolivia', es: 'Bolivia' },
  { value: 'Brazil', en: 'Brazil', es: 'Brasil' },
  { value: 'Canada', en: 'Canada', es: 'Canadá' },
  { value: 'Chile', en: 'Chile', es: 'Chile' },
  { value: 'Colombia', en: 'Colombia', es: 'Colombia' },
  { value: 'Costa Rica', en: 'Costa Rica', es: 'Costa Rica' },
  { value: 'Cuba', en: 'Cuba', es: 'Cuba' },
  { value: 'Dominica', en: 'Dominica', es: 'Dominica' },
  { value: 'Dominican Republic', en: 'Dominican Republic', es: 'República Dominicana' },
  { value: 'Ecuador', en: 'Ecuador', es: 'Ecuador' },
  { value: 'El Salvador', en: 'El Salvador', es: 'El Salvador' },
  { value: 'Grenada', en: 'Grenada', es: 'Granada' },
  { value: 'Guatemala', en: 'Guatemala', es: 'Guatemala' },
  { value: 'Guyana', en: 'Guyana', es: 'Guyana' },
  { value: 'Haiti', en: 'Haiti', es: 'Haití' },
  { value: 'Honduras', en: 'Honduras', es: 'Honduras' },
  { value: 'Jamaica', en: 'Jamaica', es: 'Jamaica' },
  { value: 'Mexico', en: 'Mexico', es: 'México' },
  { value: 'Nicaragua', en: 'Nicaragua', es: 'Nicaragua' },
  { value: 'Panama', en: 'Panama', es: 'Panamá' },
  { value: 'Paraguay', en: 'Paraguay', es: 'Paraguay' },
  { value: 'Peru', en: 'Peru', es: 'Perú' },
  { value: 'Saint Kitts and Nevis', en: 'Saint Kitts and Nevis', es: 'San Cristóbal y Nieves' },
  { value: 'Saint Lucia', en: 'Saint Lucia', es: 'Santa Lucía' },
  { value: 'Saint Vincent and the Grenadines', en: 'Saint Vincent and the Grenadines', es: 'San Vicente y las Granadinas' },
  { value: 'Suriname', en: 'Suriname', es: 'Surinam' },
  { value: 'Trinidad and Tobago', en: 'Trinidad and Tobago', es: 'Trinidad y Tobago' },
  { value: 'United States', en: 'United States', es: 'Estados Unidos' },
  { value: 'Uruguay', en: 'Uruguay', es: 'Uruguay' },
  { value: 'Venezuela', en: 'Venezuela', es: 'Venezuela' },
];

const PROJECT_STATUS_LABELS = {
  submitted: { en: 'Submitted', es: 'Enviado' },
  analyzing: { en: 'Analyzing', es: 'Analizando' },
  completed: { en: 'Completed', es: 'Completado' },
  error: { en: 'Error', es: 'Error' },
};

/* A Program's "organization_type" — the public or private entity
   presenting it (e.g. a provincial government vs. a private operator or
   cooperative). See app/programs.html. */
const PROGRAM_ORG_TYPE_LABELS = {
  public: { en: 'Public', es: 'Público' },
  private: { en: 'Private', es: 'Privado' },
};

/* A Program's funding_stage — see the comment on public.programs.funding_stage
   in supabase/schema.sql. 'preparation' Programs (e.g. USTDA) fund
   elaborating/structuring the project itself; 'financing' Programs (FSU,
   BID, capital markets debt, TASU, etc. — the default) fund the project's
   actual implementation. Used to group the "Apply to Program" picker on
   project.html into two buckets. */
const PROGRAM_FUNDING_STAGE_LABELS = {
  preparation: {
    en: 'Project preparation funding',
    es: 'Financiamiento para la elaboración del proyecto',
  },
  financing: {
    en: 'Project financing',
    es: 'Financiamiento del proyecto',
  },
};

const PLATFORM_ROLE_LABELS = {
  user: { en: 'User', es: 'Usuario' },
  advisor: { en: 'Advisor', es: 'Asesor' },
  admin: { en: 'Admin', es: 'Admin' },
};

const READINESS_STAGE_LABELS = {
  // 'Not Analyzed' isn't a projects.readiness_stage value (that column is
  // simply null for it) — this entry exists so stageLabel() can translate
  // project_workflow_events.to_stage rows logged by
  // return_project_to_not_analyzed() (migration_v20), which does use the
  // literal string 'Not Analyzed' there.
  'Not Analyzed': { en: 'Not Analyzed', es: 'No Analizado' },
  'Concept Stage': { en: 'Concept Stage', es: 'Etapa de Concepto' },
  'Early Structuring': { en: 'Early Structuring', es: 'Estructuración Temprana' },
  'Advanced Structuring': { en: 'Advanced Structuring', es: 'Estructuración Avanzada' },
  'Investment Ready': { en: 'Investment Ready', es: 'Listo para Inversión' },
};

/* Project workflow (app/project.html "workflow stepper") — the ordered
   list of the same 4 stages above, walked one step at a time by an
   advisor via advanceProjectWorkflow() below. See
   supabase/migration_v12_workflow.sql for the full rationale. */
const STAGE_ORDER = ['Concept Stage', 'Early Structuring', 'Advanced Structuring', 'Investment Ready'];

/* Advisor specialization — unused/unenforced today (every advisor is
   general-purpose: "por el momento el advisor puede hacer todo"), but the
   profiles.specialization column and this label map already exist so that
   wiring in the technical/financial/administrative advisor roles later is
   a small follow-up, not a new migration. */
const SPECIALIZATION_LABELS = {
  technical: { en: 'Technical', es: 'Técnico' },
  financial: { en: 'Financial', es: 'Financiero' },
  administrative: { en: 'Administrative', es: 'Administrativo' },
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

/* Technical criticality — same 3-tier low/medium/high scale as
   PRIORITY_LABELS above (see migration_v33_project_attributes.sql), but a
   distinct axis: priority is about management urgency, criticality is about
   the impact of a technical failure or delay. Kept as its own dictionary
   (rather than reusing PRIORITY_LABELS's text) so the two read distinctly
   wherever both appear on the same screen (e.g. project.html's meta line). */
const CRITICALITY_LABELS = {
  high: { en: 'High Technical Criticality', es: 'Criticidad Técnica Alta' },
  medium: { en: 'Medium Technical Criticality', es: 'Criticidad Técnica Media' },
  low: { en: 'Low Technical Criticality', es: 'Criticidad Técnica Baja' },
};

// Duration unit for projects.duration_value — see migration_v33_project_attributes.sql.
const DURATION_UNIT_LABELS = {
  days: { en: 'days', es: 'días' },
  months: { en: 'months', es: 'meses' },
};

/* Project complexity — same low/medium/high scale as PRIORITY_LABELS/
   CRITICALITY_LABELS (see migration_v34_project_budget_complexity.sql), but
   a third distinct axis: intrinsic difficulty/entanglement of the project
   itself (moving parts, interdependencies, unproven technology), not
   management urgency (priority) or the impact of a technical failure
   (technical_criticality). Own label dictionary so it reads distinctly
   wherever shown alongside those two. */
const COMPLEXITY_LABELS = {
  high: { en: 'High Complexity', es: 'Complejidad Alta' },
  medium: { en: 'Medium Complexity', es: 'Complejidad Media' },
  low: { en: 'Low Complexity', es: 'Complejidad Baja' },
};

/* The 9 Multilateral Finance Navigator™ mechanism names — both
   /api/analyze-project.js's FINANCING_MECHANISMS list (AI path) and this
   file's STAGE_FINANCING_SUGGESTION/USF_SUGGESTION (manual-assessment
   path) always write one of these exact English strings into
   framework_analysis.financing_recommendations[].mechanism, regardless of
   UI language — it's used as a stable key, not display text. Translated
   here at render time instead (project.html calls financeMechanismLabel()
   rather than printing item.mechanism directly), reusing the same Spanish
   wording as the public finance.html page. */
const MECHANISM_LABELS = {
  'Multilateral Development Banks': { en: 'Multilateral Development Banks', es: 'Bancos Multilaterales de Desarrollo' },
  'Development Finance Institutions': { en: 'Development Finance Institutions', es: 'Instituciones de Financiamiento para el Desarrollo' },
  'Project Finance': { en: 'Project Finance', es: 'Project Finance' },
  'Public-Private Partnerships': { en: 'Public-Private Partnerships', es: 'Asociaciones Público-Privadas' },
  'Blended Finance': { en: 'Blended Finance', es: 'Finanzas Mixtas' },
  'Guarantees & Credit Enhancement': { en: 'Guarantees & Credit Enhancement', es: 'Garantías y Mejora Crediticia' },
  'Export Credit Agencies': { en: 'Export Credit Agencies', es: 'Agencias de Crédito a la Exportación' },
  'Commercial & Institutional Capital': { en: 'Commercial & Institutional Capital', es: 'Capital Comercial e Institucional' },
  'Universal Service Funds': { en: 'Universal Service Funds', es: 'Fondos de Servicio Universal' },
  'Capital Markets Debt Instruments': { en: 'Capital Markets Debt Instruments', es: 'Instrumentos de Deuda en el Mercado de Capitales' },
  'Subsidized Rate Credit': { en: 'Subsidized Rate Credit', es: 'Créditos a Tasa Subsidiada' },
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
  wholesale_neutral_network: 'neutrality_interconnection_readiness',
  ai_datacenter: 'power_cooling_readiness',
  satellite_constellation: 'orbital_spectrum_coordination',
  early_warning_system: 'alert_dissemination_readiness',
  passive_infrastructure: 'shared_access_readiness',
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
  neutrality_interconnection_readiness: { en: 'Neutrality & Interconnection Readiness', es: 'Preparación de Neutralidad e Interconexión' },
  power_cooling_readiness: { en: 'Power & Cooling Readiness', es: 'Preparación de Energía y Refrigeración' },
  orbital_spectrum_coordination: { en: 'Orbital & Spectrum Coordination', es: 'Coordinación Orbital y de Espectro' },
  alert_dissemination_readiness: { en: 'Alert Dissemination Readiness', es: 'Preparación de Difusión de Alertas' },
  shared_access_readiness: { en: 'Shared Access & Interoperability Readiness', es: 'Preparación de Acceso Compartido e Interoperabilidad' },
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
  wholesale_neutral_network: [
    { en: 'The network topology, dimensioning and scalability plan have been technically designed and documented.', es: 'La topología, el dimensionamiento y el plan de escalabilidad de la red están diseñados y documentados técnicamente.' },
    { en: 'The network is designed for open, non-discriminatory multi-operator access, with interconnection to REFEFO or other wholesale networks planned or secured.', es: 'La red está diseñada para acceso abierto y no discriminatorio multioperador, con interconexión a la REFEFO u otras redes mayoristas planificada o asegurada.' },
    { en: 'An active or passive network sharing scheme (e.g. RAN sharing) and a post-deployment operation & maintenance plan are defined.', es: 'Está definido un esquema de compartición de red activa o pasiva (ej. RAN sharing) y un plan de operación y mantenimiento posterior al despliegue.' },
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
  early_warning_system: [
    { en: 'The dissemination technology and standard (Cell Broadcast/CAP, EAS-style interruption, etc.) are defined and the target dissemination time is documented.', es: 'La tecnología y el estándar de difusión (Cell Broadcast/CAP, interrupción estilo EAS, etc.) están definidos y el tiempo objetivo de difusión está documentado.' },
    { en: 'Coordination with hazard-detection sources (meteorological/seismological service, civil defense) and dissemination partners (mobile operators, broadcasters) is secured or well advanced.', es: 'La coordinación con las fuentes de detección de riesgo (servicio meteorológico/sismológico, defensa civil) y los socios de difusión (operadores móviles, radiodifusores) está asegurada o muy avanzada.' },
    { en: 'A redundancy/resilience plan and a periodic testing & public awareness plan exist for the system.', es: 'Existe un plan de redundancia/resiliencia y un plan de pruebas periódicas y concientización pública para el sistema.' },
  ],
  passive_infrastructure: [
    { en: 'The passive assets to be shared (poles, ducts, chambers, towers, dark fiber, etc.) are inventoried, with owner, location, capacity and technical condition documented.', es: 'Los activos pasivos a compartir (postes, ductos, cámaras, torres, fibra oscura, etc.) están inventariados, con propietario, ubicación, capacidad y estado técnico documentados.' },
    { en: 'Access/sharing agreements or a clear regulatory path with the infrastructure owner(s) are in place, under non-discriminatory and technically viable conditions.', es: 'Existen acuerdos de acceso/comparticion o un camino regulatorio claro con el/los propietario/s de la infraestructura, en condiciones no discriminatorias y técnicamente viables.' },
    { en: 'A cost-based tariff or remuneration methodology for using the shared infrastructure is defined or referenced.', es: 'Está definida o referenciada una metodología de tarifa o remuneración basada en costos para el uso de la infraestructura compartida.' },
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
  neutrality_interconnection_readiness: { en: 'Finalize the network topology/dimensioning design and secure REFEFO interconnection and a network-sharing (RAN sharing) scheme — these are the criteria ENACOM weighs most heavily for Red Mayorista Neutral eligibility.', es: 'Finalizá el diseño de topología/dimensionamiento de la red y asegurá la interconexión con la REFEFO y un esquema de compartición de red (RAN sharing) — son los criterios que ENACOM pondera con más peso para la elegibilidad de la Red Mayorista Neutral.' },
  power_cooling_readiness: { en: 'Contract power capacity and finalize the cooling design early — these typically drive the critical path.', es: 'Contratá la capacidad eléctrica y finalizá el diseño de refrigeración temprano — suelen definir el camino crítico.' },
  orbital_spectrum_coordination: { en: 'Advance orbital/frequency coordination filings and lock in launch provider terms — both have long regulatory lead times.', es: 'Avanzá las presentaciones de coordinación orbital/frecuencia y cerrá los términos con el proveedor de lanzamiento — ambos tienen plazos regulatorios largos.' },
  alert_dissemination_readiness: { en: 'Lock down the dissemination technology/standard and formalize coordination agreements with hazard-detection sources and mobile operators/broadcasters early — track each one in the project\'s Roadmaps checklist.', es: 'Definí la tecnología/estándar de difusión y formalizá temprano los convenios de coordinación con las fuentes de detección de riesgo y los operadores móviles/radiodifusores — trackealos en el checklist de Hojas de ruta del proyecto.' },
  shared_access_readiness: { en: 'Complete the asset inventory and formalize access/sharing agreements (or the regulatory path to them) with each infrastructure owner before committing to a deployment timeline.', es: 'Completá el inventario de activos y formalizá los acuerdos de acceso/comparticion (o el camino regulatorio hacia ellos) con cada propietario de infraestructura antes de comprometer un cronograma de despliegue.' },
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
const USF_ELIGIBLE_TYPES = ['fiber_backbone_last_mile', 'fixed_wireless_access', 'wholesale_neutral_network'];

function stageForScore(score) {
  if (score <= 25) return 'Concept Stage';
  if (score <= 50) return 'Early Structuring';
  if (score <= 75) return 'Advanced Structuring';
  return 'Investment Ready';
}

/* Picks the right-language text out of a framework_analysis row — see
   migration_v40_bilingual_analysis.sql. dimensions/gap_roadmap/
   financing_recommendations/summary (unsuffixed) are always Spanish; the
   _en columns are the English translation, written by
   /api/analyze-project.js for any analysis run after that migration, and
   otherwise null (not translated yet). Falls back to the Spanish field
   whenever the English one is missing/empty for a given item, so English
   viewers of an untranslated (or partially translated) analysis still see
   real text instead of a blank — never mixed with the manual-assessment
   recompute path in app/project.html, which already produces text in the
   current language directly and has no _en columns to look at (their
   absence just means every fallback below resolves to the value already
   computed in the right language, a no-op).
   `a` can be null/undefined (nothing analyzed yet) — passed straight
   through. */
function localizeAnalysis(a, lang) {
  if (!a) return a;
  if (lang !== 'en') return a;

  const dims = a.dimensions || {};
  const dimsEn = a.dimensions_en || {};
  const dimensions = {};
  Object.keys(dims).forEach((key) => {
    const es = dims[key] || {};
    const en = dimsEn[key] || {};
    dimensions[key] = {
      score: es.score,
      rationale: en.rationale || es.rationale,
    };
  });

  const gapEn = Array.isArray(a.gap_roadmap_en) ? a.gap_roadmap_en : [];
  const gapRoadmap = (a.gap_roadmap || []).map((item, i) => ({
    priority: item.priority,
    action: (gapEn[i] && gapEn[i].action) || item.action,
  }));

  const finEn = Array.isArray(a.financing_recommendations_en) ? a.financing_recommendations_en : [];
  const financingRecommendations = (a.financing_recommendations || []).map((item, i) => ({
    mechanism: item.mechanism,
    rationale: (finEn[i] && finEn[i].rationale) || item.rationale,
  }));

  return Object.assign({}, a, {
    dimensions,
    gap_roadmap: gapRoadmap,
    financing_recommendations: financingRecommendations,
    summary: a.summary_en || a.summary,
  });
}

/* Maps a raw 0-100 Investment Readiness Index™ score straight to the same
   'stage-concept'/'stage-early'/'stage-advanced'/'stage-ready' CSS suffix
   effectiveStatusClass() derives from a project's workflow readiness_stage
   (see .status-pill.stage-* in assets/style.css) — single source of truth
   for the score->color bands (<=25 / <=50 / <=75 / >75) so any UI that
   wants to color-code a raw score (e.g. dashboard.html's per-row Self-
   Assessment/AI Analysis badges) reuses stageForScore()'s exact thresholds
   instead of re-deriving them. Returns '' for a null/non-numeric score. */
function scoreBandClass(score) {
  const n = Number(score);
  if (score == null || Number.isNaN(n)) return '';
  const byStage = {
    'Concept Stage': 'stage-concept',
    'Early Structuring': 'stage-early',
    'Advanced Structuring': 'stage-advanced',
    'Investment Ready': 'stage-ready',
  };
  return byStage[stageForScore(n)] || '';
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
   applying to the Fondo de Servicio Universal (FSU). Originally offered
   only for fiber-to-the-home / last-mile projects (the criteria — GPON/
   XGS-PON, splitter ratios, fiber-penetration math — only make sense for
   FTTx), it's now also offered to any project applying under the Programa
   "Financiamiento y Apoyo a Proveedores de Servicios de TIC" (FATIC, Res.
   ENACOM 950/25) umbrella — Mercado de Capitales, TASU or the general/
   equipment línea — since all three are FSU-funded financing lines that
   span whatever infrastructure category the applicant is pursuing (see
   PLATFORM_SETUP.md's "Program-level templates" section). See the
   fsu_scoring table comment in supabase/schema.sql for the full citation
   and rationale. */

const FSU_SCORING_ELIGIBLE_TYPE = 'fiber_backbone_last_mile';

/* The three FATIC (Financiamiento y Apoyo a Proveedores de Servicios de
   TIC) program-level template_keys — see PROGRAM_TEMPLATES above. A
   project applying under a Program tagged with any of these also unlocks
   FSU Scoring, regardless of its own project_type. */
const FSU_SCORING_ELIGIBLE_PROGRAM_TEMPLATES = [
  'capital_markets_debt_financing',
  'tasu_subsidized_rate_credit',
  'fatic_general_equipment_provision',
];

/* Single source of truth for "does this project get the FSU Scoring tab?" —
   used by app/project.html (to show/hide the link) and app/fsu-scoring.html
   (to guard the page itself). `project` is a row from getProject()/
   listProjects(), which embeds `programs(name, template_key)`. */
function isFsuScoringEligible(project) {
  if (!project) return false;
  if (project.project_type === FSU_SCORING_ELIGIBLE_TYPE) return true;
  const templateKey = project.programs && project.programs.template_key;
  return FSU_SCORING_ELIGIBLE_PROGRAM_TEMPLATES.includes(templateKey);
}

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

/* Turns a filled-in project-template answer set (see PROJECT_TEMPLATES)
   into a structured plain-text block, ready to drop into (or prepend to)
   the free-text projects.description field. Skips any section/field left
   blank entirely, so a partially-filled template still compiles cleanly.
   `answers` is a flat { fieldKey: value } object (select fields store the
   option value; compiled here to the option's localized label). */
function compileTemplateAnswers(template, answers, lang) {
  if (!template || !answers) return '';
  const L = lang === 'es' ? 'es' : 'en';
  const heading = template.title[L] || template.title.en;
  const lines = [`${heading.toUpperCase()}`];
  template.sections.forEach((section) => {
    const fieldLines = [];
    section.fields.forEach((field) => {
      const raw = answers[field.key];
      if (raw === undefined || raw === null || String(raw).trim() === '') return;
      const label = (field.label[L] || field.label.en);
      let value = raw;
      if (field.type === 'select') {
        const opt = (field.options || []).find((o) => o.value === raw);
        value = opt ? (opt[L] || opt.en) : raw;
      }
      fieldLines.push(`- ${label}: ${value}`);
    });
    if (fieldLines.length) {
      const secTitle = section.title[L] || section.title.en;
      lines.push('', secTitle, ...fieldLines);
    }
  });
  if (template.notesField) {
    const notes = answers[template.notesField.key];
    if (notes && String(notes).trim()) {
      const notesLabel = template.notesField.label[L] || template.notesField.label.en;
      lines.push('', notesLabel, notes.trim());
    }
  }
  return lines.join('\n');
}

/* Flattens a template's {sections:[{fields:[...]}]} shape into one array of
   {key, label, type, options} — used both to build a "which fields does
   this template have" list for the shared-answer pool (see
   mergeSharedFieldAnswers()/autofillTemplateAnswers() below) and to send
   to /api/extract-template-data.js. `label`/`options` are resolved to the
   current UI language (a plain string / array of {value,label}) since
   that's all the extraction endpoint and the pool need — the template
   registry's bilingual {en,es} shape is purely a UI concern otherwise.
   Deliberately excludes notesField — it's a free-form catch-all, not a
   discrete fact worth extracting or caching in the pool. */
function flattenTemplateFields(template, lang) {
  if (!template) return [];
  const L = lang === 'es' ? 'es' : 'en';
  const out = [];
  template.sections.forEach((section) => {
    section.fields.forEach((field) => {
      out.push({
        key: field.key,
        label: field.label[L] || field.label.en,
        type: field.type,
        options: field.type === 'select'
          ? (field.options || []).map((o) => ({ value: o.value, label: o[L] || o.en }))
          : undefined,
      });
    });
  });
  return out;
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
  COUNTRIES_AMERICAS,
  PROJECT_STATUS_LABELS,
  PROGRAM_ORG_TYPE_LABELS,
  READINESS_STAGE_LABELS,
  DIMENSION_LABELS,
  DIMENSION_ORDER,
  TYPE_DIMENSION_LABELS,
  TYPE_DIMENSION_KEY,
  PRIORITY_LABELS,
  CRITICALITY_LABELS,
  DURATION_UNIT_LABELS,
  COMPLEXITY_LABELS,
  MECHANISM_LABELS,
  STATUS_FILTER_VALUES,
  PLATFORM_ROLE_LABELS,
  currentLang,

  dimensionLabel(key) {
    return dimLabelLookup(key, currentLang());
  },
  /* Financing mechanism names are stored as a stable English key in
     framework_analysis.financing_recommendations[].mechanism (both the AI
     and manual-assessment paths — see the comment above
     MECHANISM_LABELS). Always render through this rather than printing
     the raw value, so it follows the UI language like everything else. */
  financeMechanismLabel(value) {
    const entry = MECHANISM_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },
  assessmentQuestionSet,
  computeManualAssessment,
  priorityLabel(value) {
    const entry = PRIORITY_LABELS[(value || '').toLowerCase()];
    return entry ? entry[currentLang()] : value;
  },
  technicalCriticalityLabel(value) {
    const entry = CRITICALITY_LABELS[(value || '').toLowerCase()];
    return entry ? entry[currentLang()] : value;
  },
  durationUnitLabel(value) {
    const entry = DURATION_UNIT_LABELS[(value || '').toLowerCase()];
    return entry ? entry[currentLang()] : value;
  },
  // "18 months" / "18 meses" — null if no value is set (duration is
  // entirely optional). Ignores duration_unit if duration_value is set but
  // duration_unit isn't (falls back to just the number).
  formatDuration(value, unit) {
    if (value == null || value === '') return null;
    const unitLabel = unit ? this.durationUnitLabel(unit) : '';
    return unitLabel ? `${value} ${unitLabel}` : `${value}`;
  },
  complexityLabel(value) {
    const entry = COMPLEXITY_LABELS[(value || '').toLowerCase()];
    return entry ? entry[currentLang()] : value;
  },
  // "ARS 12,000,000" / "ARS 12.000.000" — used for both budget_amount and
  // fsu_amount so the two render identically. Null if no value is set.
  formatCurrency(value) {
    if (value == null || value === '') return null;
    return 'ARS ' + Number(value).toLocaleString(currentLang() === 'es' ? 'es-AR' : 'en-US');
  },
  // "USD 70,000,000" / "USD 70.000.000" — used for budget_amount_usd and
  // fsu_amount_usd (migration_v38_usd_amounts.sql). Same formatting
  // convention as formatCurrency() above, just with the USD prefix. Null
  // if no value is set.
  formatCurrencyUSD(value) {
    if (value == null || value === '') return null;
    return 'USD ' + Number(value).toLocaleString(currentLang() === 'es' ? 'es-AR' : 'en-US');
  },
  // ARS-equivalent of a USD figure using project.exchange_rate — purely a
  // display helper (see migration_v38_usd_amounts.sql). Returns null
  // unless both usdValue and exchangeRate are present and > 0; never
  // writes back to budget_amount/fsu_amount, so the "real" ARS fields
  // stay whatever the user explicitly entered (or empty).
  usdToArs(usdValue, exchangeRate) {
    if (usdValue == null || usdValue === '' || !exchangeRate) return null;
    const n = Number(usdValue) * Number(exchangeRate);
    return Number.isFinite(n) ? n : null;
  },

  // FSU Scoring (ENACOM Resolución 359/2025) reference data + pure scoring
  // function — see the section above for full documentation.
  FSU_SCORING_ELIGIBLE_TYPE,
  FSU_SCORING_ELIGIBLE_PROGRAM_TEMPLATES,
  isFsuScoringEligible,
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

  /* Programs can only be created by an advisor or admin — see
     supabase/migration_v19_program_permissions.sql for the RLS policy that
     actually enforces this (programs_insert_advisor_or_admin). Used by
     app/programs.html, app/new-program.html and app/new-project.html to
     hide the "Create Program" entry points from standard users, rather than
     letting them fill out the whole form and hit a permission error on
     submit. Any signed-in user — including standard users — can still SEE
     every Program and associate a project with one; only creating a new
     Program is restricted. */
  canManagePrograms(profile) {
    return this.isAdvisor(profile) || this.isAdmin(profile);
  },

  /* Same advisor-or-admin bar as canManagePrograms above, named separately
     for the "Roadmaps" checklist feature (see
     supabase/migration_v26_gestion_templates.sql) — a project owner can see
     their own project's roadmap checklist (read-only), but only an
     advisor/admin can browse/edit roadmap_templates or write to
     project_roadmaps; enforced by RLS regardless of what the UI hides. */
  canManageRoadmaps(profile) {
    return this.isAdvisor(profile) || this.isAdmin(profile);
  },

  platformRoleLabel(value) {
    const entry = PLATFORM_ROLE_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },

  roleTypeLabel(value) { return labelFor(ROLE_TYPES, value, currentLang()); },
  projectTypeLabel(value) { return labelFor(PROJECT_TYPES, value, currentLang()); },
  DOCUMENT_TYPES,
  documentTypeLabel(value) { return labelFor(DOCUMENT_TYPES, value, currentLang()); },
  ROADMAP_ENTITY_TYPES,
  roadmapEntityTypeLabel(value) { return labelFor(ROADMAP_ENTITY_TYPES, value, currentLang()); },
  ROADMAP_STATUS,
  roadmapStatusLabel(value) { return labelFor(ROADMAP_STATUS, value, currentLang()); },
  ENTITY_TYPES,
  entityTypeLabel(value) { return labelFor(ENTITY_TYPES, value, currentLang()); },
  ROADMAP_INSTANCE_STEP_STATUS,
  roadmapInstanceStepStatusLabel(value) { return labelFor(ROADMAP_INSTANCE_STEP_STATUS, value, currentLang()); },
  ROADMAP_INSTANCE_STATUS,
  roadmapInstanceStatusLabel(value) { return labelFor(ROADMAP_INSTANCE_STATUS, value, currentLang()); },
  /* Guided project-submission templates (see PROJECT_TEMPLATES above).
     Returns undefined for project types without a template — callers use
     that to decide whether to show a "Fill using template" link. */
  PROJECT_TEMPLATES,
  projectTemplateFor(projectType) { return PROJECT_TEMPLATES[projectType]; },
  /* Program-level counterpart to projectTemplateFor() above — see
     PROGRAM_TEMPLATES for why this exists as a separate registry keyed by
     programs.template_key rather than folded into PROJECT_TEMPLATES. */
  PROGRAM_TEMPLATES,
  programTemplateFor(templateKey) { return PROGRAM_TEMPLATES[templateKey]; },
  PROGRAM_TEMPLATE_OPTIONS,
  programTemplateLabel(value) { return labelFor(PROGRAM_TEMPLATE_OPTIONS, value, currentLang()); },
  compileTemplateAnswers(template, answers) { return compileTemplateAnswers(template, answers, currentLang()); },
  /* Translates a stored projects.country value (always the English
     canonical name, see COUNTRIES_AMERICAS) back to the current UI
     language. Falls back to the raw value for any pre-existing free-text
     country that predates this select (doesn't match the curated list). */
  countryLabel(value) { return labelFor(COUNTRIES_AMERICAS, value, currentLang()); },
  statusLabel(value) {
    const entry = PROJECT_STATUS_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },
  stageLabel(value) {
    const entry = READINESS_STAGE_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },
  /* See localizeAnalysis() above — picks the right-language text out of a
     framework_analysis row, with automatic fallback to Spanish for
     anything not yet translated (migration_v40_bilingual_analysis.sql). */
  localizeAnalysis(a, lang) { return localizeAnalysis(a, lang); },
  effectiveStatusValue,
  effectiveStatusLabel,
  effectiveStatusClass,
  statusFilterLabel,
  scoreBandClass,

  /* Sends a confirmation email with a link to app/email-confirmed.html
     (see emailRedirectTo below) — requires "Confirm email" to be turned on
     in Supabase (Authentication → Providers → Email) and that URL to be
     added to Supabase's Redirect URLs allowlist (Authentication → URL
     Configuration) — see PLATFORM_SETUP.md. With that setting on, the
     returned data.session is null until the user clicks the link; the
     caller (register.html) checks for that and shows a "check your email"
     message instead of redirecting straight into the app. With "Confirm
     email" off (the platform's original behavior), Supabase still sends
     nothing and returns a session immediately, so nothing here changes
     for that configuration.

     Also checks for an already-registered email and throws a normalized
     error (err.code === 'email_already_registered') either way, so
     register.html can show one consistent "an account already exists"
     message regardless of the Confirm email setting:
       - With "Confirm email" OFF, Supabase rejects the duplicate outright
         with an error (message varies by version — "User already
         registered" and similar).
       - With "Confirm email" ON, Supabase deliberately does NOT return an
         error for a duplicate email — signUp() "succeeds" with no error,
         but data.user.identities comes back as an empty array (no new
         identity was actually created) instead of the usual one-element
         array. This is Supabase's documented way to detect a duplicate
         signup without letting the response itself reveal whether an email
         is registered (an anti-enumeration measure) — see PLATFORM_SETUP.md. */
  async signUp({ email, password, fullName, organization, roleType }) {
    if (!supabaseClient) throw new Error('Platform not configured yet.');
    const emailRedirectTo = `${location.origin}/app/email-confirmed.html`;
    const { data, error } = await supabaseClient.auth.signUp({
      email,
      password,
      options: {
        data: { full_name: fullName, organization, role_type: roleType },
        emailRedirectTo,
      },
    });
    if (error) {
      if (/already registered|already exists|user_already_exists/i.test(error.message || error.code || '')) {
        const dupErr = new Error(error.message);
        dupErr.code = 'email_already_registered';
        throw dupErr;
      }
      throw error;
    }
    if (data && data.user && Array.isArray(data.user.identities) && data.user.identities.length === 0) {
      const dupErr = new Error('Email already registered.');
      dupErr.code = 'email_already_registered';
      throw dupErr;
    }
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
     Scores the questionnaire client-side (computeManualAssessment above)
     and writes it as a framework_analysis row tagged source='manual'
     (allowed by the analysis_insert_own_manual RLS policy — see
     supabase/migration_v5_manual_assessment.sql). Always sets
     status='completed' so the results panel shows the fresh score/gap
     roadmap ("Próximos pasos").

     readiness_stage handling changed with migration_v20 (the
     promote/demote workflow): this used to always overwrite
     projects.readiness_stage with the score-derived stage (result.stage),
     same as a completed AI analysis. Now the workflow stage is driven
     entirely by explicit owner/advisor actions, not by the score — so
     this only sets readiness_stage the FIRST time (when the project is
     still Not Analyzed / currentReadinessStage is null), moving it to
     'Concept Stage' as specified, and leaves it untouched on every
     subsequent re-run (e.g. re-assessing while already in Concept Stage,
     or later) so a fresh self-assessment can never silently move — let
     alone regress — a project an advisor has already promoted. Callers
     (app/assessment.html) must pass the project's current
     readiness_stage. */
  async submitManualAssessment(projectId, projectType, answers, { beneficiaryCount, currentReadinessStage } = {}) {
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

    const projectUpdate = {
      status: 'completed',
      updated_at: new Date().toISOString(),
    };
    if (!currentReadinessStage) {
      projectUpdate.readiness_stage = 'Concept Stage';
    }
    const { error: updateError } = await supabaseClient
      .from('projects')
      .update(projectUpdate)
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

  /* Batch version for dashboard.html's project grid — one query for every
     row instead of one per project (same pattern as
     listProjectProgramsForProjects above). fsu_scoring has a `unique
     (project_id)` constraint, so this is a flat Map keyed by project_id
     (at most one row per project), not an array. Only score_total is
     needed to render the dashboard badge, but the whole row is returned in
     case a caller wants more later. */
  async listFsuScoringForProjects(projectIds) {
    const ids = (projectIds || []).filter(Boolean);
    const map = new Map();
    if (!ids.length) return map;
    const { data, error } = await supabaseClient
      .from('fsu_scoring')
      .select('*')
      .in('project_id', ids);
    if (error) throw error;
    (data || []).forEach((row) => map.set(row.project_id, row));
    return map;
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
     who submitted each project.

     projects now has TWO foreign keys into profiles (user_id, the owner,
     and assigned_advisor_id — see supabase/migration_v12_workflow.sql), so
     an unqualified `profiles(...)` embed is ambiguous to PostgREST; both
     embeds below are qualified by the FK CONSTRAINT name
     (`profiles!projects_user_id_fkey`) to disambiguate.

     Tried the FK COLUMN name (`profiles!user_id`) first — PostgREST is
     documented to accept either, but on this project's PostgREST version
     it still errored PGRST201 "more than one relationship was found",
     confirmed from the browser console. The constraint name is the more
     reliable form; Postgres auto-names an unnamed inline `references`
     constraint as `<table>_<column>_fkey`, which is exactly what both
     constraints below were created as (see supabase/schema.sql /
     migration_v12_workflow.sql — neither FK was given an explicit name). */
  async listProjects() {
    const { data, error } = await supabaseClient
      .from('projects')
      .select('*, profiles!projects_user_id_fkey(full_name, organization), programs(name, template_key)')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  },

  async getProject(id) {
    const { data, error } = await supabaseClient
      .from('projects')
      .select(`
        *,
        profiles!projects_user_id_fkey(full_name, organization),
        assigned_advisor:profiles!projects_assigned_advisor_id_fkey(full_name, organization),
        programs(name, template_key)
      `)
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  /* A project is always a single type (projectType) — it drives the 9th,
     type-specific dimension in the self-assessment questionnaire and the
     dashboard's type icon. Multi-component initiatives are modeled as a
     Program containing several single-type projects (see "Programs"
     section below and supabase/migration_v9_programs.sql), not as one
     project with several types — see supabase/migration_v10_remove_secondary_types.sql. */
  /* beneficiaryCount is optional — households/beneficiaries reached (the
     key impact metric for Universal Service Fund-style submissions, see
     supabase/migration_v7_beneficiary_count.sql). Null/undefined is
     stored as null. */
  /* programId is optional — groups this project under a Program (see
     "Programs" section below and supabase/migration_v9_programs.sql).
     Null/undefined/empty string all store as null (standalone project). */
  /* generatingEntityName/generatingEntityType describe who submitted this
     project and what kind of organization they are (see
     migration_v27_gestion_instances.sql) — purely informational, also used
     to suggest matching Roadmap templates whose allowed_entity_type
     matches. Both optional. */
  async createProject({ name, projectType, programId, country, description, beneficiaryCount, generatingEntityName, generatingEntityType, durationValue, durationUnit, priority, technicalCriticality, fsuAmount, fsuAmountUsd, fsuScope, fsuPercentage, budgetAmount, budgetAmountUsd, exchangeRate, exchangeRateDate, complexity, otherFinancingPercentage, otherFinancingAmount, otherFinancingNotes }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const { data, error } = await supabaseClient
      .from('projects')
      .insert({
        user_id: session.user.id,
        name,
        project_type: projectType,
        program_id: programId || null,
        country,
        description,
        beneficiary_count: beneficiaryCount === '' || beneficiaryCount == null ? null : Number(beneficiaryCount),
        generating_entity_name: generatingEntityName || null,
        generating_entity_type: generatingEntityType || null,
        duration_value: durationValue === '' || durationValue == null ? null : Number(durationValue),
        duration_unit: durationUnit || null,
        priority: priority || null,
        technical_criticality: technicalCriticality || null,
        fsu_amount: fsuAmount === '' || fsuAmount == null ? null : Number(fsuAmount),
        // USD twin of fsu_amount — see migration_v38_usd_amounts.sql.
        // Independent, not derived from fsu_amount.
        fsu_amount_usd: fsuAmountUsd === '' || fsuAmountUsd == null ? null : Number(fsuAmountUsd),
        fsu_scope: fsuScope || null,
        // Financing mix (migration_v35_financing_mix.sql) — fsu_percentage
        // and other_financing_* complement fsu_amount/fsu_scope above; the
        // per-Program share of the mix lives on project_programs.
        // financing_percentage/financing_amount instead (set via
        // applyToProgram/updateProjectProgramFinancing, not here).
        fsu_percentage: fsuPercentage === '' || fsuPercentage == null ? null : Number(fsuPercentage),
        budget_amount: budgetAmount === '' || budgetAmount == null ? null : Number(budgetAmount),
        // USD twin of budget_amount — see migration_v38_usd_amounts.sql.
        // Independent, not derived from budget_amount.
        budget_amount_usd: budgetAmountUsd === '' || budgetAmountUsd == null ? null : Number(budgetAmountUsd),
        // Shared ARS-per-USD rate used to render an equivalent for
        // budget_amount_usd/fsu_amount_usd — see
        // migration_v38_usd_amounts.sql. Never derived automatically.
        exchange_rate: exchangeRate === '' || exchangeRate == null ? null : Number(exchangeRate),
        exchange_rate_date: exchangeRateDate || null,
        complexity: complexity || null,
        other_financing_percentage: otherFinancingPercentage === '' || otherFinancingPercentage == null ? null : Number(otherFinancingPercentage),
        // Same "other" bucket, as an absolute amount instead of a % — see
        // migration_v37_financing_amounts.sql. Independent of
        // other_financing_percentage above (same convention as
        // fsu_amount/fsu_percentage).
        other_financing_amount: otherFinancingAmount === '' || otherFinancingAmount == null ? null : Number(otherFinancingAmount),
        other_financing_notes: otherFinancingNotes || null,
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
  async updateProject(id, { name, projectType, programId, country, description, beneficiaryCount, generatingEntityName, generatingEntityType, durationValue, durationUnit, priority, technicalCriticality, fsuAmount, fsuAmountUsd, fsuScope, fsuPercentage, budgetAmount, budgetAmountUsd, exchangeRate, exchangeRateDate, complexity, otherFinancingPercentage, otherFinancingAmount, otherFinancingNotes }) {
    const { data, error } = await supabaseClient
      .from('projects')
      .update({
        name,
        project_type: projectType,
        program_id: programId || null,
        country,
        description,
        beneficiary_count: beneficiaryCount === '' || beneficiaryCount == null ? null : Number(beneficiaryCount),
        generating_entity_name: generatingEntityName || null,
        generating_entity_type: generatingEntityType || null,
        duration_value: durationValue === '' || durationValue == null ? null : Number(durationValue),
        duration_unit: durationUnit || null,
        priority: priority || null,
        technical_criticality: technicalCriticality || null,
        fsu_amount: fsuAmount === '' || fsuAmount == null ? null : Number(fsuAmount),
        fsu_amount_usd: fsuAmountUsd === '' || fsuAmountUsd == null ? null : Number(fsuAmountUsd),
        fsu_scope: fsuScope || null,
        fsu_percentage: fsuPercentage === '' || fsuPercentage == null ? null : Number(fsuPercentage),
        budget_amount: budgetAmount === '' || budgetAmount == null ? null : Number(budgetAmount),
        budget_amount_usd: budgetAmountUsd === '' || budgetAmountUsd == null ? null : Number(budgetAmountUsd),
        exchange_rate: exchangeRate === '' || exchangeRate == null ? null : Number(exchangeRate),
        exchange_rate_date: exchangeRateDate || null,
        complexity: complexity || null,
        other_financing_percentage: otherFinancingPercentage === '' || otherFinancingPercentage == null ? null : Number(otherFinancingPercentage),
        other_financing_amount: otherFinancingAmount === '' || otherFinancingAmount == null ? null : Number(otherFinancingAmount),
        other_financing_notes: otherFinancingNotes || null,
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

  /* Owner or admin only — enforced by the projects_delete_own_or_admin RLS
     policy (see supabase/migration_v14_delete_policies.sql), so this
     silently deletes nothing for anyone else even if called. Cascades to
     project_documents, framework_analysis, fsu_scoring and
     project_workflow_events via their existing FKs — nothing else to clean
     up client-side. */
  async deleteProject(id) {
    const { error } = await supabaseClient
      .from('projects')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  /* ---------- Programs ----------
     A Program groups several related projects under one umbrella — e.g.
     Chubut's "Hub Digital Patagónico", which bundled a submarine cable
     landing, a regional backbone and last-mile builds as separate
     projects, each financed independently, all presented by the same
     sponsoring organization. See supabase/migration_v9_programs.sql.
     Creating a Program is advisor/admin-only, but every Program is visible
     to every signed-in user (so any user can associate their own project
     with one) — see supabase/migration_v19_program_permissions.sql and
     canManagePrograms() above. */

  /* Returns every Program on the platform, regardless of who created it —
     enforced by the programs_select_all_authenticated RLS policy, not by
     anything client-side. Used both by programs.html (the full list) and
     new-project.html's Program dropdown (so any user can pick any
     Program). */
  async listPrograms() {
    const { data, error } = await supabaseClient
      .from('programs')
      .select('*')
      .order('name', { ascending: true });
    if (error) throw error;
    return data;
  },

  async getProgram(id) {
    const { data, error } = await supabaseClient
      .from('programs')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  /* types is optional — a declared list of one or more project-type values
     (from PROJECT_TYPES) this Program covers, set by the owner independent
     of which projects have actually been submitted under it yet. Unlike a
     project (always single-type), a Program can be several — see
     supabase/migration_v11_program_types.sql. Advisor/admin-only — enforced
     by the programs_insert_advisor_or_admin RLS policy (see
     supabase/migration_v19_program_permissions.sql); a standard user's
     insert is rejected at the database level even if the UI hiding the
     "Create Program" button were somehow bypassed. */
  async createProgram({ name, organization, organizationType, financingEntity, types, description, templateKey, fundingStage }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const { data, error } = await supabaseClient
      .from('programs')
      .insert({
        user_id: session.user.id,
        name,
        organization,
        organization_type: organizationType || 'public',
        // Who actually finances the program — distinct from organization
        // above (who presents it). See migration_v36_program_financing_entity.sql.
        financing_entity: financingEntity || null,
        types: types || [],
        description: description || null,
        template_key: templateKey || null,
        funding_stage: fundingStage === 'preparation' ? 'preparation' : 'financing',
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  /* Owner-only — enforced by programs_update_own RLS. templateKey is
     optional — see PROGRAM_TEMPLATES/PROGRAM_TEMPLATE_OPTIONS above and
     supabase/migration_v18_program_template_key.sql. fundingStage is
     'preparation' (funds elaborating the project itself, e.g. USTDA) or
     'financing' (funds the project's implementation — FSU, BID, etc.,
     default) — see PROGRAM_FUNDING_STAGE_LABELS below and
     supabase/migration_v21_program_funding_stage_and_applications.sql. */
  async updateProgram(id, { name, organization, organizationType, financingEntity, types, description, templateKey, fundingStage }) {
    const { data, error } = await supabaseClient
      .from('programs')
      .update({
        name,
        organization,
        organization_type: organizationType || 'public',
        financing_entity: financingEntity || null,
        types: types || [],
        description: description || null,
        template_key: templateKey || null,
        funding_stage: fundingStage === 'preparation' ? 'preparation' : 'financing',
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  /* Owner or admin only — enforced by the programs_delete_own_or_admin RLS
     policy (see supabase/migration_v14_delete_policies.sql). Does NOT
     delete the program's member projects — projects.program_id is "on
     delete set null", so they're simply unlinked, not removed. Any
     program_documents attached to this program ARE cascade-deleted along
     with it. */
  async deleteProgram(id) {
    const { error } = await supabaseClient
      .from('programs')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  /* ---------- Program applications (multi-program) ----------
     A project can apply to several financing Programs at once — e.g. FSU +
     BID together for implementation financing, plus a separate
     'preparation'-stage Program (USTDA) for funding to elaborate the
     project itself — independent of the single "umbrella" program_id on
     projects (Chubut Hub Digital-style grouping). See
     supabase/migration_v21_program_funding_stage_and_applications.sql. */

  /* Every Program this project has applied to, with the program's name/
     template_key/funding_stage embedded — used by project.html to render
     the "Financing Programs" section and to know which Programs are still
     available to apply to. */
  async listProjectPrograms(projectId) {
    const { data, error } = await supabaseClient
      .from('project_programs')
      .select('*, programs(name, template_key, funding_stage, financing_entity)')
      .eq('project_id', projectId)
      .order('applied_at', { ascending: true });
    if (error) throw error;
    return data;
  },

  /* Batch version for dashboard.html's project grid — one query for every
     row instead of one per project. Returns a Map keyed by project_id, each
     value the array of { program_id, programs: { name, funding_stage } }
     rows for that project. */
  async listProjectProgramsForProjects(projectIds) {
    const ids = (projectIds || []).filter(Boolean);
    const map = new Map();
    if (!ids.length) return map;
    const { data, error } = await supabaseClient
      .from('project_programs')
      .select('project_id, program_id, programs(name, funding_stage, financing_entity)')
      .in('project_id', ids);
    if (error) throw error;
    (data || []).forEach((row) => {
      if (!map.has(row.project_id)) map.set(row.project_id, []);
      map.get(row.project_id).push(row);
    });
    return map;
  },

  /* Records (or updates, if already applied) a project's application to a
     Program. templateAnswers/notes are optional — only meaningful when the
     Program has a template_key (see PROGRAM_TEMPLATES); a plain application
     to a Program with no template just passes neither. RLS
     (project_programs_insert_own_or_assigned_advisor) restricts this to the
     project's owner or its currently-assigned advisor.

     financingPercentage/financingAmount (migration_v35_financing_mix.sql /
     migration_v37_financing_amounts.sql — a project's financing can be
     expressed as either, independently, same convention as
     fsu_amount/fsu_percentage) are also optional and, unlike
     templateAnswers/notes above, are deliberately left OUT of the upserted
     object entirely when not passed — rather than defaulting them to null
     like those two — so that calling applyToProgram() again later purely
     to update notes/template answers never wipes out a share set earlier
     via updateProjectProgramFinancing() below, and vice versa. */
  async applyToProgram(projectId, programId, { templateAnswers, notes, financingPercentage, financingAmount } = {}) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const payload = {
      project_id: projectId,
      program_id: programId,
      user_id: session.user.id,
      template_answers: templateAnswers || null,
      notes: notes || null,
    };
    if (financingPercentage !== undefined) {
      payload.financing_percentage = financingPercentage === '' || financingPercentage == null ? null : Number(financingPercentage);
    }
    if (financingAmount !== undefined) {
      payload.financing_amount = financingAmount === '' || financingAmount == null ? null : Number(financingAmount);
    }
    const { data, error } = await supabaseClient
      .from('project_programs')
      .upsert(payload, { onConflict: 'project_id,program_id' })
      .select('*, programs(name, template_key, funding_stage, financing_entity)')
      .single();
    if (error) throw error;
    return data;
  },

  /* Updates just the financing_percentage/financing_amount of an existing
     application — used by project.html's per-row financing controls so an
     advisor can fill in or adjust a Program's share of the financing mix
     (expressed as a % and/or an absolute amount) without touching its
     template answers/notes. Only the keys actually passed are included in
     the update, so calling this with just { percentage } (say) leaves
     financing_amount on the row untouched — same non-destructive pattern
     as applyToProgram above. Same RLS gate (owner or assigned advisor). */
  async updateProjectProgramFinancing(projectId, programId, { percentage, amount } = {}) {
    const updates = {};
    if (percentage !== undefined) {
      updates.financing_percentage = percentage === '' || percentage == null ? null : Number(percentage);
    }
    if (amount !== undefined) {
      updates.financing_amount = amount === '' || amount == null ? null : Number(amount);
    }
    const { data, error } = await supabaseClient
      .from('project_programs')
      .update(updates)
      .eq('project_id', projectId)
      .eq('program_id', programId)
      .select('*, programs(name, template_key, funding_stage, financing_entity)')
      .single();
    if (error) throw error;
    return data;
  },

  /* Financing mix summary for a project (migration_v35_financing_mix.sql,
     extended by migration_v37_financing_amounts.sql): the FSU's share,
     every financing-stage Program application's share (skipping
     preparation-stage ones — see the column comment on
     project_programs.financing_percentage), and the "other/unregistered
     source" share, plus the total — all expressed as % of budget_amount.

     Each of the three components can be entered as a % OR as an absolute
     amount (ARS), independently (same convention as fsu_amount/
     fsu_percentage since migration_v33). When a % is set explicitly, that's
     used as-is. When only an amount is set, it's converted to a % of
     project.budget_amount — if budget_amount isn't set, an amount alone
     can't be turned into a share of it, so that component contributes 0
     here (the amount is still shown to the user elsewhere, e.g.
     fsuAttrAmount/otherFinancingAmount on project.html — this function only
     computes the % coverage summary, it doesn't hide entered amounts).

     Missing/unset shares count as 0 so a partially-filled-in mix still
     sums to something meaningful; totalPct can legitimately be less than
     100 (mix still being worked out) or, if someone overshoots, more than
     100 — callers (project.html) decide how to flag that, this just does
     the arithmetic. */
  computeFinancingCoverage(project, projectPrograms) {
    const budget = project && project.budget_amount != null ? Number(project.budget_amount) : null;
    const pctOf = (amount) => (budget && budget > 0 && amount != null ? Math.round((Number(amount) / budget) * 100) : null);
    const effectivePct = (explicitPct, amount) => {
      if (explicitPct != null) return Number(explicitPct);
      const derived = pctOf(amount);
      return derived != null ? derived : 0;
    };

    const fsuPct = project ? effectivePct(project.fsu_percentage, project.fsu_amount) : 0;
    const otherPct = project ? effectivePct(project.other_financing_percentage, project.other_financing_amount) : 0;
    const programShares = (projectPrograms || [])
      .filter((row) => row.programs && row.programs.funding_stage !== 'preparation' && (row.financing_percentage != null || row.financing_amount != null))
      .map((row) => ({ name: row.programs.name, pct: effectivePct(row.financing_percentage, row.financing_amount) }));
    const programsPct = programShares.reduce((sum, s) => sum + s.pct, 0);
    return {
      fsuPct,
      otherPct,
      programShares,
      programsPct,
      totalPct: fsuPct + otherPct + programsPct,
    };
  },

  /* Withdraws a project's application to a Program (owner or assigned
     advisor only — project_programs_delete_own_or_assigned_advisor RLS). */
  async removeProjectProgram(projectId, programId) {
    const { error } = await supabaseClient
      .from('project_programs')
      .delete()
      .eq('project_id', projectId)
      .eq('program_id', programId);
    if (error) throw error;
  },

  programOrgTypeLabel(value) {
    const entry = PROGRAM_ORG_TYPE_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },

  PROGRAM_FUNDING_STAGE_LABELS,
  programFundingStageLabel(value) {
    const entry = PROGRAM_FUNDING_STAGE_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },

  // Agreed convention (migration_v36_program_financing_entity.sql): a
  // Program tied to the Universal Service Fund has financing_entity set to
  // exactly this string. Comparison is case/whitespace-insensitive so
  // "Enacom-FSU", "enacom-fsu ", etc. all still match — the DB column has
  // no CHECK constraint enforcing the exact casing, it's a data-entry
  // convention, not a closed enum. Used by app/project.html's Financing
  // tab to group FSU program applications together with the project's own
  // direct FSU fields (fsu_amount/fsu_scope/fsu_percentage) in one block,
  // separate from every other financing source.
  FSU_FINANCING_ENTITY: 'ENACOM-FSU',
  isFsuFinancingEntity(value) {
    return !!value && value.trim().toLowerCase() === 'enacom-fsu';
  },

  async updateProjectStatus(projectId, status) {
    const { error } = await supabaseClient
      .from('projects')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', projectId);
    if (error) throw error;
  },

  /* ---------- Project workflow (advisor-driven stage advancement) ----------
     See supabase/migration_v12_workflow.sql and
     supabase/migration_v20_workflow_promote_demote.sql. All writes go
     through the RPCs below (SECURITY DEFINER functions on the database
     side) — never a direct .update() on projects — so an advisor gets
     exactly this narrow capability without a broad "advisors can edit any
     project" RLS grant.

     State machine (see migration_v20 for the full rationale):
       Not Analyzed (readiness_stage null) — owner runs the self-assessment,
         which moves it to Concept Stage (see submitManualAssessment below).
       Concept Stage — an advisor who takes it can send it back to Not
         Analyzed (returnProjectToNotAnalyzed), run AI Analysis, or promote
         it to Early Structuring (promoteProjectWorkflow).
       Early Structuring / Advanced Structuring — promote or demote, always
         with a mandatory comment.
       Investment Ready — terminal, no promote or demote. */

  /* Claims a project for the calling advisor. Unrestricted today: any
     advisor/admin can take (or re-take from someone else) any project. */
  async takeProject(projectId) {
    const { error } = await supabaseClient.rpc('take_project', { p_project_id: projectId });
    if (error) throw error;
  },

  /* Pushes a project exactly one stage forward (Concept Stage → Early
     Structuring → Advanced Structuring → Investment Ready), claims it for
     the calling advisor, and logs the transition. `note` is mandatory — the
     database rejects a null/blank one — so callers should collect it from
     the advisor before calling this rather than relying solely on the
     thrown error. Also throws if the project hasn't had its first
     self-assessment yet (readiness_stage still null) or is already at the
     final stage — callers should check nextWorkflowStage() first to
     disable the button. Returns the new stage. */
  async promoteProjectWorkflow(projectId, note) {
    const { data, error } = await supabaseClient.rpc('promote_project_workflow', {
      p_project_id: projectId,
      p_note: note,
    });
    if (error) throw error;
    return data;
  },

  /* Mirror of promoteProjectWorkflow, one stage backward. Throws if the
     project is at Concept Stage (use returnProjectToNotAnalyzed instead)
     or at Investment Ready (terminal — no demote per spec). `note` is
     mandatory. Returns the new stage. */
  async demoteProjectWorkflow(projectId, note) {
    const { data, error } = await supabaseClient.rpc('demote_project_workflow', {
      p_project_id: projectId,
      p_note: note,
    });
    if (error) throw error;
    return data;
  },

  /* The one stage-change action that isn't a simple forward/backward step:
     sends a Concept Stage project all the way back to Not Analyzed and
     un-claims it (assigned_advisor_id → null), so it's back in the owner's
     hands to redo the self-assessment. Only callable from Concept Stage —
     throws otherwise. `note` is mandatory (the reason shown to the owner).
     Returns 'Not Analyzed'. */
  async returnProjectToNotAnalyzed(projectId, note) {
    const { data, error } = await supabaseClient.rpc('return_project_to_not_analyzed', {
      p_project_id: projectId,
      p_note: note,
    });
    if (error) throw error;
    return data;
  },

  /* Full transition history for a project, oldest first — used to render
     the workflow's "who did what, when" log on project.html. */
  async getWorkflowEvents(projectId) {
    const { data, error } = await supabaseClient
      .from('project_workflow_events')
      .select('*, advisor:profiles!project_workflow_events_advisor_id_fkey(full_name)')
      .eq('project_id', projectId)
      .order('created_at', { ascending: true });
    if (error) throw error;
    return data;
  },

  STAGE_ORDER,
  SPECIALIZATION_LABELS,
  specializationLabel(value) {
    const entry = SPECIALIZATION_LABELS[value];
    return entry ? entry[currentLang()] : value;
  },
  /* The stage a project would move to if promoted right now, or null if
     it can't be promoted — either because it's still Not Analyzed (no
     self-assessment yet, readiness_stage null — promote_project_workflow()
     rejects this server-side too) or because it's already at the final
     stage. Unlike the pre-v20 version, a null readiness_stage is NOT
     treated as 'Concept Stage' — promoting only makes sense once the
     project actually has a stage. */
  nextWorkflowStage(project) {
    const current = project && project.readiness_stage;
    if (!current) return null;
    const idx = STAGE_ORDER.indexOf(current);
    if (idx === -1 || idx === STAGE_ORDER.length - 1) return null;
    return STAGE_ORDER[idx + 1];
  },

  /* Mirror of nextWorkflowStage, one stage backward — null when the
     project can't be demoted: still Not Analyzed, already at Concept Stage
     (that's returnProjectToNotAnalyzed's job, not a plain demote — see
     migration_v20), or at Investment Ready (terminal, no demote). */
  prevWorkflowStage(project) {
    const current = project && project.readiness_stage;
    if (!current || current === 'Concept Stage' || current === 'Investment Ready') return null;
    const idx = STAGE_ORDER.indexOf(current);
    if (idx <= 0) return null;
    return STAGE_ORDER[idx - 1];
  },

  /* Whether a Concept Stage project can be sent back to Not Analyzed right
     now — used to gate the "return to owner" action the same way
     nextWorkflowStage/prevWorkflowStage gate promote/demote. */
  canReturnToNotAnalyzed(project) {
    return !!project && project.readiness_stage === 'Concept Stage';
  },

  /* ---------- Documents ---------- */

  // documentType defaults to 'other' — see DOCUMENT_TYPES above and
  // supabase/migration_v24_document_categories_expand.sql. Callers
  // (new-project.html) pass one of the 7 category values depending on which
  // (all optional) drop zone the file was added to.
  async uploadDocument(projectId, file, documentType) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const userId = session.user.id;
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = `${userId}/${projectId}/${Date.now()}_${safeName}`;
    const type = DOCUMENT_TYPES.some((t) => t.value === documentType) ? documentType : 'other';

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
        document_type: type,
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

  /* Owner-only — enforced by the documents_delete_own RLS policy (see
     supabase/migration_v16_document_delete.sql). `doc` is a row from
     listDocuments() (needs .id and .storage_path). Removing the Storage
     object is best-effort: if it fails (e.g. the bucket policy hasn't been
     applied yet), the DB row is still deleted so the UI stays consistent —
     a stray orphaned file in Storage is harmless, a document that won't
     disappear from the list is confusing. There's no separate "replace"
     call: the UI deletes the old file and lets the user drop a new one in
     the same category's upload zone, which uploads as a new row. */
  async deleteDocument(doc) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    try {
      await supabaseClient.storage.from('project-documents').remove([doc.storage_path]);
    } catch (e) { /* best-effort, see doc comment above */ }
    const { error } = await supabaseClient
      .from('project_documents')
      .delete()
      .eq('id', doc.id);
    if (error) throw error;
  },

  /* Same idea as uploadDocument()/listDocuments() above, scoped to a
     Program instead of a Project — see supabase/migration_v13_program_documents.sql.
     Reuses the same "project-documents" Storage bucket (its policies only
     check the {user_id} folder prefix), just under a "programs/" subpath so
     the two don't visually mix in the bucket browser. */
  async uploadProgramDocument(programId, file) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const userId = session.user.id;
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = `${userId}/programs/${programId}/${Date.now()}_${safeName}`;

    const { error: uploadError } = await supabaseClient
      .storage
      .from('project-documents')
      .upload(storagePath, file);
    if (uploadError) throw uploadError;

    const { data, error } = await supabaseClient
      .from('program_documents')
      .insert({
        program_id: programId,
        user_id: userId,
        file_name: file.name,
        storage_path: storagePath,
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async listProgramDocuments(programId) {
    const { data, error } = await supabaseClient
      .from('program_documents')
      .select('*')
      .eq('program_id', programId)
      .order('uploaded_at', { ascending: true });
    if (error) throw error;
    return data;
  },

  /* Same idea as deleteDocument() above, scoped to a Program — see
     program_documents_delete_own RLS policy in
     supabase/migration_v16_document_delete.sql. */
  async deleteProgramDocument(doc) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    try {
      await supabaseClient.storage.from('project-documents').remove([doc.storage_path]);
    } catch (e) { /* best-effort, see deleteDocument()'s doc comment */ }
    const { error } = await supabaseClient
      .from('program_documents')
      .delete()
      .eq('id', doc.id);
    if (error) throw error;
  },

  /* ---------- Shared field-answer pool + document autofill ----------
     See migration_v23_project_shared_field_answers.sql. A project can have
     several guided templates filled in over its life (its own project-type
     template, an umbrella Program template, a preparation-funding Program
     template, one or more financing Program templates), several of which
     ask for the same underlying facts. `shared_field_answers` is a flat
     {field_key: value} pool on the project row that every template reads
     from and writes to, so the same fact only has to be entered once. */

  flattenTemplateFields(template) { return flattenTemplateFields(template, currentLang()); },

  async getSharedFieldAnswers(projectId) {
    const { data, error } = await supabaseClient
      .from('projects')
      .select('shared_field_answers')
      .eq('id', projectId)
      .maybeSingle();
    if (error) throw error;
    return (data && data.shared_field_answers) || {};
  },

  /* Merges `patch` into the project's pool (only non-empty values overwrite
     — never clears an already-known fact just because a later template left
     that field blank). Best-effort by design: every caller (project-template.
     html's submit handler) wraps this in try/catch and never blocks
     navigation on it — the pool is a convenience cache, not a place any
     template's own saved answers live. */
  async mergeSharedFieldAnswers(projectId, patch) {
    if (!projectId || !patch) return;
    const current = await this.getSharedFieldAnswers(projectId).catch(() => ({}));
    const merged = { ...current };
    Object.keys(patch).forEach((key) => {
      const value = patch[key];
      if (value !== undefined && value !== null && String(value).trim() !== '') {
        merged[key] = value;
      }
    });
    const { error } = await supabaseClient
      .from('projects')
      .update({ shared_field_answers: merged })
      .eq('id', projectId);
    if (error) throw error;
    return merged;
  },

  /* Calls /api/extract-template-data.js for exactly the given fields (each
     {key,label,type,options} — see flattenTemplateFields() above) and
     returns { answers, documentsUsed, skipped }. Callers should first drop
     any field already present in the shared pool — see
     autofillTemplateAnswers() below, which does this automatically. */
  async extractTemplateFieldsFromDocuments(projectId, fields) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const res = await fetch(extractTemplateDataUrl(), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${session.access_token}`,
      },
      body: JSON.stringify({ projectId, fields }),
    });
    const body = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(body.error || 'Autocomplete request failed.');
    return body;
  },

  /* Orchestrates the whole "Autocomplete from documents" button: fields
     already known in the project's shared pool are reused for free (no
     model call, no re-reading the documents); only fields still missing are
     sent to /api/extract-template-data.js, and whatever comes back is
     merged into the pool so the NEXT template opened for this project (e.g.
     the FSU financing template right after the USTDA preparation one) gets
     them for free too. Returns
     { answers, filledFromPool, filledFromDocuments, documentsUsed, skipped }
     — `answers` only contains keys with a known (non-null) value, ready to
     drop straight into the form for whichever fields are still blank. */
  async autofillTemplateAnswers(projectId, template) {
    const fields = this.flattenTemplateFields(template);
    const pool = await this.getSharedFieldAnswers(projectId);
    const known = {};
    const missingFields = [];
    fields.forEach((f) => {
      if (pool[f.key] !== undefined && pool[f.key] !== null && String(pool[f.key]).trim() !== '') {
        known[f.key] = pool[f.key];
      } else {
        missingFields.push(f);
      }
    });
    const filledFromPool = Object.keys(known).length;

    let documentsUsed = [];
    let skipped = [];
    if (missingFields.length) {
      const result = await this.extractTemplateFieldsFromDocuments(projectId, missingFields);
      documentsUsed = result.documentsUsed || [];
      skipped = result.skipped || [];
      const extracted = result.answers || {};
      Object.keys(extracted).forEach((key) => { known[key] = extracted[key]; });
      if (Object.keys(extracted).length) {
        try { await this.mergeSharedFieldAnswers(projectId, extracted); } catch (e) { /* non-critical */ }
      }
    }

    return {
      answers: known,
      filledFromPool,
      filledFromDocuments: Object.keys(known).length - filledFromPool,
      documentsUsed,
      skipped,
    };
  },

  /* ---------- Roadmaps (regulatory/administrative checklist) ----------
     See supabase/migration_v26_gestion_templates.sql for the full schema
     and RLS rationale. All writes here are advisor/admin-only at the RLS
     level — canManageRoadmaps() above is just the UI-side gate that hides
     the relevant buttons/forms from a standard user before they'd hit a
     permission error, same pattern as canManagePrograms(). */

  async listRoadmapTemplates() {
    const { data, error } = await supabaseClient
      .from('roadmap_templates')
      .select('*')
      .order('name', { ascending: true });
    if (error) throw error;
    return data;
  },

  /* Client-side filter, not a query param — a template with project_type
     null is deliberately generic/reusable and should match every type, so
     this can't just be `.eq('project_type', projectType)` server-side. */
  roadmapTemplatesForProjectType(templates, projectType) {
    return (templates || []).filter((t) => !t.project_type || t.project_type === projectType);
  },

  async getRoadmapTemplate(id) {
    const { data, error } = await supabaseClient
      .from('roadmap_templates')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  async listRoadmapTemplateSteps(templateId) {
    const { data, error } = await supabaseClient
      .from('roadmap_template_steps')
      .select('*')
      .eq('template_id', templateId)
      .order('step_order', { ascending: true });
    if (error) throw error;
    return data;
  },

  /* allowedEntityType is optional — null/undefined/'' means any entity
     type may run this checklist. See migration_v27_gestion_instances.sql. */
  async createRoadmapTemplate({ name, projectType, description, allowedEntityType }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const { data, error } = await supabaseClient
      .from('roadmap_templates')
      .insert({
        user_id: session.user.id,
        name,
        project_type: projectType || null,
        description: description || null,
        allowed_entity_type: allowedEntityType || null,
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async updateRoadmapTemplate(id, { name, projectType, description, allowedEntityType }) {
    const { data, error } = await supabaseClient
      .from('roadmap_templates')
      .update({
        name,
        project_type: projectType || null,
        description: description || null,
        allowed_entity_type: allowedEntityType || null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  /* Cascade-deletes this template's steps (roadmap_template_steps.template_id
     is "on delete cascade") — does NOT touch any project_roadmaps already
     instantiated from it, since those are independent copies
     (template_step_id there is "on delete set null"). */
  async deleteRoadmapTemplate(id) {
    const { error } = await supabaseClient
      .from('roadmap_templates')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  /* Wholesale replace, same simplicity level as how a Program's `types`
     checkbox list is just overwritten on save rather than diffed — steps is
     an ordered array of { title, description, entityName, entityType,
     required, expectedResult, involvedEntities }. expectedResult
     ("resultado esperado") is shown by the roadmap_instances sequential
     tracker when the user is deciding whether to advance past a step.
     entityName/entityType are the entity RESPONSIBLE for the step;
     involvedEntities (array of free-form names, added by
     migration_v29_gestion_step_entities.sql) are the other entities that
     also participate in it. */
  async replaceRoadmapTemplateSteps(templateId, steps) {
    const { error: delErr } = await supabaseClient
      .from('roadmap_template_steps')
      .delete()
      .eq('template_id', templateId);
    if (delErr) throw delErr;
    const rows = (steps || [])
      .filter((s) => s.title && s.title.trim())
      .map((s, i) => ({
        template_id: templateId,
        step_order: i,
        title: s.title.trim(),
        description: s.description ? s.description.trim() : null,
        entity_name: s.entityName ? s.entityName.trim() : null,
        entity_type: s.entityType || 'public',
        required: s.required !== false,
        expected_result: s.expectedResult ? s.expectedResult.trim() : null,
        involved_entities: Array.isArray(s.involvedEntities)
          ? s.involvedEntities.map((e) => (e || '').trim()).filter(Boolean)
          : [],
      }));
    if (!rows.length) return [];
    const { data, error } = await supabaseClient
      .from('roadmap_template_steps')
      .insert(rows)
      .select();
    if (error) throw error;
    return data;
  },

  async listProjectRoadmaps(projectId) {
    const { data, error } = await supabaseClient
      .from('project_roadmaps')
      .select('*')
      .eq('project_id', projectId)
      .order('step_order', { ascending: true });
    if (error) throw error;
    return data;
  },

  /* Copies a template's steps into project_roadmaps as independent rows —
     appended after whatever's already on the checklist (existing.length as
     the starting step_order) rather than replacing it, so loading a second
     template (or re-loading the same one) doesn't wipe out progress already
     tracked on earlier steps. */
  async instantiateRoadmapsFromTemplate(projectId, templateId) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const [steps, existing] = await Promise.all([
      this.listRoadmapTemplateSteps(templateId),
      this.listProjectRoadmaps(projectId),
    ]);
    if (!steps.length) return [];
    const startOrder = existing.length;
    const rows = steps.map((s, i) => ({
      project_id: projectId,
      template_step_id: s.id,
      step_order: startOrder + i,
      title: s.title,
      description: s.description,
      entity_name: s.entity_name,
      entity_type: s.entity_type,
      status: 'pending',
      created_by: session.user.id,
    }));
    const { data, error } = await supabaseClient
      .from('project_roadmaps')
      .insert(rows)
      .select();
    if (error) throw error;
    return data;
  },

  /* Ad-hoc step, not tied to any template — e.g. a one-off procedure
     specific to this particular project. */
  async createProjectRoadmap(projectId, { title, description, entityName, entityType, stepOrder }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const { data, error } = await supabaseClient
      .from('project_roadmaps')
      .insert({
        project_id: projectId,
        title,
        description: description || null,
        entity_name: entityName || null,
        entity_type: entityType || 'public',
        status: 'pending',
        step_order: stepOrder != null ? stepOrder : 0,
        created_by: session.user.id,
      })
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  /* patch may include any of: title, description, entityName, entityType,
     status, responsibleName, responsibleContact, dueDate, completedDate,
     notes. Only advisor/admin can call this — project_roadmaps_update_
     advisor_or_admin RLS rejects it otherwise, so the project owner's
     read-only view never even shows editable controls that would hit this. */
  async updateProjectRoadmap(id, patch) {
    const payload = { updated_at: new Date().toISOString() };
    if (patch.title !== undefined) payload.title = patch.title;
    if (patch.description !== undefined) payload.description = patch.description || null;
    if (patch.entityName !== undefined) payload.entity_name = patch.entityName || null;
    if (patch.entityType !== undefined) payload.entity_type = patch.entityType || 'public';
    if (patch.status !== undefined) payload.status = patch.status;
    if (patch.responsibleName !== undefined) payload.responsible_name = patch.responsibleName || null;
    if (patch.responsibleContact !== undefined) payload.responsible_contact = patch.responsibleContact || null;
    if (patch.dueDate !== undefined) payload.due_date = patch.dueDate || null;
    if (patch.completedDate !== undefined) payload.completed_date = patch.completedDate || null;
    if (patch.notes !== undefined) payload.notes = patch.notes || null;
    const { data, error } = await supabaseClient
      .from('project_roadmaps')
      .update(payload)
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async deleteProjectRoadmap(id) {
    const { error } = await supabaseClient
      .from('project_roadmaps')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  /* ---------- Roadmap instances (sequential workflow tracker) ----------
     See supabase/migration_v27_gestion_instances.sql. Replaces the
     free-form project_roadmaps checklist above as the per-project
     tracking UI (that table/those functions are left in place, just
     unused by the app going forward). A roadmap_instance is one named,
     sequential run of a roadmap_template against a specific project AND a
     specific performing entity — its steps are copied from the template
     at creation time (independent copies, same soft-reference pattern as
     everywhere else in this schema) and worked through in order via
     current_step_index. All writes are advisor/admin-only at the RLS
     level; canManageRoadmaps() above is the matching UI-side gate. */

  async listRoadmapInstances(projectId) {
    const { data, error } = await supabaseClient
      .from('roadmap_instances')
      .select('*')
      .eq('project_id', projectId)
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  },

  /* Every Roadmap instance the viewer can see (advisor/admin: all of
     them; a standard user: none, per RLS — Roadmap instances aren't a
     project-owner-facing list) — used by roadmap-templates.html to
     surface Roadmaps that aren't (yet, or ever) linked to a project,
     which wouldn't show up on any project's own page. Embeds the linked
     project's name for display; null when there isn't one. */
  async listAllRoadmapInstances() {
    const { data, error } = await supabaseClient
      .from('roadmap_instances')
      .select('*, projects(name)')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  },

  async getRoadmapInstance(id) {
    const { data, error } = await supabaseClient
      .from('roadmap_instances')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  async listRoadmapInstanceSteps(instanceId) {
    const { data, error } = await supabaseClient
      .from('roadmap_instance_steps')
      .select('*')
      .eq('instance_id', instanceId)
      .order('step_order', { ascending: true });
    if (error) throw error;
    return data;
  },

  /* Client-side filter, same reasoning as roadmapTemplatesForProjectType:
     a template with no allowed_entity_type is unrestricted and should
     match any performing entity. */
  roadmapTemplatesForEntityType(templates, entityType) {
    return (templates || []).filter((t) => !t.allowed_entity_type || t.allowed_entity_type === entityType);
  },

  /* Creates the instance, then copies the template's steps into
     roadmap_instance_steps as independent rows (template_step_id kept
     only as a soft "where this came from" reference). current_step_index
     starts at 0 — the first step is immediately active. projectId is
     optional — a Roadmap is often started before the project it concerns
     even exists (see migration_v28_gestion_instance_optional_project.sql)
     and can be linked to one later, or never. */
  async createRoadmapInstance({ projectId, templateId, name, performingEntityName, performingEntityType }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const { data: instance, error: instErr } = await supabaseClient
      .from('roadmap_instances')
      .insert({
        project_id: projectId || null,
        template_id: templateId || null,
        name,
        performing_entity_name: performingEntityName,
        performing_entity_type: performingEntityType,
        current_step_index: 0,
        status: 'in_progress',
        created_by: session.user.id,
      })
      .select()
      .single();
    if (instErr) throw instErr;

    if (templateId) {
      const templateSteps = await this.listRoadmapTemplateSteps(templateId);
      if (templateSteps.length) {
        const rows = templateSteps.map((s, i) => ({
          instance_id: instance.id,
          template_step_id: s.id,
          step_order: i,
          title: s.title,
          description: s.description,
          expected_result: s.expected_result,
          entity_name: s.entity_name,
          entity_type: s.entity_type,
          involved_entities: s.involved_entities || [],
          required: s.required,
          status: i === 0 ? 'in_progress' : 'pending',
        }));
        const { error: stepsErr } = await supabaseClient.from('roadmap_instance_steps').insert(rows);
        if (stepsErr) throw stepsErr;
      }
    }
    return instance;
  },

  /* The user's decision point: mark the current step completed (or
     skipped/blocked) and, if advancing, move current_step_index forward
     and mark the next step 'in_progress'. Passing advance:false just
     records the decision note/status on the current step without moving
     the pointer — "el usuario decide si avanza al paso siguiente o no". */
  async advanceRoadmapInstanceStep(instanceId, { stepId, status, decisionNote, advance }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const stepPayload = {
      status: status || 'completed',
      decision_note: decisionNote || null,
      updated_at: new Date().toISOString(),
    };
    if (stepPayload.status === 'completed' || stepPayload.status === 'skipped') {
      stepPayload.completed_at = new Date().toISOString();
      stepPayload.completed_by = session.user.id;
    }
    const { error: stepErr } = await supabaseClient
      .from('roadmap_instance_steps')
      .update(stepPayload)
      .eq('id', stepId);
    if (stepErr) throw stepErr;

    if (!advance) {
      const { data } = await supabaseClient.from('roadmap_instances').select('*').eq('id', instanceId).single();
      return data;
    }

    const steps = await this.listRoadmapInstanceSteps(instanceId);
    const idx = steps.findIndex((s) => s.id === stepId);
    const nextStep = idx >= 0 ? steps[idx + 1] : null;
    const instancePayload = { updated_at: new Date().toISOString() };
    if (nextStep) {
      instancePayload.current_step_index = idx + 1;
      await supabaseClient.from('roadmap_instance_steps').update({ status: 'in_progress' }).eq('id', nextStep.id);
    } else {
      instancePayload.status = 'completed';
      instancePayload.current_step_index = steps.length;
    }
    const { data, error } = await supabaseClient
      .from('roadmap_instances')
      .update(instancePayload)
      .eq('id', instanceId)
      .select()
      .single();
    if (error) throw error;
    return data;
  },

  async deleteRoadmapInstance(id) {
    const { error } = await supabaseClient
      .from('roadmap_instances')
      .delete()
      .eq('id', id);
    if (error) throw error;
  },

  /* Direct instance-level status override — used for "abandon"/"reopen"
     rather than the normal step-by-step advanceRoadmapInstanceStep() path. */
  async updateRoadmapInstanceStatus(id, status) {
    const { data, error } = await supabaseClient
      .from('roadmap_instances')
      .update({ status, updated_at: new Date().toISOString() })
      .eq('id', id)
      .select()
      .single();
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

  /* Batch version for dashboard.html's project grid — one query for every
     row instead of one per project. Unlike getAnalysis() (which only ever
     returns the single MOST RECENT row regardless of source, matching
     project.html's "latest result wins" detail view), the dashboard grid
     wants to show the Self-Assessment (source='manual') and the AI
     Analysis (source='ai') side by side even when one is older than the
     other — e.g. an owner self-assessed a project, then later an advisor
     ran the AI analysis; both scores are still meaningful and shouldn't
     make each other disappear. framework_analysis is an append-only
     history table (no unique constraint per project+source), so this
     fetches every row for the visible projects and keeps only the newest
     per (project_id, source) — cheap client-side reduction since rows are
     tiny and already ordered newest-first by the query.
     Returns a Map keyed by project_id, each value { manual: row|null, ai: row|null }. */
  async listAnalysesForProjects(projectIds) {
    const ids = (projectIds || []).filter(Boolean);
    const map = new Map();
    if (!ids.length) return map;
    const { data, error } = await supabaseClient
      .from('framework_analysis')
      .select('id, project_id, overall_score, stage, source, created_at')
      .in('project_id', ids)
      .order('created_at', { ascending: false });
    if (error) throw error;
    (data || []).forEach((row) => {
      if (!map.has(row.project_id)) map.set(row.project_id, { manual: null, ai: null });
      const entry = map.get(row.project_id);
      const key = row.source === 'manual' ? 'manual' : 'ai';
      if (!entry[key]) entry[key] = row; // first hit per source is the newest, thanks to the order() above
    });
    return map;
  },

  /* Calls the serverless function that runs the AI analysis — see
     analyzeProjectUrl() near the top of this file for why the URL isn't
     always the same relative path: on Bluehost production it's a
     cross-origin call to the api.* subdomain on Vercel, which
     /api/analyze-project.js sends matching CORS headers for. */
  async requestAnalysis(projectId) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    // keepalive: true — new-project.html fires this and then immediately
    // navigates to project.html (`location.href = ...`) without awaiting
    // it, so the poller on the results page can start right away instead
    // of the form staying on-screen for up to a minute. Without keepalive,
    // that navigation aborts this fetch mid-flight the instant it fires
    // (Chrome/Firefox both cancel in-flight requests from a page that's
    // being unloaded) — the request never even reaches Vercel, which is
    // why it wouldn't show up in project.html's Network tab (it belonged
    // to the page that just got torn down) and why the project can end up
    // stuck on "Applying the Investment Readiness Index…" until the
    // client-side poll timeout. keepalive keeps the request alive across
    // the navigation, the same mechanism `navigator.sendBeacon()` uses.
    // The request body here is tiny (just `projectId`) so it's nowhere
    // near the ~64KB cap Chrome enforces on keepalive requests.
    const res = await fetch(analyzeProjectUrl(), {
      method: 'POST',
      keepalive: true,
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

  /* ---------- Edit locks (concurrent-edit prevention) ----------
     Pablo: "Cuando un usuario abre un proyecto, programa o roadmap en modo
     edición, debería bloquearse para edición al resto de los usuarios." A
     hard lock — see supabase/migration_v31_edit_locks.sql for the DB side
     (acquire/release RPCs, one pair per table, plus the edit_locked_by/
     edit_locked_at columns). No manual force-unlock: LOCK_TIMEOUT_MINUTES
     below must match the "interval '5 minutes'" hardcoded into each
     acquire_*_edit_lock() RPC — change both together if it's ever tuned.

     Usage from an edit-mode page (new-project.html / new-program.html /
     new-roadmap-template.html), once isEdit is confirmed and the viewer is
     otherwise allowed to edit the record at all:

       const lock = await INAPlatform.acquireEditLock('project', editId);
       if (!lock.acquired) {
         // show the read-only banner using lock.locked_by_name (may be
         // null — see the RLS note in the migration — fall back to a
         // generic "someone else" string) and lock.locked_at, disable the
         // form, stop here.
       } else {
         // proceed as normal; start the heartbeat so the lock survives
         // long edits, and release it on save/cancel/unload:
         const stopHeartbeat = INAPlatform.startEditLockHeartbeat('project', editId);
         // ...later, on save success or Cancel:
         stopHeartbeat();
         await INAPlatform.releaseEditLock('project', editId);
       }

     kind is 'project' | 'program' | 'roadmapTemplate' — maps to the three
     RPC pairs; anything else throws rather than silently doing nothing. */

  LOCK_TIMEOUT_MINUTES: 5,
  LOCK_HEARTBEAT_MS: 60000,

  _EDIT_LOCK_RPC: {
    project: { acquire: 'acquire_project_edit_lock', release: 'release_project_edit_lock', param: 'p_project_id' },
    program: { acquire: 'acquire_program_edit_lock', release: 'release_program_edit_lock', param: 'p_program_id' },
    roadmapTemplate: { acquire: 'acquire_roadmap_template_edit_lock', release: 'release_roadmap_template_edit_lock', param: 'p_template_id' },
  },

  /* Attempts to claim the lock — succeeds immediately if it's free,
     already held by the caller (renewal), or stale (past
     LOCK_TIMEOUT_MINUTES with no renewal). Returns
     { acquired, locked_by, locked_by_name, locked_at } either way; when
     acquired is false, locked_by_name may still be null even though
     someone genuinely holds the lock — RLS only lets the caller read
     another user's profile if they're an advisor/admin (see
     profiles_select_own_or_privileged in supabase/schema.sql), so a
     standard project owner blocked by an advisor's lock won't get a name
     back. Callers should fall back to a generic "someone else" message in
     that case rather than showing a blank one. */
  async acquireEditLock(kind, id) {
    const rpc = this._EDIT_LOCK_RPC[kind];
    if (!rpc) throw new Error(`Unknown edit-lock kind: ${kind}`);
    const { data, error } = await supabaseClient.rpc(rpc.acquire, { [rpc.param]: id });
    if (error) throw error;
    // Set-returning RPCs come back as an array of rows via PostgREST —
    // exactly one row here since p_*_id is a primary key lookup.
    return (data && data[0]) || { acquired: false, locked_by: null, locked_by_name: null, locked_at: null };
  },

  /* No-op (not an error) if the caller isn't the current lock holder —
     e.g. a best-effort beforeunload release firing after the lock had
     already expired and been claimed by someone else; releasing must
     never steal that person's lock out from under them. */
  async releaseEditLock(kind, id) {
    const rpc = this._EDIT_LOCK_RPC[kind];
    if (!rpc) throw new Error(`Unknown edit-lock kind: ${kind}`);
    const { error } = await supabaseClient.rpc(rpc.release, { [rpc.param]: id });
    if (error) throw error;
  },

  /* Re-runs acquireEditLock() on an interval to renew edit_locked_at while
     the page stays open, so a long edit session doesn't get stolen out
     from under the person actively working on it. Returns a stop()
     function — callers must call it before releaseEditLock() (or on
     unmount/navigation) so a stale interval doesn't keep re-acquiring a
     lock that's meant to be released. Renewal failures are swallowed
     (non-critical, matches this file's general non-critical-background-
     task pattern) — worst case the lock simply expires on schedule and
     the editor sees a "someone else is now editing" state next action,
     same as any other timeout. */
  startEditLockHeartbeat(kind, id) {
    const timer = setInterval(() => {
      this.acquireEditLock(kind, id).catch(() => { /* non-critical */ });
    }, this.LOCK_HEARTBEAT_MS);
    return () => clearInterval(timer);
  },
};

window.INAPlatform = INAPlatform;
window.supabaseClient = supabaseClient;
