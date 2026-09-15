-- Data: telecom infrastructure product catalog for Master Data > Products
-- Generated per Pablo's request: "armar lista de productos de infraestructura de
-- telecomunicaciones y generar sql para insertar en la base de datos de productos".
--
-- Scope (per his answers): products aligned to the platform's own 8 project-type
-- categories (assets/platform.js's PROJECT_TYPES) -- submarine cable, fiber
-- backbone/last mile, FWA, neutral wholesale network, AI datacenter, satellite
-- communications, early warning system, and passive infrastructure -- so the
-- catalog's `category` values line up with vocabulary already used elsewhere in
-- the platform. Each product is a real, named product/service (verified via web
-- search), linked to its real manufacturer/provider already on file in Master Data
-- via a name lookup subquery (no hardcoded company UUIDs, so this still works if
-- company ids differ or the row was re-created). Two products have no matching
-- manufacturer yet in Master Data (submarine wet-plant cable itself, and a generic
-- Cell Broadcast alert platform) -- company_id is left NULL for those, noted in
-- each one's description.
--
-- `products.category` is a free-text column (no CHECK constraint) -- these use the
-- Spanish labels from PROJECT_TYPES verbatim so they read consistently with the
-- rest of the platform.
--
-- Excludes Chinese-origin products per Pablo's follow-up request ("quitar de la
-- base de productos los de origen chino") -- the two Huawei-linked entries
-- (OptiX OSN, 5G CPE Pro) originally in this file were removed. See
-- data_remove_chinese_origin_products.sql for the matching DELETE, in case this
-- file (with the Huawei rows) was already run against the database.
-- Run manually in Supabase SQL Editor.

insert into public.products (name, company_id, category, description)
values (
  'WaveLogic 6 Extreme',
  (select id from public.companies where name = 'Ciena' limit 1),
  'Cable Submarino',
  'Sistema de transmisión óptica coherente de Ciena para cables submarinos, con capacidad de hasta 1.6 Tbps por longitud de onda sobre distancias transoceánicas.'
);

insert into public.products (name, company_id, category, description)
values (
  '6500 Packet-Optical Platform',
  (select id from public.companies where name = 'Ciena' limit 1),
  'Cable Submarino',
  'Plataforma de terminal de línea (equipo de planta seca) de Ciena, utilizada en sistemas de cable submarino en combinación con el ''wet plant'' de fabricantes especializados.'
);

insert into public.products (name, company_id, category, description)
values (
  'Cable de fibra óptica submarino (repetido, larga distancia)',
  null,
  'Cable Submarino',
  'Cable de fibra óptica de grado submarino con repetidores para tramos transoceánicos. Sin fabricante específico cargado aún en Master Data (proveedores típicos: SubCom, Alcatel Submarine Networks, NEC).'
);

insert into public.products (name, company_id, category, description)
values (
  '1830 Photonic Service Switch (PSS)',
  (select id from public.companies where name = 'Nokia' limit 1),
  'Fibra Backbone / Última Milla',
  'Plataforma óptica de transporte (DWDM) de Nokia para redes de backbone de fibra de alta capacidad.'
);

insert into public.products (name, company_id, category, description)
values (
  'Router 6000',
  (select id from public.companies where name = 'Ericsson' limit 1),
  'Fibra Backbone / Última Milla',
  'Familia de routers IP/MPLS de Ericsson para transporte de backbone y agregación en redes de fibra.'
);

insert into public.products (name, company_id, category, description)
values (
  'Cable de fibra óptica (loose tube, exterior)',
  (select id from public.companies where name = 'STL (Sterlite Technologies Limited)' limit 1),
  'Fibra Backbone / Última Milla',
  'Cable de fibra óptica de tubo suelto para tendido exterior, usado en despliegues de backbone y última milla.'
);

insert into public.products (name, company_id, category, description)
values (
  'Radio System AIR',
  (select id from public.companies where name = 'Ericsson' limit 1),
  'Acceso Inalámbrico Fijo (FWA)',
  'Antenas activas integradas (Antenna Integrated Radio) de Ericsson, usadas en soluciones de acceso inalámbrico fijo y redes móviles.'
);

insert into public.products (name, company_id, category, description)
values (
  'FastMile 5G Gateway',
  (select id from public.companies where name = 'Nokia' limit 1),
  'Acceso Inalámbrico Fijo (FWA)',
  'Equipo de cliente (CPE) 5G de Nokia diseñado específicamente para acceso inalámbrico fijo (FWA).'
);

insert into public.products (name, company_id, category, description)
values (
  'Snapdragon X65 5G Modem-RF System',
  (select id from public.companies where name = 'Qualcomm' limit 1),
  'Acceso Inalámbrico Fijo (FWA)',
  'Chipset módem-RF 5G de Qualcomm utilizado en equipos de cliente (CPE) para acceso inalámbrico fijo.'
);

insert into public.products (name, company_id, category, description)
values (
  'Soluciones vRAN / SDN para operadores',
  (select id from public.companies where name = 'Argela' limit 1),
  'Red Mayorista Neutral (5G/FWA)',
  'Software de red de acceso radio virtualizada (vRAN) y redes definidas por software (SDN) de Argela, aplicable a esquemas de red mayorista neutral.'
);

insert into public.products (name, company_id, category, description)
values (
  'AirScale Cloud RAN',
  (select id from public.companies where name = 'Nokia' limit 1),
  'Red Mayorista Neutral (5G/FWA)',
  'Solución de RAN virtualizada en la nube de Nokia, utilizada en despliegues de redes neutrales compartidas entre operadores.'
);

insert into public.products (name, company_id, category, description)
values (
  'Cloud RAN',
  (select id from public.companies where name = 'Ericsson' limit 1),
  'Red Mayorista Neutral (5G/FWA)',
  'Solución de acceso radio virtualizado (Cloud RAN) de Ericsson, aplicable a modelos de infraestructura mayorista compartida.'
);

insert into public.products (name, company_id, category, description)
values (
  'Oracle Cloud Infrastructure (OCI) Supercluster',
  (select id from public.companies where name = 'ORACLE' limit 1),
  'Datacenter para Cargas de IA',
  'Infraestructura de cómputo de alto rendimiento de Oracle para el entrenamiento de modelos de inteligencia artificial a gran escala.'
);

insert into public.products (name, company_id, category, description)
values (
  'Cloud TPU / AI Hypercomputer',
  (select id from public.companies where name = 'Google / Google Cloud' limit 1),
  'Datacenter para Cargas de IA',
  'Unidades de procesamiento tensorial (TPU) e infraestructura de supercómputo de IA de Google Cloud.'
);

insert into public.products (name, company_id, category, description)
values (
  'EC2 UltraClusters',
  (select id from public.companies where name = 'Amazon / AWS' limit 1),
  'Datacenter para Cargas de IA',
  'Clústeres de cómputo con GPU a gran escala de AWS, orientados al entrenamiento de modelos de IA.'
);

insert into public.products (name, company_id, category, description)
values (
  'Akamai Cloud GPU Compute',
  (select id from public.companies where name = 'Akamai' limit 1),
  'Datacenter para Cargas de IA',
  'Servicio de cómputo en la nube con GPU de Akamai Cloud (ex Linode), orientado a cargas de trabajo de IA e inferencia distribuida.'
);

insert into public.products (name, company_id, category, description)
values (
  'Terminal de banda ancha satelital Starlink',
  (select id from public.companies where name = 'SpaceX' limit 1),
  'Comunicaciones Satelitales',
  'Terminal de usuario para la constelación satelital de órbita baja Starlink, de SpaceX.'
);

insert into public.products (name, company_id, category, description)
values (
  'JUPITER System',
  (select id from public.companies where name = 'Hughes Network Systems' limit 1),
  'Comunicaciones Satelitales',
  'Sistema terreno satelital (gateway y terminales) de Hughes, usado en redes de banda ancha satelital de alta capacidad.'
);

insert into public.products (name, company_id, category, description)
values (
  'FlexEnterprise',
  (select id from public.companies where name = 'Intelsat' limit 1),
  'Comunicaciones Satelitales',
  'Servicio satelital gestionado de Intelsat para conectividad empresarial de alta disponibilidad.'
);

insert into public.products (name, company_id, category, description)
values (
  'Módulos satelitales IoT/Data',
  (select id from public.companies where name = 'Globalstar' limit 1),
  'Comunicaciones Satelitales',
  'Módulos de comunicación satelital de baja potencia de Globalstar para aplicaciones de IoT y transmisión de datos.'
);

insert into public.products (name, company_id, category, description)
values (
  'Conectividad satelital 5G NB-IoT',
  (select id from public.companies where name = 'Sateliot' limit 1),
  'Comunicaciones Satelitales',
  'Servicio de conectividad NB-IoT vía satélite de Sateliot, compatible con el estándar 5G, para dispositivos IoT en zonas sin cobertura terrestre.'
);

insert into public.products (name, company_id, category, description)
values (
  'Radar Meteorológico Argentino (RMA)',
  (select id from public.companies where name = 'INVAP' limit 1),
  'Sistema de Alerta Temprana',
  'Radar meteorológico desarrollado y fabricado íntegramente en Argentina por INVAP, componente clave de la red SINARAME para la detección temprana de tormentas severas.'
);

insert into public.products (name, company_id, category, description)
values (
  'Plataforma de alerta por Cell Broadcast',
  null,
  'Sistema de Alerta Temprana',
  'Plataforma de difusión de alertas de emergencia por Cell Broadcast/SMS. Sin fabricante específico cargado aún en Master Data.'
);

insert into public.products (name, company_id, category, description)
values (
  'Cable OPGW (Optical Ground Wire)',
  (select id from public.companies where name = 'STL (Sterlite Technologies Limited)' limit 1),
  'Infraestructura Pasiva',
  'Cable de tierra con fibra óptica integrada (OPGW) de STL, usado en infraestructura pasiva combinada con líneas de energía.'
);

insert into public.products (name, company_id, category, description)
values (
  'Despliegue llave en mano de fibra y microondas',
  (select id from public.companies where name = 'AcertiS' limit 1),
  'Infraestructura Pasiva',
  'Servicio de despliegue llave en mano de redes de fibra óptica y enlaces de microondas para operadores y municipios, de AcertiS (Grupo DMC Tecnologías).'
);

insert into public.products (name, company_id, category, description)
values (
  'Obras civiles para ductos y postación',
  (select id from public.companies where name = 'Ingenieros Argentinos Asociados (IAA)' limit 1),
  'Infraestructura Pasiva',
  'Servicios de ingeniería y obra civil para el despliegue de ductos, cámaras y postación de infraestructura pasiva de telecomunicaciones.'
);
