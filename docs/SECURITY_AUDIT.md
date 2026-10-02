# Security Audit — Receipts (public-repo readiness)

- Date: 2026-10-02. Auditor: automated read-first review (code, migrations,
  history, build output) plus live-verified owner results where noted.
- Scope: entire repo at `main` — git history, Supabase schema/functions,
  Flutter/Android app, dependencies, docs, Edge Functions.
- Method: gitleaks 8.30.1 (official GitHub release) over full history +
  worktree; manual grep review; APK disassembly (`unzip` + `strings`, no
  sudo); all 7 migration files read end-to-end; primary sources only
  (supabase.com/docs, docs.flutter.dev, developer.android.com, pub.dev
  pages/changelogs, postgresql.org/docs, owasp.org, official tool repos).
- Rule: nothing below was changed to produce this report. Fixes follow in
  separate small commits; each finding carries status Open/Fixed or
  Needs-manual-action.

## Severity scale

- **Critical**: actively exploitable secret exposure or auth bypass.
- **High**: broken release integrity, ledger-integrity bypass, or required
  key rotation.
- **Medium**: privacy-relevant weakness or integrity gaming needing
  deliberate action.
- **Low**: hardening gap with limited impact.
- **Info**: verified-safe item, non-finding, or future consideration.

## Verdict (updated at the end)

**NOT SAFE YET** — see "Needs-manual-action" (§7). Code fixables are
addressed in this audit's fix commits, but rotation confirmation and
owner-side dashboard/build steps are still outstanding.

---

## PART 1 — Secrets and git history

### F-01 — SERVICE_ROLE_KEY handling: rotation required (High, Needs-manual-action)

- **What**: `env.json` (gitignored, never committed) once held a
  `SERVICE_ROLE_KEY` value alongside the anon key. Because
  `--dart-define-from-file` compiles every entry into the build, any key
  present at build time ships inside the binary.
- **Evidence of non-exposure (all checked)**:
  - `gitleaks detect --log-opts="--all --full-history"`: 24 commits, no
    leaks. `git grep service_role $(git rev-list --all)`: only prose
    mentions (AGENTS.md rules, doc comments); no values. No tags, no
    stashes; 2 dangling blobs inspected (normalize.css HTML, an
    android/.gitignore copy) — benign.
  - Current `env.json` holds only `SUPABASE_URL` + `SUPABASE_ANON_KEY`.
  - Debug APK disassembly (`libapp` kernel blob via `strings`): exactly
    ONE Supabase JWT, payload `role: anon`; no second JWT anywhere.
    Only the anon key could ever reach a bundle.
  - `pubspec.yaml` has no active `assets:` section — `env.json` is not
    bundled as an asset.
- **Why it still matters**: the file was readable by the coding agent, so
  its contents may have reached the model provider. Per policy this alone
  requires rotation — regardless of the clean scan.
- **Fix (owner, FIRST)**: Settings → API Keys → create new secret key →
  replace everywhere used (Edge Function secret) → confirm → retire the
  old key. Official procedure:
  https://supabase.com/docs/guides/api/api-keys#rotate-a-leaked-or-compromised-key
- **Status**: Needs-manual-action. The repo verdict stays negative until
  rotation is confirmed.

### F-02 — gitleaks worktree hits are non-issues (Info)

- 1× `jwt` in `env.json`: the anon key itself, gitignored, public by
  design. Not a finding.
- 17× `private-key` in `build/` + `.dart_tool/` `.dill` caches: the matched
  text is Dart string constants (`BEGIN PRIVATE KEY` + `END_PRIVATE_KEY`
  identifiers) from the `dart_jsonwebtoken` package's key parser, compiled
  into local-only, gitignored build caches. No real key material.
- **Status**: no action (build outputs are gitignored and undistributed).

### F-03 — Untracked/ignored sensitive files verified (Info, Fixed by verification)

- `git ls-files` proves NONE of these are tracked: `env.json`, `.env`,
  `android/key.properties`, `*.keystore`, `*.jks`, `google-services.json`,
  `GoogleService-Info.plist`, `android/local.properties`,
  `supabase/.temp`, `supabase/.env`, `*.pem`, `build/`.
- `git check-ignore` confirms coverage for `env.json`,
  `android/key.properties`, `android/local.properties`, `supabase/.temp`.
- **Status**: verified, no change needed.

### F-04 — Example/docs contain no secrets (Info)

- `env.example.json`: placeholders only.
- README/docs grep for emails, keys, JWTs, project refs: clean, except
  the local JDK path `/home/aashutosh31/...` in `docs/PROGRESS.md` and
  `docs/RELEASE.md` (username disclosure — fixed under F-12).
- **Status**: verified (path fix below).

---

## PART 2 — Supabase / database

Tables reviewed (11): profiles, contracts, commitments, contract_changes,
check_ins, excuses, pauses, letters, squads, squad_members, nudges.
RLS is ENABLED on all 11 (script-verified over `supabase/migrations/`).
Every policy is owner/member-scoped with `auth.uid()`; all INSERT/UPDATE
policies carry WITH CHECK; no policy uses `true` for authenticated/anon.

### F-05 — Release builds have no INTERNET permission (High, fix committed)

- File: `android/app/src/main/AndroidManifest.xml` (no `<uses-permission
  android:name="android.permission.INTERNET"/>`); only
  `android/app/src/{debug,profile}/AndroidManifest.xml` declare it.
- Why it matters: manifest merger gives release builds only the main
  manifest, so a release APK/AAB cannot reach Supabase at all — the
  shipped artifact is dead on arrival. (The stock Flutter template behaves
  the same; the official deployment page lists adding INTERNET as a review
  step: https://docs.flutter.dev/deployment/android.)
- Fix: declare INTERNET in the main manifest (same commit also sets
  `allowBackup=false`, `usesCleartextTraffic=false` — see F-07/F-08).
- Status: **Fixed**.

### F-06 — Retroactive pause backdating rewrites history (High, fix committed)

- Files: `supabase/migrations/20261001020000_ledger.sql:233-241` (table),
  `check_pause_insert()` lines 266-296 (no date bounds on `start_day`).
- Why it matters: after missing a week, a user can declare a pause with
  `start_day` a month in the past; `get_ledger`/`get_streak` then report
  those days `paused` instead of `missed`. This defeats "past days are
  permanent" (AGENTS.md core mechanic). Pauses stay visible, so it is not
  silent falsification — but it is a working history eraser.
- Fix: new migration bounds `start_day` to
  `[server-local-today − 3 days, contract end_date]` (3 days preserves the
  legitimate sick-then-declare flow and matches the 48h excuse spirit) +
  SQL regression test. Decision recorded in `docs/DECISIONS.md`.
- Status: **Fixed** (migration committed; owner applies via `db push`).

### F-07 — Unlimited profile timezone changes game the grace window (Medium, fix committed)

- Files: `20261001000000_profiles.sql:33-38` (update policy, no limit);
  `20261001020000_ledger.sql:53-116` (`check_check_in_day` trusts
  `profiles.timezone`).
- Attack: at UTC Monday 10:00, set timezone to UTC−11 → local Sunday 23:00
  → backfill Sunday as "today"; or UTC+14 to pre-fill tomorrow. Each flip
  buys ~1 day each way. The app itself never writes `timezone` (verified:
  no writes in `lib/`), so this needs raw API abuse — deliberate only.
- Fix: new migration adds `profiles.timezone_changed_at` + trigger allowing
  a change only if never changed or last change > 7 days ago. One gamed day
  per week max, each flip timestamped as evidence. +   SQL regression test.
- Status: **Fixed** (migration committed; owner applies via `db push`).

### F-08 — Squad invite codes use a 16-symbol alphabet, no rate limit (Medium, fix committed)

- File: `20261002140000_squads.sql:193`
  (`upper(substring(md5(gen_random_uuid()::text), 1, 6))`).
- Why it matters: hex uppercased is still only 16 symbols → 16^6 ≈ 16.7M
  codes, enumerable via the unauthenticated-cost `join_squad` RPC (auth
  required, but any signed-in user). Joining leaks member display names +
  kept/missed statuses + streaks. (Randomness source itself is fine:
  `gen_random_uuid()` is CSPRNG; the flaw is alphabet collapse.)
- Fix: new migration regenerates codes from `gen_random_bytes` mapped onto
  the full 36-symbol `A-Z0-9` set (2.2B space), same 6-char UX and CHECK
  constraint, retry loop unchanged. No app change needed (input already
  uppercases, maxLength 6).
- Residual: no per-account join-attempt rate limiting — platform-level;
  owner can add Supabase API rate limiting (manual checklist).
- Status: **Fixed** (code); rate limiting → Needs-manual-action (dashboard).

### F-09 — Session tokens + ledger cache in device backups (Medium, fix committed)

- Why it matters: supabase_flutter persists the session in plaintext
  SharedPreferences; drift holds ledger data in plaintext SQLite.
  `android:allowBackup` defaults to true → both land in Google Drive
  backups, where a compromised Google account yields session takeover +
  full history.
- Fix: `android:allowBackup="false"` in the main manifest (same commit as
  F-05). Full-disk encryption + keystore-backed secure storage migration
  recorded as future hardening (Info F-20), not required for v1: no PII
  beyond email, physical-access threat only.
- Status: **Fixed** (migration committed; owner applies via `db push`).

### F-10 — Raw PostgREST error text reaches users (Low, accepted)

- Files: `lib/features/*/data/*.dart` (`'Could not load X: ${e.message}'`)
  shown in snackbars.
- Why Low: messages can name constraints/tables but never secrets or other
  users' data, and they aid debugging. Scrubbing everywhere would churn
  ~15 call sites for no secret-protection gain.
- Status: Open, accepted risk (revisit on pentest).

### F-11 — `usesCleartextTraffic` not explicit (Low, fix committed)

- Default is false at our targetSdk, but implicit. Added explicit
  `android:usesCleartextTraffic="false"`; all traffic is HTTPS to the
  Supabase URL (verified: no `http://` endpoints, no analytics/trackers in
  deps).
- Status: **Fixed**.

### F-12 — Local paths in docs disclose username (Low, fix committed)

- Files: `docs/PROGRESS.md`, `docs/RELEASE.md` (`/home/aashutosh31/...`).
- Fix: rewritten as `$HOME/...`.
- Status: Open (docs fix lands with the hygiene commit).

### F-13 — Nudge `day` spoofable via direct insert (Low, fix committed)

- File: `20261002140000_squads.sql:90-95` — `day` defaults to server date
  but a direct insert could set any date. Impact is storage spam only
  (`my_nudges_today` filters to today; feed never shows nudges).
- Fix: trigger rejects `new.day != now()::date` (folded into the hardening
  migration).
- Status: **Fixed** (migration committed; owner applies via `db push`).

### F-14 — Squad size TOCTOU race (Low, fix committed)

- File: `20261002140000_squads.sql:64-80` — count-then-insert races under
  concurrent joins could admit a 6th member.
- Fix: `pg_advisory_xact_lock(hashtext(...))` at trigger start serializes
  per-squad inserts (folded into the hardening migration).
- Status: **Fixed** (migration committed; owner applies via `db push`).

### F-15 — Edge Function pins floating `@supabase/supabase-js@2` (Low, fix committed)

- File: `supabase/functions/delete-account/index.ts:21` (Deno std already
  pinned at 0.224.0).
- Fix: pin exact `supabase-js` version.
- Status: Open (lands with the hygiene commit).

### Functions review (all SECURITY DEFINER verified)

- `handle_new_user()` (profiles trigger): definer, `set search_path =
  public`, fixed-shape insert, no user input. Safe.
- `create_contract_with_commitments()`: definer + search_path, null-auth
  check, mode/count/title validation, ownership forced to `auth.uid()`.
  Minor: `p_reason` length and `p_start_date` range rely on table CHECKs /
  self-harm-only past dates — no security impact. No change.
- `get_letters()`, `get_ledger()`, `get_streak()`: definer + search_path,
  null-auth + per-row ownership checks before any data; locked bodies
  return NULL; functions revoked from PUBLIC, granted to authenticated
  only. Cross-user reads impossible (verified live in Stage 1 RLS tests).
- `create/join/leave_squad`, `send_nudge`, `my_nudges_today`,
  `squad_feed()`: same pattern; feed returns exactly the 6 allowed columns
  (asserted structurally in `docs/squad_rls_tests.sql`).
- Non-definer trigger functions need no EXECUTE review (raise-only or
  row-scoped; inert when called directly).
- RLS does not guard function execution — covered above via per-function
  auth checks + `revoke ... from public` on every RPC (verified present
  for all 9 functions).

### Views, TRUNCATE, forged writes (Info, verified)

- No `CREATE VIEW` anywhere → nothing needs `security_invoker`. 
- `TRUNCATE` requires table ownership/TRUNCATE privilege, which
  authenticated/anon never hold (postgresql.org/docs/current/ddl-priv —
  TRUNCATE is a distinct privilege, default-deny). Direct attempt fails
  42501 before RLS is even consulted. Added as a live test case.
- Forged `user_id` inserts fail on WITH CHECK (`auth.uid() = user_id`);
  added as a live test case. Ownership triggers double-check linkage.
- `get_ledger` exposes `commitment_title`, `get_letters` exposes bodies —
  both owner-gated inside definer functions. Safe.

### Key naming (Info, per instructions not a finding)

- App uses legacy `anon` JWT; Edge Function uses legacy `service_role`
  JWT. Per https://supabase.com/docs/guides/api/api-keys these are
  legacy-but-supported until end-2026 deprecation; the replacements are
  `sb_publishable_…` / `sb_secret_…`. Migration tracked as owner decision
  (manual actions), severity Info.

---

## PART 3 — Flutter / Android app

### Manifest (all fix-committed with F-05)

- `android:allowBackup` unset → default true: see F-09 (fixed false).
- `android:usesCleartextTraffic` unset → default false at targetSdk: see
  F-11 (now explicit).
- `android:exported`: MainActivity `true` (required launcher entry),
  both notification receivers `exported=false`. No other components. ✓
- Permissions (minimal, each justified): INTERNET (Supabase API; was
  debug-only — fixed), RECEIVE_BOOT_COMPLETED (reschedule reminders after
  reboot), SCHEDULE_EXACT_ALARM (exact reminder timing, user-granted with
  inexact fallback), POST_NOTIFICATIONS/VIBRATE (from plugin manifest,
  runtime-prompted on Android 13+). No camera/location/contacts/SMS. ✓
- No `android:debuggable` anywhere (release default false). ✓

### Release (verified, Info)

- R8 shrinking is ON by default for release APK/AAB with no opt-out
  possible (verified on current docs.flutter.dev Android deployment page:
  "`--[no-]shrink` ... Code shrinking is always enabled in release
  builds"). No `minifyEnabled` line needed — not reported as missing.
- Signing: `key.properties`-driven `release` config with debug fallback
  for local runs; keystore patterns gitignored; Play rejects debug-signed
  uploads, but owner must still verify the AAB signature manually
  (checklist item).
- `applicationId com.receipts.receipts` disclosure is inherent (public on
  Play). No issue.

### Local data (reviewed, reasoning)

- Stored locally: drift SQLite (contract/commitments/ledger/streak/outbox
  incl. titles + statuses), SharedPreferences (supabase session via
  supabase_flutter default storage + reminder prefs), scheduled
  notification content (titles, enum reasons — never free-text notes or
  letter bodies, verified in message engine + tap handler is a no-op).
- Encryption: NOT applied (per instructions, only if justified). Reasoning:
  data is the user's own accountability log, no PII beyond email; the
  realistic vector was cloud backups → closed by `allowBackup=false`.
  Residual physical-access/root vector accepted; `flutter_secure_storage`
  session migration noted as future hardening (Info).

### Logging, notifications, links, input, network (all verified)

- Zero `print`/`debugPrint`/`developer.log` in `lib/`.
- User error surfaces are friendly-prefix + server text (F-10, accepted).
- No custom URL schemes, no deep-link intent filters, no WebViews, no HTML
  rendering; `app_links` present only as an unused supabase transitive dep.
- All user text length-checked in UI (`maxLength` matching DB CHECKs:
  120/500/280/5000/60/6) and in DB constraints; invite input normalized +
  server-validated.
- All network via supabase_flutter HTTPS to the env URL; no analytics,
  crash-reporting, or tracker dependencies.

---

## PART 4 — Dependencies and supply chain

- `flutter pub outdated`: only patch-level transitive updates pending, plus
  `cupertino_icons` 2.0.0 major (pinned `^1.0.9`, no security relevance).
- All 14 direct deps maintained, none discontinued, all verified
  publishers or official Flutter/Dart teams (checked via pub.dev API +
  package pages).
- `osv-scanner scan --lockfile pubspec.lock`: **No issues found**.
- Gradle: AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1 (current); repositories
  limited to `google()`, `mavenCentral()`, Gradle plugin portal. ✓
- `pubspec.lock` committed; no git/path dependencies. ✓

---

## PART 5 — Public repo hygiene

- `SECURITY.md`: ADDED (private vulnerability reporting via GitHub).
- `LICENSE`: missing. Options — MIT (permissive, simple), Apache-2.0
  (permissive + patent grant), GPL-3.0 (copyleft, forces derivatives open),
  none (all-rights-reserved default). **Needs-manual-action: owner picks;
  not chosen on your behalf.**
- CI (`.github/workflows/ci.yml`): ADDED — analyze + test + gitleaks on
  push/PR, pinned SHAs (verified in official repos:
  actions/checkout@8e8c483db84b4fee98b60c0593521ed34d9990e8 (v6.0.1),
  subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 (v2.23.0),
  gitleaks/gitleaks-action@e0c47f4f8be36e29cdc102c57e68cb5cbf0e8d1e (v3.0.0)),
  `permissions: contents: read`, JDK 17 (repo workaround), no secrets used.
- `dependabot.yml`: ADDED (pub + gradle, weekly).
- README/docs review: no secrets/keys/project refs; JDK paths sanitized
  (F-12); RELEASE.md keystore steps keep secrets out of git.
- GitHub settings for owner (§7 below).

---

## §7 Needs-manual-action (numbered, do these in order)

1. **Rotate the service_role key FIRST** (blocking verdict): Dashboard →
   Settings → API Keys → create new secret key → update the Edge Function
   secret (`supabase secrets set SERVICE_ROLE_KEY=...`) → confirm the app
   delete-flow still works → retire the old key. Official procedure:
   https://supabase.com/docs/guides/api/api-keys#rotate-a-leaked-or-compromised-key
2. `supabase db push` the new hardening migration (timezone cooldown, pause
   bounds, invite alphabet, size lock, nudge-day check).
3. Run extended `docs/rls_tests.sql` + `docs/squad_rls_tests.sql` live;
   fix anything red before continuing.
4. Supabase dashboard: confirm email verification ON; set strong minimum
   password length (Auth → Policies); review rate limits + enable CAPTCHA
   (Auth → Bot and Abuse Protection); disable unused auth providers;
   confirm no storage bucket is public unless intended; review API settings;
   run Security + Performance advisors
   (`/dashboard/project/_/advisors/security`) and fix findings.
5. Create the upload keystore + `android/key.properties`; build the signed
   `.aab`; verify the signature is the upload key (not debug); upload to
   internal testing.
6. Host `docs/PRIVACY.md` publicly; complete the Play data-safety form.
7. Choose a LICENSE (MIT / Apache-2.0 / GPL-3.0 / none).
8. GitHub: enable secret scanning + push protection, private vulnerability
   reporting, branch protection on `main`, Dependabot alerts.
9. Before end-2026: migrate `anon`/`service_role` to publishable/secret
   keys (Info-level, per deprecation timeline).
