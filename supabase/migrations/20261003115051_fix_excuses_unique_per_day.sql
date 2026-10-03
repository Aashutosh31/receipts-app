-- Receipts: fix excuses uniqueness to one row per (commitment_id, day).
--
-- The live database carries a single-column UNIQUE on commitment_id
-- (constraint excuses_commitment_id_key), which rejects every second excuse
-- for the same commitment even on a different missed day. The intended rule
-- — one excuse per commitment per missed day, matching
-- unique (commitment_id, day) in 20261001020000_ledger.sql — is enforced
-- here. Dropping the wrong constraint cannot create duplicates (it is
-- strictly narrower than the composite), and the composite is only added
-- when missing, so this migration is safe on databases in either state.
-- RLS, triggers, and all other rules are untouched.

alter table public.excuses
  drop constraint if exists excuses_commitment_id_key;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.excuses'::regclass
      and contype = 'u'
      and pg_get_constraintdef(oid) = 'UNIQUE (commitment_id, day)'
  ) then
    alter table public.excuses
      add constraint excuses_commitment_day_unique
      unique (commitment_id, day);
  end if;
end
$$;
