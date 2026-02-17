import 'package:flutter_test/flutter_test.dart';
import 'package:journalx/app.dart';

void main() {
  testWidgets('JournalX app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const JournalXApp());

    // Verify that the app loads with the Food Journal title
    expect(find.text('Food'), findsOneWidget);
  });
}
