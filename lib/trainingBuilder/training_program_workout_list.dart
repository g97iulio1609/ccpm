import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
import 'training_program_controller.dart';
import 'reorder_dialog.dart';

class TrainingProgramWorkoutListPage extends StatefulWidget {
  final TrainingProgramController controller;
  final int weekIndex;

  const TrainingProgramWorkoutListPage({
    required this.controller,
    required this.weekIndex,
    super.key,
  });

  @override
  State<TrainingProgramWorkoutListPage> createState() =>
      _TrainingProgramWorkoutListPageState();
}

class _TrainingProgramWorkoutListPageState
    extends State<TrainingProgramWorkoutListPage> {
  @override
  Widget build(BuildContext context) {
    final week = widget.controller.program.weeks[widget.weekIndex];
    final workouts = week.workouts;

    return Scaffold(
      body: ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return _buildWorkoutCard(context, workout);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.controller.addWorkout(widget.weekIndex),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          'Workout ${workout.order}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () => widget.controller.removeWorkout(
                  widget.weekIndex, workout.order),
            ),
            PopupMenuItem(
              child: const Text('Copy Workout'),
              onTap: () => widget.controller.copyWorkout(
                  widget.weekIndex, workout.order - 1, context),
            ),
            PopupMenuItem(
              child: const Text('Reorder Workouts'),
              onTap: () => _showReorderWorkoutsDialog(context),
            ),
          ],
        ),
        onTap: () {
          context.go(
              '/programs_screen/user_programs/${widget.controller.program.athleteId}/training_program/${widget.controller.program.id}/week/${widget.weekIndex}/workout/${workout.order - 1}');
        },
      ),
    );
  }

  void _showReorderWorkoutsDialog(BuildContext context) {
    final workoutNames = widget.controller.program.weeks[widget.weekIndex]
        .workouts
        .map((workout) => 'Workout ${workout.order}')
        .toList();

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: workoutNames,
        onReorder: (oldIndex, newIndex) => widget.controller
            .reorderWorkouts(widget.weekIndex, oldIndex, newIndex),
      ),
    );
  }
}