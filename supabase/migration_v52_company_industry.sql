-- Migration v52: companies.industry — single-select industry classification,
-- replacing the companies.types multi-tag checkbox model in the UI.
--
-- Pablo supplied a ~22-item industry list (a standard sector classification,
-- the kind used for KYC/sanctions-style screening) and asked to: (a) merge
-- it with the 9 existing COMPANY_TYPES values rather than replace them,
-- (b) let a company pick exactly ONE from the merged list via a dropdown
-- instead of checking several boxes, (c) add a catch-all "Other" option.
-- See assets/platform.js's COMPANY_INDUSTRIES for the full merged list and
-- the note on the one exact duplicate ("Telecommunications") that was
-- de-duplicated.
--
-- companies.types (the old text[] column, migration_v44 + migration_v51) is
-- intentionally NOT dropped — it's now read-only legacy data. The app no
-- longer writes to it. This migration backfills companies.industry from
-- the first element of each company's pre-existing types array as a
-- reasonable starting point; review and correct any company that actually
-- had multiple types checked before, since only one can be kept going
-- forward.
-- Run manually in Supabase SQL Editor.

alter table public.companies
  add column if not exists industry text;

alter table public.companies
  drop constraint if exists companies_industry_check;

alter table public.companies
  add constraint companies_industry_check check (industry is null or industry in (
    'manufacturer',
    'service_provider',
    'financial_entity',
    'technology',
    'telecommunications',
    'consulting',
    'infrastructure_construction',
    'energy',
    'investor_fund',
    'aerospace',
    'banking_finance_insurance',
    'broadcasting_entertainment',
    'chemicals_petrochemicals',
    'colocation_hosting_cloud',
    'construction_engineering',
    'education',
    'fire_alarms_security',
    'government_non_military',
    'healthcare_non_pharma',
    'manufacturing',
    'maritime',
    'military_defense',
    'mining_metals',
    'nuclear_energy',
    'oil_gas_non_petrochemical',
    'power_generation_non_nuclear',
    'power_gas_transmission_distribution',
    'professional_services',
    'retail_wholesale',
    'transportation',
    'other'
  ));

-- Best-effort backfill: take the first tag of each company's old `types`
-- array as its new single `industry`. Only touches rows that don't already
-- have an industry set and did have at least one legacy type.
update public.companies
set industry = types[1]
where industry is null
  and array_length(types, 1) > 0;
