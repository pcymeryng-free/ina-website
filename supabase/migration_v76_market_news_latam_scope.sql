-- Adds a third country_scope value to public.market_news (Pablo, oct
-- 2026: "reserva un cupo minimo por region privilegiando Argentina, luego
-- latinoamerica y luego el resto") — was 'argentina'/'international' only
-- (migration_v75_market_news.sql); api/update-news.js now classifies into
-- 'argentina' | 'latam' | 'international' and reserves a minimum
-- candidate quota per tier (see SCOPE_QUOTAS / pickWithScopeQuotas() in
-- that file) so a high-volume international feed can't crowd out every
-- Argentina/LatAm item on a slow news day for those, as happened on the
-- first production run.
alter table public.market_news drop constraint if exists market_news_country_scope_check;
alter table public.market_news add constraint market_news_country_scope_check
  check (country_scope in ('argentina', 'latam', 'international'));
