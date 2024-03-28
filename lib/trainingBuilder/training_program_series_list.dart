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
    final groupedSeries = _groupSeries(exercise.series);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedSeries.length,
      itemBuilder: (context, groupIndex) {
        final seriesGroup = groupedSeries[groupIndex];
        return _buildSeriesGroupCard(context, seriesGroup, groupIndex);
      },
    );
  }

  List<List<Series>> _groupSeries(List<Series> series) {
    final groupedSeries = <List<Series>>[];
    for (final s in series) {
      final existingGroup = groupedSeries.firstWhere(
        (group) => group.first.reps == s.reps && group.first.weight == s.weight,
        orElse: () => [],
      );
      if (existingGroup.isEmpty) {
        groupedSeries.add([s]);
      } else {
        existingGroup.add(s);
      }
    }
    return groupedSeries;
  }

  Widget _buildSeriesGroupCard(BuildContext context, List<Series> seriesGroup, int groupIndex) {
    final series = seriesGroup.first;
    return GestureDetector(
      onTap: () => _showSeriesGroupDialog(context, seriesGroup, groupIndex),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(
            '${seriesGroup.length} serie${seriesGroup.length > 1 ? 's' : ''}, ${series.reps} reps x ${series.weight} kg',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  void _showSeriesGroupDialog(BuildContext context, List<Series> seriesGroup, int groupIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Series Group'),
        content: SingleChildScrollView(
          child: ListBody(
            children: seriesGroup.asMap().entries.map((entry) {
              final seriesIndex = entry.key;
              final series = entry.value;
              return _buildSeriesCard(context, series, groupIndex, seriesIndex);
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

Widget _buildSeriesCard(BuildContext context, Series series, int groupIndex, int seriesIndex) {
  return ListTile(
    title: Text(
      '${series.reps} reps x ${series.weight} kg',
      style: Theme.of(context).textTheme.bodyLarge,
    ),
    trailing: PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Edit'),
          onTap: () => controller.editSeries(
            weekIndex,
            workoutIndex,
            exerciseIndex,
            series, // Pass the current series object
            context,
          ),
        ),
        PopupMenuItem(
          child: const Text('Delete'),
          onTap: () => controller.removeSeries(
            weekIndex,
            workoutIndex,
            exerciseIndex,
            groupIndex,
            seriesIndex,
          ),
        ),
      ],
    ),
  );
}}