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
}
