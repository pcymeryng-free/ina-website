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
  PRIORITY_LABELS,
  STATUS_FILTER_VALUES,
  PLATFORM_ROLE_LABELS,
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

  /* Edits an existing project (owner only — enforced by the
     projects_update_own RLS policy, so this silently fails for anyone
     else even if called). Resets status/readiness_stage so the caller can
     re-trigger analysis against the updated description. */
  async updateProject(id, { name, projectType, country, description }) {
    const { data, error } = await supabaseClient
      .from('projects')
      .update({
        name,
        project_type: projectType,
        country,
        description,
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
