-- Data: remove Chinese-origin products from Master Data > Products.
-- Per Pablo's request: "quitar de la base de productos los de origen chino".
--
-- Scoped by companies.country = 'China' (not hardcoded to a company name), so
-- it removes any product from any Chinese manufacturer/provider on file --
-- currently just Huawei, but this also covers any other Chinese company added
-- to Master Data later. Safe to run whether or not
-- data_products_telecom_infrastructure.sql (which no longer includes the
-- Huawei rows) was already run -- this is a no-op if there's nothing to delete.
-- Run manually in Supabase SQL Editor.

-- Preview first, if you want to see what will be removed:
-- select p.id, p.name, p.category, c.name as company, c.country
-- from public.products p
-- join public.companies c on c.id = p.company_id
-- where c.country = 'China';

delete from public.products
where company_id in (
  select id from public.companies where country = 'China'
);
