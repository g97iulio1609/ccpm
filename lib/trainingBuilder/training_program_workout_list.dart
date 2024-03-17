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
    final sortedWorkouts = week.workouts.toList()..sort((a, b) => a.order.compareTo(b.order));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5, // Imposta l'altezza massima al 50% dell'altezza dello schermo
      ),
      child: ReorderableListView.builder(
        onReorder: (oldIndex, newIndex) {
          controller.reorderWorkouts(weekIndex, oldIndex, newIndex);
        },
        itemCount: sortedWorkouts.length,
        itemBuilder: (context, index) {
          final workout = sortedWorkouts[index];
          return ExpansionTile(
            key: ValueKey(workout.id),
            title: Text('Workout ${workout.order}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => controller.removeWorkout(weekIndex, workout.order - 1),
            ),
            children: [
              TrainingProgramExerciseList(
                controller: controller,
                weekIndex: weekIndex,
                workoutIndex: workout.order - 1,
              ),
              ElevatedButton(
                onPressed: () => controller.addExercise(weekIndex, workout.order - 1, context),
                child: const Text('Add New Exercise'),
              ),
            ],
          );
        },
      ),
    );
  }
}