-- Migration v51: expand companies.types with 6 sector/industry categories
-- Pablo's request: Master Data > Companies needed sector-style types
-- (Tecnología, Telecomunicaciones, Consultoría, etc.), on top of the
-- existing business-role types (manufacturer, service_provider,
-- financial_entity). A company can now carry both kinds of tags at once
-- (e.g. "Service Provider" + "Telecommunications"), same multi-tag model
-- as before — see assets/platform.js's COMPANY_TYPES comment.
-- Run manually in Supabase SQL Editor.

alter table public.companies
  drop constraint if exists companies_types_check;

alter table public.companies
  add constraint companies_types_check check (types <@ array[
    'manufacturer',
    'service_provider',
    'financial_entity',
    'technology',
    'telecommunications',
    'consulting',
    'infrastructure_construction',
    'energy',
    'investor_fund'
  ]::text[]);
