// Email-confirmation deep-link target shared by signup, the Android
// intent-filter, and tests.
//
// Flow: signUp() passes this URI as emailRedirectTo, so the confirmation
// email links back into the app instead of localhost. supabase_flutter
// already observes incoming links (detectSessionInUri defaults to true)
// and exchanges the auth callback for a session via getSessionFromUrl,
// which fires onAuthStateChange and the router's auth guard takes over.
// No custom URI-handling code is needed or wanted — see
// https://supabase.com/docs/guides/auth#email-templates and
// https://developer.android.com/training/app-links/deep-linking.
//
// Platform notes:
// - Android: scheme + host are registered in
//   android/app/src/main/AndroidManifest.xml. Custom schemes need no
//   autoVerify (that is only for https App Links).
// - iOS/web: not wired yet. iOS needs the same scheme in the Xcode URL
//   Types (or a universal link + applinks: entry); web needs no manifest
//   work. Add them here first so all platforms share one constant.

/// Deep link the confirmation email must return to.
/// Never localhost: this URI must open the installed app.
const String kAuthCallbackUri = 'com.receipts.receipts://auth-callback';

/// Parsed form of [kAuthCallbackUri].
Uri get authCallbackUri => Uri.parse(kAuthCallbackUri);

/// True for links addressed to our auth callback, including the query
/// (`?code=…`, PKCE) or fragment (`#access_token=…`, implicit) parameters
/// Supabase appends. Mirrors the heuristic supabase_flutter applies before
/// calling getSessionFromUrl.
bool isAuthCallbackUri(Uri uri) {
  return uri.scheme == authCallbackUri.scheme &&
      uri.host == authCallbackUri.host;
}
