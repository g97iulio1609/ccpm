import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'trainingModel.dart';
import 'training_program_controller.dart';
import 'training_program_series_list.dart';
import '../usersServices.dart';

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

    Future<void> addOrUpdateMaxRM(Exercise exercise, BuildContext context) async {
      final record = await usersService.getLatestExerciseRecord(userId: athleteId, exerciseId: exercise.exerciseId!);
      final maxWeightController = TextEditingController(text: record?.maxWeight.toString() ?? '');
      final repetitionsController = TextEditingController(text: record?.repetitions.toString() ?? '');

      showDialog(
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

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ReorderableListView.builder(
        onReorder: (oldIndex, newIndex) => controller.reorderExercises(weekIndex, workoutIndex, oldIndex, newIndex),
        itemCount: sortedExercises.length,
        itemBuilder: (context, index) {
          final exercise = sortedExercises[index];
          return _buildExerciseTile(context, exercise, index, addOrUpdateMaxRM);
        },
      ),
    );
  }

  Widget _buildExerciseTile(
    BuildContext context,
    Exercise exercise,
    int index,
    Function(Exercise, BuildContext) addOrUpdateMaxRM,
  ) {
    return ExpansionTile(
      key: ValueKey(exercise.id),
      title: Text(
        'Exercise ${exercise.order}: ${exercise.name} ${exercise.variant}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
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
          IconButton(
            icon: const Icon(Icons.fitness_center),
            onPressed: () => addOrUpdateMaxRM(exercise, context),
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
  }
}