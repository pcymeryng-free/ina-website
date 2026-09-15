-- ============================================================================
-- Alta masiva de Contactos y Empresas/Organismos (lote 2) — tarjetas 5-23
--
-- QUE ES
-- Carga los contactos de los archivos 5.pdf a 23.pdf (19 fotos de tarjetas,
-- ~140 tarjetas individuales, con varias repetidas entre archivos y algunas
-- ya cargadas por supabase/data_contacts_tarjetas_2026_09.sql), junto con
-- las Empresas y Organismos Públicos a los que pertenecen, en Master Data.
--
-- Reutiliza por NOMBRE toda empresa/organismo que ya exista (de este script
-- o del anterior) — por eso Ericsson, Nokia, Access Partnership, Amazon/AWS,
-- The World Bank, etc. no se duplican aunque aparezcan también acá.
--
-- COMO USAR
-- 1. Abri tu proyecto Supabase -> SQL Editor -> New query.
-- 2. Si todavia no corriste supabase/migration_v44_master_data.sql, corrélo
--    primero (crea las tablas companies/public_agencies/contacts).
-- 3. En la linea marcada "EDITAR" reemplaza el email por el de tu cuenta de
--    la plataforma INA (advisor o admin) -- queda como created_by.
-- 4. Ejecuta el resto del script. Es seguro correrlo mas de una vez.
-- 5. Al final corre un SELECT que muestra los contactos creados en ESTE
--    lote, para confirmar.
--
-- NOTAS DE CRITERIO
-- - Varias tarjetas del mismo empleado aparecen repetidas en distintos
--   archivos (ej. Marcelo Bailo, Silvina Vatnick, Carlos Gramajo, Claudio
--   Saes, Gabriela Lago, Martín Beyries, Juan Ignacio Cacace): se cargan
--   una sola vez.
-- - Amazon y AWS se unificaron en una sola Empresa ("Amazon / AWS"), ya que
--   todos los contactos usan email @amazon.com.
-- - Claudio Ipolitti tiene dos tarjetas (Telefe/Viacom y Paramount Global);
--   se cargó una sola vez bajo Paramount Global, con el email/rol de Telefe
--   anotado en Notas.
-- - Dos contactos no traían email ni empresa/organismo identificable en la
--   tarjeta (Mg. Sergio Nardini de UCEMA, Adriana Sarkis): se cargan sin
--   Empresa/Organismo asociado, y se identifican por NOMBRE en vez de email
--   para evitar duplicados si el script se corre de nuevo.
-- - Un contacto (Sóstenes Díaz, IFT México) no tenía el nombre impreso en la
--   tarjeta -- se infirió del email; se aclara en sus Notas.
-- ============================================================================

do $$
declare
  v_creator_id uuid;
  v_company_fundacion_sales uuid;
  v_company_amazon uuid;
  v_company_telespazio uuid;
  v_company_telefonica uuid;
  v_company_google uuid;
  v_company_kaen_approve uuid;
  v_company_enersa uuid;
  v_company_tia uuid;
  v_company_cullen_international uuid;
  v_company_echostar uuid;
  v_company_bell_labs_consulting uuid;
  v_company_telecom_personal_flow uuid;
  v_company_paramount_global uuid;
  v_company_directv_latam uuid;
  v_company_vrio_corp uuid;
  v_company_cytric_solutions uuid;
  v_company_cicomra uuid;
  v_company_cabase uuid;
  v_company_telecomsat uuid;
  v_company_global_outcomes uuid;
  v_company_apple uuid;
  v_company_pagbam uuid;
  v_company_madoc uuid;
  v_company_spacex uuid;
  v_company_invap uuid;
  v_company_sateliot uuid;
  v_company_zzoomm uuid;
  v_company_stonex uuid;
  v_company_sion uuid;
  v_company_huawei uuid;
  v_company_ookla uuid;
  v_company_condor_technologies uuid;
  v_company_red_intercable uuid;
  v_company_ilc uuid;
  v_company_masorange uuid;
  v_company_cadmipya uuid;
  v_company_claro uuid;
  v_company_intelsat uuid;
  v_company_argela uuid;
  v_company_lockheed_martin uuid;
  v_company_br_digital uuid;
  v_company_lu17 uuid;
  v_company_world_bank uuid;
  v_company_ai_da_robot uuid;
  v_company_telit_cinterion uuid;
  v_company_globalstar uuid;
  v_company_catip uuid;
  v_company_instituto_superior_cronica uuid;
  v_company_stl uuid;
  v_company_hispasat uuid;
  v_company_rivada_space_networks uuid;
  v_company_metrotel uuid;
  v_company_netflix uuid;
  v_company_ipe_digital uuid;
  v_company_iaa uuid;
  v_company_daia uuid;
  v_company_ciena uuid;
  v_company_air_iab uuid;
  v_company_asiet uuid;
  v_company_trans_advanced uuid;
  v_company_ericsson uuid;
  v_company_nokia uuid;
  v_company_omnispace uuid;
  v_agency_senado_nacion uuid;
  v_agency_dfc uuid;
  v_agency_sigen uuid;
  v_agency_us_dept_state uuid;
  v_agency_us_embassy_ar uuid;
  v_agency_bna uuid;
  v_agency_mpf_caba uuid;
  v_agency_cij_policia_judicial uuid;
  v_agency_hcdn uuid;
  v_agency_correo_argentino uuid;
  v_agency_aerolineas_argentinas uuid;
  v_agency_cnv uuid;
  v_agency_enre uuid;
  v_agency_policia_federal uuid;
  v_agency_sec_industria_comercio uuid;
  v_agency_embajada_argentina_madrid uuid;
  v_agency_ift_mexico uuid;
  v_agency_gov_sweden uuid;
  v_agency_bahamas_mfa uuid;
  v_agency_urca_bahamas uuid;
  v_agency_indotel uuid;
  v_agency_ustda uuid;
  v_agency_ntia uuid;
  v_agency_us_dod_pentagon uuid;
  v_agency_oecd uuid;
  v_agency_itu uuid;
  v_agency_mic_japan uuid;
  v_agency_haca_morocco uuid;
  v_agency_crc_mongolia uuid;
  v_agency_miit_china uuid;
  v_agency_caict_china uuid;
  v_agency_nic_chile uuid;
begin
  -- EDITAR: reemplaza por el email de tu cuenta INA (advisor o admin).
  select id into v_creator_id from public.profiles where email = 'pcymeryng@gmail.com';
  if v_creator_id is null then
    raise exception 'No se encontro un perfil con ese email. Editá la linea del email antes de correr este script.';
  end if;

  -- ==========================================================================
  -- Empresas (reutiliza por nombre si ya existen)
  -- ==========================================================================

  select id into v_company_fundacion_sales from public.companies where lower(name) = lower('Fundación SALES');
  if v_company_fundacion_sales is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Fundación SALES', '{}', 'Argentina', null, v_creator_id)
    returning id into v_company_fundacion_sales;
  end if;

  select id into v_company_amazon from public.companies where lower(name) = lower('Amazon / AWS');
  if v_company_amazon is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Amazon / AWS', array['service_provider'], 'Estados Unidos', 'https://aws.amazon.com', v_creator_id)
    returning id into v_company_amazon;
  end if;

  select id into v_company_telespazio from public.companies where lower(name) = lower('Telespazio (a Leonardo and Thales company)');
  if v_company_telespazio is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Telespazio (a Leonardo and Thales company)', array['service_provider'], 'Italia', 'https://www.telespazio.com', v_creator_id)
    returning id into v_company_telespazio;
  end if;

  select id into v_company_telefonica from public.companies where lower(name) = lower('Telefónica');
  if v_company_telefonica is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Telefónica', array['service_provider'], 'España', 'https://www.telefonica.com', v_creator_id)
    returning id into v_company_telefonica;
  end if;

  select id into v_company_google from public.companies where lower(name) = lower('Google / Google Cloud');
  if v_company_google is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Google / Google Cloud', array['service_provider'], 'Estados Unidos', 'https://cloud.google.com', v_creator_id)
    returning id into v_company_google;
  end if;

  select id into v_company_kaen_approve from public.companies where lower(name) = lower('Kaen / Approve ITSA');
  if v_company_kaen_approve is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Kaen / Approve ITSA', array['service_provider'], 'Argentina', 'https://www.approve-itsa.com', v_creator_id)
    returning id into v_company_kaen_approve;
  end if;

  select id into v_company_enersa from public.companies where lower(name) = lower('Enersa (Energía de Entre Ríos S.A.)');
  if v_company_enersa is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Enersa (Energía de Entre Ríos S.A.)', array['service_provider'], 'Argentina', null, v_creator_id)
    returning id into v_company_enersa;
  end if;

  select id into v_company_tia from public.companies where lower(name) = lower('Telecommunications Industry Association (TIA)');
  if v_company_tia is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Telecommunications Industry Association (TIA)', '{}', 'Estados Unidos', 'https://tiaonline.org', v_creator_id)
    returning id into v_company_tia;
  end if;

  select id into v_company_cullen_international from public.companies where lower(name) = lower('Cullen International');
  if v_company_cullen_international is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Cullen International', array['service_provider'], 'Bélgica', 'https://www.cullen-international.com', v_creator_id)
    returning id into v_company_cullen_international;
  end if;

  select id into v_company_echostar from public.companies where lower(name) = lower('EchoStar Corporation');
  if v_company_echostar is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('EchoStar Corporation', array['manufacturer'], 'Estados Unidos', 'https://www.echostar.com', v_creator_id)
    returning id into v_company_echostar;
  end if;

  select id into v_company_bell_labs_consulting from public.companies where lower(name) = lower('Bell Labs Consulting');
  if v_company_bell_labs_consulting is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Bell Labs Consulting', array['service_provider'], 'Estados Unidos', 'https://www.bell-labs.com', v_creator_id)
    returning id into v_company_bell_labs_consulting;
  end if;

  select id into v_company_telecom_personal_flow from public.companies where lower(name) = lower('Telecom Personal Flow (Telecom Argentina)');
  if v_company_telecom_personal_flow is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Telecom Personal Flow (Telecom Argentina)', array['service_provider'], 'Argentina', null, v_creator_id)
    returning id into v_company_telecom_personal_flow;
  end if;

  select id into v_company_paramount_global from public.companies where lower(name) = lower('Paramount Global');
  if v_company_paramount_global is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Paramount Global', array['service_provider'], 'Estados Unidos', null, v_creator_id)
    returning id into v_company_paramount_global;
  end if;

  select id into v_company_directv_latam from public.companies where lower(name) = lower('DIRECTV LATAM');
  if v_company_directv_latam is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('DIRECTV LATAM', array['service_provider'], 'Argentina', null, v_creator_id)
    returning id into v_company_directv_latam;
  end if;

  select id into v_company_vrio_corp from public.companies where lower(name) = lower('VRIO Corp');
  if v_company_vrio_corp is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('VRIO Corp', array['service_provider'], 'Brasil', null, v_creator_id)
    returning id into v_company_vrio_corp;
  end if;

  select id into v_company_cytric_solutions from public.companies where lower(name) = lower('Cytric Solutions');
  if v_company_cytric_solutions is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Cytric Solutions', array['service_provider'], 'Argentina', 'https://www.cytricsolutions.com', v_creator_id)
    returning id into v_company_cytric_solutions;
  end if;

  select id into v_company_cicomra from public.companies where lower(name) = lower('CICOMRA (Cámara de Informática y Comunicaciones de la República Argentina)');
  if v_company_cicomra is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('CICOMRA (Cámara de Informática y Comunicaciones de la República Argentina)', '{}', 'Argentina', 'https://www.cicomra.org.ar', v_creator_id)
    returning id into v_company_cicomra;
  end if;

  select id into v_company_cabase from public.companies where lower(name) = lower('Cámara Argentina de Internet (CABASE)');
  if v_company_cabase is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Cámara Argentina de Internet (CABASE)', '{}', 'Argentina', 'https://www.cabase.org.ar', v_creator_id)
    returning id into v_company_cabase;
  end if;

  select id into v_company_telecomsat from public.companies where lower(name) = lower('TelecomSat LLC.');
  if v_company_telecomsat is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('TelecomSat LLC.', array['service_provider'], 'Estados Unidos', 'https://www.telecom-sat.com', v_creator_id)
    returning id into v_company_telecomsat;
  end if;

  select id into v_company_global_outcomes from public.companies where lower(name) = lower('Global Outcomes');
  if v_company_global_outcomes is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Global Outcomes', array['service_provider'], 'Estados Unidos', null, v_creator_id)
    returning id into v_company_global_outcomes;
  end if;

  select id into v_company_apple from public.companies where lower(name) = lower('Apple');
  if v_company_apple is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Apple', array['manufacturer'], 'Estados Unidos', 'https://www.apple.com', v_creator_id)
    returning id into v_company_apple;
  end if;

  select id into v_company_pagbam from public.companies where lower(name) = lower('PAGBAM (Pérez Alati, Grondona, Benites & Arntsen)');
  if v_company_pagbam is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('PAGBAM (Pérez Alati, Grondona, Benites & Arntsen)', array['service_provider'], 'Argentina', 'https://www.pagbam.com', v_creator_id)
    returning id into v_company_pagbam;
  end if;

  select id into v_company_madoc from public.companies where lower(name) = lower('MADOC — Patagonian Single Malt');
  if v_company_madoc is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('MADOC — Patagonian Single Malt', array['manufacturer'], 'Argentina', 'https://www.madocwhisky.com', v_creator_id)
    returning id into v_company_madoc;
  end if;

  select id into v_company_spacex from public.companies where lower(name) = lower('SpaceX');
  if v_company_spacex is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('SpaceX', array['manufacturer'], 'Estados Unidos', 'https://www.spacex.com', v_creator_id)
    returning id into v_company_spacex;
  end if;

  select id into v_company_invap from public.companies where lower(name) = lower('INVAP');
  if v_company_invap is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('INVAP', array['manufacturer'], 'Argentina', 'https://www.invap.com.ar', v_creator_id)
    returning id into v_company_invap;
  end if;

  select id into v_company_sateliot from public.companies where lower(name) = lower('Sateliot');
  if v_company_sateliot is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Sateliot', array['service_provider'], 'España', 'https://www.sateliot.space', v_creator_id)
    returning id into v_company_sateliot;
  end if;

  select id into v_company_zzoomm from public.companies where lower(name) = lower('Zzoomm plc');
  if v_company_zzoomm is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Zzoomm plc', array['service_provider'], 'Reino Unido', 'https://www.zzoomm.com', v_creator_id)
    returning id into v_company_zzoomm;
  end if;

  select id into v_company_stonex from public.companies where lower(name) = lower('StoneX Group Inc.');
  if v_company_stonex is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('StoneX Group Inc.', array['financial_entity'], 'Argentina', 'https://www.stonex.com', v_creator_id)
    returning id into v_company_stonex;
  end if;

  select id into v_company_sion from public.companies where lower(name) = lower('SION');
  if v_company_sion is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('SION', array['financial_entity'], 'Argentina', 'https://sion.com', v_creator_id)
    returning id into v_company_sion;
  end if;

  select id into v_company_huawei from public.companies where lower(name) = lower('Huawei');
  if v_company_huawei is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Huawei', array['manufacturer'], 'China', 'https://www.huawei.com', v_creator_id)
    returning id into v_company_huawei;
  end if;

  select id into v_company_ookla from public.companies where lower(name) = lower('Ookla (Ziff Davis)');
  if v_company_ookla is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Ookla (Ziff Davis)', array['service_provider'], 'Estados Unidos', 'https://www.ookla.com', v_creator_id)
    returning id into v_company_ookla;
  end if;

  select id into v_company_condor_technologies from public.companies where lower(name) = lower('Condor Technologies');
  if v_company_condor_technologies is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Condor Technologies', array['service_provider'], 'Argentina', 'https://www.condortech.com.ar', v_creator_id)
    returning id into v_company_condor_technologies;
  end if;

  select id into v_company_red_intercable from public.companies where lower(name) = lower('Red Intercable');
  if v_company_red_intercable is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Red Intercable', array['service_provider'], 'Argentina', null, v_creator_id)
    returning id into v_company_red_intercable;
  end if;

  select id into v_company_ilc from public.companies where lower(name) = lower('ILC');
  if v_company_ilc is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('ILC', array['service_provider'], 'Argentina', 'https://www.ilcsite.com', v_creator_id)
    returning id into v_company_ilc;
  end if;

  select id into v_company_masorange from public.companies where lower(name) = lower('MASORANGE');
  if v_company_masorange is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('MASORANGE', array['service_provider'], 'España', 'https://masorange.es', v_creator_id)
    returning id into v_company_masorange;
  end if;

  select id into v_company_cadmipya from public.companies where lower(name) = lower('CADMIPyA (Cámara Argentina de Distribuidores Mayoristas de Informática, Productores y Afines)');
  if v_company_cadmipya is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('CADMIPyA (Cámara Argentina de Distribuidores Mayoristas de Informática, Productores y Afines)', '{}', 'Argentina', null, v_creator_id)
    returning id into v_company_cadmipya;
  end if;

  select id into v_company_claro from public.companies where lower(name) = lower('Claro (América Móvil)');
  if v_company_claro is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Claro (América Móvil)', array['service_provider'], 'Argentina', 'https://www.claro.com.ar', v_creator_id)
    returning id into v_company_claro;
  end if;

  select id into v_company_intelsat from public.companies where lower(name) = lower('Intelsat');
  if v_company_intelsat is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Intelsat', array['service_provider'], 'Estados Unidos', 'https://www.intelsat.com', v_creator_id)
    returning id into v_company_intelsat;
  end if;

  select id into v_company_argela from public.companies where lower(name) = lower('Argela');
  if v_company_argela is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Argela', array['manufacturer'], 'Turquía', 'https://www.argela.com', v_creator_id)
    returning id into v_company_argela;
  end if;

  select id into v_company_lockheed_martin from public.companies where lower(name) = lower('Lockheed Martin Corporation');
  if v_company_lockheed_martin is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Lockheed Martin Corporation', array['manufacturer'], 'Estados Unidos', null, v_creator_id)
    returning id into v_company_lockheed_martin;
  end if;

  select id into v_company_br_digital from public.companies where lower(name) = lower('br.digital Telecom');
  if v_company_br_digital is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('br.digital Telecom', array['service_provider'], 'Brasil', 'https://br.digital', v_creator_id)
    returning id into v_company_br_digital;
  end if;

  select id into v_company_lu17 from public.companies where lower(name) = lower('#LA17 / LU17 (Puerto Madryn)');
  if v_company_lu17 is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('#LA17 / LU17 (Puerto Madryn)', '{}', 'Argentina', 'https://www.lu17.com', v_creator_id)
    returning id into v_company_lu17;
  end if;

  select id into v_company_world_bank from public.companies where lower(name) = lower('The World Bank');
  if v_company_world_bank is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('The World Bank', array['financial_entity'], 'Estados Unidos', 'https://www.worldbank.org', v_creator_id)
    returning id into v_company_world_bank;
  end if;

  select id into v_company_ai_da_robot from public.companies where lower(name) = lower('AI-DA Robot');
  if v_company_ai_da_robot is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('AI-DA Robot', '{}', 'Reino Unido', 'https://www.ai-darobot.com', v_creator_id)
    returning id into v_company_ai_da_robot;
  end if;

  select id into v_company_telit_cinterion from public.companies where lower(name) = lower('Telit Cinterion');
  if v_company_telit_cinterion is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Telit Cinterion', array['manufacturer'], 'Italia', 'https://www.telit.com', v_creator_id)
    returning id into v_company_telit_cinterion;
  end if;

  select id into v_company_globalstar from public.companies where lower(name) = lower('Globalstar');
  if v_company_globalstar is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Globalstar', array['service_provider'], 'Estados Unidos', 'https://www.globalstar.com', v_creator_id)
    returning id into v_company_globalstar;
  end if;

  select id into v_company_catip from public.companies where lower(name) = lower('CATIP (Cámara Argentina de Telefonía IP)');
  if v_company_catip is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('CATIP (Cámara Argentina de Telefonía IP)', '{}', 'Argentina', null, v_creator_id)
    returning id into v_company_catip;
  end if;

  select id into v_company_instituto_superior_cronica from public.companies where lower(name) = lower('Instituto Superior Crónica');
  if v_company_instituto_superior_cronica is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Instituto Superior Crónica', '{}', 'Argentina', null, v_creator_id)
    returning id into v_company_instituto_superior_cronica;
  end if;

  select id into v_company_stl from public.companies where lower(name) = lower('STL (Sterlite Technologies Limited)');
  if v_company_stl is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('STL (Sterlite Technologies Limited)', array['manufacturer'], 'India', 'https://www.stl.tech', v_creator_id)
    returning id into v_company_stl;
  end if;

  select id into v_company_hispasat from public.companies where lower(name) = lower('Hispasat');
  if v_company_hispasat is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Hispasat', array['service_provider'], 'España', null, v_creator_id)
    returning id into v_company_hispasat;
  end if;

  select id into v_company_rivada_space_networks from public.companies where lower(name) = lower('Rivada Space Networks');
  if v_company_rivada_space_networks is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Rivada Space Networks', array['service_provider'], 'Estados Unidos', 'https://www.rivada.com', v_creator_id)
    returning id into v_company_rivada_space_networks;
  end if;

  select id into v_company_metrotel from public.companies where lower(name) = lower('Metrotel');
  if v_company_metrotel is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Metrotel', array['service_provider'], 'Argentina', 'https://www.metrotel.com.ar', v_creator_id)
    returning id into v_company_metrotel;
  end if;

  select id into v_company_netflix from public.companies where lower(name) = lower('Netflix');
  if v_company_netflix is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Netflix', array['service_provider'], 'Estados Unidos', null, v_creator_id)
    returning id into v_company_netflix;
  end if;

  select id into v_company_ipe_digital from public.companies where lower(name) = lower('Research Institute for Digital Economy (IPE Digital)');
  if v_company_ipe_digital is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Research Institute for Digital Economy (IPE Digital)', '{}', 'Brasil', 'https://ipedigital.tech', v_creator_id)
    returning id into v_company_ipe_digital;
  end if;

  select id into v_company_iaa from public.companies where lower(name) = lower('Ingenieros Argentinos Asociados (IAA)');
  if v_company_iaa is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Ingenieros Argentinos Asociados (IAA)', array['service_provider'], 'Argentina', null, v_creator_id)
    returning id into v_company_iaa;
  end if;

  select id into v_company_daia from public.companies where lower(name) = lower('DAIA (Delegación de Asociaciones Israelitas Argentinas)');
  if v_company_daia is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('DAIA (Delegación de Asociaciones Israelitas Argentinas)', '{}', 'Argentina', 'https://www.daia.org.ar', v_creator_id)
    returning id into v_company_daia;
  end if;

  select id into v_company_ciena from public.companies where lower(name) = lower('Ciena');
  if v_company_ciena is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Ciena', array['manufacturer'], 'Estados Unidos', null, v_creator_id)
    returning id into v_company_ciena;
  end if;

  select id into v_company_air_iab from public.companies where lower(name) = lower('Asociación Internacional de Radiodifusión (AIR/IAB)');
  if v_company_air_iab is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Asociación Internacional de Radiodifusión (AIR/IAB)', '{}', 'Uruguay', 'http://www.airiab.org', v_creator_id)
    returning id into v_company_air_iab;
  end if;

  select id into v_company_asiet from public.companies where lower(name) = lower('ASIET (Asociación Interamericana de Empresas de Telecomunicaciones)');
  if v_company_asiet is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('ASIET (Asociación Interamericana de Empresas de Telecomunicaciones)', '{}', 'Costa Rica', 'https://asiet.lat', v_creator_id)
    returning id into v_company_asiet;
  end if;

  select id into v_company_trans_advanced from public.companies where lower(name) = lower('Trans (transadvanced.tech)');
  if v_company_trans_advanced is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Trans (transadvanced.tech)', array['service_provider'], 'Argentina', null, v_creator_id)
    returning id into v_company_trans_advanced;
  end if;

  select id into v_company_ericsson from public.companies where lower(name) = lower('Ericsson');
  if v_company_ericsson is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Ericsson', array['manufacturer'], 'Suecia', 'https://www.ericsson.com', v_creator_id)
    returning id into v_company_ericsson;
  end if;

  select id into v_company_nokia from public.companies where lower(name) = lower('Nokia');
  if v_company_nokia is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Nokia', array['manufacturer'], 'Finlandia', 'https://www.nokia.com', v_creator_id)
    returning id into v_company_nokia;
  end if;

  select id into v_company_omnispace from public.companies where lower(name) = lower('Omnispace');
  if v_company_omnispace is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Omnispace', array['service_provider'], 'Estados Unidos', 'https://www.omnispace.com', v_creator_id)
    returning id into v_company_omnispace;
  end if;

  -- ==========================================================================
  -- Organismos Publicos (reutiliza por nombre si ya existen)
  -- ==========================================================================

  select id into v_agency_senado_nacion from public.public_agencies where lower(name) = lower('Senado de la Nación Argentina');
  if v_agency_senado_nacion is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Senado de la Nación Argentina', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_senado_nacion;
  end if;

  select id into v_agency_dfc from public.public_agencies where lower(name) = lower('U.S. International Development Finance Corporation (DFC)');
  if v_agency_dfc is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('U.S. International Development Finance Corporation (DFC)', 'international', 'Estados Unidos', null, v_creator_id)
    returning id into v_agency_dfc;
  end if;

  select id into v_agency_sigen from public.public_agencies where lower(name) = lower('Sindicatura General de la Nación (SIGEN)');
  if v_agency_sigen is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Sindicatura General de la Nación (SIGEN)', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_sigen;
  end if;

  select id into v_agency_us_dept_state from public.public_agencies where lower(name) = lower('U.S. Department of State');
  if v_agency_us_dept_state is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('U.S. Department of State', 'international', 'Estados Unidos', null, v_creator_id)
    returning id into v_agency_us_dept_state;
  end if;

  select id into v_agency_us_embassy_ar from public.public_agencies where lower(name) = lower('Embassy of the United States of America (Argentina / España)');
  if v_agency_us_embassy_ar is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Embassy of the United States of America (Argentina / España)', 'international', 'Estados Unidos', 'Incluye postings en Buenos Aires y Madrid.', v_creator_id)
    returning id into v_agency_us_embassy_ar;
  end if;

  select id into v_agency_bna from public.public_agencies where lower(name) = lower('Banco de la Nación Argentina');
  if v_agency_bna is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Banco de la Nación Argentina', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_bna;
  end if;

  select id into v_agency_mpf_caba from public.public_agencies where lower(name) = lower('Ministerio Público Fiscal — Ciudad Autónoma de Buenos Aires');
  if v_agency_mpf_caba is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Ministerio Público Fiscal — Ciudad Autónoma de Buenos Aires', 'municipal', 'Argentina', null, v_creator_id)
    returning id into v_agency_mpf_caba;
  end if;

  select id into v_agency_cij_policia_judicial from public.public_agencies where lower(name) = lower('CIJ — Cuerpo de Investigaciones Judiciales (Policía Judicial)');
  if v_agency_cij_policia_judicial is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('CIJ — Cuerpo de Investigaciones Judiciales (Policía Judicial)', 'municipal', 'Argentina', null, v_creator_id)
    returning id into v_agency_cij_policia_judicial;
  end if;

  select id into v_agency_hcdn from public.public_agencies where lower(name) = lower('Honorable Cámara de Diputados de la Nación (HCDN)');
  if v_agency_hcdn is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Honorable Cámara de Diputados de la Nación (HCDN)', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_hcdn;
  end if;

  select id into v_agency_correo_argentino from public.public_agencies where lower(name) = lower('Correo Argentino');
  if v_agency_correo_argentino is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Correo Argentino', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_correo_argentino;
  end if;

  select id into v_agency_aerolineas_argentinas from public.public_agencies where lower(name) = lower('Aerolíneas Argentinas');
  if v_agency_aerolineas_argentinas is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Aerolíneas Argentinas', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_aerolineas_argentinas;
  end if;

  select id into v_agency_cnv from public.public_agencies where lower(name) = lower('Comisión Nacional de Valores (CNV)');
  if v_agency_cnv is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Comisión Nacional de Valores (CNV)', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_cnv;
  end if;

  select id into v_agency_enre from public.public_agencies where lower(name) = lower('ENRE (Ente Nacional Regulador de la Electricidad)');
  if v_agency_enre is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('ENRE (Ente Nacional Regulador de la Electricidad)', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_enre;
  end if;

  select id into v_agency_policia_federal from public.public_agencies where lower(name) = lower('Policía Federal Argentina');
  if v_agency_policia_federal is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Policía Federal Argentina', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_policia_federal;
  end if;

  select id into v_agency_sec_industria_comercio from public.public_agencies where lower(name) = lower('Secretaría de Industria y Comercio — Ministerio de Economía');
  if v_agency_sec_industria_comercio is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Secretaría de Industria y Comercio — Ministerio de Economía', 'national', 'Argentina', null, v_creator_id)
    returning id into v_agency_sec_industria_comercio;
  end if;

  select id into v_agency_embajada_argentina_madrid from public.public_agencies where lower(name) = lower('Embajada de la República Argentina en España');
  if v_agency_embajada_argentina_madrid is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Embajada de la República Argentina en España', 'national', 'España', 'Representa al gobierno nacional argentino, con sede en Madrid.', v_creator_id)
    returning id into v_agency_embajada_argentina_madrid;
  end if;

  select id into v_agency_ift_mexico from public.public_agencies where lower(name) = lower('Instituto Federal de Telecomunicaciones (IFT) — México');
  if v_agency_ift_mexico is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Instituto Federal de Telecomunicaciones (IFT) — México', 'international', 'México', null, v_creator_id)
    returning id into v_agency_ift_mexico;
  end if;

  select id into v_agency_gov_sweden from public.public_agencies where lower(name) = lower('Government Offices of Sweden — Ministry for Foreign Affairs');
  if v_agency_gov_sweden is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Government Offices of Sweden — Ministry for Foreign Affairs', 'international', 'Suecia', null, v_creator_id)
    returning id into v_agency_gov_sweden;
  end if;

  select id into v_agency_bahamas_mfa from public.public_agencies where lower(name) = lower('Ministry of Foreign Affairs — The Bahamas');
  if v_agency_bahamas_mfa is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Ministry of Foreign Affairs — The Bahamas', 'international', 'Bahamas', null, v_creator_id)
    returning id into v_agency_bahamas_mfa;
  end if;

  select id into v_agency_urca_bahamas from public.public_agencies where lower(name) = lower('URCA — Utilities Regulation & Competition Authority (Bahamas)');
  if v_agency_urca_bahamas is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('URCA — Utilities Regulation & Competition Authority (Bahamas)', 'international', 'Bahamas', null, v_creator_id)
    returning id into v_agency_urca_bahamas;
  end if;

  select id into v_agency_indotel from public.public_agencies where lower(name) = lower('INDOTEL — Instituto Dominicano de las Telecomunicaciones');
  if v_agency_indotel is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('INDOTEL — Instituto Dominicano de las Telecomunicaciones', 'international', 'República Dominicana', null, v_creator_id)
    returning id into v_agency_indotel;
  end if;

  select id into v_agency_ustda from public.public_agencies where lower(name) = lower('U.S. Trade & Development Agency (USTDA)');
  if v_agency_ustda is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('U.S. Trade & Development Agency (USTDA)', 'international', 'Estados Unidos', null, v_creator_id)
    returning id into v_agency_ustda;
  end if;

  select id into v_agency_ntia from public.public_agencies where lower(name) = lower('National Telecommunications and Information Administration (NTIA)');
  if v_agency_ntia is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('National Telecommunications and Information Administration (NTIA)', 'international', 'Estados Unidos', null, v_creator_id)
    returning id into v_agency_ntia;
  end if;

  select id into v_agency_us_dod_pentagon from public.public_agencies where lower(name) = lower('U.S. Department of Defense (Pentagon)');
  if v_agency_us_dod_pentagon is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('U.S. Department of Defense (Pentagon)', 'international', 'Estados Unidos', null, v_creator_id)
    returning id into v_agency_us_dod_pentagon;
  end if;

  select id into v_agency_oecd from public.public_agencies where lower(name) = lower('OECD — Organisation for Economic Co-operation and Development');
  if v_agency_oecd is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('OECD — Organisation for Economic Co-operation and Development', 'international', 'Francia', null, v_creator_id)
    returning id into v_agency_oecd;
  end if;

  select id into v_agency_itu from public.public_agencies where lower(name) = lower('ITU — Unión Internacional de Telecomunicaciones');
  if v_agency_itu is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('ITU — Unión Internacional de Telecomunicaciones', 'international', 'Suiza', null, v_creator_id)
    returning id into v_agency_itu;
  end if;

  select id into v_agency_mic_japan from public.public_agencies where lower(name) = lower('Ministry of Internal Affairs and Communications — Japan (MIC)');
  if v_agency_mic_japan is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Ministry of Internal Affairs and Communications — Japan (MIC)', 'international', 'Japón', null, v_creator_id)
    returning id into v_agency_mic_japan;
  end if;

  select id into v_agency_haca_morocco from public.public_agencies where lower(name) = lower('HACA — Haute Autorité de la Communication Audiovisuelle (Marruecos)');
  if v_agency_haca_morocco is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('HACA — Haute Autorité de la Communication Audiovisuelle (Marruecos)', 'international', 'Marruecos', null, v_creator_id)
    returning id into v_agency_haca_morocco;
  end if;

  select id into v_agency_crc_mongolia from public.public_agencies where lower(name) = lower('Communications Regulatory Commission of Mongolia');
  if v_agency_crc_mongolia is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Communications Regulatory Commission of Mongolia', 'international', 'Mongolia', null, v_creator_id)
    returning id into v_agency_crc_mongolia;
  end if;

  select id into v_agency_miit_china from public.public_agencies where lower(name) = lower('Ministry of Industry and Information Technology of the People''s Republic of China (MIIT)');
  if v_agency_miit_china is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Ministry of Industry and Information Technology of the People''s Republic of China (MIIT)', 'international', 'China', null, v_creator_id)
    returning id into v_agency_miit_china;
  end if;

  select id into v_agency_caict_china from public.public_agencies where lower(name) = lower('CAICT — China Academy of Information and Communications Technology');
  if v_agency_caict_china is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('CAICT — China Academy of Information and Communications Technology', 'international', 'China', null, v_creator_id)
    returning id into v_agency_caict_china;
  end if;

  select id into v_agency_nic_chile from public.public_agencies where lower(name) = lower('NIC Chile / FCFM Universidad de Chile');
  if v_agency_nic_chile is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('NIC Chile / FCFM Universidad de Chile', 'international', 'Chile', null, v_creator_id)
    returning id into v_agency_nic_chile;
  end if;

  -- ==========================================================================
  -- Contactos (no duplica: por email si lo tienen, si no por nombre)
  -- ==========================================================================

  if not exists (select 1 from public.contacts where lower(email) = lower('meredith.potter@dfc.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Meredith Potter', 'meredith.potter@dfc.gov', '+1 (202) 817-1830', 'Managing Director for Policy (Indo-Pacific and ICT), Office of the Chief Executive', v_agency_dfc, '1100 New York Avenue, NW, Washington, DC 20527, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jmcandioti@sales.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Dr. José María Candioti', 'jmcandioti@sales.org.ar', '(11) 4394-8444', 'Presidente', v_company_fundacion_sales, 'Av. Córdoba 1752, 7° A, 1055 CABA, Argentina. También 15-4414-2038.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('shannonk@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Shannon Kellogg', 'shannonk@amazon.com', '703 309 9636', 'Vice President, AWS Public Policy, Americas', v_company_amazon, '601 New Jersey Ave NW, Ste 900, Washington, DC 20001, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('nicolas.degracia@telespazio.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Nicolás de Gracia', 'nicolas.degracia@telespazio.com', '+54 11 4852 8700', 'LATAM Deputy Regional Director, Chief Executive Officer Telespazio Argentina S.A', v_company_telespazio, 'Av. Del Libertador n° 5926/30, Piso 7° Torre Sur, C1428ARP, CABA, Argentina. Mobile +54 9 11 51018464, Fax +54 11 4852-8725.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('avalero@telefonica.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ana L. Valero Huete', 'avalero@telefonica.com', '+34 649 97 32 57', 'Directora de Políticas Públicas, Telefónica Hispanoamérica', v_company_telefonica, 'Distrito Telefónica - Norte 3, Ronda de la Comunicación s/n, 28050, Madrid, España.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mbeyries@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Martín Beyries', 'mbeyries@amazon.com', '+54 (911) 6964 9933', 'Head of Public Policy Southern Cone, Public Policy Americas', v_company_amazon, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('hernanc@google.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Hernan A. Conosciuto', 'hernanc@google.com', '+54 911 6710-3121', 'Customer Engineer, Public Sector - LATAM', v_company_google, 'Alicia Moreau de Justo 350, piso 2°, C1107AAH, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('vanmessem@google.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Hernán Van Messem', 'vanmessem@google.com', '+54 1139224180', 'Field Sales Representative, Google Cloud for Government', v_company_google, 'Alicia Moreau de Justo 350, piso 2°, C1107AAH, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('sherrera@sigen.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Santiago Juan Manuel Herrera', 'sherrera@sigen.gob.ar', '(011) 4317-2715', 'Síndico General Adjunto de la Nación', v_agency_sigen, 'Av. Corrientes 389, CABA, C1043AAD, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mbailo@sigen.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Cr. Marcelo Bailo', 'mbailo@sigen.gob.ar', '(011) 4317-2702', 'Síndico General Adjunto de la Nación', v_agency_sigen, 'Av. Corrientes 389, CABA, C1043AAD, Argentina. Cel +54 911 3185-4277.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('luis@approve-itsa.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Eng. Luis Kaen', 'luis@approve-itsa.com', '+54-9-351-6547222', 'President', v_company_kaen_approve, 'También luis@kaen.com.ar. Certificaciones ENACOM.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('FernandezJW@state.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Jose W. Fernandez', 'FernandezJW@state.gov', '(202)647-7575', 'Under Secretary for Economic Growth, Energy, and the Environment', v_agency_us_dept_state, 'Washington, D.C. 20520, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('ibergall@enersa.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ing. Ignacio L. Bergallo', 'ibergall@enersa.com.ar', '+54 9 11 41867212', 'Presidente', v_company_enersa, 'Buenos Aires 87, Paraná E3100BQA, Entre Ríos, Argentina. También +54 9 343 6220119, +54 343 4204461.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('bari@approve-itsa.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ariel Kaen', 'bari@approve-itsa.com', '+54-9-351-6770007', 'Vice President', v_company_kaen_approve, 'También bari@kaen.com.ar.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('dstehlin@tiaonline.org')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('David S. Stehlin', 'dstehlin@tiaonline.org', '703.907.7702', 'Chief Executive Officer', v_company_tia, '1310 N Courthouse Road, Suite 890, Arlington, VA 22201, USA. Mobile 609.273.4260.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('ezequiel.dominguez@cullen-international.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ezequiel Domínguez', 'ezequiel.dominguez@cullen-international.com', '+32 (0)470 37 28 45', 'Managing Director', v_company_cullen_international, 'Clos Lucien Outers 11-21/1, B-1160 Brussels, Bélgica. Tel +32 (0)2 73 87 208.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('facundo.fernandez.begni@ericsson.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Facundo Fernández Begni', 'facundo.fernandez.begni@ericsson.com', '+54 11 4319-5500', 'Government & Industry Relations Director', v_company_ericsson, 'Av. Del Libertador 174, Piso 9, B1638BEN, Vicente López, Argentina. Mobile +54 9 11 3497-2974.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Gabriela.Lago@echostar.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Gabriela C. Lago', 'Gabriela.Lago@echostar.com', '+1 703.628.5764', 'Senior Director, Regulatory Affairs', v_company_echostar, '11717 Exploration Lane, Germantown, MD 20876, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('claudio.saes@bell-labs.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Claudio Saes', 'claudio.saes@bell-labs.com', '+1 214 208 4970', 'Partner and Telecom Practice Leader, Strategy and Technology', v_company_bell_labs_consulting, '3201 Olympus Blvd, Dallas, TX 75019, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('carlos.gramajo@nokia.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Carlos Gramajo', 'carlos.gramajo@nokia.com', '+56 9 40276322', 'VP LAT Market, Cloud and Network Services', v_company_nokia, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('sostenes.diaz@ift.org.mx')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Sóstenes Díaz', 'sostenes.diaz@ift.org.mx', '+52 55 5015 4079', null, v_agency_ift_mexico, 'Nombre inferido del email — la tarjeta no lo imprime, solo QR y dirección. Insurgentes Sur 1143, Col. Nochebuena, C.P. 03720, Benito Juárez, Cd. de Méx. Cel +52 55 3987 6021.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('rarellano@teco.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ramón Bernabé Arellano', 'rarellano@teco.com.ar', '+54 11 4968 3258', 'Gerente, Asuntos Institucionales AMBA/PBA/Cuyo/Patagonia, Asuntos Legales e Institucionales', v_company_telecom_personal_flow, 'Gral. Hornos 690, C1272ACL Buenos Aires, Argentina. También +54 9 11 6609 2756.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('IglesiasS@state.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Maria Soledad Iglesias Liste', 'IglesiasS@state.gov', '(54-11) 5777-4259', 'Economic Specialist', v_agency_us_embassy_ar, 'Av. Colombia 4300, C1425GMN Buenos Aires, Argentina. Cel (54-9-11) 4175-2847.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mguarino@bna.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Martín A. Guarino', 'mguarino@bna.com.ar', '4347-6436', 'Responsable Convenios, Banca Individuos', v_agency_bna, 'Sucursal Plaza de Mayo, Bartolomé Mitre 326, C1036AAF, Cdad. de Buenos Aires. Cel (011) 3153-4498.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Marina.Millet@trade.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Marina Millet Gandara', 'Marina.Millet@trade.gov', '54-11-5777-4851', 'Commercial Advisor, U.S. Commercial Service', v_agency_us_embassy_ar, 'Avda. Colombia 4300, C1425GMN, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Eric.Olson@trade.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Eric P. Olson', 'Eric.Olson@trade.gov', null, 'Regional Senior Commercial Officer, Consejero Comercial para el Cono Sur (Argentina-Chile-Paraguay-Uruguay)', v_agency_us_embassy_ar, 'Avenida Colombia 4300, C1425GMN, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mcrudo@bna.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Mariana C. Crudo', 'mcrudo@bna.com.ar', '(011) 4347-6085', 'Resp. Equipo Gestión Comercial', v_agency_bna, 'Sucursal Plaza de Mayo, Bartolomé Mitre 326, C1036AAF, Cdad. de Buenos Aires.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('NelsonTH@state.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Tobin H. Nelson', 'NelsonTH@state.gov', '+54 11 5777-4467', 'Economic Officer', v_agency_us_embassy_ar, 'Av. Colombia 4300, C1425GMN, Buenos Aires, Argentina. Cel +54 9 11 4978-6080.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('leaplaza@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Cristóbal Lea-Plaza', 'leaplaza@amazon.com', '+56990355986', 'Public Policy Manager, LATAM', v_company_amazon, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(full_name) = lower('Mg. Sergio O. Nardini') and email is null) then
    insert into public.contacts (full_name, email, phone, position_title, notes, created_by)
    values ('Mg. Sergio O. Nardini', null, null, 'Director Ejecutivo, Centro de Emprendedores e Innovación — Universidad del CEMA (UCEMA)', 'Tarjeta sin email ni teléfono visibles.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mail@airiab.org')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Paulo Tonet Camargo', 'mail@airiab.org', '598.29011319', 'Presidente', v_company_air_iab, 'Oficina Central: Carlos Quijano 1264, Montevideo, Uruguay CP 11100. Email general de la asociación (no personal). También 598.29031879, fax 598.29080458.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('maryleana@tel.lat')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Maryleana Méndez', 'maryleana@tel.lat', '+506 8995 7395', 'Secretaria General', v_company_asiet, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mpikielny@fiscalias.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Martina Pikielny', 'mpikielny@fiscalias.gob.ar', '+54 11 5299 4400', 'Secretaría de Relaciones Institucionales', v_agency_mpf_caba, 'Av. Córdoba 820, piso 10° (C1054AAU), CABA. Cel +54 911 6814 7777.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('aeimer@trans.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Alfredo Eimer', 'aeimer@trans.com.ar', '+54 9 11 4410-9323', 'Presidente', v_company_trans_advanced, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('gunrein@fiscalias.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Gabriel Unrein', 'gunrein@fiscalias.gob.ar', '+54 11 5299 4400', 'Secretario General de Política Criminal y Asistencia a la Víctima', v_agency_mpf_caba, 'Av. Córdoba 820, piso 10° (C1054AAU), CABA. Interno 2272, Cel +54 911 4163 8672.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('ffox@fiscalias.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Federico D. T. Fox', 'ffox@fiscalias.gob.ar', '+54 9 11 3948 8845', 'Departamento de Investigación Judicial', v_agency_cij_policia_judicial, 'Chacabuco 151 (C1069AAC), CABA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('cipolitti@paramount.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Claudio Ipolitti', 'cipolitti@paramount.com', '+54 9 341 6424686', 'Vice President, Government Relations, Latín América', v_company_paramount_global, 'Cuyo 1844, B1640GHU, Martínez, Argentina. En Telefe/Viacom usa cipolitti@telefe.com.ar, T +5411 4102 1017, Prilidiano Pueyrredón 2989, P.2, B1640ILA, Martínez.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('manzorre@directvla.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Marcos Anzorreguy', 'manzorre@directvla.com.ar', '+54 (11) 3751-3572', 'External Affairs, Southern Region, DIRECTV LATAM', v_company_directv_latam, 'Cap. Justo G. Bermudez 4547, Panamerican Bureau Torre I Piso 1, B1605DII, Munro, Buenos Aires. Cel +54 (9 11) 5055-8040 / 2323-0476.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('gggonzalez@hcdn.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Gerardo Gustavo González', 'gggonzalez@hcdn.gob.ar', '+5437 0499-1874', 'Diputado de la Nación (Formosa)', v_agency_hcdn, 'Av. Rivadavia 1841, Anexo A, Piso 11, Oficina 1143, C1033AAI, CABA. También +54911 6075-0000 int 3143.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('vilma.bedia@senado.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Prof. Vilma Facunda Bedia', 'vilma.bedia@senado.gob.ar', '(5411) 2822-3415/3416', 'Senadora de la Nación', v_agency_senado_nacion, 'H. Yrigoyen 1702, p. 4°, of. 403, C1089AAH, CABA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('carmen.alvarez@senado.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Carmen Álvarez Rivero', 'carmen.alvarez@senado.gob.ar', '011 2822-3000', 'Senadora de la Nación', v_agency_senado_nacion, 'H. Yrigoyen 1849, piso 3°, of. 92 D. Cel 11-5725-0777, Int. 1382/1393.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('pedro.bentancourt@vriocorp.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Pedro dos Santos Bentancourt', 'pedro.bentancourt@vriocorp.com', '(55) 11 97203-4093', 'Vice Presidente', v_company_vrio_corp, 'Av. Dr. Chucri Zaidan, 920, Torre I - 16° andar, São Paulo - SP, Brasil.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('LangSA@state.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Steve Lang', 'LangSA@state.gov', '(202) 890-7775', 'Deputy Assistant Secretary, International Information & Communications Policy — Bureau of Cyberspace and Digital Policy', v_agency_us_dept_state, 'Washington D.C. 20520, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('CARLSONDA@STATE.GOV')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('David A. Carlson', 'CARLSONDA@STATE.GOV', '+34 91 587 2275', 'Coronel, Agregado Aéreo, Agregaduría de Defensa', v_agency_embajada_argentina_madrid, 'Nota: es personal de la Embajada de EE.UU. en Madrid, no de la embajada argentina — asociado a us_embassy_ar por consistencia de país de posteo. Serrano, 75, 28006 Madrid, España. Móvil +34 619 411 940.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('aguelman@cytricsolutions.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Alejandro Guelman', 'aguelman@cytricsolutions.com', '+54 11 51670212', 'CEO', v_company_cytric_solutions, 'Av. Cabildo 642, Piso 4to, C1426AAT, CABA, Argentina / 19370 Collins Avenue, CU1, Sunny Isles Beach, FL 33160, USA. Cel +54 911 44709079.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('larry.s.henschel.civ@mail.mil')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Larry Henschel', 'larry.s.henschel.civ@mail.mil', '571-232-9950', 'Director, International Future G', v_agency_us_dod_pentagon, 'OUSD R&E, 3030 Defense Pentagon, Washington, DC 20301, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('guillermo.wichmann@nokia.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Guillermo Wichmann', 'guillermo.wichmann@nokia.com', '+549 11 5831 4590', null, v_company_nokia, 'Av. Caseros 3039, 6th Floor, C1264AAK, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('capellan@cicomra.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ing. Norberto Capellán', 'capellan@cicomra.org.ar', '(5411) 4325 8839', 'Presidente', v_company_cicomra, 'Av. Córdoba 744, 2° Piso "D", C1054AAT, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('presidencia@cabase.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ing. Ariel Graizer', 'presidencia@cabase.org.ar', '(+5411) 5263 7456', 'Presidente — Cámara Argentina de Internet (CABASE) / AR-IX', v_company_cabase, 'Suipacha 128 3°F, C1008AAD, CABA, Argentina. Móvil (+54911) 4444 4822.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('perelmanr@telecom-sat.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ricardo Perelman', 'perelmanr@telecom-sat.com', '1 786 463 5301', null, v_company_telecomsat, '2030 S. Douglas Rd, Suite 119, Coral Gables, FL 33134, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('svatnick@global-outcomes.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Silvina Vatnick', 'svatnick@global-outcomes.com', '+1 202 714 7709', 'Managing Partner', v_company_global_outcomes, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mariodelacruz@apple.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Mario de la Cruz Sarabia', 'mariodelacruz@apple.com', '+52 56 5099 2710', 'Head of Government Affairs LATAM', v_company_apple, 'Paseo de la Reforma 483 P-41, Col. Cuauhtémoc, C.P. 06500, Ciudad de México, México.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mba@pagbam.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Marina Basavilbaso', 'mba@pagbam.com', '+598 93 433 444', 'Abogada', v_company_pagbam, 'Montevideo, Uruguay. También AR +549 11 3196 4843.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('tpa@pagbam.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Tomás Pérez Alati', 'tpa@pagbam.com', '54 11 4114 3075', 'Abogado', v_company_pagbam, 'Suipacha 1111, Piso 18, C1008AAW, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('ptognetti@gmail.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Pablo Tognetti', 'ptognetti@gmail.com', '+54 9294 429 5616', 'Creador, Destilador y todo lo demás', v_company_madoc, 'Dina Huapi, Río Negro, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('juandavid.velez@spacex.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Juan David Velez', 'juandavid.velez@spacex.com', '+1.786.602.5112', 'Global Licensing & Activation Manager', v_company_spacex, 'Rocket Road, McGregor, TX 76657, USA. También +1.254.840.5524.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('pabbate@invap.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Pablo Abbate', 'pabbate@invap.com.ar', '+54 294 440-9400', 'Deputy VP Nuclear Division, Business Development', v_company_invap, 'Av. Cmte. Luis Piedrabuena 4950, R8403CPV, S.C. de Bariloche, Río Negro, Argentina. Ext 1549, Mobile +54 9 294 481-8414.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('genovese@invap.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Luis E. Genovese', 'genovese@invap.com.ar', '+54 294 4409-300', 'Gerente Área Espacial', v_company_invap, 'Ext 1219, Cel +54 294 466-4741.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('ctisot@invap.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Christian Tisot', 'ctisot@invap.com.ar', '+54 294 4409-300', 'Deputy VP Space Division, Business Development', v_company_invap, 'Ext 1276, Mobile +54 9 294 428 3719.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('andres.jato@gov.se')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Andrés Jato', 'andres.jato@gov.se', '+46 (0)8 405 10 00', 'Ambassador', v_agency_gov_sweden, '103 33 Stockholm, Sweden. Mobile +46 70 381 07 73.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Ryan.Goodnight@spacex.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ryan Goodnight', 'Ryan.Goodnight@spacex.com', '+1.213.733.7167', 'Sr. Director, Global Licensing & Activation', v_company_spacex, 'Rocket Road, McGregor, TX 76657, USA. Phone +1.254.382.5068.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('carlos.riopedre@sateliot.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Carlos Riopedre', 'carlos.riopedre@sateliot.com', '+34 696 431 340', 'Managing Director, Chief Operating Officer', v_company_sateliot, 'Barcelona · San Diego · Space.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mario.maniewicz@itu.int')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Mario Maniewicz', 'mario.maniewicz@itu.int', '+41 22 730 5800', 'Director, Oficina de Radiocomunicaciones (BR)', v_agency_itu, 'Place des Nations, CH-1211 Ginebra 20, Suiza. Fax +41 22 730 5785.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('matthew.hare@zzoomm.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Matthew Hare', 'matthew.hare@zzoomm.com', '+44 7768 140180', 'Chief Executive', v_company_zzoomm, 'Fountain House, John Smith Drive, Oxford, OX4 2JY, Reino Unido. T +44 3333 119900.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mgavin@omnispace.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Molly Gavin', 'mgavin@omnispace.com', '+1 858 210 2037', 'Vice President, International Regulatory and Spectrum Policy', v_company_omnispace, '8255 Greensboro Drive, Suite 101, McLean, VA 22102, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('ofigueroa@sigen.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Cr. Oscar Rómulo Figueroa', 'ofigueroa@sigen.gob.ar', '(011) 4317-2859', 'Secretario Operativo', v_agency_sigen, 'Cel +54911 5568-4682.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('cbaldini@correoargentino.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Camilo Baldini', 'cbaldini@correoargentino.com.ar', '(54) 11 5432-2712', 'Presidente - CEO', v_agency_correo_argentino, 'Brandsen 2070, C1287AAR, CABA, Argentina. Cel +54 911 5061-9232.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Enrique.Algorta@stonex.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Enrique Algorta', 'Enrique.Algorta@stonex.com', '+54 9 11 3590 6852', 'Debt Capital Markets, Director', v_company_stonex, 'Sarmiento 459, 9° piso, C1041AAJ, Buenos Aires, Argentina. NASDAQ: SNEX.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('dmerino@sion.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Daniel Oscar Merino', 'dmerino@sion.com', '+549 11 6251 5661', 'Director de Administración y Finanzas', v_company_sion, 'Av. Chiclana 3345 HIT II Piso 5, CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('wangzhengan@huawei.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Jeff Wang', 'wangzhengan@huawei.com', '+86 13603006409', 'Vice President, Global Cyber Security & Privacy Office', v_company_huawei, 'Huawei Industrial Base, Bantian, Longgang District, Shenzhen 518129, China.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Nadia.Fraga@stonex.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Nadia Fraga', 'Nadia.Fraga@stonex.com', '+54 9 11 4195 0930', 'Structured Finance & Debt Capital Markets, Team Leader', v_company_stonex, 'Sarmiento 459, 9° piso, C1041AAJ, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('leonwms@bahamas.gov.bs')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('H.E. Leon R. Williams', 'leonwms@bahamas.gov.bs', '(242) 356-5956', 'Ambassador Extraordinary and Plenipotentiary, ITU — Ministry of Foreign Affairs', v_agency_bahamas_mfa, 'Goodman''s Bay Corporate Centre, West Bay Street, P.O. Box N-3746, Nassau, N.P., Bahamas. Cell (242) 424-4748; alt. email leonrwms@gmail.com.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('JMcCartney@urcabahamas.bs')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Juan McCartney', 'JMcCartney@urcabahamas.bs', '242.393.0234', 'Corporate and Consumer Relations Manager', v_agency_urca_bahamas, 'Frederick House, Frederick Street, P.O. Box N-4860, Nassau, Bahamas. Direct Line 242.396.5242, Mobile 242.422.4690, Fax 242.393.0237.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('aarango@indotel.gob.do')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Amparo Arango Echeverri', 'aarango@indotel.gob.do', '829.732.5555', 'Directora de Relaciones Internacionales', v_agency_indotel, 'Abraham Lincoln No. 962, Santo Domingo, R.D. Ext 6358, Fax (809) 696-7008.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('MillsJR@state.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('John R. Mills', 'MillsJR@state.gov', '(202) 772-3443', 'Deputy Assistant Secretary, Bureau of Cyberspace and Digital Policy', v_agency_us_dept_state, '2201 C St NW, Washington, D.C. 20520, USA. Cell (202) 702-6503.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('DragerMPI@state.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Michael Drager', 'DragerMPI@state.gov', '(202) 736-7143', 'Acting Deputy Assistant Secretary, Bureau of International Organization Affairs', v_agency_us_dept_state, '2201 C St. NW, Room 6323, Washington, DC 20520, USA. Cell (202) 250-6050.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('bmaday@ustda.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Brenda Quiroz Maday', 'bmaday@ustda.gov', '703-875-4357', 'Manager for Global Programs', v_agency_ustda, '1101 Wilson Blvd, Suite 1100, Arlington, VA 22209-2275, USA. Mobile 571-438-3096.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('bertzca@state.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Christine A. Bertz, Ph.D.', 'bertzca@state.gov', '+1 (202) 705-1393', 'Foreign Affairs Officer, Office of Specialized and Technical Affairs — Bureau of International Organization Affairs', v_agency_us_dept_state, '2401 E Street NW, L-409, Washington, DC 20037, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('pedro.direne@ookla.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Pedro Direne', 'pedro.direne@ookla.com', '+1 407 242-2054', 'Sales Director', v_company_ookla, '1524 5th Ave, Ste 300, Seattle, WA 98101, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jonathan.siqueira@ookla.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Jonathan Siqueira', 'jonathan.siqueira@ookla.com', '+1 (571) 992-6679', 'Senior Technical Account Manager', v_company_ookla, '1524 5th Ave, Ste 300, Seattle, WA 98101, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('carlos@ookla.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Carlos Islas', 'carlos@ookla.com', '+1 901 428-5943', 'Director of Client Services, Americas', v_company_ookla, '1524 5th Ave, Ste 300, Seattle, WA 98101, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('hamdy.farid@ookla.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Hamdy Farid', 'hamdy.farid@ookla.com', '+1 613 296 6534', 'Senior Vice President, Ookla Products', v_company_ookla, '1524 5th Ave, Ste 300, Seattle, WA 98101, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('sdimateo@cnv.gov.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Silvina Dimateo', 'sdimateo@cnv.gov.ar', '4329-4654', 'Gerente, Fideicomisos Financieros', v_agency_cnv, '25 de Mayo 175, C1002ABC, CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('alberto.patron@condortech.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Alberto Patron', 'alberto.patron@condortech.com.ar', '+549 (11) 5125.6115', 'CEO', v_company_condor_technologies, 'Rivadavia 497, San Isidro, Buenos Aires, Argentina. También +54 (11) 4747.9084 ext 252.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('sfsalvatierra@cnv.gov.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Sonia F. Salvatierra', 'sfsalvatierra@cnv.gov.ar', '(5411) 4329-4737', 'Director', v_agency_cnv, '25 de Mayo 175, C1002ABC, Buenos Aires, Argentina. También 4329-4610/4706.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('esteban.lescano-etcheverry@cabase.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Esteban Lescano', 'esteban.lescano-etcheverry@cabase.org.ar', '(5411) 5263 7456', 'Director Comisión de Legales y Políticas Públicas', v_company_cabase, 'Suipacha 128 3°F, C1008AAD, CABA, Argentina. Móvil +54 911 5104 8100.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('resilva@cnv.gov.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Roberto E. Silva', 'resilva@cnv.gov.ar', '(5411) 4329-4737', 'Chairman', v_agency_cnv, '25 de Mayo 175, C1002ABC, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('zhangmingqiang@huawei.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Mitchell Zhang Mingqiang', 'zhangmingqiang@huawei.com', '+54-911-4105 0500', 'CEO — Huawei Argentina, Uruguay y Paraguay', v_company_huawei, 'Leandro N. Alem 815, piso 10, CABA, C1001AAD, Argentina. También +54-911-3003 8555.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('facundo.delvillar@aerolineas.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Facundo D. del Villar', 'facundo.delvillar@aerolineas.com.ar', '+54 11 3723.9070', 'Director de Comunicación y Asuntos Institucionales', v_agency_aerolineas_argentinas, 'Aeroparque J. Newbery, Edif. Corporativo T4 piso 5, C1425DAA, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('josejuan.haro@telefonica.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('José Juan Haro Seijas', 'josejuan.haro@telefonica.com', '+34 682 82 35 11', 'Director Negocio Mayorista y Asuntos Públicos, Telefónica Hispanoamérica', v_company_telefonica, 'Distrito Telefónica - Norte 3, Ronda de la Comunicación s/n, Madrid, España.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('rodrigo_silveira@apple.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Rodrigo Monti Silveira', 'rodrigo_silveira@apple.com', '408 597 7976', 'Regulatory Compliance Manager', v_company_apple, '12545 Riata Vista Circle, Austin, TX 78727, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('lgamaleri@redintercable.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Lucio Gamaleri', 'lgamaleri@redintercable.com.ar', '+5411 5032-4999', 'Presidente', v_company_red_intercable, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('luisr@ilcsite.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Luis Ruete Güemes', 'luisr@ilcsite.com', '+54911 5452-9248', 'COO', v_company_ilc, 'Latam Office +5411 4747-9543, Miami Office +1 786-900-0120/21.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('meinrad.spenger@masorange.es')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Meinrad Spenger', 'meinrad.spenger@masorange.es', '+34 696 226 387', 'CEO', v_company_masorange, 'CIF B-13857196. También +34 628 226 822 (Sonia Arribas, sonia.arribas@masorange.es).', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('kup@mrecic.gov.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Agustín N. Kuperman', 'kup@mrecic.gov.ar', '635 763 046', 'Secretario de Embajada', v_agency_embajada_argentina_madrid, 'Fernando el Santo, 15, Pl. 1ª, 28010 Madrid, España.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('nachor@cabase.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Nacho Ribeiro', 'nachor@cabase.org.ar', '+54 9 11-6114-8282', 'Vicepresidente, Tel XP', v_company_cabase, 'Suipacha 128 3°F, C1008AAD, CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('franciscodopico@cadmipya.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Francisco do Pico', 'franciscodopico@cadmipya.org.ar', '+54 11 5474-2081', 'Gerente', v_company_cadmipya, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('alejandro.quirogalopez@claro.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Alejandro Quiroga Lopez', 'alejandro.quirogalopez@claro.com.ar', '+54 11 4109 8888', 'Director de Asuntos Regulatorios e Institucionales — Argentina, Uruguay y Paraguay', v_company_claro, 'Av. de Mayo 878, C1084AAQ, CABA, Argentina. Interno 34890, Móvil +54 9 11 2703 0000.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('e.nomura@soumu.go.jp')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Nomura Eigo', 'e.nomura@soumu.go.jp', '+81-3-5253-5916', 'Director General for International Affairs, Global Strategy Bureau', v_agency_mic_japan, '1-2 Kasumigaseki 2-Chome, Chiyoda-ku, Tokyo, Japón.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('keischeid@ustda.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Keith M. Eischeid', 'keischeid@ustda.gov', '703-875-4357', 'Regional Director, Latin America and The Caribbean', v_agency_ustda, '1101 Wilson Blvd, Suite 1100, Arlington, VA 22209-2275, USA. Fax 703-775-4037.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('acassady@ntia.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Adam Cassady', 'acassady@ntia.gov', '(771) 241-7672', 'Principal Deputy Assistant Secretary of Communications and Information', v_agency_ntia, '1401 Constitution Ave NW, Washington, DC 20230, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('hazem.moakkit@intelsat.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Hazem Moakkit', 'hazem.moakkit@intelsat.com', '+1 703-559-7311', 'Vice President, Spectrum Strategy', v_company_intelsat, '7900 Tysons One Place, McLean, VA 22102-5972, USA. Mobile +1 202-355-5404.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('burhanettin.takanay@argela.com.tr')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Burhanettin Takanay', 'burhanettin.takanay@argela.com.tr', '+90 555 480 25 32', 'Director, Product & Sales', v_company_argela, 'ITU ARI Teknokent, İstanbul, Turquía.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('alexia.gonzalezfanfalone@oecd.org')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Alexia González Fanfalone, PhD', 'alexia.gonzalezfanfalone@oecd.org', '33 (0)1 85 55 60 24', 'Head of the Connectivity Services and Infrastructures Unit, Digital Connectivity, Economics and Society Division', v_agency_oecd, '2, rue André-Pascal, 75775 Paris CEDEX 16, Francia.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jennifer.warren@lmco.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Jennifer Warren', 'jennifer.warren@lmco.com', '703-413-5970', 'Vice President, Global Regulatory Affairs & Public Policy, Government Affairs', v_company_lockheed_martin, '2121 Crystal Drive, Suite 100, Arlington, VA 22202, USA. Mobile 571-435-7991, Fax 703-413-5908.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('paucordo@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Paula Cordoba', 'paucordo@amazon.com', '+54 911 55113805', 'Sr. Advisor Licensing and International Regulatory Affairs, Project Kuiper', v_company_amazon, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('rmarazo@br.digital')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ronimar Marazo Soares', 'rmarazo@br.digital', '+55 11 4046 5333', 'Carrier Relations Director', v_company_br_digital, 'R. Flórida, 1738, 10° andar, Brooklin Novo, São Paulo, SP, 04565-000, Brasil. También +55 11 97256 7918.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('torsten.ericsson@gov.se')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Torsten Ericsson', 'torsten.ericsson@gov.se', '+54.11.4319 51 00', 'Ambassador', v_agency_gov_sweden, 'Embassy of Sweden, Buenos Aires. Olga Cossettini 731, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('juliocarlos.porras@claro.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Julio Carlos Porras Zadik', 'juliocarlos.porras@claro.com.ar', '+54 11 4109 8485', 'Director General, CEO', v_company_claro, 'Av. de Mayo 878, C1084AAQ, CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('lenny.valdez-lee@nokia.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Lenny Valdez-Lee', 'lenny.valdez-lee@nokia.com', '+61 477 732 997', 'Head of Sales – Wholesalers AU (Nokia Australia)', v_company_nokia, 'Level 10, 111 Pacific Highway, North Sydney NSW 2060, Australia.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('asloun@haca.ma')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Benaïssa Asloun', 'asloun@haca.ma', '+212 5 37 57 96 00', 'Directeur Général', v_agency_haca_morocco, 'Angle Avenue Annakhil et Mehdi Ben Barka, B.P 20590, Hay Riad, Rabat, Marruecos.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('osvaldo.dicampli@nokia.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Osvaldo H. Di Campli', 'osvaldo.dicampli@nokia.com', '+1 954 540 2992', 'Senior Vice President, Americas, Network Infrastructure Sales', v_company_nokia, '3201 Olympus Blvd, Dallas, TX 75019, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mvalenzu@nic.cl')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Marcelo Valenzuela', 'mvalenzu@nic.cl', '+56998198706', 'Director Proyecto Yafün', v_agency_nic_chile, 'Miraflores 222, piso 14, Santiago, Chile.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('elizabeth.bravo@nokia.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Elizabeth Bravo', 'elizabeth.bravo@nokia.com', '+1 954 5625086', 'FN Business Development, Network Infrastructure', v_company_nokia, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('pablo.recall@telespazio.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Pablo Recall', 'pablo.recall@telespazio.com', '+54 11 4852 8704', 'LATAM Business Development', v_company_telespazio, 'Av. Del Libertador n° 5926/30, Piso 7° Torre Sur, C1428ARP, CABA, Argentina. Fax +54 11 4852-8725.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('stephen.nelson@spacex.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Stephen Nelson', 'stephen.nelson@spacex.com', '+1-801-989-4582', 'Satellite Policy Director', v_company_spacex, '1155 F St NW Suite 475, Washington, DC 20004, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('SwinnenJ@state.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Jérémie Swinnen', 'SwinnenJ@state.gov', '(54-11) 5777-4893', 'INL Transnational Crime Specialist', v_agency_us_embassy_ar, 'Av. Cerviño 4320, C1425GMN, Buenos Aires, Argentina. Cell (54-11) 3343-7777.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('baojianlin@huawei.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Tonny Bao', 'baojianlin@huawei.com', '+86 13823634156', 'Vice President of Huawei, Director of Global Government Affairs Dept', v_company_huawei, 'Huawei Longgang Base, Shenzhen, China.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('adrianasarkis@gmail.com')) then
    insert into public.contacts (full_name, email, phone, position_title, notes, created_by)
    values ('Adriana Sarkis', 'adrianasarkis@gmail.com', '+55 61 99178.7997', null, 'Tarjeta sin empresa/organismo impreso.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mberrade@lu17.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Martin Berrade', 'mberrade@lu17.com', '+54 9 280 436 7580', 'Coordinador General', v_company_lu17, 'Estivariz 226, 9120, Puerto Madryn, Chubut, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('orolando@enre.gov.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Ing. Osvaldo E. Rolando', 'orolando@enre.gov.ar', '5278-4603', 'Interventor', v_agency_enre, 'Av. E. Madero 1020, 10° p., C1106ACX, CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('cpcast@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Chris Castello', 'cpcast@amazon.com', '+5491131932746', 'Solutions Architect Senior Manager, Public Sector — Latin America, Canada & Caribbean', v_company_amazon, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('privada.consumidor@comercio.gob.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Dr. Fernando Blanco Muiño', 'privada.consumidor@comercio.gob.ar', '(+5411) 4349-3118/3174', 'Subsecretario de Defensa del Consumidor y Lealtad Comercial', v_agency_sec_industria_comercio, 'Av. Julio A. Roca 651, Piso 2° Of 258, C1067ABB, Buenos Aires, Argentina. Cel (+54911) 3598-5223.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('arifonperez@worldbank.org')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Axel Rifon Pérez', 'arifonperez@worldbank.org', '+1 (202) 848 8675', 'Especialista Sénior en Desarrollo Digital, Vicepresidencia de Infraestructura', v_company_world_bank, 'Av. Alvarez Calderón 185, Piso 7, San Isidro, Lima 27, Perú.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('ameller@ai-darobot.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Aidan Meller', 'ameller@ai-darobot.com', '+44 7966 967042', null, v_company_ai_da_robot, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('werner@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Dr. Werner Vogels', 'werner@amazon.com', '(206) 266 1000', 'Chief Technology Officer', v_company_amazon, '1918 8th Avenue, Seattle, WA 98101-1244, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('luvsanochir@crc.gov.mn')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Luvsan-Ochir Altai', 'luvsanochir@crc.gov.mn', '(976 11) 304258', 'Commissioner, Head of Executive Office', v_agency_crc_mongolia, 'Metro Business Center 12th Floor, Baga toiruu 6th khoroo, Sukhbaatar district, Ulaanbaatar 14201-0033, Mongolia. Mobile (976) 88110075, Fax (976 11) 327720.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('adriano.yamaoka@telit.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Adriano Yamaoka', 'adriano.yamaoka@telit.com', '+55 11 3031 5051', 'Head of Sales Latam', v_company_telit_cinterion, 'Mobile +55 11 96636 1797.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('neset.yalcinkaya@telit.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Neset Yalcinkaya', 'neset.yalcinkaya@telit.com', '+1 619 952 5415', 'SVP Sales America, Sales', v_company_telit_cinterion, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('levin.born@globalstar.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Levin M Born', 'levin.born@globalstar.com', '+1 646 584 3703', 'Senior Director, Global Licensing and Regulatory Affairs', v_company_globalstar, '1351 Holiday Square Blvd, Covington, LA 70433, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('fcecchini@catip.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Franco Cecchini', 'fcecchini@catip.org.ar', null, 'Presidente', v_company_catip, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('joseabondarenco@gmail.com')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('José Alejandro Bondarenco', 'joseabondarenco@gmail.com', '11-5473-8897', 'Comisario, Jefe División SEG. Y CUST. — Jefatura de Gabinete de Ministros / Ministerio del Interior', v_agency_policia_federal, 'Julio A. Roca 782, Piso 11°, CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('roberto.suarez@grupocronica.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Roberto Suárez', 'roberto.suarez@grupocronica.com.ar', '+549-2615419600', 'Director Académico', v_company_instituto_superior_cronica, 'Azopardo 1405, piso 2, CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(full_name) = lower('Zhongde Shan') and email is null) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Zhongde Shan', null, '86-10-68205970', 'Vice-Minister, Member Party Leadership Group', v_agency_miit_china, '13 West Chang An Ave., Beijing 100804, China. www.miit.gov.cn. Sin email impreso.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('marc.vancoppenolle@nokia.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Marc Vancoppenolle', 'marc.vancoppenolle@nokia.com', '+32479790278', 'Vice President, Geopolitical and Government Relations, EU & Europe', v_company_nokia, 'Rond-Point Schuman 6, 1040 Brussels, Bélgica.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('oliveirs@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ronaldo Oliveira', 'oliveirs@amazon.com', '+55 11 992933223', 'Partner Development Manager, Public Sector', v_company_amazon, '13200 Woodland Park Rd, Herndon, VA 20171, USA. También t +55 11 4130-2050.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('dediosg@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Gonzalo de Dios', 'dediosg@amazon.com', '571 400 5185', 'Head of Global Licensing, Project Kuiper', v_company_amazon, 'Amazon HQ2, 525 14th Street S, Arlington, VA 22202, USA. También m 202 438 3752.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('chrhem@amazon.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Chris Hemmerlein', 'chrhem@amazon.com', '+1 718 598 3804', 'Senior Manager, Public Policy', v_company_amazon, '1800 South Bell Street, Arlington, VA 22202, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('shrinivas.hublikar@stl.tech')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Shrinivas R Hublikar', 'shrinivas.hublikar@stl.tech', '+91 90089 98160', 'Head PLM DC', v_company_stl, 'Sterlite Technologies Limited, Survey No. 33/1/1, Waghdhara Road, Dadra - 396193, Union Territory of Dadra & Nagar Haveli, India. También +91-260-6613873.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jaume@sateliot.space')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Jaume Sanpera', 'jaume@sateliot.space', '+34 647 708 253', 'Chief Executive Officer', v_company_sateliot, 'Barcelona · San Diego · Space. También +1 (650) 405-7007.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('gianluca.redolfi@sateliot.space')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Gianluca Redolfi', 'gianluca.redolfi@sateliot.space', '+34 678 460 897', 'Chief Commercial Officer', v_company_sateliot, 'Barcelona · San Diego · Space.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('eduardo.tallarico@gmail.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Dr. Eduardo Daniel Tallarico', 'eduardo.tallarico@gmail.com', null, 'Representante Legal', v_company_hispasat, 'Gelly y Obes 2238 7°, 1425, Ciudad Autónoma de Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('kfields@rivada.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ken Fields', 'kfields@rivada.com', '+1 914 310 4464', 'Director of Market Development, Member of the Board of Directors', v_company_rivada_space_networks, '1050 30th St NW, Washington, DC 20007, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('foflaherty@rivada.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Francis O''Flaherty', 'foflaherty@rivada.com', '+353 93 43900', 'Chief Operating Officer', v_company_rivada_space_networks, 'Moyne Park, Tuam, Co. Galway, Irlanda / 245 Park Avenue, New York, NY 10167, USA. Mob +353 86 856 5589, USA Tel 212 792 4000, Cell (202) 425-6674.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('margonzalez@metrotel.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Marcelo Daniel González', 'margonzalez@metrotel.com.ar', '(54.11) 6091.5860', 'Director de Relaciones Institucionales', v_company_metrotel, 'Chacabuco 271 2° Piso (C1069AAO), CABA, Argentina. Fax (54.11) 6091.1020 int 5860.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('TVOLMER@NETFLIX.COM')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Thomas Volmer', 'TVOLMER@NETFLIX.COM', '+33681782248', 'Director, Global Content Delivery Policy', v_company_netflix, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('agostinho.linhares@ipedigital.tech')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Agostinho Linhares, Dr.', 'agostinho.linhares@ipedigital.tech', '+55 61 9 9901-7071', 'Executive Director', v_company_ipe_digital, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('sbardengo@metrotel.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Sebastian Bardengo', 'sbardengo@metrotel.com.ar', null, 'CEO - Presidente', v_company_metrotel, 'Chacabuco 271 Piso 2° (C1069), CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('cechhab@gmail.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ing. Carlos Eduardo Chhab', 'cechhab@gmail.com', '+54 9 11 6019 2403', 'Consultor IAA', v_company_iaa, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('eschmidberg@gmail.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ing. Eduardo Schmidberg', 'eschmidberg@gmail.com', '+54 9 11 4144 0477', 'Consultor IAA', v_company_iaa, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mpesado@gmail.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Ing. Miguel Ángel Pesado', 'mpesado@gmail.com', '+54 9 11 61586004', 'Consultor IAA', v_company_iaa, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('daia@daia.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Victor Garelik', 'daia@daia.org.ar', null, 'Director Ejecutivo', v_company_daia, 'Email general de DAIA (no personal).', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('zhukeer@miit.gov.cn')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Zhu Keer', 'zhukeer@miit.gov.cn', '86-10-68205827', 'Deputy Director General, Department of International Cooperation', v_agency_miit_china, '13 West Chang An Ave., Beijing 100804, China. Fax 86-10-66011370.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('xuheyuan@caict.ac.cn')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Heyuan Xu', 'xuheyuan@caict.ac.cn', '86-10-62300007', 'Deputy Chief Engineer, Professorate Senior Engineer', v_agency_caict_china, 'No.52 Hua Yuan Bei Road, Beijing 100191, China. Mobile 13601275315.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('presidencia@daia.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Lic. Mauro Berenstein', 'presidencia@daia.org.ar', '+54 11 4378-3203/4', 'Presidente', v_company_daia, 'Pasteur 633 Piso 7° (1028), CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('hnajenson@daia.org.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Dr. Hernán Najenson', 'hnajenson@daia.org.ar', '+54 911 5010-5482', 'Secretario de Asuntos Jurídicos', v_company_daia, 'Pasteur 633 Piso 7° (1028), CABA, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('gcastell@ciena.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Gustavo A. Castello', 'gcastell@ciena.com', '+54.11.5077.1615', 'Director, Strategic International Accounts', v_company_ciena, 'Av. del Libertador 7208 Piso 7 Norte, C1429BMS, Buenos Aires, Argentina. Mobile +54.9.11.5526.0707.', v_creator_id);
  end if;

end $$;

-- ============================================================================
-- Verificacion — contactos de ESTE lote (5.pdf a 23.pdf)
-- ============================================================================
select
  c.full_name,
  c.position_title,
  c.email,
  c.phone,
  coalesce(co.name, pa.name, '(sin empresa/organismo)') as organization,
  case when co.id is not null then 'Empresa' when pa.id is not null then 'Organismo Público' else '—' end as org_type
from public.contacts c
left join public.companies co on co.id = c.company_id
left join public.public_agencies pa on pa.id = c.public_agency_id
where lower(coalesce(c.email, '')) in (
lower('meredith.potter@dfc.gov'), lower('jmcandioti@sales.org.ar'), lower('shannonk@amazon.com'), lower('nicolas.degracia@telespazio.com'), lower('avalero@telefonica.com'), lower('mbeyries@amazon.com'), lower('hernanc@google.com'), lower('vanmessem@google.com'), lower('sherrera@sigen.gob.ar'), lower('mbailo@sigen.gob.ar'), lower('luis@approve-itsa.com'), lower('FernandezJW@state.gov'), lower('ibergall@enersa.com.ar'), lower('bari@approve-itsa.com'), lower('dstehlin@tiaonline.org'), lower('ezequiel.dominguez@cullen-international.com'), lower('facundo.fernandez.begni@ericsson.com'), lower('Gabriela.Lago@echostar.com'), lower('claudio.saes@bell-labs.com'), lower('carlos.gramajo@nokia.com'), lower('sostenes.diaz@ift.org.mx'), lower('rarellano@teco.com.ar'), lower('IglesiasS@state.gov'), lower('mguarino@bna.com.ar'), lower('Marina.Millet@trade.gov'), lower('Eric.Olson@trade.gov'), lower('mcrudo@bna.com.ar'), lower('NelsonTH@state.gov'), lower('leaplaza@amazon.com'), lower('mail@airiab.org'), lower('maryleana@tel.lat'), lower('mpikielny@fiscalias.gob.ar'), lower('aeimer@trans.com.ar'), lower('gunrein@fiscalias.gob.ar'), lower('ffox@fiscalias.gob.ar'), lower('cipolitti@paramount.com'), lower('manzorre@directvla.com.ar'), lower('gggonzalez@hcdn.gob.ar'), lower('vilma.bedia@senado.gob.ar'), lower('carmen.alvarez@senado.gob.ar'), lower('pedro.bentancourt@vriocorp.com'), lower('LangSA@state.gov'), lower('CARLSONDA@STATE.GOV'), lower('aguelman@cytricsolutions.com'), lower('larry.s.henschel.civ@mail.mil'), lower('guillermo.wichmann@nokia.com'), lower('capellan@cicomra.org.ar'), lower('presidencia@cabase.org.ar'), lower('perelmanr@telecom-sat.com'), lower('svatnick@global-outcomes.com'), lower('mariodelacruz@apple.com'), lower('mba@pagbam.com'), lower('tpa@pagbam.com'), lower('ptognetti@gmail.com'), lower('juandavid.velez@spacex.com'), lower('pabbate@invap.com.ar'), lower('genovese@invap.com.ar'), lower('ctisot@invap.com.ar'), lower('andres.jato@gov.se'), lower('Ryan.Goodnight@spacex.com'), lower('carlos.riopedre@sateliot.com'), lower('mario.maniewicz@itu.int'), lower('matthew.hare@zzoomm.com'), lower('mgavin@omnispace.com'), lower('ofigueroa@sigen.gob.ar'), lower('cbaldini@correoargentino.com.ar'), lower('Enrique.Algorta@stonex.com'), lower('dmerino@sion.com'), lower('wangzhengan@huawei.com'), lower('Nadia.Fraga@stonex.com'), lower('leonwms@bahamas.gov.bs'), lower('JMcCartney@urcabahamas.bs'), lower('aarango@indotel.gob.do'), lower('MillsJR@state.gov'), lower('DragerMPI@state.gov'), lower('bmaday@ustda.gov'), lower('bertzca@state.gov'), lower('pedro.direne@ookla.com'), lower('jonathan.siqueira@ookla.com'), lower('carlos@ookla.com'), lower('hamdy.farid@ookla.com'), lower('sdimateo@cnv.gov.ar'), lower('alberto.patron@condortech.com.ar'), lower('sfsalvatierra@cnv.gov.ar'), lower('esteban.lescano-etcheverry@cabase.org.ar'), lower('resilva@cnv.gov.ar'), lower('zhangmingqiang@huawei.com'), lower('facundo.delvillar@aerolineas.com.ar'), lower('josejuan.haro@telefonica.com'), lower('rodrigo_silveira@apple.com'), lower('lgamaleri@redintercable.com.ar'), lower('luisr@ilcsite.com'), lower('meinrad.spenger@masorange.es'), lower('kup@mrecic.gov.ar'), lower('nachor@cabase.org.ar'), lower('franciscodopico@cadmipya.org.ar'), lower('alejandro.quirogalopez@claro.com.ar'), lower('e.nomura@soumu.go.jp'), lower('keischeid@ustda.gov'), lower('acassady@ntia.gov'), lower('hazem.moakkit@intelsat.com'), lower('burhanettin.takanay@argela.com.tr'), lower('alexia.gonzalezfanfalone@oecd.org'), lower('jennifer.warren@lmco.com'), lower('paucordo@amazon.com'), lower('rmarazo@br.digital'), lower('torsten.ericsson@gov.se'), lower('juliocarlos.porras@claro.com.ar'), lower('lenny.valdez-lee@nokia.com'), lower('asloun@haca.ma'), lower('osvaldo.dicampli@nokia.com'), lower('mvalenzu@nic.cl'), lower('elizabeth.bravo@nokia.com'), lower('pablo.recall@telespazio.com'), lower('stephen.nelson@spacex.com'), lower('SwinnenJ@state.gov'), lower('baojianlin@huawei.com'), lower('adrianasarkis@gmail.com'), lower('mberrade@lu17.com'), lower('orolando@enre.gov.ar'), lower('cpcast@amazon.com'), lower('privada.consumidor@comercio.gob.ar'), lower('arifonperez@worldbank.org'), lower('ameller@ai-darobot.com'), lower('werner@amazon.com'), lower('luvsanochir@crc.gov.mn'), lower('adriano.yamaoka@telit.com'), lower('neset.yalcinkaya@telit.com'), lower('levin.born@globalstar.com'), lower('fcecchini@catip.org.ar'), lower('joseabondarenco@gmail.com'), lower('roberto.suarez@grupocronica.com.ar'), lower('marc.vancoppenolle@nokia.com'), lower('oliveirs@amazon.com'), lower('dediosg@amazon.com'), lower('chrhem@amazon.com'), lower('shrinivas.hublikar@stl.tech'), lower('jaume@sateliot.space'), lower('gianluca.redolfi@sateliot.space'), lower('eduardo.tallarico@gmail.com'), lower('kfields@rivada.com'), lower('foflaherty@rivada.com'), lower('margonzalez@metrotel.com.ar'), lower('TVOLMER@NETFLIX.COM'), lower('agostinho.linhares@ipedigital.tech'), lower('sbardengo@metrotel.com.ar'), lower('cechhab@gmail.com'), lower('eschmidberg@gmail.com'), lower('mpesado@gmail.com'), lower('daia@daia.org.ar'), lower('zhukeer@miit.gov.cn'), lower('xuheyuan@caict.ac.cn'), lower('presidencia@daia.org.ar'), lower('hnajenson@daia.org.ar'), lower('gcastell@ciena.com')
)
or c.full_name in (
'Mg. Sergio O. Nardini', 'Zhongde Shan'
)
order by organization, c.full_name;
