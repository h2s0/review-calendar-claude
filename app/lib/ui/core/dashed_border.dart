import 'package:flutter/material.dart';

/// A dashed rounded-rect border + optional fill — Flutter's `Border` has no
/// dashed style built in, and the design prototype uses dashed borders in
/// several places (undecided-visit chips, upload dropzone, unresolved
/// visit-slot). Mirrors CSS `border: Npx dashed <color>`.
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    required this.child,
    required this.color,
    super.key,
    this.strokeWidth = 1,
    this.radius = 12,
    this.dashWidth = 4,
    this.gapWidth = 3,
    this.background,
  });

  final Widget child;
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double gapWidth;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: color,
        strokeWidth: strokeWidth,
        radius: radius,
        dashWidth: dashWidth,
        gapWidth: gapWidth,
        background: background,
      ),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.gapWidth,
    this.background,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double gapWidth;
  final Color? background;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    if (background != null) {
      canvas.drawRRect(rrect, Paint()..color = background!);
    }
    final dashPath = Path();
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashPath.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + gapWidth;
      }
    }
    canvas.drawPath(
      dashPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.background != background;
  }
}

/// A short dashed vertical divider — used between the DATE/TIME halves of
/// the visit-slot chip.
class DashedVerticalDivider extends StatelessWidget {
  const DashedVerticalDivider({
    required this.color,
    super.key,
    this.width = 1,
    this.dashHeight = 3,
    this.gapHeight = 2,
  });

  final Color color;
  final double width;
  final double dashHeight;
  final double gapHeight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, double.infinity),
      painter: _DashedLinePainter(
        color: color,
        dashHeight: dashHeight,
        gapHeight: gapHeight,
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({
    required this.color,
    required this.dashHeight,
    required this.gapHeight,
  });
  final Color color;
  final double dashHeight;
  final double gapHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, dashHeight), paint);
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}
