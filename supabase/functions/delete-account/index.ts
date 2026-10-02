// Supabase Edge Function: delete-account.
//
// Deletes the CALLER's auth account. Every app table references auth.users
// with ON DELETE CASCADE, so Postgres removes all rows (contracts,
// commitments, check-ins, excuses, pauses, letters, changes, memberships,
// nudges, and squads the caller created) in the same operation.
//
// SECURITY: the service role key is read ONLY from server-side secrets
// (`supabase secrets set SERVICE_ROLE_KEY=...`, falling back to the
// platform-injected SUPABASE_SERVICE_ROLE_KEY). It never ships in the app,
// never appears in client code, and must never be committed.
//
// Deploy (owner):
//   1. supabase secrets set SERVICE_ROLE_KEY='<service_role key>'
//      (Dashboard: Project Settings -> Edge Functions -> Secrets also works.)
//   2. supabase functions deploy delete-account
//   3. Confirm: POST /functions/v1/delete-account with a user JWT returns
//      {"deleted":true}, and the user + all rows are gone.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.117.2';

serve(async (req: Request): Promise<Response> => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceKey =
    Deno.env.get('SERVICE_ROLE_KEY') ??
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    '';
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return Response.json({ error: 'Server misconfigured' }, { status: 500 });
  }

  // Identify the caller from their own JWT (sent automatically by the app).
  const caller = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const {
    data: { user },
  } = await caller.auth.getUser();
  if (!user) {
    return Response.json({ error: 'Not authenticated' }, { status: 401 });
  }

  // Delete ONLY the caller. The service key never leaves this function.
  const admin = createClient(supabaseUrl, serviceKey);
  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) {
    console.error('delete-account admin delete failed', {
      message: error.message,
      name: error.name,
      status: error.status,
      code: error.code,
    });
    return Response.json({ error: 'Delete failed' }, { status: 500 });
  }
  return Response.json({ deleted: true });
});
