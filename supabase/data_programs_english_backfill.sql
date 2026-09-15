-- ============================================================================
-- Backfill: English translations for existing Financing Programs
--
-- Pablo, sep 2026: "la descripción está en español" — after migration_v61
-- added programs.organization_en / financing_entity_en (and migration_v60
-- already had description_en), the fields work correctly, but they're
-- OPTIONAL overrides: an existing program with no English value keeps
-- showing its Spanish organization/financing_entity/description even when
-- the viewer has the site in English, because there's nothing to fall back
-- to yet. This script fills in name_en/organization_en/financing_entity_en/
-- description_en for the 9 programs whose full Spanish text is on file in
-- this supabase/ folder (same backfill pattern already used for the
-- Starlink success cases — see data_success_cases_titles_en_backfill.sql).
--
-- COVERAGE — programs backfilled by this script (matched by exact `name`):
--   - "Conexión Sur" (data_program_conexion_sur.sql)
--   - The 4 DFC programs (data_programs_dfc.sql)
--   - The 3 BID "Acceso a Crédito Telecom para ISPs" programs
--     (data_programs_bid_acceso_credito_isp.sql)
--   - "Atlántico-Pacífico" (data_pipeline_proyectos_planilla_ago2026.sql)
--
-- NOT COVERED — programs created directly through new-program.html whose
-- exact stored text isn't on file here (so translating them here would risk
-- fabricating content that doesn't match what's actually in the database):
-- TASU, FATIC (general and Mercado de Capitales), Red Mayorista Neutral,
-- Conectividad de Interés Público, and Asistencia ante Emergencias y
-- Catástrofes — see data_fix_fsu_program_names_prefix.sql for the full
-- list. For those, either fill in the English fields by hand on each
-- program's edit page, or export their current Spanish text so a follow-up
-- backfill can be generated for them too.
--
-- SAFE TO RE-RUN: every field uses `coalesce(existing_en, 'new value')`, so
-- it never overwrites a value someone already filled in by hand — running
-- this script twice, or after someone has since edited a program's English
-- fields, changes nothing for the fields already set.
--
-- Names deliberately left untranslated: "Atlántico-Pacífico" is the
-- corridor's own proper name (same convention as leaving a few Success
-- Case titles untranslated in data_success_cases_titles_en_backfill.sql).
-- financing_entity is left as-is (no _en override) for the 4 DFC programs:
-- it's already stored as the institution's English legal name ("U.S.
-- International Development Finance Corporation (DFC)"), so the existing
-- fallback already shows correctly in English.
-- ============================================================================


-- ============================================================================
-- 1) Conexión Sur (BID)
-- ============================================================================
update public.programs
set
  name_en = coalesce(name_en, 'South Connection'),
  organization_en = coalesce(organization_en, 'Inter-American Development Bank (IDB)'),
  financing_entity_en = coalesce(financing_entity_en, 'Inter-American Development Bank (IDB)'),
  description_en = coalesce(description_en, $en$IDB regional program ("South Connection"), launched on March 27, 2025 at the Annual Meetings of the Boards of Governors of the IDB and IDB Invest (Santiago, Chile), with the support of Argentina, Bolivia, Brazil, Chile, Colombia, Ecuador, Guyana, Paraguay, Peru, Suriname and Uruguay. Three pillars: (1) connectivity — roads, ports, waterways, power grids and digital networks; (2) regional and global value chains; (3) regulatory and institutional strengthening. Expands the "Integration Routes" alliance (Brasília Agreement, May 2023), with possible co-financing alongside FONPLATA, BNDES and CAF.

Source: IDB, "IDB Launches 'South Connection' Regional Program" (03/27/2025) — https://www.iadb.org/en/news/idb-launches-south-connection-regional-program$en$)
where name = 'Conexión Sur';


-- ============================================================================
-- 2) DFC — Financiamiento de Deuda (Préstamos Directos y Garantías)
-- ============================================================================
update public.programs
set
  name_en = coalesce(name_en, 'DFC — Debt Financing (Direct Loans and Guarantees)'),
  organization_en = coalesce(organization_en, 'National Communications Entity (ENACOM)'),
  description_en = coalesce(description_en, $en$Direct loans and loan guarantees from DFC (U.S. International Development Finance Corporation) for digital infrastructure and telecommunications projects in emerging markets — one of DFC's 7 declared priority sectors (along with energy, critical minerals, transportation, financial services, health and agriculture). DFC has explicitly financed fiber-optic networks, wireless towers/connectivity and data centers in other countries in the region and in Asia under this same line.

PUBLISHED TERMS: amounts of up to US$1 billion per transaction, with tenors of 5 to 25 years, subject to U.S. federal credit law and to DFC's own due diligence (commercial viability of the project, additionality relative to the private market, and U.S. strategic/development interest). Includes structured-debt and project-finance modalities, designed for both private operators and public-private vehicles.

WHO IS INVOLVED: the project developer/operator (borrower), DFC (lender or guarantor), and — when the transaction is a guarantee rather than a direct loan — a commercial financial institution that provides the underlying credit.

BENEFIT: access to long-term dollar-denominated credit on more favorable terms than the local market, without the project needing a U.S. partner. WHAT AN ARGENTINE PROJECT NEEDS: confirm Argentina's eligibility as a recipient country at the time of application (DFC's list of eligible countries can change), and prepare the business case/financial structure that DFC evaluates through its own application process (not administered by ENACOM).

Source: DFC, "Debt Financing" — dfc.gov/what-we-offer/our-products/debt-financing (accessed 2026).$en$)
where name = 'DFC — Financiamiento de Deuda (Préstamos Directos y Garantías)';


-- ============================================================================
-- 3) DFC — Inversión de Capital (Equity)
-- ============================================================================
update public.programs
set
  name_en = coalesce(name_en, 'DFC — Equity Investment'),
  organization_en = coalesce(organization_en, 'National Communications Entity (ENACOM)'),
  description_en = coalesce(description_en, $en$Direct equity investments made by DFC in companies or funds that support development challenges while advancing U.S. strategic interests — unlike a loan, DFC becomes a (typically minority) shareholder in the project vehicle, aligning its incentives with the operator's long-term commercial success.

TYPICAL APPLICATION IN DIGITAL INFRASTRUCTURE: capitalizing neutral wholesale network operators, shared passive-infrastructure/tower companies, submarine-cable operators or data-center operators that need to strengthen their capital structure (not just debt) to scale, especially in expansion stages where additional leverage is no longer viable without more equity.

WHO IS INVOLVED: the company or operator receiving the investment, DFC as equity investor, and — frequently — private co-investors that DFC seeks to mobilize alongside its own contribution (its stated role is to "catalyze" private capital, not replace it).

BENEFIT: strengthens the project's capital structure without adding debt, and DFC's participation as a shareholder often facilitates later access to other financiers (a "seal of quality" effect/mitigation of perceived risk). WHAT AN ARGENTINE PROJECT NEEDS: a corporate structure and business plan that supports a DFC exit in the medium/long term (DFC is not a permanent partner), and confirmation of country eligibility when applying directly to DFC.

Source: DFC, "Equity" — dfc.gov/what-we-offer/our-products/equity (accessed 2026).$en$)
where name = 'DFC — Inversión de Capital (Equity)';


-- ============================================================================
-- 4) DFC — Seguro de Riesgo Político (Political Risk Insurance)
-- ============================================================================
update public.programs
set
  name_en = coalesce(name_en, 'DFC — Political Risk Insurance'),
  organization_en = coalesce(organization_en, 'National Communications Entity (ENACOM)'),
  description_en = coalesce(description_en, $en$Unlike DFC's other instruments, Political Risk Insurance does NOT disburse funds to the project: it covers U.S. investors and lenders (or, in certain cases, the financial institution involved in the transaction) against losses arising from political risks in the recipient country — currency inconvertibility/inability to repatriate funds, expropriation or government interference, and political violence (including terrorism). By reducing perceived risk, it helps the project access BETTER TERMS from traditional private financing (lower rates, greater lender appetite) — similar in logic to the IDB's Guarantee Mechanism (see the BID "Telecom Credit Access for ISPs" programs on this platform), though it covers different risks (political vs. credit).

PUBLISHED COVERAGE: up to US$1 billion per project.

WHO IS INVOLVED: the insured investor or lender (policy beneficiary), DFC (insurer), and the project/operator in the recipient country whose operation is indirectly backed by the coverage.

BENEFIT: usually the instrument that most facilitates attracting U.S./international private investors and banks to an infrastructure project in an emerging market, by removing political uncertainty as a decision-making obstacle — relevant for a telecommunications project with a long repayment horizon (fiber, submarine cable, data centers) where the investment horizon spans several political-economic cycles. WHAT AN ARGENTINE PROJECT NEEDS: identify which investor or lender (typically American) would be the insured party under the policy — this is not coverage the Argentine project contracts directly for itself — and confirm country eligibility when applying to DFC.

Source: DFC, "Political Risk Insurance" — dfc.gov/what-we-offer/our-products/political-risk-insurance (accessed 2026).$en$)
where name = 'DFC — Seguro de Riesgo Político (Political Risk Insurance)';


-- ============================================================================
-- 5) DFC — Asistencia Técnica y Estudios de Factibilidad
-- ============================================================================
update public.programs
set
  name_en = coalesce(name_en, 'DFC — Technical Assistance and Feasibility Studies'),
  organization_en = coalesce(organization_en, 'National Communications Entity (ENACOM)'),
  description_en = coalesce(description_en, $en$DFC grants for feasibility studies, front-end engineering design (FEED), environmental and social impact assessments, transaction structuring and other project-preparation work — under the authority of the BUILD Act (the 2019 law that created DFC). This is not construction financing: it is logically identical to the USTDA program already loaded on the platform (Definitional Mission / Feasibility Study), but from DFC instead of USTDA.

HOW IT WORKS: DFC determines the scope of the technical-assistance work, feasibility study or training to be funded, and the grant recipient selects the entity with the relevant expertise that actually carries it out. In most cases these grants are intended for projects that have already received — or could reasonably receive — DFC financing or insurance later on (Debt Financing, Equity Investment or Political Risk Insurance, the other 3 DFC programs loaded on this platform); in other words, it acts as the preliminary step that enables applying to those instruments with a better-structured project and lower execution risk.

WHO IS INVOLVED: the project developer/sponsor (grant recipient), DFC (grantor), and the consulting/technical entity that carries out the study or technical-assistance work.

BENEFIT: reduces execution risk and improves the project's "bankability" before seeking construction financing, without committing the developer's own capital at this early stage. WHAT AN ARGENTINE PROJECT NEEDS: precisely identify which preparation study/work is missing (technical, environmental/social feasibility, financial structuring) and its link to an eventual later application to one of the other 3 DFC programs.

Source: DFC, "Technical Assistance & Feasibility Studies" — dfc.gov/what-we-offer/our-products/technical-assistance-feasibility-studies (accessed 2026).$en$)
where name = 'DFC — Asistencia Técnica y Estudios de Factibilidad';


-- ============================================================================
-- 6) BID — Acceso a Crédito Telecom para ISPs: Línea de Crédito Bancario
-- ============================================================================
update public.programs
set
  name_en = coalesce(name_en, 'IDB — Telecom Credit Access for ISPs: Bank Credit Line'),
  organization_en = coalesce(organization_en, 'National Communications Entity (ENACOM)'),
  financing_entity_en = coalesce(financing_entity_en, 'Inter-American Development Bank (IDB)'),
  description_en = coalesce(description_en, $en$Adaptation to Argentina of Component 1 (bank-credit instrument) of the IDB's "Telecom Credit Access Program" for Brazil (BR-L1619). Finances, through medium/long-term loans at a reduced rate, the expansion of fixed broadband networks by regional internet service providers (ISPs) — cooperatives and telecom SMEs — that today can only access personal credit or very short-term financing (3-6 months) at rates far above those of other infrastructure sectors.

FLOW OF FUNDS (adapted from Brazil's FUST/MCOM/Banco Central do Brasil to their Argentine equivalents): the IDB grants a loan to the National Treasury → channeled to the FSU (Universal Service Fund, administered by ENACOM, equivalent to Brazil's FUST) → the FSU transfers resources to a designated Financial Agent (development bank) → the Financial Agent lends at a reduced rate to Accredited Financial Institutions (authorized by the BCRA and accredited with the Financial Agent, equivalent to the Banco Central do Brasil scheme) → those institutions provide direct or indirect credit to eligible ISPs (sub-borrowers).

WHO IS INVOLVED (adapted): eligible ISP (telecommunications/internet service provider, with an access-count ceiling to be defined — Brazil used 200,000 accesses), Financial Agent (institution eligible to operate FSU resources, under contract with ENACOM as Executing Body), Accredited Financial Institutions (authorized by the BCRA).

BENEFIT: an instrument with a track record of successful implementation in Brazil (CG-Fust). WHAT ARGENTINA NEEDS TO ADAPT IT: financial modeling that enables small ISPs to access credit, and definition of the Financial Agent and the accreditation criteria for Financial Institutions.

Order-of-magnitude reference from Brazil (not directly transferable): US$98.5M from the IDB for the full Component 1 (all 3 instruments), aimed mainly at Tier 2 ISPs (~430, revenue BRL 5M-50M) and Tier 3 (~1,900, revenue BRL 1M-5M). Sizing for Argentina requires its own diagnostic.

Source: IDB, "Telecom Credit Access Program (BR-L1619)" — "Case Brasil" presentation, attached to the INA project (06/26/2026).$en$)
where name = 'BID — Acceso a Crédito Telecom para ISPs: Línea de Crédito Bancario';


-- ============================================================================
-- 7) BID — Acceso a Crédito Telecom para ISPs: FIDC
-- ============================================================================
update public.programs
set
  name_en = coalesce(name_en, 'IDB — Telecom Credit Access for ISPs: Investment Fund for Credit Rights (FIDC)'),
  organization_en = coalesce(organization_en, 'National Communications Entity (ENACOM)'),
  financing_entity_en = coalesce(financing_entity_en, 'Inter-American Development Bank (IDB)'),
  description_en = coalesce(description_en, $en$Adaptation to Argentina of Component 1 (non-bank credit instrument, FIDC) of the IDB's "Telecom Credit Access Program" for Brazil (BR-L1619). Finances ISPs' PURCHASE OF NETWORK EQUIPMENT, avoiding the cash payment or very short-term financing that distributors currently offer — without going through a bank.

STRUCTURE (Brazil's FIDC is adapted as a Financial Trust or Closed-End Mutual Investment Fund under CNV regulations, the equivalent structure available in Argentina):
1. A network-equipment manufacturer or distributor ("Accredited Supplier") sells equipment to an ISP on credit, and assigns the collection rights on those invoices/promissory notes to the Fund.
2. The Fund issues two classes of units: Senior Units (subscribed with FSU/IDB contributions) and Subordinated Units (subscribed by the Accredited Supplier itself, as a "skin in the game" commitment — absorbing any losses first). Qualified/professional investors may subscribe additional units, thereby leveraging public resources with private capital.
3. The Fund pays the Accredited Supplier in cash (or on short terms) for the assigned rights, and collects from the ISP in medium/long-term installments — the ISP ends up paying the credit to the Fund, not to the Supplier.

WHO IS INVOLVED (adapted): eligible ISP, Accredited Supplier (network-equipment manufacturer/distributor or wholesale telecom provider), Authorized Investors (qualified/professional per the CNV rules applicable to Financial Trusts/closed-end mutual funds), Fund Manager/Administrator.

BENEFIT: serves ISPs of all sizes (does not depend on a bank's credit assessment) and allows attracting private investors, leveraging FSU/IDB resources beyond the amount directly contributed. WHAT ARGENTINA NEEDS TO ADAPT IT: identify network-equipment suppliers/manufacturers interested in assigning collection rights, and fund managers/administrators (mutual-fund management companies or financial trustees) willing to structure the vehicle under CNV regulations.

Source: IDB, "Telecom Credit Access Program (BR-L1619)" — "Case Brasil" presentation, attached to the INA project (06/26/2026).$en$)
where name = 'BID — Acceso a Crédito Telecom para ISPs: Fondo de Inversión en Derechos Crediticios (FIDC)';


-- ============================================================================
-- 8) BID — Acceso a Crédito Telecom para ISPs: Mecanismo de Garantía
-- ============================================================================
update public.programs
set
  name_en = coalesce(name_en, 'IDB — Telecom Credit Access for ISPs: Guarantee Mechanism'),
  organization_en = coalesce(organization_en, 'National Communications Entity (ENACOM)'),
  financing_entity_en = coalesce(financing_entity_en, 'Inter-American Development Bank (IDB)'),
  description_en = coalesce(description_en, $en$Adaptation to Argentina of Component 1 (guarantee mechanism) of the IDB's "Telecom Credit Access Program" for Brazil (BR-L1619). Unlike the other two instruments, it does NOT disburse funds to the ISP directly: it reduces the lender's perceived risk so the ISP can access BETTER TERMS on traditional bank credit (lower rate, longer terms).

STRUCTURE (adapted from Brazil's FUST/MCOM/Banco Central do Brasil to their Argentine equivalents): the IDB grants a loan to the National Treasury → channeled to the FSU (administered by ENACOM) → through a Financial Agent, the FSU sets up a Credit Guarantee Mechanism (a trustee issuing guarantees) → Accredited Financial Institutions (authorized by the BCRA) lend to eligible ISPs under market conditions, but with an individual guarantee from the fund for each transaction — the ISP is the guarantee beneficiary, the financial institution is the secured creditor.

WHO IS INVOLVED (adapted): eligible ISP (guarantee beneficiary), Accredited Financial Institutions (lender/secured creditor), Financial Agent (contracts the trustee that issues the guarantees), ENACOM (defines project eligibility criteria for guaranteed financing, as the public-policy sponsor).

BENEFIT: the instrument that allows the MAXIMUM LEVERAGE of FSU/IDB resources among the three proposed — a guarantee covers a multiple of the guaranteed credit, unlike funding a direct loan or purchasing collection rights. WHAT ARGENTINA NEEDS TO ADAPT IT: gauge financial institutions' interest in operating under this scheme, and develop the financial modeling demonstrating the expected impact on lowering the interest rate offered to ISPs.

Source: IDB, "Telecom Credit Access Program (BR-L1619)" — "Case Brasil" presentation, attached to the INA project (06/26/2026).$en$)
where name = 'BID — Acceso a Crédito Telecom para ISPs: Mecanismo de Garantía';


-- ============================================================================
-- 9) Atlántico-Pacífico (EPECH) — name kept as-is (corridor's own proper
--    name), only organization + description translated.
-- ============================================================================
update public.programs
set
  organization_en = coalesce(organization_en, 'EPECH (Chubut Provincial Energy Company)'),
  description_en = coalesce(description_en, $en$Program grouping the "Atlántico-Pacífico" digital infrastructure corridor led by EPECH (Chubut Provincial Energy Company): a fiber-optic backbone between the Andean Region and Trelew that follows the route of the provincial power-transmission line, an overland stretch toward Chile (Esquel-Chaitén-Puerto Montt), a submarine cable providing an Atlantic outlet to Uruguay (Trelew-Punta del Este), a tandem data center with AI hardware, and the associated landing/civil works — five components presented separately and financed independently under a single program.

Source: ENACOM project-tracking spreadsheet, Aug. 2026.$en$)
where name = 'Atlántico-Pacífico';


-- ============================================================================
-- Verificación — debería devolver 9 filas, todas con organization_en y
-- description_en completos (financing_entity_en solo en Conexión Sur y los
-- 3 BID-ISP; Atlántico-Pacífico no tiene financing_entity ni name_en).
-- ============================================================================
select name, name_en, organization_en, financing_entity_en,
       (description_en is not null) as has_description_en
from public.programs
where name in (
  'Conexión Sur',
  'DFC — Financiamiento de Deuda (Préstamos Directos y Garantías)',
  'DFC — Inversión de Capital (Equity)',
  'DFC — Seguro de Riesgo Político (Political Risk Insurance)',
  'DFC — Asistencia Técnica y Estudios de Factibilidad',
  'BID — Acceso a Crédito Telecom para ISPs: Línea de Crédito Bancario',
  'BID — Acceso a Crédito Telecom para ISPs: Fondo de Inversión en Derechos Crediticios (FIDC)',
  'BID — Acceso a Crédito Telecom para ISPs: Mecanismo de Garantía',
  'Atlántico-Pacífico'
)
order by name;
