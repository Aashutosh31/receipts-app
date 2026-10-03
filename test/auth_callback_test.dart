import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/features/auth/data/auth_callback.dart';

void main() {
  group('auth callback URI', () {
    test('uses the app custom scheme, never localhost', () {
      expect(kAuthCallbackUri, 'com.receipts.receipts://auth-callback');
      final Uri uri = authCallbackUri;
      expect(uri.scheme, 'com.receipts.receipts');
      expect(uri.host, 'auth-callback');
      expect(uri.toString(), isNot(contains('localhost')));
      expect(uri.toString(), isNot(contains('http')));
    });

    test('matches bare and parameterized callbacks', () {
      expect(isAuthCallbackUri(authCallbackUri), isTrue);
      // PKCE flow appends the exchange code as a query parameter.
      expect(
        isAuthCallbackUri(
          Uri.parse('com.receipts.receipts://auth-callback?code=abc123'),
        ),
        isTrue,
      );
      // Implicit flow appends tokens as a fragment.
      expect(
        isAuthCallbackUri(
          Uri.parse(
            'com.receipts.receipts://auth-callback'
            '#access_token=tok&refresh_token=tok&type=signup',
          ),
        ),
        isTrue,
      );
    });

    test('rejects non-callback links', () {
      expect(
        isAuthCallbackUri(Uri.parse('https://example.supabase.co/auth/v1/x')),
        isFalse,
      );
      expect(
        isAuthCallbackUri(Uri.parse('com.other.app://auth-callback')),
        isFalse,
      );
      expect(
        isAuthCallbackUri(Uri.parse('com.receipts.receipts://other')),
        isFalse,
      );
      expect(isAuthCallbackUri(Uri.parse('com.receipts.receipts://')), isFalse);
    });
  });

  group('Android manifest wiring', () {
    test('registers the callback scheme and host on MainActivity', () {
      final String manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('android:scheme="com.receipts.receipts"'));
      expect(manifest, contains('android:host="auth-callback"'));
      expect(manifest, contains('android.intent.action.VIEW'));
      expect(manifest, contains('android.intent.category.BROWSABLE'));
    });
  });
}
