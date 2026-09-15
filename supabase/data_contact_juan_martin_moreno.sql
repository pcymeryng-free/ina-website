-- ============================================================================
-- Alta de Contacto — Juan Martín Moreno (The World Bank)
--
-- QUÉ ES
-- Carga manual del contacto de la tarjeta de presentación que Pablo
-- fotografió, mientras la función de lectura automática de tarjetas
-- (api/extract-business-card.js — ver migration_v45_contact_business_card.sql)
-- todavía no está desplegada en Vercel (el archivo existe en el proyecto
-- pero falta el `git push` que dispara el deploy — ver la conversación).
--
-- Crea (si no existe todavía) la Empresa "The World Bank" en Master Data,
-- etiquetada como financial_entity (institución de financiamiento para el
-- desarrollo), y el Contacto de Juan Martín Moreno con su cargo vigente ahí.
--
-- Datos tomados de la tarjeta:
--   Juan Martín Moreno — Senior Social Protection Economist
--   The World Bank (IBRD · IDA | World Bank Group)
--   T +54 11 4316 0615   E jmoreno1@worldbank.org
--   Bouchard 547, piso 29, C1106ABG, BUEWB, CABA, Argentina
--
-- CÓMO USAR
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. Si todavía no corriste supabase/migration_v44_master_data.sql, corrélo
--    primero (crea las tablas companies/contacts que este archivo usa).
-- 3. En la línea marcada "EDITAR" reemplazá el email por el de tu cuenta de
--    la plataforma INA (tiene que ser advisor o admin, ya registrada en
--    public.profiles) — queda como created_by de la Empresa y el Contacto.
-- 4. Ejecutá el resto del script. Es seguro correrlo más de una vez: si "The
--    World Bank" ya existe como Empresa la reutiliza en vez de duplicarla,
--    y el contacto se identifica por email así que tampoco se duplica.
-- 5. Al final corre un SELECT que muestra el contacto creado, para
--    confirmar.
-- ============================================================================

do $$
declare
  v_creator_id uuid;
  v_company_id uuid;
begin
  -- EDITAR: reemplazá por el email de tu cuenta INA (advisor o admin).
  select id into v_creator_id from public.profiles where email = 'pcymeryng@gmail.com';
  if v_creator_id is null then
    raise exception 'No se encontró un perfil con ese email. Editá la línea del email (EDITAR_TU_EMAIL@ejemplo.com) antes de correr este script.';
  end if;

  -- Empresa: reutiliza "The World Bank" si ya existe (comparación sin
  -- distinguir mayúsculas/minúsculas).
  select id into v_company_id from public.companies where lower(name) = lower('The World Bank');
  if v_company_id is null then
    insert into public.companies (name, types, country, website, notes, created_by)
    values (
      'The World Bank',
      array['financial_entity'],
      'Estados Unidos',
      'https://www.worldbank.org',
      'Grupo Banco Mundial (IBRD · IDA). Oficina Argentina: Bouchard 547, piso 29, C1106ABG, CABA.',
      v_creator_id
    )
    returning id into v_company_id;
  end if;

  -- Contacto: no lo duplica si ya existe uno con el mismo email.
  if not exists (select 1 from public.contacts where lower(email) = lower('jmoreno1@worldbank.org')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values (
      'Juan Martín Moreno',
      'jmoreno1@worldbank.org',
      '+54 11 4316 0615',
      'Senior Social Protection Economist',
      v_company_id,
      'Cargado desde tarjeta de presentación (IBRD · IDA | World Bank Group). Dirección: Bouchard 547, piso 29, C1106ABG, CABA, Argentina.',
      v_creator_id
    );
  end if;
end $$;

-- ============================================================================
-- Verificación
-- ============================================================================
select c.full_name, c.position_title, c.email, c.phone, co.name as company_name, co.types
from public.contacts c
join public.companies co on co.id = c.company_id
where lower(c.email) = lower('jmoreno1@worldbank.org');
