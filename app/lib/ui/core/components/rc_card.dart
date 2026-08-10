import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

class RcCard extends StatelessWidget {
  const RcCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(RcSpacing.section),
    this.radius = RcRadius.large,
    this.borderStyle = BorderStyle.solid,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final BorderStyle borderStyle;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    final borderRadius = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      container: true,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: colors.border, style: borderStyle),
        ),
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: RcSize.minimumTouchTarget,
                  ),
                  child: content,
                ),
              ),
      ),
    );
  }
}
