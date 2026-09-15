-- ============================================================================
-- Data: agregar a Master Data > Empresas las que figuran en la base de
-- productos y todavía no están cargadas como Empresa.
--
-- Per Pablo's request: "agregar a la base de empresas las que figuran en la
-- base de productos y que aun no figuran en la base de empresas".
--
-- CONTEXTO
-- Revisé supabase/data_products_telecom_infrastructure.sql (los 26 productos
-- cargados en esta misma sesión) y todo producto con un fabricante/proveedor
-- puntual ya está vinculado (vía company_id) a una Empresa que ya existe en
-- Master Data: Ciena, Nokia, Ericsson, STL, Qualcomm, Argela, ORACLE,
-- Google / Google Cloud, Amazon / AWS, Akamai, SpaceX, Hughes Network
-- Systems, Intelsat, Globalstar, Sateliot, INVAP, AcertiS e Ingenieros
-- Argentinos Asociados (IAA). Ninguno de esos productos referencia una
-- empresa que falte.
--
-- El único hueco real está en la DESCRIPCIÓN (no en company_id, que quedó en
-- NULL a propósito) del producto "Cable de fibra óptica submarino (repetido,
-- larga distancia)": ahí se nombran 3 proveedores típicos de ese rubro que
-- todavía no están en Master Data como Empresa — SubCom, Alcatel Submarine
-- Networks (ASN) y NEC. Este script las agrega.
--
-- No hay un fabricante único correcto para vincular a ese producto genérico
-- (los 3 son competidores en el mismo segmento), así que company_id de ese
-- producto queda en NULL como está — si Pablo quiere vincularlo a una de las
-- 3 puntualmente, decime a cuál y genero el UPDATE.
--
-- Verificadas por búsqueda web (setiembre 2026):
--   - SubCom (TE SubCom): con sede en Eatontown, Nueva Jersey (EE.UU.),
--     propiedad de Cerberus Capital Management desde 2018 (comprada a TE
--     Connectivity). Sitio: subcom.com.
--   - Alcatel Submarine Networks (ASN): con sede en Francia. Nokia vendió el
--     80% al Estado francés (cierre 31/12/2024), conservando 20% de forma
--     transitoria. Sitio: asn.com.
--   - NEC Corporation (División de Redes Submarinas): sede en Tokio, Japón.
--     Sitio: nec.com.
--
-- Idempotente: cada insert está guardado con "if not exists (... lower(name)
-- ...)", así que correr el script más de una vez no duplica ninguna Empresa.
-- Run manually in Supabase SQL Editor.
-- ============================================================================

do $$
declare
  v_creator_id uuid;
begin
  select id into v_creator_id from public.profiles where email = 'pcymeryng@gmail.com';

  if not exists (select 1 from public.companies where lower(name) = lower('SubCom')) then
    insert into public.companies (name, industry, country, website, notes, created_by)
    values (
      'SubCom',
      'manufacturer',
      'Estados Unidos',
      'https://www.subcom.com',
      'Proveedor de sistemas de cable submarino de fibra óptica (planta seca y húmeda). Propiedad de Cerberus Capital Management desde 2018 (ex TE Connectivity / Tyco Electronics Subsea Communications).',
      v_creator_id
    );
  end if;

  if not exists (select 1 from public.companies where lower(name) = lower('Alcatel Submarine Networks (ASN)')) then
    insert into public.companies (name, industry, country, website, notes, created_by)
    values (
      'Alcatel Submarine Networks (ASN)',
      'manufacturer',
      'Francia',
      'https://www.asn.com',
      'Fabricante y proveedor de sistemas de cable submarino. Ex subsidiaria de Nokia; el Estado francés adquirió el 80% (cierre 31/12/2024), Nokia retiene 20% de forma transitoria.',
      v_creator_id
    );
  end if;

  if not exists (select 1 from public.companies where lower(name) = lower('NEC')) then
    insert into public.companies (name, industry, country, website, notes, created_by)
    values (
      'NEC',
      'manufacturer',
      'Japón',
      'https://www.nec.com',
      'Corporación tecnológica japonesa; su División de Redes Submarinas es uno de los principales proveedores mundiales de sistemas de cable submarino de fibra óptica.',
      v_creator_id
    );
  end if;
end $$;

-- Verificación: confirmar que las 3 quedaron cargadas.
-- select name, industry, country, website from public.companies
-- where name in ('SubCom', 'Alcatel Submarine Networks (ASN)', 'NEC')
-- order by name;
