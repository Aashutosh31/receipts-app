# Receipts: Project Rules for the Coding Agent

## Product
Receipts is a 90-day accountability app ("winter arc"). Its purpose is to challenge the user's ego with their own data. It targets CONSISTENCY, never body punishment. Never add weight-loss pressure, calorie shaming, or restriction mechanics.

Core mechanics:
- The Contract: the user locks 3-5 non-negotiable daily commitments for 90 days. Changing one is costly and recorded.
- The Ledger: check-ins and misses cannot be edited or deleted after submission. Past days are permanent.
- Excuse tracking: when a day is missed, the user tags a reason (tired, busy, unmotivated, forgot, other). The app later shows their top excuse with counts.
- Confrontational personal prompts instead of generic quotes (example: "It's 6:40. You said 5:30.").
- Letter to future self: written on day 1, unlocked on days 30, 60, 90.
- Hard Mode (any miss resets the streak) and Kind Mode (max 2 recovery days per contract).
- Sick/Injury mode: a declared pause that is recorded visibly but does not break the streak.
- Squads (later stage): 3-5 friends see each other's misses.

## Tech stack (do not substitute without asking me)
- Flutter stable, Dart null-safe. Android first; keep code iOS-compatible.
- State: flutter_riverpod. Routing: go_router. Backend: supabase_flutter.
- Local notifications: flutter_local_notifications + timezone + flutter_timezone.
- Local DB (Stage 5 only): drift.
- Backend: Supabase Postgres with Row Level Security on EVERY table. All schema changes are SQL files in /supabase/migrations, named with a timestamp prefix, never edited after being applied (add a new migration instead).

## Architecture
Feature-first folders: lib/features/<feature>/{data,domain,presentation}, plus lib/core (theme, router, supabase client, utils). Repositories wrap Supabase calls; UI never calls Supabase directly. Use immutable models. Handle loading, error, and empty states on every screen.

## Security rules (non-negotiable)
- Only the Supabase URL and anon key may exist in the app. NEVER use or ask me for the service_role key in app code.
- Keys come from env.json via --dart-define-from-file. env.json is in .gitignore. Commit env.example.json with placeholders.
- Truth about time comes from the SERVER (now() in Postgres), never the device clock, for anything that locks, unlocks, or dates a record.
- RLS: a user can only read and write their own rows. Immutability is enforced with database triggers that raise exceptions on UPDATE/DELETE of ledger tables.
- Validate input in the database (check constraints), not only in the UI.

## Research rules
- Before using any package or API, check its official page (pub.dev package page, docs.flutter.dev, supabase.com/docs, developer.android.com, pub.dev changelog). Use the latest stable versions compatible with each other. Do not guess APIs from memory; if the docs differ from what you remember, trust the docs.
- Only use official or primary sources (official docs, package repos, changelogs). Do not copy code from random blogs or forums. Cite the doc URL in a code comment when behavior is non-obvious (e.g., Android exact-alarm permission).
- Note any deprecation warnings and fix them.

## Quality gates (run after EVERY task, fix before moving on)
1. flutter pub get
2. dart format .
3. flutter analyze (zero errors, zero warnings)
4. flutter test (write unit tests for streak logic, ledger logic, excuse analytics, and date/timezone handling)
5. flutter build apk --debug (must succeed)
Then commit with a clear message. Never leave the repo in a broken state.

## Working style
- Small, reviewable commits. One stage at a time. Do not build features from later stages early.
- If a requirement is ambiguous, make the most reasonable decision, write it in docs/DECISIONS.md, and continue. Ask me only when blocked by something only I can provide (keys, accounts, device access).
- Keep a running docs/PROGRESS.md: what is done, what is next, how to run, known issues.
- Tell me exactly what manual steps I need to do (e.g., apply a migration, enable an auth provider) in plain numbered steps.

## UI direction
Dark, minimal, high-contrast, sharp typography, no cartoonish gamification. Tone is direct and honest, never cruel. Copy should confront behavior, not insult the person. Support text scaling and screen readers.
