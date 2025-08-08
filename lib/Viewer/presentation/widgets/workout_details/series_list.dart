import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/UI/components/series_header.dart';

class SeriesList extends StatelessWidget {
  final List<Series> series;
  final void Function(Series series) onSeriesTap;
  final void Function(Series series) onToggleComplete;
  const SeriesList({
    super.key,
    required this.series,
    required this.onSeriesTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            vertical: AppTheme.spacing.xs,
            horizontal: AppTheme.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(77),
            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
          ),
          child: const SeriesHeader(),
        ),
        SizedBox(height: AppTheme.spacing.sm),
        ...series.asMap().entries.map((entry) {
          final index = entry.key;
          final s = entry.value;
          return Container(
            margin: EdgeInsets.only(bottom: AppTheme.spacing.xs),
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.xs,
              horizontal: AppTheme.spacing.sm,
            ),
            decoration: BoxDecoration(
              color: s.isCompleted
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(
                  alpha: s.isCompleted ? 0 : 0.3,
                ),
              ),
            ),
            child: _SeriesRow(
              index: index,
              series: s,
              onTap: () => onSeriesTap(s),
              onToggleComplete: () => onToggleComplete(s),
            ),
          );
        }),
      ],
    );
  }
}

class _SeriesRow extends StatelessWidget {
  final int index;
  final Series series;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  const _SeriesRow({
    required this.index,
    required this.series,
    required this.onTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final done = series.isCompleted;
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: done
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: done
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: _pill(
              context,
              label: _formatRepsRange(series.reps, series.maxReps),
              icon: Icons.repeat,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: _pill(
              context,
              label: _formatWeightRange(series.weight, series.maxWeight),
              icon: Icons.fitness_center,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                done ? '${series.repsDone}×${series.weightDone}' : '-',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                  color: done
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: IconButton(
            icon: Icon(
              series.isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_outlined,
              color: series.isCompleted
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            onPressed: onToggleComplete,
          ),
        ),
      ],
    );
  }

  String _formatRepsRange(int reps, int? maxReps) {
    if (maxReps != null && maxReps > reps) {
      return '$reps-$maxReps';
    }
    return '$reps';
  }

  String _formatWeightRange(num weight, double? maxWeight) {
    String fmt(num v) => (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
    if (maxWeight != null && maxWeight > weight) {
      return '${fmt(weight)}-${fmt(maxWeight)} kg';
    }
    return '${fmt(weight)} kg';
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
