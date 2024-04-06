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
    final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex]
        .exercises[exerciseIndex];
    final groupedSeries = _groupSeries(exercise.series);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedSeries.length,
      itemBuilder: (context, index) {
        final item = groupedSeries[index];
        if (item is List<Series>) {
          return _buildSeriesGroupCard(context, item, index);
        } else {
          return _buildSeriesCard(context, item as Series, index);
        }
      },
    );
  }

  List<dynamic> _groupSeries(List<Series> series) {
    final groupedSeries = <dynamic>[];
    for (final s in series) {
      final existingGroup = groupedSeries.firstWhere(
        (item) =>
            item is List<Series> &&
            item.first.reps == s.reps &&
            item.first.weight == s.weight,
        orElse: () => null,
      );
      if (existingGroup != null) {
        existingGroup.add(s);
      } else {
        groupedSeries.add([s]);
      }
    }
    return groupedSeries
        .map((item) => item.length == 1 ? item.first : item)
        .toList();
  }

  Widget _buildSeriesGroupCard(
    BuildContext context, List<Series> seriesGroup, int groupIndex) {
  final series = seriesGroup.first;
  return GestureDetector(
    onTap: () => _showSeriesDialog(context, seriesGroup, groupIndex),
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          '${seriesGroup.length} serie${seriesGroup.length > 1 ? 's' : ''}, ${series.reps} reps x ${series.weight} kg',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Edit All'),
              onTap: () => _showEditAllSeriesDialog(context, seriesGroup),
            ),
            PopupMenuItem(
              child: const Text('Delete'),
              onTap: () =>
                  _showDeleteSeriesGroupDialog(context, seriesGroup, groupIndex),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showDeleteSeriesGroupDialog(
      BuildContext context, List<Series> seriesGroup, int groupIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Series Group'),
        content: const Text('Are you sure you want to delete this series group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteSeriesGroup(seriesGroup, groupIndex);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

void _deleteSeriesGroup(List<Series> seriesGroup, int groupIndex) {
  final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex]
      .exercises[exerciseIndex];

  // Crea una copia delle serie da eliminare
  List<Series> seriesToRemove = List.from(seriesGroup);

  // Aggiungi gli ID delle serie da eliminare a trackToDeleteSeries
  for (Series series in seriesToRemove) {
    if (series.serieId != null) {
      controller.program.trackToDeleteSeries.add(series.serieId!);
    }
  }

  // Rimuovi le serie dall'elenco delle serie dell'esercizio
  exercise.series.removeWhere((series) => seriesToRemove.contains(series));

  // Aggiorna gli ordini delle serie rimanenti
  for (int i = 0; i < exercise.series.length; i++) {
    exercise.series[i].order = i + 1;
  }

  // Notifica il controller delle modifiche
  controller.notifyListeners();
}

  void _showSeriesDialog(
      BuildContext context, List<Series> seriesGroup, int groupIndex) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Series Group'),
            content: SingleChildScrollView(
              child: ListBody(
                children: seriesGroup.asMap().entries.map((entry) {
                  final seriesIndex = entry.key;
                  final series = entry.value;
                  return _buildSeriesCard(
                      context, series, groupIndex, seriesIndex, () {
                    setState(() =>
                        _removeSeries(seriesGroup, groupIndex, seriesIndex));
                  });
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    ).then((_) => controller.notifyListeners());
  }

  void _showEditAllSeriesDialog(
    BuildContext context, List<Series> seriesGroup) async {
  final series = seriesGroup.first;
  final repsController = TextEditingController(text: series.reps.toString());
  final weightController =
      TextEditingController(text: series.weight.toString());

  final result = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit All Series'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: repsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Reps'),
          ),
          TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (result == true) {
    final reps = int.parse(repsController.text);
    final weight = double.parse(weightController.text);

    for (final s in seriesGroup) {
      s.reps = reps;
      s.weight = weight;
    }

    controller.updateSeries(
        weekIndex, workoutIndex, exerciseIndex, seriesGroup);
  }
}

  void _removeSeries(
      List<Series> seriesGroup, int groupIndex, int seriesIndex) {
    final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex]
        .exercises[exerciseIndex];
    final series = seriesGroup[seriesIndex];
    exercise.series.remove(series);
  }

  Widget _buildSeriesCard(BuildContext context, Series series,
      [int? groupIndex, int? seriesIndex, VoidCallback? onRemove]) {
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
                weekIndex, workoutIndex, exerciseIndex, series, context),
          ),
          PopupMenuItem(
            child: const Text('Delete'),
            onTap: () {
              if (onRemove != null) {
                onRemove();
              } else {
                controller.removeSeries(weekIndex, workoutIndex, exerciseIndex,
                    groupIndex ?? 0, seriesIndex ?? 0);
              }
            },
          ),
        ],
      ),
    );
  }
}