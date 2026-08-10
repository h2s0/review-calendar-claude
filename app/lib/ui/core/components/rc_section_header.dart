import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

class RcSectionHeader extends StatelessWidget {
  const RcSectionHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: RcSpacing.sm,
            runSpacing: RcSpacing.xxs,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle case final subtitle?)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: context.rcColors.inkSubtle,
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
