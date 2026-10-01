# Decisions

## Stage 1 (2026-10-01)

1. **Supabase key name**: `supabase_flutter` 2.18 renamed `anonKey` to
   `publishableKey` (deprecated alias still exists, see
   https://pub.dev/packages/supabase_flutter/changelog#2130). The env file
   keeps the task-specified `SUPABASE_ANON_KEY` name; the initializer passes
   its value to `publishableKey`. Same public key, new parameter name.
2. **Android org**: `com.receipts` (`flutter create --org com.receipts`),
   applicationId `com.receipts.receipts`. Placeholder until a real domain
   exists.
3. **Commitment count 3-5**: max 5 enforced immediately by a BEFORE INSERT
   trigger; the full 3-5 range enforced by a DEFERRABLE constraint trigger
   at transaction commit. Single-statement PostgREST inserts can only grow a
   contract one row per transaction, so atomic creation must go through the
   `create_contract_with_commitments` RPC (contract + 3-5 commitments in one
   transaction). Documented in SUPABASE_SETUP constraints; UI (later stage)
   must use that RPC for the lock-in flow.
4. **Active-commitment counting**: the max-5 check counts all rows ever
   created for the contract (retired rows still count), so a contract can
   never exceed 5 commitments total. `get_ledger`/`get_streak` only consider
   commitments active on a given day (`created_at <= day < retired_at`).
5. **Check-in grace window**: target day accepted when it equals today in the
   user's profile timezone (server `now()`), or yesterday when local time is
   before 03:00. Mirrored in Dart `DateTimeUtils.canCheckInForDay` for tests;
   SQL triggers remain authoritative.
6. **Excuse 48h window**: deadline is 48 hours after the end of the missed
   day in the user's timezone
   (`((day+1) midnight local)::timestamptz + 48h >= now()`), past days only,
   and rejected when a done check-in exists for that commitment/day.
7. **Kind-mode recoveries**: the recovery budget (max 2) is consumed
   chronologically — the earliest misses use it first. A miss with budget
   left counts toward the streak; a miss with none resets to zero.
   `recoveries_used` is tracked during the forward walk. Paused days are
   skipped in both modes. Both the Dart `StreakLogic` and SQL `get_streak`
   implement this same forward walk (a unit test caught an earlier
   tail-budget version that tolerated the wrong misses).
8. **Letters**: direct `SELECT` on `letters.body` revoked from
   `anon`/`authenticated` (column-level grants for metadata only); body only
   flows through `get_letters()`, which returns NULL + `is_unlocked=false`
   before `start_date + unlock_day_number` (server date, user timezone).
9. **Contract dates**: `end_date` always overwritten to `start_date + 90` by
   trigger, backed by a CHECK constraint. `start_date` defaults to the
   server's current date.
10. **SQL validation without a live DB**: the sandbox Docker daemon was
    unresponsive, so migrations were validated with the `pglast` Postgres
    parser (all 5 files parse) plus manual review. Update 2026-10-01: all 5
    migrations were then applied to the live project via `supabase db push`,
    and the corrected `docs/rls_tests.sql` ran green in the SQL Editor.
    Live finding: with SELECT/INSERT-only RLS policies, a forbidden
    check_ins UPDATE/DELETE affects 0 rows instead of raising, so the test
    asserts `row_count == 0` (the `trg_check_ins_no_update` trigger remains
    as defense-in-depth); test cleanup uses ROLLBACK because contracts are
    delete-protected. See commit `cdab315`.
