import 'package:flutter_test/flutter_test.dart';
import 'package:receipts/main.dart';

void main() {
  testWidgets('shows missing-config guidance without env keys', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ReceiptsApp());
    expect(find.textContaining('Missing SUPABASE_URL'), findsOneWidget);
    expect(
      find.textContaining('flutter run --dart-define-from-file=env.json'),
      findsOneWidget,
    );
  });
}
