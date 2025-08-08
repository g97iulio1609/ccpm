import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

class MetaChips extends StatelessWidget {
  final Exercise exercise;
  const MetaChips({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final reps = exercise.series.isNotEmpty ? exercise.series.first.reps : null;
    final weight =
        exercise.series.isNotEmpty ? exercise.series.first.weight : null;
    final rest = exercise.series
        .firstWhere((s) => s.restTimeSeconds != null,
            orElse: () => exercise.series.first)
        .restTimeSeconds;

    return Wrap(
      spacing: AppTheme.spacing.xs,
      runSpacing: AppTheme.spacing.xs,
      children: [
        _chip(context, Icons.layers_outlined, '${exercise.series.length} serie'),
        if (reps != null) _chip(context, Icons.repeat, 'x$reps'),
        if (weight != null)
          _chip(context, Icons.fitness_center, _formatWeight(weight)),
        if (rest != null) _chip(context, Icons.timer_outlined, _formatRest(rest)),
      ],
    );
  }

  String _formatWeight(dynamic weight) {
    if (weight == null) return '-';
    if (weight is int || weight is double) {
      final num w = weight as num;
      final str = (w % 1 == 0) ? w.toInt().toString() : w.toStringAsFixed(1);
      return '$str kg';
    }
    return '$weight kg';
  }

  String _formatRest(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m${secs > 0 ? ' ${secs}s' : ''}';
    }
    return '${secs}s';
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

