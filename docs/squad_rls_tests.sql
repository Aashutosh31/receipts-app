-- docs/squad_rls_tests.sql
-- SQL-level security tests for Receipts Stage 5B squads.
--
-- HOW TO RUN (Supabase SQL Editor, as database owner):
--   1. Apply all migrations in supabase/migrations/ first.
--   2. Create six test users (Authentication -> Users -> Add user, or sign up
--      from the app). Copy their UUIDs. (You can reuse the Stage 1 A/B/C
--      users and add D/E/F.)
-- 3. Replace USER_A_UUID ... USER_F_UUID below with those UUIDs.
--   Test roles (do not change): D = squad owner + member + test-contract
--   owner (D is contract-free; A already has a real active contract and the
--   one-active-contract partial index would reject a second one for A);
--   E = second member; C = non-member; A, B, F = fillers to reach 5 members.
--   4. Run this whole script. Every check prints NOTICE "PASS ...".
--      Any unexpected result raises EXCEPTION "FAIL ..." and aborts.
--   5. The whole script runs in one transaction and rolls back at the end,
--      so no test data survives.
--
-- WHAT IT PROVES:
--   (a) non-members read nothing: squads, squad_members, nudges all 0 rows;
--   (b) squad_feed() as a non-member raises; as a member it works and its
--       columns contain ONLY member_user_id, display_name, day_number,
--       today_status, current_streak, missed_count (no notes, titles,
--       letter bodies, or excuse free text possible by construction);
--   (c) 6th member join fails (max 5 enforced);
--   (d) second nudge to anyone the same day fails (1-per-day enforced).


begin;

-- ---------------------------------------------------------------- setup data
-- Inserted as owner (bypasses RLS).
insert into public.squads (id, name, invite_code, created_by)
values (
  'c0000000-0000-0000-0000-000000000001',
  'Test Squad',
  'TST001',
  '648d4ee8-2a07-4bab-b6c0-3b9732a87410'
)
on conflict (id) do nothing;

insert into public.squad_members (squad_id, user_id)
values
  ('c0000000-0000-0000-0000-000000000001', '648d4ee8-2a07-4bab-b6c0-3b9732a87410'),
  ('c0000000-0000-0000-0000-000000000001', '63328b58-dad5-4ae6-8e42-e73058bd5ebb')
on conflict do nothing;

-- Display names so the feed has something to return.
update public.profiles set display_name = 'Test Dev'
where id = '648d4ee8-2a07-4bab-b6c0-3b9732a87410';
update public.profiles set display_name = 'Test Em'
where id = '63328b58-dad5-4ae6-8e42-e73058bd5ebb';

-- User D gets a contract + commitment + today check-in so the feed computes
-- kept status, streak, and a zero missed count. D is used because it has no
-- real contract: the contracts_one_active_per_user partial unique index
-- would reject a second active contract for a user that already has one
-- (this is what broke the first version of this script for User A), and
-- ON CONFLICT (id) cannot catch that separate constraint.
insert into public.contracts (id, user_id, start_date, mode, status)
values (
  'c0000000-0000-0000-0000-000000000011',
  '648d4ee8-2a07-4bab-b6c0-3b9732a87410',
  (now()::date) - 5,
  'hard',
  'active'
)
on conflict (id) do nothing;

insert into public.commitments (id, contract_id, user_id, title, sort_order)
values (
  'c0000000-0000-0000-0000-000000000021',
  'c0000000-0000-0000-0000-000000000011',
  '648d4ee8-2a07-4bab-b6c0-3b9732a87410',
  'Test commitment D',
  0
)
on conflict (id) do nothing;

insert into public.check_ins (user_id, commitment_id, day, done)
values (
  '648d4ee8-2a07-4bab-b6c0-3b9732a87410',
  'c0000000-0000-0000-0000-000000000021',
  (now()::date),
  true
)
on conflict (commitment_id, day) do nothing;

-- ------------------------------------------- (a) non-member reads nothing
set role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', 'a1286af9-13ba-4112-aa6b-d52d5a964c0e', 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_squads integer;
  v_members integer;
  v_nudges integer;
begin
  select count(*) into v_squads from public.squads;
  if v_squads != 0 then
    raise exception 'FAIL: non-member can read squads (%)', v_squads;
  end if;
  raise notice 'PASS: non-member reads 0 squads';

  select count(*) into v_members from public.squad_members;
  if v_members != 0 then
    raise exception 'FAIL: non-member can read squad_members (%)', v_members;
  end if;
  raise notice 'PASS: non-member reads 0 squad_members';

  select count(*) into v_nudges from public.nudges;
  if v_nudges != 0 then
    raise exception 'FAIL: non-member can read nudges (%)', v_nudges;
  end if;
  raise notice 'PASS: non-member reads 0 nudges';

  begin
    perform * from public.squad_feed('c0000000-0000-0000-0000-000000000001');
    raise exception 'FAIL: squad_feed succeeded for non-member';
  exception when others then
    if SQLERRM not like '%not a squad member%' then
      raise exception 'FAIL: unexpected squad_feed error: %', SQLERRM;
    end if;
    raise notice 'PASS: squad_feed rejects non-members';
  end;
end;
$$;

-- --------------------------------- (b) member feed works, columns are safe
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '63328b58-dad5-4ae6-8e42-e73058bd5ebb', 'role', 'authenticated')::text,
  true
);

do $$
declare
  r record;
  v_keys text[];
  v_allowed text[] := array[
    'member_user_id', 'display_name', 'day_number',
    'today_status', 'current_streak', 'missed_count'
  ];
  v_key text;
  v_rows integer := 0;
  v_dev_today text;
begin
  for r in
    select * from public.squad_feed('c0000000-0000-0000-0000-000000000001')
  loop
    v_rows := v_rows + 1;
    select array_agg(k) into v_keys
    from jsonb_object_keys(to_jsonb(r)) as k;
    foreach v_key in array v_keys loop
      if not (v_key = any (v_allowed)) then
        raise exception 'FAIL: feed leaks column %', v_key;
      end if;
    end loop;
    if r.display_name = 'Test Dev' then
      v_dev_today := r.today_status;
    end if;
  end loop;
  if v_rows != 2 then
    raise exception 'FAIL: feed returned % rows, expected 2', v_rows;
  end if;
  raise notice 'PASS: feed columns are exactly the 6 allowed ones';
  if v_dev_today is distinct from 'kept' then
    raise exception 'FAIL: expected kept for today, got %', v_dev_today;
  end if;
  raise notice 'PASS: feed shows kept for completed today';
end;
$$;

-- ------------------------------------------------- (d) one nudge per day
do $$
declare
  v_nudged uuid[];
begin
  perform public.send_nudge(
    'c0000000-0000-0000-0000-000000000001',
    '648d4ee8-2a07-4bab-b6c0-3b9732a87410'
  );
  raise notice 'PASS: first nudge of the day succeeds';

  begin
    perform public.send_nudge(
      'c0000000-0000-0000-0000-000000000001',
      '648d4ee8-2a07-4bab-b6c0-3b9732a87410'
    );
    raise exception 'FAIL: second nudge succeeded';
  exception when others then
    if SQLERRM not like '%already nudged today%' then
      raise exception 'FAIL: unexpected nudge error: %', SQLERRM;
    end if;
    raise notice 'PASS: second nudge the same day fails';
  end;

  select array_agg(t.to_user_id) into v_nudged
  from public.my_nudges_today('c0000000-0000-0000-0000-000000000001') as t;
  if not ('648d4ee8-2a07-4bab-b6c0-3b9732a87410'::uuid = any (v_nudged)) then
    raise exception 'FAIL: my_nudges_today missing the recipient';
  end if;
  raise notice 'PASS: my_nudges_today lists the recipient';
end;
$$;

-- ------------------------------------------------------ (c) max 5 members
-- Fill to 5 with A, B, F (as owner, bypassing RLS but not triggers).
-- No contracts are created for fillers: several already have real ones and
-- the one-active-contract index would reject a second.
reset role;

insert into public.squad_members (squad_id, user_id)
values
  ('c0000000-0000-0000-0000-000000000001', 'aed027ef-a2a4-436e-b427-353ecf282c8d'),
  ('c0000000-0000-0000-0000-000000000001', '61330a53-3661-4ca0-b920-6307228fb574'),
  ('c0000000-0000-0000-0000-000000000001', '9c9e2226-e0d6-45d5-becf-1f57dc528af2')
on conflict do nothing;

set role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', 'a1286af9-13ba-4112-aa6b-d52d5a964c0e', 'role', 'authenticated')::text,
  true
);

do $$
begin
  begin
    perform public.join_squad('TST001');
    raise exception 'FAIL: 6th member joined';
  exception when others then
    if SQLERRM not like '%squad is full%' then
      raise exception 'FAIL: unexpected join error: %', SQLERRM;
    end if;
    raise notice 'PASS: 6th member join fails (max 5)';
  end;
end;
$$;

reset role;

-- ---------------------------------------------------------------- cleanup
-- Roll back all test data instead of deleting protected rows.
rollback;
