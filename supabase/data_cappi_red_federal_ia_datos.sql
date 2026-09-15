-- ============================================================================
-- Alta de proyecto: Red Federal de Centros Regionales de IA y Datos
-- Proponente: CAPPI — Cámara Argentina de Pequeños Proveedores de Internet
-- Propuesta institucional presentada a ENACOM, junio de 2026
-- Fuente: CAPPI-ENACOM_Red_Federal_Centros_Regionales_IA_y_Datos.pdf
--
-- CÓMO USAR ESTE ARCHIVO
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. En la línea marcada "EDITAR" más abajo, reemplazá el email por el de
--    la cuenta de la plataforma INA que va a figurar como propietaria del
--    proyecto. Tiene que ser un email que YA tenga fila en
--    public.profiles (ya registrado en app/register.html).
-- 3. Ejecutá el script completo. Al final corre un SELECT que muestra el
--    proyecto recién creado para confirmar.
-- 4. El PDF original no se puede adjuntar por SQL — ver instrucciones al
--    pie de este archivo.
--
-- POR QUÉ 'ai_datacenter' Y NO OTRA CATEGORÍA
-- El proyecto es una red de pequeños centros regionales de cómputo/IA
-- (servidor de virtualización + servidor con GPU, por nodo), desplegados
-- sobre shelters de ISP ya existentes. Encaja exactamente en el perfil
-- "Edge / Micro (PyME distribuido)" + "Red distribuida de N nodos" del
-- template de Datacenter ya existente en la plataforma (DATACENTER_TEMPLATE
-- en assets/platform.js) — por eso, además del INSERT, este script deja
-- pre-cargado projects.shared_field_answers con las respuestas de ese
-- template que sí están respaldadas por el documento. Cuando alguien abra
-- este proyecto y use "Usar template" → Template de Datacenter, el
-- formulario va a aparecer con estos campos ya completos (ver
-- autofillTemplateAnswers() en assets/platform.js), y solo faltará
-- completar lo que el documento no especifica (monto solicitado, potencia
-- exacta, CAPEX/OPEX, marco regulatorio, sustentabilidad, etc.).
-- ============================================================================

insert into public.projects (
  user_id,
  name,
  project_type,
  country,
  description,
  beneficiary_count,
  generating_entity_name,
  generating_entity_type,
  shared_field_answers
)
values (
  -- EDITAR: email de la cuenta que debe figurar como dueña del proyecto.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'Red Federal de Centros Regionales de IA y Datos',

  'ai_datacenter',

  'Argentina',

$desc$TEMPLATE DE PROYECTO DE DATACENTER

0. Datos generales del proponente y roles institucionales
- Destinatario de la presentación: ENACOM
- Organismo ejecutor / contraparte: CAPPI - Camara Argentina de Pequenos Proveedores de Internet, en conjunto con los ISP asociados que operen cada centro regional
- Roles y responsabilidades institucionales: ENACOM: acompanamiento institucional, coordinacion con organismos publicos, articulacion con programas nacionales, promocion de infraestructura digital federal y generacion de marcos de cooperacion. CAPPI: coordinacion tecnica, capacitacion, definicion de estandares, seleccion de proyectos piloto, mesa permanente de innovacion y difusion nacional. ISP asociados a CAPPI: operan cada centro regional aportando la infraestructura ya existente (shelters, cabeceras FTTH, fibra optica, energia de respaldo, personal tecnico).

1. Clasificación
- Tipo de datacenter: Edge / Micro (PyME distribuido)
- Escala del proyecto (potencia total): < 1 MW (Edge/Micro)
- Topología: Red distribuida de N nodos
- Detalle de topología (si es red distribuida): Etapa 1 - Programa Piloto: 10 ISP asociados a CAPPI, 12 meses. Etapa 2 - Expansion Regional: 50 centros regionales distribuidos, 24 meses. Etapa 3 - Consolidacion Nacional: mas de 100 centros regionales interconectados, 60 meses.
- Uso previsto / modelo de servicio: Cloud público general
- Horizonte de despliegue: Reconversión de sitio/infraestructura existente
- Segmentos de servicio / público objetivo: Municipios y comunas (ver Notas adicionales para el resto de los segmentos)

2. Sitio y terreno
- Modalidad del sitio: Infraestructura de ISP reutilizada (shelter / cabecera FTTH)
- Superficie del sitio: Entre 6 m² y 12 m² por nodo (shelter existente del ISP)

4. Refrigeración
- Tipo de refrigeración: Aire forzado (CRAC/CRAH)

5. Cómputo
- Tipo principal de cómputo: GPU
- Carga de trabajo objetivo: Inferencia (asistentes, IA como servicio)
- Especificaciones de servidores (cómputo e IA): Servidor de Virtualizacion (1 unidad): procesador de 32 a 64 nucleos, 128 GB RAM, almacenamiento SSD empresarial, fuente redundante - para VPS, aplicaciones empresariales, plataformas municipales y sistemas de gestion. Servidor de Inteligencia Artificial (1 unidad): GPU NVIDIA RTX serie profesional, 64 GB RAM o superior, SSD NVMe - para asistentes virtuales, automatizacion documental, procesamiento de lenguaje natural e IA para municipios y empresas.

6. Red y conectividad
- Ancho de banda externo contratado: Inicial: 2 Gbps simetricos dedicados. Recomendado: 5 Gbps simetricos. Escalable: hasta 10 Gbps o superior.

7. Almacenamiento
- Capacidad inicial: 20 TB a 50 TB
- Escalabilidad de almacenamiento: Hasta 100 TB o más

8. Seguridad física y nivel Tier
- Nivel Tier (Uptime Institute): No aplica a esta escala (justificar en notas)
- Controles mínimos: Control de acceso

11. Modelo de negocio y financiero
- Etapa de la propuesta: Piloto

12. Dimensionamiento y capacidad operativa estimada
- Servidores virtuales soportados (por nodo): 20 a 30 servidores virtuales, con infraestructura inicial de 2 Gbps
- Dispositivos IoT / cámaras IP soportadas: Entre 200 y 500 cámaras IP
- Clientes institucionales estimados (municipios): 5 a 10 municipios pequenos
- Clientes empresariales estimados: Más de 100 empresas
- Volumen de consultas de IA estimado: Miles de consultas mensuales (por nodo)

Notas adicionales (salvaguardas ambientales y sociales, marco de resultados/marco lógico, matriz de riesgos de 7 categorías, plan de despliegue por etapas y KPIs del piloto, checklist de documentación de respaldo, etc.)
Segmentos de servicio adicionales no capturados en el campo unico de "publico objetivo" (la propuesta apunta simultaneamente a varios): Empresas y comercios (servidores virtuales, hosting, correo corporativo, respaldo de informacion, automatizacion empresarial, asistentes inteligentes); Sector agropecuario (plataformas IoT, monitoreo ganadero, sensores rurales, estaciones meteorologicas, control de silos, gestion hidrica, telemetria); Educacion (plataformas virtuales, capacitacion digital, laboratorios tecnologicos, formacion en IA); Salud (respaldo de sistemas, gestion documental, turnos inteligentes, procesamiento administrativo).

Modelo económico: diversifica el negocio tradicional de conectividad de los ISP mediante nuevas fuentes de ingreso (cloud regional, hosting, VPS, backup empresarial, almacenamiento remoto, videovigilancia, IA como servicio, automatizacion documental, servicios para municipios, plataformas IoT, servicios para el agro).

Aprovechamiento de infraestructura existente: el modelo no requiere construir nuevos edificios - reutiliza shelters, energia de respaldo, climatizacion, fibra optica, personal tecnico, seguridad y monitoreo ya desplegados por los ISP asociados a CAPPI, concentrando la inversion en equipamiento tecnologico y software.

Impacto esperado: desarrollo de infraestructura digital federal, generacion de empleo tecnologico, fortalecimiento de ISP PyME, mayor digitalizacion de municipios, incorporacion de IA en economias regionales, menor dependencia tecnologica centralizada, nuevos modelos de negocio e impulso a la economia del conocimiento.

Nota sobre financiamiento: la propuesta no especifica un monto de inversion solicitado a ENACOM ni un instrumento financiero concreto - se presenta como una propuesta de articulacion institucional (acompanamiento, coordinacion con organismos publicos, marcos de cooperacion) y definicion de estandares tecnicos; el financiamiento del equipamiento por nodo queda a cargo de cada ISP participante, salvo que se defina en una etapa posterior un mecanismo de cofinanciamiento con ENACOM.

Fuente: PROPUESTA CAPPI-ENACOM - Proyecto Estrategico Nacional "Red Federal de Centros Regionales de IA y Datos", Camara Argentina de Pequenos Proveedores de Internet (CAPPI), junio de 2026 (documento adjunto en la seccion de documentos tecnicos del proyecto).$desc$,

  -- beneficiary_count: el documento da capacidades operativas POR NODO
  -- (5-10 municipios, +100 empresas, 200-500 cámaras IP) pero no una
  -- cifra total de beneficiarios para toda la red (que además depende de
  -- cuántos nodos se desplieguen finalmente). Queda en NULL; se puede
  -- estimar y cargar más adelante multiplicando por la cantidad de nodos
  -- de cada etapa (10 → 50 → 100+).
  null,

  'CAPPI - Camara Argentina de Pequenos Proveedores de Internet',

  -- CAPPI es una cámara/asociación de ISPs PyME, no un ISP individual, así
  -- que ninguno de los valores de la taxonomía existente (regulator /
  -- national_gov / provincial_gov / municipal_gov / isp / manufacturer /
  -- integrator / other) la describe con precisión. 'other' es el valor más
  -- correcto hoy; si en el futuro se agrega una categoría específica para
  -- "asociación/cámara sectorial" convendría migrar este valor.
  'other',

  -- Respuestas del Template de Datacenter (assets/platform.js →
  -- DATACENTER_TEMPLATE) respaldadas por el documento — ver el comentario
  -- al inicio del archivo. Solo se incluyen campos con sustento explícito
  -- en el PDF; todo lo que el documento no especifica (monto solicitado,
  -- potencia exacta en kW, CAPEX/OPEX, redundancia energética, tenencia
  -- del sitio, licencia TIC, sustentabilidad, etc.) se dejó fuera a
  -- propósito para no inventar datos — quien complete el template desde la
  -- plataforma va a ver esos campos vacíos, listos para completar.
$$
{
  "destinatario_presentacion": "enacom",
  "organismo_ejecutor": "CAPPI - Camara Argentina de Pequenos Proveedores de Internet, en conjunto con los ISP asociados que operen cada centro regional",
  "roles_institucionales": "ENACOM: acompanamiento institucional, coordinacion con organismos publicos, articulacion con programas nacionales, promocion de infraestructura digital federal y generacion de marcos de cooperacion. CAPPI: coordinacion tecnica, capacitacion, definicion de estandares, seleccion de proyectos piloto, mesa permanente de innovacion y difusion nacional. ISP asociados a CAPPI: operan cada centro regional aportando la infraestructura ya existente (shelters, cabeceras FTTH, fibra optica, energia de respaldo, personal tecnico).",
  "tipo_datacenter": "edge_micro",
  "escala_potencia": "lt_1mw",
  "topologia": "red_distribuida",
  "topologia_detalle": "Etapa 1 - Programa Piloto: 10 ISP asociados a CAPPI, 12 meses. Etapa 2 - Expansion Regional: 50 centros regionales distribuidos, 24 meses. Etapa 3 - Consolidacion Nacional: mas de 100 centros regionales interconectados, 60 meses.",
  "uso_servicio": "cloud_publico",
  "horizonte_despliegue": "reconversion",
  "segmento_servicio": "municipios_comunas",
  "modalidad_sitio": "infra_isp",
  "superficie_sitio": "Entre 6 m2 y 12 m2 por nodo (shelter existente del ISP)",
  "tipo_refrigeracion": "aire_forzado",
  "tipo_computo": "gpu",
  "carga_trabajo": "inferencia",
  "especificaciones_servidores": "Servidor de Virtualizacion (1 unidad): procesador de 32 a 64 nucleos, 128 GB RAM, almacenamiento SSD empresarial, fuente redundante - para VPS, aplicaciones empresariales, plataformas municipales y sistemas de gestion. Servidor de Inteligencia Artificial (1 unidad): GPU NVIDIA RTX serie profesional, 64 GB RAM o superior, SSD NVMe - para asistentes virtuales, automatizacion documental, procesamiento de lenguaje natural e IA para municipios y empresas.",
  "ancho_banda_externo": "Inicial: 2 Gbps simetricos dedicados. Recomendado: 5 Gbps simetricos. Escalable: hasta 10 Gbps o superior.",
  "capacidad_inicial_almacenamiento": "20 TB a 50 TB",
  "escalabilidad_almacenamiento": "Hasta 100 TB o mas",
  "nivel_tier": "no_aplica",
  "controles_minimos": "Control de acceso",
  "etapa_propuesta": "piloto",
  "servidores_virtuales_nodo": "20 a 30 servidores virtuales (con infraestructura inicial de 2 Gbps)",
  "dispositivos_iot_soportados": "Entre 200 y 500 camaras IP",
  "clientes_institucionales_estimados": "5 a 10 municipios pequenos",
  "clientes_empresariales_estimados": "Mas de 100 empresas",
  "volumen_consultas_ia_estimado": "Miles de consultas mensuales (por nodo)",
  "notas_adicionales": "Segmentos de servicio adicionales no capturados en el campo unico de publico objetivo: Empresas y comercios, Sector agropecuario, Educacion, Salud (ver descripcion completa del proyecto). Fuente: PROPUESTA CAPPI-ENACOM, Red Federal de Centros Regionales de IA y Datos, junio de 2026."
}
$$::jsonb
);

-- Verificación: confirma que el proyecto se creó y te muestra su id.
select id, name, project_type, country, generating_entity_name, created_at
from public.projects
where name = 'Red Federal de Centros Regionales de IA y Datos'
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
-- 2. Abrí el proyecto "Red Federal de Centros Regionales de IA y Datos".
-- 3. En la sección de Documentos, subí el archivo
--    "CAPPI-ENACOM_Red_Federal_Centros_Regionales_IA_y_Datos.pdf" en la
--    categoría "Técnica" (technical).
-- 4. Opcional pero recomendado: desde la sección de Templates del
--    proyecto, abrí "Usar template" → Template de Datacenter. Vas a ver
--    los campos de arriba ya precargados (gracias a shared_field_answers)
--    — completá ahí lo que falta (monto solicitado, potencia en kW/MW,
--    CAPEX/OPEX, licencia TIC, sustentabilidad, etc.) antes de presentarlo
--    formalmente.
--
-- El paso 3 inserta automáticamente la fila correspondiente en
-- public.project_documents con el storage_path correcto; un INSERT manual
-- por SQL no puede garantizar eso sin haber subido antes el archivo al
-- bucket.
-- ============================================================================
