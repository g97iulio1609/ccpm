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

    // Ordina gli esercizi in base al campo 'order'
    final sortedExercises = workout.exercises.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      children: [
        for (int i = 0; i < sortedExercises.length; i++)
          ExpansionTile(
            title: Text('Exercise ${sortedExercises[i].order}: ${sortedExercises[i].name} ${sortedExercises[i].variant}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => controller.editExercise(weekIndex, workoutIndex, sortedExercises[i].order - 1, context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => controller.removeExercise(weekIndex, workoutIndex, sortedExercises[i].order - 1),
                ),
              ],
            ),
            children: [
              TrainingProgramSeriesList(
                controller: controller,
                weekIndex: weekIndex,
                workoutIndex: workoutIndex,
                exerciseIndex: sortedExercises[i].order - 1,
              ),
              ElevatedButton(
                onPressed: () => controller.addSeries(weekIndex, workoutIndex, sortedExercises[i].order - 1, context),
                child: const Text('Add New Series'),
              ),
            ],
          ),
      ],
    );
  }
}