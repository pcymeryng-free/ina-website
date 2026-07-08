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
  SUPABASE_URL: 'https://supabase.com/dashboard/project/lyyuxoltyyckfppfjbyn/settings/general', // e.g. https://abcdefgh.supabase.co
  SUPABASE_ANON_KEY: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5eXV4b2x0eXlja2ZwcGZqYnluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1MDYyNzIsImV4cCI6MjA5OTA4MjI3Mn0.2Ggj03wA2GILf-26PhDT4ZQx2g9ePI8u1WBLwMN774s',
};

const supabaseClient = (INA_PLATFORM_CONFIG.SUPABASE_URL !== 'YOUR_SUPABASE_URL' && window.supabase)
  ? window.supabase.createClient(INA_PLATFORM_CONFIG.SUPABASE_URL, INA_PLATFORM_CONFIG.SUPABASE_ANON_KEY)
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

function currentLang() {
  return document.documentElement.getAttribute('lang') === 'es' ? 'es' : 'en';
}

function labelFor(list, value, lang) {
  const item = list.find((i) => i.value === value);
  if (!item) return value;
  return item[lang] || item.en;
}

/* ---------- Auth helpers ---------- */

const INAPlatform = {
  ROLE_TYPES,
  PROJECT_TYPES,
  PROJECT_STATUS_LABELS,
  READINESS_STAGE_LABELS,
  DIMENSION_LABELS,
  DIMENSION_ORDER,
  PRIORITY_LABELS,
  currentLang,

  dimensionLabel(key) {
    const entry = DIMENSION_LABELS[key];
    return entry ? entry[currentLang()] : key;
  },
  priorityLabel(value) {
    const entry = PRIORITY_LABELS[(value || '').toLowerCase()];
    return entry ? entry[currentLang()] : value;
  },

  isConfigured() {
    return !!supabaseClient;
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
     (preserving a ?next= return path) if there's no active session. */
  async requireAuth() {
    const session = await this.getSession();
    if (!session) {
      const next = encodeURIComponent(location.pathname + location.search);
      location.href = `login.html?next=${next}`;
      return null;
    }
    return session;
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

  /* ---------- Projects ---------- */

  async listProjects() {
    const { data, error } = await supabaseClient
      .from('projects')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return data;
  },

  async getProject(id) {
    const { data, error } = await supabaseClient
      .from('projects')
      .select('*')
      .eq('id', id)
      .single();
    if (error) throw error;
    return data;
  },

  async createProject({ name, projectType, country, description }) {
    const session = await this.getSession();
    if (!session) throw new Error('Not signed in.');
    const { data, error } = await supabaseClient
      .from('projects')
      .insert({
        user_id: session.user.id,
        name,
        project_type: projectType,
        country,
        description,
      })
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
