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

## Next (Stage 2+, do NOT build yet)

- Auth UI (email), contract lock-in flow using
  `create_contract_with_commitments`, daily check-in + excuse UI, ledger
  screen backed by `get_ledger`/`get_streak`, letters UI via `get_letters`,
  local notifications (Stage 4+), drift cache (Stage 5 only).

## How to run

```sh
flutter pub get
flutter run --dart-define-from-file=env.json
```

## Known issues

- Docker daemon hung in this sandbox during Stage 1, so migrations were
  additionally parser-validated (`pglast`) before the live `db push`.
- `flutter build apk --debug` requires Android SDK (present here); iOS build
  needs macOS/Xcode and is untested.
- Android builds fail under the default Java 27 (`JAVA_HOME` from mise):
  Gradle `JdkImageTransform` on `android-36/core-for-system-modules.jar`
  errors out (same family as flutter/flutter#156304). Workaround used here:
  `JAVA_HOME=/home/aashutosh31/development/jdk17 flutter build apk --debug`
  (Temurin 17.0.20, already on this machine). No repo change was needed;
  do not commit any local JDK path.
