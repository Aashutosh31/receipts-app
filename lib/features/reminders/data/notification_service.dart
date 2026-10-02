// NotificationService behind an interface. Wraps flutter_local_notifications
// plus timezone/ flutter_timezone. Initialized once at startup; the device
// location drives all TZDateTime scheduling.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdb;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> init();
  Future<bool> notificationsEnabled();
  Future<bool> requestNotificationsPermission();
  Future<bool> canScheduleExact();
  Future<void> requestExactAlarms();

  /// Schedules one notification. Returns false when [localFireTime] is in
  /// the past (nothing scheduled).
  Future<bool> schedule({
    required int id,
    required DateTime localFireTime,
    required String title,
    required String body,
    required bool exact,
    String? payload,
  });

  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<int> pendingCount();
}

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'receipts_reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  Future<void> init() async {
    tzdb.initializeTimeZones();
    try {
      final String identifier =
          (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings darwin = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: darwin,
    );
    await _plugin.initialize(
      settings: settings,
      // Tapping a reminder opens the app; deep-link routing of taps is
      // future work (documented in DECISIONS.md).
      onDidReceiveNotificationResponse: (_) {},
    );
    _ready = true;
  }

  bool get isReady => _ready;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _darwin => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> notificationsEnabled() async {
    final bool? android = await _android?.areNotificationsEnabled();
    if (android != null) {
      return android;
    }
    final NotificationsEnabledOptions? darwin = await _darwin
        ?.checkPermissions();
    return darwin?.isEnabled ?? false;
  }

  @override
  Future<bool> requestNotificationsPermission() async {
    final bool? android = await _android?.requestNotificationsPermission();
    if (android != null) {
      return android;
    }
    final bool? darwin = await _darwin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return darwin ?? false;
  }

  @override
  Future<bool> canScheduleExact() async {
    final bool? android = await _android?.canScheduleExactNotifications();
    // Non-Android platforms schedule exact by default.
    return android ?? true;
  }

  @override
  Future<void> requestExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
  }

  /// Interprets device-local wall-clock fields in the device location.
  tz.TZDateTime toZoned(DateTime localWallTime) {
    final tz.Location location = tz.local;
    return tz.TZDateTime(
      location,
      localWallTime.year,
      localWallTime.month,
      localWallTime.day,
      localWallTime.hour,
      localWallTime.minute,
    );
  }

  @override
  Future<bool> schedule({
    required int id,
    required DateTime localFireTime,
    required String title,
    required String body,
    required bool exact,
    String? payload,
  }) async {
    final tz.TZDateTime zoned = toZoned(localFireTime);
    if (!zoned.isAfter(tz.TZDateTime.now(tz.local))) {
      return false;
    }
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      channelId,
      'Reminders',
      channelDescription: 'Daily commitment reminders and evening last call',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails darwin = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: android,
      iOS: darwin,
    );
    // Exact needs SCHEDULE_EXACT_ALARM (user-granted, denied by default on
    // Android 14+); otherwise we schedule inexact so reminders still arrive.
    // See: https://developer.android.com/about/versions/14/changes/schedule-exact-alarms
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: zoned,
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
    return true;
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<int> pendingCount() async {
    final List<PendingNotificationRequest> pending = await _plugin
        .pendingNotificationRequests();
    return pending.length;
  }
}
