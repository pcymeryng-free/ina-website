-- ============================================================================
-- Alta de proyecto: Finalización de Despliegue FTTH y Migración HFC-FTTH
-- Proponente: Cooperativa de Luz y Fuerza Eléctrica, Industrias y Otros
-- Servicios Públicos, Vivienda y Crédito de Punta Alta Limitada (CEPA)
-- Punta Alta, Partido de Coronel Rosales, Provincia de Buenos Aires
-- Carpeta Técnica presentada a ENACOM — Programa FATIC (Financiamiento y
-- Apoyo a Proveedores de Servicios de TIC, Res. ENACOM 950/25), línea de
-- financiamiento "Créditos a Tasa Subsidiada"
-- Fuente: 0004 - IF-2026-22344883-APN-AICPUST%ENACOM(CARPETA TECNICA).pdf
--
-- NOTA: la Carpeta Técnica original tiene algunos campos sin completar por
-- la Cooperativa (ej. "cubre al xxxx% de la localidad", comercios/
-- establecimientos educativos/salud/policía/bomberos beneficiados sin
-- cifra, texto descriptivo de la sección 15 en blanco aunque el cuadro
-- resumen de inversión sí está completo). La descripción de abajo refleja
-- exactamente lo que el documento completó y deja fuera lo que no —no se
-- inventó ningún dato.
--
-- POR QUÉ 'fiber_backbone_last_mile'
-- Es un proyecto de finalización de red FTTH (última milla) + migración
-- tecnológica HFC→FTTH de un ISP cooperativo ya operativo — encaja
-- directamente en esta categoría (la misma que usan Cruce Transandino y
-- Corredores Digitales Ferroviarios), y es además el tipo elegible tanto
-- para Universal Service Funds (USF_ELIGIBLE_TYPES) como para la
-- herramienta de FSU Scoring de la plataforma (ver nota al final).
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

  'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta',

  'fiber_backbone_last_mile',

  'Argentina',

$desc$Finalizacion de Despliegue FTTH y Migracion HFC-FTTH en Punta Alta (Partido de Coronel Rosales, Provincia de Buenos Aires). Carpeta Tecnica presentada por la Cooperativa de Luz y Fuerza Electrica, Industrias y Otros Servicios Publicos, Vivienda y Credito de Punta Alta Limitada (CEPA) ante ENACOM, en el marco del Programa FATIC "Financiamiento y Apoyo a Proveedores de Servicios de TIC" (Resolucion ENACOM N 950/25), linea de financiamiento "Creditos a Tasa Subsidiada". Documento GEDO IF-2026-22344883-APN-AICPUST#ENACOM.

Objetivo: completar el despliegue de la red de fibra optica al hogar (FTTH) en el 45% del area de cobertura donde aun no esta disponible, y en forma complementaria impulsar la migracion progresiva de los usuarios que aun operan sobre la red HFC hacia la nueva infraestructura FTTH (mayor velocidad, mejor uplink, menor latencia, equipamiento WiFi 6).

Diagnostico / problematica actual: (a) Bajo nivel de migracion sobre la red ya desplegada - la FTTH ya cubre el 55% del area de cobertura, pero solo el 50% de los usuarios de esa zona migro; dentro de ese segmento el 45% mantiene planes HFC de 6 y 14 Mbps, un 30% usa equipos sin WiFi y el 70% restante tiene WiFi 4 obsoleto. (b) Cobertura incompleta de la nueva red - resta desplegar aproximadamente el 45% de la red FTTH, lo que impide que la totalidad de los asociados acceda a planes de 100 Mbps o superiores.

Estado de la red actual: la CEPA opera una red HFC bajo estandar DOCSIS 3.0 que cubre la totalidad de Punta Alta, con diseno que data de 2002 (aprox. 2000 hogares pasados por nodo). Desde 2021 despliega en paralelo una red FTTH, hoy operativa en aproximadamente el 55% del area de cobertura HFC.

Caracteristicas de la zona: Punta Alta es cabecera del Partido de Coronel Rosales, con sectores urbanos consolidados y barrios perifericos de buena dispersion poblacional. La cercania al mar y las condiciones climaticas de la region (vientos intensos, humedad y salinidad) exigen estandares tecnicos elevados en materiales, canalizaciones y estructuras de soporte. Requiere coexistencia temporal HFC/FTTH y reemplazo progresivo de infraestructura sin afectar la continuidad del servicio.

Etapas del proyecto: Etapa 1 - acopio de materiales para despliegue y migracion. Etapa 2 - migracion de asociados con cable modems sobre el sector FTTH ya construido, y despliegue de red troncal, red de distribucion de fibra al hogar y montaje de cajas NAP. Etapa 3 - fusionado de fibra, mediciones opticas, montaje y puesta en marcha de OLTs. Etapa 4 - puesta en marcha de la red y migracion de clientes HFC a FTTH en los sectores de la nueva red. El proyecto se organiza en 3 zonas geograficas (Zona 1, Zona 2 y Zona 3).

Caracteristicas tecnicas de la red proyectada: red convergente FTTH con tecnologia GPON (Red Optica Pasiva con Capacidad de Gigabit) segun normativa ITU-T G.984.1 a G.984.7, sobre infraestructura aerea por postacion propia de la Cooperativa. Sectores de 4 manzanas (con ajustes en zonas de baja densidad), diseno para 24-32 usuarios por manzana, relacion total 1:64 por salida PON de la OLT (splitters 1:8 troncal + 1:8 distribucion), con reserva de fibra en troncal y distribucion. Red troncal: cable optico monomodo FURUKAWA CFOA-SM-AS80-TS 24F G-652D NR (EXP), domos de empalme Furukawa FK-CEO-4M con splitters PLC full-spectrum 1:8. Red de distribucion: cable FURUKAWA CFOA-SM-AS80-TS 12F G-652D NR CT. Gabinetes de distribucion: cajas de terminacion optica Furukawa FK-CTO-16MT con splitters conectorizados 1:8.

Calidad tecnica de la propuesta: OLT con placas de uplink redundantes (alta disponibilidad) y soporte multiprotocolo GPON/XG-PON/XGS-PON/XGS-PON Pro (asegura la inversion a futuro, permitiendo migrar de GPON a XGS-PON sin reemplazar la planta externa). ONT con WiFi 6 AX3000 y antenas de 7 dBi, velocidades de acceso domiciliario de hasta 574 Mbit/s (2,4GHz) y 2402 Mbit/s (5GHz) - responde directamente al principal motivo de reclamos actuales (cobertura WiFi domiciliaria).

Equipamiento principal a adquirir: 2x OLT Huawei MA5800-X7/EA5800-X7 (chasis multiservicio, availability >99,999%, hasta 112 puertos GPON/XGS-PON por placa), 4x placa principal MPLB, 14x placas OLT Advanced Flex-PON 2.0, ~5000x ONT Huawei EG8145X6-10 (GPON, WiFi 6), cable optico FURUKAWA (16.000 m de 24F troncal + 52.000 m de 12F distribucion), 300.000 m de cable drop FTTH, mas morseteria completa (rack, suspension y retencion preformada, fleje, cruces de reserva) y pasivos (domos de empalme, splitters, cajas terminales opticas).

Beneficiarios: 13.500 hogares potencialmente beneficiados (dato consignado en la Carpeta Tecnica; las categorias de comercios, establecimientos educativos, salud, policia, bomberos y organismos municipales/provinciales figuran en el documento original sin completar por la Cooperativa, y el porcentaje exacto de cobertura de la localidad tampoco esta consignado - documento presentado con esos campos en blanco).

Inversion total requerida: USD 457.780,07 (equivalente a $ 650.047.693,72 al tipo de cambio de referencia $1.420/USD consignado en la Carpeta Tecnica), desglosado en: Pasivos de Red USD 100.947,68; Morseteria USD 39.576,00; Acometida Clientes USD 262.500,00; Activos de Nodo USD 54.756,39. Financiacion: linea de creditos otorgada por el Banco Nacion Argentina (en el marco de la linea ENACOM "Creditos a Tasa Subsidiada" del Programa FATIC), con el saldo a cubrir con fondos propios de la Cooperativa.

Fuente: Carpeta Tecnica, Cooperativa Electrica de Punta Alta, documento GEDO IF-2026-22344883-APN-AICPUST#ENACOM (documento adjunto en la seccion de documentos tecnicos del proyecto).$desc$,

  -- beneficiary_count: 13.500 hogares, el unico dato numerico que la
  -- Cooperativa completo en la seccion 14 de la Carpeta Tecnica (las
  -- demas categorias - comercios, educacion, salud, policia, bomberos,
  -- organismos - quedaron sin completar en el documento original).
  13500,

  'Cooperativa Electrica de Punta Alta (CEPA)',

  -- La Cooperativa opera directamente la red HFC/FTTH para sus asociados
  -- - encaja de forma directa en 'isp' de la taxonomia existente (a
  -- diferencia de CAPPI, que es una camara sectorial y no un operador).
  'isp'
);

-- Verificación: confirma que el proyecto se creó y te muestra su id.
select id, name, project_type, country, beneficiary_count, generating_entity_name, created_at
from public.projects
where name = 'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta'
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
-- 2. Abrí el proyecto "Finalización de Despliegue FTTH y Migración
--    HFC-FTTH - Cooperativa Eléctrica de Punta Alta".
-- 3. En la sección de Documentos, subí el archivo
--    "0004 - IF-2026-22344883-APN-AICPUST%ENACOM(CARPETA TECNICA).pdf" en
--    la categoría "Técnica" (technical).
--
-- El paso 3 inserta automáticamente la fila correspondiente en
-- public.project_documents con el storage_path correcto; un INSERT manual
-- por SQL no puede garantizar eso sin haber subido antes el archivo al
-- bucket.
--
-- OPCIONAL — FSU Scoring: como este proyecto es 'fiber_backbone_last_mile'
-- con tecnología GPON, es elegible para la herramienta de scoring FSU de
-- la plataforma (app/fsu-scoring.html, basada en la "Manual Estratégico de
-- Elaboración de Proyectos" de ENACOM, Res. 359/2025). El documento no trae
-- todos los datos crudos que ese formulario pide (penetración exacta de
-- fibra, modelo de negocio, velocidad actual/propuesta exacta, salto
-- tecnológico, población de la localidad, años de capacidad técnica), así
-- que no se precargó — conviene completarlo a mano desde la plataforma una
-- vez que la Cooperativa termine de llenar los campos que la Carpeta
-- Técnica dejó en blanco (ver nota al inicio de este archivo).
--
-- OPCIONAL — vincular a un Programa: si ya tenés cargado en
-- public.programs un Programa para la línea ENACOM "Créditos a Tasa
-- Subsidiada" (Programa FATIC, Res. 950/25), podés asociar este proyecto
-- con:
--
--   insert into public.project_programs (project_id, program_id, user_id)
--   select
--     (select id from public.projects where name = 'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta' order by created_at desc limit 1),
--     p.id,
--     (select id from public.profiles where email = 'TU_EMAIL_AQUI@ejemplo.com')
--   from public.programs p
--   where p.name ilike '%Tasa Subsidiada%'
--   limit 1;
--
-- Si no tenés ese Programa cargado todavía, este INSERT simplemente no
-- afecta ninguna fila (el `where` no encuentra nada) — no hace falta
-- comentarlo si preferís dejarlo listo para más adelante.
-- ============================================================================
