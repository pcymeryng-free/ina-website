-- ============================================================================
-- Backfill EN: traducción al inglés de los 6 análisis de
-- data_ai_analysis_all_projects.sql
-- ============================================================================
--
-- QUÉ HACE ESTE SCRIPT
-- Completa las 4 columnas nuevas de migration_v40_bilingual_analysis.sql
-- (dimensions_en, gap_roadmap_en, financing_recommendations_en,
-- summary_en) para los 6 framework_analysis ya cargados en
-- data_ai_analysis_all_projects.sql. No inserta filas nuevas — son 6
-- UPDATE, uno por proyecto, localizados por project_id + source='ai'.
--
-- Los rationale de cada dimensión y el summary son traducción fiel (no
-- literal palabra por palabra) del texto en español ya cargado. Los
-- textos de gap_roadmap_en y financing_recommendations_en son las mismas
-- frases exactas en inglés de RECOMMENDATION_TIPS / STAGE_FINANCING_
-- SUGGESTION / USF_SUGGESTION en assets/platform.js — igual criterio que
-- se usó para las versiones en español.
--
-- REQUISITOS: correr data_ai_analysis_all_projects.sql y
-- migration_v40_bilingual_analysis.sql antes que este script.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Proyecto Cruce Transandino (Andean Crossing Project)
-- ----------------------------------------------------------------------------
update public.framework_analysis
set
  dimensions_en =
$dims_en${"legal_regulatory": {"score": 45, "rationale": "The document doesn't confirm the status of binational (Argentina-Chile) permits for the Andean crossing or the rights-of-way across the 21 segments; there's a defined route path but no evidence of finalized approvals."}, "technical_maturity": {"score": 80, "rationale": "Advanced, specific technical design: 4 HDPE ducts, 144-fiber G.652D cable, initial capacity of 2.4 Tbps across 1,170 km in Argentina (2,300 km total route)."}, "financial_robustness": {"score": 35, "rationale": "No financial model (CAPEX/OPEX, revenue projections) is documented for the Argentine segment in the available source."}, "sponsor_capacity": {"score": 85, "rationale": "Cirion Technologies is a telecommunications infrastructure operator with an established track record in the region, already operating international fiber networks."}, "market_demand": {"score": 50, "rationale": "Demand for transandean capacity and 20+ benefited localities are mentioned, but no anchor customers or letters of intent are documented."}, "environmental_social": {"score": 20, "rationale": "No environmental and social impact assessment or community consultation is documented along the route."}, "risk_mitigation": {"score": 30, "rationale": "No risk register or mitigation mechanisms (technical, financial, currency) are identified in the source."}, "governance_reporting": {"score": 25, "rationale": "No governance structures or reporting/monitoring mechanisms for the project are documented."}, "rollout_readiness": {"score": 55, "rationale": "The route is already segmented into 21 stretches with an H2 2026–H2 2028 schedule, but closure of right-of-way agreements for each stretch isn't confirmed."}}$dims_en$::jsonb,
  gap_roadmap_en =
$gap_en$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "medium", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "medium", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}]$gap_en$::jsonb,
  financing_recommendations_en =
$fin_en$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$fin_en$::jsonb,
  summary_en =
$sum_en$Readiness score 47/100 (Early Structuring). The project combines high technical maturity (a 21-segment route, 144-fiber G.652D cable, 2.4 Tbps of initial capacity) with a sponsor with a proven track record (Cirion Technologies), but it still lacks a documented financial model, an environmental and social impact assessment, and a risk register — typical gaps for an international crossing that hasn't yet closed its binational permits. Priority focus: environmental and social readiness.$sum_en$
where project_id = (select id from public.projects
     where name = 'Proyecto Cruce Transandino (Andean Crossing Project)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

-- ----------------------------------------------------------------------------
-- Red Federal de Centros Regionales de IA y Datos
-- ----------------------------------------------------------------------------
update public.framework_analysis
set
  dimensions_en =
$dims_en${"legal_regulatory": {"score": 25, "rationale": "It's an institutional proposal submitted to ENACOM, but no permits, land-use approvals, or specific licenses are documented for the proposed nodes."}, "technical_maturity": {"score": 40, "rationale": "Defines initial parameters (edge/micro datacenter, forced-air cooling, sub-1 MW scale) but without vendor selection or concrete server specifications."}, "financial_robustness": {"score": 20, "rationale": "No financial model (CAPEX/OPEX, capital structure) is documented for any of the three proposed deployment stages."}, "sponsor_capacity": {"score": 25, "rationale": "CAPPI is a chamber that groups small Internet providers, with no documented track record building or operating datacenters."}, "market_demand": {"score": 30, "rationale": "Regional demand for cloud/AI computing is projected, but there are no institutional or corporate customers with signed commitments."}, "environmental_social": {"score": 15, "rationale": "No environmental and social impact assessment is documented for the proposed nodes."}, "risk_mitigation": {"score": 15, "rationale": "No risk register or mitigation mechanisms are identified in the proposal."}, "governance_reporting": {"score": 30, "rationale": "The 3-stage phased plan (10-ISP pilot at 12 months, 50 nodes at 24 months, 100+ nodes at 60 months) provides some milestone structure, but without defined governance or reporting."}, "power_cooling_readiness": {"score": 30, "rationale": "The cooling type is defined (forced air) but there's no contracted or secured power supply capacity for any node."}}$dims_en$::jsonb,
  gap_roadmap_en =
$gap_en$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Strengthen the sponsor's track record documentation or bring in an experienced co-sponsor/EPC partner."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}]$gap_en$::jsonb,
  financing_recommendations_en =
$fin_en$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$fin_en$::jsonb,
  summary_en =
$sum_en$Readiness score 26/100 (Early Structuring, right at the boundary with Concept Stage). The proposal defines a 3-stage deployment plan (a 10-ISP pilot, 50 nodes, 100+ nodes) and initial technical parameters, but as an institutional initiative from an ISP chamber — not an individual operator with a datacenter track record — it still lacks a financial model, an environmental/social assessment, and contracted power supply capacity. Priority focus: environmental and social readiness, and risk mitigation.$sum_en$
where project_id = (select id from public.projects
     where name = 'Red Federal de Centros Regionales de IA y Datos'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

-- ----------------------------------------------------------------------------
-- Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal
-- ----------------------------------------------------------------------------
update public.framework_analysis
set
  dimensions_en =
$dims_en${"legal_regulatory": {"score": 45, "rationale": "It's a regulatory-framework proposal that explicitly references Colombia's and Brazil's shared-access regimes as models — a solid conceptual basis, though no Argentine regulatory instrument has been enacted yet."}, "technical_maturity": {"score": 10, "rationale": "No technical design applies here: it's a policy/regulatory proposal, not an infrastructure build with technical specifications."}, "financial_robustness": {"score": 10, "rationale": "No financial model is documented — the proposal doesn't involve CAPEX/OPEX for a specific build."}, "sponsor_capacity": {"score": 20, "rationale": "CAPPI acts as an institutional/policy-advocacy driver, not an infrastructure executor, so a construction-capacity assessment doesn't apply."}, "market_demand": {"score": 40, "rationale": "Identifies multiple interested stakeholders in shared access (electric cooperatives, provincial distributors, SMEs, regional operators, public agencies), which supports demand for the proposed framework."}, "environmental_social": {"score": 10, "rationale": "A direct environmental and social assessment doesn't apply, since this is a regulatory proposal."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented for implementing the proposed framework."}, "governance_reporting": {"score": 25, "rationale": "The proposal outlines institutional roles in general terms, but without a specific governance or reporting mechanism defined."}, "type_specific_readiness": {"score": 25, "rationale": "The specific technical requirements of a shared-access implementation (asset inventory, tariff methodology) still haven't been developed for the Argentine case."}}$dims_en$::jsonb,
  gap_roadmap_en =
$gap_en$[{"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Strengthen the sponsor's track record documentation or bring in an experienced co-sponsor/EPC partner."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}]$gap_en$::jsonb,
  financing_recommendations_en =
$fin_en$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$fin_en$::jsonb,
  summary_en =
$sum_en$Readiness score 22/100 (Concept Stage). It's a regulatory-framework proposal — not a physical build — modeled on Colombia's and Brazil's regimes; its strongest point is conceptual regulatory clarity and the range of interested stakeholders identified, but since it isn't an infrastructure project, no technical design, financial model, or environmental assessment applies to it. Priority focus: project-specific technical maturity.$sum_en$
where project_id = (select id from public.projects
     where name = 'Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

-- ----------------------------------------------------------------------------
-- Plan Argentina Digital Federal 2040 - Corredores Digitales Ferroviarios
-- ----------------------------------------------------------------------------
update public.framework_analysis
set
  dimensions_en =
$dims_en${"legal_regulatory": {"score": 45, "rationale": "Builds on existing railway easements and routes (a real advantage for land access), but no formal agreement with the railway authority or corridor-specific permits are documented."}, "technical_maturity": {"score": 55, "rationale": "Defines concrete technical options (96/144/288-fiber cables, DWDM compatibility) across different capacity scenarios."}, "financial_robustness": {"score": 15, "rationale": "No financial model or budget is documented for the proposed national backbone rollout."}, "sponsor_capacity": {"score": 20, "rationale": "It's an institutional CAPPI proposal, without an individual executing sponsor with a track record of national-scale backbone rollout."}, "market_demand": {"score": 45, "rationale": "Positioned as a complement to the REFEFO and mentions municipalities and localities along the railway routes as potential beneficiaries, without formal demand studies."}, "environmental_social": {"score": 20, "rationale": "No environmental and social impact assessment is documented, though using existing railway routes could reduce impact relative to a new route."}, "risk_mitigation": {"score": 15, "rationale": "No risk register is identified for the proposed rollout."}, "governance_reporting": {"score": 20, "rationale": "No governance structures or reporting mechanisms are defined for executing the plan."}, "rollout_readiness": {"score": 40, "rationale": "Pre-existing railway easements ease access to the route, but the last-mile distribution and customer-connection strategy for each corridor isn't detailed."}}$dims_en$::jsonb,
  gap_roadmap_en =
$gap_en$[{"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Strengthen the sponsor's track record documentation or bring in an experienced co-sponsor/EPC partner."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "medium", "action": "Lock down right-of-way and duct/pole access agreements before finalizing the rollout schedule."}]$gap_en$::jsonb,
  financing_recommendations_en =
$fin_en$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$fin_en$::jsonb,
  summary_en =
$sum_en$Readiness score 31/100 (Early Structuring). It leverages railway easements and routes that already exist nationwide (a real advantage for land access) and defines 96/144/288-fiber technical options compatible with DWDM, but — like other institutional CAPPI proposals — it still lacks a financial model, an environmental/social assessment, and an individual executing sponsor with a track record. Priority focus: financial robustness.$sum_en$
where project_id = (select id from public.projects
     where name = 'Plan Argentina Digital Federal 2040 - Corredores Digitales Ferroviarios'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

-- ----------------------------------------------------------------------------
-- Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta
-- ----------------------------------------------------------------------------
update public.framework_analysis
set
  dimensions_en =
$dims_en${"legal_regulatory": {"score": 70, "rationale": "CEPA is an already-regulated electric cooperative that provides telecommunications services — the technical file reports no pending legal disputes or regulatory uncertainty."}, "technical_maturity": {"score": 85, "rationale": "Detailed GPON technical design with specific equipment (Huawei MA5800-X7/EA5800-X7 OLT/ONT, Furukawa fiber and hardware, 1:64 splitters)."}, "financial_robustness": {"score": 65, "rationale": "Investment budget broken down by category (USD 457,780.07 / ARS $650,047,693.72) with an identified funding source (a Banco Nación credit line plus own funds), though without documented revenue/tariff projections or stress tests."}, "sponsor_capacity": {"score": 80, "rationale": "CEPA already operates an existing HFC/FTTH network — a proven track record as a service provider, not a new sponsor with no history."}, "market_demand": {"score": 75, "rationale": "Reports 13,500 households as a concrete subscriber base migrating from HFC to FTTH — demonstrated demand, not projected."}, "environmental_social": {"score": 30, "rationale": "No formal environmental and social impact assessment or community consultation is documented in the technical file."}, "risk_mitigation": {"score": 25, "rationale": "No formal risk register or mitigation mechanisms are documented in the technical file."}, "governance_reporting": {"score": 40, "rationale": "As a regulated cooperative there's statutory governance (a member assembly), but the technical file doesn't document specific reporting/monitoring mechanisms for this project."}, "rollout_readiness": {"score": 75, "rationale": "Equipment already specified and the project divided into 4 stages, building on an existing HFC network — high deployment readiness."}}$dims_en$::jsonb,
  gap_roadmap_en =
$gap_en$[{"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "medium", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "low", "action": "Build or refine a stress-tested financial model backed by real market data."}]$gap_en$::jsonb,
  financing_recommendations_en =
$fin_en$[{"mechanism": "Universal Service Funds", "rationale": "This project reports a concrete number of beneficiaries reached in an underserved area — a strong fit for a national Universal Service Fund's subsidized-rate credit or grant line (e.g. ENACOM's Fondo de Servicio Universal in Argentina)."}, {"mechanism": "Public-Private Partnerships", "rationale": "Advanced-structuring projects are often well positioned for a PPP structure once remaining gaps are closed."}]$fin_en$::jsonb,
  summary_en =
$sum_en$Readiness score 61/100 (Advanced Structuring) — the highest of the six projects loaded. It's the only technical file from an operator already in operation (Cooperativa Eléctrica de Punta Alta), with a detailed GPON technical design, an itemized investment budget (USD 457,780.07), and a Banco Nación credit line already identified as a funding source — it also reports 13,500 concrete beneficiary households, which qualifies it for the Universal Service Fund. The main gaps are the lack of a formal risk register and a documented environmental and social impact assessment. Priority focus: risk mitigation coverage.$sum_en$
where project_id = (select id from public.projects
     where name = 'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

-- ----------------------------------------------------------------------------
-- Patagonia - Hub de Infraestructura de IA para el Sur Global
-- ----------------------------------------------------------------------------
update public.framework_analysis
set
  dimensions_en =
$dims_en${"legal_regulatory": {"score": 30, "rationale": "Mentions the RIGI regime (30-year regulatory stability) as a general enabling framework, but no RIGI benefit has been requested or approved for a specific project; the document itself flags macroeconomic instability and exchange controls as an open regulatory risk."}, "technical_maturity": {"score": 35, "rationale": "Provides industry benchmark parameters (PUE 1.15-1.25, DLC cooling, 50-200 kW/rack density) as targets, but without a specific technical design for a site chosen among the three candidate corridors."}, "financial_robustness": {"score": 20, "rationale": "Only presents comparative industry CAPEX/OPEX ranges (USD 4-8M/MW, USD 15-30/MWh) — there's no project-specific financial model or defined capital structure."}, "sponsor_capacity": {"score": 10, "rationale": "There's no named executing sponsor: Ciena Corporation is a networking-equipment manufacturer publishing the opportunity analysis, not a developer or investor committed to the build."}, "market_demand": {"score": 25, "rationale": "Qualitatively describes a target audience (global cloud/AI operators seeking non-aligned jurisdictions) without anchor customers or letters of intent."}, "environmental_social": {"score": 5, "rationale": "No environmental and social impact assessment is documented for any of the three candidate corridors."}, "risk_mitigation": {"score": 45, "rationale": "The most developed point in the document: an explicit map of risks and enablers across 5 categories (energy, connectivity, regulatory, logistics, talent) with identified mitigants for each."}, "governance_reporting": {"score": 5, "rationale": "No governance structures or reporting mechanisms are documented — consistent with the document being an opportunity analysis, not the file of a project under execution."}, "power_cooling_readiness": {"score": 30, "rationale": "Defines a cooling approach (DLC, humidity-independent) and an energy-mix strategy (wind + gas + future storage) at a conceptual level, but without contracted power supply for any specific site."}}$dims_en$::jsonb,
  gap_roadmap_en =
$gap_en$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Strengthen the sponsor's track record documentation or bring in an experienced co-sponsor/EPC partner."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}]$gap_en$::jsonb,
  financing_recommendations_en =
$fin_en$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$fin_en$::jsonb,
  summary_en =
$sum_en$Readiness score 23/100 (Concept Stage). It's a strategic opportunity analysis from a technology vendor (Ciena Corporation), not the file of a project with an executing sponsor, a single site, or a committed budget: it evaluates three candidate corridors (Neuquén-Cipolletti, Puerto Madryn-Comodoro, Río Grande-Ushuaia) using industry benchmark parameters rather than a site-specific design. Its risk-and-enablers map (energy, connectivity, regulatory, logistics, talent) is, paradoxically, the most developed aspect of the document. Priority focus: governance and reporting.$sum_en$
where project_id = (select id from public.projects
     where name = 'Patagonia - Hub de Infraestructura de IA para el Sur Global'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

-- ============================================================================
-- Verificación
-- ============================================================================
select
  p.name,
  fa.summary_en is not null as has_summary_en,
  fa.dimensions_en is not null as has_dimensions_en,
  fa.gap_roadmap_en is not null as has_gap_en,
  fa.financing_recommendations_en is not null as has_fin_en
from public.projects p
join public.framework_analysis fa on fa.project_id = p.id
where p.user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')
  and fa.source = 'ai'
  and p.name in (
    'Proyecto Cruce Transandino (Andean Crossing Project)',
    'Red Federal de Centros Regionales de IA y Datos',
    'Programa Nacional de Infraestructura Compartida y Acceso Abierto para el Desarrollo Digital Federal',
    'Plan Argentina Digital Federal 2040 - Corredores Digitales Ferroviarios',
    'Finalizacion de Despliegue FTTH y Migracion HFC-FTTH - Cooperativa Electrica de Punta Alta',
    'Patagonia - Hub de Infraestructura de IA para el Sur Global'
  )
order by p.name;
