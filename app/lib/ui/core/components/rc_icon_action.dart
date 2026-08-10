import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

class RcIconAction extends StatelessWidget {
  const RcIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: RcSize.iconMedium),
      style: IconButton.styleFrom(
        backgroundColor: colors.card,
        disabledBackgroundColor: colors.backgroundAlternative,
        disabledForegroundColor: colors.inkMuted,
        side: BorderSide(color: colors.border),
        minimumSize: const Size.square(RcSize.minimumTouchTarget),
        shape: const CircleBorder(),
      ),
    );
  }
}
