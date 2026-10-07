/**
 * INA Platform — /api/set-user-disabled
 * Vercel serverless function (Node.js runtime, no external dependencies).
 *
 * Pablo asked for a way to "eliminar un usuario" from app/admin.html. A
 * real delete isn't safe on this schema — profiles.id cascades from
 * auth.users, and projects.user_id/programs.user_id/contracts.user_id/
 * roadmap_templates.user_id (and everything hanging off a project_id:
 * risks, roadmap instances, documents, analyses...) all cascade from
 * profiles.id. Deleting a user who ever created a project would silently
 * delete that project and everything under it. Confirmed with Pablo
 * (AskUserQuestion): the actual want is DEACTIVATE, not delete — block
 * sign-in, keep the profile and all their data exactly as-is, reversibly.
 *
 * Uses Supabase's own ban support (GoTrue Admin API's ban_duration) rather
 * than inventing a parallel lockout mechanism: setting it blocks future
 * sign-in AND future token refresh, so an already-active session is locked
 * out within its current access token's lifetime (~1h default) without
 * needing to forcibly kill live sessions. There's no literal "forever"
 * value, so a very long duration (876000h, ~100 years) stands in for a
 * permanent disable — Supabase's own documented pattern — and 'none'
 * re-enables. The profiles.disabled column (migration_v73) is kept in
 * sync purely so the client can show/filter on it cheaply — it does not
 * itself gate anything; the ban is what actually blocks access.
 *
 * Required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 * SUPABASE_ANON_KEY (same three api/create-user.js uses).
 */

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

/* Same allowlist/CORS approach as every other api/*.js here. */
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

/* Duplicated from api/create-user.js — mirrors assets/platform.js's
   entityPermission()/canManageUsers() exactly (admin.html is gated by
   requireCanManageUsers(), which also allows a custom role explicitly
   granted can_edit on 'user_management'; advisor is always excluded).
   Re-implemented server-side via service-role reads rather than trusting
   any client-supplied role flag, since this endpoint performs a
   privileged action. */
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

  const userId = typeof (body && body.userId) === 'string' ? body.userId : '';
  const disabled = !!(body && body.disabled);
  if (!userId) return json(res, 400, { error: 'userId is required' });

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const caller = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!caller || !caller.id) return json(res, 401, { error: 'Invalid session' });

    if (caller.id === userId) {
      return json(res, 400, { error: 'You cannot disable your own account' });
    }

    const authorized = await callerCanManageUsers(caller.id, { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
    if (!authorized) return json(res, 403, { error: 'Not authorized to manage users' });

    const banRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
      body: JSON.stringify({ ban_duration: disabled ? '876000h' : 'none' }),
    });
    if (!banRes.ok) {
      const errText = await banRes.text().catch(() => '');
      console.error(`[set-user-disabled] ban update failed (status ${banRes.status}):`, errText);
      return json(res, 502, { error: 'Could not update account access', detail: errText });
    }

    const profileRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Prefer: 'return=minimal',
      },
      body: JSON.stringify({ disabled }),
    });
    if (!profileRes.ok) {
      const errText = await profileRes.text().catch(() => '');
      console.error(`[set-user-disabled] profiles update failed (status ${profileRes.status}):`, errText);
      return json(res, 502, { error: 'Access was updated but the profile record could not be synced', detail: errText });
    }

    return json(res, 200, { ok: true, disabled });
  } catch (err) {
    console.error('[set-user-disabled] unhandled error:', err);
    return json(res, 500, { error: 'Request failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 30 };
