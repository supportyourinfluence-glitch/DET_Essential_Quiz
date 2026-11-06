-- Supabase SQL Editor에서 한 번 실행한다.
-- 표는 직접 읽고 쓸 수 없고, 동기화 코드를 아는 경우에만 아래 함수로 접근한다.
-- 코드는 해시로만 저장한다.

create table if not exists public.word_sync (
  code_hash text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.word_sync enable row level security;
revoke all on public.word_sync from anon, authenticated;

create or replace function public.sync_pull(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if length(p_code) <> 20 then
    raise exception 'invalid code';
  end if;
  select data into result from public.word_sync
    where code_hash = encode(sha256(convert_to(p_code, 'UTF8')), 'hex');
  return result;
end;
$$;

create or replace function public.sync_push(p_code text, p_data jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if length(p_code) <> 20 then
    raise exception 'invalid code';
  end if;
  if pg_column_size(p_data) > 1000000 then
    raise exception 'data too large';
  end if;
  insert into public.word_sync (code_hash, data, updated_at)
    values (encode(sha256(convert_to(p_code, 'UTF8')), 'hex'), p_data, now())
    on conflict (code_hash) do update set data = excluded.data, updated_at = now();
end;
$$;

revoke all on function public.sync_pull(text) from public;
revoke all on function public.sync_push(text, jsonb) from public;
grant execute on function public.sync_pull(text) to anon;
grant execute on function public.sync_push(text, jsonb) to anon;
