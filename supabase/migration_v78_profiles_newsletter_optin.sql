-- ============================================================================
-- migration_v78_profiles_newsletter_optin.sql
--
-- QUÉ AGREGA
-- Pablo (oct 2026): "quiero que agregues a la configuracion de los
-- usuarios de INA la opcion de que reciban el newsletter. El default es
-- NO."
--
-- Per-user, self-service opt-in (app/profile.html's new "Email
-- Preferences" block) — separate from app_settings.newsletter_enabled/
-- newsletter_recipient_email (migration_v77), which stays as the admin's
-- single configured address and master on/off switch. api/update-news.js
-- now sends to the union of: that admin address (if newsletter_enabled),
-- plus every profile with receives_newsletter = true.
--
-- No new RLS policy needed: profiles_update_own (schema.sql) already lets
-- a user update any column on their own row (the self-update guard
-- trigger only blocks role/custom_role_id, see
-- migration_v3_profile_self_update_guard.sql), so this column is
-- self-editable the moment it exists.
-- ============================================================================

alter table public.profiles
  add column if not exists receives_newsletter boolean not null default false;
