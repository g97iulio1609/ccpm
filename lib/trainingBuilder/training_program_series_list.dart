import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'trainingModel.dart';
import 'training_program_controller.dart';

class TrainingProgramSeriesList extends ConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;
  final int exerciseIndex;

  const TrainingProgramSeriesList({
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    required this.exerciseIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: ReorderableListView.builder(
        onReorder: (oldIndex, newIndex) => controller.reorderSeries(weekIndex, workoutIndex, exerciseIndex, oldIndex, newIndex),
        itemCount: exercise.series.length,
        itemBuilder: (context, index) {
          final series = exercise.series[index];
          return _buildSeriesTile(context, series, index);
        },
      ),
    );
  }

  Widget _buildSeriesTile(BuildContext context, Series series, int index) {
    return ListTile(
      key: UniqueKey(),
      title: Text(
        'Series: Sets ${series.sets} x Reps ${series.reps} x ${series.weight} Kg',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => controller.editSeries(weekIndex, workoutIndex, exerciseIndex, index, context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => controller.removeSeries(weekIndex, workoutIndex, exerciseIndex, index),
          ),
        ],
      ),
    );
  }
}