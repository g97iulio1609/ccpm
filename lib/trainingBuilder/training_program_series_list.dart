import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';

class TrainingProgramSeriesList extends ConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;
  final int exerciseIndex;

  const TrainingProgramSeriesList({
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    required this.exerciseIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    return Column(
      children: [
        for (int i = 0; i < exercise.series.length; i++)
          ListTile(
            title: Text('Series: Sets ${exercise.series[i].sets} x Reps ${exercise.series[i].reps} x ${exercise.series[i].weight} Kg'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => controller.editSeries(weekIndex, workoutIndex, exerciseIndex, i, context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => controller.removeSeries(weekIndex, workoutIndex, exerciseIndex, i),
                ),
              ],
            ),
          ),
      ],
    );
  }
}