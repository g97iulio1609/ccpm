import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';
import 'training_program_series_list.dart';

class TrainingProgramExerciseList extends ConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;

  const TrainingProgramExerciseList({
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];

    return Column(
      children: [
        for (int i = 0; i < workout.exercises.length; i++)
          ExpansionTile(
            title: Text('Exercise ${workout.exercises[i].order}: ${workout.exercises[i].name} ${workout.exercises[i].variant}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => controller.editExercise(weekIndex, workoutIndex, i, context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => controller.removeExercise(weekIndex, workoutIndex, i),
                ),
              ],
            ),
            children: [
              TrainingProgramSeriesList(
                controller: controller,
                weekIndex: weekIndex,
                workoutIndex: workoutIndex,
                exerciseIndex: i,
              ),
              ElevatedButton(
                onPressed: () => controller.addSeries(weekIndex, workoutIndex, i, context),
                child: const Text('Add New Series'),
              ),
            ],
          ),
      ],
    );
  }
}