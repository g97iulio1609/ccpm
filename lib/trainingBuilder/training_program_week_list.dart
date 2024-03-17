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
    final sortedWeeks = program.weeks..sort((a, b) => a.number.compareTo(b.number));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7, // Imposta l'altezza massima al 70% dell'altezza dello schermo
      ),
      child: ReorderableListView.builder(
        onReorder: (oldIndex, newIndex) {
          controller.reorderWeeks(oldIndex, newIndex);
        },
        itemCount: sortedWeeks.length,
        itemBuilder: (context, index) {
          final week = sortedWeeks[index];
          return ExpansionTile(
            key: ValueKey(week.id),
            title: Text('Week ${week.number}'),
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
        },
      ),
    );
  }
}