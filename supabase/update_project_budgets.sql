-- ============================================================================
-- Completa budget_amount (migration_v34) para los proyectos donde el monto
-- estimado se pudo detectar con confianza en el texto/adjuntos originales.
--
-- METODOLOGÍA: se revisó la descripción y shared_field_answers de los 7
-- proyectos cargados en la plataforma (supabase/data_*.sql). Solo 2 de los
-- 7 documentos fuente incluyen una cifra de presupuesto/inversión total
-- explícita y verificable — en los otros 5 la fuente original directamente
-- no especifica un monto (no es un dato faltante por mi parte: el pliego,
-- carpeta o propuesta no lo publica). Ver detalle de cada caso abajo.
--
-- PROYECTOS CON MONTO DETECTADO (2)
-- ----------------------------------------------------------------------------
-- 1) Sistema de Alerta Temprana - AlertAR
--    Fuente: "Pasos para la ET.pdf" (paso 5, "Finalización y remisión para
--    licitación") — estimación presupuestaria interna basada en presupuestos
--    de mercado previos. El pliego de licitación PLIEG-2026-63921688 NO
--    publica presupuesto oficial (es la oferta económica de cada oferente
--    la que define el monto final). Este valor ya está cargado en
--    shared_field_answers.monto_total_solicitado (ver update_alertar_monto.sql);
--    ahora se copia también a la nueva columna budget_amount.
--    Monto: ARS 12.000.000.000 (12.000 millones)
--
-- 2) Finalización de Despliegue FTTH y Migración HFC-FTTH - CEPA Punta Alta
--    Fuente: Carpeta Técnica "0004 - IF-2026-22344883-APN-AICPUST%ENACOM
--    (CARPETA TECNICA).pdf", cuadro resumen de inversión (sección completa
--    en el documento original, a diferencia de otras secciones que la
--    Cooperativa dejó en blanco).
--    Inversión total: USD 457.780,07, equivalente a ARS 650.047.693,72 al
--    tipo de cambio de referencia $1.420/USD consignado en la propia
--    Carpeta Técnica. Como budget_amount es una columna sin campo de moneda
--    separado (ARS por convención, ver comentario de columna en
--    migration_v34), se carga el equivalente en ARS.
--    Monto: ARS 650.047.693,72
--
-- PROYECTOS SIN MONTO DETECTADO (5) — NO se generó UPDATE para estos
-- ----------------------------------------------------------------------------
-- - Proyecto Cruce Transandino (Cirion Technologies): el documento fuente
--   es una propuesta confidencial v1.0 que no incluye cifras de inversión
--   ni presupuesto en ningún punto del texto cargado.
-- - CAPPI Red Federal de IA y Datos: la propuesta dice explícitamente que
--   "no especifica un monto de inversión solicitado a ENACOM" — el
--   financiamiento del equipamiento queda a cargo de cada ISP participante.
-- - CAPPI Infraestructura Compartida: propuesta de marco regulatorio de
--   comparticion de infraestructura, sin CAPEX propio ni monto asociado.
-- - CAPPI Corredores Digitales Ferroviarios: mismo caso, sin cifra de
--   inversión total en el documento fuente.
-- - Patagonia Hub IA (Ciena): el documento aclara que "no hay presupuesto
--   total" definido (no hay sitio ni sponsor ejecutor concreto todavía) —
--   solo da un rango de CAPEX por MW (USD 4-8 M/MW) que no es un monto de
--   proyecto, sino un parámetro de referencia por escala.
--
-- Si conseguís el dato real para alguno de estos 5 (oferta económica,
-- carpeta técnica actualizada, etc.), se puede cargar a mano desde
-- new-project.html → Editar → campo "Presupuesto total", o con un UPDATE
-- igual a los de abajo.
--
-- CÓMO USAR
-- EDITAR el email si no es 'pcymeryng@gmail.com' en cada bloque. Los
-- proyectos tienen que existir ya (fueron cargados con los data_*.sql
-- correspondientes).
-- ============================================================================

-- 1) AlertAR
update public.projects
set
  budget_amount = 12000000000,
  updated_at = now()
where name = 'Sistema de Alerta Temprana - AlertAR'
  -- EDITAR: email de la cuenta dueña del proyecto, si no es esta.
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- 2) CEPA Punta Alta FTTH
update public.projects
set
  budget_amount = 650047693.72,
  updated_at = now()
where name = 'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta'
  -- EDITAR: email de la cuenta dueña del proyecto, si no es esta.
  and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com');

-- ============================================================================
-- Verificación
-- ============================================================================
select
  name,
  budget_amount,
  updated_at
from public.projects
where name in (
  'Sistema de Alerta Temprana - AlertAR',
  'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta'
)
order by name;
