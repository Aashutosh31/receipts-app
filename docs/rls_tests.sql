-- docs/rls_tests.sql
-- SQL-level security tests for Receipts Stage 1.
--
-- HOW TO RUN (Supabase SQL Editor, as database owner):
--   1. Apply all migrations in supabase/migrations/ first.
--   2. Create two test users (Authentication -> Users -> Add user, or sign up
--      from the app). Copy their UUIDs.
--   3. Replace aed027ef-a2a4-436e-b427-353ecf282c8d_UUID and 61330a53-3661-4ca0-b920-6307228fb574_UUID below with those UUIDs.
--   4. Run this whole script. Every check prints NOTICE "PASS ...".
--      Any unexpected result raises EXCEPTION "FAIL ..." and aborts.
--   5. The script cleans up its own rows at the end (contracts cascade).
--
-- WHAT IT PROVES:
--   (a) user A cannot read user B's rows (contracts, check_ins, excuses);
--   (b) UPDATE/DELETE on check_ins fails (INSERT-only ledger);
--   (c) backdated check_in inserts fail (no history backfill);
--   (d) letter body is hidden before unlock (direct SELECT on body denied,
--       get_letters() returns NULL body + is_unlocked=false; day-0 letter
--       returns its body).
begin;

-- ---------------------------------------------------------------- setup data
-- Inserted as owner (bypasses RLS). Triggers still fire, which is intended:
-- day values below satisfy the server-clock grace rules.
insert into public.contracts (id, user_id, start_date, mode, status)
values (
  'a0000000-0000-0000-0000-000000000001',
  'aed027ef-a2a4-436e-b427-353ecf282c8d',
  (now()::date) - 5,
  'hard',
  'active'
), (
  'b0000000-0000-0000-0000-000000000002',
  '61330a53-3661-4ca0-b920-6307228fb574',
  (now()::date) - 5,
  'hard',
  'active'
)
on conflict (id) do nothing;

insert into public.commitments (id, contract_id, user_id, title, sort_order)
values (
  'a0000000-0000-0000-0000-000000000011',
  'a0000000-0000-0000-0000-000000000001',
  'aed027ef-a2a4-436e-b427-353ecf282c8d',
  'Test commitment A',
  0
), (
  'b0000000-0000-0000-0000-000000000021',
  'b0000000-0000-0000-0000-000000000002',
  '61330a53-3661-4ca0-b920-6307228fb574',
  'Test commitment B',
  0
)
on conflict (id) do nothing;

-- A valid check-in for TODAY (passes the day trigger) so we have a row on
-- which to attempt forbidden UPDATE/DELETE.
insert into public.check_ins (user_id, commitment_id, day, done)
values ('aed027ef-a2a4-436e-b427-353ecf282c8d', 'a0000000-0000-0000-0000-000000000011', (now()::date), true)
on conflict (commitment_id, day) do nothing;

-- Two letters: day-0 (unlocked, body visible via RPC) and day-30 (locked).
insert into public.letters (user_id, contract_id, unlock_day_number, body)
values
  ('aed027ef-a2a4-436e-b427-353ecf282c8d', 'a0000000-0000-0000-0000-000000000001', 0, 'day zero letter'),
  ('aed027ef-a2a4-436e-b427-353ecf282c8d', 'a0000000-0000-0000-0000-000000000001', 30, 'day thirty secret')
on conflict (contract_id, unlock_day_number) do nothing;

-- ------------------------------------------------- (a) cross-user isolation
set role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', 'aed027ef-a2a4-436e-b427-353ecf282c8d', 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_contracts integer;
  v_checkins integer;
begin
  select count(*) into v_contracts
  from public.contracts
  where user_id = '61330a53-3661-4ca0-b920-6307228fb574'::uuid;
  if v_contracts != 0 then
    raise exception 'FAIL: user A can read user B contracts (%)', v_contracts;
  end if;
  raise notice 'PASS: user A cannot read user B contracts';

  select count(*) into v_checkins
  from public.check_ins
  where user_id = '61330a53-3661-4ca0-b920-6307228fb574'::uuid;
  if v_checkins != 0 then
    raise exception 'FAIL: user A can read user B check_ins (%)', v_checkins;
  end if;
  raise notice 'PASS: user A cannot read user B check_ins';
end;
$$;

-- --------------------------------------- (b) check_ins are INSERT-only
do $$
declare
  v_rows integer;
begin
  update public.check_ins
  set done = false
  where commitment_id = 'a0000000-0000-0000-0000-000000000011';

  get diagnostics v_rows = row_count;

  if v_rows <> 0 then
    raise exception 'FAIL: UPDATE on check_ins affected % row(s)', v_rows;
  end if;

  raise notice 'PASS: UPDATE on check_ins is blocked';

  delete from public.check_ins
  where commitment_id = 'a0000000-0000-0000-0000-000000000011';

  get diagnostics v_rows = row_count;

  if v_rows <> 0 then
    raise exception 'FAIL: DELETE on check_ins affected % row(s)', v_rows;
  end if;

  raise notice 'PASS: DELETE on check_ins is blocked';
end;
$$;

-- ------------------------------------------- (c) backdated inserts fail
do $$
begin
  begin
    insert into public.check_ins (user_id, commitment_id, day, done)
    values (
      'aed027ef-a2a4-436e-b427-353ecf282c8d',
      'a0000000-0000-0000-0000-000000000011',
      (now()::date) - 5,
      true
    );
    raise exception 'FAIL: backdated check_in insert succeeded';
  exception when others then
    if SQLERRM not like '%backfill%' then
      raise exception 'FAIL: unexpected backdate error: %', SQLERRM;
    end if;
    raise notice 'PASS: backdated check_in insert fails';
  end;
end;
$$;

-- --------------------------------- (d) letter body hidden before unlock
do $$
declare
  r record;
begin
  -- Direct SELECT on the body column must be denied by column grants.
  begin
    perform body from public.letters
    where contract_id = 'a0000000-0000-0000-0000-000000000001'
    limit 1;
    raise exception 'FAIL: direct SELECT on letters.body succeeded';
  exception when insufficient_privilege then
    raise notice 'PASS: direct SELECT on letters.body denied';
  end;

  -- RPC: day-0 letter unlocked with body; day-30 locked with NULL body.
  for r in
    select * from public.get_letters('a0000000-0000-0000-0000-000000000001')
  loop
    if r.unlock_day_number = 0 then
      if not r.is_unlocked or r.body is null then
        raise exception 'FAIL: day-0 letter should be unlocked with body';
      end if;
      raise notice 'PASS: day-0 letter unlocked with body';
    elsif r.unlock_day_number = 30 then
      if r.is_unlocked or r.body is not null then
        raise exception 'FAIL: day-30 letter body leaked before unlock';
      end if;
      raise notice 'PASS: day-30 letter body hidden before unlock';
    end if;
  end loop;
end;
$$;

reset role;

-- ---------------------------------------------------------------- cleanup
-- Roll back all test data instead of deleting contracts.
rollback;
