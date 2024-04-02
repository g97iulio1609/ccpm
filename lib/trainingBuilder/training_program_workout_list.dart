import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
import 'training_program_controller.dart';
import 'training_program_exercise_list.dart';
import 'reorder_dialog.dart';

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
    final workouts = week.workouts;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _buildWorkoutCard(context, workout);
      },
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text(
          'Workout ${workout.order}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () => controller.removeWorkout(weekIndex, workout.order),
            ),
            PopupMenuItem(
              child: const Text('Copy Workout'),
              onTap: () => controller.copyWorkout(weekIndex, workout.order - 1, context),
            ),
            PopupMenuItem(
              child: const Text('Reorder Workouts'),
              onTap: () => _showReorderWorkoutsDialog(context, weekIndex),
            ),
          ],
        ),
        children: [
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

  void _showReorderWorkoutsDialog(BuildContext context, int weekIndex) {
    final workoutNames = controller.program.weeks[weekIndex].workouts.map((workout) => 'Workout ${workout.order}').toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: workoutNames,
        onReorder: (oldIndex, newIndex) => controller.reorderWorkouts(weekIndex, oldIndex, newIndex),
      ),
    );
  }
}