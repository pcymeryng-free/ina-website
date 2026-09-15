-- ============================================================================
-- Roadmap Template: "INA F1 — Project Structuring Framework™ (5 Fases)"
--
-- QUÉ CARGA ESTE SCRIPT (ítem B de la hoja de ruta de corto plazo propuesta
-- en INA_Project_Structuring_Framework_y_Plataforma.pdf, sección 9.3)
-- Crea un roadmap_template REUTILIZABLE con las cinco fases del Project
-- Structuring Framework™ de INA (framework.html, sección F1) como pasos
-- secuenciales, cada uno con su objetivo, sus entregables (en
-- expected_result) y el gate que habilita. No requiere ninguna migración
-- de esquema — usa el sistema de Roadmaps ya existente
-- (roadmap_templates / roadmap_template_steps), el mismo que ya carga
-- supabase/data_roadmap_alertar_et.sql.
--
-- A diferencia de ese script, este SOLO crea el template reutilizable —
-- no lo instancia sobre ningún proyecto puntual (no toca roadmap_instances
-- ni roadmap_instance_steps). Cualquier advisor/admin puede instanciarlo
-- después, por proyecto, desde app/roadmap-templates.html o desde la
-- sección "Roadmaps" de app/project.html, cuantas veces lo necesite.
--
-- project_type = null y allowed_entity_type = null a propósito: el
-- Framework aplica "de la misma manera a un organismo público, una
-- empresa privada, un consorcio de operadores o un vehículo de inversión
-- de capital mixto" (framework.html, F1), así que el template debe
-- aparecer disponible para CUALQUIER tipo de proyecto y cualquier tipo de
-- entidad (ver INAPlatform.listRoadmapTemplates() en assets/platform.js:
-- filtra por `!t.project_type || t.project_type === projectType`).
--
-- Los campos entity_name / involved_entities de cada paso reflejan el
-- "Checkpoint humano" y el "Agente de IA" de cada fase, tal como están
-- documentados en framework.html (tabla de Arquitectura de Agentes de IA
-- y Matriz RACI) — así el roadmap deja explícito, paso a paso, quién
-- aprueba y qué agente de IA puede asistir en el borrador, sin que la
-- plataforma tenga hoy agentes de Fase III/IV/V realmente construidos
-- (eso queda para el mediano/largo plazo de la hoja de ruta).
--
-- CÓMO USAR
-- 1. EDITAR el email si el dueño del template no es 'pcymeryng@gmail.com'.
--    Tiene que tener rol advisor/admin en public.profiles (si lo corrés
--    desde el SQL Editor de Supabase funciona igual, sin importar el rol,
--    porque el Editor corre con privilegios elevados y no pasa por RLS).
-- 2. Ejecutá el script completo. Al final corre un SELECT de verificación
--    con las 5 fases en orden.
-- 3. Para usarlo: en la plataforma, abrí un proyecto → Roadmaps →
--    "Instanciar desde template" → elegí "INA F1 — Project Structuring
--    Framework™ (5 Fases)" → completá la entidad que lo ejecuta.
-- ============================================================================

with new_template as (
  insert into public.roadmap_templates (user_id, project_type, name, description, allowed_entity_type)
  values (
    (select id from public.profiles where email = 'pcymeryng@gmail.com'),
    null,
    'INA F1 — Project Structuring Framework™ (5 Fases)',
    'Checklist reutilizable de las cinco fases del Project Structuring Framework™ de INA — Diagnóstico Estratégico y Alineación, Factibilidad/Business Case/Estructuración Financiera, Diseño de Gobernanza y Modelo Contractual, Contratación e Implementación, y Monitoreo/Gestión del Cambio/Mejora Continua — con los entregables y el gate que habilita cada una. Aplica a cualquier tipología de proyecto y a cualquier naturaleza de sponsor (público, privado o de capital mixto). Fuente: INA Project Structuring Framework™, metodología v1.0 (julio 2026).',
    null
  )
  returning id
),
step_data (step_order, title, description, entity_name, entity_type, involved_entities, expected_result) as (
  values
    (
      0,
      'Fase I — Diagnóstico Estratégico y Alineación',
      'Establecer el problema a resolver, su alineación con los objetivos estratégicos del sponsor y el nivel de patrocinio ejecutivo disponible. El Agente de Diagnóstico de INA puede asistir analizando la documentación existente del sponsor (contratos, inventarios de red, actas, relevamientos previos) y redactando un primer borrador del Documento de Diagnóstico Estratégico.',
      'Sponsor ejecutivo',
      'mixed',
      array['Comité Directivo (aprueba el Gate 1)', 'Agente de Diagnóstico (IA) — borrador asistido']::text[],
      'Documento de Diagnóstico Estratégico y Carta de Alineación completos y validados por el sponsor ejecutivo — habilita el Gate 1 (decisión go/no-go).'
    ),
    (
      1,
      'Fase II — Factibilidad, Business Case y Estructuración Financiera',
      'Determinar la viabilidad técnica, financiera y regulatoria, y construir el business case que respalda la decisión de inversión. El Agente de Estructuración Financiera de INA puede asistir cruzando los parámetros del proyecto contra líneas de financiamiento disponibles (BID, CAF, FSU, otras) y generando un modelo preliminar de costo total.',
      'Comité Directivo',
      'mixed',
      array['PMO', 'Agente de Estructuración Financiera (IA) — modelo preliminar']::text[],
      'Business Case, Modelo Financiero a 5 años, Análisis de Fuentes de Financiamiento y Matriz de Riesgos Preliminar completos y ratificados por el comité directivo — habilita el Gate 2 (decisión de inversión).'
    ),
    (
      2,
      'Fase III — Diseño de Gobernanza y Modelo Contractual',
      'Definir cómo se gobernará el proyecto durante la ejecución y qué modelo contractual transfiere riesgo a los proveedores. El Copiloto de Estructuración Contractual de INA puede asistir redactando especificaciones técnicas y documentación de licitación a partir de la librería de cláusulas de INA, y señalando cláusulas atípicas o de alto riesgo.',
      'Comité Técnico',
      'mixed',
      array['Legales / Asesoría Jurídica', 'PMO', 'Copiloto de Estructuración Contractual (IA) — borrador asistido']::text[],
      'Manual de Gobernanza del Proyecto, Especificaciones Técnicas y Modelo de Contrato, y Matriz RACI completos y validados por legales y el comité técnico — habilita el Gate 3 (autorización para lanzar la contratación).'
    ),
    (
      3,
      'Fase IV — Contratación e Implementación',
      'Ejecutar el proceso de contratación según la normativa aplicable e impulsar la implementación con control activo de alcance, tiempo, costo y calidad. El Agente de Evaluación de Ofertas de INA puede asistir preprocesando y puntuando ofertas técnicas, y resumiendo en lenguaje natural los informes de avance de proveedores.',
      'PMO',
      'mixed',
      array['Comité Evaluador', 'Proveedor adjudicado', 'Agente de Evaluación de Ofertas (IA) — preprocesamiento de ofertas']::text[],
      'Contrato Adjudicado y Plan de Ejecución, Informes de Avance, y Aceptación de Hitos con Firma de Puesta en Marcha completos — habilita el Gate 4 (aceptación de la solución).'
    ),
    (
      4,
      'Fase V — Monitoreo, Gestión del Cambio y Mejora Continua',
      'Asegurar la adopción operativa, sostener el desempeño en el tiempo y capturar lecciones aprendidas para futuros proyectos. El Agente de Inteligencia Operativa de INA puede asistir monitoreando continuamente KPIs y SLAs, detectando anomalías y redactando los informes de cierre y lecciones aprendidas.',
      'PMO',
      'mixed',
      array['Sponsor ejecutivo', 'Agente de Inteligencia Operativa (IA) — monitoreo continuo']::text[],
      'Plan de Gestión del Cambio Ejecutado, Tablero de Desempeño e Informe de Cierre y Lecciones Aprendidas completos y validados por el PMO y el sponsor ejecutivo. Fase continua — sin gate adicional.'
    )
)
insert into public.roadmap_template_steps (
  template_id, step_order, title, description, entity_name, entity_type, required, expected_result, involved_entities
)
select nt.id, sd.step_order, sd.title, sd.description, sd.entity_name, sd.entity_type, true, sd.expected_result, sd.involved_entities
from new_template nt cross join step_data sd;

-- ============================================================================
-- Verificación
-- ============================================================================
select
  rt.name as template_name,
  rt.project_type,
  rt.allowed_entity_type,
  rts.step_order,
  rts.title as step_title,
  rts.entity_name as step_responsible,
  rts.involved_entities
from public.roadmap_templates rt
join public.roadmap_template_steps rts on rts.template_id = rt.id
where rt.name = 'INA F1 — Project Structuring Framework™ (5 Fases)'
  and rt.user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')
order by rts.step_order;
