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

    return Column(
      children: [
        for (int i = 0; i < week.workouts.length; i++)
          ExpansionTile(
            title: Text('Workout ${week.workouts[i].order}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => controller.removeWorkout(weekIndex, i),
            ),
            children: [
              TrainingProgramExerciseList(
                controller: controller,
                weekIndex: weekIndex,
                workoutIndex: i,
              ),
              ElevatedButton(
                onPressed: () => controller.addExercise(weekIndex, i, context),
                child: const Text('Add New Exercise'),
              ),
            ],
          ),
      ],
    );
  }
}