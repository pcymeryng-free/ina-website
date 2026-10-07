/**
 * INA Platform — /api/delete-user
 * Vercel serverless function (Node.js runtime, no external dependencies).
 *
 * Pablo: "el usuario admin puede además borrar definitivamente un usuario
 * siempre que no tenga proyectos asociados." Sits alongside
 * api/set-user-disabled.js (deactivate, reversible, the default/safe
 * action) as a second, genuinely destructive one.
 *
 * profiles.id cascades from auth.users.id, and projects.user_id/
 * programs.user_id/contracts.user_id/roadmap_templates.user_id all cascade
 * from profiles.id — each of those four is a real, independently-owned
 * top-level record (e.g. deleting a PROGRAM deliberately does NOT cascade
 * down to its member projects — see schema.sql's
 * programs_delete_own_or_admin comment — so a program is a genuinely
 * separate thing someone can own even with zero projects). Confirmed with
 * Pablo (AskUserQuestion) that the safety check covers all four tables,
 * not just projects — refuses the delete if the target owns ANY of them.
 * Every other user_id-referencing row in the schema is always paired with
 * a project_id on the same row, so it's bounded collateral of that
 * project's own lifecycle, not a separate business record — not part of
 * this check.
 *
 * Required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
 * SUPABASE_ANON_KEY (same three api/set-user-disabled.js uses).
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

/* Duplicated from api/create-user.js / api/set-user-disabled.js — mirrors
   assets/platform.js's entityPermission()/canManageUsers() exactly. */
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
  if (!userId) return json(res, 400, { error: 'userId is required' });

  const authHeader = req.headers.authorization || '';
  const accessToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
  if (!accessToken) return json(res, 401, { error: 'Missing Authorization header' });

  try {
    const caller = await verifyUser(accessToken, { supabaseUrl: SUPABASE_URL, anonKey: SUPABASE_ANON_KEY });
    if (!caller || !caller.id) return json(res, 401, { error: 'Invalid session' });

    if (caller.id === userId) {
      return json(res, 400, { error: 'You cannot delete your own account' });
    }

    const authorized = await callerCanManageUsers(caller.id, { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY });
    if (!authorized) return json(res, 403, { error: 'Not authorized to manage users' });

    const serviceOpts = { supabaseUrl: SUPABASE_URL, serviceKey: SUPABASE_SERVICE_ROLE_KEY };
    const [projects, programs, contracts, roadmap_templates] = await Promise.all([
      countOwned('projects', userId, serviceOpts),
      countOwned('programs', userId, serviceOpts),
      countOwned('contracts', userId, serviceOpts),
      countOwned('roadmap_templates', userId, serviceOpts),
    ]);
    const counts = { projects, programs, contracts, roadmap_templates };
    if (projects || programs || contracts || roadmap_templates) {
      return json(res, 409, { error: 'has_owned_records', counts });
    }

    const deleteRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
      method: 'DELETE',
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    });
    if (!deleteRes.ok) {
      const errText = await deleteRes.text().catch(() => '');
      console.error(`[delete-user] delete failed (status ${deleteRes.status}):`, errText);
      return json(res, 502, { error: 'Could not delete user', detail: errText });
    }

    return json(res, 200, { ok: true });
  } catch (err) {
    console.error('[delete-user] unhandled error:', err);
    return json(res, 500, { error: 'Request failed', detail: String((err && err.message) || err) });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 30 };
