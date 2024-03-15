import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';
import 'training_program_exercise_list.dart';

class TrainingProgramWorkoutList extends ConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;

  const TrainingProgramWorkoutList({
    required this.controller,
    required this.weekIndex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = controller.program.weeks[weekIndex];

    // Ordina i workouts in base al campo 'order'
    final sortedWorkouts = week.workouts.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      children: [
        for (int i = 0; i < sortedWorkouts.length; i++)
          ExpansionTile(
            title: Text('Workout ${sortedWorkouts[i].order}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => controller.removeWorkout(weekIndex, sortedWorkouts[i].order - 1),
            ),
            children: [
              TrainingProgramExerciseList(
                controller: controller,
                weekIndex: weekIndex,
                workoutIndex: sortedWorkouts[i].order - 1,
              ),
              ElevatedButton(
                onPressed: () => controller.addExercise(weekIndex, sortedWorkouts[i].order - 1, context),
                child: const Text('Add New Exercise'),
              ),
            ],
          ),
      ],
    );
  }
}