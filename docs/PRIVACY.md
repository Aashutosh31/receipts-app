# Privacy Policy — Receipts

Plain-language summary of what Receipts stores, where, and how to delete it.
Host this content at a public URL before the Play Console data-safety form
asks for it (see `docs/RELEASE.md`).

## What we store (server, Supabase Postgres)

Tied to your login email, nothing else:

- **Account**: email, password hash (handled by Supabase Auth; we never see
  passwords), display name if you set one, timezone.
- **Contract**: start/end dates, Hard or Kind mode, status.
- **Commitments**: titles, optional target times, retirement timestamps.
- **Ledger**: daily check-ins (done/not done) and miss reasons you tag
  (`tired`, `busy`, `unmotivated`, `forgot`, `other`) plus any short note
  you attach (max 280 chars).
- **Pauses, letters, contract changes, squads, nudges**: exactly what you
  enter, plus server timestamps.

We do **not** collect location, contacts, photos, advertising IDs, or
analytics. No third-party SDK receives your data. AI is not involved.

## What stays on your device only

- Reminder preferences (quiet hours, tone, per-commitment toggles).
- An offline cache of your contract/ledger and queued check-ins.
- The login session token (standard Supabase session storage).

## Who can see your data

- **Only you**, enforced by database Row Level Security on every table.
- **Squadmates** see only: your display name, day number, today's kept or
  missed status, current streak, and missed count. Never notes, letters,
  excuse notes, or commitment titles.
- **Nobody else.** There is no admin viewer in the app.

## Deletion

In the app: **Settings → Danger zone → Delete my account and data**
(type DELETE to confirm). This calls a server function that deletes your
login and, via database cascades, every row above — including squads you
created (their members lose that squad) — then wipes the on-device cache
and settings and signs you out. There is no undo and no recovery.

The service role key used by that function lives only as a server-side
secret. It is never shipped in the app and never committed to git.

## Contact / changes

Questions about your data: reply through the app's support channel with
your login email. If this policy changes materially, the app will note it
in `docs/PROGRESS.md` and the Play listing before the change ships.

## Exercising deletion (owner manual steps)

1. Deploy the function once:
   ```sh
   supabase secrets set SERVICE_ROLE_KEY='<service_role key>'
   supabase functions deploy delete-account
   ```
   (Dashboard alternative: Project Settings → Edge Functions → Secrets,
   then deploy from the Functions page.)
2. In the app on a test account: Settings → Danger zone → type DELETE →
   confirm. Expect: success, immediate sign-out, login rejected afterwards.
3. Verify in the Supabase dashboard (Table Editor + Authentication → Users):
   the user and all of their rows are gone.
