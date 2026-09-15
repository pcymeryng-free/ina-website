-- Data: backfill success_cases.title_en for the 21 Starlink case studies
-- seeded by data_success_cases_starlink.sql — Pablo, sep 2026: "tanto en
-- Success Cases como en Financing Programs hay que poner en inglés todo el
-- contenido cuando el idioma seleccionado es el inglés". Those rows already
-- had summary_en/metrics_en; only the case TITLE itself was Spanish-only
-- (see migration_v60_bilingual_title_description.sql, which adds the
-- title_en column this file populates).
--
-- Matched by exact `title` text and guarded with `title_en is null` so this
-- is safe to run even if some titles were already edited by hand in the UI
-- — it will never clobber a value someone already set.
--
-- Run this AFTER migration_v60_bilingual_title_description.sql, in the
-- Supabase SQL Editor. A handful of titles are proper names shared across
-- both languages (e.g. "Enseña por Bolivia + One Laptop Per Child") and are
-- intentionally left out below — successCaseDisplayTitle() already falls
-- back to `title` for those, so there is nothing to translate.

update public.success_cases set title_en = 'Connecting 2,000 educational institutions'
  where title = 'Conexión de 2.000 instituciones educativas' and title_en is null;

update public.success_cases set title_en = 'Instituto Redes do Futuro — 114 kits in the Amazon'
  where title = 'Instituto Redes do Futuro — 114 kits en la Amazonía' and title_en is null;

update public.success_cases set title_en = 'Partnership with the Ministry of Education — 1,600 remote schools'
  where title = 'Alianza con el Ministerio de Educación — 1.600 escuelas remotas' and title_en is null;

update public.success_cases set title_en = 'Polaris Program — Mapuche indigenous region'
  where title = 'Programa Polaris — región indígena Mapuche' and title_en is null;

update public.success_cases set title_en = 'First medical center in the Xingu Indigenous Reserve'
  where title = 'Primer centro médico en la Reserva Indígena Xingu' and title_en is null;

update public.success_cases set title_en = 'Unconnected NGO — 10 ultra-rural communities'
  where title = 'ONG Unconnected — 10 comunidades ultra-rurales' and title_en is null;

update public.success_cases set title_en = 'Telemedicine on medical boats in the Amazon rainforest'
  where title = 'Telemedicina en barcos médicos de la selva amazónica' and title_en is null;

update public.success_cases set title_en = 'Contigo Antioquia Program — specialized telehealth'
  where title = 'Programa Contigo Antioquia — telesalud especializada' and title_en is null;

update public.success_cases set title_en = 'Recovery after Hurricane Melissa'
  where title = 'Recuperación tras el Huracán Melissa' and title_en is null;

update public.success_cases set title_en = 'Flood response — 56 terminals donated'
  where title = 'Respuesta a inundaciones — 56 terminales donadas' and title_en is null;

update public.success_cases set title_en = 'Flood recovery in Rio Do Sul'
  where title = 'Recuperación por inundaciones en Rio Do Sul' and title_en is null;

update public.success_cases set title_en = 'Flooding emergency in Bahía Blanca'
  where title = 'Emergencia por inundaciones en Bahía Blanca' and title_en is null;

update public.success_cases set title_en = 'Response to flooding and landslides'
  where title = 'Respuesta a inundaciones y deslizamientos' and title_en is null;

update public.success_cases set title_en = 'Bacanora-mezcal production on a 17,000-acre ranch'
  where title = 'Producción de bacanora-mezcal en un rancho de 17.000 acres' and title_en is null;

update public.success_cases set title_en = 'Real-time digital agriculture in the Bahia region'
  where title = 'Agricultura digital en tiempo real en la región de Bahía' and title_en is null;

update public.success_cases set title_en = 'John Deere selects Starlink for agricultural machinery'
  where title = 'John Deere selecciona Starlink para maquinaria agrícola' and title_en is null;

update public.success_cases set title_en = 'Educación Misiones — 45 antennas in rural schools'
  where title = 'Educación Misiones — 45 antenas en escuelas rurales' and title_en is null;

update public.success_cases set title_en = 'US$6 million investment for 1,500 public schools'
  where title = 'Inversión de $6 millones para 1.500 escuelas públicas' and title_en is null;

update public.success_cases set title_en = 'Isla Esmeralda connectivity'
  where title = 'Conectividad de la Isla Esmeralda' and title_en is null;

update public.success_cases set title_en = 'Minas Gerais Fire Department training'
  where title = 'Capacitación del Cuerpo de Bomberos de Minas Gerais' and title_en is null;
