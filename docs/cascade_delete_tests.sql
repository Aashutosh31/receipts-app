-- docs/cascade_delete_tests.sql
-- SQL-level regression tests for the auth-cascade delete bypass
-- (migrations 20261002170555_auth_cascade_delete.sql and
-- 20261002174007_auth_cascade_session_user.sql).
--
-- HOW TO RUN (Supabase SQL Editor, as database owner):
--   1. Apply all migrations in supabase/migrations/ first.
--   2. Pick ONE throwaway test user for the cascade step below and put
--      their UUID in USER_F_UUID. The script deletes that auth.users row
--      and verifies the cascade, then ROLLS BACK so nothing persists.
--      USER_F is suggested (least used by manual testing).
--   3. Replace USER_F_UUID below with that UUID.
--   4. Run this whole script. Every check prints NOTICE "PASS ...".
--      Any unexpected result raises EXCEPTION "FAIL ..." and aborts.
--   5. The whole script runs in one transaction and rolls back at the end.
--
-- WHAT IT PROVES:
--   (a) ordinary users still cannot delete contracts (0 rows: no RLS
--       delete policy);
--   (b) non-cascade roles (even the owner) still hit the 25001 trigger on
--       direct contract/check-in deletes;
--   (c) deleting auth.users under a real supabase_auth_admin SESSION
--       (via SET SESSION AUTHORIZATION, superuser-only) cascades through
--       contracts, commitments, and check-ins with no 25001. Plain
--       SET ROLE would only change current_user and stay blocked;
--   (d) the bypass helper keys on session_user (robust to SECURITY DEFINER
--       hops, which rewrite current_user) and is not definer itself.

\set user_f USER_F_UUID

begin;

-- ---------------------------------------------------------------- setup data
-- Inserted as owner (bypasses RLS). Reuses F's active contract when one
-- already exists so the one-active-contract index never trips.
do $$
declare
  v_contract uuid;
begin
  select id into v_contract from public.contracts
  where user_id = :'user_f' and status = 'active'
  order by created_at desc limit 1;

  if v_contract is null then
    insert into public.contracts (id, user_id, start_date, mode, status)
    values (
      'd0000000-0000-0000-0000-000000000001',
      :'user_f',
      (now()::date) - 5,
      'hard',
      'active'
    )
    on conflict (id) do nothing;

    insert into public.commitments (id, contract_id, user_id, title, sort_order)
    values (
      'd0000000-0000-0000-0000-000000000011',
      'd0000000-0000-0000-0000-000000000001',
      :'user_f',
      'Cascade test commitment',
      0
    )
    on conflict (id) do nothing;

    insert into public.check_ins (user_id, commitment_id, day, done)
    values (:'user_f', 'd0000000-0000-0000-0000-000000000011', (now()::date), true)
    on conflict (commitment_id, day) do nothing;
  end if;
end;
$$;

-- ---------------------------------- (a) ordinary users cannot delete rows
set role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', :'user_f', 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_rows integer;
begin
  delete from public.contracts where user_id = :'user_f';
  get diagnostics v_rows = row_count;
  if v_rows <> 0 then
    raise exception 'FAIL: user deleted % contract row(s)', v_rows;
  end if;
  raise notice 'PASS: user contract delete affects 0 rows (no RLS policy)';
end;
$$;

-- ----------------- (b) non-cascade roles still hit the delete triggers
reset role;

do $$
declare
  v_contract uuid;
begin
  select id into v_contract from public.contracts
  where user_id = :'user_f' and status = 'active'
  order by created_at desc limit 1;

  begin
    delete from public.contracts where id = v_contract;
    raise exception 'FAIL: owner contract delete succeeded';
  exception when others then
    if SQLERRM not like '%contracts cannot be deleted%' then
      raise exception 'FAIL: unexpected contract error: %', SQLERRM;
    end if;
    if SQLSTATE != '25001' then
      raise exception 'FAIL: expected 25001, got %', SQLSTATE;
    end if;
    raise notice 'PASS: owner direct contract delete raises 25001';
  end;

  begin
    delete from public.check_ins
    where user_id = :'user_f';
    raise exception 'FAIL: owner check_in delete succeeded';
  exception when others then
    if SQLERRM not like '%insert-only%' then
      raise exception 'FAIL: unexpected check_in error: %', SQLERRM;
    end if;
    raise notice 'PASS: owner direct check_in delete raises 25001';
  end;
end;
$$;

-- ---------------------- (c) auth cascade deletes through the blockers
-- Supabase Auth deletes auth.users as supabase_auth_admin (see production
-- postgres_logs: db_role supabase_auth_admin, DELETE FROM users).
-- The bypass helper keys on session_user, so this section must change the
-- SESSION identity, not merely SET ROLE (which only rewrites current_user
-- and would still be blocked, exactly like the production failure before
-- the session_user fix). SET SESSION AUTHORIZATION requires superuser;
-- the SQL Editor runs as postgres, so this works here. Everything below
-- still rolls back at the end.
set session authorization supabase_auth_admin;

do $$
declare
  v_contracts integer;
  v_commitments integer;
  v_checkins integer;
begin
  delete from auth.users where id = :'user_f';

  select count(*) into v_contracts from public.contracts
  where user_id = :'user_f';
  select count(*) into v_commitments from public.commitments
  where user_id = :'user_f';
  select count(*) into v_checkins from public.check_ins
  where user_id = :'user_f';

  if v_contracts != 0 or v_commitments != 0 or v_checkins != 0 then
    raise exception
      'FAIL: cascade leftovers contracts=% commitments=% check_ins=%',
      v_contracts, v_commitments, v_checkins;
  end if;
  raise notice 'PASS: auth cascade deleted contracts, commitments, check_ins';
end;
$$;

-- Back to the owner session for the remaining checks. (RESET ROLE alone
-- would not suffice: it restores current_user but leaves session_user
-- switched, which is precisely the distinction under test.)
reset session authorization;

-- -------- (d) bypass helper keys on session_user, stays invoker, read-only
-- current_user can change under SECURITY DEFINER execution while
-- session_user keeps identifying the original session login, so the bypass
-- must key on session_user. This checks the live definition without
-- deleting anything.
do $$
declare
  v_src text;
  v_definer boolean;
begin
  select prosrc, prosecdef into v_src, v_definer
  from pg_proc
  where pronamespace = 'public'::regnamespace
    and proname = 'is_auth_account_cascade';
  if v_src is null then
    raise exception 'FAIL: is_auth_account_cascade() missing';
  end if;
  if v_src not like '%session_user%' then
    raise exception 'FAIL: helper does not check session_user';
  end if;
  if v_src like '%current_user%' then
    raise exception 'FAIL: helper still references current_user';
  end if;
  if v_definer then
    raise exception 'FAIL: helper must stay SECURITY INVOKER';
  end if;
  raise notice 'PASS: bypass keys on session_user, invoker, present';
end;
$$;

-- ---------------------------------------------------------------- cleanup
-- Roll back everything, including the auth.users delete above.
rollback;
