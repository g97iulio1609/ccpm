import 'package:alphanessone/trainingBuilder/trainingModel.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';
import 'training_program_workout_list.dart';

class TrainingProgramWeekList extends ConsumerWidget {
  final TrainingProgramController controller;

  const TrainingProgramWeekList({required this.controller, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = controller.program;
    final sortedWeeks = program.weeks..sort((a, b) => a.number.compareTo(b.number));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: ReorderableListView.builder(
        onReorder: controller.reorderWeeks,
        itemCount: sortedWeeks.length,
        itemBuilder: (context, index) {
          final week = sortedWeeks[index];
          return _buildWeekTile(context, week, index);
        },
      ),
    );
  }

  Widget _buildWeekTile(BuildContext context, Week week, int index) {
    return ExpansionTile(
      key: ValueKey(week.id),
      title: Text(
        'Week ${week.number}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => controller.removeWeek(index),
      ),
      children: [
        TrainingProgramWorkoutList(
          controller: controller,
          weekIndex: index,
        ),
        ElevatedButton(
          onPressed: () => controller.addWorkout(index),
          child: const Text('Add New Workout'),
        ),
      ],
    );
  }
}