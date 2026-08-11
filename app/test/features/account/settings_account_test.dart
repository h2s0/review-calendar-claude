import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/review_calendar_test_app.dart';

void main() {
  testWidgets('signing out from Settings calls through to AuthRepository', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();

    await tester.pumpReviewCalendarApp(authRepository: authRepository);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('로그아웃'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));

    expect(authRepository.signOutCalls, 1);
    // Signing out drops back to the login screen — settings/tabs are gone.
    expect(find.text('Google로 계속하기'), findsOneWidget);
  });

  testWidgets(
    'deleting the account requires confirmation before calling through',
    (tester) async {
      final authRepository = FakeAuthRepository();

      await tester.pumpReviewCalendarApp(authRepository: authRepository);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('회원 탈퇴'));
      await tester.pump(const Duration(milliseconds: 100));

      // The confirmation dialog is up — cancelling must not call through.
      expect(find.text('취소'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(authRepository.deleteAccountCalls, 0);

      // Confirming does call through.
      await tester.tap(find.text('회원 탈퇴'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('탈퇴하기'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(authRepository.deleteAccountCalls, 1);
      expect(find.text('Google로 계속하기'), findsOneWidget);
    },
  );
}
