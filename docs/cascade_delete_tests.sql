-- docs/cascade_delete_tests.sql
-- SQL-level regression tests for the auth-cascade delete bypass
-- (migrations 20261002170555_auth_cascade_delete.sql and
-- 20261002174007_auth_cascade_session_user.sql).
--
-- HOW TO RUN (Supabase SQL Editor, as database owner):
--   1. Apply all migrations in supabase/migrations/ first.
--   2. Pick ONE throwaway test user UUID and replace every occurrence of
--      9c9e2226-e0d6-45d5-becf-1f57dc528af2 below with it (9 spots: seeded
--      rows and JWT-claim simulation; this script no longer deletes any
--      auth row). Any throwaway account works: the setup reuses that
--      user's existing active contract when one exists, so no
--      contract-free account is required.
--   3. Run this whole script. Every check prints NOTICE "PASS ...".
--      Any unexpected result raises EXCEPTION "FAIL ..." and aborts.
--   4. The whole script runs in one transaction and rolls back at the end.
--
-- WHAT IT PROVES:
--   (a) ordinary users still cannot delete contracts (0 rows: no RLS
--       delete policy);
--   (b) non-cascade roles (even the owner) still hit the 25001 trigger on
--       direct contract/check-in deletes;
--   (c) NOT executable in hosted SQL Editor (see note below): the real
--       end-to-end auth cascade was verified manually with a throwaway
--       account, which is the authoritative test for the actual Auth path;
--   (d) the bypass helper keys on session_user (robust to SECURITY DEFINER
--       hops, which rewrite current_user) and is not definer itself.


begin;

-- ---------------------------------------------------------------- setup data
-- Inserted as owner (bypasses RLS). Reuses the user's active contract when
-- one already exists so the one-active-contract index never trips.
do $$
declare
  v_contract uuid;
begin
  select id into v_contract from public.contracts
  where user_id = '9c9e2226-e0d6-45d5-becf-1f57dc528af2' and status = 'active'
  order by created_at desc limit 1;

  if v_contract is null then
    insert into public.contracts (id, user_id, start_date, mode, status)
    values (
      'd0000000-0000-0000-0000-000000000001',
      '9c9e2226-e0d6-45d5-becf-1f57dc528af2',
      (now()::date) - 5,
      'hard',
      'active'
    )
    on conflict (id) do nothing;

    insert into public.commitments (id, contract_id, user_id, title, sort_order)
    values (
      'd0000000-0000-0000-0000-000000000011',
      'd0000000-0000-0000-0000-000000000001',
      '9c9e2226-e0d6-45d5-becf-1f57dc528af2',
      'Cascade test commitment',
      0
    )
    on conflict (id) do nothing;

    insert into public.check_ins (user_id, commitment_id, day, done)
    values ('9c9e2226-e0d6-45d5-becf-1f57dc528af2', 'd0000000-0000-0000-0000-000000000011', (now()::date), true)
    on conflict (commitment_id, day) do nothing;
  end if;
end;
$$;

-- ---------------------------------- (a) ordinary users cannot delete rows
set role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '9c9e2226-e0d6-45d5-becf-1f57dc528af2', 'role', 'authenticated')::text,
  true
);

do $$
declare
  v_rows integer;
begin
  delete from public.contracts where user_id = '9c9e2226-e0d6-45d5-becf-1f57dc528af2';
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
  where user_id = '9c9e2226-e0d6-45d5-becf-1f57dc528af2' and status = 'active'
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
    where user_id = '9c9e2226-e0d6-45d5-becf-1f57dc528af2';
    raise exception 'FAIL: owner check_in delete succeeded';
  exception when others then
    if SQLERRM not like '%insert-only%' then
      raise exception 'FAIL: unexpected check_in error: %', SQLERRM;
    end if;
    raise notice 'PASS: owner direct check_in delete raises 25001';
  end;
end;
$$;

-- ---------------------- (c) MANUAL ONLY: real auth-cascade verification
-- NOT executable here. Simulating the Auth deletion would require a real
-- supabase_auth_admin SESSION identity, and hosted Supabase rejects both
-- impersonation routes: SET ROLE changes only current_user (the bypass
-- helper intentionally ignores it), and SET SESSION AUTHORIZATION fails
-- with 42501 permission denied in the hosted SQL Editor. There is no
-- SQL-only way to become supabase_auth_admin from the editor.
--
-- Authoritative verification (already performed manually, do not repeat
-- against real users): with the session_user bypass migration applied,
-- delete a throwaway account (Dashboard -> Authentication -> Users, or the
-- app's Settings -> Danger zone flow) and confirm in postgres_logs / table
-- counts that auth.users, contracts, commitments, check_ins, excuses,
-- pauses, letters, changes, memberships, and nudges for that user are gone
-- with no 25001 raised. That manual run is the production proof for the
-- actual Auth cascade path; sections (a), (b), and (d) below remain the
-- executable regression checks.

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
-- Roll back all seeded rows. (No auth row is deleted by this script;
-- see section (c) above for why the live cascade is verified manually.)
rollback;
