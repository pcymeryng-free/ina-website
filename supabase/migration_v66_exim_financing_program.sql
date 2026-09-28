-- Adds EXIM (Export-Import Bank of the United States) as a Financing
-- Program — sourced from the U.S. Department of State fact sheet "United
-- States and Argentina Launch Andes-Atlantic Corridor" (2026-09-23/24),
-- found while cross-checking the Pax Silica internal analysis against
-- what's already loaded in Financing Programs. Same shape/convention as
-- the existing BID "Conexión Sur" row: a direct bilateral/regional
-- instrument with no ENACOM-administered domestic channel yet, so
-- organization and financing_entity are the same value.
--
-- user_id is set to Pablo's own profile (pcymeryng@gmail.com) so the
-- Activity Log / "added by" columns attribute this the same way a normal
-- New Program submission would, even though it's going in via SQL.
--
-- Run this once in the Supabase SQL Editor.

insert into public.programs (
  user_id,
  name,
  name_en,
  organization,
  organization_en,
  organization_type,
  financing_entity,
  financing_entity_en,
  types,
  description,
  description_en,
  funding_stage,
  program_role
) values (
  '532b9308-dfec-4944-9668-5ae7de5bb9f8', -- pcymeryng@gmail.com
  'EXIM — Export-Import Bank de Estados Unidos',
  'EXIM — U.S. Export-Import Bank',
  'Export-Import Bank of the United States (EXIM)',
  'Export-Import Bank of the United States (EXIM)',
  'public',
  'Export-Import Bank of the United States (EXIM)',
  'Export-Import Bank of the United States (EXIM)',
  array[
    'submarine_cable',
    'fiber_backbone_last_mile',
    'fixed_wireless_access',
    'wholesale_neutral_network',
    'ai_datacenter',
    'satellite_constellation',
    'passive_infrastructure'
  ]::text[],
  'Agencia de crédito a la exportación del gobierno de Estados Unidos, activada como instrumento de financiamiento para Argentina en el marco del "U.S.-Argentina Build the Future Framework" (septiembre 2026) y el lanzamiento del Andes-Atlantic Corridor — el primer corredor del Partnership for Global Infrastructure and Investment en el hemisferio occidental, que conecta el noroeste minero y Vaca Muerta con puertos atlánticos vía infraestructura de transporte, energía y digital.

EXIM emitió un term sheet indicativo no vinculante de hasta US$ 6.000 millones para Argentina LNG, dentro de un marco bilateral que prevé financiamiento de hasta US$ 7.000 millones para 2027. El fact sheet oficial cita explícitamente cables submarinos, redes de fibra, conectividad inalámbrica fija y satelital, y datacenters de IA como "proyectos de interés" del Corridor — el mismo alcance de infraestructura digital que ya cubre la plataforma INA.

A diferencia de los programas del BID/DFC ya cargados (adaptados específicamente a Argentina vía ENACOM), este instrumento de EXIM todavía no tiene un canal doméstico administrador definido públicamente — opera como línea de crédito a la exportación directa del gobierno de EE.UU.

Fuente: U.S. Department of State, "United States and Argentina Launch Andes-Atlantic Corridor" (fact sheet, 23-24/09/2026).',
  'U.S. government export credit agency, activated as a financing instrument for Argentina under the "U.S.-Argentina Build the Future Framework" (September 2026) and the launch of the Andes-Atlantic Corridor — the first Partnership for Global Infrastructure and Investment Corridor in the Western Hemisphere, connecting Argentina''s mineral-rich northwest and Vaca Muerta to Atlantic ports via transport, energy and digital infrastructure.

EXIM issued a non-binding indicative term sheet of up to US$6 billion for Argentina LNG, within a bilateral framework providing for up to US$7 billion in financing through 2027. The official fact sheet explicitly cites submarine cables, fiber networks, fixed wireless and satellite connectivity, and AI datacenters as Corridor "projects of interest" — the same digital-infrastructure scope already covered by the INA platform.

Unlike the IDB/DFC programs already loaded (specifically adapted for Argentina via ENACOM), this EXIM instrument doesn''t yet have a publicly defined domestic administering channel — it operates as a direct U.S. government export credit line.

Source: U.S. Department of State, "United States and Argentina Launch Andes-Atlantic Corridor" (fact sheet, 09/23-24/2026).',
  'financing',
  'financing'
);
