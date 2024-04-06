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

    return ResponsiveGridView(
      items: exercises,
      itemBuilder: (context, index, exercise) => _buildExerciseCard(context, exercise, usersService, athleteId, dateFormat),
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
          Flexible(
            child: ListTile(
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
                  PopupMenuItem(
                    child: const Text('Reorder Exercises'),
                    onTap: () => _showReorderExercisesDialog(context, weekIndex, workoutIndex),
                  ),
                ],
              ),
            ),
          ),
          Flexible(
            child: TrainingProgramSeriesList(
              controller: controller,
              usersService: usersService, // Pass the usersService here
              weekIndex: weekIndex,
              workoutIndex: workoutIndex,
              exerciseIndex: exercise.order - 1,
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () => controller.addSeries(weekIndex, workoutIndex, exercise.order - 1, context),
                child: const Text('Add New Series'),
              ),
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

class ResponsiveGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, int index, T item) itemBuilder;

  const ResponsiveGridView({
    required this.items,
    required this.itemBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = _getCrossAxisCount(width);
        final childAspectRatio = _getChildAspectRatio(width);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(context, index, items[index]),
        );
      },
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) {
      return 3;
    } else if (width > 800) {
      return 3;
    } else if (width > 600) {
      return 2;
    } else {
      return 1;
    }
  }

  double _getChildAspectRatio(double width) {
    if (width > 1200) {
      return 1.2;
    } else if (width > 800) {
      return 1.1;
    } else if (width > 600) {
      return 1.0;
    } else {
      return 0.9;
    }
  }
}