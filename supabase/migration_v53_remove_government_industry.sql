-- Migration v53: remove 'government_non_military' ("Sector público, excepto
-- ejército") from companies.industry, per Pablo's request. He also asked to
-- alphabetize the dropdown list (assets/platform.js's COMPANY_INDUSTRIES) —
-- that's a display-order-only change and needs no DB migration, since the
-- CHECK constraint doesn't care about value order.
--
-- Any company already classified as 'government_non_military' is reset to
-- NULL (unclassified) rather than silently reassigned to some other
-- industry — Pablo should review and pick the right one for each. Public-
-- sector organizations arguably belong in public_agencies (a separate
-- table, migration_v44) rather than companies anyway.
-- Run manually in Supabase SQL Editor.

update public.companies
set industry = null
where industry = 'government_non_military';

alter table public.companies
  drop constraint if exists companies_industry_check;

alter table public.companies
  add constraint companies_industry_check check (industry is null or industry in (
    'aerospace',
    'banking_finance_insurance',
    'broadcasting_entertainment',
    'chemicals_petrochemicals',
    'colocation_hosting_cloud',
    'construction_engineering',
    'consulting',
    'education',
    'energy',
    'financial_entity',
    'fire_alarms_security',
    'healthcare_non_pharma',
    'infrastructure_construction',
    'investor_fund',
    'manufacturer',
    'manufacturing',
    'maritime',
    'military_defense',
    'mining_metals',
    'nuclear_energy',
    'oil_gas_non_petrochemical',
    'power_gas_transmission_distribution',
    'power_generation_non_nuclear',
    'professional_services',
    'retail_wholesale',
    'service_provider',
    'technology',
    'telecommunications',
    'transportation',
    'other'
  ));
