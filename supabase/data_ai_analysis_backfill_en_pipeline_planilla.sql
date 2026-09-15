-- ============================================================================
-- Backfill EN: traduccion al ingles de los 18 analisis de
-- data_ai_analysis_pipeline_planilla.sql
-- ============================================================================
-- Mismo criterio que los backfills anteriores (all_projects, alertar) --
-- completa dimensions_en/gap_roadmap_en/financing_recommendations_en/
-- summary_en (migration_v40_bilingual_analysis.sql) con una traduccion
-- fiel al ingles del analisis ya cargado para los 18 proyectos de la
-- planilla de pipeline (Atlantico-Pacifico, PUMA, Bioceanico Norte, CALF,
-- Internet Service, ARSAT x3, Starlink, ENACOM x3, YPF, Telcos).
--
-- REQUISITOS: correr data_ai_analysis_pipeline_planilla.sql y
-- migration_v40_bilingual_analysis.sql antes que este script.
-- ============================================================================

update public.framework_analysis
set
  dimensions_en =
$t0dims${"legal_regulatory": {"score": 20, "rationale": "No permits or authorizations are documented for the route; the source spreadsheet doesn't clarify the status of right-of-way."}, "technical_maturity": {"score": 30, "rationale": "The route is defined as following EPECH's power line, but fiber count, capacity, and vendor are not specified."}, "financial_robustness": {"score": 10, "rationale": "No dedicated budget is reported for this segment in the source spreadsheet."}, "sponsor_capacity": {"score": 55, "rationale": "EPECH is a provincial power utility with real, operating power-transmission infrastructure, though with no documented track record as a telecommunications operator."}, "market_demand": {"score": 20, "rationale": "No anchor customers or demand studies are documented for this specific segment."}, "environmental_social": {"score": 10, "rationale": "No environmental and social impact assessment is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is identified."}, "governance_reporting": {"score": 15, "rationale": "No project-specific governance or reporting mechanisms are documented."}, "rollout_readiness": {"score": 30, "rationale": "Leveraging the existing power line route is a real access advantage, but no timeline or confirmed right-of-way agreements exist."}}$t0dims$::jsonb,
  gap_roadmap_en =
$t0gap$[{"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}]$t0gap$::jsonb,
  financing_recommendations_en =
$t0fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t0fin$::jsonb,
  summary_en =
$t0sum$Readiness score 22/100 (Concept Stage). The segment leverages EPECH's power-transmission line route as a real access advantage, but the source spreadsheet reports no dedicated budget, environmental assessment, or risk register for this component. Priority focus: financial model robustness.$t0sum$
where project_id = (select id from public.projects
     where name = 'Atlántico-Pacífico — Troncal FO Región Andina (Futaleufú)-Trelew'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t1dims${"legal_regulatory": {"score": 15, "rationale": "Crosses the Andes into Chile; no binational permits or right-of-way agreements are documented in either country."}, "technical_maturity": {"score": 25, "rationale": "The distance (500 km) and route are known, but there's no cable specification or vendor."}, "financial_robustness": {"score": 25, "rationale": "The spreadsheet reports a range of USD 35M to 60M (the midpoint was loaded into budget_amount_usd), but with no financial model or capital structure."}, "sponsor_capacity": {"score": 50, "rationale": "EPECH brings real transmission-infrastructure experience, though not in international fiber deployments."}, "market_demand": {"score": 20, "rationale": "No demand studies or anchor customers are documented for the cross-Andes segment."}, "environmental_social": {"score": 10, "rationale": "The mountain crossing raises real environmental considerations that aren't addressed in the source."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 15, "rationale": "No governance structures are defined for this segment."}, "rollout_readiness": {"score": 25, "rationale": "The status of the binational right-of-way agreements needed to advance the timeline is not confirmed."}}$t1dims$::jsonb,
  gap_roadmap_en =
$t1gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}]$t1gap$::jsonb,
  financing_recommendations_en =
$t1fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t1fin$::jsonb,
  summary_en =
$t1sum$Readiness score 22/100 (Concept Stage). This is a cross-border segment (Argentina-Chile) with a budget estimate (USD 47.5M, the midpoint of the reported range) but no documented binational permits, environmental assessment, or risk register. Priority focus: environmental and social readiness.$t1sum$
where project_id = (select id from public.projects
     where name = 'Atlántico-Pacífico — Tramo Terrestre Esquel-Chaitén-Puerto Montt'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t2dims${"legal_regulatory": {"score": 15, "rationale": "A submarine cable with landing stations in two countries requires maritime and telecommunications authorizations in both jurisdictions, none of which are documented."}, "technical_maturity": {"score": 20, "rationale": "Only the distance (1,500 km) is known; there's no cable system specification, capacity, or landing stations."}, "financial_robustness": {"score": 25, "rationale": "The spreadsheet reports a range of USD 120M to 180M (the midpoint was loaded), with no financial model."}, "sponsor_capacity": {"score": 30, "rationale": "EPECH is a provincial power utility with no documented track record in submarine cables, a project type that typically requires a specialized operator."}, "market_demand": {"score": 20, "rationale": "No anchor customers or capacity commitments are documented for the international gateway."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment of the marine works is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 15, "rationale": "No governance structures are defined."}, "route_feasibility": {"score": 15, "rationale": "No marine route survey or landing site selection is documented."}}$t2dims$::jsonb,
  gap_roadmap_en =
$t2gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Complete the marine route survey and secure landing station permits early — these have long lead times."}, {"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}]$t2gap$::jsonb,
  financing_recommendations_en =
$t2fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t2fin$::jsonb,
  summary_en =
$t2sum$Readiness score 18/100 (Concept Stage), the lowest of the five Atlantic-Pacific corridor components. This is the component that departs most from its sponsor's profile (EPECH, a power utility with no submarine-cable track record), and it lacks a marine route survey, binational permits, and a financial model. Priority focus: environmental and social readiness.$t2sum$
where project_id = (select id from public.projects
     where name = 'Atlántico-Pacífico — Cable Submarino Trelew (AR)-Punta del Este (UY)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t3dims${"legal_regulatory": {"score": 15, "rationale": "No land-use authorizations or specific licenses are documented for the two proposed sites."}, "technical_maturity": {"score": 35, "rationale": "Setting Tier IV as the target standard is a concrete technical data point, but there's no site design, hardware vendor, or server specifications."}, "financial_robustness": {"score": 25, "rationale": "The spreadsheet reports a range of USD 110M to 160M (the midpoint was loaded), with no funding structure."}, "sponsor_capacity": {"score": 40, "rationale": "EPECH brings real power-infrastructure management experience — relevant for a data center — but with no track record operating data centers."}, "market_demand": {"score": 15, "rationale": "No compute/AI customers or capacity commitments are documented."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 15, "rationale": "No governance structures are defined."}, "power_cooling_readiness": {"score": 25, "rationale": "EPECH's background as a power utility is a potential advantage for this specific dimension, but no contracted power capacity or cooling design is documented."}}$t3dims$::jsonb,
  gap_roadmap_en =
$t3gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}]$t3gap$::jsonb,
  financing_recommendations_en =
$t3fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t3fin$::jsonb,
  summary_en =
$t3sum$Readiness score 21/100 (Concept Stage). The Tier IV target standard and EPECH's power-sector background are relevant starting points, but the component lacks a site design, contracted power capacity, and a financial model. Priority focus: environmental and social readiness.$t3sum$
where project_id = (select id from public.projects
     where name = 'Atlántico-Pacífico — Datacenter Tier IV en Tándem (2 sedes) + HW IA'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t4dims${"legal_regulatory": {"score": 15, "rationale": "No civil works permits or authorizations are documented for the landing works."}, "technical_maturity": {"score": 20, "rationale": "There's no detailed engineering for the civil works or the contingency component."}, "financial_robustness": {"score": 25, "rationale": "The spreadsheet reports a range of USD 40M to 70M (the midpoint was loaded), with no cost breakdown."}, "sponsor_capacity": {"score": 45, "rationale": "EPECH has real civil-works execution capacity as a provincial infrastructure utility."}, "market_demand": {"score": 15, "rationale": "Demand for this component depends entirely on the rest of the corridor; there's no standalone assessment."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment of the landing works is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk or contingency register is documented, despite the component being named 'contingency' itself."}, "governance_reporting": {"score": 15, "rationale": "No governance structures are defined."}, "shared_access_readiness": {"score": 15, "rationale": "No asset inventory or shared-access agreements are documented."}}$t4dims$::jsonb,
  gap_roadmap_en =
$t4gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Complete the asset inventory and formalize access/sharing agreements (or the regulatory path to them) with each infrastructure owner before committing to a deployment timeline."}]$t4gap$::jsonb,
  financing_recommendations_en =
$t4fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t4fin$::jsonb,
  summary_en =
$t4sum$Readiness score 19/100 (Concept Stage). This is supporting infrastructure for the Atlantic-Pacific corridor, with no detailed engineering or standalone risk register despite being named as the contingency component. Priority focus: environmental and social readiness.$t4sum$
where project_id = (select id from public.projects
     where name = 'Atlántico-Pacífico — Amarre: Obra Civil y Contingencia'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t5dims${"legal_regulatory": {"score": 10, "rationale": "No regulatory or permitting progress is documented for the landing stations in Argentina or South Africa."}, "technical_maturity": {"score": 10, "rationale": "The spreadsheet description is explicit that there's no technology, budget, or timeline detailed yet."}, "financial_robustness": {"score": 5, "rationale": "No budget figure or funding source is documented at all."}, "sponsor_capacity": {"score": 60, "rationale": "Etisalat is a large-scale international telecommunications operator with a real track record deploying infrastructure — a heavyweight sponsor despite the lack of detail on the project itself."}, "market_demand": {"score": 15, "rationale": "The Argentina-South Africa route suggests a strategic South-South connectivity intent, with no demand studies documented."}, "environmental_social": {"score": 5, "rationale": "No environmental assessment is documented at all."}, "risk_mitigation": {"score": 5, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 10, "rationale": "No governance structures are documented."}, "route_feasibility": {"score": 5, "rationale": "No marine route survey or identified landing sites exist."}}$t5dims$::jsonb,
  gap_roadmap_en =
$t5gap$[{"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Complete the marine route survey and secure landing station permits early — these have long lead times."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}]$t5gap$::jsonb,
  financing_recommendations_en =
$t5fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t5fin$::jsonb,
  summary_en =
$t5sum$Readiness score 14/100 (Concept Stage) — the most notable data point is that the sponsor, Etisalat, is an international telecommunications operator with a real track record in large-scale deployments; however, the source spreadsheet is explicit that the project itself doesn't yet have defined technology, budget, or timeline. Priority focus: financial model robustness.$t5sum$
where project_id = (select id from public.projects
     where name = 'Cable Submarino PUMA (Argentina-Sudáfrica)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t6dims${"legal_regulatory": {"score": 15, "rationale": "No permits for the Jama border crossing or local authorizations are documented."}, "technical_maturity": {"score": 15, "rationale": "There's no technology or vendor specification, beyond the wholesale purpose."}, "financial_robustness": {"score": 5, "rationale": "No budget or funding source is reported."}, "sponsor_capacity": {"score": 25, "rationale": "Comtec is a regional operator with no documented track record in the available source."}, "market_demand": {"score": 35, "rationale": "Naming 20 towns in Salta and mining complexes as beneficiaries is a concrete demand data point, though without formal studies or letters of intent."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 10, "rationale": "No governance structures are documented."}, "rollout_readiness": {"score": 15, "rationale": "No timeline or right-of-way agreements are documented for the corridor toward Chile."}}$t6dims$::jsonb,
  gap_roadmap_en =
$t6gap$[{"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}]$t6gap$::jsonb,
  financing_recommendations_en =
$t6fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t6fin$::jsonb,
  summary_en =
$t6sum$Readiness score 16/100 (Concept Stage). Naming 20 towns and mining complexes as beneficiaries is the proposal's strongest data point, but no budget, technology, or risk register is documented. Priority focus: financial model robustness.$t6sum$
where project_id = (select id from public.projects
     where name = 'Tramo Bioceánico Norte (Salta)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t7dims${"legal_regulatory": {"score": 20, "rationale": "No specific permits for the ring are documented, beyond CALF's regulated status as a cooperative."}, "technical_maturity": {"score": 35, "rationale": "Nokia as the technology vendor is a concrete data point, but there's no network topology design or dimensioning."}, "financial_robustness": {"score": 40, "rationale": "The USD 100M budget and a concrete funding mechanism (corporate bond) are two real financial signals — more advanced than a mere estimate, though without a complete financial model."}, "sponsor_capacity": {"score": 55, "rationale": "CALF is an Alto Valle electric cooperative with a real, established track record in the region."}, "market_demand": {"score": 20, "rationale": "No demand studies or committed wholesale customers are documented."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment is documented."}, "risk_mitigation": {"score": 15, "rationale": "No formal risk register is documented, though having a corporate bond already implies some prior financial scrutiny."}, "governance_reporting": {"score": 20, "rationale": "As a cooperative, CALF has a statutory governance structure, though no project-specific reporting mechanisms are documented."}, "neutrality_interconnection_readiness": {"score": 15, "rationale": "No REFEFO interconnection or network-sharing (RAN sharing) scheme is documented."}}$t7dims$::jsonb,
  gap_roadmap_en =
$t7gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Finalize the network topology/dimensioning design and secure REFEFO interconnection and a network-sharing (RAN sharing) scheme — these are the criteria ENACOM weighs most heavily for Red Mayorista Neutral eligibility."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}]$t7gap$::jsonb,
  financing_recommendations_en =
$t7fin$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$t7fin$::jsonb,
  summary_en =
$t7sum$Readiness score 26/100 (Early Structuring) — the highest among the spreadsheet's new projects. CALF is a cooperative with a real track record, defined Nokia technology, a reported budget, and a concrete funding mechanism (corporate bond), but still without an environmental assessment, risk register, or REFEFO interconnection scheme. Priority focus: environmental and social readiness.$t7sum$
where project_id = (select id from public.projects
     where name = 'CALF — Anillo Mayorista de Fibra Óptica (Neuquén)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t8dims${"legal_regulatory": {"score": 15, "rationale": "No permits or authorizations are documented for the wholesale network."}, "technical_maturity": {"score": 25, "rationale": "Nokia as the technology vendor is a concrete data point, but with no topology design or dimensioning."}, "financial_robustness": {"score": 15, "rationale": "A funding mechanism (corporate bond) is noted but with no amount or total budget documented."}, "sponsor_capacity": {"score": 20, "rationale": "Internet Service is an operator with no documented track record in the available source."}, "market_demand": {"score": 15, "rationale": "No demand studies or wholesale customers are documented."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 10, "rationale": "No governance structures are documented."}, "neutrality_interconnection_readiness": {"score": 10, "rationale": "No REFEFO interconnection or network-sharing scheme is documented."}}$t8dims$::jsonb,
  gap_roadmap_en =
$t8gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Finalize the network topology/dimensioning design and secure REFEFO interconnection and a network-sharing (RAN sharing) scheme — these are the criteria ENACOM weighs most heavily for Red Mayorista Neutral eligibility."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}]$t8gap$::jsonb,
  financing_recommendations_en =
$t8fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t8fin$::jsonb,
  summary_en =
$t8sum$Readiness score 14/100 (Concept Stage). Unlike CALF, this Entre Ríos wholesale network notes a funding mechanism (corporate bond) but with no amount, total budget, or documented sponsor track record. Priority focus: environmental and social readiness.$t8sum$
where project_id = (select id from public.projects
     where name = 'Internet Service — Red Mayorista de Fibra Óptica (Entre Ríos)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t9dims${"legal_regulatory": {"score": 40, "rationale": "Since this modernizes a network already operated by ARSAT under its existing regulatory framework, permitting risk is lower than for a new deployment, though no specific authorizations for this renewal are documented."}, "technical_maturity": {"score": 45, "rationale": "Nokia and Ciena as vendors, and the fact that this is an upgrade to an already-built, operating backbone network, provide a concrete technical foundation."}, "financial_robustness": {"score": 30, "rationale": "A USD 100M budget is reported, but with no documented funding structure or model."}, "sponsor_capacity": {"score": 70, "rationale": "ARSAT is Argentina's state telecommunications company, with a real, operating national fiber network (REFEFO) — the sponsor with the strongest proven track record in this batch."}, "market_demand": {"score": 35, "rationale": "REFEFO already serves real nationwide demand; the modernization addresses an existing need, not a projected one."}, "environmental_social": {"score": 15, "rationale": "Since this is an upgrade to an existing network, the incremental environmental impact is presumably lower than a new deployment, though no assessment is documented."}, "risk_mitigation": {"score": 15, "rationale": "No risk register is documented for this specific renewal."}, "governance_reporting": {"score": 25, "rationale": "As a state-owned company, ARSAT has inherent institutional oversight, though no project-specific reporting mechanisms are documented."}, "rollout_readiness": {"score": 40, "rationale": "Modernizing an already-deployed network is a real execution advantage over a greenfield project, though no specific timeline is documented."}}$t9dims$::jsonb,
  gap_roadmap_en =
$t9gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "medium", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}]$t9gap$::jsonb,
  financing_recommendations_en =
$t9fin$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$t9fin$::jsonb,
  summary_en =
$t9sum$Readiness score 35/100 (Early Structuring). ARSAT is the sponsor with the strongest proven track record among the spreadsheet's new projects — it operates REFEFO, the already-existing national fiber network — and this is a technology modernization built on that base, not a from-scratch deployment. Even so, a financial model, risk register, and environmental assessment are still missing. Priority focus: environmental and social readiness.$t9sum$
where project_id = (select id from public.projects
     where name = 'ARSAT — Modernización REFEFO (Renovación Tecnológica)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t10dims${"legal_regulatory": {"score": 35, "rationale": "As a state-owned company, ARSAT operates under the existing spectrum regulatory framework, though no specific 5G spectrum allocation is documented for this plan."}, "technical_maturity": {"score": 35, "rationale": "Nokia as the vendor and a phased plan (100 of 1,000 localities in the first stage) are concrete data points, with no site-specific engineering."}, "financial_robustness": {"score": 35, "rationale": "Two funding figures are reported (USD 100M total budget and USD 15M from FSU), more advanced than a single isolated estimate."}, "sponsor_capacity": {"score": 65, "rationale": "ARSAT has a real track record as a national telecommunications operator."}, "market_demand": {"score": 30, "rationale": "1,000 target localities is a concrete scale target, though without confirmed sites or formal demand studies."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 20, "rationale": "No plan-specific reporting mechanisms are documented."}, "spectrum_site_readiness": {"score": 20, "rationale": "No confirmed spectrum allocation or line-of-sight studies for the sites are documented."}}$t10dims$::jsonb,
  gap_roadmap_en =
$t10gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Secure spectrum allocation and complete line-of-sight studies before committing to a deployment timeline."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}]$t10gap$::jsonb,
  financing_recommendations_en =
$t10fin$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$t10fin$::jsonb,
  summary_en =
$t10sum$Readiness score 29/100 (Early Structuring). ARSAT's plan defines a scale target (1,000 localities, with a first phase of 100) and two funding figures (total budget and FSU amount), but lacks confirmed spectrum allocation, an environmental assessment, and a risk register. Priority focus: environmental and social readiness.$t10sum$
where project_id = (select id from public.projects
     where name = 'ARSAT — Plan FWA 5G (1.000 localidades, 1a fase 100 localidades)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t11dims${"legal_regulatory": {"score": 30, "rationale": "ARSAT operates under an existing state framework, but no specific authorizations are documented for the 25 proposed sites."}, "technical_maturity": {"score": 30, "rationale": "The mini-edge/container format and the Oracle partnership are concrete technical data points, with no per-site specifications."}, "financial_robustness": {"score": 20, "rationale": "Only the FSU amount (USD 25M) is reported — no total project budget is documented."}, "sponsor_capacity": {"score": 70, "rationale": "The combination of ARSAT (a state operator with a real track record) and Oracle (a top-tier global technology vendor) is the strongest joint sponsor in this batch."}, "market_demand": {"score": 20, "rationale": "No compute/AI customers or capacity commitments are documented for the 25 sites."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 20, "rationale": "No governance mechanisms specific to the joint initiative are documented."}, "power_cooling_readiness": {"score": 15, "rationale": "No contracted power capacity or cooling design is documented for any of the 25 sites."}}$t11dims$::jsonb,
  gap_roadmap_en =
$t11gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Contract power capacity and finalize the cooling design early — these typically drive the critical path."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}]$t11gap$::jsonb,
  financing_recommendations_en =
$t11fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t11fin$::jsonb,
  summary_en =
$t11sum$Readiness score 25/100 (Concept Stage). The ARSAT/Oracle partnership is the strongest joint sponsor in the batch (state operator + global technology vendor), but the initiative still has no total budget, environmental assessment, or contracted power capacity for any of the 25 proposed mini-edge sites. Priority focus: environmental and social readiness.$t11sum$
where project_id = (select id from public.projects
     where name = 'ARSAT / Oracle — Datacenter de IA Distribuida (Mini Edge, 25 Sitios)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t12dims${"legal_regulatory": {"score": 30, "rationale": "Starlink already operates commercially in Argentina under an existing license, though no specific authorizations are documented for the 6,000-school rollout."}, "technical_maturity": {"score": 60, "rationale": "Unlike most projects in this batch, Starlink is a satellite technology already operating and proven at global scale — a substantially more mature technical foundation."}, "financial_robustness": {"score": 20, "rationale": "Only the FSU amount (USD 22M) is reported — no total rollout budget is documented."}, "sponsor_capacity": {"score": 80, "rationale": "SpaceX/Starlink is one of the most capable satellite operators globally, with a constellation already deployed and operating — the sponsor with the strongest technical standing in the entire batch."}, "market_demand": {"score": 30, "rationale": "6,000 schools is a concrete, nationwide-scale target, though with no formal agreement documented."}, "environmental_social": {"score": 10, "rationale": "No environmental impact assessment is documented."}, "risk_mitigation": {"score": 15, "rationale": "No rollout-specific risk register is documented, though the technology itself is already operationally validated."}, "governance_reporting": {"score": 15, "rationale": "No governance or reporting mechanisms are documented for the 6,000-school program."}, "orbital_spectrum_coordination": {"score": 55, "rationale": "The Starlink constellation already has orbital and spectrum coordination resolved globally — a real and substantial advantage over a from-scratch satellite project."}}$t12dims$::jsonb,
  gap_roadmap_en =
$t12gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}]$t12gap$::jsonb,
  financing_recommendations_en =
$t12fin$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$t12fin$::jsonb,
  summary_en =
$t12sum$Readiness score 35/100 (Early Structuring). Starlink is the technically strongest sponsor in the batch — an already-operating satellite constellation with orbital and spectrum coordination resolved — but the 6,000-school program still has no total budget or formal agreement documented beyond the FSU amount. Priority focus: environmental and social readiness.$t12sum$
where project_id = (select id from public.projects
     where name = 'Starlink — Conectividad Satelital para 6.000 Escuelas'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t13dims${"legal_regulatory": {"score": 40, "rationale": "ENACOM is the regulator itself driving the initiative — a strong regulatory position, though the specific installation permits in National Parks (which involve a different agency) are not documented."}, "technical_maturity": {"score": 30, "rationale": "It relies on existing satellite technology (Satellite/Starlink), but with no site list or specific engineering."}, "financial_robustness": {"score": 20, "rationale": "Only the FSU amount (USD 8M) is reported — no total budget is documented."}, "sponsor_capacity": {"score": 55, "rationale": "ENACOM as the national regulator has real institutional capacity, though it isn't an infrastructure operator itself."}, "market_demand": {"score": 20, "rationale": "The target number of portals or parks isn't documented."}, "environmental_social": {"score": 15, "rationale": "The National Parks context implies real environmental sensitivity that isn't addressed in the available source."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 30, "rationale": "Since this is an initiative of the regulator itself, there's a stronger baseline institutional governance structure than for a private-proponent project, though no specific reporting mechanisms are documented."}, "orbital_spectrum_coordination": {"score": 25, "rationale": "Relying on existing satellite providers reduces some of the coordination burden, but no specific filings or agreements are documented."}}$t13dims$::jsonb,
  gap_roadmap_en =
$t13gap$[{"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Advance orbital/frequency coordination filings and lock in launch provider terms — both have long regulatory lead times."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}]$t13gap$::jsonb,
  financing_recommendations_en =
$t13fin$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$t13fin$::jsonb,
  summary_en =
$t13sum$Readiness score 27/100 (Early Structuring). Since it's driven by the regulator itself (ENACOM), the initiative starts from a stronger institutional position than other projects in the batch, but it still doesn't define the target number of portals/parks, the total budget, or an environmental assessment — relevant given the protected-areas context. Priority focus: risk mitigation coverage.$t13sum$
where project_id = (select id from public.projects
     where name = 'ENACOM — Portales Conectados en Parques Nacionales'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t14dims${"legal_regulatory": {"score": 10, "rationale": "No regulatory data is documented at all."}, "technical_maturity": {"score": 5, "rationale": "There's no technical specification whatsoever beyond the project name."}, "financial_robustness": {"score": 5, "rationale": "No budget or funding source is reported."}, "sponsor_capacity": {"score": 50, "rationale": "YPF is a large-scale, financially solid national energy company, though no data on the 5G network project itself is documented."}, "market_demand": {"score": 10, "rationale": "The intended use (internal/industrial) and scope aren't documented."}, "environmental_social": {"score": 5, "rationale": "No environmental assessment is documented."}, "risk_mitigation": {"score": 5, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 10, "rationale": "No governance structures are documented."}, "type_specific_readiness": {"score": 5, "rationale": "No project-specific technical requirements are documented for this initiative."}}$t14dims$::jsonb,
  gap_roadmap_en =
$t14gap$[{"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Document the project-specific technical requirements and specialized permits this project type requires."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}]$t14gap$::jsonb,
  financing_recommendations_en =
$t14fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t14fin$::jsonb,
  summary_en =
$t14sum$Readiness score 12/100 (Concept Stage) — the spreadsheet data is essentially just the project name and sponsor. YPF brings real institutional standing, but no other data is documented yet. Priority focus: technical design maturity.$t14sum$
where project_id = (select id from public.projects
     where name = 'YPF — Redes Privadas 5G'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t15dims${"legal_regulatory": {"score": 45, "rationale": "Modernizing its own spectrum-monitoring system falls directly within ENACOM's regulatory mandate — low external permitting risk, though with no detail on the procurement process."}, "technical_maturity": {"score": 20, "rationale": "No vendor or system specification for the modernization is documented."}, "financial_robustness": {"score": 30, "rationale": "A USD 60M budget is reported, though the spreadsheet doesn't clarify the currency with certainty for this row."}, "sponsor_capacity": {"score": 60, "rationale": "ENACOM has real institutional capacity as the national regulator for a project modernizing its own systems."}, "market_demand": {"score": 15, "rationale": "Market demand in the usual sense doesn't apply — this is an internal tool for the regulator."}, "environmental_social": {"score": 10, "rationale": "No environmental assessment is documented."}, "risk_mitigation": {"score": 15, "rationale": "No risk register is documented, though being an internal regulatory system reduces some of the execution risk typical of an infrastructure project."}, "governance_reporting": {"score": 35, "rationale": "Since this is the regulator's own project over its own systems, there's a more solid baseline institutional governance than for a project from an external proponent."}, "type_specific_readiness": {"score": 15, "rationale": "The specific technical requirements of the spectrum-monitoring system to be modernized aren't documented."}}$t15dims$::jsonb,
  gap_roadmap_en =
$t15gap$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Document the project-specific technical requirements and specialized permits this project type requires."}, {"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}]$t15gap$::jsonb,
  financing_recommendations_en =
$t15fin$[{"mechanism": "Blended Finance", "rationale": "Blended finance can de-risk early-structuring projects enough to attract larger commercial co-investors."}]$t15fin$::jsonb,
  summary_en =
$t15sum$Readiness score 27/100 (Early Structuring). By modernizing its own spectrum-monitoring system, ENACOM starts from a solid regulatory and institutional position, with a reported budget (USD 60M, currency to be confirmed), but with no vendor or technical system specification documented yet. Priority focus: environmental and social readiness.$t15sum$
where project_id = (select id from public.projects
     where name = 'ENACOM — Modernización del Sistema de Control de Espectro'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t16dims${"legal_regulatory": {"score": 30, "rationale": "A spectrum marketplace requires its own enabling regulatory framework; ENACOM has the regulatory authority, but the specific framework isn't documented yet."}, "technical_maturity": {"score": 10, "rationale": "No platform specification is documented at all."}, "financial_robustness": {"score": 5, "rationale": "No budget or scope is reported."}, "sponsor_capacity": {"score": 55, "rationale": "ENACOM has real institutional capacity as regulator, though the project itself lacks almost all detail."}, "market_demand": {"score": 15, "rationale": "No demand or interested parties for the secondary spectrum market are documented."}, "environmental_social": {"score": 5, "rationale": "A typical environmental assessment doesn't apply, but there's also no project scope data at all."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 30, "rationale": "As a regulatory initiative from ENACOM itself, it starts from a more solid institutional base, though with no specific reporting mechanisms documented."}, "type_specific_readiness": {"score": 10, "rationale": "The specific technical and regulatory requirements of a spectrum marketplace aren't documented."}}$t16dims$::jsonb,
  gap_roadmap_en =
$t16gap$[{"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "A typical environmental assessment does not apply, but the project scope should still be formally documented."}, {"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Document the project-specific technical requirements and specialized permits this project type requires."}, {"priority": "high", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}]$t16gap$::jsonb,
  financing_recommendations_en =
$t16fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t16fin$::jsonb,
  summary_en =
$t16sum$Readiness score 19/100 (Concept Stage). This is the most preliminary initiative in ENACOM's batch — just the name and general purpose of a secondary spectrum market, with no budget, scope, or specific regulatory framework documented yet. Priority focus: financial model robustness.$t16sum$
where project_id = (select id from public.projects
     where name = 'ENACOM — Marketplace de Espectro'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

update public.framework_analysis
set
  dimensions_en =
$t17dims${"legal_regulatory": {"score": 15, "rationale": "No permits or authorizations are documented for the site rollout."}, "technical_maturity": {"score": 10, "rationale": "The number of sites and technical specification aren't documented."}, "financial_robustness": {"score": 10, "rationale": "FSU funding is noted as planned, but with no defined amount in the source spreadsheet."}, "sponsor_capacity": {"score": 20, "rationale": "'Telcos' is a generic reference to mobile operators, with no specific operator or documented track record."}, "market_demand": {"score": 15, "rationale": "The number or location of sites to be deployed isn't documented."}, "environmental_social": {"score": 10, "rationale": "No environmental assessment is documented."}, "risk_mitigation": {"score": 10, "rationale": "No risk register is documented."}, "governance_reporting": {"score": 10, "rationale": "No governance structures are documented."}, "shared_access_readiness": {"score": 15, "rationale": "No site inventory or shared-access agreements are documented."}}$t17dims$::jsonb,
  gap_roadmap_en =
$t17gap$[{"priority": "high", "action": "Advance the technical design and vet equipment vendors to reduce execution risk."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "high", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "high", "action": "Prioritize closing regulatory and permitting gaps — this is often the single biggest blocker to progressing past Concept Stage."}]$t17gap$::jsonb,
  financing_recommendations_en =
$t17fin$[{"mechanism": "Development Finance Institutions", "rationale": "Concept-stage projects typically need advisory support and early-stage grant or concessional funding before commercial capital becomes available."}]$t17fin$::jsonb,
  summary_en =
$t17sum$Readiness score 13/100 (Concept Stage). This is the least defined project in the FSU-funded batch: the source spreadsheet identifies no specific operator, no number of sites, and no FSU amount. Priority focus: technical design maturity.$t17sum$
where project_id = (select id from public.projects
     where name = 'Telcos — Programa Play (Sitios Móviles)'
       and user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com'))
  and source = 'ai';

-- ============================================================================
-- Verificacion
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
    'Atlántico-Pacífico — Troncal FO Región Andina (Futaleufú)-Trelew',
    'Atlántico-Pacífico — Tramo Terrestre Esquel-Chaitén-Puerto Montt',
    'Atlántico-Pacífico — Cable Submarino Trelew (AR)-Punta del Este (UY)',
    'Atlántico-Pacífico — Datacenter Tier IV en Tándem (2 sedes) + HW IA',
    'Atlántico-Pacífico — Amarre: Obra Civil y Contingencia',
    'Cable Submarino PUMA (Argentina-Sudáfrica)',
    'Tramo Bioceánico Norte (Salta)',
    'CALF — Anillo Mayorista de Fibra Óptica (Neuquén)',
    'Internet Service — Red Mayorista de Fibra Óptica (Entre Ríos)',
    'ARSAT — Modernización REFEFO (Renovación Tecnológica)',
    'ARSAT — Plan FWA 5G (1.000 localidades, 1a fase 100 localidades)',
    'ARSAT / Oracle — Datacenter de IA Distribuida (Mini Edge, 25 Sitios)',
    'Starlink — Conectividad Satelital para 6.000 Escuelas',
    'ENACOM — Portales Conectados en Parques Nacionales',
    'YPF — Redes Privadas 5G',
    'ENACOM — Modernización del Sistema de Control de Espectro',
    'ENACOM — Marketplace de Espectro',
    'Telcos — Programa Play (Sitios Móviles)'
  )
order by p.name;
