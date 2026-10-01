import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/core/utils/excuse_analytics.dart';

void main() {
  group('ExcuseAnalytics', () {
    test('counts reasons and finds the top excuse', () {
      final counts = ExcuseAnalytics.countByReason(const [
        'tired',
        'busy',
        'tired',
        'forgot',
        'tired',
        'busy',
      ]);
      expect(counts, {'tired': 3, 'busy': 2, 'forgot': 1});
      expect(ExcuseAnalytics.topExcuse(counts), 'tired');
    });

    test('ignores unknown reasons', () {
      final counts = ExcuseAnalytics.countByReason(const [
        'tired',
        'nope',
        'busy',
      ]);
      expect(counts, {'tired': 1, 'busy': 1});
    });

    test('empty input has no top excuse', () {
      expect(ExcuseAnalytics.countByReason(const []), isEmpty);
      expect(ExcuseAnalytics.topExcuse(const {}), isNull);
    });
  });
}
