-- Unique project names (Pablo, nov 2026: "evita que haya 2 proyectos con
-- el mismo nombre" — two "HUB Digital Chubut" projects had been loaded
-- from the same document, one of them through a fresh "Nuevo proyecto"
-- instead of "Subir versión actualizada" on the existing one).
--
-- Names are compared ignoring case, accents and repeated/edge spaces:
-- "HUB Digital Chubut", "Hub digital  chubut" and "Hub Digital Chubút" are
-- the same name. Applies across ALL projects, every owner.
--
-- Run AFTER resolving any existing duplicates — the unique index below
-- fails to build otherwise. This query lists them:
--   select public.project_name_key(name) k, array_agg(id), array_agg(name)
--   from public.projects group by 1 having count(*) > 1;

create or replace function public.project_name_key(p_name text)
returns text
language sql
immutable
parallel safe
as $$
  select translate(
    lower(regexp_replace(btrim(coalesce(p_name, '')), '\s+', ' ', 'g')),
    'áàäâãéèëêíìïîóòöôõúùüûñç',
    'aaaaaeeeeiiiiooooouuuunc'
  );
$$;

create unique index if not exists projects_name_key_unique
  on public.projects (public.project_name_key(name));

-- Used by assets/platform.js (assertProjectNameAvailable) to give a clear
-- message BEFORE the insert/update. SECURITY DEFINER because RLS hides other
-- users' projects from the caller; it only ever answers true/false, never
-- which project or whose.
create or replace function public.project_name_taken(p_name text, p_exclude_id uuid default null)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.projects
    where public.project_name_key(name) = public.project_name_key(p_name)
      and (p_exclude_id is null or id <> p_exclude_id)
  );
$$;

revoke all on function public.project_name_taken(text, uuid) from public;
grant execute on function public.project_name_taken(text, uuid) to authenticated;
