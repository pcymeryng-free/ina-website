-- ============================================================================
-- Alta de proyecto: Patagonia — Hub de Infraestructura de IA para el Sur
-- Global
-- Autor del análisis: Ciena Corporation — Charla Técnica, junio 2026
-- Fuente: 2.Hub-de-Infraestructura-IA-para-el-Sur-Global.pdf
--
-- NOTA CONCEPTUAL — leer antes de correr este script
-- A diferencia de los proyectos cargados anteriormente, este documento NO
-- es una carpeta técnica de un proponente concreto con un sitio, sponsor y
-- plan de ejecución definidos: es un análisis estratégico/comercial de
-- Ciena Corporation que argumenta POR QUÉ la Patagonia argentina es una
-- localización óptima para un datacenter de IA a escala (100 MW+),
-- evaluando TRES corredores candidatos (Neuquén-Cipolletti, Puerto
-- Madryn-Comodoro, Río Grande-Ushuaia) en vez de comprometerse con un
-- sitio único. No hay sponsor ejecutor nombrado, ni presupuesto total, ni
-- cronograma de desembolsos — es la tesis de oportunidad, no la carpeta de
-- un proyecto ya estructurado.
--
-- Aun así encaja muy bien en el Template de Datacenter ya existente en la
-- plataforma (assets/platform.js → DATACENTER_TEMPLATE), así que además
-- del INSERT este script precarga projects.shared_field_answers con las
-- respuestas de ese template que sí están respaldadas por el documento
-- (igual criterio que se usó para la Red Federal de Centros Regionales de
-- IA y Datos de CAPPI). Todo lo que el documento no específica a nivel de
-- sitio concreto (superficie exacta, presupuesto total, cronograma,
-- proponente ejecutor) se dejó fuera a propósito.
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
  generating_entity_type,
  shared_field_answers
)
values (
  -- EDITAR: email de la cuenta que debe figurar como dueña del proyecto.
  (select id from public.profiles where email = 'pcymeryng@gmail.com'),

  'Patagonia - Hub de Infraestructura de IA para el Sur Global',

  'ai_datacenter',

  'Argentina',

$desc$TEMPLATE DE PROYECTO DE DATACENTER

1. Clasificación
- Tipo de datacenter: IA - Entrenamiento / Hyperscale
- Escala del proyecto (potencia total): 100 MW - 1+ GW (IA Hyperscale)
- Topología: Sitio único (primer campus ancla)
- Detalle de topología (si es red distribuida): Tres corredores estrategicos evaluados como candidatos para el primer campus (~100 MW): Neuquen-Cipolletti (~900 km de Buenos Aires, cercania a Vaca Muerta/gas/aeropuerto, mix gas+eolico ideal); Puerto Madryn-Comodoro (~1.400 km de BA, excelente recurso eolico, costa atlantica apta para cable submarino y cooling marino); Rio Grande-Ushuaia (~3.000 km de BA, temperatura media 6C, Zona Franca de Tierra del Fuego, paso Drake, potencial hub trans-oceanico Pacifico-Atlantico).
- Uso previsto / modelo de servicio: GPU-as-a-Service
- Horizonte de despliegue: Nuevo (greenfield)
- Segmentos de servicio / público objetivo: Otro

2. Sitio y terreno
- Modalidad del sitio: Terreno propio, obra nueva
- Tenencia: Propiedad

3. Energía
- Potencia total planificada: 100 MW (primer campus ancla propuesto); el analisis tambien contempla escenarios de hasta 200 MW de carga TI total
- Densidad de energía por rack: 50-200 kW/rack (densidades tipicas de IA)
- Fuente de suministro: Mix
- Respaldo (generador): combustible y autonomía: Generacion termica a gas (CCGT) de Vaca Muerta como base/respaldo, USD 18-28/MWh, disponibilidad 24/7 - complementa la base eolica dentro del "mix optimo" propuesto
- Factibilidad con distribuidora local: No verificada

4. Refrigeración
- Tipo de refrigeración: Direct Liquid Cooling (back-plate o cold plate)
- PUE objetivo declarado: 1,15-1,25 en Patagonia (vs. 1,35-1,50 en Austin/Virginia del Norte, segun el analisis comparativo del documento)

5. Cómputo
- Tipo principal de cómputo: GPU
- Carga de trabajo objetivo: Entrenamiento de modelos (LLMs)

6. Red y conectividad
- Redundancia de tránsito: 1 proveedor único (estado actual: toda la conectividad transita por Buenos Aires, sin cable submarino propio - ver notas)

10. Sustentabilidad
- Fuente de energía: Mixta
- Consumo de agua estimado: No aplica - sistemas DLC, independientes de la humedad, sin consumo hidrico evaporativo relevante segun el documento

11. Modelo de negocio y financiero
- Etapa de la propuesta: Piloto (primer campus ancla que, segun el documento, "puede anclar el ecosistema completo")
- CAPEX total (y por MW/nodo, si se conoce): USD 4-8 M/MW en Sur de Argentina, vs. USD 10-15 M/MW en Austin, USD 12-18 M/MW en Virginia del Norte, USD 12-16 M/MW en Dublin y USD 10-14 M/MW en Oslo (referencia: CBRE, JLL, Cushman & Wakefield, 2025-2026)
- OPEX anual estimado: OPEX de energia USD 15-30/MWh en Patagonia (vs. USD 45-110/MWh en los demas hubs comparados); ahorro estimado en cooling de USD 18-20 M/año para 100 MW de carga TI
- Modelo de pricing de servicios: GPU-as-a-Service (USD/hora por GPU)
- Indicadores de rentabilidad financiera: Mas de USD 2.000 M de ahorro en TCO a 10 años vs. Virginia del Norte, para una carga de 100 MW (estimacion del documento)
- Moneda del préstamo/inversión y cobertura de riesgo cambiario: Contratos y PPAs denominados en USD, planteados explicitamente como mitigante frente al riesgo regulatorio de inestabilidad macroeconomica y controles de cambio
- Estructura de financiamiento propuesta: Capital privado

Notas adicionales (salvaguardas ambientales y sociales, marco de resultados/marco lógico, matriz de riesgos de 7 categorías, plan de despliegue por etapas y KPIs del piloto, checklist de documentación de respaldo, etc.)
Mapa de riesgos y habilitadores del documento: Energia - riesgo: saturacion de la red SADI y CAPEX de transmision; habilitante: Vaca Muerta, eolico, generacion on-site. Conectividad - riesgo: sin cable submarino directo, fibra saturada; habilitante: Cable Humboldt via Chile, financiamiento RIGI para fibra. Regulatorio - riesgo: inestabilidad macroeconomica, controles de cambio; habilitante: RIGI (estabilidad regulatoria 30 años), Zona Franca de Tierra del Fuego, contratos en USD. Logistica - riesgo: distancia de 900 a 3.000 km de Buenos Aires; habilitante: transporte aereo, regimen de Zona Franca sin aranceles. Talento - riesgo: escasez de ingenieros especializados; habilitante: modelo remoto-first, universidades de Neuquen y Bariloche.

Segmento de servicio objetivo (no capturado en el campo unico de "publico objetivo"): operadores de nube/IA globales, particularmente europeos y asiaticos, que buscan jurisdicciones no alineadas - el documento senala que la LGPD brasilena y la neutralidad politica argentina crean una "ventana unica" para este perfil de cliente.

Ventana de oportunidad: el documento identifica 2024-2030 como la unica ventana para posicionar a la Patagonia como hub de IA, condicionado a resolver la conectividad (sin integracion con el cable Humboldt o cable submarino propio, la region queda limitada a entrenamiento batch, no a inferencia en tiempo real).

Fuente: "PATAGONIA - Hub de Infraestructura IA para el Sur Global. Analisis Tecnico, Geografico y Economico - Sur de Argentina", Ciena Corporation, Charla Tecnica, junio de 2026 (documento adjunto en la seccion de documentos tecnicos del proyecto).$desc$,

  -- beneficiary_count: no aplica - es infraestructura de computo IA a
  -- escala hyperscale orientada a clientes corporativos/operadores de
  -- nube globales, no un despliegue con una poblacion beneficiaria directa
  -- medible en hogares.
  null,

  'Ciena Corporation',

  -- Ciena es un fabricante de equipamiento de redes ópticas/DWDM, autor
  -- del análisis técnico - 'manufacturer' es el valor más preciso de la
  -- taxonomía existente (no es un ISP, gobierno, ni integrador de este
  -- proyecto específico).
  'manufacturer',

  -- Respuestas del Template de Datacenter (assets/platform.js →
  -- DATACENTER_TEMPLATE) respaldadas por el documento. No se completaron
  -- superficie_sitio (solo hay precio por hectárea, no una superficie
  -- concreta), especificaciones_servidores (no hay BOM de equipamiento —
  -- es un análisis de siting, no una carpeta técnica de despliegue),
  -- nivel_tier, licencia_tic, ni los campos de dimensionamiento operativo
  -- (sección 12) — nada de eso está en el documento.
$$
{
  "tipo_datacenter": "ia_entrenamiento",
  "escala_potencia": "100mw_1gw",
  "topologia": "sitio_unico",
  "topologia_detalle": "Tres corredores estrategicos evaluados como candidatos para el primer campus (~100 MW): Neuquen-Cipolletti (~900 km de Buenos Aires, cercania a Vaca Muerta/gas/aeropuerto, mix gas+eolico ideal); Puerto Madryn-Comodoro (~1.400 km de BA, excelente recurso eolico, costa atlantica apta para cable submarino y cooling marino); Rio Grande-Ushuaia (~3.000 km de BA, temperatura media 6C, Zona Franca de Tierra del Fuego, paso Drake, potencial hub trans-oceanico Pacifico-Atlantico).",
  "uso_servicio": "gpu_as_a_service",
  "horizonte_despliegue": "greenfield",
  "segmento_servicio": "otro",
  "modalidad_sitio": "terreno_propio",
  "tenencia": "propiedad",
  "potencia_total": "100 MW (primer campus ancla propuesto); escenarios de analisis de hasta 200 MW de carga TI total",
  "densidad_rack": "50-200 kW/rack",
  "fuente_suministro": "mix",
  "respaldo_generador": "Generacion termica a gas (CCGT) de Vaca Muerta como base/respaldo, USD 18-28/MWh, disponibilidad 24/7",
  "factibilidad_distribuidora": "no_verificada",
  "tipo_refrigeracion": "dlc",
  "pue_objetivo": "1.15-1.25 en Patagonia (vs. 1.35-1.50 en Austin/Virginia del Norte)",
  "tipo_computo": "gpu",
  "carga_trabajo": "entrenamiento",
  "redundancia_transito": "un_proveedor",
  "fuente_energia_sustentable": "mixta",
  "consumo_agua": "No aplica - sistemas DLC, independientes de la humedad, sin consumo hidrico evaporativo relevante",
  "etapa_propuesta": "piloto",
  "capex_total": "USD 4-8 M/MW en Sur de Argentina (referencia: CBRE, JLL, Cushman & Wakefield 2025-2026)",
  "opex_anual": "USD 15-30/MWh de energia en Patagonia; ahorro estimado en cooling de USD 18-20 M/año para 100 MW de carga TI",
  "modelo_pricing": "gpu_as_a_service",
  "indicadores_rentabilidad": "Mas de USD 2.000 M de ahorro en TCO a 10 años vs. Virginia del Norte para 100 MW",
  "moneda_cobertura_cambiaria": "Contratos y PPAs en USD, como mitigante frente a inestabilidad macro y controles de cambio",
  "estructura_financiamiento": "capital_privado",
  "notas_adicionales": "Mapa de riesgos y habilitadores (energia, conectividad, regulatorio RIGI/Zona Franca TDF, logistica, talento). Segmento objetivo: operadores de nube/IA globales (Europa/Asia) buscando jurisdiccion no alineada. Ventana de oportunidad 2024-2030. Fuente: Ciena Corporation, Hub de Infraestructura IA para el Sur Global, junio 2026."
}
$$::jsonb
);

-- Verificación: confirma que el proyecto se creó y te muestra su id.
select id, name, project_type, country, generating_entity_name, created_at
from public.projects
where name = 'Patagonia - Hub de Infraestructura de IA para el Sur Global'
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
-- 2. Abrí el proyecto "Patagonia - Hub de Infraestructura de IA para el
--    Sur Global".
-- 3. En la sección de Documentos, subí el archivo
--    "2.Hub-de-Infraestructura-IA-para-el-Sur-Global.pdf" en la categoría
--    "Técnica" (technical) o "Económica" (economic) — el documento mezcla
--    ambos enfoques; "Técnica" es la opción más consistente con los otros
--    proyectos ya cargados.
-- 4. Opcional pero recomendado: desde la sección de Templates del
--    proyecto, abrí "Usar template" → Template de Datacenter. Vas a ver
--    los campos de arriba ya precargados (gracias a shared_field_answers)
--    — completá ahí lo que falta (proponente ejecutor concreto, corredor
--    elegido, superficie exacta, monto total y cronograma) una vez que el
--    proyecto pase de tesis de oportunidad a proyecto estructurado.
-- ============================================================================
