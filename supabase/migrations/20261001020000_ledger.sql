-- Receipts Stage 1: ledger tables (check_ins, excuses, pauses).
-- The Ledger is permanent: check-ins and misses cannot be edited or deleted.
-- Truth about time comes from the SERVER (now()), never the device clock.

-- ---------------------------------------------------------------- check_ins
create table if not exists public.check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  commitment_id uuid not null references public.commitments (id) on delete cascade,
  day date not null,
  done boolean not null,
  note text null check (note is null or char_length(note) <= 500),
  created_at timestamptz not null default now(),
  unique (commitment_id, day)
);

alter table public.check_ins enable row level security;

drop policy if exists "check_ins_select_own" on public.check_ins;
create policy "check_ins_select_own"
  on public.check_ins for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "check_ins_insert_own" on public.check_ins;
create policy "check_ins_insert_own"
  on public.check_ins for insert
  to authenticated
  with check (auth.uid() = user_id);

-- No UPDATE/DELETE policies: PostgREST already blocks them. Triggers below
-- enforce INSERT-only at the database level for all roles.
create or replace function public.block_check_in_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'check_ins are insert-only and cannot be edited or deleted'
    using errcode = '25001';
  return null;
end;
$$;

drop trigger if exists trg_check_ins_no_update on public.check_ins;
create trigger trg_check_ins_no_update
  before update or delete on public.check_ins
  for each row execute function public.block_check_in_mutation();

-- Reject inserts where day is not today in the user's profile timezone
-- according to the SERVER clock. A documented grace window until 03:00 local
-- the next day is allowed, so late-night check-ins count but history cannot
-- be backfilled. Also confines day to the parent contract range.
create or replace function public.check_check_in_day()
returns trigger
language plpgsql
as $$
declare
  v_tz text;
  v_local_ts timestamp;
  v_today date;
  v_allowed boolean := false;
  v_commitment_user uuid;
  v_contract_id uuid;
  v_start date;
  v_end date;
begin
  select timezone into v_tz from public.profiles where id = new.user_id;
  if v_tz is null then
    v_tz := 'UTC';
  end if;

  -- Server clock converted to the user's timezone.
  v_local_ts := (now() at time zone v_tz);
  v_today := (v_local_ts)::date;

  if new.day = v_today then
    v_allowed := true;
  elsif new.day = v_today - 1
    and extract(hour from v_local_ts) < 3 then
    v_allowed := true;
  end if;

  if not v_allowed then
    raise exception
      'check_in day % is not today (%) in your timezone; backfill is forbidden',
      new.day, v_today
      using errcode = '23514';
  end if;

  select user_id, contract_id
    into v_commitment_user, v_contract_id
  from public.commitments
  where id = new.commitment_id;

  if v_commitment_user is null then
    raise exception 'commitment does not exist' using errcode = '23503';
  end if;
  if v_commitment_user != new.user_id then
    raise exception 'commitment does not belong to you' using errcode = '42501';
  end if;

  select start_date, end_date into v_start, v_end
  from public.contracts where id = v_contract_id;
  if new.day < v_start or new.day > v_end then
    raise exception 'check_in day % outside contract range', new.day
      using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_check_ins_day on public.check_ins;
create trigger trg_check_ins_day
  before insert on public.check_ins
  for each row execute function public.check_check_in_day();

-- ------------------------------------------------------------------ excuses
do $$
begin
  if not exists (select 1 from pg_type where typname = 'excuse_reason') then
    create type public.excuse_reason as enum (
      'tired', 'busy', 'unmotivated', 'forgot', 'other'
    );
  end if;
end
$$;

create table if not exists public.excuses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  commitment_id uuid not null references public.commitments (id) on delete cascade,
  day date not null,
  reason public.excuse_reason not null,
  free_text text null check (
    free_text is null or char_length(free_text) <= 280
  ),
  created_at timestamptz not null default now(),
  unique (commitment_id, day)
);

alter table public.excuses enable row level security;

drop policy if exists "excuses_select_own" on public.excuses;
create policy "excuses_select_own"
  on public.excuses for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "excuses_insert_own" on public.excuses;
create policy "excuses_insert_own"
  on public.excuses for insert
  to authenticated
  with check (auth.uid() = user_id);

create or replace function public.block_excuse_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'excuses are insert-only and cannot be edited or deleted'
    using errcode = '25001';
  return null;
end;
$$;

drop trigger if exists trg_excuses_no_update on public.excuses;
create trigger trg_excuses_no_update
  before update or delete on public.excuses
  for each row execute function public.block_excuse_mutation();

-- Excuses allowed only for past days with no done check-in, within 48 hours
-- after the missed day (server clock, user timezone).
create or replace function public.check_excuse_window()
returns trigger
language plpgsql
as $$
declare
  v_tz text;
  v_today date;
  v_deadline timestamptz;
  v_done boolean;
  v_owner uuid;
begin
  select timezone into v_tz from public.profiles where id = new.user_id;
  if v_tz is null then
    v_tz := 'UTC';
  end if;
  v_today := ((now() at time zone v_tz))::date;

  if new.day >= v_today then
    raise exception 'excuses are only for past days'
      using errcode = '23514';
  end if;

  -- Deadline: 48h after the end of the missed day in the user's timezone.
  v_deadline :=
    (((new.day + 1)::text || ' 00:00 ' || v_tz)::timestamptz)
    + interval '48 hours';
  if now() > v_deadline then
    raise exception 'excuse window (48h) has passed for %', new.day
      using errcode = '23514';
  end if;

  select user_id into v_owner
  from public.commitments where id = new.commitment_id;
  if v_owner is null then
    raise exception 'commitment does not exist' using errcode = '23503';
  end if;
  if v_owner != new.user_id then
    raise exception 'commitment does not belong to you' using errcode = '42501';
  end if;

  select done into v_done
  from public.check_ins
  where commitment_id = new.commitment_id and day = new.day;
  if found and v_done is true then
    raise exception 'cannot excuse a completed day'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_excuses_window on public.excuses;
create trigger trg_excuses_window
  before insert on public.excuses
  for each row execute function public.check_excuse_window();

-- ------------------------------------------------------------------- pauses
-- Sick/Injury mode: a declared pause, recorded visibly, does not break streak.
create table if not exists public.pauses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  contract_id uuid not null references public.contracts (id) on delete cascade,
  type text not null check (type in ('sick', 'injury')),
  start_day date not null,
  end_day date null check (end_day is null or end_day >= start_day),
  created_at timestamptz not null default now()
);

alter table public.pauses enable row level security;

drop policy if exists "pauses_select_own" on public.pauses;
create policy "pauses_select_own"
  on public.pauses for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "pauses_insert_own" on public.pauses;
create policy "pauses_insert_own"
  on public.pauses for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "pauses_update_own" on public.pauses;
create policy "pauses_update_own"
  on public.pauses for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Insert plus one controlled end update only. No deletes. No overlapping
-- pauses per contract. Owner must match contract owner.
create or replace function public.check_pause_insert()
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
  if exists (
    select 1 from public.pauses
    where contract_id = new.contract_id
      and daterange(start_day, coalesce(end_day, 'infinity'::date), '[]')
        && daterange(new.start_day, coalesce(new.end_day, 'infinity'::date), '[]')
  ) then
    raise exception 'pause overlaps an existing pause' using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_pauses_insert on public.pauses;
create trigger trg_pauses_insert
  before insert on public.pauses
  for each row execute function public.check_pause_insert();

create or replace function public.check_pause_update()
returns trigger
language plpgsql
as $$
begin
  -- Only end_day may change, exactly once (NULL -> date).
  if new.id is distinct from old.id
    or new.user_id is distinct from old.user_id
    or new.contract_id is distinct from old.contract_id
    or new.type is distinct from old.type
    or new.start_day is distinct from old.start_day
    or new.created_at is distinct from old.created_at then
    raise exception 'only end_day may be updated on pauses'
      using errcode = '25001';
  end if;
  if old.end_day is not null then
    raise exception 'pause end_day is already set'
      using errcode = '25001';
  end if;
  if new.end_day is null or new.end_day < old.start_day then
    raise exception 'invalid pause end_day' using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_pauses_update on public.pauses;
create trigger trg_pauses_update
  before update on public.pauses
  for each row execute function public.check_pause_update();

create or replace function public.block_pause_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception 'pauses cannot be deleted' using errcode = '25001';
  return null;
end;
$$;

drop trigger if exists trg_pauses_no_delete on public.pauses;
create trigger trg_pauses_no_delete
  before delete on public.pauses
  for each row execute function public.block_pause_delete();
