-- ============================================================================
-- Backfill EN: traducción al inglés del análisis de
-- data_ai_analysis_alertar.sql
-- ============================================================================
-- Mismo criterio que data_ai_analysis_backfill_en_all_projects.sql —
-- completa dimensions_en/gap_roadmap_en/financing_recommendations_en/
-- summary_en (migration_v40_bilingual_analysis.sql) con una traducción
-- fiel al inglés del análisis ya cargado.
--
-- REQUISITOS: correr data_ai_analysis_alertar.sql y
-- migration_v40_bilingual_analysis.sql antes que este script.
-- ============================================================================

update public.framework_analysis
set
  dimensions_en =
$dims_en${"legal_regulatory": {"score": 85, "rationale": "Solid, already-in-force legal basis: Resolution RESOL-2018-51-APN-SGM#JGM (National Contingency Plan) has required PRESTADORES (mobile carriers) to provide multi-channel dissemination since 2018; the specific project behind this tender (IF-2025-117577290-APN-DNPYD#ENACOM) was already approved by Resolution RESOL-2025-1387-APN-ENACOM#JGM, with multiple prior agreements already signed (CONVE-2025-133062984-APN-MSG and four IF-2025-...-APN-SRI#ENACOM reports)."}, "technical_maturity": {"score": 85, "rationale": "Very advanced, detailed technical design in the tender documents: full CBE/CBC architecture, CAP 1.2 standard, interface and functionality specifications, security (Common Criteria EAL4+), and storage capacity, with mandatory technical requirements for bidders."}, "financial_robustness": {"score": 25, "rationale": "The tender documents don't publish an official budget or financial model: the price only emerges from each bidder's economic offer in a single-stage tender process, with no cost projections or funding structure documented in the source."}, "sponsor_capacity": {"score": 80, "rationale": "ENACOM is the contracting agency: a national regulator with a proven track record regulating the sector since before 2018, and one that has already successfully coordinated prior agreements (SRI, MSG) for this specific project."}, "market_demand": {"score": 65, "rationale": "Solid institutional (not commercial) demand: a legal mandate since 2018, SINAGIR's statutory mission (Law 27.287), and coordination already underway with the National Security Ministry and the three PRESTADORES, though the anchor-customer/market-study concept from a commercial project doesn't apply."}, "environmental_social": {"score": 15, "rationale": "No environmental and social impact assessment or community consultation is documented in the tender file (a software/alert-equipment platform tender with no civil works would be unlikely to require one, but there's no documented evidence either way)."}, "risk_mitigation": {"score": 55, "rationale": "Operational risk mitigation is well covered: dual CBE redundancy (local and geographic) and dual CBC per PRESTADOR, a minimum 36-month hardware/software warranty, a 60-day testing period before final acceptance, and an economic-penalty regime for TMA/TMR non-compliance. No financial/political/currency risk register is documented (these don't apply to a domestic public tender)."}, "governance_reporting": {"score": 55, "rationale": "Governance defined for the award and implementation stage: an evaluation committee, mandatory technical requirements, mandatory technical ratification by PRESTADORES and SINAGIR, and support KPIs (TMA/TMR) for the 36-month service period. Reporting/monitoring mechanisms (dashboards, periodic reports) beyond incident resolution aren't detailed."}, "alert_dissemination_readiness": {"score": 65, "rationale": "Dissemination technology and standard are fully defined (3GPP Cell Broadcast Service + CAP 1.2), and coordination with hazard-detection sources (the CBE's multi-agency access to Civil Defense, meteorology, health, security) and with mobile operators (the three PRESTADORES, already mandated by regulation since 2018) is very advanced. Gaps remain: no target dissemination time in seconds/minutes is set, and the tender doesn't describe a POST-implementation periodic testing plan or a public-awareness campaign (it only defines the pre-acceptance testing period)."}}$dims_en$::jsonb,
  gap_roadmap_en =
$gap_en$[{"priority": "high", "action": "Complete the environmental and social impact assessment and document stakeholder consultation."}, {"priority": "high", "action": "Build or refine a stress-tested financial model backed by real market data."}, {"priority": "medium", "action": "Formalize a risk register with mitigation measures and, where relevant, insurance or guarantee mechanisms."}, {"priority": "medium", "action": "Establish clear governance structures and reporting/monitoring mechanisms before seeking investment."}, {"priority": "low", "action": "Commission demand studies or secure anchor customer commitments to de-risk the revenue case."}, {"priority": "low", "action": "Lock down the dissemination technology/standard and formalize coordination agreements with hazard-detection sources and mobile operators/broadcasters early — track each one in the project's Roadmaps checklist."}]$gap_en$::jsonb,
  financing_recommendations_en =
$fin_en$[{"mechanism": "Public-Private Partnerships", "rationale": "Advanced-structuring projects are often well positioned for a PPP structure once remaining gaps are closed."}]$fin_en$::jsonb,
  summary_en =
$sum_en$Readiness score 59/100 (Advanced Structuring) — the second-highest of the seven projects loaded on the platform, after Cooperativa Eléctrica de Punta Alta. Unlike the third-party proposals analyzed earlier, this is ENACOM's own tender: it has an already-in-force legal basis (Resolution RESOL-2018-51-APN-SGM#JGM and the specific project approved by Resolution RESOL-2025-1387-APN-ENACOM#JGM) and a fully defined CBE/CBC technical architecture, with dual redundancy and the three mobile PRESTADORES already coordinated under a regulatory mandate since 2018. Its main gaps are the lack of a public financial model (the budget only emerges from each bidder's economic offer, not published in the tender) and the absence of a documented environmental and social impact assessment. Priority focus: environmental and social readiness.$sum_en$
where project_id = (select id from public.projects
     where name = 'Sistema de Alerta Temprana - AlertAR'
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
where p.name = 'Sistema de Alerta Temprana - AlertAR'
  and p.user_id = (select id from public.profiles where email = 'pcymeryng@gmail.com')
  and fa.source = 'ai';
