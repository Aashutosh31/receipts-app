## Stage 5B (squads)

1. **Membership writes go through RPCs only** (`create_squad`, `join_squad`,
   `leave_squad`): invite codes must not be enumerable, and creation must
   atomically add the creator. Tables carry member/owner-gated SELECT
   policies; squads and memberships have no direct INSERT policies.
2. **Max 5 enforced by trigger** (`enforce_squad_size`); multiple squads per
   user allowed (simpler than a one-squad rule, same cap).
3. **Nudge = 1 per sender per squad per day** via a unique constraint (race
   safe), with a friendly duplicate message; the single preset text is
   pinned by a check constraint. Nudge day uses server UTC date, matching
   the insert default and the `my_nudges_today` lookup.
4. **Feed privacy by construction**: `squad_feed()` returns exactly 6
   columns (member id, display name, day number, today status, streak,
   missed count). Per-member timezone mirrors `get_streak`; members without
   contracts get null rows rather than being hidden.
5. **No-contract members keep a disabled Nudge button** (visible, honest)
   instead of disappearing from the feed.

## Stage 5A (offline outbox with drift)

1. **drift 2.35.1 + drift_flutter 0.3.1** (codegen via drift_dev +
   build_runner, committed `.g.dart`). One SQLite file, every row keyed by
   owning user_id; queries always filter by it.
   See: https://drift.simonbinder.eu/docs/getting-started/
2. **Server judges, client explains**: outbox rows carry the device-date day;
   late arrivals are rejected by the existing same-day trigger. Rejections
   are marked failed with the server message verbatim and kept until the
   user dismisses them — never silently dropped, never auto-retried into
   the same wall (a duplicate-key rejection counts as sent: the row exists).
3. **Offline numbers are labeled approximate**: streak/day-number derive
   locally from cache via the existing pure StreakLogic; only the server
   RPCs date records.
4. **bluetooth-only counts as offline** for sync purposes (needs wifi,
   mobile, or ethernet).
5. **Sync points**: app open (Gate), reconnect (connectivity listener),
   pull-to-refresh, post-mutation invalidates — never blocking UI.

## Stage 4 (insights, letters, receipt, retire friction)

1. **Charts**: verified fl_chart 1.2.0 is healthy (7.2k likes, 150 pub
   points, verified publisher) but chose plain Flutter widgets instead:
   zero new dependency/version risk, matches the dark-minimal aesthetic,
   and renders identically inside the shareable RepaintBoundary card.
2. **Letters**: day-1 gate requires the day-0 letter until written
   (PopScope-blocked, non-dismissible). Milestones 30/60/90 may be written
   any time before unlock; bodies travel only via get_letters(), and the
   RPC's is_unlocked flag (server time) is authoritative for reveals,
   countdowns, and the Final Receipt gate.
3. **Share image excludes private content**: the captured card shows
   aggregates only (kept/total, longest streak, top excuse). Letter bodies
   and excuse free texts never enter the shared image or share text.
4. **Retire writes two rows**: UPDATE retired_at (the database trigger
   auto-logs a system `retire` row) plus an explicit user-reason `retire`
   row. Both appear in the Ledger's Contract changes section.
5. **share_plus 13.3.1** (Flutter Favorite): `SharePlus.instance.share`
   with `ShareParams(files, fileNameOverrides, sharePositionOrigin)` for the
   iPad popover anchor. PNG bytes go to a temp file via path_provider.
   See: https://pub.dev/packages/share_plus#share-files

## Auth-scoping hotfix (multi-user isolation)

1. **User-scoped providers await the live user id**: `currentUserIdProvider`
   (from the Supabase auth stream) is watched by every user-data provider, so
   A -> null -> B always refetches and signed-out reads short-circuit to
   null/empty without querying. RLS remains the server-side enforcement;
   providers just stop serving cross-user memory cache.
2. **autoDispose on user-scoped providers**: caches die with their last
   listener as defense in depth alongside the session watch.
3. **Per-user reminder settings keys**: `reminder_settings_v1_<userId>`
   (signed-out gets an unreachable key), so shared devices cannot leak
   quiet hours, tone, toggles, or permission state across users.
4. **Test fakes replay an initial session** like gotrue does, so provider
   tests settle deterministically (`test/test_fakes.dart`).

## Stage 3 (reminders)

1. **Exact alarms via SCHEDULE_EXACT_ALARM, never USE_EXACT_ALARM**: the
   latter is reserved for alarm-clock/calendar apps and risks Play Store
   rejection. Denied/unavailable exact alarms degrade honestly to
   `inexactAllowWhileIdle` and the UI says which mode is active.
   See: https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
2. **iOS honesty**: no true alarms on iOS, only UserNotifications; at most
   64 pending requests system-wide, so scheduling caps at 60 and packs
   day-major order. Documented on the permission screen.
   See: https://pub.dev/packages/flutter_local_notifications#ios-pending-notifications-limit
3. **Rolling 7-day window, refreshed on app open**: covers app updates,
   contract edits, and timezone changes (device reboot restore is handled
   by the plugin's own boot receiver; the window extension happens here).
4. **Deterministic notification IDs** (FNV-1a over day|commitment|kind):
   Dart's `String.hashCode` is unstable across runs, which would orphan
   follow-ups after a restart and break cancel-on-Done.
5. **Quiet hours shift, never drop**: reminders inside the window move to
   its end (rolling past midnight when needed). Default 22:00-07:00.
6. **Tone is a cap, pauses force calm**: escalation runs on trailing
   consecutive misses; the user's tone setting only caps it, and pause days
   always use the softened pool.
7. **Notification taps just open the app**: deep-link routing of taps is
   future work; the callback is a documented no-op for now.
8. **Settings live in SharedPreferences**, not Supabase: they are
   device-local prefs (Stage 5 drift is for cached backend data).

## Stage 2 (2026-10-02)

1. **Auth guard shape**: go_router `redirect` handles only the synchronous
   session check; contract onboarding gating lives in `GateScreen`, which
   loads the active contract async and navigates post-frame. Keeps slow
   queries out of navigation.
2. **Today rows use `done`, not `status`**: for the current day the SQL
   `status` is `missed` until a check-in exists, but the UI says "Not yet
   logged today" — a day is only a miss once it is over.
3. **Done is disabled while paused**: a paused day carries no obligation, so
   the Today list shows a rest banner instead of active Done buttons.
4. **Excuse sheet is required**: it is non-dismissible and steps through
   every pending miss; the client uses a 2-calendar-day approximation of the
   48h window while the database trigger enforces the exact deadline.
5. **Onboarding start date**: the pledge screen previews the end date from
   the device date, but the server sets the real `start_date` on insert
   (AGENTS.md server-truth rule); the RPC overwrites `end_date`.
6. **No letters/excuse-analytics/squads/notifications**: excluded per the
   Stage 2 brief; the unused Stage 1 `ExcuseAnalytics` helper stays for later.

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
