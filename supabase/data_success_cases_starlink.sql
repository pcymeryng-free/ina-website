-- Data: seed the new Casos de Éxito (Success Cases) library with the 21 case
-- studies from "Starlink Impact Use Cases LATAM ESP.pdf" (Pablo, sep 2026).
-- Requires migration_v59_success_cases.sql to have been run first.
--
-- Grouped exactly as the source PDF groups them (Educación / Salud /
-- Respuesta a Emergencias / Agricultura / Iniciativas Gubernamentales),
-- mapped onto success_cases.sector. English summaries are original
-- translations of the source Spanish text, matching the platform's
-- existing bilingual convention (see migration_v40_bilingual_analysis.sql
-- and migration_v50_investment_proposal.sql). created_by left NULL — no
-- specific advisor account attached to the seed data.
--
-- Run manually in Supabase SQL Editor, once.

insert into public.success_cases
  (title, provider, country, region, sector, summary_es, summary_en, beneficiaries_count, metrics_es, metrics_en, source_label)
values

-- ---------- EDUCACIÓN ----------
(
  'Conexión de 2.000 instituciones educativas',
  'Starlink', 'Colombia', null, 'education',
  'Starlink, en alianza con un distribuidor autorizado, ha conectado 2.000 instituciones educativas en Colombia, beneficiando a más de 700.000 estudiantes y 18.000 docentes.',
  'Starlink, in partnership with an authorized distributor, has connected 2,000 educational institutions in Colombia, benefiting more than 700,000 students and 18,000 teachers.',
  700000,
  '2.000 instituciones · 700.000 estudiantes · 18.000 docentes',
  '2,000 institutions · 700,000 students · 18,000 teachers',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Instituto Redes do Futuro — 114 kits en la Amazonía',
  'Starlink', 'Brasil', 'Amazonía', 'education',
  'Una donación de 114 kits Starlink conectó a más de 14.000 estudiantes a internet de alta velocidad en la Amazonía brasileña, a través del Instituto Redes do Futuro. Antes de la donación, el 50% de los estudiantes no tenía acceso a internet y el otro 50% tenía conectividad deficiente.',
  'A donation of 114 Starlink kits connected more than 14,000 students to high-speed internet in the Brazilian Amazon, through the Instituto Redes do Futuro. Before the donation, 50% of students had no internet access and the other 50% had poor connectivity.',
  14000,
  '114 kits donados · 14.000 estudiantes conectados',
  '114 kits donated · 14,000 students connected',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Alianza con el Ministerio de Educación — 1.600 escuelas remotas',
  'Starlink', 'Panamá', null, 'education',
  'Starlink y el Ministerio de Educación de Panamá han conectado más de 1.600 escuelas remotas, beneficiando a más de 450.000 estudiantes y 13.000 docentes en todo el país.',
  'Starlink and Panama''s Ministry of Education have connected more than 1,600 remote schools, benefiting more than 450,000 students and 13,000 teachers nationwide.',
  450000,
  '1.600 escuelas · 450.000 estudiantes · 13.000 docentes',
  '1,600 schools · 450,000 students · 13,000 teachers',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Programa Polaris — región indígena Mapuche',
  'Starlink', 'Chile', 'La Araucanía', 'education',
  'El Programa Polaris donó $500.000 para conectar más de 50 escuelas, 7.500 estudiantes y 700 docentes en la región indígena Mapuche de La Araucanía, a través de la ONG Enseña Chile.',
  'The Polaris Program donated $500,000 to connect more than 50 schools, 7,500 students and 700 teachers in the Mapuche indigenous region of La Araucanía, through the NGO Enseña Chile.',
  7500,
  'US$500.000 donados · 50 escuelas · 7.500 estudiantes · 700 docentes',
  'US$500,000 donated · 50 schools · 7,500 students · 700 teachers',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Enseña por Bolivia + One Laptop Per Child',
  'Starlink', 'Bolivia', 'La Paz y Santa Cruz', 'education',
  'Se donaron 22 kits Starlink a Enseña por Bolivia, en alianza con One Laptop Per Child, para conectar escuelas rurales en La Paz y Santa Cruz. Este proyecto ha inspirado una iniciativa para conectar 5.000 escuelas junto con el Ministerio de Educación.',
  '22 Starlink kits were donated to Enseña por Bolivia, in partnership with One Laptop Per Child, to connect rural schools in La Paz and Santa Cruz. This project has inspired an initiative to connect 5,000 schools together with the Ministry of Education.',
  null,
  '22 kits donados · iniciativa en curso para 5.000 escuelas',
  '22 kits donated · ongoing initiative for 5,000 schools',
  'Starlink — Impacto en América Latina (2026)'
),

-- ---------- SALUD ----------
(
  'Primer centro médico en la Reserva Indígena Xingu',
  'Starlink', 'Brasil', 'Amazonía', 'health',
  'Starlink se asoció con la ONG Xingu + Catu para abrir el primer centro médico de Brasil en la Reserva Indígena Xingu, hogar de la nación Kuikuro. El proyecto lleva rayos X, ecografías y consultas remotas a 2.000 personas que antes debían viajar más de 12 horas para recibir tratamiento.',
  'Starlink partnered with the NGO Xingu + Catu to open Brazil''s first medical center in the Xingu Indigenous Reserve, home to the Kuikuro nation. The project brings X-rays, ultrasounds and remote consultations to 2,000 people who previously had to travel more than 12 hours for treatment.',
  2000,
  '2.000 personas beneficiadas · antes, +12 horas de viaje para atención',
  '2,000 people benefited · previously, 12+ hours of travel for care',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'ONG Unconnected — 10 comunidades ultra-rurales',
  'Starlink', 'Colombia', 'Amazonía', 'health',
  'La ONG Unconnected, en alianza con Starlink, conectó 10 comunidades ultra-rurales en la Amazonía colombiana para servicios de salud, beneficiando a 1.447 personas.',
  'The NGO Unconnected, in partnership with Starlink, connected 10 ultra-rural communities in the Colombian Amazon for health services, benefiting 1,447 people.',
  1447,
  '10 comunidades conectadas · 1.447 personas beneficiadas',
  '10 communities connected · 1,447 people benefited',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Telemedicina en barcos médicos de la selva amazónica',
  'Starlink', 'Perú', 'Amazonía', 'health',
  'Starlink proporciona conectividad en barcos médicos en la selva amazónica peruana, permitiendo telemedicina y consultas remotas con médicos para comunidades ribereñas de difícil acceso.',
  'Starlink provides connectivity on medical boats in the Peruvian Amazon rainforest, enabling telemedicine and remote consultations with doctors for hard-to-reach riverside communities.',
  null,
  null,
  null,
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Programa Contigo Antioquia — telesalud especializada',
  'Starlink', 'Colombia', 'Antioquia', 'health',
  'El programa Contigo Antioquia, en alianza con Starlink, capacita al personal médico en municipios remotos de Antioquia para ofrecer telesalud especializada.',
  'The Contigo Antioquia program, in partnership with Starlink, trains medical staff in remote municipalities of Antioquia to offer specialized telehealth.',
  null,
  null,
  null,
  'Starlink — Impacto en América Latina (2026)'
),

-- ---------- RESPUESTA A EMERGENCIAS ----------
(
  'Recuperación tras el Huracán Melissa',
  'Starlink', 'Jamaica', null, 'emergency_response',
  'Tras el paso del Huracán Melissa, Starlink apoyó los esfuerzos de recuperación en Jamaica donando más de 1.000 kits a organismos de respuesta de emergencia y organizaciones humanitarias como Medic Corps. Además, proporcionó servicio gratuito durante el desastre por 2 meses.',
  'Following Hurricane Melissa, Starlink supported recovery efforts in Jamaica by donating more than 1,000 kits to emergency response agencies and humanitarian organizations such as Medic Corps. It also provided free service during the disaster for 2 months.',
  null,
  '1.000+ kits donados · servicio gratuito por 2 meses',
  '1,000+ kits donated · free service for 2 months',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Respuesta a inundaciones — 56 terminales donadas',
  'Starlink', 'Colombia', null, 'emergency_response',
  'Starlink donó 56 terminales para apoyar 3 respuestas a desastres naturales relacionados con inundaciones en Colombia.',
  'Starlink donated 56 terminals to support 3 disaster-response efforts related to flooding in Colombia.',
  null,
  '56 terminales donadas · 3 respuestas a desastres',
  '56 terminals donated · 3 disaster responses',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Recuperación por inundaciones en Rio Do Sul',
  'Starlink', 'Brasil', 'Rio Do Sul', 'emergency_response',
  'Starlink entregó más de 1.000 terminales junto con servicio gratuito para asistir en la respuesta y recuperación por las graves inundaciones en Rio Do Sul.',
  'Starlink delivered more than 1,000 terminals along with free service to assist in the response and recovery from severe flooding in Rio Do Sul.',
  null,
  '1.000+ terminales · servicio gratuito',
  '1,000+ terminals · free service',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Emergencia por inundaciones en Bahía Blanca',
  'Starlink', 'Argentina', 'Bahía Blanca', 'emergency_response',
  'Starlink apoyó la respuesta de emergencia ante severas inundaciones en Bahía Blanca activando 591 cuentas gratuitas por 1 mes y donando 10 terminales más 1 mes de Roaming Ilimitado a los primeros respondedores.',
  'Starlink supported the emergency response to severe flooding in Bahía Blanca by activating 591 free accounts for 1 month and donating 10 terminals plus 1 month of Unlimited Roaming to first responders.',
  null,
  '591 cuentas gratuitas (1 mes) · 10 terminales donadas + roaming ilimitado',
  '591 free accounts (1 month) · 10 terminals donated + unlimited roaming',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Respuesta a inundaciones y deslizamientos',
  'Starlink', 'Ecuador', null, 'emergency_response',
  'Starlink donó 8 terminales para apoyar 2 respuestas a desastres naturales por inundaciones y deslizamientos en Ecuador, maximizando la conectividad de emergencia.',
  'Starlink donated 8 terminals to support 2 disaster-response efforts for flooding and landslides in Ecuador, maximizing emergency connectivity.',
  null,
  '8 terminales donadas · 2 respuestas a desastres',
  '8 terminals donated · 2 disaster responses',
  'Starlink — Impacto en América Latina (2026)'
),

-- ---------- AGRICULTURA ----------
(
  'Producción de bacanora-mezcal en un rancho de 17.000 acres',
  'Starlink', 'México', 'Sonora', 'agriculture',
  'Javier, ganadero de tercera generación, usa Starlink en su rancho de 17.000 acres en Sonora para revolucionar la producción de bacanora-mezcal. El internet de alta velocidad le permite compartir sus métodos artesanales globalmente y vender internacionalmente.',
  'Javier, a third-generation rancher, uses Starlink on his 17,000-acre ranch in Sonora to revolutionize bacanora-mezcal production. High-speed internet lets him share his artisanal methods globally and sell internationally.',
  null,
  'Rancho de 17.000 acres',
  '17,000-acre ranch',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Agricultura digital en tiempo real en la región de Bahía',
  'Starlink', 'Brasil', 'Luís Eduardo Magalhães (Bahía)', 'agriculture',
  'En Luís Eduardo Magalhães, la empresa de agricultura digital de Leonardo utiliza Starlink para dar soporte rural en tiempo real. Reemplaza los desplazamientos por respuestas rápidas a clientes y mejora la conectividad para el negocio y su familia. "Es un cambio radical. Antes tenía que manejar para tener señal y perdía negocios."',
  'In Luís Eduardo Magalhães, Leonardo''s digital agriculture company uses Starlink to provide real-time rural support. It replaces travel with fast responses to clients and improves connectivity for the business and his family. "It''s a radical change. Before, I had to drive to get signal and I was losing business."',
  null,
  'Cita: "Es un cambio radical. Antes tenía que manejar para tener señal y perdía negocios."',
  'Quote: "It''s a radical change. Before, I had to drive to get signal and I was losing business."',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'John Deere selecciona Starlink para maquinaria agrícola',
  'Starlink', 'Brasil', null, 'agriculture',
  'John Deere seleccionó Starlink en 2024 como su solución de conectividad satelital para maquinaria agrícola en zonas remotas de Brasil. Hasta la fecha, han cubierto cerca del 70% de las regiones productoras de granos sin internet confiable.',
  'John Deere selected Starlink in 2024 as its satellite connectivity solution for agricultural machinery in remote areas of Brazil. To date, they have covered nearly 70% of grain-producing regions without reliable internet.',
  null,
  '~70% de las regiones productoras de granos cubiertas',
  '~70% of grain-producing regions covered',
  'Starlink — Impacto en América Latina (2026)'
),

-- ---------- INICIATIVAS GUBERNAMENTALES ----------
(
  'Educación Misiones — 45 antenas en escuelas rurales',
  'Starlink', 'Perú', 'Provincias Rurales', 'government',
  'Educación Misiones, del Ministerio de Educación, instaló 45 antenas Starlink en escuelas rurales de Perú, beneficiando a más de 2.000 estudiantes, familias y comunidades.',
  'Educación Misiones, a Ministry of Education program, installed 45 Starlink antennas in rural schools across Peru, benefiting more than 2,000 students, families and communities.',
  2000,
  '45 antenas instaladas · 2.000+ beneficiarios',
  '45 antennas installed · 2,000+ beneficiaries',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Inversión de $6 millones para 1.500 escuelas públicas',
  'Starlink', 'El Salvador', null, 'government',
  'El Regulador y el Ministerio de Educación de El Salvador aprobaron $6 millones para conectar 1.500 escuelas públicas con internet de alta velocidad Starlink, invirtiendo $4.000 por sitio para cerrar la brecha digital.',
  'El Salvador''s Regulator and Ministry of Education approved $6 million to connect 1,500 public schools with high-speed Starlink internet, investing $4,000 per site to close the digital divide.',
  null,
  'US$6 millones aprobados · 1.500 escuelas · US$4.000 por sitio',
  'US$6 million approved · 1,500 schools · US$4,000 per site',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Conectividad de la Isla Esmeralda',
  'Starlink', 'Panamá', 'Isla Esmeralda', 'government',
  'Starlink, en alianza con UFINET, Edupan y el Ministerio de Educación, conectó la Isla Esmeralda, beneficiando a 134 estudiantes en una localidad de 524 habitantes.',
  'Starlink, in partnership with UFINET, Edupan and the Ministry of Education, connected Isla Esmeralda, benefiting 134 students in a locality of 524 inhabitants.',
  134,
  '134 estudiantes beneficiados · localidad de 524 habitantes',
  '134 students benefited · locality of 524 inhabitants',
  'Starlink — Impacto en América Latina (2026)'
),
(
  'Capacitación del Cuerpo de Bomberos de Minas Gerais',
  'Starlink', 'Brasil', 'Región Sureste (Minas Gerais)', 'government',
  'El Cuerpo de Bomberos de Minas Gerais capacitó a 306 bomberos (174 militares y 132 civiles) para combatir incendios forestales utilizando Starlink para monitoreo en tiempo real y protección de vidas y el medio ambiente.',
  'The Minas Gerais Fire Department trained 306 firefighters (174 military and 132 civilian) to fight forest fires using Starlink for real-time monitoring and the protection of lives and the environment.',
  null,
  '306 bomberos capacitados (174 militares + 132 civiles)',
  '306 firefighters trained (174 military + 132 civilian)',
  'Starlink — Impacto en América Latina (2026)'
);
