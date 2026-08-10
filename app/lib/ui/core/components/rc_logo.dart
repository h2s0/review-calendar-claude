import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

class RcLogo extends StatelessWidget {
  const RcLogo({
    super.key,
    this.size = 36,
    this.inverted = false,
    this.semanticLabel = '리뷰캘린더',
  });

  final double size;
  final bool inverted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final logo = CustomPaint(
      size: Size.square(size),
      painter: _RcLogoPainter(
        brand: context.rcColors.brand,
        soft: context.rcColors.brandSoft,
        inverted: inverted,
      ),
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: logo);
    }

    return Semantics(label: semanticLabel, image: true, child: logo);
  }
}

class RcWordmark extends StatelessWidget {
  const RcWordmark({super.key, this.inverted = false});

  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Semantics(
      label: '리뷰캘린더',
      header: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RcLogo(size: 32, inverted: inverted, semanticLabel: null),
          const SizedBox(width: 8),
          Text(
            '리뷰캘린더',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: inverted ? colors.card : colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _RcLogoPainter extends CustomPainter {
  const _RcLogoPainter({
    required this.brand,
    required this.soft,
    required this.inverted,
  });

  final Color brand;
  final Color soft;
  final bool inverted;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40;
    canvas.scale(scale);

    final foreground = inverted ? Colors.white : brand;
    final background = inverted ? brand : soft;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 40, 40),
        const Radius.circular(11),
      ),
      Paint()..color = background,
    );

    final outline = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 11, 22, 21),
        const Radius.circular(3.5),
      ),
      outline,
    );

    final fill = Paint()..color = foreground;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 11, 22, 5.5),
          const Radius.circular(3.5),
        ),
        fill,
      )
      ..drawRect(const Rect.fromLTWH(9, 13, 22, 3.5), fill)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 8, 2.2, 6),
          const Radius.circular(1.1),
        ),
        fill,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(23.8, 8, 2.2, 6),
          const Radius.circular(1.1),
        ),
        fill,
      );

    final check = Path()
      ..moveTo(14, 23)
      ..lineTo(18, 27)
      ..lineTo(26, 20);
    canvas.drawPath(
      check,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RcLogoPainter oldDelegate) {
    return brand != oldDelegate.brand ||
        soft != oldDelegate.soft ||
        inverted != oldDelegate.inverted;
  }
}
