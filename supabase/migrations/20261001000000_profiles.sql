-- Receipts Stage 1: profiles.
-- RLS on every table. Only owner (auth.uid()) can read/write own rows.
-- Auto-creates a profile row when auth.users gets a new user.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text check (
    display_name is null
    or char_length(display_name) between 1 and 60
  ),
  timezone text not null default 'UTC' check (
    char_length(timezone) between 1 and 64
  ),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Validate that timezone is a known IANA name. Truth about time comes from
-- the server; an invalid zone would break day-boundary triggers.
create or replace function public.validate_profile_timezone()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1 from pg_timezone_names where name = new.timezone
  ) then
    raise exception 'invalid timezone: %', new.timezone
      using errcode = '23514';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_validate_timezone on public.profiles;
create trigger trg_profiles_validate_timezone
  before insert or update on public.profiles
  for each row execute function public.validate_profile_timezone();

-- Auto-create profile on signup. Runs as definer so it bypasses RLS.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id)
  values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
