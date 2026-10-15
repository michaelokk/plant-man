-- Gardener pricing questionnaire: storage for answers and job photos.
-- Run once in the INKnerd project: Supabase dashboard -> SQL Editor -> New query -> paste -> Run.
-- Safe to run again.

-- 1. Answers: one row per person filling the form (id is generated in their browser).
create table if not exists public.gardener_responses (
  id uuid primary key,
  data jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Nobody reads or writes the table directly with the public key;
-- the form saves only through the function below, and you read rows in the dashboard.
alter table public.gardener_responses enable row level security;

create or replace function public.save_gardener_response(p_id uuid, p_data jsonb)
returns void
language sql
security definer
set search_path = public
as $$
  insert into public.gardener_responses (id, data)
  values (p_id, p_data)
  on conflict (id) do update
    set data = excluded.data, updated_at = now();
$$;

revoke all on function public.save_gardener_response(uuid, jsonb) from public;
grant execute on function public.save_gardener_response(uuid, jsonb) to anon, authenticated;

-- 2. Photos: public bucket, images only, up to 10 MB each.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('gardener-photos', 'gardener-photos', true, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'])
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- The form may add photos; it cannot list, replace or delete them.
drop policy if exists "gardener photos upload" on storage.objects;
create policy "gardener photos upload" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'gardener-photos');

-- Handy view for reading answers: one row per respondent, newest first.
create or replace view public.gardener_responses_overview
with (security_invoker = true) as
select id,
       data->'answers'->>'name' as name,
       jsonb_array_length(coalesce(data->'jobs', '[]'::jsonb)) as jobs,
       updated_at
from public.gardener_responses
order by updated_at desc;
