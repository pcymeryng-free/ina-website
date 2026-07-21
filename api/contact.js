/**
 * INA Website — /api/contact
 * Vercel serverless function (Node.js runtime) that sends the public
 * contact.html form to INA's real mailbox over SMTP, using the same
 * mail account Pablo already reads in Roundcube (Bluehost webmail) —
 * i.e. this does NOT use a third-party email API, it logs in to INA's
 * own mail server the same way an email client (Outlook, Roundcube,
 * Thunderbird...) would, and sends "as" info@inaai.co.
 *
 * Required environment variables (set in Vercel → Project → Settings →
 * Environment Variables — see MIGRACION_BLUEHOST.md "Parte 7" for how
 * to find these values in Bluehost cPanel):
 *   SMTP_HOST     — mail server hostname (cPanel → Email Accounts →
 *                   "Connect Devices" for info@inaai.co, e.g.
 *                   mail.international-network-advisors.com or the
 *                   server hostname Bluehost shows there)
 *   SMTP_PORT     — usually 465 (SSL) or 587 (STARTTLS)
 *   SMTP_USER     — the full mailbox address, info@inaai.co
 *   SMTP_PASS     — that mailbox's password (the Bluehost email account
 *                   password — the same one used to log into Roundcube)
 *   CONTACT_TO    — optional, defaults to info@inaai.co if unset
 *
 * This function stays on Vercel permanently, exactly like
 * /api/analyze-project.js — Bluehost (production, static hosting) has
 * no Node.js runtime, so the Bluehost-hosted contact.html calls this
 * over HTTPS via api.international-network-advisors.com instead of a
 * same-origin relative path (see ALLOWED_ORIGINS/isAllowedOrigin below
 * and assets/script.js's contactUrl() helper).
 */

const nodemailer = require('nodemailer');

function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(body));
}

/* CORS — same allowlist/reasoning as api/analyze-project.js: the
   production domain (with and without www) plus any Vercel preview
   deployment, never a wildcard. */
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

function isValidEmail(v) {
  return typeof v === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v);
}

// Very small HTML-escaper for the strings we interpolate into the
// HTML email body below (defense in depth — plain-text part has no
// injection risk, but the HTML part does if left unescaped).
function escapeHtml(v) {
  return String(v)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

async function handler(req, res) {
  const origin = req.headers.origin;
  if (isAllowedOrigin(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }
  if (req.method !== 'POST') {
    return json(res, 405, { error: 'Method not allowed' });
  }

  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, CONTACT_TO } = process.env;
  if (!SMTP_HOST || !SMTP_PORT || !SMTP_USER || !SMTP_PASS) {
    // Deliberately vague to the client, detailed in server logs — this
    // means Pablo hasn't set the SMTP_* env vars in Vercel yet.
    console.error('contact: missing SMTP_HOST/SMTP_PORT/SMTP_USER/SMTP_PASS env vars');
    return json(res, 500, { error: 'Email is not configured on the server yet.' });
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (e) {
    return json(res, 400, { error: 'Invalid JSON body' });
  }
  body = body || {};

  const name = (body.name || '').toString().trim();
  const org = (body.org || '').toString().trim();
  const type = (body.type || '').toString().trim();
  const email = (body.email || '').toString().trim();
  const message = (body.message || '').toString().trim();
  // Honeypot: a hidden field real visitors never fill in. If it has a
  // value, silently pretend success instead of telling a bot it failed.
  const honeypot = (body.company_website || '').toString().trim();

  if (honeypot) {
    return json(res, 200, { ok: true });
  }
  if (!name || !org || !email || !message) {
    return json(res, 400, { error: 'Missing required fields.' });
  }
  if (!isValidEmail(email)) {
    return json(res, 400, { error: 'Invalid email address.' });
  }
  if (message.length > 8000) {
    return json(res, 400, { error: 'Message is too long.' });
  }

  const port = Number(SMTP_PORT);
  const transporter = nodemailer.createTransport({
    host: SMTP_HOST,
    port,
    secure: port === 465, // 465 = implicit TLS, 587 = STARTTLS (secure:false, upgraded automatically)
    auth: { user: SMTP_USER, pass: SMTP_PASS },
  });

  const to = (CONTACT_TO || 'info@inaai.co').trim();
  const subject = `Advisory Request — ${org || name}`;
  const text =
    `New advisory request from the INA website contact form.\n\n` +
    `Name: ${name}\n` +
    `Organization: ${org}\n` +
    `Type: ${type || '—'}\n` +
    `Email: ${email}\n\n` +
    `Message:\n${message}`;
  const html =
    `<p>New advisory request from the INA website contact form.</p>` +
    `<p>` +
    `<b>Name:</b> ${escapeHtml(name)}<br>` +
    `<b>Organization:</b> ${escapeHtml(org)}<br>` +
    `<b>Type:</b> ${escapeHtml(type || '—')}<br>` +
    `<b>Email:</b> ${escapeHtml(email)}` +
    `</p>` +
    `<p><b>Message:</b><br>${escapeHtml(message).replace(/\n/g, '<br>')}</p>`;

  try {
    await transporter.sendMail({
      from: `"INA Website" <${SMTP_USER}>`,
      to,
      replyTo: `"${name}" <${email}>`,
      subject,
      text,
      html,
    });
    return json(res, 200, { ok: true });
  } catch (err) {
    console.error('contact: SMTP send failed', err);
    return json(res, 502, { error: 'Could not send the email right now.' });
  }
}

module.exports = handler;
module.exports.config = { maxDuration: 20 };
