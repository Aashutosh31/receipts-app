# Progress

## Done (Stage 1: project foundation + backend schema)

- Flutter 3.47.5 app `receipts` scaffolded (Android + iOS, org `com.receipts`).
- Dependencies (pub.dev latest stable, verified 2026-10-01): flutter_riverpod
  3.4.3, go_router 18.0.2, supabase_flutter 2.18.0, intl 0.20.3.
- Architecture skeleton: `lib/core` (theme, router, supabase, utils) +
  `lib/features/{contract,ledger,excuse}/{data,domain,presentation}`.
  Repository (`ContractRepository`) wraps Supabase; UI never calls Supabase.
- Env handling: `env.json` (gitignored) + `env.example.json`;
  `SupabaseInitializer` reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` via
  `String.fromEnvironment`. Run command:
  `flutter run --dart-define-from-file=env.json`
- Dark minimal theme, go_router foundation route, missing-config placeholder
  screen; loading/error/empty-state handling pattern in place.
- Supabase migrations (`supabase/migrations/`, timestamped, RLS everywhere):
  profiles + auto-create trigger, contracts (one-active partial index,
  end=start+90), commitments (max-5 + deferred 3-5 triggers, retire-only
  updates, auto-log to contract_changes), contract_changes (append-only),
  check_ins (insert-only, server-clock day + 03:00 grace, contract-range
  check), excuses (enum, past-days-only, 48h window, no-done-check-in),
  pauses (insert + single end_day update, no overlap, no delete), letters
  (column-grant body protection + `get_letters()` RPC).
- RPCs: `create_contract_with_commitments`, `get_letters`, `get_ledger`,
  `get_streak` (hard/kind + pauses).
- Pure-Dart mirrors with unit tests: streak, ledger, excuse analytics,
  date/time grace logic.
- Docs: `docs/SUPABASE_SETUP.md`, `docs/rls_tests.sql`, `docs/DECISIONS.md`.
- Quality gates green: pub get, format, analyze, test, debug APK.
- Live Supabase verification (owner, 2026-10-01, commit `cdab315`): all 5
  migrations applied via `supabase db push`, all 8 tables present, Email auth
  enabled, `env.json` holds only URL + anon key. Corrected
  `docs/rls_tests.sql` ran green in the SQL Editor: cross-user reads return
  0 rows, check_ins UPDATE/DELETE affect 0 rows (RLS has no UPDATE/DELETE
  policies; trigger `trg_check_ins_no_update` verified present as
  defense-in-depth), backdated inserts rejected, letter body hidden
  pre-unlock via `get_letters()`.

## Done (Stage 2: working MVP)

- Auth: email/password sign up (with email-confirmation pending state),
  sign in, sign out with confirm, persistent session via supabase_flutter,
  auth-guarded routes (`/signin`, `/signup` public; everything else requires
  a session; first-time users land on `/contract/new`).
- Onboarding "Sign the Contract": 3-5 commitments (title + optional
  HH:MM target time), Hard/Kind Mode cards with plain-language explanations,
  pledge screen showing the 90-day end date, signed by typing a name. Writes
  atomically via `create_contract_with_commitments`.
- Today screen: server-truth day number (`get_streak.today`), streak header,
  honest status line, per-commitment Done buttons behind a "final, cannot be
  edited" confirm sheet, pause declare/end entry, sign out.
- Ledger screen: 90-day read-only grid (kept/missed/paused/upcoming + legend,
  today outlined), tap-a-day sheet with promised vs done per commitment.
- Missed-day flow: on app open, unexcused misses inside the 48h window open a
  required, non-dismissible "Tag your excuse" sheet (5 reasons + optional
  280-char note) stepping through each miss.
- Sick/Injury mode: declare from today (sick/injury), end an open pause;
  paused days render visibly in Today and Ledger and never break the streak.
- Reusable `core/widgets`: Loading/Error/Empty states on every screen,
  AppButton, final-confirm sheet, StatusChip, bottom nav.
- Tests: 52 green, including mocked-repository Today widget tests (fakes
  implement the repository interfaces via ProviderScope overrides).
- Quality gates green: pub get, format, analyze (zero), test, debug APK.
- Manual acceptance on a physical Android phone (owner, post-`831a8f2`):
  fresh auth flow, account creation, confirmation email sent, sign-in,
  contract lock-in with 3 commitments, Kind Mode, typed-name pledge, Day 1
  of 90 with correct streak/status, check-ins persisting across reopen,
  read-only Ledger, sick/injury pause flow, sign-out. No Stage 3+ features
  tested or built.

## Fixed (auth-cascade delete bypass)

- Production delete-account failed with 25001 because the contract
  immutability trigger (and the 8 sibling blockers) rejected the internal
  Supabase Auth cascade. New migration
  `20261002170555_auth_cascade_delete.sql` lets only `supabase_auth_admin`
  through; RLS, messages, and all other rules unchanged. Proven by
  `docs/cascade_delete_tests.sql` (owner runs it; rolls back). Edge Function
  untouched — no separate issue found.

## Fixed (auth-scoping hotfix)

- Multi-user isolation bug: user-scoped providers survived sign-out/sign-in,
  so User B/C saw User A's cached contract. Fixed by scoping every
  user-data provider to the live auth user id (`currentUserIdProvider`) plus
  autoDispose, and per-user reminder-settings keys. Backend RLS untouched
  (was already correct). Regression tests: A -> null -> B refetch behavior
  and per-user settings isolation. Tests: 86 green.

## Done (Stage 3: local reminders)

- Packages (pub.dev latest stable): flutter_local_notifications 22.3.1,
  timezone 0.11.1, flutter_timezone 5.1.0, shared_preferences (settings).
- Android setup per plugin README: desugaring + Java 17, RECEIVE_BOOT_COMPLETED
  and SCHEDULE_EXACT_ALARM permissions, scheduled/boot receivers, release
  keep.xml for the notification icon.
- `NotificationService` behind an interface, started in `main()` with the
  timezone database and device location (flutter_timezone, UTC fallback).
- Permission flow: explanation-first screen on first Today visit;
  Android 13+ notification prompt, exact-alarm request with honest
  exact-vs-approximate status; iOS limits documented in-app (no true alarms,
  64 pending cap). Re-reviewable from Settings.
- Scheduling: per-commitment target-time reminder + 30-minute follow-up
  (skipped/cancelled when done), one 21:00 last call per day, rolling 7-day
  window capped at 60, refreshed on every app open (covers updates, edits,
  timezone changes; reboot restore via plugin receiver). Quiet hours shift
  instead of dropping (default 22:00-07:00).
- Message engine: 78 templates in calm/firm/blunt tiers using title, target,
  now, streak, day, last excuse, done/total; escalation on consecutive misses
  capped by the tone setting; pause days always softened. Banned-word test
  guards against insults and weight/body references.
- Settings screen: live status (on/off, exact/approximate, scheduled count),
  quiet-hours pickers, tone cap, per-commitment toggles, sign out.
- Tests: 84 green (message engine, scheduling math incl. midnight/DST edges,
  mocked-repo widget tests incl. settings/permission screens).
- Quality gates green: pub get, format, analyze (zero), test, debug APK.
- Native verification via `aapt dump` on the debug APK: merged manifest holds
  INTERNET, POST_NOTIFICATIONS, VIBRATE, RECEIVE_BOOT_COMPLETED and
  SCHEDULE_EXACT_ALARM (no USE_EXACT_ALARM) plus both scheduled-notification
  receivers with boot/update intent filters.
- No emulator in this sandbox (system-image/emulator downloads stall), so
  on-device notification delivery still needs the real-phone checklist.

## Done (Stage 4: insights, letters, receipt, retire friction)

- Packages (pub.dev verified): share_plus 13.3.1 + path_provider for the
  shareable image. fl_chart 1.2.0 checked healthy but deliberately not used;
  charts are plain Flutter widgets (zero new native deps, same render in the
  share card).
- Insights tab: top excuse with counts, weekday / commitment breakdowns,
  weekly trend strip, and a data-generated one-line insight
  (e.g. weekday or commitment concentration). Respectful empty states before
  day 7 and when no excuses exist.
- Letters tab: milestone cards (day 1/30/60/90) with server-time countdowns;
  required day-1 writing screen (blocked back navigation until sealed);
  reveal screens pairing each unlocked letter with since-day-1 stats
  (kept rate, top excuse, streak).
- Final Receipt (gated on day-90 unlock): promised vs kept, kept rate,
  longest streak, top excuse, day-1 letter. Share button captures an
  aggregates-only RepaintBoundary card to PNG and opens the platform share
  sheet; letter text and free-text notes never leave the app.
- Retire friction: per-commitment menu on Today opens a sheet showing live
  streak + day number, requires a written reason, then retires (trigger row
  plus user-reason row, both listed in a new Contract changes section on
  the Ledger).
- Tests: 110 green (analytics math + insight variants, letter countdown and
  validation, receipt aggregates, RPC lock states via fakes).
- Quality gates green: pub get, format, analyze (zero), test, debug APK.

## Done (Stage 5A: offline outbox)

- drift 2.35.1 + drift_flutter 0.3.1 cache contract/commitments/ledger for
  offline reading (codegen committed); outbox queue for offline check-ins
  with pending/failed states; late arrivals rejected by the server stay
  visible with the server message until dismissed — never silently dropped.
- Sync on app open, reconnect, pull-to-refresh, and after mutations;
  connectivity_plus gating (wifi/mobile/ethernet only). Offline Today/Ledger
  render from cache with honest approximate labels; Outbox screen + banners.
- Tests: 120 green, incl. in-memory drift tests (queue, rejection honesty,
  duplicate-as-sent, cache round-trip, per-user isolation).
- Quality gates green: pub get, format, analyze (zero), test, debug APK.

## Done (Stage 5B: squads)

- Migration `20261002140000_squads.sql` (parser-validated; needs live
  `db push` by owner): `squads` (unique 6-char invite codes),
  `squad_members` (max 5 via trigger), `nudges` (1 preset message pinned by
  check, 1 per sender per squad per day via unique constraint, write-once).
  RLS member/owner-gated; membership writes RPC-only.
- RPCs: `create_squad` (atomic creator membership + collision-safe codes),
  `join_squad` (case-insensitive, idempotent), `leave_squad`,
  `send_nudge` (friendly daily-limit error), `my_nudges_today`, and
  `squad_feed` returning exactly 6 privacy-safe columns (verified by
  `docs/squad_rls_tests.sql`: non-member reads 0 rows, feed rejects
  non-members, 6th join fails, 2nd nudge fails).
- Squads tab: list, create (shows code once), join-by-code, feed with
  kept/missed/paused chips + streaks + miss counts, per-member nudge
  buttons with sent state, leave with confirm.
- Tests: 129 green (invite validation, feed parsing incl. null rows,
  faked feed/nudge UI + provider tests).

## Done (Stage 5C: release readiness)

- Icon + splash via official tooling (flutter_launcher_icons 0.14.4,
  flutter_native_splash 2.4.8): dark receipt-slip mark from
  `assets/icon/app_icon.png`, `#0A0A0B` splash incl. Android 12+ section.
- Release config: `applicationId com.receipts.receipts`, version from
  pubspec; `android/key.properties` signing with committed `.example`
  template (secrets gitignored, debug fallback for local runs);
  `flutter build appbundle --release` green (55MB `.aab`).
- `docs/RELEASE.md`: keystore steps, bundle build, internal-testing rollout,
  and the closed-testing rule for new personal accounts (≥12 testers,
  14 continuous days, official Play help article 14151465).
- Privacy + deletion: `docs/PRIVACY.md` (plain-language storage list, squad
  visibility limits, cascade consequences); `delete-account` Edge Function
  (service key server-side secret only); in-app Settings danger zone (type
  DELETE → server delete → local cache/settings wipe → sign-out).
- Final audit: no service_role or secrets in app code/git, no JWT-like
  strings, RLS on all 11 tables (script-verified), squad RPCs
  authenticated-only. See `docs/FINAL_CHECKLIST.md` (incl. owner manual
  steps: push squad migration, deploy function, host privacy URL, Play
  rollout).
- Tests: 133 green. Quality gates green: pub get, format, analyze (zero),
  test, debug APK + release appbundle.

## Next

- Project complete through Stage 5. Remaining owner-side work is listed in
  `docs/FINAL_CHECKLIST.md` (live migration push, function deploy, Play
  rollout, real-phone verification).

## Security audit (public-repo readiness)

- Full read-first audit in `docs/SECURITY_AUDIT.md` (gitleaks clean history,
  RLS verified on all 11 tables, manifest/DB hardening, supply chain clean).
- Fixed in follow-up commits: release INTERNET permission, `allowBackup`
  off, explicit no-cleartext, timezone-change cooldown + pause-date bounds
  + invite-entropy + size-race lock + nudge-day pin (new hardening
  migration, owner applies via `db push`), extended attack coverage in
  `docs/rls_tests.sql`, `SECURITY.md`, pinned-SHA CI, Dependabot, edge JS
  pin. Gates green (analyze zero, 135 tests, debug APK).
- Still needs the owner: service_role rotation, hardening migration push,
  live SQL tests, dashboard checklist, signed AAB, privacy URL, LICENSE
  choice, GitHub settings (see audit §7). Verdict stays negative until
  rotation is confirmed.

## How to run

```sh
flutter pub get
flutter run --dart-define-from-file=env.json
```

### On an Android emulator

1. Create an emulator (Android Studio → Device Manager, or):
   ```sh
   flutter emulators --create
   flutter emulators --launch <emulator_id>
   ```
2. Confirm it is visible: `flutter devices`
3. Run the app on it (first run grants no special permissions):
   ```sh
   flutter run --dart-define-from-file=env.json -d <emulator_id>
   ```
4. If the Gradle build fails under Java 27, prefix the run command with
   `JAVA_HOME=$HOME/development/jdk17` (see Known issues).

## Known issues

- Docker daemon hung in this sandbox during Stage 1, so migrations were
  additionally parser-validated (`pglast`) before the live `db push`.
- `flutter build apk --debug` requires Android SDK (present here); iOS build
  needs macOS/Xcode and is untested.
- Android builds fail under the default Java 27 (`JAVA_HOME` from mise):
  Gradle `JdkImageTransform` on `android-36/core-for-system-modules.jar`
  errors out (same family as flutter/flutter#156304). Workaround used here:
  `JAVA_HOME=$HOME/development/jdk17 flutter build apk --debug`
  (Temurin 17.0.20, already on this machine). No repo change was needed;
  do not commit any local JDK path.
