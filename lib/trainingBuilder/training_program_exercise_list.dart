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
    final sortedExercises = workout.exercises.toList()..sort((a, b) => a.order.compareTo(b.order));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5, // Imposta l'altezza massima al 50% dell'altezza dello schermo
      ),
      child: ReorderableListView.builder(
        onReorder: (oldIndex, newIndex) {
          controller.reorderExercises(weekIndex, workoutIndex, oldIndex, newIndex);
        },
        itemCount: sortedExercises.length,
        itemBuilder: (context, index) {
          final exercise = sortedExercises[index];
          return ExpansionTile(
            key: ValueKey(exercise.id),
            title: Text('Exercise ${exercise.order}: ${exercise.name} ${exercise.variant}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => controller.editExercise(weekIndex, workoutIndex, exercise.order - 1, context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => controller.removeExercise(weekIndex, workoutIndex, exercise.order - 1),
                ),
              ],
            ),
            children: [
              TrainingProgramSeriesList(
                controller: controller,
                weekIndex: weekIndex,
                workoutIndex: workoutIndex,
                exerciseIndex: exercise.order - 1,
              ),
              ElevatedButton(
                onPressed: () => controller.addSeries(weekIndex, workoutIndex, exercise.order - 1, context),
                child: const Text('Add New Series'),
              ),
            ],
          );
        },
      ),
    );
  }
}