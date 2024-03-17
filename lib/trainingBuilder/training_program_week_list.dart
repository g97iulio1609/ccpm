import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';
import 'training_program_workout_list.dart';

class TrainingProgramWeekList extends ConsumerWidget {
  final TrainingProgramController controller;

  const TrainingProgramWeekList({required this.controller, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = controller.program;

    // Ordina le settimane in base al valore di 'number'
    final sortedWeeks = program.weeks..sort((a, b) => a.number.compareTo(b.number));

    return Column(
      children: [
        for (int i = 0; i < sortedWeeks.length; i++)
          ExpansionTile(
            title: Text('Week ${sortedWeeks[i].number}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => controller.removeWeek(i),
            ),
            children: [
              TrainingProgramWorkoutList(
                controller: controller,
                weekIndex: i,
              ),
              ElevatedButton(
                onPressed: () => controller.addWorkout(i),
                child: const Text('Add New Workout'),
              ),
            ],
          ),
      ],
    );
  }
}