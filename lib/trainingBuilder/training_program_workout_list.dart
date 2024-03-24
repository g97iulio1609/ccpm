import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
import 'training_program_controller.dart';
import 'training_program_exercise_list.dart';

class TrainingProgramWorkoutList extends ConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;

  const TrainingProgramWorkoutList({
    required this.controller,
    required this.weekIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = controller.program.weeks[weekIndex];
    final sortedWorkouts = week.workouts.toList()..sort((a, b) => a.order.compareTo(b.order));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedWorkouts.length,
      itemBuilder: (context, index) {
        final workout = sortedWorkouts[index];
        return _buildWorkoutCard(context, workout, index);
      },
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout, int index) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'Workout ${workout.order}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => controller.removeWorkout(weekIndex, workout.order - 1),
            ),
          ),
          TrainingProgramExerciseList(
            controller: controller,
            weekIndex: weekIndex,
            workoutIndex: workout.order - 1,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => controller.addExercise(weekIndex, workout.order - 1, context),
              child: const Text('Add New Exercise'),
            ),
          ),
        ],
      ),
    );
  }
}