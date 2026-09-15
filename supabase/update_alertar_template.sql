-- ============================================================================
-- Completar el Template de Sistema de Alerta Temprana (AlertAR)
-- para un proyecto "Sistema de Alerta Temprana - AlertAR" YA EXISTENTE
-- Fuente: PLIEG-2026-63921688-APN-DNIERYSTIYC%ENACOM.pdf
-- ============================================================================
--
-- DIFERENCIA CON supabase/data_alertar.sql
-- data_alertar.sql crea el proyecto desde cero (INSERT). Este script en
-- cambio hace lo que hace la app cuando completás el Template de Sistema
-- de Alerta Temprana desde app/project-template.html sobre un proyecto
-- que YA existe (haya sido creado por SQL o a mano desde la plataforma):
--   1. Mezcla (merge) las respuestas del template en projects.
--      shared_field_answers, igual que INAPlatform.mergeSharedFieldAnswers()
--      — solo agrega/actualiza claves, nunca borra datos que ya estuvieran
--      cargados por otro template.
--   2. Reemplaza projects.description por el texto compilado del template
--      (mismo formato exacto que genera INAPlatform.compileTemplateAnswers():
--      título en mayúsculas, subtítulos por sección, líneas "- Etiqueta:
--      valor"), igual que cuando guardás el formulario y volvés a
--      new-project.html con la descripción ya compilada.
--
-- USAR ESTE SCRIPT SI...
-- ...el proyecto "Sistema de Alerta Temprana - AlertAR" ya existe en tu
-- base (lo creaste desde la plataforma, o ya corriste data_alertar.sql) y
-- lo que necesitás es (re)completar el template con estos datos.
-- Si el proyecto TODAVÍA NO existe, corré supabase/data_alertar.sql en su
-- lugar — ya inserta el proyecto con esta misma información.
--
-- CÓMO USAR
-- 1. EDITAR el email de la cuenta dueña del proyecto si no es
--    'pcymeryng@gmail.com'.
-- 2. Ejecutá el script completo. Al final corre un SELECT de verificación
--    mostrando el nuevo shared_field_answers y description.
-- ============================================================================

update public.projects
set
  shared_field_answers = coalesce(shared_field_answers, '{}'::jsonb) || $$
{
  "organismo_ejecutor": "ENACOM (organismo contratante de la licitacion llave en mano); sistema entregado en propiedad al Ministerio de Seguridad Nacional para uso del SINAGIR",
  "roles_institucionales": "ENACOM: organismo contratante y regulador, emisor del pliego. MINISTERIO DE SEGURIDAD NACIONAL / SINAGIR: destinatario final de la propiedad del sistema y usuario operativo. AMX Argentina S.A. (Claro), Telefonica Moviles Argentina S.A. (Movistar) y Telecom Argentina S.A. (Personal): los tres PRESTADORES de telefonia movil, cada uno con dos CBC propios. Adjudicatario: proveedor unico llave en mano de los 4 renglones, a cargo de implementacion y soporte por 36 meses.",
  "riesgos_cubiertos": "Riesgos naturales (sismos, tsunamis, lluvias intensas y otros eventos meteorologicos extremos), alertas de seguridad publica, personas desaparecidas, ordenes de evacuacion y mensajes gubernamentales de emergencia de interes general.",
  "zona_geografica_cobertura": "Todo el territorio de la Republica Argentina, segun la cobertura de red movil de los tres PRESTADORES (AMX Argentina S.A., Telefonica Moviles Argentina S.A. y Telecom Argentina S.A.)",
  "poblacion_beneficiada_estimada": "No especificada como cifra puntual en el pliego; alcanza en principio a toda la poblacion con cobertura de red movil de los tres PRESTADORES a nivel nacional (CBS no requiere suscripcion previa).",
  "fuente_deteccion_alerta": "combinacion",
  "canal_difusion_principal": "cell_broadcast",
  "estandar_tecnico": "cbs_3gpp",
  "operadores_moviles_involucrados": "AMX Argentina S.A. (Claro), Telefonica Moviles Argentina S.A. (Movistar) y Telecom Argentina S.A. (Personal) - cada uno con dos CBC en ubicaciones geograficas distintas dentro del territorio nacional.",
  "cobertura_dispositivos": "universal",
  "idiomas_soportados": "Multiples idiomas, segun configuracion del dispositivo receptor (sin lista cerrada en el pliego)",
  "arquitectura_propuesta": "CBE central del Gobierno con redundancia local y geografica (segundo CBE fuera del territorio nacional); HUB de mediacion basado en CAP 1.2 entre el CBE y los CBC de cada PRESTADOR; mensaje CAP enviado del CBE al CBC via HTTP/HTTPS cliente-servidor; el CBC distribuye el mensaje via el core de red (AMF/MME/RNC/BSC) a las celdas del area afectada; asistencia de IA local/privativa para redaccion de mensajes con aprobacion humana obligatoria previa al envio.",
  "integracion_sistemas_existentes": "La interfaz del CBE debe poder embeberse en los sistemas existentes del SINAGIR.",
  "redundancia_resiliencia": "Dos niveles de redundancia del CBE (local y geografica, segundo CBE fuera del territorio nacional, conmutacion automatica o manual); cada PRESTADOR con dos CBC en ubicaciones distintas con conmutacion automatica al CBC de respaldo; almacenamiento redundante minimo 2TB por servidor (RAID o equivalente); conectividad de red nivel 2 con conmutadores redundantes.",
  "marco_normativo_aplicable": "Resolucion RESOL-2018-51-APN-SGM#JGM de ENACOM (Plan Nacional de Contingencia, Anexo I punto 6.3). Proyecto especifico IF-2025-117577290-APN-DNPYD#ENACOM, aprobado por Resolucion RESOL-2025-1387-APN-ENACOM#JGM del 18/11/2025. Convenios antecedentes: CONVE-2025-133062984-APN-MSG, IF-2025-135142880-APN-SRI#ENACOM, IF-2025-135142235-APN-SRI#ENACOM, IF-2025-135141617-APN-SRI#ENACOM, IF-2025-135140231-APN-SRI#ENACOM.",
  "autorizacion_espectro": "no_aplica",
  "acuerdos_institucionales_necesarios": "Ratificacion tecnica de los PRESTADORES y el SINAGIR sobre compatibilidad y funcionalidad con sus sistemas existentes (apartado 7.2.2 del proyecto IF-2025-117577290-APN-DNPYD#ENACOM). Vinculos de red entre nodos redundantes del CBE a definir por ENACOM/SINAGIR durante la implementacion.",
  "responsable_operacion_sistema": "Ministerio de Seguridad Nacional / SINAGIR (propiedad y uso); adjudicatario (actualizacion, mantenimiento y soporte tecnico durante 36 meses posteriores a la puesta en marcha)",
  "plan_pruebas_periodicas": "Ultimos 60 dias de los 12 meses de plazo de implementacion destinados a pruebas con el Ministerio de Seguridad Nacional y la totalidad de los PRESTADORES; entornos de pruebas de campo dedicados para el CBE y cada CBC, con posibilidad de entorno de pruebas conjunto.",
  "modelo_sostenibilidad": "Servicios de actualizacion, mantenimiento, capacitacion, soporte tecnico (mesa de ayuda 7x24x365) y servicios administrados por 36 meses a cargo del adjudicatario; garantia minima de hardware y software de 36 meses; penalidades por incumplimiento de TMA (0,1%/0,05%) y TMR (1%/0,5%) de incidencias criticas/no criticas.",
  "notas_adicionales": "Licitacion llave en mano, adjudicacion global a un unico adjudicatario para 4 renglones (CBE+licencias; 3x CBC+licencias; implementacion/capacitacion; mantenimiento y soporte 36 meses). Evaluacion por comite con requisitos tecnicos excluyentes. Certificaciones de seguridad Common Criteria EAL4+ o equivalente; retencion de registros 3 anios; EOL de equipos no inferior a 48 meses desde la instalacion."
}
$$::jsonb,

  description = $desc$TEMPLATE DE PROYECTO DE SISTEMA DE ALERTA TEMPRANA

0. Datos generales del proponente y roles institucionales
- Organismo ejecutor / contraparte: ENACOM (organismo contratante de la licitación llave en mano). El sistema resultante se entrega en propiedad al MINISTERIO DE SEGURIDAD NACIONAL para su uso por el Sistema Nacional para la Gestion Integral del Riesgo (SINAGIR) o la entidad que en el futuro lo reemplace.
- Roles y responsabilidades institucionales: ENACOM - organismo contratante y regulador, emisor del pliego, responsable de definir la ubicacion del CBE principal y coordinar junto al SINAGIR los vinculos de red entre nodos redundantes. MINISTERIO DE SEGURIDAD NACIONAL / SINAGIR - destinatario final de la propiedad del sistema, usuario operativo, responsable del control de acceso fisico al CBE en su ubicacion. AMX Argentina S.A. (Claro), Telefonica Moviles Argentina S.A. (Movistar) y Telecom Argentina S.A. (Personal) - los tres PRESTADORES de telefonia movil, cada uno con dos Cell Broadcast Center (CBC) propios en ubicaciones geograficas distintas, responsables de distribuir las alertas a su infraestructura de red movil. Adjudicatario - proveedor unico de la solucion llave en mano (los CUATRO renglones), responsable de la implementacion, puesta en marcha, capacitacion y de los servicios de actualizacion, mantenimiento y soporte tecnico por 36 meses posteriores.

1. Alcance de riesgos y cobertura
- Tipos de riesgo cubiertos: riesgos naturales (sismos, tsunamis, lluvias intensas y otros eventos meteorologicos extremos), alertas de seguridad publica, alertas por personas desaparecidas, ordenes de evacuacion y mensajes gubernamentales de emergencia de interes general - clasificables dentro del CBE por tipo de evento (meteorologico, sanitario, seguridad, evacuacion, etc.) y nivel de severidad (severo, extremo, informativo).
- Zona geografica de cobertura: todo el territorio de la Republica Argentina, segun el area de cobertura de red movil de los tres PRESTADORES (AMX Argentina S.A., Telefonica Moviles Argentina S.A. y Telecom Argentina S.A.).
- Poblacion beneficiada estimada: el pliego no especifica una cifra puntual; alcanza en principio a la totalidad de la poblacion con cobertura de red movil de los tres PRESTADORES a nivel nacional, dado que el CBS no requiere suscripcion previa del usuario para recibir el mensaje.
- Fuente de deteccion/disparo de la alerta: combinacion de varias fuentes - el CBE brinda acceso multientidad a distintos organismos gubernamentales (Defensa Civil, seguridad publica, salud, meteorologia), cada uno actuando dentro de su competencia, bajo supervision y aprobacion centralizada del Estado.

2. Tecnologia y canales de difusion de la alerta
- Canal de difusion principal: Cell Broadcast (SMS-CB) - el pliego limita expresamente el alcance de esta especificacion tecnica al sistema de alerta temprana basado en CBS (Cell Broadcast Service), aunque menciona otras tecnologias de PWS (apps, redes sociales, radio/TV, DVB/ISDB, IoT, Galileo/EU-Alert) como parte del panorama general.
- Estandar tecnico: Cell Broadcast Service (CBS) 3GPP para la difusion, con el mensaje de alerta generado y formateado segun el estandar CAP 1.2 (Common Alerting Protocol) en su adaptacion al marco argentino, tanto para la comunicacion CBE-CBC como para una eventual capa de mediacion/HUB multicanal.
- Operadores moviles que se preve que participen: AMX Argentina S.A. (Claro), Telefonica Moviles Argentina S.A. (Movistar) y Telecom Argentina S.A. (Personal) - los tres PRESTADORES de telefonia movil con licencia en Argentina, cada uno con dos CBC en ubicaciones geograficas distintas dentro del territorio nacional.
- Cobertura de dispositivos: universal - todos los dispositivos moviles compatibles con CBS en la zona definida reciben el mensaje automaticamente, sin necesidad de suscripcion previa ni instalacion de aplicacion.
- Idiomas soportados: multiples idiomas, segun la configuracion de idioma del dispositivo receptor (el pliego no fija una lista cerrada de idiomas).

3. Arquitectura tecnica e integracion
- Arquitectura de sistema propuesta: Cell Broadcast Entity (CBE) central gestionado por el Gobierno, con dos niveles de redundancia (local y geografica) - incluyendo un segundo CBE en una ubicacion geografica diferente del territorio nacional, con conmutacion automatica o manual ante inoperatividad del equipo principal. Una capa de mediacion/HUB basada en CAP 1.2 conecta el CBE con los Cell Broadcast Center (CBC) de cada PRESTADOR, permitiendo integracion de multiples emisores/canales de alerta y desacoplamiento/orquestacion de APIs; este HUB se considera parte del CBE y es transparente para el operador movil. El mensaje CAP se envia del CBE al CBC via peticion HTTP/HTTPS en modo cliente-servidor; el CBC lo interpreta y distribuye via el core de red del operador (AMF en 5G, MME en 4G, RNC/BSC en tecnologias anteriores) a las celdas del area geografica afectada. El sistema debe ofrecer asistencia de inteligencia artificial para sugerir la redaccion de mensajes de alerta (segun tipo de evento, severidad, audiencia e idioma), ejecutada de forma local y privativa dentro del entorno del CBE -sin exponer datos a servicios publicos de IA generativa- y con revision y aprobacion humana obligatoria antes de cualquier envio.
- Integracion con sistemas nacionales de alerta existentes: la interfaz del CBE debe poder embeberse en los sistemas existentes del SINAGIR.
- Tiempo objetivo de difusion (disparo a broadcast): no se especifica un tiempo objetivo puntual en segundos/minutos en el pliego (los unicos indicadores temporales definidos son de soporte tecnico: Tiempo Maximo de Atencion y Tiempo Maximo de Resolucion de incidencias, no de difusion de la alerta en si).
- Plan de redundancia y resiliencia: dos niveles de redundancia del CBE (local y geografica, con segundo CBE fuera del territorio nacional); cada PRESTADOR con dos CBC en ubicaciones geograficas distintas, con conmutacion automatica al CBC de respaldo ante fallas, sin interrupcion del servicio; almacenamiento redundante de al menos 2 TB por servidor (cabinas de discos en configuracion RAID o equivalente) y conectividad de red de nivel 2 con conmutadores redundantes.

4. Marco regulatorio e institucional
- Marco normativo aplicable: Resolucion RESOL-2018-51-APN-SGM#JGM de ENACOM (2018), que reglamenta el Plan Nacional de Contingencia y en su Anexo I, punto 6.3, obliga a los prestadores del Servicio de Comunicaciones Moviles (SCM) a disponer de los medios para emitir mensajes de multidifusion ante una alerta o emergencia declarada, segun lo solicite la Secretaria de Proteccion Civil y Abordaje Integral de Emergencias y Catastrofes. El proyecto especifico que da origen a esta licitacion es IF-2025-117577290-APN-DNPYD#ENACOM, aprobado por Resolucion RESOL-2025-1387-APN-ENACOM#JGM del 18 de noviembre de 2025, con los convenios antecedentes CONVE-2025-133062984-APN-MSG, IF-2025-135142880-APN-SRI#ENACOM, IF-2025-135142235-APN-SRI#ENACOM, IF-2025-135141617-APN-SRI#ENACOM e IF-2025-135140231-APN-SRI#ENACOM.
- Autorizacion de espectro: no aplica - el sistema opera sobre las redes moviles y el espectro ya licenciado de los tres PRESTADORES existentes, sin requerir una nueva asignacion de espectro segun el pliego.
- Convenios institucionales necesarios: la propuesta tecnica seleccionada se somete a ratificacion tecnica de los PRESTADORES y del SINAGIR, para dejar constancia de que resulta compatible y funcional con los sistemas e infraestructura que estos poseen (conforme apartado 7.2.2 del proyecto especifico IF-2025-117577290-APN-DNPYD#ENACOM). Los vinculos de red dedicados entre los nodos redundantes del CBE seran definidos por ENACOM/SINAGIR durante la implementacion.
- Entidad responsable de la operacion/mantenimiento continuo: el sistema se entrega en propiedad al MINISTERIO DE SEGURIDAD NACIONAL para uso del SINAGIR; durante los 36 meses posteriores a la puesta en marcha, el adjudicatario presta los servicios de actualizacion, mantenimiento, soporte tecnico y servicios administrados.

5. Pruebas, concientizacion publica y sostenibilidad
- Plan de pruebas periodicas: de los 12 meses totales de plazo de implementacion (a contar desde el mes siguiente al perfeccionamiento de la orden de compra), los ultimos 60 dias corresponden a un periodo de pruebas con el MINISTERIO DE SEGURIDAD NACIONAL y la totalidad de los PRESTADORES. Tanto el CBE como cada CBC deben contar con su propio entorno de pruebas de campo, con posibilidad de un entorno de pruebas conjunto CBE+CBC.
- Campana de concientizacion publica: no se describe una campana de concientizacion publica especifica en las secciones del pliego relevadas.
- Modelo de sostenibilidad financiera/operativa post-implementacion: servicios de actualizacion, mantenimiento, capacitacion, soporte tecnico (mesa de ayuda 7x24x365) y servicios administrados de sistemas y gestion de proyecto por 36 meses posteriores a la puesta en marcha, a cargo del adjudicatario. Garantia minima de hardware y software de 36 meses desde la aceptacion de las pruebas. Penalidades economicas por incumplimiento del Tiempo Maximo de Atencion (TMA, 8 horas corridas) y del Tiempo Maximo de Resolucion (TMR) de incidencias criticas y no criticas: 0,1% (TMA critica), 0,05% (TMA no critica), 1% (TMR critica) y 0,5% (TMR no critica) del valor mensual del servicio por cada incumplimiento.

Notas adicionales
Modalidad de contratacion: licitacion "llave en mano" con adjudicacion global a un unico adjudicatario para los CUATRO renglones. Renglon 1: provision de la Plataforma CBE (Cell Broadcast Entity) y entrega de licencias (1 unidad). Renglon 2: provision de Plataformas CBC (Cell Broadcast Center) y entrega de licencias (3 unidades, una por PRESTADOR). Renglon 3: servicio de implementacion, instalacion, configuracion, puesta en marcha y funcionamiento, capacitacion y transferencia de conocimientos (1 servicio). Renglon 4: servicio de actualizacion, mantenimiento y soporte tecnico, servicios administrados de sistemas y gestion de proyecto, y activacion de las licencias de uso (36 meses). Evaluacion de ofertas a cargo de un comite de evaluacion, con requisitos tecnicos excluyentes (el incumplimiento de cualquier item excluyente desestima automaticamente la oferta) y orden de merito tecnico-economico. El equipamiento del CBE debe contar con certificaciones de seguridad robustas (Common Criteria EAL4+ o equivalente) y tiempo de guarda/retencion de registros de 3 anios. La fecha de fin de vida util (EOL) de los equipos ofertados no debe ser inferior a 48 meses desde la instalacion.

Fuente: "Pliego de Especificaciones Tecnicas" - Licitacion PLIEG-2026-63921688-APN-DNIERYSTIYC#ENACOM (documento adjunto en la seccion de documentos tecnicos del proyecto).$desc$,

  updated_at = now()

where name = 'Sistema de Alerta Temprana - AlertAR'
  -- EDITAR: email de la cuenta dueña del proyecto, si no es esta.
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ============================================================================
-- Verificación
-- ============================================================================
select
  id,
  name,
  project_type,
  jsonb_object_keys(shared_field_answers) as answered_field
from public.projects
where name = 'Sistema de Alerta Temprana - AlertAR'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')
order by answered_field;

select id, name, left(description, 200) as description_preview, updated_at
from public.projects
where name = 'Sistema de Alerta Temprana - AlertAR'
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ============================================================================
-- NOTA
-- Si esta UPDATE no afecta ninguna fila, es porque el proyecto todavía no
-- existe con ese nombre + dueño — corré primero supabase/data_alertar.sql
-- (o creá el proyecto manualmente desde app/new-project.html) y después
-- volvé a correr este script.
-- ============================================================================
