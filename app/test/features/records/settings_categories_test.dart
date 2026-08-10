import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/records/data/memory_record_categories_repository.dart';

import '../../support/review_calendar_test_app.dart';

void main() {
  testWidgets('adding a category in Settings persists through the real '
      'RecordCategoriesRepository', (tester) async {
    final repository = MemoryRecordCategoriesRepository();

    await tester.pumpReviewCalendarApp(categoriesRepository: repository);
    await tester.pump(const Duration(milliseconds: 100));

    // Open settings from the home tab's gear icon.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField), '테스트 카테고리');
    await tester.tap(find.byKey(const ValueKey('settings:add-category')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('테스트 카테고리'), findsOneWidget);

    // Leave and re-enter Settings — a fresh `SettingsScreen` instance only
    // shows the category if it actually round-tripped through the real
    // `RecordCategoriesRepository` (via `AppShell`'s live subscription),
    // not just `SettingsScreen`'s own optimistic local state.
    await tester.tap(find.byKey(const ValueKey('settings:back')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('테스트 카테고리'), findsOneWidget);
  });
}
