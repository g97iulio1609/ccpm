import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercise.series.length,
      itemBuilder: (context, index) {
        final series = exercise.series[index];
        return _buildSeriesCard(context, series, index);
      },
    );
  }

  Widget _buildSeriesCard(BuildContext context, Series series, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          'Series: Sets ${series.sets} x Reps ${series.reps} x ${series.weight} Kg',
          style: Theme.of(context).textTheme.bodyLarge,
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
      ),
    );
  }
}