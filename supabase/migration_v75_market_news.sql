-- Daily telecom/digital-infrastructure market news feed (Pablo, oct 2026:
-- "agregarle al sitio una pagina de noticias relevantes del mercado de las
-- telecomunicaciones... que todos los dias se actualice"). Written once a
-- day by api/update-news.js (a Vercel Cron-triggered serverless function —
-- see vercel.json's "crons" entry — that pulls a curated set of Argentina +
-- international telecom RSS feeds, has an LLM filter out anything not
-- genuinely relevant and summarize/translate what's kept, then inserts
-- here with the SERVICE ROLE key, bypassing RLS). Read publicly from
-- news.html with the plain anon key and no auth — this is public marketing
-- content, not platform data, so there's no owner/advisor/admin distinction
-- here at all, unlike every other table in this schema.
create table if not exists public.market_news (
  id uuid primary key default gen_random_uuid(),
  -- The day this item was curated for, in Argentina local time (see
  -- argentinaTodayDate() in api/update-news.js) — NOT the feed's own
  -- pubDate, which can be a few hours off depending on the source's time
  -- zone. This is what news.html groups and sorts by for its day-by-day
  -- infinite scroll.
  published_date date not null,
  title text not null,
  title_en text,
  summary text not null,
  summary_en text,
  source_name text not null,
  -- The dedup key: api/update-news.js fetches already-seen source_urls
  -- before ever calling the LLM, so a link already stored here never gets
  -- re-curated (and never costs a second model call) on a later run.
  source_url text not null unique,
  country_scope text not null check (country_scope in ('argentina', 'international')),
  category text,
  created_at timestamptz not null default now()
);

comment on table public.market_news is 'Daily-curated telecom/digital-infrastructure news (Argentina + international) shown on the public news.html feed. Written only by api/update-news.js via the service role key.';

create index if not exists market_news_feed_idx on public.market_news (published_date desc, created_at desc);

alter table public.market_news enable row level security;

-- Public content: anyone (including an anonymous visitor on the public
-- site, who never signs in at all) can read it. No insert/update/delete
-- policy for anon/authenticated on purpose — the service role key api/
-- update-news.js uses bypasses RLS entirely, so this table is otherwise
-- fully read-only from every client.
drop policy if exists "market_news_public_read" on public.market_news;
create policy "market_news_public_read" on public.market_news
  for select using (true);
