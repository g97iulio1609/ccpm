import 'package:alphanessone/trainingBuilder/training_model.dart';
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedWeeks.length,
      itemBuilder: (context, index) {
        final week = sortedWeeks[index];
        return _buildWeekCard(context, week, index);
      },
    );
  }

  Widget _buildWeekCard(BuildContext context, Week week, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text(
          'Week ${week.number}',
          style: Theme.of(context).textTheme.titleLarge,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => controller.addWorkout(index),
              child: const Text('Add New Workout'),
            ),
          ),
        ],
      ),
    );
  }
}