/**
 * INA Platform — /api/create-user
 * Vercel serverless function (Node.js runtime, no external dependencies).
 *
 * Pablo (oct 2026): "permitir al usuario admin la posibilidad de dar de
 * alta usuarios en la plataforma." app/admin.html previously only listed
 * existing users and let an admin change their role — there was no way to
 * create one. assets/platform.js's signUp() can't be reused for this: it
 * calls the client-side supabaseClient.auth.signUp(), which always
 * authenticates the CALLING browser as the newly-created user — fine for
 * self-registration, but it would log the admin out of their own session
 * and into the new account. Creating a user on someone else's behalf
 * requires Supabase's Admin/GoTrue REST API (service-role key), hence this
 * standalone endpoint.
 *
 * Two clarifying decisions from Pablo (AskUserQuestion): new users are
 * onboarded by EMAIL INVITATION (they set their own password — this
 * endpoint never receives or sets one), and the admin picks the PLATFORM
 * ROLE at creation time (see the follow-up INAPlatform.setUserRole() call
 * made client-side in admin.html for non-default roles).
 *
 * handle_new_user() (supabase/schema.sql) bootstraps a `profiles` row from
 * `raw_user_meta_data` on ANY auth.users insert — admin-created via the
 * Admin API or self-registered via signUp(), it doesn't matter, both paths
 * populate that same column. So the invite's `data` payload below is
 * deliberately shaped to match exactly what that trigger reads
 * (full_name/organization/role_type) — no schema changes needed.
 *
 * Required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 * SUPABASE_ANON_KEY (same three every other endpoint here uses for
 * verifyUser(); SERVICE_ROLE_KEY is also what authorizes the actual Admin
 * API invite call and the authorization-check reads below).
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
   flag, since this endpoint performs a privileged action. */
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

  const email = typeof (body && body.email) === 'string' ? body.email.trim() : '';
  const fullName = typeof (body && body.fullName) === 'string' ? body.fullName.trim() : '';
  const organization = typeof (body && body.organization) === 'string' ? body.organization.trim() : '';
  const roleType = typeof (body && body.roleType) === 'string' ? body.roleType.trim() : '';
  if (!email || !fullName) {
    return json(res, 400, { error: 'email and fullName are required' });
  }

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const caller = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!caller || !caller.id) return json(res, 401, { error: 'Invalid session' });

    const authorized = await callerCanManageUsers(caller.id, { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
    if (!authorized) return json(res, 403, { error: 'Not authorized to create users' });

    // redirect_to can't be derived from `location` server-side — the
    // caller's own (already CORS-validated) Origin header is the right
    // source, falling back to the production domain if it's somehow
    // absent (e.g. a same-origin request with no Origin header sent).
    const redirectOrigin = isAllowedOrigin(origin) ? origin : 'https://www.international-network-advisors.com';
    const redirectTo = `${redirectOrigin}/app/accept-invite.html`;

    const inviteRes = await fetch(`${SUPABASE_URL}/auth/v1/invite?redirect_to=${encodeURIComponent(redirectTo)}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
      body: JSON.stringify({
        email,
        data: { full_name: fullName, organization, role_type: roleType || 'other' },
      }),
    });

    if (!inviteRes.ok) {
      const errText = await inviteRes.text().catch(() => '');
      if (isDuplicateEmailError(errText)) {
        return json(res, 409, { error: 'email_already_registered' });
      }
      console.error(`[create-user] invite request failed (status ${inviteRes.status}):`, errText);
      return json(res, 502, { error: 'Could not create user', detail: errText });
    }

    const created = await inviteRes.json();
    return json(res, 200, { ok: true, user: { id: created.id, email: created.email } });
  } catch (err) {
    console.error('[create-user] unhandled error:', err);
    return json(res, 500, { error: 'User creation failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 30 };
