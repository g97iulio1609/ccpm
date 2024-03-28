import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'training_model.dart';
import 'training_program_controller.dart';
import 'training_program_series_list.dart';
import '../users_services.dart';

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
    final usersService = ref.watch(usersServiceProvider);
    final athleteId = controller.athleteIdController.text;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedExercises.length,
      itemBuilder: (context, index) {
        final exercise = sortedExercises[index];
        return _buildExerciseCard(context, exercise, usersService, athleteId, dateFormat);
      },
    );
  }

  Widget _buildExerciseCard(
      BuildContext context,
      Exercise exercise,
      UsersService usersService,
      String athleteId,
      DateFormat dateFormat,
      ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              '${exercise.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(exercise.variant),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Edit'),
                  onTap: () => controller.editExercise(weekIndex, workoutIndex, exercise.order - 1, context),
                ),
                PopupMenuItem(
                  child: const Text('Delete'),
                  onTap: () => controller.removeExercise(weekIndex, workoutIndex, exercise.order - 1),
                ),
                PopupMenuItem(
                  child: const Text('Update Max RM'),
                  onTap: () => _addOrUpdateMaxRM(exercise, context, usersService, athleteId, dateFormat),
                ),
              ],
            ),
          ),
          TrainingProgramSeriesList(
            controller: controller,
            weekIndex: weekIndex,
            workoutIndex: workoutIndex,
            exerciseIndex: exercise.order - 1,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () => controller.addSeries(weekIndex, workoutIndex, exercise.order - 1, context),
              child: const Text('Add New Series'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addOrUpdateMaxRM(
      Exercise exercise,
      BuildContext context,
      UsersService usersService,
      String athleteId,
      DateFormat dateFormat,
      ) async {
    final record = await usersService.getLatestExerciseRecord(userId: athleteId, exerciseId: exercise.exerciseId!);
    final maxWeightController = TextEditingController(text: record?.maxWeight.toString() ?? '');
    final repetitionsController = TextEditingController(text: record?.repetitions.toString() ?? '');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Max RM'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: maxWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Weight'),
              ),
              TextField(
                controller: repetitionsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Repetitions'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final maxWeight = int.tryParse(maxWeightController.text) ?? 0;
                final repetitions = int.tryParse(repetitionsController.text) ?? 0;

                if (record != null) {
                  await usersService.updateExerciseRecord(
                    userId: athleteId,
                    exerciseId: exercise.exerciseId!,
                    recordId: record.id,
                    maxWeight: maxWeight,
                    repetitions: repetitions,
                  );
                } else {
                  await usersService.addExerciseRecord(
                    userId: athleteId,
                    exerciseId: exercise.exerciseId!,
                    exerciseName: exercise.name,
                    maxWeight: maxWeight,
                    repetitions: repetitions,
                    date: dateFormat.format(DateTime.now()),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}