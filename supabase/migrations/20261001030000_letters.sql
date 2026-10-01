-- Receipts Stage 1: letters to future self.
-- Written on day 1, unlocked on days 30/60/90 (server date).
-- Body is hidden before unlock: direct SELECT on body is revoked and clients
-- must use the secure RPC public.get_letters().

create table if not exists public.letters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  contract_id uuid not null references public.contracts (id) on delete cascade,
  unlock_day_number integer not null check (
    unlock_day_number in (0, 30, 60, 90)
  ),
  body text not null check (char_length(body) between 1 and 5000),
  created_at timestamptz not null default now(),
  unique (contract_id, unlock_day_number)
);

alter table public.letters enable row level security;

drop policy if exists "letters_select_own" on public.letters;
create policy "letters_select_own"
  on public.letters for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "letters_insert_own" on public.letters;
create policy "letters_insert_own"
  on public.letters for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Letters are permanent: block UPDATE and DELETE.
create or replace function public.block_letter_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'letters cannot be edited or deleted'
    using errcode = '25001';
  return null;
end;
$$;

drop trigger if exists trg_letters_no_mutation on public.letters;
create trigger trg_letters_no_mutation
  before update or delete on public.letters
  for each row execute function public.block_letter_mutation();

-- Ensure letter owner matches contract owner.
create or replace function public.check_letter_owner()
returns trigger
language plpgsql
as $$
declare
  v_owner uuid;
begin
  select user_id into v_owner
  from public.contracts where id = new.contract_id;
  if v_owner is null then
    raise exception 'contract does not exist' using errcode = '23503';
  end if;
  if v_owner != new.user_id then
    raise exception 'contract does not belong to you' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_letters_owner on public.letters;
create trigger trg_letters_owner
  before insert on public.letters
  for each row execute function public.check_letter_owner();

-- Restrict direct SELECT on body. PostgREST/authenticated can read metadata
-- columns only; body is only available through get_letters().
-- NOTE: Supabase default grants are revoked first so column grants apply.
revoke all on public.letters from anon, authenticated;
grant select (id, user_id, contract_id, unlock_day_number, created_at)
  on public.letters to authenticated;
grant insert (user_id, contract_id, unlock_day_number, body)
  on public.letters to authenticated;

-- Secure RPC: returns body only when the server date has reached the unlock
-- day (start_date + unlock_day_number in the user's timezone), otherwise
-- body is NULL and is_unlocked is false.
create or replace function public.get_letters(p_contract_id uuid)
returns table (
  id uuid,
  unlock_day_number integer,
  unlock_date date,
  is_unlocked boolean,
  body text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_owner uuid;
  v_start date;
  v_tz text;
  v_today date;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select user_id, start_date into v_owner, v_start
  from public.contracts where contracts.id = p_contract_id;
  if v_owner is null then
    raise exception 'contract does not exist' using errcode = '23503';
  end if;
  if v_owner != v_user then
    raise exception 'access denied' using errcode = '42501';
  end if;

  select timezone into v_tz from public.profiles where profiles.id = v_user;
  if v_tz is null then
    v_tz := 'UTC';
  end if;
  v_today := ((now() at time zone v_tz))::date;

  return query
  select
    l.id,
    l.unlock_day_number,
    (v_start + l.unlock_day_number)::date as unlock_date,
    ((v_start + l.unlock_day_number) <= v_today) as is_unlocked,
    case
      when (v_start + l.unlock_day_number) <= v_today then l.body
      else null
    end as body
  from public.letters l
  where l.contract_id = p_contract_id
  order by l.unlock_day_number;
end;
$$;

revoke all on function public.get_letters(uuid) from public;
grant execute on function public.get_letters(uuid) to authenticated;
