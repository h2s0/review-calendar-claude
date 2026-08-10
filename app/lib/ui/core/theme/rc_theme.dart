import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_colors.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';

abstract final class RcTheme {
  static ThemeData light() {
    const colors = RcColors.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.brand,
      brightness: Brightness.light,
      primary: colors.brand,
      onPrimary: colors.card,
      secondary: colors.brandDeep,
      onSecondary: colors.card,
      error: colors.deadline.ink,
      onError: colors.card,
      surface: colors.background,
      onSurface: colors.ink,
      outline: colors.borderStrong,
      outlineVariant: colors.border,
    );

    final textTheme = _textTheme(colors);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Pretendard',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      textTheme: textTheme,
      extensions: const [colors],
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: colors.background,
        foregroundColor: colors.ink,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RcRadius.large),
          side: BorderSide(color: colors.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.border, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: colors.card,
          minimumSize: const Size.fromHeight(RcSize.minimumTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: RcSpacing.section,
            vertical: RcSpacing.xl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RcRadius.medium),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.ink,
          minimumSize: const Size.square(RcSize.minimumTouchTarget),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.brand),
    );
  }

  static TextTheme _textTheme(RcColors colors) {
    TextStyle style({
      required double size,
      required FontWeight weight,
      required double height,
      double letterSpacing = -0.2,
      Color? color,
    }) {
      return TextStyle(
        fontFamily: 'Pretendard',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color ?? colors.ink,
      );
    }

    return TextTheme(
      headlineSmall: style(
        size: 22,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.7,
      ),
      titleLarge: style(
        size: 17,
        weight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.4,
      ),
      titleMedium: style(size: 14, weight: FontWeight.w700, height: 1.4),
      titleSmall: style(size: 13, weight: FontWeight.w700, height: 1.4),
      bodyLarge: style(size: 14, weight: FontWeight.w500, height: 1.5),
      bodyMedium: style(size: 13, weight: FontWeight.w500, height: 1.45),
      bodySmall: style(
        size: 11,
        weight: FontWeight.w500,
        height: 1.45,
        color: colors.inkSubtle,
      ),
      labelLarge: style(size: 13, weight: FontWeight.w700, height: 1.3),
      labelMedium: style(
        size: 11,
        weight: FontWeight.w600,
        height: 1.3,
        color: colors.inkSubtle,
      ),
      labelSmall: style(
        size: 9.5,
        weight: FontWeight.w600,
        height: 1.25,
        color: colors.inkSubtle,
      ),
    );
  }
}

extension RcThemeContext on BuildContext {
  RcColors get rcColors =>
      Theme.of(this).extension<RcColors>() ?? RcColors.light;
}
