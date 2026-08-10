import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';

class RcStatusBadge extends StatelessWidget {
  const RcStatusBadge({
    required this.label,
    required this.foreground,
    required this.background,
    super.key,
    this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(RcRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RcSpacing.md,
          vertical: RcSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final icon?) ...[
              Icon(icon, size: RcSize.iconSmall, color: foreground),
              const SizedBox(width: RcSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
