import 'package:flutter/material.dart';
import 'package:review_calendar/ui/core/theme/rc_layout.dart';
import 'package:review_calendar/ui/core/theme/rc_theme.dart';

/// A single-selection pill (category chips, etc.) matching the design
/// mockup's plain color-fill selection style — no checkmark glyph, unlike
/// Material's [ChoiceChip].
class RcChoicePill extends StatelessWidget {
  const RcChoicePill({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.rcColors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.brand : colors.backgroundAlternative,
        borderRadius: BorderRadius.circular(RcRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(RcRadius.pill),
          onTap: onSelected,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: RcSpacing.xl,
              vertical: RcSpacing.lg,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.card : colors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
