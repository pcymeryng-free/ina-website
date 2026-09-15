-- ============================================================================
-- Alta masiva de Contactos y Empresas/Organismos — tarjetas de presentación
--
-- QUE ES
-- Carga los 31 contactos de las 4 tarjetas fotografiadas por Pablo
-- (tarjetas.pdf, tarjetas 2.pdf, tarjetas 3.pdf, tarjetas 4.pdf), junto con
-- las 18 Empresas y 4 Organismos Públicos a los que pertenecen, en Master
-- Data (companies / public_agencies / contacts).
--
-- COMO USAR
-- 1. Abri tu proyecto Supabase -> SQL Editor -> New query.
-- 2. Si todavia no corriste supabase/migration_v44_master_data.sql, corrélo
--    primero (crea las tablas companies/public_agencies/contacts que este
--    archivo usa).
-- 3. En la linea marcada "EDITAR" reemplaza el email por el de tu cuenta de
--    la plataforma INA (tiene que ser advisor o admin, ya registrada en
--    public.profiles) -- queda como created_by de todo lo que se crea acá.
-- 4. Ejecuta el resto del script. Es seguro correrlo mas de una vez: las
--    Empresas/Organismos se reutilizan por nombre si ya existen, y los
--    Contactos se identifican por email, asi que tampoco se duplican.
-- 5. Al final corre un SELECT que muestra los 31 contactos creados, para
--    confirmar.
-- ============================================================================

do $$
declare
  v_creator_id uuid;
  v_company_access_partnership uuid;
  v_company_conosur_inversiones uuid;
  v_company_akamai uuid;
  v_company_tmg_telecom uuid;
  v_company_gsma uuid;
  v_company_america_movil uuid;
  v_company_eand uuid;
  v_company_liberty_latin_america uuid;
  v_company_qualcomm uuid;
  v_company_atn_international uuid;
  v_company_gogo_business_aviation uuid;
  v_company_ericsson uuid;
  v_company_dpl_news uuid;
  v_company_ispectrum uuid;
  v_company_hughes uuid;
  v_company_nokia uuid;
  v_company_bluenote uuid;
  v_company_omnispace uuid;
  v_agency_att_bolivia uuid;
  v_agency_fcc uuid;
  v_agency_nsc_white_house uuid;
  v_agency_us_doc uuid;
begin
  -- EDITAR: reemplaza por el email de tu cuenta INA (advisor o admin).
  select id into v_creator_id from public.profiles where email = 'pcymeryng@gmail.com';
  if v_creator_id is null then
    raise exception 'No se encontro un perfil con ese email. Editá la linea del email antes de correr este script.';
  end if;

  -- ==========================================================================
  -- Empresas (reutiliza por nombre si ya existen)
  -- ==========================================================================

  select id into v_company_access_partnership from public.companies where lower(name) = lower('Access Partnership');
  if v_company_access_partnership is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Access Partnership', array['service_provider'], 'Reino Unido', 'https://accesspartnership.com', v_creator_id)
    returning id into v_company_access_partnership;
  end if;

  select id into v_company_conosur_inversiones from public.companies where lower(name) = lower('Conosur Inversiones');
  if v_company_conosur_inversiones is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Conosur Inversiones', array['financial_entity'], 'Argentina', null, v_creator_id)
    returning id into v_company_conosur_inversiones;
  end if;

  select id into v_company_akamai from public.companies where lower(name) = lower('Akamai');
  if v_company_akamai is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Akamai', array['service_provider'], 'Estados Unidos', 'https://www.akamai.com', v_creator_id)
    returning id into v_company_akamai;
  end if;

  select id into v_company_tmg_telecom from public.companies where lower(name) = lower('TMG');
  if v_company_tmg_telecom is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('TMG', array['service_provider'], 'Francia', 'https://www.tmgtelecom.com', v_creator_id)
    returning id into v_company_tmg_telecom;
  end if;

  select id into v_company_gsma from public.companies where lower(name) = lower('GSMA');
  if v_company_gsma is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('GSMA', '{}', 'Reino Unido', 'https://www.gsma.com', v_creator_id)
    returning id into v_company_gsma;
  end if;

  select id into v_company_america_movil from public.companies where lower(name) = lower('América Móvil');
  if v_company_america_movil is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('América Móvil', array['service_provider'], 'México', 'https://www.americamovil.com', v_creator_id)
    returning id into v_company_america_movil;
  end if;

  select id into v_company_eand from public.companies where lower(name) = lower('e&');
  if v_company_eand is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('e&', array['service_provider'], 'Emiratos Árabes Unidos', 'https://www.eand.com', v_creator_id)
    returning id into v_company_eand;
  end if;

  select id into v_company_liberty_latin_america from public.companies where lower(name) = lower('Liberty Latin America');
  if v_company_liberty_latin_america is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Liberty Latin America', array['service_provider'], 'Estados Unidos', 'https://www.lla.com', v_creator_id)
    returning id into v_company_liberty_latin_america;
  end if;

  select id into v_company_qualcomm from public.companies where lower(name) = lower('Qualcomm');
  if v_company_qualcomm is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Qualcomm', array['manufacturer'], 'Estados Unidos', 'https://www.qualcomm.com', v_creator_id)
    returning id into v_company_qualcomm;
  end if;

  select id into v_company_atn_international from public.companies where lower(name) = lower('ATN International');
  if v_company_atn_international is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('ATN International', array['service_provider'], 'Estados Unidos', 'https://www.atni.com', v_creator_id)
    returning id into v_company_atn_international;
  end if;

  select id into v_company_gogo_business_aviation from public.companies where lower(name) = lower('Gogo Business Aviation');
  if v_company_gogo_business_aviation is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Gogo Business Aviation', array['service_provider'], 'Estados Unidos', 'https://www.gogoair.com', v_creator_id)
    returning id into v_company_gogo_business_aviation;
  end if;

  select id into v_company_ericsson from public.companies where lower(name) = lower('Ericsson');
  if v_company_ericsson is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Ericsson', array['manufacturer'], 'Suecia', 'https://www.ericsson.com', v_creator_id)
    returning id into v_company_ericsson;
  end if;

  select id into v_company_dpl_news from public.companies where lower(name) = lower('DPL News (Digital Policy Law)');
  if v_company_dpl_news is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('DPL News (Digital Policy Law)', '{}', 'Argentina', 'https://www.dplnews.com', v_creator_id)
    returning id into v_company_dpl_news;
  end if;

  select id into v_company_ispectrum from public.companies where lower(name) = lower('iSpectrum');
  if v_company_ispectrum is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('iSpectrum', array['service_provider'], 'Argentina', 'https://www.ispectrum.com.ar', v_creator_id)
    returning id into v_company_ispectrum;
  end if;

  select id into v_company_hughes from public.companies where lower(name) = lower('Hughes Network Systems');
  if v_company_hughes is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Hughes Network Systems', array['manufacturer'], 'Estados Unidos', 'https://www.hughes.com', v_creator_id)
    returning id into v_company_hughes;
  end if;

  select id into v_company_nokia from public.companies where lower(name) = lower('Nokia');
  if v_company_nokia is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('Nokia', array['manufacturer'], 'Finlandia', 'https://www.nokia.com', v_creator_id)
    returning id into v_company_nokia;
  end if;

  select id into v_company_bluenote from public.companies where lower(name) = lower('BlueNote Management Consulting');
  if v_company_bluenote is null then
    insert into public.companies (name, types, country, website, created_by)
    values ('BlueNote Management Consulting', array['service_provider'], 'Argentina', 'https://www.bluenotemc.com', v_creator_id)
    returning id into v_company_bluenote;
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

  select id into v_agency_att_bolivia from public.public_agencies where lower(name) = lower('Autoridad de Regulación y Fiscalización de Telecomunicaciones y Transportes (ATT)');
  if v_agency_att_bolivia is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Autoridad de Regulación y Fiscalización de Telecomunicaciones y Transportes (ATT)', 'international', 'Bolivia', 'Regulador de telecomunicaciones y transportes de Bolivia.', v_creator_id)
    returning id into v_agency_att_bolivia;
  end if;

  select id into v_agency_fcc from public.public_agencies where lower(name) = lower('Federal Communications Commission (FCC)');
  if v_agency_fcc is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('Federal Communications Commission (FCC)', 'international', 'Estados Unidos', 'Regulador de comunicaciones de Estados Unidos.', v_creator_id)
    returning id into v_agency_fcc;
  end if;

  select id into v_agency_nsc_white_house from public.public_agencies where lower(name) = lower('National Security Council (The White House)');
  if v_agency_nsc_white_house is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('National Security Council (The White House)', 'international', 'Estados Unidos', 'Consejo de Seguridad Nacional, Casa Blanca.', v_creator_id)
    returning id into v_agency_nsc_white_house;
  end if;

  select id into v_agency_us_doc from public.public_agencies where lower(name) = lower('U.S. Department of Commerce');
  if v_agency_us_doc is null then
    insert into public.public_agencies (name, jurisdiction, country, notes, created_by)
    values ('U.S. Department of Commerce', 'international', 'Estados Unidos', 'Departamento de Comercio de Estados Unidos.', v_creator_id)
    returning id into v_agency_us_doc;
  end if;

  -- ==========================================================================
  -- Contactos (no duplica si ya existe uno con el mismo email)
  -- ==========================================================================

  if not exists (select 1 from public.contacts where lower(email) = lower('juan.cacace@accesspartnership.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Juan Ignacio Cacace', 'juan.cacace@accesspartnership.com', '+44 (0)745 283 6801', 'Director, Government Affairs, Global Market Access', v_company_access_partnership, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('joaquin.pozzo@conosurinversiones.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Joaquín A. Pozzo', 'joaquin.pozzo@conosurinversiones.com.ar', '+54 9 11 4184 8833', 'Director', v_company_conosur_inversiones, 'Edificio Blue Sky - Av. del Libertador 1068, piso 4° (CABA).', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('cborggre@akamai.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Christian Borggreen', 'cborggre@akamai.com', '+32 (0)497 543636', 'Senior Director, Global Public Policy & Head of Public Policy, EMEA', v_company_akamai, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('geraldo@tmgtelecom.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Geraldo Neto', 'geraldo@tmgtelecom.com', '+1 (703) 224 1501', 'Vice President', v_company_tmg_telecom, '20 rue de la Villette, 69328 Lyon, Francia. Móvil +33 (0)6 43 17 39 88.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('lgallitto@gsma.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Lucas Gallitto', 'lgallitto@gsma.com', '+54 (911) 3497 2970', 'Head of Latin America', v_company_gsma, 'Av. del Libertador 6810, 15th Floor (Square Libertador Building), C1429BMO, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('nrios@att.gob.bo')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Néstor Ríos Rivero', 'nrios@att.gob.bo', '+591 71292920', 'Director Ejecutivo', v_agency_att_bolivia, 'La Paz: Calacoto, calle 13, N° 8260, entre Av. Los Sauces y Av. Costanera.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jgiusti@gsma.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('John Giusti', 'jgiusti@gsma.com', '+44 (0)7826 948 115', 'Chief Regulatory Officer', v_company_gsma, '1 Angel Lane, London, U.K. EC4R 3AB.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('hector.huerta@americamovil.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Héctor Hugo Huerta Reyna', 'hector.huerta@americamovil.com', '+52 55 2581 4463', 'Subdirector de Regulación Internacional', v_company_america_movil, 'Lago Zurich No.245, Piso 16, Edificio Telcel, Col. Ampliación Granada, Deleg. Miguel Hidalgo, C.P. 11529, México D.F. Fax (5255) 2581 4183.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('pmlikota@eand.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Mateo Pablo Mlikota', 'pmlikota@eand.com', '+971 50 143 4232', 'Sr. Vice President, International Roaming & Mobile Services', v_company_eand, 'Tel +971 4 371 7300.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Sebastian.Kaplan@lla.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Sebastian Kaplan', 'Sebastian.Kaplan@lla.com', '+54 911 5885 4933', 'Vice President, Government Affairs', v_company_liberty_latin_america, null, v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('hmarin@qti.qualcomm.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Hector Marin', 'hmarin@qti.qualcomm.com', '52 55 1948 1159', 'Senior Director, Government Affairs', v_company_qualcomm, 'Qualcomm International, Inc., Mexico Branch Office, Paseo de las Palmas 425, Desp. 603, Col. Lomas Chapultepec, CDMX 11000, México. Directo 52 55 3602 2012.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('dnewman@atni.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Delreo Newman, PhD', 'dnewman@atni.com', '978.810.5158', 'Director of International Regulatory of Government Affairs', v_company_atn_international, '500 Cummings Center, Beverly, MA 01915, USA. Oficina 978.617.1300.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jmacdougall@gogoair.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Jim MacDougall', 'jmacdougall@gogoair.com', '+1 602-549-3870', 'Vice President, Business Development', v_company_gogo_business_aviation, '105 Edgeview Drive, Suite 300, Broomfield, CO 80021, USA.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('rodrigo.dienstmann@ericsson.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Rodrigo Dienstmann', 'rodrigo.dienstmann@ericsson.com', '+55 11 98105-0403', 'President, Ericsson Latam South', v_company_ericsson, 'Avenida Chucri Zaidan, 920, 4° andar - sala 04-101, Market Place Tower, São Paulo, SP, Brasil. Oficina +55 11 2224-4541.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jacqueline.lopes@ericsson.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Jacqueline Lopes', 'jacqueline.lopes@ericsson.com', '+55 11 96488-7379', 'Head of Government & Policy Advocacy, LATAM South', v_company_ericsson, 'Avenida Chucri Zaidan, 920, 4° andar - sala 04-101, Market Place Tower, São Paulo, SP, Brasil.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('nicolas.larocca@digitalpolicylaw.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Nicolás Larocca', 'nicolas.larocca@digitalpolicylaw.com', '+54 9 11 65445918', 'Analista y corresponsal en Argentina', v_company_dpl_news, 'X: @nicolarocca_', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mpereira@qti.qualcomm.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Milene Franco Pereira', 'mpereira@qti.qualcomm.com', '+55 61 99693 2052', 'Senior Manager, Government Affairs', v_company_qualcomm, 'Qualcomm Serviços de Telecomunicações Ltda., SCN Quadra 1, Bl. D, 2nd Floor, Vega Building, Rooms 212 and 213, Brasília, DF 70711-040, Brasil. Tel +55 61 2106 7997.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('maldax@ispectrum.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Martin Aldax', 'maldax@ispectrum.com.ar', '+54 9 11 5508-3652', 'Co-Founder & CCO', v_company_ispectrum, 'WhatsApp.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('pbertolini@digitalpolicylaw.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Paula Bertolini', 'pbertolini@digitalpolicylaw.com', '+54 9 11 6627 0018', 'Directora de la Agencia Informativa DPL News', v_company_dpl_news, 'Twitter: @Pablabertol', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('hugo.frega@hughes.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Hugo Frega', 'hugo.frega@hughes.com', '301.655.1567', 'General Manager, CALA Group International Division', v_company_hughes, 'Hughes Network Systems (An EchoStar Company), 11717 Exploration Lane, Germantown, MD 20876, USA. Tel 301.601.7219, Fax 301.428.2818.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('nicolaskaravaski@ispectrum.com.ar')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Nicolás Karavaski', 'nicolaskaravaski@ispectrum.com.ar', '+54 9 11 5474-7325', 'Advisor', v_company_ispectrum, 'WhatsApp.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('fernando_ivan.sosa@nokia.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Fernando Sosa', 'fernando_ivan.sosa@nokia.com', '+54 9 1136855049', 'Head of MU South, Customer Experience', v_company_nokia, 'Av. Caseros 3039, Buenos Aires, Argentina.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('juan.crosta@bluenotemc.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Juan Ignacio Crosta', 'juan.crosta@bluenotemc.com', '+54 (911) 5180 3282', null, v_company_bluenote, 'Av. Federico Lacroze 2306, Piso 5°, 1426CPV, Buenos Aires, Argentina. Tel +54 (11) 4777-2473, Fax +54 (11) 4778-1746.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jared.carlson@fcc.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Jared M. Carlson', 'jared.carlson@fcc.gov', '+1 202 615 3750', 'Deputy Chief, Office of International Affairs', v_agency_fcc, '45 L Street, NE, Washington, DC 20554. Oficina +1 202 418 2368.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mdelatorre@omnispace.com')) then
    insert into public.contacts (full_name, email, phone, position_title, company_id, notes, created_by)
    values ('Mindel De La Torre', 'mdelatorre@omnispace.com', '+1 703 228 9697', 'Chief Regulatory and International Strategy Officer', v_company_omnispace, '8255 Greensboro Drive, Suite 101, McLean, VA 22102, USA. Oficina +1 202 930 5935.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Jessica.Rosenworcel@fcc.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Jessica Rosenworcel', 'Jessica.Rosenworcel@fcc.gov', '(202) 418-1000', 'Chairwoman', v_agency_fcc, '45 L Street, N.E., Washington, DC 20554.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Anna.Gomez@fcc.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Anna M. Gomez', 'Anna.Gomez@fcc.gov', '(202) 418-2100', 'Commissioner', v_agency_fcc, '45 L Street, NE, Washington, DC 20554.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('ethan.lucarelli@fcc.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Ethan Lucarelli', 'ethan.lucarelli@fcc.gov', '(217) 390-4490', 'Chief, Office of International Affairs', v_agency_fcc, '45 L Street, NE, Washington, DC 20554. Oficina (202) 418-0539.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('jonathan.campbell@fcc.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Jonathan M. Campbell', 'jonathan.campbell@fcc.gov', '(202) 418-0605', 'Legal Advisor, Wireless, International & Space — Office of Chairwoman Jessica Rosenworcel', v_agency_fcc, '45 L Street, NE, Washington, DC 20554.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('Anne.Neuberger@nsc.eop.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Anne Neuberger', 'Anne.Neuberger@nsc.eop.gov', '(202) 456-9187', 'Deputy Assistant to the President, Deputy National Security Advisor — Cyber & Emerging Technologies', v_agency_nsc_white_house, 'National Security Council, The White House. Email alternativo: ANeuberger@nsc.eop.ic.gov.', v_creator_id);
  end if;

  if not exists (select 1 from public.contacts where lower(email) = lower('mmcmillan@doc.gov')) then
    insert into public.contacts (full_name, email, phone, position_title, public_agency_id, notes, created_by)
    values ('Megan L. McMillan', 'mmcmillan@doc.gov', '1 (202) 642-0602', 'Senior Counsel, Commercial Law Development Program', v_agency_us_doc, 'Office of the General Counsel, U.S. Department of Commerce, Washington, D.C. 20230. Oficina 1 (202) 482-2400, Travel Mobile 1 (202) 510-7839. www.cldp.doc.gov.', v_creator_id);
  end if;

end $$;

-- ============================================================================
-- Verificacion
-- ============================================================================
select
  c.full_name,
  c.position_title,
  c.email,
  c.phone,
  coalesce(co.name, pa.name) as organization,
  case when co.id is not null then 'Empresa' else 'Organismo Público' end as org_type
from public.contacts c
left join public.companies co on co.id = c.company_id
left join public.public_agencies pa on pa.id = c.public_agency_id
where lower(c.email) in (
lower('juan.cacace@accesspartnership.com'), lower('joaquin.pozzo@conosurinversiones.com.ar'), lower('cborggre@akamai.com'), lower('geraldo@tmgtelecom.com'), lower('lgallitto@gsma.com'), lower('nrios@att.gob.bo'), lower('jgiusti@gsma.com'), lower('hector.huerta@americamovil.com'), lower('pmlikota@eand.com'), lower('Sebastian.Kaplan@lla.com'), lower('hmarin@qti.qualcomm.com'), lower('dnewman@atni.com'), lower('jmacdougall@gogoair.com'), lower('rodrigo.dienstmann@ericsson.com'), lower('jacqueline.lopes@ericsson.com'), lower('nicolas.larocca@digitalpolicylaw.com'), lower('mpereira@qti.qualcomm.com'), lower('maldax@ispectrum.com.ar'), lower('pbertolini@digitalpolicylaw.com'), lower('hugo.frega@hughes.com'), lower('nicolaskaravaski@ispectrum.com.ar'), lower('fernando_ivan.sosa@nokia.com'), lower('juan.crosta@bluenotemc.com'), lower('jared.carlson@fcc.gov'), lower('mdelatorre@omnispace.com'), lower('Jessica.Rosenworcel@fcc.gov'), lower('Anna.Gomez@fcc.gov'), lower('ethan.lucarelli@fcc.gov'), lower('jonathan.campbell@fcc.gov'), lower('Anne.Neuberger@nsc.eop.gov'), lower('mmcmillan@doc.gov')
)
order by organization, c.full_name;
