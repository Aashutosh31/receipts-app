# Supabase Setup (Stage 1)

Follow these numbered steps to bring up the Receipts backend. You only need
the Supabase dashboard and the URL + anon key at the end.

## 1. Create the Supabase project

1. Go to https://supabase.com/dashboard and sign in (or create an account).
2. Click **New project**, pick a name (e.g. `receipts`), set a strong database
   password, choose the region closest to you.
3. Wait until the project status is green/healthy.

## 2. Apply the migrations

You have two options. Option A is recommended (versioned, repeatable).

### Option A: via Supabase CLI (`supabase db push`)

1. Install the CLI: https://supabase.com/docs/guides/cli
2. From the project root, link your project:
   ```sh
   supabase link --project-ref YOUR_PROJECT_REF
   ```
   (Find the reference in **Project Settings → General → Reference ID**.)
3. Push the migrations in `supabase/migrations/` (they apply in filename order):
   ```sh
   supabase db push
   ```
4. Verify in **Database → Tables** that you see: `profiles`, `contracts`,
   `commitments`, `contract_changes`, `check_ins`, `excuses`, `pauses`,
   `letters`.

### Option B: via the SQL Editor (no CLI)

1. Open **SQL Editor → New query** in the dashboard.
2. Copy-paste each file in `supabase/migrations/` **in this exact order** and
   run it:
   1. `20261001000000_profiles.sql`
   2. `20261001010000_contracts_commitments.sql`
   3. `20261001020000_ledger.sql`
   4. `20261001030000_letters.sql`
   5. `20261001040000_rpcs.sql`
3. Each file is idempotent for tables/policies (`if not exists` /
   `drop ... if exists`), so re-running a file is safe.

## 3. Enable Email auth

1. Go to **Authentication → Providers**.
2. Enable **Email** (keep **Confirm email** ON for production).
3. Optional: configure your redirect URLs under
   **Authentication → URL Configuration** for magic-link / recovery flows.

## 4. Find the URL and anon (publishable) key

1. Go to **Project Settings → API**.
2. Copy the **Project URL** → put it as `SUPABASE_URL` in `env.json`.
3. Copy the **anon / publishable** key → put it as `SUPABASE_ANON_KEY` in
   `env.json`. (Supabase renamed "anon key" to "publishable key" in 2024; it
   is the same safe-to-ship public key. Never use the `service_role` /
   secret key in the app.)
4. See `env.example.json` for the exact shape.

## 5. Run the app

```sh
flutter run --dart-define-from-file=env.json
```

## 6. Verify RLS and triggers

1. Create two test users (Authentication → Users → Add user, or sign up from
   the app once auth UI lands).
2. Open the SQL Editor and run the checks in `docs/rls_tests.sql`.
   It proves: user A cannot read user B's rows; UPDATE/DELETE on `check_ins`
   fails; backdated inserts fail; letter bodies stay hidden before unlock
   (use `get_letters()` instead of direct SELECT on `body`).
