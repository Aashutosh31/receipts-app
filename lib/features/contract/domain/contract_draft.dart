// Onboarding input model + validation for the "Sign the Contract" flow.
// Pure Dart so it can be unit-tested without Supabase.

import 'contract_models.dart';

/// One commitment drafted during onboarding.
class CommitmentDraft {
  CommitmentDraft({this.title = '', this.targetTime = ''});

  /// 1-120 chars (database check constraint).
  String title;

  /// '' (none) or HH:MM 24-hour (maps to the database `time` column).
  String targetTime;
}

/// Mutable onboarding form state. The screen owns one instance.
class ContractDraft {
  ContractDraft()
    : commitments = <CommitmentDraft>[
        CommitmentDraft(),
        CommitmentDraft(),
        CommitmentDraft(),
      ];

  final List<CommitmentDraft> commitments;
  ContractModeDto? mode;

  /// The typed signature on the pledge screen.
  String signature = '';

  bool get canAddMore => commitments.length < 5;
  bool get canRemove => commitments.length > 3;

  /// 90-day end date shown before signing. Starts today (device date is
  /// only for preview; the server sets the real start_date on insert).
  DateTime endDate(DateTime startDate) {
    final DateTime start = DateTime.utc(
      startDate.year,
      startDate.month,
      startDate.day,
    );
    return start.add(const Duration(days: 90));
  }

  /// Returns the first problem found, or null when the draft is signable.
  String? validate() {
    if (commitments.length < 3 || commitments.length > 5) {
      return 'Choose 3 to 5 commitments.';
    }
    for (int i = 0; i < commitments.length; i++) {
      final String title = commitments[i].title.trim();
      if (title.isEmpty) {
        return 'Commitment ${i + 1} needs a title.';
      }
      if (title.length > 120) {
        return 'Commitment ${i + 1} is too long (max 120 characters).';
      }
      final String time = commitments[i].targetTime.trim();
      if (time.isNotEmpty && !_isValidTime(time)) {
        return 'Commitment ${i + 1}: time must look like 06:30.';
      }
    }
    if (mode == null) {
      return 'Pick Hard Mode or Kind Mode.';
    }
    if (signature.trim().isEmpty) {
      return 'Type your name to sign the pledge.';
    }
    return null;
  }

  static final RegExp _timePattern = RegExp(r'^([01][0-9]|2[0-3]):[0-5][0-9]$');

  static bool _isValidTime(String value) => _timePattern.hasMatch(value);
}
