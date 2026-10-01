import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads Supabase credentials injected at compile time via
/// `--dart-define-from-file=env.json`.
///
/// See: https://docs.flutter.dev/build-systems-and-config#passing-config-values-to-dart-define
/// Only the Supabase URL and anon (publishable) key may exist in the app.
/// Never add a service_role key here (AGENTS.md security rules).
class SupabaseEnv {
  static const String url = String.fromEnvironment('SUPABASE_URL');

  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

/// Initializes the Supabase client. Safe to call when env keys are missing
/// (e.g. local widget tests): initialization is skipped and callers can check
/// [SupabaseEnv.isConfigured].
class SupabaseInitializer {
  static Future<void> initialize() async {
    if (!SupabaseEnv.isConfigured) {
      return;
    }
    // supabase_flutter >=2.13 renamed `anonKey` to `publishableKey`.
    // The SUPABASE_ANON_KEY value from env.json is the publishable key.
    // See: https://pub.dev/packages/supabase_flutter/changelog#2130
    await Supabase.initialize(
      url: SupabaseEnv.url,
      publishableKey: SupabaseEnv.anonKey,
    );
  }
}
