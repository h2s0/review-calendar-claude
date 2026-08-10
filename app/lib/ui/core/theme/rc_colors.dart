import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_event_colors.dart';

@immutable
class RcColors extends ThemeExtension<RcColors> {
  const RcColors({
    required this.background,
    required this.backgroundAlternative,
    required this.card,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.inkSubtle,
    required this.inkMuted,
    required this.brand,
    required this.brandDeep,
    required this.brandSoft,
    required this.brandTint,
    required this.visit,
    required this.deadline,
    required this.posted,
    required this.unscheduled,
  });

  static const light = RcColors(
    background: Color(0xFFFAF8F3),
    backgroundAlternative: Color(0xFFF3F0E8),
    card: Color(0xFFFFFFFF),
    border: Color(0x143C3228),
    borderStrong: Color(0x243C3228),
    ink: Color(0xFF1F1B16),
    inkSubtle: Color(0xFF6B6357),
    inkMuted: Color(0xFF9A9081),
    brand: Color(0xFF4A7A5C),
    brandDeep: Color(0xFF355943),
    brandSoft: Color(0xFFE8F0E9),
    brandTint: Color(0xFFD6E4D9),
    visit: RcEventColors(
      ink: Color(0xFFB8860B),
      soft: Color(0xFFFBF1CE),
      chip: Color(0xFFEBCB5C),
    ),
    deadline: RcEventColors(
      ink: Color(0xFFC23B3B),
      soft: Color(0xFFFAE1E1),
      chip: Color(0xFFEB9494),
    ),
    posted: RcEventColors(
      ink: Color(0xFF4A7A5C),
      soft: Color(0xFFDDE9DF),
      chip: Color(0xFF8FB39A),
    ),
    unscheduled: RcEventColors(
      ink: Color(0xFF6B7A8F),
      soft: Color(0xFFE4E8EE),
      chip: Color(0xFFA5B1C2),
    ),
  );

  final Color background;
  final Color backgroundAlternative;
  final Color card;
  final Color border;
  final Color borderStrong;
  final Color ink;
  final Color inkSubtle;
  final Color inkMuted;
  final Color brand;
  final Color brandDeep;
  final Color brandSoft;
  final Color brandTint;
  final RcEventColors visit;
  final RcEventColors deadline;
  final RcEventColors posted;
  final RcEventColors unscheduled;

  @override
  RcColors copyWith({
    Color? background,
    Color? backgroundAlternative,
    Color? card,
    Color? border,
    Color? borderStrong,
    Color? ink,
    Color? inkSubtle,
    Color? inkMuted,
    Color? brand,
    Color? brandDeep,
    Color? brandSoft,
    Color? brandTint,
    RcEventColors? visit,
    RcEventColors? deadline,
    RcEventColors? posted,
    RcEventColors? unscheduled,
  }) {
    return RcColors(
      background: background ?? this.background,
      backgroundAlternative:
          backgroundAlternative ?? this.backgroundAlternative,
      card: card ?? this.card,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      ink: ink ?? this.ink,
      inkSubtle: inkSubtle ?? this.inkSubtle,
      inkMuted: inkMuted ?? this.inkMuted,
      brand: brand ?? this.brand,
      brandDeep: brandDeep ?? this.brandDeep,
      brandSoft: brandSoft ?? this.brandSoft,
      brandTint: brandTint ?? this.brandTint,
      visit: visit ?? this.visit,
      deadline: deadline ?? this.deadline,
      posted: posted ?? this.posted,
      unscheduled: unscheduled ?? this.unscheduled,
    );
  }

  @override
  RcColors lerp(covariant RcColors? other, double t) {
    if (other == null) {
      return this;
    }

    return RcColors(
      background: Color.lerp(background, other.background, t) ?? background,
      backgroundAlternative:
          Color.lerp(backgroundAlternative, other.backgroundAlternative, t) ??
          backgroundAlternative,
      card: Color.lerp(card, other.card, t) ?? card,
      border: Color.lerp(border, other.border, t) ?? border,
      borderStrong:
          Color.lerp(borderStrong, other.borderStrong, t) ?? borderStrong,
      ink: Color.lerp(ink, other.ink, t) ?? ink,
      inkSubtle: Color.lerp(inkSubtle, other.inkSubtle, t) ?? inkSubtle,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t) ?? inkMuted,
      brand: Color.lerp(brand, other.brand, t) ?? brand,
      brandDeep: Color.lerp(brandDeep, other.brandDeep, t) ?? brandDeep,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t) ?? brandSoft,
      brandTint: Color.lerp(brandTint, other.brandTint, t) ?? brandTint,
      visit: RcEventColors.lerp(visit, other.visit, t),
      deadline: RcEventColors.lerp(deadline, other.deadline, t),
      posted: RcEventColors.lerp(posted, other.posted, t),
      unscheduled: RcEventColors.lerp(unscheduled, other.unscheduled, t),
    );
  }
}
