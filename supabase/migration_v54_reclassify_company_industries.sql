-- Migration v54: reclassify companies.industry based on real-world research
-- (web search on each company's actual line of business), per Pablo's request:
-- "revisar las empresas de la base de datos y cambiar, si fuera necesario, el
-- tipo de empresa en base a las opciones de la lista y a la informacion
-- disponible de la empresa en internet."
--
-- Context: migration_v52's backfill (`industry = types[1]`) mostly carried over
-- 'service_provider' -- a generic business-role tag from the old COMPANY_TYPES
-- checkbox list -- rather than a real sector classification. This migration
-- replaces that generic value with the closest matching value from
-- COMPANY_INDUSTRIES (assets/platform.js) based on each company's actual
-- business, confirmed via web search. 13 companies already had an accurate
-- value (mostly hardware manufacturers correctly tagged 'manufacturer', plus
-- 3 financial entities) and are left untouched -- not included below.
--
-- Each UPDATE is scoped to id AND the industry value on record at review time
-- (IS NOT DISTINCT FROM), so it's a no-op if Pablo already changed that company
-- manually since the CSV export this was based on -- it won't clobber a newer
-- manual edit.
-- Run manually in Supabase SQL Editor.

-- #LA17 / LU17 (Puerto Madryn)
-- Es LU17 Radio Golfo Nuevo (AM 540 / FM), primera radio privada de Chubut, con la marca #LA17 para su plataforma multimedia (radio + sitio + redes) en Puerto Madryn — emisora de radiodifusion, no un service_provider generico.
update public.companies
set industry = 'broadcasting_entertainment'
where id = '68457217-5a16-4b8c-b580-7d1186c9bdcc'
  and industry is not distinct from 'service_provider';

-- Access Partnership
-- Access Partnership es una consultora global de asuntos regulatorios y politica publica para el sector tecnologico/telecom, no un operador ni proveedor de servicios en si.
update public.companies
set industry = 'consulting'
where id = '386b85db-4134-44cb-bbbf-5b6d2ddf5725'
  and industry is not distinct from 'service_provider';

-- AcertiS
-- AcertiS (parte de Grupo DMC Tecnologias) construye/despliega redes de fibra optica y microondas (proyectos llave en mano) para operadores y municipios en LatAm — es un contratista de infraestructura de telecom, no un operador.
update public.companies
set industry = 'infrastructure_construction'
where id = 'b6f7bc33-3f6d-4d26-911e-c1ef648b8297'
  and industry is not distinct from 'service_provider';

-- AI-DA Robot
-- Ai-Da es un robot artista hiperrealista impulsado por IA (camaras, algoritmos, brazo robotico) — proyecto de robotica/IA, no una entidad de broadcasting.
update public.companies
set industry = 'technology'
where id = '5e536eae-f9ca-4675-af9c-e452c4859dc9'
  and industry is not distinct from NULL;

-- Akamai
-- Akamai es una red de distribucion de contenido (CDN) y plataforma de cloud/edge computing y seguridad.
update public.companies
set industry = 'colocation_hosting_cloud'
where id = 'b239c510-f69b-4d48-8cee-bd6acc0b1d76'
  and industry is not distinct from 'service_provider';

-- Amazon / AWS
-- Amazon Web Services es el proveedor de infraestructura cloud de Amazon.
update public.companies
set industry = 'colocation_hosting_cloud'
where id = 'f1595e15-7980-400c-b7cd-5d5169fd5fcb'
  and industry is not distinct from 'service_provider';

-- América Móvil
-- America Movil es un operador de telecomunicaciones (matriz de Claro) en LatAm.
update public.companies
set industry = 'telecommunications'
where id = '8d59c04d-fca2-4339-8ef7-ac9042a35491'
  and industry is not distinct from 'service_provider';

-- Argela
-- Argela (subsidiaria de Turk Telekom) desarrolla software y soluciones de red de proxima generacion (5G, SDN, NFV, analitica) para operadores — es una empresa de tecnologia/software de telecom, no un fabricante de hardware.
update public.companies
set industry = 'technology'
where id = '73ade016-cbc7-468c-a580-929f7f43ed11'
  and industry is not distinct from 'manufacturer';

-- ASIET (Asociación Interamericana de Empresas de Telecomunicaciones)
-- ASIET es la Asociacion Interamericana de Empresas de Telecomunicaciones — camara del sector telecom.
update public.companies
set industry = 'telecommunications'
where id = 'fae0b8d2-b511-4155-ba0f-c3d3ceeb278e'
  and industry is not distinct from NULL;

-- Asociación Internacional de Radiodifusión (AIR/IAB)
-- AIR/IAB es la Asociacion Internacional de Radiodifusion — entidad del sector de radiodifusion.
update public.companies
set industry = 'broadcasting_entertainment'
where id = '37739605-73a6-41d4-96ba-ed70b9f5a5d1'
  and industry is not distinct from NULL;

-- ATN International
-- ATN International es una holding de operadores de telecomunicaciones (Caribe/Bermuda/EE.UU.).
update public.companies
set industry = 'telecommunications'
where id = 'b13d5fb7-56ca-46fa-871c-e9f9494cb609'
  and industry is not distinct from 'service_provider';

-- Bell Labs Consulting
-- Bell Labs Consulting es la unidad de consultoria estrategica/tecnologica de Nokia Bell Labs para clientes de telecom y empresas.
update public.companies
set industry = 'consulting'
where id = '2b7bc1e0-1b59-4d23-b798-82c538f09bbd'
  and industry is not distinct from 'service_provider';

-- BlueNote Management Consulting
-- BlueNote Management Consulting es una consultora de gestion.
update public.companies
set industry = 'consulting'
where id = '280f4de4-996b-4ac3-b4fb-d35c5e0e7602'
  and industry is not distinct from 'service_provider';

-- br.digital Telecom
-- br.digital Telecom es un operador/proveedor de conectividad en Brasil.
update public.companies
set industry = 'telecommunications'
where id = 'c3a9dcc9-6344-42c2-a737-fd6d1cb154d4'
  and industry is not distinct from 'service_provider';

-- CADMIPyA (Cámara Argentina de Distribuidores Mayoristas de Informática, Productores y Afines)
-- CADMIPyA agrupa a los distribuidores mayoristas de informatica y afines de Argentina — camara del canal mayorista de IT.
update public.companies
set industry = 'retail_wholesale'
where id = '05466f57-6d02-4e2e-8a14-356df7ce280d'
  and industry is not distinct from NULL;

-- Cámara Argentina de Internet (CABASE)
-- CABASE es la Camara Argentina de Internet — entidad del sector de telecomunicaciones/Internet.
update public.companies
set industry = 'telecommunications'
where id = '6a70536f-98e8-465a-9aac-44e1ea64fa35'
  and industry is not distinct from NULL;

-- CATIP (Cámara Argentina de Telefonía IP)
-- CATIP es la Camara Argentina de Telefonia IP — entidad del sector telecom.
update public.companies
set industry = 'telecommunications'
where id = 'bd10713f-dfac-4cc9-8ac2-17149ca5c6ad'
  and industry is not distinct from NULL;

-- CICOMRA (Cámara de Informática y Comunicaciones de la República Argentina)
-- CICOMRA es la Camara de Informatica y Comunicaciones de la Republica Argentina — agrupa al sector de informatica/TI (y comunicaciones).
update public.companies
set industry = 'technology'
where id = '9003cc3c-e93f-40be-996a-91b1b4b89715'
  and industry is not distinct from NULL;

-- Claro (América Móvil)
-- Claro es el operador de telecomunicaciones de America Movil en Argentina.
update public.companies
set industry = 'telecommunications'
where id = 'd8c70578-4e15-4ef2-9de3-b139a4090642'
  and industry is not distinct from 'service_provider';

-- Condor Technologies
-- Condor Technologies desarrolla plataformas/software de billing y gestion en tiempo real (ej. Kuntur Fiber Manager) para carriers y proveedores SaaS — empresa de tecnologia/software para telecom, no un operador.
update public.companies
set industry = 'technology'
where id = 'ca032351-e4f4-4f70-ab39-6a04612e13dd'
  and industry is not distinct from 'service_provider';

-- Cullen International
-- Cullen International es una consultora de investigacion regulatoria y de politicas de telecom/medios (Europa).
update public.companies
set industry = 'consulting'
where id = '0edcb04e-1800-4e87-abf3-7941bae3d0c5'
  and industry is not distinct from 'service_provider';

-- Cytric Solutions
-- Cytric Solutions ofrece ciberseguridad industrial y monitoreo de amenazas para infraestructura critica — empresa de tecnologia/ciberseguridad.
update public.companies
set industry = 'technology'
where id = '12aaf324-c8db-4614-be35-e0e09891d982'
  and industry is not distinct from 'service_provider';

-- DAIA (Delegación de Asociaciones Israelitas Argentinas)
-- DAIA es una organizacion comunitaria (Delegacion de Asociaciones Israelitas Argentinas), no una empresa con un rubro de industria aplicable de la lista.
update public.companies
set industry = 'other'
where id = '12f745f0-4e87-42dd-a7ac-6a2cd3548f3e'
  and industry is not distinct from NULL;

-- DIRECTV LATAM
-- DIRECTV LATAM es un servicio de television paga satelital — radiodifusion/entretenimiento.
update public.companies
set industry = 'broadcasting_entertainment'
where id = '4d6341f3-baaa-4ee7-aed6-1ac139ef603d'
  and industry is not distinct from 'service_provider';

-- DPL News (Digital Policy Law)
-- DPL News (DPL Group) produce analisis estrategico, contenido y servicios de inteligencia sobre politica digital/telecom para audiencias especializadas — mas cercano a servicios profesionales de analisis/asesoria que a un medio masivo de entretenimiento.
update public.companies
set industry = 'professional_services'
where id = '35fadc17-0c77-491e-bf76-e4090f6ce30b'
  and industry is not distinct from NULL;

-- e&
-- e& (ex Etisalat) es un grupo de telecomunicaciones de EAU.
update public.companies
set industry = 'telecommunications'
where id = 'fdf3d78c-1b89-4e52-9178-060f32602026'
  and industry is not distinct from 'service_provider';

-- EchoStar Corporation
-- EchoStar Corporation es hoy un grupo de telecomunicaciones (Dish Network, Boost Mobile, Hughes) mas que un fabricante puro.
update public.companies
set industry = 'telecommunications'
where id = 'a2ba1baf-e0e6-4a4f-8ccb-feba6967b60a'
  and industry is not distinct from 'manufacturer';

-- Enersa (Energía de Entre Ríos S.A.)
-- Enersa es la empresa de energia electrica de la provincia de Entre Rios (distribucion/transmision electrica provincial).
update public.companies
set industry = 'power_gas_transmission_distribution'
where id = 'febea544-ba8d-4dc3-b1d3-6df466961005'
  and industry is not distinct from 'service_provider';

-- Fundación SALES
-- Fundacion SALES realiza misiones medicas/odontologicas gratuitas — entidad de salud.
update public.companies
set industry = 'healthcare_non_pharma'
where id = '4de42757-336c-43c2-bd81-bd5448c37eeb'
  and industry is not distinct from NULL;

-- Global Outcomes
-- Global Outcomes es una consultora/firma de asesoria para gobiernos, corporaciones y organismos multilaterales en LatAm.
update public.companies
set industry = 'consulting'
where id = '93dcb2a1-af4a-484f-9605-68602187cb53'
  and industry is not distinct from 'service_provider';

-- Globalstar
-- Globalstar es un operador de comunicaciones satelitales.
update public.companies
set industry = 'telecommunications'
where id = '660d01b1-0d1c-497d-bef0-9e34a9a44ea7'
  and industry is not distinct from 'service_provider';

-- Gogo Business Aviation
-- Gogo Business Aviation provee conectividad de banda ancha (satelital/aire-tierra) para aviacion de negocios — servicio de telecomunicaciones.
update public.companies
set industry = 'telecommunications'
where id = 'cde2427d-8530-4441-a5a1-d93c104af4c4'
  and industry is not distinct from 'service_provider';

-- Google / Google Cloud
-- Google Cloud es la plataforma de infraestructura cloud de Google.
update public.companies
set industry = 'colocation_hosting_cloud'
where id = '6d7afe38-306e-4f66-bf8f-24c1c62a78fb'
  and industry is not distinct from 'service_provider';

-- GSMA
-- GSMA es la asociacion global de operadores moviles.
update public.companies
set industry = 'telecommunications'
where id = '6fa62437-9484-498a-b340-c1e32b343cda'
  and industry is not distinct from NULL;

-- Hispasat
-- Hispasat es un operador de satelites de comunicaciones (España).
update public.companies
set industry = 'telecommunications'
where id = 'a4b0ac2a-7e85-4fea-a3fd-af20ab315252'
  and industry is not distinct from 'service_provider';

-- ILC
-- ILC (International Logistics Company) es una empresa de logistica/forwarding internacional especializada en los mercados de telecomunicaciones y broadcast — su rubro es transporte/logistica, no telecom en si.
update public.companies
set industry = 'transportation'
where id = '9b119f29-0a22-4a6f-bb29-d37c8bccb88e'
  and industry is not distinct from 'service_provider';

-- Ingenieros Argentinos Asociados (IAA)
-- Ingenieros Argentinos Asociados (IAA) es una firma de ingenieria.
update public.companies
set industry = 'construction_engineering'
where id = 'dc0cef7b-69b2-4eb1-a961-b12d5a86452d'
  and industry is not distinct from 'service_provider';

-- Instituto Superior Crónica
-- Instituto Superior Cronica es un instituto de formacion (periodismo/medios).
update public.companies
set industry = 'education'
where id = '87eea35d-8cb7-4a79-8961-5d926249ea86'
  and industry is not distinct from NULL;

-- Intelsat
-- Intelsat es un operador de satelites de comunicaciones.
update public.companies
set industry = 'telecommunications'
where id = 'c542fd52-b4a6-4e11-b371-9faae7027136'
  and industry is not distinct from 'service_provider';

-- iSpectrum
-- iSpectrum es una empresa de ingenieria digital argentina que desarrolla una plataforma SaaS propia para gestion del espectro radioelectrico (usada incluso por ENACOM) — empresa de tecnologia, no consultora pura.
update public.companies
set industry = 'technology'
where id = '61c6186d-06aa-4dcb-a1cf-c0d475dbfb5e'
  and industry is not distinct from 'service_provider';

-- Kaen / Approve ITSA
-- Approve-IT S.A. es una consultora de cumplimiento regulatorio (homologacion/type approval) para equipos de telecomunicaciones y seguridad electrica.
update public.companies
set industry = 'consulting'
where id = 'd1cf1b34-1cb8-4eb3-952b-95d013263c7b'
  and industry is not distinct from 'service_provider';

-- Liberty Latin America
-- Liberty Latin America es un operador de cable/telecomunicaciones en el Caribe/LatAm.
update public.companies
set industry = 'telecommunications'
where id = '74e8b615-7de0-4a6d-98b6-6b7912c695e9'
  and industry is not distinct from 'service_provider';

-- Lockheed Martin Corporation
-- Lockheed Martin es un contratista de defensa (la mayor parte de sus ingresos provienen de contratos militares); aunque tambien fabrica aeronaves/satelites, se clasifica como Militar/Defensa.
update public.companies
set industry = 'military_defense'
where id = '396099a5-c81d-4310-bfeb-e6a5f421232f'
  and industry is not distinct from 'manufacturer';

-- MADOC — Patagonian Single Malt
-- MADOC es una destileria de whisky patagonico — manufactura de bebidas/alimentos, distinto de 'manufacturer' (que en esta lista se usa para fabricantes de equipos tecnologicos/telecom).
update public.companies
set industry = 'manufacturing'
where id = '60f01f71-a3e9-4154-b0ff-caa2a6f938b9'
  and industry is not distinct from 'manufacturer';

-- MASORANGE
-- MASORANGE (fusion MasMovil + Orange España) es un operador de telecomunicaciones.
update public.companies
set industry = 'telecommunications'
where id = '4f4082ba-0605-4130-a9cc-cd32b132a9ad'
  and industry is not distinct from 'service_provider';

-- Metrotel
-- Metrotel es un operador de fibra/telecomunicaciones y datacenter en Argentina.
update public.companies
set industry = 'telecommunications'
where id = '8d2a2348-d205-400b-9271-cc52de26aa17'
  and industry is not distinct from 'service_provider';

-- Netflix
-- Netflix es un servicio de streaming de entretenimiento.
update public.companies
set industry = 'broadcasting_entertainment'
where id = '246adf04-c93e-4192-bc80-ce3b1d76f09d'
  and industry is not distinct from 'service_provider';

-- Omnispace
-- Omnispace desarrolla redes satelitales no terrestres (NTN) — servicio de telecomunicaciones.
update public.companies
set industry = 'telecommunications'
where id = '19ac3901-8dc6-4a02-ba2b-50869359214a'
  and industry is not distinct from 'service_provider';

-- Ookla (Ziff Davis)
-- Ookla (Ziff Davis) desarrolla software de testeo/analitica de redes (Speedtest) — empresa de tecnologia, no un operador.
update public.companies
set industry = 'technology'
where id = '5d52df4c-74cb-4ea7-a529-f00810e6c665'
  and industry is not distinct from 'service_provider';

-- ORACLE
-- Oracle es una empresa de software empresarial y cloud, no un fabricante de hardware.
update public.companies
set industry = 'technology'
where id = 'a756a87d-6507-4f27-9a02-a90361405d00'
  and industry is not distinct from 'manufacturer';

-- PAGBAM (Pérez Alati, Grondona, Benites & Arntsen)
-- PAGBAM es un estudio juridico (abogados) — servicios profesionales.
update public.companies
set industry = 'professional_services'
where id = 'e9b94c82-409d-4663-82f9-a62c1839213f'
  and industry is not distinct from 'service_provider';

-- Paramount Global
-- Paramount Global es un conglomerado de medios y entretenimiento.
update public.companies
set industry = 'broadcasting_entertainment'
where id = '18f9883a-506d-4da6-85de-f0af5fa0d7cf'
  and industry is not distinct from 'service_provider';

-- Red Intercable
-- Red Intercable es un operador de cable/telecomunicaciones en Argentina.
update public.companies
set industry = 'telecommunications'
where id = 'f739efa5-f96f-4eb8-be75-fb825c765382'
  and industry is not distinct from 'service_provider';

-- Research Institute for Digital Economy (IPE Digital)
-- IPE Digital es un instituto de investigacion sobre economia digital (Brasil) — servicios de investigacion/asesoria.
update public.companies
set industry = 'professional_services'
where id = '2380aae0-8f7d-427f-a64b-4be4bfe25d50'
  and industry is not distinct from NULL;

-- Rivada Space Networks
-- Rivada Space Networks desarrolla una constelacion satelital de telecomunicaciones.
update public.companies
set industry = 'telecommunications'
where id = '9afba1a0-dfb1-474f-9de9-fe41d68a4916'
  and industry is not distinct from 'service_provider';

-- Sateliot
-- Sateliot ofrece conectividad satelital para IoT.
update public.companies
set industry = 'telecommunications'
where id = '633a287c-76e8-4110-a5a6-9c7f3395656a'
  and industry is not distinct from 'service_provider';

-- SION
-- SION es un proveedor de Internet (ISP) y servicios de telecomunicaciones en Argentina, no una entidad financiera.
update public.companies
set industry = 'telecommunications'
where id = '121426d7-951c-4449-bee8-cbfdec6aaa9f'
  and industry is not distinct from 'financial_entity';

-- SpaceX
-- SpaceX es una empresa aeroespacial (cohetes, lanzamientos, Starlink) — mejor descripta como Aerospace que como 'manufacturer' generico.
update public.companies
set industry = 'aerospace'
where id = '788ba93d-763e-4cf5-b32c-30ce79beadb2'
  and industry is not distinct from 'manufacturer';

-- Telecom Personal Flow (Telecom Argentina)
-- Telecom Personal/Flow (Telecom Argentina) es un operador de telecomunicaciones.
update public.companies
set industry = 'telecommunications'
where id = '89842422-449e-45d2-886f-9e07729ab1e2'
  and industry is not distinct from 'service_provider';

-- Telecommunications Industry Association (TIA)
-- TIA es la Telecommunications Industry Association (EE.UU.) — camara del sector telecom.
update public.companies
set industry = 'telecommunications'
where id = '13781b7a-50cc-4310-918a-9ccd17a818e5'
  and industry is not distinct from NULL;

-- TelecomSat LLC.
-- TelecomSat LLC ofrece servicios de telecomunicaciones satelitales.
update public.companies
set industry = 'telecommunications'
where id = '2daf0a73-739c-4927-9333-8f52790eef52'
  and industry is not distinct from 'service_provider';

-- Telefónica
-- Telefonica es un operador de telecomunicaciones (España).
update public.companies
set industry = 'telecommunications'
where id = 'bfcf7b4e-8782-4dab-8bf3-e1f139223726'
  and industry is not distinct from 'service_provider';

-- Telespazio (a Leonardo and Thales company)
-- Telespazio (Leonardo/Thales) opera servicios satelitales (telecom, observacion de la Tierra, navegacion).
update public.companies
set industry = 'telecommunications'
where id = '717b6c4b-c454-4208-9523-76bcd518879e'
  and industry is not distinct from 'service_provider';

-- TMG
-- TMG (tmgtelecom.com) es una empresa de telecomunicaciones francesa.
update public.companies
set industry = 'telecommunications'
where id = 'adb41326-4527-4b59-b70c-4b20b88bab54'
  and industry is not distinct from 'service_provider';

-- Trans (transadvanced.tech)
-- Trans Advanced Technologies es una integradora/desarrolladora de soluciones tecnologicas (conectividad, ciberseguridad, salud/educacion digital) en Argentina.
update public.companies
set industry = 'technology'
where id = '341af84a-f294-4c17-a0c8-ac78d77cc0a0'
  and industry is not distinct from 'service_provider';

-- VRIO Corp
-- VRIO Corp es la holding de television paga satelital de LatAm (DIRECTV Latin America / Sky Brasil).
update public.companies
set industry = 'broadcasting_entertainment'
where id = 'b6b3d982-6b45-4b16-902c-d745ae6d380b'
  and industry is not distinct from 'service_provider';

-- Zzoomm plc
-- Zzoomm plc es un proveedor de banda ancha de fibra (ISP) en el Reino Unido.
update public.companies
set industry = 'telecommunications'
where id = '27b1db97-8729-4dd0-a225-188c425ed28c'
  and industry is not distinct from 'service_provider';
