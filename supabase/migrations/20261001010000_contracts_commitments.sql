-- Receipts Stage 1: contracts, commitments, contract_changes.
-- One active contract per user. 3-5 commitments per contract.
-- Commitments cannot be deleted; retiring is an UPDATE of retired_at only.

-- ---------------------------------------------------------------- contracts
create table if not exists public.contracts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  start_date date not null default (now()::date),
  end_date date not null default ((now()::date) + 90),
  mode text not null check (mode in ('hard', 'kind')),
  status text not null default 'active' check (
    status in ('active', 'completed', 'abandoned')
  ),
  kind_recoveries_used integer not null default 0 check (
    kind_recoveries_used between 0 and 2
  ),
  created_at timestamptz not null default now(),
  check (end_date = start_date + 90)
);

alter table public.contracts enable row level security;

drop policy if exists "contracts_select_own" on public.contracts;
create policy "contracts_select_own"
  on public.contracts for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "contracts_insert_own" on public.contracts;
create policy "contracts_insert_own"
  on public.contracts for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "contracts_update_own" on public.contracts;
create policy "contracts_update_own"
  on public.contracts for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Only one active contract per user.
drop index if exists contracts_one_active_per_user;
create unique index contracts_one_active_per_user
  on public.contracts (user_id)
  where status = 'active';

-- Server truth: end_date is always start_date + 90 days.
create or replace function public.set_contract_end_date()
returns trigger
language plpgsql
as $$
begin
  new.end_date := new.start_date + 90;
  return new;
end;
$$;

drop trigger if exists trg_contracts_set_end_date on public.contracts;
create trigger trg_contracts_set_end_date
  before insert or update on public.contracts
  for each row execute function public.set_contract_end_date();

-- Contracts are permanent history: block deletes.
create or replace function public.block_contract_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception 'contracts cannot be deleted'
    using errcode = '25001';
  return null;
end;
$$;

drop trigger if exists trg_contracts_no_delete on public.contracts;
create trigger trg_contracts_no_delete
  before delete on public.contracts
  for each row execute function public.block_contract_delete();

-- ------------------------------------------------------------ commitments
create table if not exists public.commitments (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references public.contracts (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  target_time time null,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now(),
  retired_at timestamptz null check (
    retired_at is null or retired_at >= created_at
  )
);

alter table public.commitments enable row level security;

drop policy if exists "commitments_select_own" on public.commitments;
create policy "commitments_select_own"
  on public.commitments for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "commitments_insert_own" on public.commitments;
create policy "commitments_insert_own"
  on public.commitments for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "commitments_update_own" on public.commitments;
create policy "commitments_update_own"
  on public.commitments for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Commitment must belong to a contract owned by the same user.
create or replace function public.check_commitment_owner()
returns trigger
language plpgsql
as $$
declare
  v_owner uuid;
begin
  select user_id into v_owner
  from public.contracts
  where id = new.contract_id;
  if v_owner is null then
    raise exception 'contract % does not exist', new.contract_id
      using errcode = '23503';
  end if;
  if v_owner != new.user_id then
    raise exception 'commitment user must match contract owner'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_commitments_owner on public.commitments;
create trigger trg_commitments_owner
  before insert or update on public.commitments
  for each row execute function public.check_commitment_owner();

-- Max 5 commitments per contract, enforced immediately for fast feedback.
create or replace function public.enforce_commitment_max()
returns trigger
language plpgsql
as $$
declare
  v_count integer;
begin
  select count(*) into v_count
  from public.commitments
  where contract_id = new.contract_id;
  if v_count >= 5 then
    raise exception 'contract already has 5 commitments (max 5)'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_commitments_max on public.commitments;
create trigger trg_commitments_max
  before insert on public.commitments
  for each row execute function public.enforce_commitment_max();

-- 3-5 range enforced at transaction commit. Because commitments are created
-- incrementally, single-statement inserts would fail the minimum outside an
-- atomic transaction. Use the create_contract_with_commitments RPC (defined
-- below) which inserts the contract plus 3-5 commitments atomically.
create or replace function public.enforce_commitment_range()
returns trigger
language plpgsql
as $$
declare
  v_count integer;
begin
  select count(*) into v_count
  from public.commitments
  where contract_id = new.contract_id;
  if v_count < 3 or v_count > 5 then
    raise exception
      'contract must have 3-5 commitments, found % (use atomic creation)',
      v_count
      using errcode = '23514';
  end if;
  return null;
end;
$$;

drop trigger if exists trg_commitments_range on public.commitments;
create constraint trigger trg_commitments_range
  after insert or update on public.commitments
  deferrable initially deferred
  for each row execute function public.enforce_commitment_range();

-- Commitments cannot be deleted.
create or replace function public.block_commitment_delete()
returns trigger
language plpgsql
as $$
begin
  raise exception 'commitments cannot be deleted; retire them instead'
    using errcode = '25001';
  return null;
end;
$$;

drop trigger if exists trg_commitments_no_delete on public.commitments;
create trigger trg_commitments_no_delete
  before delete on public.commitments
  for each row execute function public.block_commitment_delete();

-- Retiring is an UPDATE of retired_at ONLY. Any other column change is
-- rejected, and retired_at can only go from NULL to a timestamp once.
create or replace function public.allow_commitment_retire_only()
returns trigger
language plpgsql
as $$
begin
  if new.id != old.id
    or new.contract_id != old.contract_id
    or new.user_id != old.user_id
    or new.title is distinct from old.title
    or new.target_time is distinct from old.target_time
    or new.sort_order is distinct from old.sort_order
    or new.created_at is distinct from old.created_at
  then
    raise exception 'only retired_at may be updated on commitments'
      using errcode = '25001';
  end if;
  if old.retired_at is not null then
    raise exception 'commitment is already retired'
      using errcode = '25001';
  end if;
  if new.retired_at is null then
    raise exception 'retiring requires setting retired_at'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_commitments_retire_only on public.commitments;
create trigger trg_commitments_retire_only
  before update on public.commitments
  for each row execute function public.allow_commitment_retire_only();

-- --------------------------------------------------------- contract_changes
-- Append-only log of any change, with reason text.
create table if not exists public.contract_changes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  contract_id uuid not null references public.contracts (id) on delete cascade,
  commitment_id uuid null references public.commitments (id) on delete cascade,
  change_type text not null check (
    change_type in ('create', 'retire', 'status', 'mode', 'note')
  ),
  reason text not null check (char_length(reason) between 1 and 500),
  created_at timestamptz not null default now()
);

alter table public.contract_changes enable row level security;

drop policy if exists "contract_changes_select_own" on public.contract_changes;
create policy "contract_changes_select_own"
  on public.contract_changes for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "contract_changes_insert_own" on public.contract_changes;
create policy "contract_changes_insert_own"
  on public.contract_changes for insert
  to authenticated
  with check (auth.uid() = user_id);

-- Append-only: block UPDATE and DELETE.
create or replace function public.block_contract_changes_mutation()
returns trigger
language plpgsql
as $$
begin
  raise exception 'contract_changes is append-only'
    using errcode = '25001';
  return null;
end;
$$;

drop trigger if exists trg_contract_changes_no_update on public.contract_changes;
create trigger trg_contract_changes_no_update
  before update or delete on public.contract_changes
  for each row execute function public.block_contract_changes_mutation();

-- Record every retirement in contract_changes automatically.
create or replace function public.log_commitment_retirement()
returns trigger
language plpgsql
as $$
begin
  insert into public.contract_changes (
    user_id, contract_id, commitment_id, change_type, reason
  )
  values (
    new.user_id,
    new.contract_id,
    new.id,
    'retire',
    'commitment retired: ' || new.title
  );
  return new;
end;
$$;

drop trigger if exists trg_commitments_log_retire on public.commitments;
create trigger trg_commitments_log_retire
  after update of retired_at on public.commitments
  for each row
  when (old.retired_at is null and new.retired_at is not null)
  execute function public.log_commitment_retirement();

-- Atomic creation helper: inserts a contract plus 3-5 commitments in one
-- transaction so the deferred range trigger passes. Validates ownership via
-- auth.uid(). Returns the new contract id.
create or replace function public.create_contract_with_commitments(
  p_start_date date,
  p_mode text,
  p_commitments jsonb,
  p_reason text default 'initial contract lock'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_contract uuid;
  v_n integer;
  v_item jsonb;
  v_idx integer := 0;
begin
  if v_user is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if p_mode not in ('hard', 'kind') then
    raise exception 'invalid mode %', p_mode using errcode = '23514';
  end if;
  v_n := jsonb_array_length(p_commitments);
  if v_n < 3 or v_n > 5 then
    raise exception 'need 3-5 commitments, got %', v_n using errcode = '23514';
  end if;

  insert into public.contracts (user_id, start_date, mode)
  values (v_user, p_start_date, p_mode)
  returning id into v_contract;

  for v_item in select * from jsonb_array_elements(p_commitments) loop
    if char_length(v_item ->> 'title') < 1
      or char_length(v_item ->> 'title') > 120 then
      raise exception 'invalid commitment title' using errcode = '23514';
    end if;
    insert into public.commitments (
      contract_id, user_id, title, target_time, sort_order
    )
    values (
      v_contract,
      v_user,
      v_item ->> 'title',
      nullif(v_item ->> 'target_time', '')::time,
      v_idx
    );
    v_idx := v_idx + 1;
  end loop;

  insert into public.contract_changes (
    user_id, contract_id, change_type, reason
  )
  values (v_user, v_contract, 'create', p_reason);

  return v_contract;
end;
$$;
