import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/UI/components/series_header.dart';

// Calcolo rigoroso di completamento: serve a evitare che serie sotto i minimi
// (reps/weight) risultino completate anche se un flag legacy è true.
bool _isStrictlyDone(Series s) {
  final int minReps = s.reps;
  final int? maxReps = s.maxReps;
  final double minWeight = s.weight;
  final double? maxWeight = s.maxWeight;

  final int repsDone = s.repsDone;
  final double weightDone = s.weightDone;

  final bool repsOk = maxReps != null
      ? (repsDone >= minReps && repsDone <= maxReps)
      : (repsDone >= minReps);
  final bool weightOk = maxWeight != null
      ? (weightDone >= minWeight && weightDone <= maxWeight)
      : (weightDone >= minWeight);
  return repsOk && weightOk;
}

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
          final done = _isStrictlyDone(s);
          final attempted = s.hasExecutionData && !done;
          return Container(
            margin: EdgeInsets.only(bottom: AppTheme.spacing.xs),
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.xs,
              horizontal: AppTheme.spacing.sm,
            ),
            decoration: BoxDecoration(
              color: done
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.16)
                  : attempted
                      ? colorScheme.tertiaryContainer.withValues(alpha: 0.12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              border: Border.all(
                color: attempted
                    ? colorScheme.tertiary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.outlineVariant.withValues(
                        alpha: done ? 0 : 0.3,
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
    final done = _isStrictlyDone(series);
    final attempted = series.hasExecutionData && !done;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 480;
    
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: done
          ? colorScheme.primaryContainer
          : (attempted
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: done
                    ? colorScheme.onPrimaryContainer
                    : (attempted
                        ? colorScheme.onTertiaryContainer
                        : colorScheme.onSurfaceVariant),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(width: isCompact ? 4 : 8),
        Expanded(
          flex: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: _pill(
              context,
              label: _formatRepsRange(context, series.reps, series.maxReps),
              icon: Icons.repeat,
            ),
          ),
        ),
        SizedBox(width: isCompact ? 4 : 8),
        Expanded(
          flex: 5,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: _pill(
              context,
              label: _formatWeightRange(context, series.weight, series.maxWeight),
              icon: Icons.fitness_center,
            ),
          ),
        ),
        SizedBox(width: isCompact ? 4 : 8),
        Expanded(
          flex: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
        done
          ? '${series.repsDone}×${_fmtNum(series.weightDone)}'
          : (attempted
            ? _attemptedText(series)
            : '-'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: done ? FontWeight.w600 : FontWeight.normal,
          color: done
            ? colorScheme.onSurface
            : (attempted
              ? colorScheme.tertiary
              : colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: IconButton(
            icon: Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_outlined,
              color: done
                  ? colorScheme.primary
                  : (attempted
                      ? colorScheme.tertiary
                      : colorScheme.onSurfaceVariant),
              size: 24,
            ),
            onPressed: onToggleComplete,
          ),
        ),
      ],
    );
  }

  String _formatRepsRange(BuildContext context, int reps, int? maxReps) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    if (maxReps != null && maxReps > reps) {
      return isVeryCompact ? '$reps~$maxReps' : '$reps-$maxReps';
    }
    return '$reps';
  }

  String _formatWeightRange(BuildContext context, num weight, double? maxWeight) {
    String fmt(num v) => (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryCompact = screenWidth < 360;
    
    if (maxWeight != null && maxWeight > weight) {
      return isVeryCompact 
        ? '${fmt(weight)}~${fmt(maxWeight)}' 
        : '${fmt(weight)}-${fmt(maxWeight)}kg';
    }
    return '${fmt(weight)}${isVeryCompact ? '' : 'kg'}';
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 480;
    final isVeryCompact = screenWidth < 360;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVeryCompact ? 2 : (isCompact ? 4 : 8), 
        vertical: isVeryCompact ? 3 : (isCompact ? 4 : 6)
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCompact) ...[
            Icon(icon, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.clip,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurface,
                fontSize: isVeryCompact ? 10 : (isCompact ? 12 : null),
                letterSpacing: isVeryCompact ? -0.2 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _attemptedText(Series s) {
    final hasReps = s.repsDone > 0;
    final hasWeight = s.weightDone > 0;
    if (hasReps && hasWeight) return '${s.repsDone}×${_fmtNum(s.weightDone)}';
    if (hasReps) return '${s.repsDone}×-';
    return '-×${_fmtNum(s.weightDone)}';
  }

  String _fmtNum(num v) => (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
}
