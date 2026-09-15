-- ============================================================================
-- Alta de proyecto: Proyecto Cruce Transandino (Andean Crossing Project)
-- Sponsor: Cirion Technologies — Propuesta presentada a ENACOM, junio 2026
-- Fuente: Proyecto_Cruce_Transandino_Propuesta_ENACOM_2026 FLV v2.pdf
--
-- CÓMO USAR ESTE ARCHIVO
-- 1. Abrí tu proyecto Supabase → SQL Editor → New query.
-- 2. En la línea marcada "EDITAR" más abajo, reemplazá el email por el de
--    la cuenta de la plataforma INA que va a figurar como propietaria del
--    proyecto (cualquier usuario ya registrado — vos mismo, o el usuario
--    que corresponda a Cirion/ENACOM si ya tiene cuenta creada).
-- 3. Ejecutá el script completo. Al final corre un SELECT que te muestra
--    el proyecto recién creado (con su id) para confirmar.
-- 4. El PDF original NO se puede adjuntar por SQL (los documentos viven en
--    Supabase Storage, no en esta tabla) — ver las instrucciones al pie de
--    este archivo para subirlo desde la plataforma en dos minutos.
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
  -- EDITAR: reemplazar por el email de la cuenta que debe figurar como
  -- dueña del proyecto en la plataforma. Tiene que ser un email que YA
  -- tenga una fila en public.profiles (es decir, ya se registró en
  -- app/register.html). Si no existe todavía, hay que crear la cuenta
  -- primero y después correr este script.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'Proyecto Cruce Transandino (Andean Crossing Project)',

  -- Ruta de fibra óptica terrestre backbone que atraviesa 21 tramos y más
  -- de 20 localidades del interior — encaja en la categoría existente
  -- 'fiber_backbone_last_mile' (Backbone de Fibra / Última Milla), la
  -- misma que usan los proyectos de tendido troncal ya cargados en la
  -- plataforma. No es 'submarine_cable' (es 100% terrestre) ni
  -- 'wholesale_neutral_network' (el modelo de negocio mayorista es un
  -- beneficio derivado, no el objeto central del proyecto).
  'fiber_backbone_last_mile',

  'Argentina',

$desc$Proyecto Cruce Transandino (Andean Crossing Project): nueva ruta de fibra óptica terrestre subterránea de alta capacidad entre Las Toninas (Provincia de Buenos Aires, Argentina) y Santiago de Chile, atravesando la Cordillera de los Andes. Presentado por Cirion Technologies ante ENACOM en junio de 2026 (documento confidencial v1.0).

Longitud total aproximada de 2.300 km, de los cuales cerca de 1.170 km corresponden a nueva infraestructura en territorio argentino, distribuida en 21 tramos que siguen las zonas de camino de rutas nacionales y provinciales (RN 226, RN 188, RN 143, RN 144, RN 40, RP 11, RP 145, entre otras) desde Las Toninas hasta el paso fronterizo con Chile en Las Loicas/Malargüe.

Infraestructura: 4 ductos PEAD (40 mm externo / 34 mm interno) enterrados a 1,0-1,5 m de profundidad, cable de fibra óptica monomodo G.652D de 144 fibras instalado por soplado, cámaras de empalme prefabricadas de hormigón armado, empalmes por fusión en cajas Commscope FOSC-400 B4, y ODFs en cada nodo de amplificación/regeneración. Capacidad inicial de 2,4 Tbps, escalable con tecnología Ciena/Infinera.

Constituye la primera ruta interoceánica terrestre completamente nueva de la región en más de dos décadas, conectando los ecosistemas de cables submarinos del Atlántico (estación de aterrizaje de Cirion en Las Toninas) con los del Pacífico, y aportando diversificación y redundancia geográfica real a la conectividad internacional de Argentina frente a los corredores andinos existentes.

Impacto social: atraviesa más de 20 localidades del interior bonaerense, sur de La Pampa y este de Mendoza (entre ellas Olavarría, Tandil, Bolívar, Pehuajó, General Villegas, Rancul, San Rafael y Malargüe) que hoy presentan disponibilidad limitada y costos mayoristas elevados de conectividad de banda ancha. La nueva ruta permitirá a los ISP locales acceder a capacidad mayorista a precios competitivos, mejorar la resiliencia (diversidad de ruta real, reducción de puntos únicos de falla) y habilitar SLAs de alta disponibilidad (99,99%) para usuarios residenciales, comercios, industria, agro, educación y salud. Generará empleo local directo e indirecto durante la construcción (18 a 30 meses estimados).

Relevancia estratégica: posiciona a Argentina como nodo de tránsito para el creciente tráfico internacional impulsado por nube, streaming e IA, en conexión con nuevos cables submarinos del Pacífico (Proyecto Humboldt de Google, cable Firmina), y habilita condiciones de conectividad, energía y clima favorables para la instalación de datacenters de entrenamiento de IA en el sur de Mendoza y la región cuyana.

Plan de despliegue: H2 2026-Q1 2027 ingeniería de detalle y gestión de permisos; H1 2027 inicio de obra civil en tramos costeros y pampeanos (Las Toninas-Bolívar); H2 2027 avance en tramos pampeano-occidentales (Pehuajó-San Rafael); H1 2028 obras en precordillera y cordillera (San Rafael-Frontera); H2 2028 recepción de obra e integración con el sector chileno, puesta en servicio del enlace interoceánico completo.

Sponsor/operador: Cirion Technologies, empresa de infraestructura digital líder en América Latina, operadora de la estación de aterrizaje de cables submarinos de Las Toninas desde 1990.

Fuente: Proyecto Cruce Transandino - Propuesta a ENACOM, Cirion Technologies, junio de 2026, v1.0 (documento confidencial - ver adjunto en la sección de documentos técnicos del proyecto).$desc$,

  -- beneficiary_count: el documento habla de "+20 localidades beneficiadas"
  -- pero no da una cifra de población/hogares consolidada, así que queda
  -- en NULL. Si conseguís el dato (suma de población de las 20+
  -- localidades, o de hogares/ISPs abastecidos), lo podés cargar después
  -- editando el proyecto desde app/new-project.html.
  null,

  'Cirion Technologies',

  -- No hay un valor de generating_entity_type pensado para "operador de
  -- infraestructura / carrier" puro — el más cercano de la taxonomía
  -- existente (regulator / national_gov / provincial_gov / municipal_gov /
  -- isp / manufacturer / integrator / other) es 'isp', ya que Cirion opera
  -- como carrier mayorista. Si preferís etiquetarlo distinto, cambiá este
  -- valor por 'other'.
  'isp'
);

-- Verificación: confirma que el proyecto se creó y te muestra su id.
select id, name, project_type, country, generating_entity_name, created_at
from public.projects
where name = 'Proyecto Cruce Transandino (Andean Crossing Project)'
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
-- 2. Abrí el proyecto "Proyecto Cruce Transandino" recién creado.
-- 3. En la sección de Documentos, subí el archivo
--    "Proyecto_Cruce_Transandino_Propuesta_ENACOM_2026 FLV v2.pdf" en la
--    categoría "Técnica" (technical) — es la que corresponde a una memoria
--    descriptiva de obra.
--
-- Eso inserta automáticamente la fila correspondiente en
-- public.project_documents con el storage_path correcto
-- ({user_id}/{project_id}/{filename}), algo que un INSERT manual por SQL
-- no puede garantizar sin haber subido antes el archivo al bucket.
-- ============================================================================
