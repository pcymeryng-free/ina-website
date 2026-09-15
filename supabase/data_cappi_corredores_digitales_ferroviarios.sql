-- ============================================================================
-- Alta de proyecto: Plan Argentina Digital Federal 2040 — Programa
-- Nacional de Corredores Digitales Ferroviarios
-- Proponente: CAPPI — Cámara Argentina de Pequeños Proveedores de Internet
-- Propuesta institucional presentada a ENACOM, junio de 2026
-- Fuente: Plan_Argentina_Digital_Federal_2040_CAPPI-ENACOM.pdf
--
-- POR QUÉ 'fiber_backbone_last_mile'
-- A diferencia de la propuesta de "Infraestructura Compartida y Acceso
-- Abierto" (marco regulatorio, sin obra física — cargada como 'other'),
-- este documento SÍ describe una obra concreta: una red troncal de fibra
-- óptica (96/144/288 fibras, lista para DWDM) desplegada sobre las trazas
-- ferroviarias existentes en todo el país, complementando la REFEFO. Es
-- el mismo tipo de obra que el Proyecto Cruce Transandino ya cargado
-- (backbone de fibra de largo alcance) — por eso usa la misma categoría
-- 'fiber_backbone_last_mile'. No hay un PROJECT_TEMPLATES guiado para este
-- tipo (solo ai_datacenter, submarine_cable, wholesale_neutral_network y
-- early_warning_system lo tienen), así que no se completa
-- shared_field_answers, igual que con el Cruce Transandino.
--
-- CÓMO USAR ESTE ARCHIVO
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. En la línea marcada "EDITAR" más abajo, reemplazá el email por el de
--    la cuenta de la plataforma INA que va a figurar como propietaria del
--    proyecto. Tiene que ser un email que YA tenga fila en
--    public.profiles.
-- 3. Ejecutá el script completo. Al final corre un SELECT de verificación.
-- 4. El PDF original no se puede adjuntar por SQL — ver instrucciones al
--    pie de este archivo.
-- ============================================================================

insert into public.projects (
  user_id,
  name,
  project_type,
  country,
  description,
  beneficiary_count,
  generating_entity_name,
  generating_entity_type
)
values (
  -- EDITAR: email de la cuenta que debe figurar como dueña del proyecto.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'Plan Argentina Digital Federal 2040 - Corredores Digitales Ferroviarios',

  'fiber_backbone_last_mile',

  'Argentina',

$desc$Plan Argentina Digital Federal 2040 - Programa Nacional de Corredores Digitales Ferroviarios. Propuesta institucional de CAPPI (Camara Argentina de Pequenos Proveedores de Internet) presentada a ENACOM en junio de 2026: transformar los corredores ferroviarios argentinos en corredores digitales, desplegando fibra optica troncal sobre trazas, servidumbres, estaciones y predios ferroviarios ya existentes en todo el pais.

Relacion con REFEFO: la propuesta se presenta explicitamente como complemento de la Red Federal de Fibra Optica (REFEFO), no como reemplazo ni competencia. Busca potenciarla y expandir su alcance territorial aprovechando la infraestructura ferroviaria existente (servidumbres, estaciones, galpones, predios operativos, edificios ferroviarios, infraestructura tecnica y postes historicos de comunicaciones), evitando duplicar infraestructura.

Por que los ferrocarriles: los corredores ferroviarios ya atraviesan grandes ciudades, ciudades intermedias, localidades rurales, zonas industriales, regiones agropecuarias, puertos y centros logisticos - trazas que en gran parte conservan servidumbres y activos reutilizables para una nueva red digital federal.

Objetivo general: desarrollar una red nacional de infraestructura digital basada en corredores ferroviarios que complemente la REFEFO, democratice el acceso al ancho de banda, reduzca las asimetrias regionales y cree las condiciones para el desarrollo de la economia digital argentina. Objetivos estrategicos: complementar la REFEFO, reducir costos de transporte mayorista, crear nuevas rutas digitales, generar redundancia nacional, desarrollar infraestructura para Inteligencia Artificial, fortalecer a los ISP PyME y cooperativas, impulsar la economia del conocimiento, crear empleo tecnologico, promover el desarrollo regional y democratizar el acceso a las nuevas tecnologias.

Arquitectura del proyecto - cinco componentes:
1) Red Nacional de Corredores Digitales Ferroviarios: despliegue de fibra optica troncal sobre ramales ferroviarios activos, ramales de carga, ramales inactivos y trazas historicas. Capacidad inicial sugerida de 96, 144 o 288 fibras segun corredor, preparada para DWDM, transporte de alta capacidad, redes de Inteligencia Artificial e interconexion de datacenters.
2) Programa Estacion Digital Argentina: cada estacion ferroviaria estrategica se transforma en nodo digital regional (punto de interconexion, centro de datos, nodo de IA, centro de capacitacion tecnologica, punto de monitoreo urbano, centro de servicios municipales, nodo de videovigilancia).
3) Programa Postes del Telegrafo: relevamiento, recuperacion y reutilizacion de postes telegraficos historicos tecnicamente aptos, con menor costo de despliegue, menor impacto ambiental, recuperacion patrimonial y mayor velocidad de implementacion; donde no sea viable su uso, se reemplazan manteniendo la traza existente.
4) IXP Federales y Puntos de Interconexion Regional: puntos de interconexion regionales para ISP, cooperativas, municipios, universidades y datacenters, para reducir la concentracion de trafico en los grandes centros urbanos (menor latencia, menor costo de transito, mas competencia, mejor calidad de servicio).
5) Red Federal de Centros Regionales de IA y Datos: la infraestructura ferroviaria como columna vertebral de la Red Federal de Centros Regionales de IA y Datos (otra propuesta de CAPPI ya cargada en la plataforma), alojando micro datacenters, plataformas cloud, almacenamiento regional, servidores GPU, servicios de IA y backup regional en cada nodo.

Red Argentina de IA Distribuida: la integracion de REFEFO, Corredores Digitales Ferroviarios, Centros Regionales de IA, IXP Federales y Datacenters Regionales permitiria crear la primera infraestructura nacional distribuida para Inteligencia Artificial, con menor latencia, menor dependencia de centros urbanos, procesamiento regional y servicios digitales federales.

Beneficios por actor: ENACOM (mas conectividad, competencia, cobertura e infraestructura federal); ARSAT (mas capilaridad para REFEFO, mas puntos de acceso, mas utilizacion de infraestructura); Trenes Argentinos (puesta en valor de activos, nuevos usos para infraestructura existente, ingresos complementarios); provincias (inversion, empleo, desarrollo tecnologico); municipios (infraestructura digital, ciudades inteligentes, videovigilancia, servicios digitales); ISP PyME (menor costo mayorista, nuevas oportunidades de negocio, mas competitividad); universidades (centros regionales de datos, investigacion, innovacion); empresas (servicios cloud, IA regional, infraestructura tecnologica); ciudadanos (Internet mas accesible, mejor calidad de servicio, mas oportunidades).

Etapas de implementacion: Fase 1 - Mapa Nacional de Corredores Digitales (6 meses). Fase 2 - Corredores Piloto (12 meses; objetivo 5.000 km iniciales). Fase 3 - Nodos Regionales e IXP (24 meses). Fase 4 - Integracion con Centros Regionales de IA (36 meses). Fase 5 - Expansion Nacional (horizonte 2040; objetivo mas de 20.000 km de corredores digitales ferroviarios integrados a la REFEFO).

Mesa Nacional de Coordinacion (participantes sugeridos): ENACOM, ARSAT, CAPPI, Trenes Argentinos Infraestructura, Trenes Argentinos Cargas, provincias, municipios, universidades, cooperativas y prestadores TIC.

Fuente: PROPUESTA CAPPI-ENACOM - Plan Argentina Digital Federal 2040, Programa Nacional de Corredores Digitales Ferroviarios, Camara Argentina de Pequenos Proveedores de Internet (CAPPI), junio de 2026 (documento adjunto en la seccion de documentos tecnicos del proyecto).$desc$,

  -- beneficiary_count: el documento da metas de kilometros de traza
  -- (5.000 km en la Fase 2, +20.000 km al horizonte 2040) pero no una
  -- cifra de poblacion/hogares beneficiados. Queda en NULL.
  null,

  'CAPPI - Camara Argentina de Pequenos Proveedores de Internet',

  -- Mismo criterio que en los demas proyectos de CAPPI ya cargados: es
  -- una camara/asociacion sectorial, no un ISP individual ni un organismo
  -- publico, asi que 'other' es el valor mas correcto de la taxonomia
  -- existente.
  'other'
);

-- Verificación: confirma que el proyecto se creó y te muestra su id.
select id, name, project_type, country, generating_entity_name, created_at
from public.projects
where name = 'Plan Argentina Digital Federal 2040 - Corredores Digitales Ferroviarios'
order by created_at desc
limit 1;

-- ============================================================================
-- PASO SIGUIENTE (fuera de SQL): adjuntar el PDF original
-- ============================================================================
-- Los documentos de un proyecto viven en Supabase Storage (bucket
-- "project-documents"), no en una tabla que se pueda poblar con SQL plano
-- sin subir el archivo real. Para adjuntar el PDF:
--
-- 1. Entrá a la plataforma (app/dashboard.html) con la cuenta que usaste
--    como dueña del proyecto arriba.
-- 2. Abrí el proyecto "Plan Argentina Digital Federal 2040 - Corredores
--    Digitales Ferroviarios".
-- 3. En la sección de Documentos, subí el archivo
--    "Plan_Argentina_Digital_Federal_2040_CAPPI-ENACOM.pdf" en la
--    categoría "Técnica" (technical).
--
-- El paso 3 inserta automáticamente la fila correspondiente en
-- public.project_documents con el storage_path correcto; un INSERT manual
-- por SQL no puede garantizar eso sin haber subido antes el archivo al
-- bucket.
--
-- NOTA: si más adelante querés vincular formalmente este proyecto con el
-- de "Red Federal de Centros Regionales de IA y Datos" (Componente 5 de
-- esta propuesta), la forma correcta en el modelo actual es agrupar
-- ambos bajo un mismo public.programs (ver app/programs.html /
-- app/new-program.html) — projects.program_id los relaciona como parte
-- de una misma iniciativa "paraguas", igual que hace Chubut con su Hub
-- Digital Patagónico.
-- ============================================================================
