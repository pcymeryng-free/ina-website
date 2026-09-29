-- ============================================================================
-- migration_v69_contract_templates.sql
--
-- QUÉ AGREGA
-- Un default de NDA/SOW/Contrato de Servicio editable y reusable, por
-- encima del texto hardcodeado en CONTRACT_TEMPLATES (assets/platform.js).
-- Una fila por stage_type, org-wide (no por usuario) — igual que contracts/
-- contract_stages, esto es advisor/admin compartido, no dueño-por-fila.
--
-- Cada columna title_*/body_* es NULL hasta que alguien edita o sube un
-- template para ese idioma puntual — "guardar como default" pisa SOLO las
-- columnas de ESE idioma (title_en/body_en o title_es/body_es), nunca las
-- del otro. Con NULL, el código sigue usando CONTRACT_TEMPLATES como
-- fallback — no hace falta tener las dos versiones cargadas para que esto
-- funcione.
--
-- QUÉ NO CAMBIA
-- No toca contracts/contract_stages ni sus políticas.
-- ============================================================================

create table public.contract_templates (
  stage_type text primary key
    check (stage_type in ('nda', 'sow', 'service_contract')),
  title_en text,
  title_es text,
  body_en text,
  body_es text,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

alter table public.contract_templates enable row level security;

create policy "contract_templates_select_advisor_or_admin" on public.contract_templates
  for select using (public.is_advisor() or public.is_admin());

create policy "contract_templates_insert_advisor_or_admin" on public.contract_templates
  for insert with check (public.is_advisor() or public.is_admin());

create policy "contract_templates_update_advisor_or_admin" on public.contract_templates
  for update using (public.is_advisor() or public.is_admin())
  with check (public.is_advisor() or public.is_admin());

create policy "contract_templates_delete_advisor_or_admin" on public.contract_templates
  for delete using (public.is_advisor() or public.is_admin());
