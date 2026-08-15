import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/campaign/data/fake_campaign_repository.dart';

import '../../support/review_calendar_test_app.dart';

void main() {
  testWidgets(
    'submitting the manual-entry form creates a real campaign and the '
    'calendar reflects it after popping back',
    (tester) async {
      final repository = FakeCampaignRepository();

      await tester.pumpReviewCalendarApp(campaignRepository: repository);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byKey(const ValueKey('tab-bar:upload')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('직접 입력'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.enterText(find.byType(TextField).first, '테스트 카페 홍대점');
      await tester.pump(const Duration(milliseconds: 100));

      // The visit date starts as "미정" (undecided) — it's a required field
      // (see campaign_registration_draft.dart's `_validateAvailability`), so
      // it has to be picked before submitting can succeed.
      await tester.tap(find.text('미정').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').first);
      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('캘린더에 등록하기'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      expect(repository.createCallCount, 1);
      expect(repository.createCalls.single.brand, '테스트 카페 홍대점');

      // The upload sheet pops back to the calendar/home shell on success.
      expect(find.text('캘린더에 등록하기'), findsNothing);

      await tester.tap(find.text('캘린더'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('테스트 카페 홍대점'), findsWidgets);
    },
  );

  testWidgets('blocks submitting a manual entry with no visit date instead of '
      'silently saving a placeholder date', (tester) async {
    final repository = FakeCampaignRepository();

    await tester.pumpReviewCalendarApp(campaignRepository: repository);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('tab-bar:upload')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('직접 입력'));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).first, '테스트 카페 홍대점');
    await tester.pump(const Duration(milliseconds: 100));

    // Visit date left as "미정" — never opened the date picker.
    await tester.tap(find.text('캘린더에 등록하기'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.createCallCount, 0);
    expect(find.text('캘린더에 등록하기'), findsOneWidget);
  });
}
