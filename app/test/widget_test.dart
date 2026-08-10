import 'package:flutter_test/flutter_test.dart';

import 'support/review_calendar_test_app.dart';

void main() {
  testWidgets('App launches on the home tab when already signed in', (
    WidgetTester tester,
  ) async {
    // FakeAuthRepository defaults to a signed-in user.
    await tester.pumpReviewCalendarApp();
    // Not pumpAndSettle: the home screen's goal-push mascot loops forever
    // (repeat(reverse: true)), so settling never completes.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('안녕하세요 👋'), findsOneWidget);
    expect(find.text('다가오는 일정'), findsOneWidget);
  });
}
