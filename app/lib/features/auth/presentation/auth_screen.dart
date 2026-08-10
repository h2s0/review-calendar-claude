import 'package:flutter/material.dart';
import 'package:review_calendar/features/auth/data/auth_repository.dart';
import 'package:review_calendar/features/auth/presentation/auth_ui_state.dart';
import 'package:review_calendar/ui/core/components/rc_logo.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({required this.state, required this.onSignIn, super.key});

  final AuthUiState state;
  final ValueChanged<AuthProvider> onSignIn;

  @override
  Widget build(BuildContext context) {
    final providers = _providersFor(Theme.of(context).platform);
    return Scaffold(
      key: const ValueKey('screen:/auth'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(RcSpacing.page),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - RcSpacing.page * 2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: RcLogo(size: 64),
                        ),
                        const SizedBox(height: RcSpacing.page),
                        Text(
                          '체험단 일정을\n한눈에 관리하세요',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontSize: 30, height: 1.25),
                        ),
                        const SizedBox(height: RcSpacing.xl),
                        Text(
                          '방문 일정부터 포스팅 마감, 수익까지\n리뷰캘린더가 놓치지 않게 정리해 드려요.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: context.rcColors.inkSubtle),
                        ),
                        const SizedBox(height: RcSpacing.hero),
                        if (state.message case final message?) ...[
                          _AuthMessage(
                            message: message,
                            tone: state.messageTone,
                          ),
                          const SizedBox(height: RcSpacing.section),
                        ],
                        for (final provider in providers) ...[
                          _ProviderButton(
                            provider: provider,
                            isLoading:
                                state.isSigningIn &&
                                state.activeProvider == provider,
                            isEnabled: !state.isSigningIn,
                            onPressed: () => onSignIn(provider),
                          ),
                          const SizedBox(height: RcSpacing.xl),
                        ],
                        const SizedBox(height: RcSpacing.md),
                        Text(
                          '로그인하면 일정과 설정을 기기 간에 안전하게 동기화할 수 있어요.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<AuthProvider> _providersFor(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.iOS => const [
        AuthProvider.apple,
        AuthProvider.google,
        AuthProvider.kakao,
      ],
      _ => const [AuthProvider.google, AuthProvider.kakao],
    };
  }
}

final class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message, required this.tone});

  final String message;
  final AuthMessageTone tone;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tone == AuthMessageTone.error
              ? context.rcColors.deadline.soft
              : context.rcColors.brandSoft,
          borderRadius: BorderRadius.circular(RcRadius.medium),
          border: Border.all(
            color: tone == AuthMessageTone.error
                ? context.rcColors.deadline.chip
                : context.rcColors.brandTint,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(RcSpacing.section),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: RcSize.iconMedium,
                color: tone == AuthMessageTone.error
                    ? context.rcColors.deadline.ink
                    : context.rcColors.brandDeep,
              ),
              const SizedBox(width: RcSpacing.lg),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.provider,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  final AuthProvider provider;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (provider) {
      AuthProvider.apple => 'Apple로 계속하기',
      AuthProvider.google => 'Google로 계속하기',
      AuthProvider.kakao => '카카오로 계속하기',
    };
    final foreground = provider == AuthProvider.kakao
        ? context.rcColors.ink
        : provider == AuthProvider.apple
        ? context.rcColors.card
        : context.rcColors.ink;
    final background = provider == AuthProvider.kakao
        ? context.rcColors.visit.chip
        : provider == AuthProvider.apple
        ? context.rcColors.ink
        : context.rcColors.card;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: 54,
        child: FilledButton(
          key: ValueKey('auth:${provider.name}'),
          onPressed: isEnabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background.withValues(alpha: 0.58),
            disabledForegroundColor: foreground.withValues(alpha: 0.78),
            side: BorderSide(color: context.rcColors.borderStrong),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: isLoading
                    ? SizedBox.square(
                        dimension: RcSize.iconMedium,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : _ProviderMark(provider: provider),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ProviderMark extends StatelessWidget {
  const _ProviderMark({required this.provider});

  final AuthProvider provider;

  @override
  Widget build(BuildContext context) {
    return switch (provider) {
      AuthProvider.apple => const Icon(Icons.apple_rounded),
      AuthProvider.google => Text(
        'G',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: const Color(0xFF4285F4),
          fontWeight: FontWeight.w800,
        ),
      ),
      AuthProvider.kakao => const Icon(Icons.chat_bubble_rounded),
    };
  }
}
