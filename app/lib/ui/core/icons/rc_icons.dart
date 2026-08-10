import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Hand-ported glyphs from the design prototype's `Icons` object
/// (design-system.jsx), transcribed path-for-path from the original SVG
/// `d` strings so they render pixel-identical without needing an external
/// icon-font dependency. All glyphs use a 24x24 viewBox.
enum RcIconGlyph {
  plus,
  camera,
  bell,
  check,
  calendar,
  chevronLeft,
  chevronRight,
  chevronDown,
  close,
  sparkle,
  image,
  wallet,
  home,
  list,
  edit,
  dot,
  clock,
  pin,
  pen,
  trend,
}

/// A stroked (occasionally filled) vector icon matching the prototype's
/// hand-drawn icon set. Defaults mirror the JSX `Icon` component: 20px,
/// `currentColor`, 1.8 stroke width, round caps/joins, no fill.
class RcIcon extends StatelessWidget {
  const RcIcon(
    this.glyph, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth,
  });

  final RcIconGlyph glyph;
  final double size;
  final Color? color;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ?? IconTheme.of(context).color ?? const Color(0xFF1F1B16);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RcIconPainter(
          glyph: glyph,
          color: resolvedColor,
          strokeWidth:
              strokeWidth ?? (glyph == RcIconGlyph.sparkle ? 1.5 : 1.8),
        ),
      ),
    );
  }
}

class _RcIconPainter extends CustomPainter {
  _RcIconPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  final RcIconGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale, scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (glyph) {
      case RcIconGlyph.plus:
        canvas.drawPath(
          Path()
            ..moveTo(12, 5)
            ..lineTo(12, 19),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, 12)
            ..lineTo(19, 12),
          stroke,
        );
        break;

      case RcIconGlyph.camera:
        final body = Path()
          ..moveTo(23, 19)
          ..arcToPoint(const Offset(21, 21), radius: const Radius.circular(2))
          ..lineTo(3, 21)
          ..arcToPoint(const Offset(1, 19), radius: const Radius.circular(2))
          ..lineTo(1, 8)
          ..arcToPoint(const Offset(3, 6), radius: const Radius.circular(2))
          ..lineTo(7, 6)
          ..lineTo(9, 3)
          ..lineTo(15, 3)
          ..lineTo(17, 6)
          ..lineTo(21, 6)
          ..arcToPoint(const Offset(23, 8), radius: const Radius.circular(2))
          ..close();
        canvas.drawPath(body, stroke);
        canvas.drawCircle(const Offset(12, 13), 4, stroke);
        break;

      case RcIconGlyph.bell:
        // Dome drawn with an explicit start/sweep angle (rather than
        // arcToPoint's largeArc/clockwise flags) since start and end are
        // exactly one diameter apart — an ambiguous case for flag-based
        // arcs that was rendering the dome flipped.
        final body = Path()
          ..addArc(
            Rect.fromCircle(center: const Offset(12, 8), radius: 6),
            0,
            -math.pi,
          )
          ..cubicTo(6, 15, 3, 17, 3, 17)
          ..lineTo(21, 17)
          ..cubicTo(39, 17, 18, 15, 18, 8);
        canvas.drawPath(body, stroke);
        final clapper = Path()
          ..moveTo(13.73, 21)
          ..quadraticBezierTo(12, 22.6, 10.27, 21);
        canvas.drawPath(clapper, stroke);
        break;

      case RcIconGlyph.check:
        canvas.drawPath(
          Path()
            ..moveTo(20, 6)
            ..lineTo(9, 17)
            ..lineTo(4, 12),
          stroke,
        );
        break;

      case RcIconGlyph.calendar:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 4, 18, 18),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(16, 2)
            ..lineTo(16, 6),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 2)
            ..lineTo(8, 6),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(3, 10)
            ..lineTo(21, 10),
          stroke,
        );
        break;

      case RcIconGlyph.chevronLeft:
        canvas.drawPath(
          Path()
            ..moveTo(15, 18)
            ..lineTo(9, 12)
            ..lineTo(15, 6),
          stroke,
        );
        break;

      case RcIconGlyph.chevronRight:
        canvas.drawPath(
          Path()
            ..moveTo(9, 18)
            ..lineTo(15, 12)
            ..lineTo(9, 6),
          stroke,
        );
        break;

      case RcIconGlyph.chevronDown:
        canvas.drawPath(
          Path()
            ..moveTo(6, 9)
            ..lineTo(12, 15)
            ..lineTo(18, 9),
          stroke,
        );
        break;

      case RcIconGlyph.close:
        canvas.drawPath(
          Path()
            ..moveTo(18, 6)
            ..lineTo(6, 18),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6, 6)
            ..lineTo(18, 18),
          stroke,
        );
        break;

      case RcIconGlyph.sparkle:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(13.5, 7.5)
            ..lineTo(18, 9)
            ..lineTo(13.5, 10.5)
            ..lineTo(12, 15)
            ..lineTo(10.5, 10.5)
            ..lineTo(6, 9)
            ..lineTo(10.5, 7.5)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(19, 14)
            ..lineTo(19.8, 16.2)
            ..lineTo(22, 17)
            ..lineTo(19.8, 17.8)
            ..lineTo(19, 20)
            ..lineTo(18.2, 17.8)
            ..lineTo(16, 17)
            ..lineTo(18.2, 16.2)
            ..close(),
          stroke,
        );
        break;

      case RcIconGlyph.image:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18),
            const Radius.circular(2),
          ),
          stroke,
        );
        canvas.drawCircle(const Offset(8.5, 8.5), 1.5, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(21, 15)
            ..lineTo(16, 10)
            ..lineTo(5, 21),
          stroke,
        );
        break;

      case RcIconGlyph.wallet:
        final body = Path()
          ..moveTo(20, 12)
          ..lineTo(20, 8)
          ..arcToPoint(
            const Offset(18, 6),
            radius: const Radius.circular(2),
            clockwise: false,
          )
          ..lineTo(4, 6)
          ..arcToPoint(
            const Offset(2, 8),
            radius: const Radius.circular(2),
            clockwise: false,
          )
          ..lineTo(2, 17)
          ..arcToPoint(
            const Offset(4, 19),
            radius: const Radius.circular(2),
            clockwise: false,
          )
          ..lineTo(18, 19)
          ..arcToPoint(
            const Offset(20, 17),
            radius: const Radius.circular(2),
            clockwise: false,
          )
          ..lineTo(20, 13);
        canvas.drawPath(body, stroke);
        final slot = Path()
          ..moveTo(20, 12)
          ..lineTo(16, 12)
          ..arcToPoint(
            const Offset(16, 16),
            radius: const Radius.circular(2),
            clockwise: false,
          )
          ..lineTo(20, 16);
        canvas.drawPath(slot, stroke);
        break;

      case RcIconGlyph.home:
        canvas.drawPath(
          Path()
            ..moveTo(3, 12)
            ..lineTo(12, 3)
            ..lineTo(21, 12),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(5, 10)
            ..lineTo(5, 20)
            ..lineTo(19, 20)
            ..lineTo(19, 10),
          stroke,
        );
        break;

      case RcIconGlyph.list:
        canvas.drawPath(
          Path()
            ..moveTo(8, 6)
            ..lineTo(21, 6),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 12)
            ..lineTo(21, 12),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(8, 18)
            ..lineTo(21, 18),
          stroke,
        );
        for (final y in [6.0, 12.0, 18.0]) {
          canvas.drawCircle(Offset(3, y), strokeWidth / 2, fill);
        }
        break;

      case RcIconGlyph.edit:
        canvas.drawPath(
          Path()
            ..moveTo(12, 20)
            ..lineTo(21, 20),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(16.5, 3.5)
            ..arcToPoint(
              const Offset(19.5, 6.5),
              radius: const Radius.circular(2.12),
            )
            ..lineTo(7, 19)
            ..lineTo(3, 20)
            ..lineTo(4, 16)
            ..close(),
          stroke,
        );
        break;

      case RcIconGlyph.dot:
        canvas.drawCircle(const Offset(12, 12), 3, fill);
        break;

      case RcIconGlyph.clock:
        canvas.drawCircle(const Offset(12, 12), 10, stroke);
        canvas.drawPath(
          Path()
            ..moveTo(12, 6)
            ..lineTo(12, 12)
            ..lineTo(16, 14),
          stroke,
        );
        break;

      case RcIconGlyph.pin:
        final body = Path()
          ..moveTo(21, 10)
          ..cubicTo(21, 17, 12, 23, 12, 23)
          ..cubicTo(12, 23, 3, 17, 3, 10)
          ..arcToPoint(
            const Offset(21, 10),
            radius: const Radius.circular(9),
            largeArc: true,
          )
          ..close();
        canvas.drawPath(body, stroke);
        canvas.drawCircle(const Offset(12, 10), 3, stroke);
        break;

      case RcIconGlyph.pen:
        canvas.drawPath(
          Path()
            ..moveTo(17, 3)
            ..arcToPoint(
              const Offset(21, 7),
              radius: const Radius.elliptical(2.85, 2.83),
              largeArc: true,
            )
            ..lineTo(7.5, 20.5)
            ..lineTo(2, 22)
            ..lineTo(3.5, 16.5)
            ..close(),
          stroke,
        );
        break;

      case RcIconGlyph.trend:
        canvas.drawPath(
          Path()
            ..moveTo(23, 6)
            ..lineTo(13.5, 15.5)
            ..lineTo(8.5, 10.5)
            ..lineTo(1, 18),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(17, 6)
            ..lineTo(23, 6)
            ..lineTo(23, 12),
          stroke,
        );
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RcIconPainter oldDelegate) {
    return oldDelegate.glyph != glyph ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
