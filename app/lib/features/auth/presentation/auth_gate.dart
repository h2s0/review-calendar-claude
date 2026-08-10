import 'package:flutter/material.dart';
import 'package:review_calendar/features/auth/domain/auth_user.dart';
import 'package:review_calendar/features/auth/presentation/auth_screen.dart';
import 'package:review_calendar/features/auth/presentation/auth_ui_state.dart';
import 'package:review_calendar/features/auth/presentation/auth_view_model.dart';
import 'package:review_calendar/ui/core/components/rc_logo.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    required this.viewModel,
    required this.authenticatedBuilder,
    super.key,
  });

  final AuthViewModel viewModel;
  final Widget Function(AuthUser user) authenticatedBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final state = viewModel.state;
        return switch (state.gateStatus) {
          AuthGateStatus.initializing => const _AuthInitializingScreen(),
          AuthGateStatus.signedOut => AuthScreen(
            state: state,
            onSignIn: viewModel.signIn,
          ),
          AuthGateStatus.signedIn => authenticatedBuilder(state.user!),
        };
      },
    );
  }
}

final class _AuthInitializingScreen extends StatelessWidget {
  const _AuthInitializingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('screen:/auth-loading'),
      body: Center(
        child: Semantics(
          label: '로그인 상태 확인 중',
          liveRegion: true,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RcLogo(size: 56),
              SizedBox(height: RcSpacing.page),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
