-- ============================================================================
-- migration_v79_profiles_newsletter_language.sql
--
-- QUÉ AGREGA
-- Pablo (oct 2026): "cada usuario debe poder elegir no solo recibir el
-- newsletter sino tambien el idioma. (Ingles/Español)"
--
-- profiles.newsletter_language ('es' | 'en'), chosen next to the
-- receives_newsletter opt-in (migration_v78) in app/profile.html's "Email
-- Preferences" block. Defaults to 'es' — what every newsletter was sent in
-- before this column existed, so nobody's email changes language on their
-- own. api/update-news.js builds one PDF per language actually in use and
-- sends each group its own email.
--
-- The admin's single app_settings.newsletter_recipient_email has no
-- language of its own: if that address also belongs to a profile, that
-- profile's choice applies; otherwise it gets Spanish.
--
-- No new RLS policy needed — same reasoning as migration_v78:
-- profiles_update_own already lets a user update this column on their
-- own row.
-- ============================================================================

alter table public.profiles
  add column if not exists newsletter_language text not null default 'es';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'profiles_newsletter_language_check'
  ) then
    alter table public.profiles
      add constraint profiles_newsletter_language_check check (newsletter_language in ('es', 'en'));
  end if;
end $$;
