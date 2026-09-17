<?php
/**
 * INA Website — whoami.php
 *
 * Returns the caller's IP address and country as JSON, read from the
 * headers Cloudflare adds on every request it proxies to this site (see
 * MIGRACION_BLUEHOST.md) — no GeoIP lookup, no secrets, nothing else.
 *
 * Used by assets/platform.js (app/*.html, once per page load) to enrich
 * the activity_log rows it writes directly via the authenticated
 * Supabase client (INAPlatform.logActivity()/logPageView()) with the
 * same ip/country info the public site's log-visit.php gets "for free"
 * from Cloudflare on that side. This file only ever reads request
 * headers and never talks to Supabase itself, so it needs no API key at
 * all, anon or otherwise.
 *
 * Lives at the SITE ROOT on Bluehost (like contact.php/log-visit.php):
 * Bluehost has no Node.js, so anything the production domain needs
 * server-side has to be PHP.
 */

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$ip = isset($_SERVER['HTTP_CF_CONNECTING_IP'])
    ? $_SERVER['HTTP_CF_CONNECTING_IP']
    : (isset($_SERVER['REMOTE_ADDR']) ? $_SERVER['REMOTE_ADDR'] : null);

$country = isset($_SERVER['HTTP_CF_IPCOUNTRY']) ? $_SERVER['HTTP_CF_IPCOUNTRY'] : null;

echo json_encode(array('ip' => $ip, 'country' => $country));
