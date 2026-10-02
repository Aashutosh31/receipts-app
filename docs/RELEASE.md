# Release to Google Play (internal testing)

Application ID: `com.receipts.receipts` · Version: see `version:` in
`pubspec.yaml` (bump `+N` build number for every Play upload).

## 1. Signing (owner machine only, once)

1. Generate the upload keystore (back it up offline with its passwords —
   losing it locks you out of future updates):
   ```sh
   keytool -genkey -v -keystore ~/receipts-upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias receipts-upload
   ```
2. Copy `android/key.properties.example` to `android/key.properties`
   (gitignored — never commit it, never share it) and fill in the real
   values.
3. The Gradle config (`android/app/build.gradle.kts`) uses `key.properties`
   when present and falls back to debug keys otherwise, so local
   `--release` runs keep working without secrets.

## 2. Build the release bundle

```sh
flutter pub get
dart format .   # must be clean
flutter analyze # zero issues
flutter test    # all green
JAVA_HOME=$HOME/development/jdk17 \
  flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

## 3. Play Console internal testing

1. Create the app in Play Console (**Create app**, default settings).
2. Complete **App content** questionnaires (privacy policy URL — host
   `docs/PRIVACY.md` content somewhere public; data safety form; content
   rating; target audience; news apps declaration if asked).
3. Go to **Release → Testing → Internal testing → Create new release**,
   upload `app-release.aab`, add release notes, **Save → Review → Start
   rollout to Internal testing**.
4. Create the tester list (email list or Google Group) and share the
   opt-in link. Internal builds are normally available within seconds.
5. Install on a device from the opt-in link and smoke-test: sign up, sign
   contract, check in, ledger, reminders (grant notification + alarm
   permissions when asked).

## 4. Closed testing track (required before production for new accounts)

Per the official Play Console help
(https://support.google.com/googleplay/android-developer/answer/14151465):
personal developer accounts created after **November 13, 2023** must run a
**closed test with at least 12 testers opted in continuously for at least
14 days** before they can apply for production access (reduced from 20;
testers must genuinely engage on unique devices or review keeps failing).
After meeting the criteria, apply on the Play Console Dashboard; review
usually takes 7 days or less.

Steps: **Release → Testing → Closed testing → Create track**, reuse the
tested `.aab`, add the 12+ tester emails, roll out, keep everyone opted in
for 14+ days, then **Dashboard → Apply for production access** and answer
the closed-test questions honestly.

## 5. Versioning rules

- Every Play upload needs a higher `versionCode` (`+N` in `pubspec.yaml`).
- Keep one changelog line per release in release notes.
- Never commit `android/key.properties`, `*.keystore`, `*.jks`, or
  `env.json` (all gitignored; the final audit greps for them).
