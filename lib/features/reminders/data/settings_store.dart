// Reminder settings persisted in SharedPreferences (Stage 5 drift is for
// cached backend data; small local prefs like these stay in prefs).

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/message_engine.dart';
import '../domain/reminder_plan.dart';

class ReminderSettings {
  const ReminderSettings({
    this.quietStartMinutes = 22 * 60,
    this.quietEndMinutes = 7 * 60,
    this.tone = ReminderTone.firm,
    this.disabledCommitmentIds = const <String>{},
    this.permissionAsked = false,
  });

  final int quietStartMinutes;
  final int quietEndMinutes;
  final ReminderTone tone;
  final Set<String> disabledCommitmentIds;
  final bool permissionAsked;

  QuietHours get quietHours =>
      QuietHours(startMinutes: quietStartMinutes, endMinutes: quietEndMinutes);

  bool enabledFor(String commitmentId) =>
      !disabledCommitmentIds.contains(commitmentId);

  ReminderSettings copyWith({
    int? quietStartMinutes,
    int? quietEndMinutes,
    ReminderTone? tone,
    Set<String>? disabledCommitmentIds,
    bool? permissionAsked,
  }) {
    return ReminderSettings(
      quietStartMinutes: quietStartMinutes ?? this.quietStartMinutes,
      quietEndMinutes: quietEndMinutes ?? this.quietEndMinutes,
      tone: tone ?? this.tone,
      disabledCommitmentIds:
          disabledCommitmentIds ?? this.disabledCommitmentIds,
      permissionAsked: permissionAsked ?? this.permissionAsked,
    );
  }

  Map<String, Object> toMap() {
    return <String, Object>{
      'quietStart': quietStartMinutes,
      'quietEnd': quietEndMinutes,
      'tone': tone.index,
      'disabled': disabledCommitmentIds.toList(),
      'asked': permissionAsked,
    };
  }

  static ReminderSettings fromMap(Map<String, Object?> map) {
    final List<String> disabled = <String>[];
    final Object? rawDisabled = map['disabled'];
    if (rawDisabled is List) {
      for (final Object? item in rawDisabled) {
        if (item is String) {
          disabled.add(item);
        }
      }
    }
    final Object? rawTone = map['tone'];
    final int toneIndex = rawTone is int ? rawTone : ReminderTone.firm.index;
    return ReminderSettings(
      quietStartMinutes: (map['quietStart'] as int?) ?? 22 * 60,
      quietEndMinutes: (map['quietEnd'] as int?) ?? 7 * 60,
      tone: ReminderTone
          .values[toneIndex.clamp(0, ReminderTone.values.length - 1)],
      disabledCommitmentIds: disabled.toSet(),
      permissionAsked: (map['asked'] as bool?) ?? false,
    );
  }
}

class ReminderSettingsStore {
  ReminderSettingsStore(this._prefs);

  static const String key = 'reminder_settings_v1';

  final SharedPreferences _prefs;

  ReminderSettings load() {
    final String? raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const ReminderSettings();
    }
    try {
      final Map<String, Object?> map = <String, Object?>{};
      for (final String pair in raw.split(';')) {
        final int separator = pair.indexOf('=');
        if (separator < 0) {
          continue;
        }
        map[pair.substring(0, separator)] = _decodeValue(
          pair.substring(separator + 1),
        );
      }
      final Object? disabled = map['disabled'];
      if (disabled is String) {
        map['disabled'] = disabled.isEmpty ? <String>[] : disabled.split(',');
      }
      return ReminderSettings.fromMap(map);
    } catch (_) {
      return const ReminderSettings();
    }
  }

  Future<void> save(ReminderSettings settings) {
    final Map<String, Object> map = settings.toMap();
    final Object? disabled = map['disabled'];
    final String encoded = map.entries
        .map((MapEntry<String, Object> e) {
          final Object value = e.key == 'disabled' && disabled is List
              ? disabled.join(',')
              : e.value;
          return '${e.key}=$value';
        })
        .join(';');
    return _prefs.setString(key, encoded);
  }

  static Object _decodeValue(String raw) {
    final int? number = int.tryParse(raw);
    if (number != null) {
      return number;
    }
    if (raw == 'true') {
      return true;
    }
    if (raw == 'false') {
      return false;
    }
    return raw;
  }
}
