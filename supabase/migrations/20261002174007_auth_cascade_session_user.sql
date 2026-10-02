-- Receipts: key the auth-cascade bypass on session_user, not current_user.
--
-- The live database proved the 20261002170555 bypass insufficient: the
-- helper was present and correct, the Auth session was supabase_auth_admin,
-- yet the cascade still raised 25001. The consistent explanation is that
-- the deletion reaches the triggers through a SECURITY DEFINER hop, which
-- rewrites current_user while session_user keeps identifying the original
-- session login (supabase_auth_admin).
--
-- session_user is the correct identity for this narrow bypass, and it is
-- strictly safer: it can only change via superuser SET SESSION
-- AUTHORIZATION, which no client, PostgREST, or service_role path performs.
-- Conversely, a current_user check could in principle be fooled from the
-- other direction by a definer function owned by a privileged role invoked
-- from a lesser session. No PostgREST session ever authenticates as
-- supabase_auth_admin, so ordinary, service_role, and owner deletes stay
-- blocked exactly as before.
--
-- This migration changes ONLY the helper. It stays plain SECURITY INVOKER.
-- The 8 blocker functions, RLS, policies, and all other rules are untouched.

create or replace function public.is_auth_account_cascade()
returns boolean
language sql
stable
as $$ select session_user = 'supabase_auth_admin' $$;
