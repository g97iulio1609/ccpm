import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/Viewer/UI/widgets/workout_formatters.dart';

class MetaChips extends StatelessWidget {
  final Exercise exercise;
  const MetaChips({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final isCardio = exercise.type.toLowerCase() == 'cardio';
    final isBodyweight = exercise.isBodyweight == true;
    final isHiit = isCardio && exercise.series.any((s) => s.cardioType == 'hiit');
    
    final reps = exercise.series.isNotEmpty ? exercise.series.first.reps : null;
    final weight = exercise.series.isNotEmpty ? exercise.series.first.weight : null;
    final rest = exercise.series
        .firstWhere((s) => s.restTimeSeconds != null, orElse: () => exercise.series.first)
        .restTimeSeconds;

    List<Widget> chips = [
      _chip(context, Icons.layers_outlined, '${exercise.series.length} serie'),
    ];

    if (isHiit) {
      // HIIT specific chips
      chips.add(_chip(context, Icons.flash_on, 'HIIT'));
      final firstHiitSeries = exercise.series.firstWhere((s) => s.cardioType == 'hiit', orElse: () => exercise.series.first);
      
      if (firstHiitSeries.workIntervalSeconds != null && firstHiitSeries.workIntervalSeconds! > 0) {
        chips.add(_chip(context, Icons.play_arrow, '${firstHiitSeries.workIntervalSeconds}s lavoro'));
      }
      if (firstHiitSeries.restIntervalSeconds != null && firstHiitSeries.restIntervalSeconds! > 0) {
        chips.add(_chip(context, Icons.pause, '${firstHiitSeries.restIntervalSeconds}s riposo'));
      }
      if (firstHiitSeries.rounds != null && firstHiitSeries.rounds! > 0) {
        chips.add(_chip(context, Icons.repeat, '${firstHiitSeries.rounds} round'));
      }
    } else if (isCardio) {
      // Standard cardio chips
      chips.add(_chip(context, Icons.directions_run, 'Cardio'));
    } else {
      // Weight training chips
      if (reps != null) chips.add(_chip(context, Icons.repeat, 'x$reps'));
      if (weight != null && !isBodyweight) {
        chips.add(_chip(context, Icons.fitness_center, WorkoutFormatters.formatWeight(weight)));
      }
    }

    if (rest != null) {
      chips.add(_chip(context, Icons.timer_outlined, WorkoutFormatters.formatRest(rest)));
    }

    return Wrap(
      spacing: AppTheme.spacing.xs,
      runSpacing: AppTheme.spacing.xs,
      children: chips,
    );
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
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
