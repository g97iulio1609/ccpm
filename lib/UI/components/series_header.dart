import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class SeriesHeader extends StatelessWidget {
  final List<String> labels;
  final List<int>? flex;

  const SeriesHeader({
    super.key,
    this.labels = const ['#', 'Reps', 'Peso', 'Fatti'],
    this.flex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<int> effectiveFlex = flex ?? [1, 2, 2, 2];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTheme.spacing.xs,
        horizontal: AppTheme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              labels[0],
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          ...List.generate(labels.length - 1, (index) {
            final label = labels[index + 1];
            final flexValue = effectiveFlex.length > index + 1
                ? effectiveFlex[index + 1]
                : 2;
            return Expanded(
              flex: flexValue,
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ],
      ),
    );
  }
}
