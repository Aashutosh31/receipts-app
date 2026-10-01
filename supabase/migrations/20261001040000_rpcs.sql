-- Receipts Stage 1: read RPCs get_ledger and get_streak.
-- Both compute from SERVER dates (now()) in the user's profile timezone.

-- get_ledger: one row per (day, commitment) from start_date through end_date.
-- status is promised (future) | done | missed | paused (sick/injury cover).
-- Retired commitments only appear for days before their retired_at date.
create or replace function public.get_ledger(p_contract_id uuid)
returns table (
  day date,
  commitment_id uuid,
  commitment_title text,
  status text,
  done boolean,
  is_paused boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_owner uuid;
  v_start date;
  v_end date;
  v_tz text;
  v_today date;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select user_id, start_date, end_date
    into v_owner, v_start, v_end
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
  with days as (
    select generate_series(v_start, v_end, interval '1 day')::date as d
  ),
  active_commitments as (
    select c.id, c.title, c.created_at::date as born, c.retired_at::date as retired
    from public.commitments c
    where c.contract_id = p_contract_id
  )
  select
    days.d as day,
    ac.id as commitment_id,
    ac.title as commitment_title,
    case
      when exists (
        select 1 from public.pauses p
        where p.contract_id = p_contract_id
          and days.d >= p.start_day
          and (p.end_day is null or days.d <= p.end_day)
      ) then 'paused'
      when days.d > v_today then 'promised'
      when ci.done is true then 'done'
      else 'missed'
    end as status,
    ci.done as done,
    exists (
      select 1 from public.pauses p
      where p.contract_id = p_contract_id
        and days.d >= p.start_day
        and (p.end_day is null or days.d <= p.end_day)
    ) as is_paused
  from days
  cross join active_commitments ac
  left join public.check_ins ci
    on ci.commitment_id = ac.id
    and ci.day = days.d
  where days.d >= ac.born
    and (ac.retired is null or days.d < ac.retired)
  order by days.d, ac.title;
end;
$$;

revoke all on function public.get_ledger(uuid) from public;
grant execute on function public.get_ledger(uuid) to authenticated;

-- get_streak: current streak honoring hard/kind mode and pauses.
-- Hard mode: any miss resets. Kind mode: up to 2 missed days tolerated.
-- Paused days are skipped (never break the streak).
create or replace function public.get_streak(p_contract_id uuid)
returns table (
  current_streak integer,
  recoveries_used integer,
  mode text,
  today date
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_owner uuid;
  v_start date;
  v_end date;
  v_mode text;
  v_tz text;
  v_today date;
  v_last date;
  v_day date;
  v_paused boolean;
  v_all_done boolean;
  v_active_count integer;
  v_done_count integer;
  v_streak integer := 0;
  v_recoveries integer := 0;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select user_id, start_date, end_date, contracts.mode
    into v_owner, v_start, v_end, v_mode
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
  v_last := least(v_today, v_end);

  -- Walk forward from start_date: the kind-mode recovery budget is consumed
  -- by the earliest misses first (mirrors Dart StreakLogic). A miss with
  -- budget left counts toward the streak; a miss with no budget resets it.
  v_day := v_start;
  while v_day <= v_last loop
    select exists (
      select 1 from public.pauses p
      where p.contract_id = p_contract_id
        and v_day >= p.start_day
        and (p.end_day is null or v_day <= p.end_day)
    ) into v_paused;
    if v_paused then
      v_day := v_day + 1;
      continue;
    end if;

    select count(*), count(*) filter (where ci.done is true)
      into v_active_count, v_done_count
    from public.commitments c
    left join public.check_ins ci
      on ci.commitment_id = c.id and ci.day = v_day
    where c.contract_id = p_contract_id
      and v_day >= c.created_at::date
      and (c.retired_at is null or v_day < c.retired_at::date);

    if v_active_count = 0 then
      v_day := v_day + 1;
      continue;
    end if;

    v_all_done := (v_done_count = v_active_count);
    if v_all_done then
      v_streak := v_streak + 1;
    elsif v_mode = 'kind' and v_recoveries < 2 then
      v_recoveries := v_recoveries + 1;
      v_streak := v_streak + 1;
    else
      v_streak := 0;
    end if;
    v_day := v_day + 1;
  end loop;

  return query select
    v_streak,
    case when v_mode = 'kind'
      then v_recoveries
      else 0
    end,
    v_mode,
    v_today;
end;
$$;

revoke all on function public.get_streak(uuid) from public;
grant execute on function public.get_streak(uuid) to authenticated;
