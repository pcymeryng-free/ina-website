-- ============================================================================
-- migration_v77_newsletter_settings.sql
--
-- QUÉ AGREGA
-- Pablo (oct 2026): "las novedades diarias que se muestran en la pagina
-- news se puedan descargar en un newsletter en pdf en forma diaria y que
-- se puda configurar para que se envien por mail a una cuenta de correo
-- electronico."
--
-- Two new columns on the existing app_settings singleton row (same
-- table/pattern as migration_v74_debug_mode.sql's debug_mode — one global
-- row, readable by anyone, writable only by an admin):
--   - newsletter_enabled: whether api/update-news.js should email the PDF
--     newsletter after each day's curation run, in addition to always
--     building it on-demand for news.html's "Download PDF" button (that
--     part needs no flag — it's just a public read of already-public data).
--   - newsletter_recipient_email: where to send it. A single address is
--     enough for what was actually asked for; if this ever needs multiple
--     recipients, this becomes a comma-separated list read by
--     api/update-news.js, not a schema change.
-- ============================================================================

alter table public.app_settings
  add column if not exists newsletter_enabled boolean not null default false,
  add column if not exists newsletter_recipient_email text;
