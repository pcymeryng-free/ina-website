-- ============================================================================
-- Roadmap: "Elaboración de Especificaciones Técnicas (ET)" para el
-- proyecto "Sistema de Alerta Temprana - AlertAR"
-- Fuente: Pasos para la ET.pdf
--
-- QUE CARGA ESTE SCRIPT
-- El documento narra, en 5 pasos secuenciales, el proceso administrativo
-- que ENACOM ya recorrió para llegar al Pliego de Especificaciones
-- Técnicas de AlertAR (PLIEG-2026-63921688) que ya está cargado en la
-- plataforma. Encaja exactamente en el sistema de "Hojas de ruta"
-- (Roadmaps) de la plataforma: un roadmap_template reutilizable (checklist
-- con nombre, pasos, entidad responsable de cada paso) instanciado como un
-- roadmap_instance sobre este proyecto puntual.
--
-- Como el proceso que describe el documento YA CONCLUYÓ (culmina con el
-- pliego remitido a licitación e incorporado al Plan Anual de
-- Contrataciones 2026), los 5 pasos se cargan con status='completed' y el
-- roadmap_instance con status='completed' — exactamente el mismo estado
-- final que produce INAPlatform.advanceRoadmapInstanceStep() cuando el
-- usuario completa el último paso desde la UI.
--
-- El template queda reutilizable (scoped a project_type=
-- 'early_warning_system', allowed_entity_type='regulator') por si en el
-- futuro ENACOM elabora las ET de otro sistema de alerta temprana y
-- quiere instanciar el mismo checklist desde cero (en ese caso quedaría
-- en 'in_progress' en vez de 'completed').
--
-- DATO NUEVO QUE APORTA ESTE DOCUMENTO (no estaba en el pliego)
-- El paso 5 menciona una estimación presupuestaria de 12.000 millones de
-- pesos (basada en presupuestos de mercado previos) — el pliego en sí no
-- publica presupuesto. Si querés, puedo generar por separado un UPDATE
-- que cargue esto en shared_field_answers.monto_total_solicitado del
-- proyecto AlertAR (quedó vacío en el template por esta misma razón). No
-- lo hago acá para no mezclarlo con la carga del roadmap.
--
-- CÓMO USAR
-- 1. EDITAR el email de la cuenta si no es 'pcymeryng@gmail.com'. Tiene
--    que tener rol advisor/admin en public.profiles para que la UI le
--    muestre este roadmap_template en app/roadmap-templates.html (correr
--    esto desde el SQL Editor de Supabase igual funciona sin importar el
--    rol, porque el Editor corre con privilegios elevados y no pasa por
--    RLS).
-- 2. El proyecto "Sistema de Alerta Temprana - AlertAR" tiene que existir
--    ya (data_alertar.sql).
-- 3. Ejecutá el script completo. Al final corre un SELECT de verificación.
-- ============================================================================

with new_template as (
  insert into public.roadmap_templates (user_id, project_type, name, description, allowed_entity_type)
  values (
    (select id from public.profiles where email = 'pcymeryng@gmail.com'),
    'early_warning_system',
    'Elaboración de Especificaciones Técnicas (ET) - Sistema de Alerta Temprana',
    'Checklist administrativo/regulatorio que documenta el proceso seguido por ENACOM para elaborar el Pliego de Especificaciones Técnicas de un sistema de alerta temprana, desde la definición del estándar tecnológico hasta la remisión de las actuaciones para licitación. Basado en el proceso real seguido para AlertAR (PLIEG-2026-63921688). Fuente: "Pasos para la ET.pdf".',
    'regulator'
  )
  returning id
),
step_data (step_order, title, description, entity_name, entity_type, involved_entities, expected_result) as (
  values
    (
      0,
      'Fundamento normativo y definición de tecnología',
      'Mediante la Resolución ENACOM N° 960/2025 se determinó oficialmente la tecnología Cell Broadcast (CB) como el estándar nacional para los sistemas de alerta temprana basados en telefonía móvil, fundado en su alta eficacia, nulo requerimiento de suscripción del usuario y su capacidad de operar sin congestionar las redes móviles.',
      'ENACOM',
      'public',
      array[]::text[],
      'Tecnología Cell Broadcast (CB) definida oficialmente como estándar nacional para sistemas de alerta temprana vía telefonía móvil (Resolución ENACOM N° 960/2025).'
    ),
    (
      1,
      'Instrucción para el inicio de actuaciones',
      'Tras la aprobación del proyecto específico AlertAR mediante la Resolución ENACOM N° 1387/2025, la intervención del organismo instruyó formalmente el inicio de las contrataciones. La Dirección Nacional de Planificación y Desarrollo (DNPYD) solicitó formalmente a la Dirección Nacional de Ingeniería del Espectro Radioeléctrico y Servicios de TIC (DNIERYSTIYC) la confección de las especificaciones técnicas, con el objetivo de definir los requisitos de una solución llave en mano que permitiera salvaguardar la integridad de los habitantes ante emergencias y catástrofes.',
      'Dirección Nacional de Planificación y Desarrollo (DNPYD)',
      'public',
      array['Dirección Nacional de Ingeniería del Espectro Radioeléctrico y Servicios de TIC (DNIERYSTIYC)']::text[],
      'Solicitud formal de la DNPYD a la DNIERYSTIYC para confeccionar las especificaciones técnicas de una solución llave en mano (Resolución ENACOM N° 1387/2025).'
    ),
    (
      2,
      'Elaboración de las Especificaciones Técnicas (DNIERYSTIYC)',
      'La DNIERYSTIYC desarrolló el pliego técnico (PLIEG-2026-63921688) basándose en estándares internacionales (3GPP, ETSI y GSMA) para asegurar compatibilidad con redes 2G/3G/4G/5G; definió la arquitectura del sistema (plataforma central de gestión para el gobierno - CBE - y centros de difusión por operador móvil - CBC); especificó un esquema de redundancia local y geográfica activo-activo tanto para el CBE como para los CBC; e incluyó requisitos de seguridad y trazabilidad (bastionado, comunicaciones seguras vía TLS v1.2+, y registro detallado de actividades para auditoría).',
      'Dirección Nacional de Ingeniería del Espectro Radioeléctrico y Servicios de TIC (DNIERYSTIYC)',
      'public',
      array[]::text[],
      'Pliego de Especificaciones Técnicas (PLIEG-2026-63921688) elaborado, cubriendo estándares internacionales, arquitectura CBE/CBC, redundancia activo-activo y seguridad/trazabilidad.'
    ),
    (
      3,
      'Intervención y dictamen de la ONTI',
      'Antes de su aprobación definitiva, el proyecto fue sometido a la evaluación de la Oficina Nacional de Tecnologías de Información (ONTI), que analizó la Descripción Técnica del Proyecto (DTP) y el requerimiento tecnológico propuesto. El dictamen sugirió precisiones sobre el carácter abierto de la licitación, la terminología sobre servicios de inteligencia artificial de terceros y el régimen de licenciamiento de software. La DNIERYSTIYC tomó nota de estos comentarios para la versión final de las especificaciones, asegurando la robustez del pliego.',
      'Oficina Nacional de Tecnologías de Información (ONTI)',
      'public',
      array['Dirección Nacional de Ingeniería del Espectro Radioeléctrico y Servicios de TIC (DNIERYSTIYC)']::text[],
      'Dictamen de la ONTI emitido, con recomendaciones sobre el carácter abierto de la licitación, la terminología de IA de terceros y el licenciamiento de software, incorporadas a la versión final del pliego.'
    ),
    (
      4,
      'Finalización y remisión para licitación',
      'Una vez consolidadas las ET y con el visto bueno técnico, se determinó una estimación presupuestaria de 12.000 millones de pesos, basada en presupuestos de mercado previos. La DNPYD remitió las actuaciones a la Dirección General de Administración (DGA) para que arbitrara las medidas de adquisición de los bienes y servicios detallados en el pliego. El requerimiento fue incorporado en el Plan Anual de Contrataciones 2026 bajo el proyecto número 32, Sistema de Alerta Pública Temprana.',
      'Dirección Nacional de Planificación y Desarrollo (DNPYD)',
      'public',
      array['Dirección General de Administración (DGA)']::text[],
      'Actuaciones remitidas a la DGA; requerimiento incorporado al Plan Anual de Contrataciones 2026 (proyecto N° 32); estimación presupuestaria de $12.000 millones de pesos determinada; pliego consolidado y remitido para licitación.'
    )
),
new_steps as (
  insert into public.roadmap_template_steps (
    template_id, step_order, title, description, entity_name, entity_type, required, expected_result, involved_entities
  )
  select nt.id, sd.step_order, sd.title, sd.description, sd.entity_name, sd.entity_type, true, sd.expected_result, sd.involved_entities
  from new_template nt cross join step_data sd
  returning id, step_order, title, description, expected_result, entity_name, entity_type, involved_entities
),
new_instance as (
  insert into public.roadmap_instances (
    project_id, template_id, name, performing_entity_name, performing_entity_type, current_step_index, status, created_by
  )
  select
    (select id from public.projects
       where name = 'Sistema de Alerta Temprana - AlertAR'
         and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')),
    (select id from new_template),
    'Elaboración de ET - AlertAR',
    'ENACOM',
    'regulator',
    5,
    'completed',
    (select id from public.profiles where email = 'pcymeryng@gmail.com')
  returning id
)
insert into public.roadmap_instance_steps (
  instance_id, template_step_id, step_order, title, description, expected_result,
  entity_name, entity_type, involved_entities, required, status, completed_at, completed_by
)
select
  ni.id, ns.id, ns.step_order, ns.title, ns.description, ns.expected_result,
  ns.entity_name, ns.entity_type, ns.involved_entities, true, 'completed', now(),
  (select id from public.profiles where email = 'pcymeryng@gmail.com')
from new_instance ni cross join new_steps ns
order by ns.step_order;

-- ============================================================================
-- Verificación
-- ============================================================================
select
  ri.name as roadmap_name,
  ri.performing_entity_name,
  ri.status as roadmap_status,
  ris.step_order,
  ris.title as step_title,
  ris.status as step_status,
  ris.entity_name as step_responsible
from public.roadmap_instances ri
join public.roadmap_instance_steps ris on ris.instance_id = ri.id
join public.projects p on p.id = ri.project_id
where p.name = 'Sistema de Alerta Temprana - AlertAR'
  and p.user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')
order by ris.step_order;
