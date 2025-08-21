import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

class SuperSetSeriesMatrix extends StatelessWidget {
  final List<Exercise> exercises;
  final void Function(Series series, String exerciseType) onSeriesTap;
  final void Function(Series series) onToggleComplete;
  const SuperSetSeriesMatrix({
    super.key,
    required this.exercises,
    required this.onSeriesTap,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final maxSeries = exercises.map((e) => e.series.length).fold<int>(0, (p, c) => c > p ? c : p);

    return Column(
      children: List<Widget>.generate(maxSeries, (rowIndex) {
        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacing.xs),
          padding: EdgeInsets.symmetric(
            vertical: AppTheme.spacing.xs,
            horizontal: AppTheme.spacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            color: Colors.transparent,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${rowIndex + 1}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              ...exercises.asMap().entries.map((entry) {
                final exIndex = entry.key;
                final exercise = entry.value;
                final hasSeries = rowIndex < exercise.series.length;
                final series = hasSeries ? exercise.series[rowIndex] : null;

                final isCardio = exercise.type.toLowerCase() == 'cardio';
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(left: exIndex == 0 ? 0 : AppTheme.spacing.xs),
                    padding: EdgeInsets.symmetric(
                      vertical: AppTheme.spacing.xs,
                      horizontal: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: series?.isCompleted == true
                          ? Colors.green.withAlpha(26)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                    ),
                    child: hasSeries
                        ? _SeriesCell(
                            indexChar: String.fromCharCode(65 + exIndex),
                            series: series!,
                            isCardio: isCardio,
                            onTap: () => onSeriesTap(series, exercise.type),
                            onToggleComplete: () => onToggleComplete(series),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}

class _SeriesCell extends StatelessWidget {
  final String indexChar;
  final Series series;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final bool isCardio;
  const _SeriesCell({
    required this.indexChar,
    required this.series,
    required this.onTap,
    required this.onToggleComplete,
    required this.isCardio,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            indexChar,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                isCardio ? _formatDuration(series.durationSeconds) : '${series.reps}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                isCardio ? _formatDistance(series.distanceMeters) : '${series.weight} kg',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                isCardio
                    ? _formatExecuted(series)
                    : (series.isCompleted ? '${series.repsDone}×${series.weightDone}' : '-'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: series.isCompleted ? FontWeight.bold : null,
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
              color: series.isCompleted ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            onPressed: onToggleComplete,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '-';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDistance(int? meters) {
    if (meters == null || meters <= 0) return '-';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  String _formatExecuted(Series s) {
    final d = _formatDuration(s.executedDurationSeconds ?? 0);
    final dist = _formatDistance(s.executedDistanceMeters ?? 0);
    if (d == '-' && dist == '-') return '-';
    if (d != '-' && dist != '-') return '$d • $dist';
    return d != '-' ? d : dist;
  }
}
