-- Receipts security hardening (audit F-06, F-07, F-08, F-13, F-14).
-- No new tables, no policy or grant changes, no RLS changes.
--
-- 1. profiles.timezone_changed_at + 7-day cooldown on timezone changes.
--    Day boundaries (and the check-in grace window) derive from the profile
--    timezone, so unlimited flips allowed ~1 day of backfill/prefill per
--    flip. The app never writes timezone itself, so legitimate users are
--    unaffected; each flip is timestamped as evidence.
-- 2. pauses.start_day bounded to [server-local-today - 3 days, contract
--    end_date]. Declaring a pause weeks after the fact rewrote misses as
--    paused days. Three days preserve the genuine sick-then-declare flow.
-- 3. Squad invite codes drawn from the full 36-symbol A-Z0-9 alphabet via
--    gen_random_bytes (CSPRNG). The old md5-hex construction collapsed to
--    16 symbols (16^6, enumerable); same 6-char UX and CHECK constraint.
-- 4. Squad-size check serialized per squad with an advisory xact lock,
--    closing the concurrent-join race past 5 members.
-- 5. Nudge day pinned to the server date (was spoofable on direct insert;
--    impact limited to storage spam since only today is ever read).

-- ---------------------------------------------------------------- 1. timezone
alter table public.profiles
  add column if not exists timezone_changed_at timestamptz;

create or replace function public.limit_timezone_changes()
returns trigger
language plpgsql
as $$
begin
  if old.timezone is distinct from new.timezone then
    if old.timezone_changed_at is not null
      and now() - old.timezone_changed_at < interval '7 days' then
      raise exception 'timezone was changed recently; try again in a few days'
        using errcode = '23514';
    end if;
    new.timezone_changed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_timezone_cooldown on public.profiles;
create trigger trg_profiles_timezone_cooldown
  before update on public.profiles
  for each row execute function public.limit_timezone_changes();

-- ------------------------------------------------------------- 2. pause dates
create or replace function public.check_pause_insert()
returns trigger
language plpgsql
as $$
declare
  v_owner uuid;
  v_tz text;
  v_today date;
  v_end date;
begin
  select user_id, end_date into v_owner, v_end
  from public.contracts where id = new.contract_id;
  if v_owner is null then
    raise exception 'contract does not exist' using errcode = '23503';
  end if;
  if v_owner != new.user_id then
    raise exception 'contract does not belong to you' using errcode = '42501';
  end if;

  select timezone into v_tz from public.profiles where id = new.user_id;
  if v_tz is null then
    v_tz := 'UTC';
  end if;
  v_today := ((now() at time zone v_tz))::date;
  if new.start_day < v_today - 3 or new.start_day > v_end then
    raise exception 'pause must start within the last 3 days and inside the contract'
      using errcode = '23514';
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

-- --------------------------------------------------- 3. invite code alphabet
create or replace function public.create_squad(p_name text)
returns table (id uuid, invite_code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_name text := btrim(coalesce(p_name, ''));
  v_code text;
  v_bytes bytea;
  v_tries integer := 0;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if char_length(v_name) < 1 or char_length(v_name) > 60 then
    raise exception 'squad name must be 1-60 characters'
      using errcode = '23514';
  end if;
  loop
    v_tries := v_tries + 1;
    -- 6 chars from the full A-Z0-9 alphabet (36^6 space), drawn from
    -- gen_random_bytes. The old md5-hex construction collapsed to 16
    -- symbols (16^6, enumerable via unauthenticated-cost join attempts).
    v_bytes := gen_random_bytes(6);
    select string_agg(
      substr(
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789',
        (get_byte(v_bytes, s.i) % 36) + 1,
        1
      ),
      '' order by s.i
    )
    into v_code
    from (select generate_series(0, 5) as i) s;
    begin
      insert into public.squads (name, invite_code, created_by)
      values (v_name, v_code, v_user)
      returning squads.id into v_id;
      exit;
    exception when unique_violation then
      if v_tries >= 10 then
        raise;
      end if;
    end;
  end loop;
  insert into public.squad_members (squad_id, user_id)
  values (v_id, v_user);
  return query select v_id, v_code;
end;
$$;

-- ------------------------------------------------------- 4. size race lock
create or replace function public.enforce_squad_size()
returns trigger
language plpgsql
as $$
declare
  v_count integer;
begin
  -- Serialize concurrent joins per squad: without this lock, two
  -- transactions can both pass the count check and admit a 6th member.
  -- The xact-scoped lock releases automatically at transaction end.
  perform pg_advisory_xact_lock(hashtext('squad-size:' || new.squad_id::text));
  select count(*) into v_count
  from public.squad_members
  where squad_id = new.squad_id;
  if v_count >= 5 then
    raise exception 'squad is full (max 5 members)'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

-- ---------------------------------------------------------- 5. nudge day pin
create or replace function public.check_nudge_membership()
returns trigger
language plpgsql
as $$
begin
  if new.day != (now()::date) then
    raise exception 'nudge day must be today'
      using errcode = '23514';
  end if;
  if not exists (
    select 1 from public.squad_members
    where squad_id = new.squad_id and user_id = new.from_user_id
  ) then
    raise exception 'sender is not a squad member' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.squad_members
    where squad_id = new.squad_id and user_id = new.to_user_id
  ) then
    raise exception 'recipient is not a squad member'
      using errcode = '23514';
  end if;
  return new;
end;
$$;
