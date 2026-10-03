# Final Checklist — Receipts Stage 5C (release readiness)

## Security audit (all verified this stage)

- [x] No `service_role` key in app code: repo-wide grep finds it only in
      `supabase/functions/delete-account/index.ts`, where it is read from
      server-side secrets (`Deno.env`) and never ships to clients.
- [x] No secrets committed: no `key.properties`, `*.keystore`, `*.jks`,
      or `env.json` tracked by git (all gitignored); no JWT-like strings in
      `lib/`, `test/`, or `android/`.
- [x] RLS enabled on all 11 tables: profiles, contracts, commitments,
      contract_changes, check_ins, excuses, pauses, letters, squads,
      squad_members, nudges (verified by script over `supabase/migrations/`).
- [x] New squad migration adds no `service_role` usage; all squad RPCs are
      `SECURITY DEFINER` with `authenticated`-only execute grants.

## Release artifacts

- [x] App icon generated with `flutter_launcher_icons` 0.14.4
      (source art: `assets/icon/app_icon.png`, dark receipt-slip mark).
- [x] Splash generated with `flutter_native_splash` 2.4.8
      (`#0A0A0B` background + icon, incl. Android 12+ section).
- [x] `applicationId: com.receipts.receipts`, version from `pubspec.yaml`
      (`1.0.0+1`; bump `+N` per Play upload).
- [x] Release signing via `android/key.properties` (gitignored template at
      `android/key.properties.example`); release builds fail fast with a
      clear error when it is missing — debug keys are never used for
      release.
- [x] `flutter build appbundle --release` succeeds (JDK 17 workaround as
      usual). Output: `build/app/outputs/bundle/release/app-release.aab`.
- [x] `docs/RELEASE.md`: keystore steps, bundle build, internal-testing
      rollout, and the closed-testing rule for new personal accounts
      (≥12 testers, 14 continuous days, per the official Play Console help
      article answer/14151465).
- [x] iOS build remains untested (needs macOS/Xcode) — noted, not blocking
      the Android release track.

## Privacy & deletion

- [x] `docs/PRIVACY.md`: plain-language storage list, squad visibility
      limits, deletion consequences (including squads you created).
- [x] Edge Function `delete-account` written (deploys with
      `supabase secrets set SERVICE_ROLE_KEY=...` then
      `supabase functions deploy delete-account`).
- [x] In-app flow: Settings → Danger zone → type DELETE → server delete →
      local cache + settings wipe → sign-out. Failure keeps local data for
      retry. Covered by `test/delete_account_test.dart`.
- [ ] Owner still to do (needs Supabase + Play access — cannot be done
      from here):
  1. `supabase db push` the squad migration + deploy the function + set
     the secret, then run `docs/squad_rls_tests.sql` with six test users.
  2. Host `docs/PRIVACY.md` content at a public URL for the Play
     data-safety form.
  3. Create the Play app, upload the `.aab` to internal testing, smoke-test
     on a real phone (auth → contract → check-in → reminders incl. alarm
     permission paths → squads → delete flow on a throwaway account).

## Quality gates (this stage)

- [x] `flutter pub get`
- [x] `dart format .` (clean)
- [x] `flutter analyze` (zero issues)
- [x] `flutter test` (133 green, incl. outbox/rejection, squad RLS-model,
      delete-flow tests)
- [x] `flutter build apk --debug` + `flutter build appbundle --release`
