import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

class StartExerciseButton extends StatelessWidget {
  final Exercise exercise;
  final int startIndex;
  final bool isContinue;
  final void Function(Series series, Exercise exercise) onStart;
  const StartExerciseButton({
    super.key,
    required this.exercise,
    required this.startIndex,
    required this.isContinue,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FilledButton.icon(
      onPressed: () => onStart(exercise.series[startIndex], exercise),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
      ),
      icon: Icon(
        isContinue ? Icons.play_arrow : Icons.fitness_center,
        color: colorScheme.onPrimary,
      ),
      label: Text(
        isContinue ? 'Continua (Serie ${startIndex + 1})' : 'Inizia Allenamento',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class StartSuperSetButton extends StatelessWidget {
  final List<Exercise> exercises;
  final void Function(Series series, Exercise exercise) onStart;
  const StartSuperSetButton({super.key, required this.exercises, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Exercise? firstExercise;
    int startSeriesIndex = 0;
    for (final exercise in exercises) {
      for (int i = 0; i < exercise.series.length; i++) {
        if (!exercise.series[i].isCompleted) {
          firstExercise = exercise;
          startSeriesIndex = i;
          break;
        }
      }
      if (firstExercise != null) break;
    }
    if (firstExercise == null) return const SizedBox.shrink();

    final isContinueMode = exercises.any((e) => e.series.any((s) => s.isCompleted));

    return FilledButton.icon(
      onPressed: () => onStart(firstExercise!.series[startSeriesIndex], firstExercise),
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
      ),
      icon: Icon(
        isContinueMode ? Icons.play_arrow : Icons.fitness_center,
        color: colorScheme.onPrimary,
      ),
      label: Text(
        isContinueMode ? 'Continua Super Set (Serie ${startSeriesIndex + 1})' : 'Inizia Super Set',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
