import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_initializer.dart';
import 'core/theme/app_theme.dart';
import 'features/reminders/data/notification_service.dart';
import 'features/reminders/presentation/reminder_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseInitializer.initialize();
  // Stage 3 reminders: timezone database + device location + plugin.
  final NotificationService notificationService = LocalNotificationService();
  await notificationService.init();
  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const ReceiptsApp(),
    ),
  );
}

class ReceiptsApp extends ConsumerWidget {
  const ReceiptsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!SupabaseEnv.isConfigured) {
      return MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Missing SUPABASE_URL / SUPABASE_ANON_KEY. '
                'Run: flutter run --dart-define-from-file=env.json',
                semanticsLabel: 'Missing Supabase configuration',
              ),
            ),
          ),
        ),
      );
    }
    return MaterialApp.router(
      title: 'Receipts',
      theme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: MediaQuery.textScalerOf(context)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
