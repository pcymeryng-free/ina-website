-- ============================================================================
-- Alta de proyecto: Programa Nacional de Infraestructura Compartida y
-- Acceso Abierto para el Desarrollo Digital Federal
-- Proponente: CAPPI — Cámara Argentina de Pequeños Proveedores de Internet
-- Propuesta institucional presentada a ENACOM, junio de 2026
-- Fuente: Programa Nacional de infraestructura compartida y acceso directo.pdf
--
-- NOTA CONCEPTUAL — leer antes de correr este script
-- A diferencia de los otros dos proyectos de CAPPI ya cargados (Red
-- Federal de Centros Regionales de IA y Datos = obra de infraestructura
-- concreta), este documento NO es un proyecto de despliegue físico: es una
-- propuesta de MARCO REGULATORIO/NORMATIVO nacional (acceso abierto y
-- comparticion de infraestructura pasiva/activa entre operadores,
-- inspirada en los modelos de Colombia y Brasil). No tiene sitio, ruta,
-- capacidad ni CAPEX propios — por eso no encaja en ninguna de las
-- categorías con template guiado (ai_datacenter, submarine_cable,
-- wholesale_neutral_network, early_warning_system) y se carga con
-- project_type = 'other'. No se completa shared_field_answers porque no
-- hay ningún PROJECT_TEMPLATES pensado para una propuesta normativa.
-- Si en el futuro la plataforma modela "propuestas regulatorias" como una
-- entidad propia (más cerca de public.programs o de un
-- roadmap_template que de public.projects), este registro sería
-- candidato a migrar ahí — por ahora se carga como proyecto para que
-- quede visible y trazable en la plataforma, tal como pidió el usuario.
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

  'Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal',

  -- Ver "NOTA CONCEPTUAL" arriba: es una propuesta de marco regulatorio,
  -- no una obra de infraestructura con tipo definido.
  'other',

  'Argentina',

$desc$Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal. Propuesta institucional de CAPPI (Camara Argentina de Pequenos Proveedores de Internet) presentada a ENACOM en junio de 2026, tomando como referencia los marcos regulatorios de Colombia y Brasil y adaptandolos al rol de cooperativas electricas, distribuidoras provinciales, prestadores PyME, operadores regionales y organismos publicos en Argentina.

Diagnostico: el principal obstaculo para seguir expandiendo redes de telecomunicaciones en Argentina ya no es tecnologico sino economico, regulatorio y administrativo. Existen miles de kilometros de infraestructura ya instalada (postes electricos, columnas de alumbrado, ductos, camaras, torres, redes de fibra optica, infraestructura pasiva y activa, terrenos fiscales inutilizados, ductos vacios de Arsat) con capacidad ociosa o subutilizada, mientras cientos de localidades siguen sin acceso adecuado por los altos costos de despliegue y la falta de reglas uniformes de acceso. CAPPI identifica cinco problemas centrales: asimetria regulatoria entre provincias/municipios/cooperativas/distribuidoras, costos de ocupacion imprevisibles, barreras de entrada para pequenos operadores, duplicacion innecesaria de infraestructura en algunas localidades mientras otras quedan desatendidas, y saturacion fisica en ciertos sectores urbanos.

Experiencia internacional de referencia: Colombia desarrollo uno de los marcos regulatorios mas avanzados de la region (acceso obligatorio, tarifas basadas en costos eficientes, metodologias publicas, transparencia, no discriminacion, resolucion regulatoria de controversias), reforzado por la Ley 2416 de 2024 que declaro de utilidad publica e interes social las obras de despliegue de infraestructura de telecomunicaciones. Brasil desarrollo un modelo coordinado entre ANATEL y ANEEL basado en comparticion obligatoria, puntos de fijacion normalizados, inventarios de ocupacion, tarifas reguladas y procedimientos uniformes. La ensenanza para Argentina: reglas claras, costos eficientes y mecanismos transparentes de acceso aumentan la inversion, mejoran la competencia, reducen las barreras de entrada y aceleran la conectividad, sin necesidad de subsidiar operadores.

Principios rectores propuestos para el modelo argentino: (1) Facilidad esencial - toda infraestructura apta para soportar redes de telecomunicaciones se considera estrategica para el desarrollo nacional; (2) Acceso abierto - todo operador habilitado por ENACOM puede solicitar acceso; (3) No discriminacion - condiciones iguales para todos los prestadores; (4) Transparencia - criterios tecnicos y economicos publicos; (5) Costos eficientes - remuneracion basada en costos reales y rentabilidad razonable; (6) Desarrollo federal - toda politica publica debe priorizar la reduccion de asimetrias territoriales.

Alcance de la comparticion: infraestructura electrica y asociada (postes, columnas, ductos, camaras, canalizaciones, infraestructura subterranea), sujeta a que exista capacidad disponible, sea tecnicamente viable, no afecte la seguridad y no degrade los servicios existentes. Comparticion pasiva: fibra oscura, ductos, camaras, torres, shelters, espacios tecnicos. Comparticion activa (cuando no resulte viable desplegar nueva infraestructura fisica): OLT, GPON, XGS-PON, Ethernet, MPLS, DWDM, backhaul, datacenters. Para localidades con restricciones tecnicas, ambientales o urbanisticas se proponen mecanismos de acceso mayorista sobre infraestructura existente con condiciones transparentes, razonables y no discriminatorias.

Mecanismos institucionales propuestos:
- Metodologia Nacional de Costos Eficientes: la remuneracion por uso de infraestructura contemplaria CAPEX, OPEX, vida util, depreciacion, mantenimiento, administracion y rentabilidad razonable, garantizando una remuneracion justa al propietario sin encarecer artificialmente las nuevas inversiones.
- Tarifa Nacional de Referencia: previsibilidad, seguridad juridica, transparencia y equidad territorial (el objetivo no es fijar precios artificialmente bajos sino eliminar distorsiones).
- Banco Nacional de Postes y Ductos: administrado por ENACOM, con informacion de ubicacion, propietario, capacidad, ocupacion, disponibilidad y estado tecnico de cada activo, para reducir conflictividad y aumentar transparencia y eficiencia.
- Registro Nacional de Infraestructura Disponible: declaracion de redes FTTH, fibra oscura, OLT, backhaul, datacenters y capacidad disponible, para facilitar acuerdos entre operadores y acelerar despliegues.
- Mesa Nacional de Infraestructura Compartida: integrada por ENACOM, ARSAT, CAPPI, cooperativas electricas, distribuidoras, provincias, municipios, operadores TIC y OSRNA, con funciones de actualizacion normativa, resolucion de controversias, seguimiento de indicadores y revision metodologica.

Beneficios por actor: ENACOM (mas conectividad, mas competencia, menos conflictos); provincias (mas inversion, mas empleo, mas desarrollo); municipios (menor ocupacion del espacio publico, menor impacto visual); cooperativas y distribuidoras (ingresos previsibles, reglas claras); ISP (menores costos de despliegue, mas capacidad de inversion); usuarios (mas competencia, mejor calidad, mas opciones).

Impacto esperado durante los primeros cinco anos: mas competencia, menor costo de despliegue, mas localidades conectadas, menos duplicacion de infraestructura, mayor aprovechamiento de activos existentes, menor ocupacion del espacio publico, mayor velocidad de expansion FTTH, mayor acceso a servicios digitales y mejor infraestructura de base para Inteligencia Artificial.

Fuente: PROPUESTA CAPPI-ENACOM - Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal, Camara Argentina de Pequenos Proveedores de Internet (CAPPI), junio de 2026 (documento adjunto en la seccion de documentos tecnicos del proyecto).$desc$,

  -- beneficiary_count: no aplica - es una propuesta de marco regulatorio de
  -- alcance nacional, no una obra con una poblacion beneficiaria acotada.
  null,

  'CAPPI - Camara Argentina de Pequenos Proveedores de Internet',

  -- Mismo criterio que en los otros proyectos de CAPPI ya cargados: es una
  -- camara/asociacion sectorial, no un ISP individual ni un organismo
  -- publico, asi que 'other' es el valor mas correcto de la taxonomia
  -- existente.
  'other'
);

-- Verificación: confirma que el proyecto se creó y te muestra su id.
select id, name, project_type, country, generating_entity_name, created_at
from public.projects
where name = 'Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal'
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
-- 2. Abrí el proyecto "Programa Nacional de Infraestructura Compartida y
--    Acceso Abierto...".
-- 3. En la sección de Documentos, subí el archivo
--    "Programa Nacional de infraestructura compartida y acceso
--    directo.pdf" en la categoría "Administrativa" (administrative) — es
--    la que mejor corresponde a una propuesta normativa/regulatoria, más
--    que "Técnica" (que en este proyecto usaste para las dos propuestas
--    de infraestructura física de CAPPI).
--
-- El paso 3 inserta automáticamente la fila correspondiente en
-- public.project_documents con el storage_path correcto; un INSERT manual
-- por SQL no puede garantizar eso sin haber subido antes el archivo al
-- bucket.
-- ============================================================================
