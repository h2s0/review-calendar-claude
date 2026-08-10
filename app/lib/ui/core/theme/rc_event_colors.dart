import 'package:flutter/material.dart';

@immutable
class RcEventColors {
  const RcEventColors({
    required this.ink,
    required this.soft,
    required this.chip,
  });

  final Color ink;
  final Color soft;
  final Color chip;

  static RcEventColors lerp(
    RcEventColors first,
    RcEventColors second,
    double t,
  ) {
    return RcEventColors(
      ink: Color.lerp(first.ink, second.ink, t) ?? second.ink,
      soft: Color.lerp(first.soft, second.soft, t) ?? second.soft,
      chip: Color.lerp(first.chip, second.chip, t) ?? second.chip,
    );
  }
}
