import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'training_model.dart';
import 'training_program_controller.dart';
import 'training_program_series_list.dart';
import '../users_services.dart';
import 'reorder_dialog.dart';

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
    final exercises = workout.exercises;
    final usersService = ref.watch(usersServiceProvider);
    final athleteId = controller.athleteIdController.text;
    final dateFormat = DateFormat('yyyy-MM-dd');

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      itemBuilder: (context, index) =>
          _buildExerciseCard(context, exercises[index], usersService, athleteId, dateFormat),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExerciseHeader(context, exercise, usersService, athleteId, dateFormat),
            const SizedBox(height: 16),
            _buildExerciseSeries(context, exercise, usersService),
            const SizedBox(height: 16),
            _buildAddSeriesButton(context, exercise),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseHeader(
    BuildContext context,
    Exercise exercise,
    UsersService usersService,
    String athleteId,
    DateFormat dateFormat,
  ) {
    return ListTile(
      title: Text(
        exercise.name,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(exercise.variant),
      trailing: _buildExercisePopupMenu(context, exercise, usersService, athleteId, dateFormat),
    );
  }

  PopupMenuButton _buildExercisePopupMenu(
    BuildContext context,
    Exercise exercise,
    UsersService usersService,
    String athleteId,
    DateFormat dateFormat,
  ) {
    return PopupMenuButton(
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
        PopupMenuItem(
          child: const Text('Reorder Exercises'),
          onTap: () => _showReorderExercisesDialog(context, weekIndex, workoutIndex),
        ),
      ],
    );
  }

  Widget _buildExerciseSeries(BuildContext context, Exercise exercise, UsersService usersService) {
    return TrainingProgramSeriesList(
      controller: controller,
      usersService: usersService,
      weekIndex: weekIndex,
      workoutIndex: workoutIndex,
      exerciseIndex: exercise.order - 1,
    );
  }

  Widget _buildAddSeriesButton(BuildContext context, Exercise exercise) {
    return ElevatedButton(
      onPressed: () => controller.addSeries(weekIndex, workoutIndex, exercise.order - 1, context),
      child: const Text('Add New Series'),
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
          content: _buildMaxRMInputFields(maxWeightController, repetitionsController),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _saveMaxRM(
                  record,
                  athleteId,
                  exercise,
                  maxWeightController,
                  repetitionsController,
                  usersService,
                  dateFormat,
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaxRMInputFields(
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
  ) {
    return Column(
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
    );
  }

  Future<void> _saveMaxRM(
    ExerciseRecord? record,
    String athleteId,
    Exercise exercise,
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
    UsersService usersService,
    DateFormat dateFormat,
  ) async {
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
  }

  void _showReorderExercisesDialog(BuildContext context, int weekIndex, int workoutIndex) {
    final exerciseNames = controller.program.weeks[weekIndex].workouts[workoutIndex].exercises.map((exercise) => exercise.name).toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: exerciseNames,
        onReorder: (oldIndex, newIndex) => controller.reorderExercises(weekIndex, workoutIndex, oldIndex, newIndex),
      ),
    );
  }
}