import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class ProgressBar extends StatelessWidget {
  final int done;
  final int total;
  final String Function(double pct)? labelBuilder;
  const ProgressBar({super.key, required this.done, required this.total, this.labelBuilder});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : done / total;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct.clamp(0, 1),
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Text(
          labelBuilder?.call(pct) ?? '${(pct * 100).round()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}
