<?php
/**
 * INA Website — log-visit.php
 *
 * Logs an anonymous page view from the public (institutional) site into
 * Supabase's activity_log table — see supabase/migration_v63_activity_log.sql.
 * Called from assets/script.js on every public page load via an <img>
 * beacon (new Image().src = '/log-visit.php?path=...'), NOT fetch()/POST:
 * Bluehost's WAF ("Human Presence Check", Imunify360 rule 33355 — see the
 * long comment at the top of contact.php) intercepts AJAX POSTs it can't
 * verify come from a real browser navigation. A plain GET image request
 * doesn't trip that rule, the same reason the contact form had to move
 * off fetch() to a native form POST.
 *
 * No secrets live in this file. It writes to Supabase using the Anon Key
 * (the same public, safe-to-embed key already hardcoded in
 * assets/platform.js — Supabase's security model puts the real access
 * control in Postgres RLS policies, not in keeping this key secret). The
 * RLS policy "activity_log_insert_anon_pageview" only allows this
 * anonymous path to insert rows with event_type='page_view' and no
 * user_id, so even a malicious caller of this endpoint can't write
 * anything else into the table.
 *
 * Lives at the SITE ROOT on Bluehost, next to contact.html/index.html —
 * same reasoning as contact.php (Bluehost has no Node.js, so anything
 * that needs to run server-side on the production domain has to be PHP).
 */

// Always respond with a 1x1 transparent GIF, whether or not the insert
// succeeded — this is a fire-and-forget beacon, never worth surfacing an
// error to the visitor or retrying client-side.
function ina_log_visit_respond_pixel() {
    header('Content-Type: image/gif');
    header('Cache-Control: no-store');
    // Smallest valid GIF: 1x1 transparent pixel.
    echo base64_decode('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBTAA7');
    exit;
}

$supabaseUrl = 'https://lyyuxoltyyckfppfjbyn.supabase.co';
$supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5eXV4b2x0eXlja2ZwcGZqYnluIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM1MDYyNzIsImV4cCI6MjA5OTA4MjI3Mn0.2Ggj03wA2GILf-26PhDT4ZQx2g9ePI8u1WBLwMN774s';

function ina_log_visit_clean($value, $maxLen = 512) {
    $value = is_string($value) ? $value : '';
    $value = trim($value);
    if (function_exists('mb_substr')) {
        $value = mb_substr($value, 0, $maxLen);
    } else {
        $value = substr($value, 0, $maxLen);
    }
    return $value;
}

$path = ina_log_visit_clean(isset($_GET['path']) ? $_GET['path'] : '/', 512);
$referrer = ina_log_visit_clean(isset($_GET['ref']) ? $_GET['ref'] : '', 512);

// Real visitor IP: when the site sits behind Cloudflare (it does — see
// MIGRACION_BLUEHOST.md), REMOTE_ADDR is Cloudflare's edge IP, not the
// visitor's. CF-Connecting-IP is the header Cloudflare adds with the
// actual client IP.
$ip = isset($_SERVER['HTTP_CF_CONNECTING_IP'])
    ? $_SERVER['HTTP_CF_CONNECTING_IP']
    : (isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : null);

// Country: Cloudflare resolves this from the connecting IP for free on
// every request it proxies — no separate GeoIP lookup/API needed.
$country = isset($_SERVER['HTTP_CF_IPCOUNTRY']) ? $_SERVER['HTTP_CF_IPCOUNTRY'] : null;

$userAgent = ina_log_visit_clean(isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '', 512);

$payload = array(
    'event_type' => 'page_view',
    'user_id' => null,
    'path' => $path,
    'ip_address' => $ip,
    'country' => $country,
    'user_agent' => $userAgent,
);
if ($referrer !== '') {
    $payload['details'] = array('referrer' => $referrer);
}

$ch = curl_init($supabaseUrl . '/rest/v1/activity_log');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
curl_setopt($ch, CURLOPT_HTTPHEADER, array(
    'apikey: ' . $supabaseAnonKey,
    'Authorization: Bearer ' . $supabaseAnonKey,
    'Content-Type: application/json',
    'Prefer: return=minimal',
));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 3);
curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 2);
curl_exec($ch);
curl_close($ch);

ina_log_visit_respond_pixel();
