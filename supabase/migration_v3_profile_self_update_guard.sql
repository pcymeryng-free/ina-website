-- ============================================================================
-- INA Platform — Migration v3: block self-service role escalation
-- Run this ONCE in your EXISTING Supabase project (SQL Editor → New query →
-- paste this whole file → Run). Needed for the new Profile page, where
-- users can now edit their own name/organization/"you are a" — this makes
-- sure that same update path can never be used to change their own
-- platform role (user/advisor) too.
--
-- Without this, the profiles_update_own RLS policy (which only checks
-- "is this your row", not "which columns") would technically allow a user
-- to grant themselves the advisor role via the same client-side update
-- call the profile UI uses — even though the Profile page itself never
-- sends the role field.
-- ============================================================================

create or replace function public.prevent_role_self_change()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  if auth.uid() = old.id and new.role is distinct from old.role then
    raise exception 'You cannot change your own platform role.';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_role_self_change_trigger on public.profiles;
create trigger prevent_role_self_change_trigger
  before update on public.profiles
  for each row execute procedure public.prevent_role_self_change();
