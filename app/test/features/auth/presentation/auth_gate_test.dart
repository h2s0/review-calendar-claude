import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/presentation/auth_screen.dart';
import 'package:review_calendar/features/auth/presentation/auth_ui_state.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

import '../../../support/fake_auth_repository.dart';
import '../../../support/review_calendar_test_app.dart';

void main() {
  testWidgets('keeps app hidden while auth state initializes', (tester) async {
    final auth = FakeAuthRepository(initialUser: null, emitInitialState: false);

    await tester.pumpWidget(buildReviewCalendarTestApp(authRepository: auth));
    await tester.pump();

    expect(find.byKey(const ValueKey('screen:/auth-loading')), findsOneWidget);

    auth.emit(null);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('screen:/auth')), findsOneWidget);

    await auth.dispose();
  });

  testWidgets('shows Android providers and enters the app after sign-in', (
    tester,
  ) async {
    final auth = FakeAuthRepository(initialUser: null);

    await tester.pumpWidget(buildReviewCalendarTestApp(authRepository: auth));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth:google')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth:kakao')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth:apple')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('auth:google')));
    // Not pumpAndSettle: the Home tab's goal-push mascot loops forever.
    await tester.pump(const Duration(milliseconds: 100));

    expect(auth.signInCalls, [AuthProvider.google]);
    expect(find.byKey(const ValueKey('screen:/auth')), findsNothing);
    expect(find.text('안녕하세요 👋'), findsOneWidget);

    await auth.dispose();
  });

  testWidgets('shows Apple only on the iOS provider set', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: RcTheme.light().copyWith(platform: TargetPlatform.iOS),
        home: AuthScreen(
          state: const AuthUiState(
            gateStatus: AuthGateStatus.signedOut,
            actionStatus: AuthActionStatus.idle,
          ),
          onSignIn: (_) {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('auth:apple')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth:google')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth:kakao')), findsOneWidget);
  });

  testWidgets('disables providers while a sign-in attempt is pending', (
    tester,
  ) async {
    final completer = Completer<AuthSignInResult>();
    final auth = FakeAuthRepository(
      initialUser: null,
      signInHandler: (_) => completer.future,
    );

    await tester.pumpWidget(buildReviewCalendarTestApp(authRepository: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('auth:kakao')));
    await tester.pump();

    final google = tester.widget<FilledButton>(
      find.byKey(const ValueKey('auth:google')),
    );
    expect(google.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(const AuthSignInFailure(kind: AuthFailureKind.network));
    await tester.pumpAndSettle();
    expect(find.text('인터넷 연결을 확인하고 다시 시도해 주세요.'), findsOneWidget);

    await auth.dispose();
  });

  for (final entry in {
    AuthFailureKind.cancelled: '로그인이 취소됐어요. 다시 시도할 수 있어요.',
    AuthFailureKind.provider: '공급자 연결 오류',
  }.entries) {
    testWidgets('shows ${entry.key.name} feedback and remains signed out', (
      tester,
    ) async {
      final auth = FakeAuthRepository(
        initialUser: null,
        signInHandler: (_) async => AuthSignInFailure(
          kind: entry.key,
          message: entry.key == AuthFailureKind.provider ? entry.value : null,
        ),
      );

      await tester.pumpWidget(buildReviewCalendarTestApp(authRepository: auth));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('auth:google')));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.byKey(const ValueKey('screen:/auth')), findsOneWidget);

      await auth.dispose();
    });
  }

  testWidgets('meets login tap target and labeling guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      buildReviewCalendarTestApp(
        authRepository: FakeAuthRepository(initialUser: null),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
