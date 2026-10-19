/**
 * INA Platform — /api/manage-user
 * Vercel serverless function (Node.js runtime, no external dependencies).
 *
 * Merges what used to be three separate files — api/create-user.js,
 * api/set-user-disabled.js, api/delete-user.js — into one, dispatched by
 * `action` in the POST body ('create' | 'disable' | 'delete'). Pure
 * consolidation, not a behavior change: every check, error shape and
 * response below is unchanged from those three files (see git history for
 * each one's own design notes — the CORS/origin allowlist, verifyUser(),
 * callerCanManageUsers() and the per-action logic are all copied as-is,
 * just no longer duplicated three times).
 *
 * Why merged (Pablo, oct 2026): the Vercel Hobby plan caps a deployment at
 * 12 Serverless Functions; adding api/update-news.js as a 13th made every
 * deploy fail outright ("No more than 12 Serverless Functions..."). These
 * three were the best candidates to fold together — same auth pattern,
 * same admin-only "user management" gate, no AI-provider logic to keep
 * untangled — freeing two slots (13 files -> 11) without touching anything
 * about how admin.html actually calls them beyond adding `action` to the
 * body (see assets/platform.js's adminCreateUser()/setUserDisabled()/
 * adminDeleteUser()).
 *
 * Required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 * SUPABASE_ANON_KEY (same three every action already used).
 */

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

/* Same allowlist/CORS approach as every other api/*.js here — see
   api/analyze-project.js's comment for why this stays a small explicit
   list rather than '*'. */
const ALLOWED_ORIGINS = [
  'https://international-network-advisors.com',
  'https://www.international-network-advisors.com',
];
function isAllowedOrigin(origin) {
  if (!origin) return false;
  if (ALLOWED_ORIGINS.includes(origin)) return true;
  try {
    return new URL(origin).hostname.endsWith('.vercel.app');
  } catch (e) {
    return false;
  }
}

async function verifyUser(accessToken, { supabaseUrl, anonKey }) {
  const res = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: { apikey: anonKey, Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) return null;
  return res.json();
}

/* Mirrors assets/platform.js's entityPermission()/canManageUsers() exactly
   (admin.html itself is gated by requireCanManageUsers(), which also
   allows a custom role explicitly granted can_edit on 'user_management' —
   advisor is always excluded from that entity). Re-implemented here via
   service-role REST reads rather than trusting any client-supplied role
   flag, since every action below performs a privileged operation. */
async function callerCanManageUsers(callerId, { supabaseUrl, serviceKey }) {
  const profileRes = await fetch(
    `${supabaseUrl}/rest/v1/profiles?id=eq.${callerId}&select=role,custom_role_id`,
    { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } }
  );
  if (!profileRes.ok) return false;
  const rows = await profileRes.json();
  const profile = rows[0];
  if (!profile) return false;
  if (profile.role === 'admin') return true;
  if (profile.role === 'advisor') return false;
  if (!profile.custom_role_id) return false;
  const permRes = await fetch(
    `${supabaseUrl}/rest/v1/role_permissions?role_id=eq.${profile.custom_role_id}&entity=eq.user_management&select=can_edit`,
    { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } }
  );
  if (!permRes.ok) return false;
  const permRows = await permRes.json();
  return permRows.some((r) => r.can_edit);
}

function isDuplicateEmailError(bodyText) {
  return /already registered|already exists|user_already_exists/i.test(bodyText || '');
}

// Reads the exact row count for `table` owned by userId without fetching
// any rows — Prefer: count=exact makes PostgREST report the total in the
// Content-Range response header (e.g. "0-0/3") regardless of the
// limit=0 page actually returned.
async function countOwned(table, userId, { supabaseUrl, serviceKey }) {
  const res = await fetch(
    `${supabaseUrl}/rest/v1/${table}?user_id=eq.${userId}&select=id&limit=0`,
    { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, Prefer: 'count=exact' } }
  );
  if (!res.ok) throw new Error(`count query failed for ${table} (${res.status})`);
  const range = res.headers.get('content-range') || '';
  const total = range.includes('/') ? parseInt(range.split('/')[1], 10) : 0;
  return Number.isFinite(total) ? total : 0;
}

/* ---------- action: create (was api/create-user.js) ----------
   Can't reuse assets/platform.js's signUp(): it calls the client-side
   supabaseClient.auth.signUp(), which always authenticates the CALLING
   browser as the newly-created user — fine for self-registration, but it
   would log the admin out of their own session. New users are onboarded
   by EMAIL INVITATION (they set their own password — this never receives
   or sets one); handle_new_user() (supabase/schema.sql) bootstraps a
   `profiles` row from `raw_user_meta_data` on ANY auth.users insert, admin-
   created or self-registered, so the invite's `data` payload is shaped to
   match exactly what that trigger reads. */
async function actionCreate(body, { origin, supabaseUrl, serviceKey }) {
  const email = typeof (body && body.email) === 'string' ? body.email.trim() : '';
  const fullName = typeof (body && body.fullName) === 'string' ? body.fullName.trim() : '';
  const organization = typeof (body && body.organization) === 'string' ? body.organization.trim() : '';
  const roleType = typeof (body && body.roleType) === 'string' ? body.roleType.trim() : '';
  if (!email || !fullName) return { status: 400, body: { error: 'email and fullName are required' } };

  // redirect_to can't be derived from `location` server-side — the
  // caller's own (already CORS-validated) Origin header is the right
  // source, falling back to the production domain if it's somehow absent.
  const redirectOrigin = isAllowedOrigin(origin) ? origin : 'https://www.international-network-advisors.com';
  const redirectTo = `${redirectOrigin}/app/accept-invite.html`;

  const inviteRes = await fetch(`${supabaseUrl}/auth/v1/invite?redirect_to=${encodeURIComponent(redirectTo)}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
    body: JSON.stringify({ email, data: { full_name: fullName, organization, role_type: roleType || 'other' } }),
  });
  if (!inviteRes.ok) {
    const errText = await inviteRes.text().catch(() => '');
    if (isDuplicateEmailError(errText)) return { status: 409, body: { error: 'email_already_registered' } };
    console.error(`[manage-user:create] invite request failed (status ${inviteRes.status}):`, errText);
    return { status: 502, body: { error: 'Could not create user', detail: errText } };
  }
  const created = await inviteRes.json();
  return { status: 200, body: { ok: true, user: { id: created.id, email: created.email } } };
}

/* ---------- action: disable (was api/set-user-disabled.js) ----------
   Deactivates (not deletes) a user. A real delete isn't safe on this
   schema — profiles.id cascades from auth.users, and projects.user_id/
   programs.user_id/contracts.user_id/roadmap_templates.user_id (and
   everything hanging off a project_id) all cascade from profiles.id, so
   deleting a user who ever created a project would silently delete that
   project and everything under it (see actionDelete() below for the one
   case this IS allowed). Uses Supabase's own ban support (ban_duration)
   rather than inventing a parallel lockout: it blocks future sign-in AND
   token refresh, so an already-active session is locked out within its
   current access token's lifetime (~1h) without needing to kill live
   sessions. There's no literal "forever" value — a very long duration
   (876000h, ~100 years) stands in for a permanent disable (Supabase's own
   documented pattern), 'none' re-enables. profiles.disabled is kept in
   sync purely so the client can show/filter on it cheaply — it does not
   itself gate anything; the ban is what actually blocks access. */
async function actionDisable(body, caller, { supabaseUrl, serviceKey }) {
  const userId = typeof (body && body.userId) === 'string' ? body.userId : '';
  const disabled = !!(body && body.disabled);
  if (!userId) return { status: 400, body: { error: 'userId is required' } };
  if (caller.id === userId) return { status: 400, body: { error: 'You cannot disable your own account' } };

  const banRes = await fetch(`${supabaseUrl}/auth/v1/admin/users/${userId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
    body: JSON.stringify({ ban_duration: disabled ? '876000h' : 'none' }),
  });
  if (!banRes.ok) {
    const errText = await banRes.text().catch(() => '');
    console.error(`[manage-user:disable] ban update failed (status ${banRes.status}):`, errText);
    return { status: 502, body: { error: 'Could not update account access', detail: errText } };
  }

  const profileRes = await fetch(`${supabaseUrl}/rest/v1/profiles?id=eq.${userId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, Prefer: 'return=minimal' },
    body: JSON.stringify({ disabled }),
  });
  if (!profileRes.ok) {
    const errText = await profileRes.text().catch(() => '');
    console.error(`[manage-user:disable] profiles update failed (status ${profileRes.status}):`, errText);
    return { status: 502, body: { error: 'Access was updated but the profile record could not be synced', detail: errText } };
  }
  return { status: 200, body: { ok: true, disabled } };
}

/* ---------- action: delete (was api/delete-user.js) ----------
   A genuinely destructive, irreversible action — sits alongside
   actionDisable() (the default/safe one) for when an admin needs the
   account truly gone. Confirmed with Pablo (AskUserQuestion): refuses the
   delete if the target owns ANY project/program/contract/roadmap_template
   (each a real, independently-owned top-level record — e.g. deleting a
   PROGRAM deliberately does NOT cascade down to its member projects, so a
   program is a genuinely separate thing someone can own even with zero
   projects). Every other user_id-referencing row in the schema is always
   paired with a project_id on the same row, so it's bounded collateral of
   that project's own lifecycle, not a separate business record — not part
   of this check. */
async function actionDelete(body, caller, { supabaseUrl, serviceKey }) {
  const userId = typeof (body && body.userId) === 'string' ? body.userId : '';
  if (!userId) return { status: 400, body: { error: 'userId is required' } };
  if (caller.id === userId) return { status: 400, body: { error: 'You cannot delete your own account' } };

  const serviceOpts = { supabaseUrl, serviceKey };
  const [projects, programs, contracts, roadmap_templates] = await Promise.all([
    countOwned('projects', userId, serviceOpts),
    countOwned('programs', userId, serviceOpts),
    countOwned('contracts', userId, serviceOpts),
    countOwned('roadmap_templates', userId, serviceOpts),
  ]);
  const counts = { projects, programs, contracts, roadmap_templates };
  if (projects || programs || contracts || roadmap_templates) {
    return { status: 409, body: { error: 'has_owned_records', counts } };
  }

  const deleteRes = await fetch(`${supabaseUrl}/auth/v1/admin/users/${userId}`, {
    method: 'DELETE',
    headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
  });
  if (!deleteRes.ok) {
    const errText = await deleteRes.text().catch(() => '');
    console.error(`[manage-user:delete] delete failed (status ${deleteRes.status}):`, errText);
    return { status: 502, body: { error: 'Could not delete user', detail: errText } };
  }
  return { status: 200, body: { ok: true } };
}

async function handler(req, res) {
  const origin = req.headers.origin;
  if (isAllowedOrigin(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }
  if (req.method !== 'POST') {
    return json(res, 405, { error: 'Method not allowed' });
  }

  const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, SUPABASE_ANON_KEY } = process.env;
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY || !SUPABASE_ANON_KEY) {
    return json(res, 500, { error: 'Server misconfigured: missing required environment variables.' });
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (e) {
    return json(res, 400, { error: 'Invalid JSON body' });
  }

  const action = body && body.action;
  if (!['create', 'disable', 'delete'].includes(action)) {
    return json(res, 400, { error: "action must be one of 'create', 'disable', 'delete'" });
  }

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const caller = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!caller || !caller.id) return json(res, 401, { error: 'Invalid session' });

    const authorized = await callerCanManageUsers(caller.id, { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
    if (!authorized) return json(res, 403, { error: action === 'create' ? 'Not authorized to create users' : 'Not authorized to manage users' });

    const opts = { origin, supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY };
    const result = action === 'create' ? await actionCreate(body, opts)
      : action === 'disable' ? await actionDisable(body, caller, opts)
      : await actionDelete(body, caller, opts);
    return json(res, result.status, result.body);
  } catch (err) {
    console.error(`[manage-user:${action}] unhandled error:`, err);
    return json(res, 500, { error: 'Request failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 30 };
