-- Receipts: allow the internal Supabase Auth account-deletion cascade.
--
-- The delete-account Edge Function calls admin.auth.admin.deleteUser(),
-- which deletes auth.users as the supabase_auth_admin role. Foreign-key
-- cascades then delete that user's contracts, commitments, check-ins,
-- excuses, pauses, letters, changes, memberships, and nudges — but the
-- blanket immutability triggers below rejected EVERY deleter, aborting the
-- whole cascade with 25001 ('contracts cannot be deleted').
--
-- This migration changes only the trigger behavior: the internal auth
-- cascade (current_user = 'supabase_auth_admin') is allowed through, while
-- every other deleter — clients, service_role, owner — stays blocked with
-- the original messages and codes. RLS, policies, and all other integrity
-- rules are untouched. No new client capability is exposed.

-- Single source of truth for the bypass: true only for the internal Auth
-- deletion cascade. Plain (not definer) so current_user is the executor.
create or replace function public.is_auth_account_cascade()
returns boolean
language sql
stable
as $$ select current_user = 'supabase_auth_admin' $$;

create or replace function public.block_contract_delete()
returns trigger
language plpgsql
as $$
begin
  if public.is_auth_account_cascade() then
    return old;
  end if;
  raise exception 'contracts cannot be deleted'
    using errcode = '25001';
  return null;
end;
$$;

create or replace function public.block_commitment_delete()
returns trigger
language plpgsql
as $$
begin
  if public.is_auth_account_cascade() then
    return old;
  end if;
  raise exception 'commitments cannot be deleted; retire them instead'
    using errcode = '25001';
  return null;
end;
$$;

create or replace function public.block_contract_changes_mutation()
returns trigger
language plpgsql
as $$
begin
  if public.is_auth_account_cascade() then
    return old;
  end if;
  raise exception 'contract_changes is append-only'
    using errcode = '25001';
  return null;
end;
$$;

create or replace function public.block_check_in_mutation()
returns trigger
language plpgsql
as $$
begin
  if public.is_auth_account_cascade() then
    return old;
  end if;
  raise exception 'check_ins are insert-only and cannot be edited or deleted'
    using errcode = '25001';
  return null;
end;
$$;

create or replace function public.block_excuse_mutation()
returns trigger
language plpgsql
as $$
begin
  if public.is_auth_account_cascade() then
    return old;
  end if;
  raise exception 'excuses are insert-only and cannot be edited or deleted'
    using errcode = '25001';
  return null;
end;
$$;

create or replace function public.block_pause_delete()
returns trigger
language plpgsql
as $$
begin
  if public.is_auth_account_cascade() then
    return old;
  end if;
  raise exception 'pauses cannot be deleted' using errcode = '25001';
  return null;
end;
$$;

create or replace function public.block_letter_mutation()
returns trigger
language plpgsql
as $$
begin
  if public.is_auth_account_cascade() then
    return old;
  end if;
  raise exception 'letters cannot be edited or deleted'
    using errcode = '25001';
  return null;
end;
$$;

create or replace function public.block_nudge_mutation()
returns trigger
language plpgsql
as $$
begin
  if public.is_auth_account_cascade() then
    return old;
  end if;
  raise exception 'nudges cannot be edited or deleted'
    using errcode = '25001';
  return null;
end;
$$;
