-- Receipts Stage 5B: squads, squad members (max 5), and nudges.
-- Squads let 3-5 friends see each other's misses. A secure RPC exposes ONLY
-- display name, day number, today's kept/missed status, current streak, and
-- missed count: never notes, letters, excuse free text, or commitment titles.
-- Membership changes and nudges go through RPCs; RLS stays owner/member-only.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------- squads
create table if not exists public.squads (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 60),
  invite_code text not null unique check (invite_code ~ '^[A-Z0-9]{6}$'),
  created_by uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.squads enable row level security;

-- NOTE: the squads member-gated SELECT policy lives below, right after the
-- squad_members table is created. Postgres validates policy expressions at
-- CREATE POLICY time, so it cannot reference squad_members before that
-- table exists (SQLSTATE 42P01 on first apply).

-- ---------------------------------------------------------- squad_members
create table if not exists public.squad_members (
  squad_id uuid not null references public.squads (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (squad_id, user_id)
);

alter table public.squad_members enable row level security;

-- A member can see their own membership rows (squad listing joins squads,
-- which is member-gated above).
drop policy if exists "squad_members_select_own" on public.squad_members;
create policy "squad_members_select_own"
  on public.squad_members for select
  to authenticated
  using (auth.uid() = user_id);

-- Leaving: a member can delete only their own row.
drop policy if exists "squad_members_delete_own" on public.squad_members;
create policy "squad_members_delete_own"
  on public.squad_members for delete
  to authenticated
  using (auth.uid() = user_id);

-- Members can read squads they belong to. Joining happens via the
-- join_squad() RPC (invite codes must not be enumerable by non-members).
drop policy if exists "squads_select_member" on public.squads;
create policy "squads_select_member"
  on public.squads for select
  to authenticated
  using (
    exists (
      select 1 from public.squad_members m
      where m.squad_id = squads.id and m.user_id = auth.uid()
    )
  );

-- Max 5 members per squad, enforced immediately.
create or replace function public.enforce_squad_size()
returns trigger
language plpgsql
as $$
declare
  v_count integer;
begin
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

drop trigger if exists trg_squad_members_size on public.squad_members;
create trigger trg_squad_members_size
  before insert on public.squad_members
  for each row execute function public.enforce_squad_size();

-- ----------------------------------------------------------------- nudges
-- One preset nudge per member per squad per day, server-enforced by the
-- unique constraint. The message text itself is fixed by check constraint.
create table if not exists public.nudges (
  id uuid primary key default gen_random_uuid(),
  squad_id uuid not null references public.squads (id) on delete cascade,
  from_user_id uuid not null references auth.users (id) on delete cascade,
  to_user_id uuid not null references auth.users (id) on delete cascade,
  day date not null default (now()::date),
  message text not null default 'Your squad noticed. Today still counts.'
    check (message = 'Your squad noticed. Today still counts.'),
  created_at timestamptz not null default now(),
  check (from_user_id != to_user_id),
  unique (squad_id, from_user_id, day)
);

alter table public.nudges enable row level security;

-- Members can read nudges in their squads (to see sent state and nudges
-- aimed at them) and insert only their own sends.
drop policy if exists "nudges_select_member" on public.nudges;
create policy "nudges_select_member"
  on public.nudges for select
  to authenticated
  using (
    exists (
      select 1 from public.squad_members m
      where m.squad_id = nudges.squad_id and m.user_id = auth.uid()
    )
  );

drop policy if exists "nudges_insert_own" on public.nudges;
create policy "nudges_insert_own"
  on public.nudges for insert
  to authenticated
  with check (auth.uid() = from_user_id);

-- Nudges are write-once: block UPDATE and DELETE for all roles.
create or replace function public.block_nudge_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'nudges cannot be edited or deleted'
    using errcode = '25001';
  return null;
end;
$$;

drop trigger if exists trg_nudges_no_mutation on public.nudges;
create trigger trg_nudges_no_mutation
  before update or delete on public.nudges
  for each row execute function public.block_nudge_mutation();

-- Both sides of a nudge must belong to the squad.
create or replace function public.check_nudge_membership()
returns trigger
language plpgsql
as $$
begin
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

drop trigger if exists trg_nudges_membership on public.nudges;
create trigger trg_nudges_membership
  before insert on public.nudges
  for each row execute function public.check_nudge_membership();

-- --------------------------------------------------------------- RPCs

-- Create a squad and join as its first member. Returns id + invite code.
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
    v_code := upper(substring(md5(gen_random_uuid()::text), 1, 6));
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

revoke all on function public.create_squad(text) from public;
grant execute on function public.create_squad(text) to authenticated;

-- Join by invite code (case-insensitive). Idempotent for existing members.
create or replace function public.join_squad(p_invite_code text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_squad uuid;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  select id into v_squad from public.squads
  where invite_code = upper(btrim(coalesce(p_invite_code, '')));
  if v_squad is null then
    raise exception 'no squad uses that invite code'
      using errcode = '23514';
  end if;
  if exists (
    select 1 from public.squad_members
    where squad_id = v_squad and user_id = v_user
  ) then
    return v_squad;
  end if;
  insert into public.squad_members (squad_id, user_id)
  values (v_squad, v_user);
  return v_squad;
end;
$$;

revoke all on function public.join_squad(text) from public;
grant execute on function public.join_squad(text) to authenticated;

-- Leave a squad (deletes only the caller's membership).
create or replace function public.leave_squad(p_squad_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  delete from public.squad_members
  where squad_id = p_squad_id and user_id = v_user;
end;
$$;

revoke all on function public.leave_squad(uuid) from public;
grant execute on function public.leave_squad(uuid) to authenticated;

-- Send today's preset nudge to one squadmate. Friendly error when the
-- daily limit is already used.
create or replace function public.send_nudge(
  p_squad_id uuid,
  p_to_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_to_user_id = v_user then
    raise exception 'you cannot nudge yourself' using errcode = '23514';
  end if;
  begin
    insert into public.nudges (squad_id, from_user_id, to_user_id)
    values (p_squad_id, v_user, p_to_user_id);
  exception when unique_violation then
    raise exception 'you already nudged today — one per day'
      using errcode = '23514';
  end;
end;
$$;

revoke all on function public.send_nudge(uuid, uuid) from public;
grant execute on function public.send_nudge(uuid, uuid) to authenticated;

-- Which squadmates the caller already nudged today (server UTC date,
-- matching the insert default).
create or replace function public.my_nudges_today(p_squad_id uuid)
returns table (to_user_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.squad_members
    where squad_id = p_squad_id and user_id = v_user
  ) then
    raise exception 'not a squad member' using errcode = '42501';
  end if;
  return query
  select n.to_user_id from public.nudges n
  where n.squad_id = p_squad_id
    and n.from_user_id = v_user
    and n.day = (now()::date);
end;
$$;

revoke all on function public.my_nudges_today(uuid) from public;
grant execute on function public.my_nudges_today(uuid) to authenticated;

-- Squad feed: per member ONLY display name, day number, today's
-- kept/missed status, current streak, and missed count. Never notes,
-- letters, excuse free text, or commitment titles.
create or replace function public.squad_feed(p_squad_id uuid)
returns table (
  member_user_id uuid,
  display_name text,
  day_number integer,
  today_status text,
  current_streak integer,
  missed_count integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  r record;
  v_owner uuid;
  v_start date;
  v_end date;
  v_mode text;
  v_tz text;
  v_today date;
  v_day date;
  v_paused boolean;
  v_active integer;
  v_done integer;
  v_streak integer;
  v_recoveries integer;
  v_missed integer;
  v_today_status text;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if not exists (
    select 1 from public.squad_members
    where squad_id = p_squad_id and user_id = v_user
  ) then
    raise exception 'not a squad member' using errcode = '42501';
  end if;

  for r in
    select m.user_id as member_id,
           coalesce(p.display_name, 'Squadmate') as name
    from public.squad_members m
    left join public.profiles p on p.id = m.user_id
    where m.squad_id = p_squad_id
    order by name
  loop
    v_owner := null;
    v_start := null;
    select user_id, start_date, end_date, contracts.mode
      into v_owner, v_start, v_end, v_mode
    from public.contracts
    where contracts.user_id = r.member_id
      and contracts.status = 'active'
    order by contracts.created_at desc
    limit 1;

    if v_owner is null then
      member_user_id := r.member_id;
      display_name := r.name;
      day_number := null;
      today_status := null;
      current_streak := null;
      missed_count := null;
      return next;
      continue;
    end if;

    select timezone into v_tz
    from public.profiles where profiles.id = r.member_id;
    if v_tz is null then
      v_tz := 'UTC';
    end if;
    v_today := ((now() at time zone v_tz))::date;

    v_streak := 0;
    v_recoveries := 0;
    v_missed := 0;
    v_day := v_start;
    while v_day <= least(v_today, v_end) loop
      select exists (
        select 1 from public.pauses p
        where p.user_id = r.member_id
          and v_day >= p.start_day
          and (p.end_day is null or v_day <= p.end_day)
      ) into v_paused;
      if v_paused then
        v_day := v_day + 1;
        continue;
      end if;

      select count(*), count(*) filter (where ci.done is true)
        into v_active, v_done
      from public.commitments c
      left join public.check_ins ci
        on ci.commitment_id = c.id and ci.day = v_day
      where c.user_id = r.member_id
        and v_day >= c.created_at::date
        and (c.retired_at is null or v_day < c.retired_at::date);

      if v_active = 0 then
        v_day := v_day + 1;
        continue;
      end if;

      if v_done = v_active then
        v_streak := v_streak + 1;
      else
        v_missed := v_missed + 1;
        if v_mode = 'kind' and v_recoveries < 2 then
          v_recoveries := v_recoveries + 1;
          v_streak := v_streak + 1;
        else
          v_streak := 0;
        end if;
      end if;
      v_day := v_day + 1;
    end loop;

    -- Today's kept/missed/paused verdict for this member.
    v_today_status := null;
    if v_today between v_start and v_end then
      select exists (
        select 1 from public.pauses p
        where p.user_id = r.member_id
          and v_today >= p.start_day
          and (p.end_day is null or v_today <= p.end_day)
      ) into v_paused;
      if v_paused then
        v_today_status := 'paused';
      else
        select count(*), count(*) filter (where ci.done is true)
          into v_active, v_done
        from public.commitments c
        left join public.check_ins ci
          on ci.commitment_id = c.id and ci.day = v_today
        where c.user_id = r.member_id
          and v_today >= c.created_at::date
          and (c.retired_at is null or v_today < c.retired_at::date);
        if v_active = 0 then
          v_today_status := null;
        elsif v_done = v_active then
          v_today_status := 'kept';
        else
          v_today_status := 'missed';
        end if;
      end if;
    end if;

    member_user_id := r.member_id;
    display_name := r.name;
    day_number := (v_today - v_start) + 1;
    today_status := v_today_status;
    current_streak := v_streak;
    missed_count := v_missed;
    return next;
  end loop;
end;
$$;

revoke all on function public.squad_feed(uuid) from public;
grant execute on function public.squad_feed(uuid) to authenticated;
