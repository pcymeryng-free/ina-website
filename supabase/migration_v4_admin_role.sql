-- ============================================================================
-- INA Platform — Migration v4: admin role + user management panel
-- Run this ONCE in your EXISTING Supabase project (the one where you already
-- ran schema.sql and migration_v2/v3): Dashboard → SQL Editor → New query →
-- paste this whole file → Run.
--
-- What this adds:
--   1. profiles.role now allows 'admin' in addition to 'user' / 'advisor'.
--      Admins can view every project (same as advisors) AND change any
--      user's role from the new app/admin.html panel.
--   2. profiles.email — mirrors auth.users.email, kept in sync going
--      forward by handle_new_user(). Backfilled below for existing rows.
--      Lets the admin panel list/search users without needing service-role
--      access to auth.users from the client.
--   3. is_admin() helper, mirroring is_advisor().
--   4. Updated profiles RLS: advisors AND admins can read every profile row
--      (previously only advisors could read their own row — see note
--      below); a new profiles_update_admin policy lets admins update any
--      user's row (used to change role). Self-role-change is still blocked
--      for everyone, including admins, by the existing
--      prevent_role_self_change_trigger from migration v3.
--
-- NOTE on point 4: the original schema's profiles_select_own policy only
-- ever allowed reading your OWN row, even for advisors — meaning the
-- "submitted by" name in the advisor all-projects grid may have been
-- silently blank for other users' projects. This migration fixes that
-- as a side effect of adding admin read access.
-- ============================================================================

-- 1. Add email column + backfill from auth.users for existing rows.
alter table public.profiles
  add column if not exists email text;

update public.profiles p
set email = u.email
from auth.users u
where u.id = p.id and (p.email is null or p.email <> u.email);

-- 2. Allow 'admin' in the role check constraint.
alter table public.profiles
  drop constraint if exists profiles_role_check;
alter table public.profiles
  add constraint profiles_role_check check (role in ('user', 'advisor', 'admin'));

-- 3. is_admin() helper (is_advisor() already exists from earlier migrations).
create or replace function public.is_admin()
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$;

-- 4. Replace the profiles SELECT policy so advisors AND admins can read
--    every profile row (see note above).
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_select_own_or_privileged" on public.profiles;
create policy "profiles_select_own_or_privileged" on public.profiles
  for select using (auth.uid() = id or public.is_advisor() or public.is_admin());

-- 5. New UPDATE policy so admins can change any user's row (role changes
--    made from app/admin.html). profiles_update_own (self-updates) is
--    untouched. The prevent_role_self_change_trigger still blocks an
--    admin from changing their OWN role via this path.
drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin" on public.profiles
  for update using (public.is_admin());

-- 6. Keep handle_new_user() in sync so new signups populate email too.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, organization, role_type, role, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'organization', ''),
    coalesce(new.raw_user_meta_data->>'role_type', 'other'),
    'user',
    new.email
  );
  return new;
end;
$$;

-- ============================================================================
-- After running this: create your first admin account normally through
-- the app (Sign up on /app/register.html, any role_type is fine), then
-- promote it to admin with:
--
--   update public.profiles set role = 'admin' where email = 'you@example.com';
--
-- (This one-time promotion has to be done here, in SQL Editor, with a
-- privileged connection — it's the same reason the very first advisor
-- also had to be promoted this way. Every admin promotion *after* this
-- first one can be done from app/admin.html instead.)
-- ============================================================================
