import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_model.dart';
import 'training_program_controller.dart';
import 'utility_functions.dart';
import '../users_services.dart';

class TrainingProgramSeriesList extends ConsumerWidget {
  final TrainingProgramController controller;
  final UsersService usersService;
  final int weekIndex;
  final int workoutIndex;
  final int exerciseIndex;

  const TrainingProgramSeriesList({
    required this.controller,
    required this.usersService,
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
      physics: NeverScrollableScrollPhysics(),
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
  for (int i = 0; i < series.length; i++) {
    final currentSeries = series[i];
    if (i == 0 || currentSeries.reps != series[i - 1].reps || currentSeries.weight != series[i - 1].weight) {
      groupedSeries.add([currentSeries]);
    } else {
      (groupedSeries.last as List<Series>).add(currentSeries);
    }
  }
  return groupedSeries.map((item) => item.length == 1 ? item.first : item).toList();
}

  Widget _buildSeriesGroupCard(
      BuildContext context, List<Series> seriesGroup, int groupIndex) {
    final series = seriesGroup.first;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              '${seriesGroup.length} serie${seriesGroup.length > 1 ? 's' : ''}, ${series.reps} reps x ${series.weight} kg',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: _buildSeriesGroupPopupMenu(context, seriesGroup, groupIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesGroupPopupMenu(
      BuildContext context, List<Series> seriesGroup, int groupIndex) {
    return PopupMenuButton(
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

  Widget _buildSeriesCard(BuildContext context, Series series,
      [int? groupIndex, int? seriesIndex, VoidCallback? onRemove]) {
    return ListTile(
      title: Text(
        '${series.reps} reps x ${series.weight} kg',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text('RPE: ${series.rpe}, Intensity: ${series.intensity}'),
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

void _showEditAllSeriesDialog(BuildContext context, List<Series> seriesGroup) async {
  final series = seriesGroup.first;
  final repsController = TextEditingController(text: series.reps.toString());
  final setsController = TextEditingController(text: seriesGroup.length.toString());
  final intensityController = TextEditingController(text: series.intensity);
  final rpeController = TextEditingController(text: series.rpe);
  final weightController = TextEditingController(text: series.weight.toString());

  FocusNode weightFocusNode = FocusNode();
  FocusNode intensityFocusNode = FocusNode();

  final result = await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Edit All Series'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: repsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps'),
                  onChanged: (_) {
                    _updateRPE(repsController, weightController, rpeController, intensityController, setState);
                  },
                ),
                TextField(
                  controller: setsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sets'),
                ),
                TextField(
                  controller: intensityController,
                  keyboardType: TextInputType.number,
                  focusNode: intensityFocusNode,
                  decoration: const InputDecoration(labelText: 'Intensity (%)'),
                  onChanged: (_) {
                    if (intensityFocusNode.hasFocus) {
                      _updateWeight(weightController, intensityController, setState);
                    }
                  },
                ),
                TextField(
                  controller: rpeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'RPE'),
                  onChanged: (_) {
                    _updateWeightAndIntensity(repsController, weightController, rpeController, intensityController, setState);
                  },
                ),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  focusNode: weightFocusNode,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  onChanged: (_) {
                    if (weightFocusNode.hasFocus) {
                      _updateIntensity(weightController, intensityController, setState);
                    }
                    _updateRPE(repsController, weightController, rpeController, intensityController, setState);
                  },
                ),
              ],
            ),
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
        );
      },
    ),
  );

  weightFocusNode.dispose();
  intensityFocusNode.dispose();

  if (result == true) {
    final reps = int.parse(repsController.text);
    final sets = int.parse(setsController.text);
    final intensity = intensityController.text;
    final rpe = rpeController.text;
    final weight = double.parse(weightController.text);

    // Update the series within the group
    for (int i = 0; i < seriesGroup.length; i++) {
      final s = seriesGroup[i];
      s.reps = reps;
      s.intensity = intensity;
      s.rpe = rpe;
      s.weight = weight;
    }

    // Add or remove series to match the new sets count
    final exercise = controller.program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final seriesIndex = exercise.series.indexOf(seriesGroup.first);
    if (sets > seriesGroup.length) {
      for (int i = seriesGroup.length; i < sets; i++) {
        final newSeries = Series(
          serieId: UniqueKey().toString(),
          reps: reps,
          sets: 1,
          intensity: intensity,
          rpe: rpe,
          weight: weight,
          order: series.order + i,
          done: false,
          reps_done: 0,
          weight_done: 0.0,
        );
        exercise.series.insert(seriesIndex + i, newSeries);
      }
    } else if (sets < seriesGroup.length) {
      for (int i = sets; i < seriesGroup.length; i++) {
        final removedSeries = exercise.series.removeAt(seriesIndex + sets);
        controller.program.trackToDeleteSeries.add(removedSeries.serieId!);
      }
    }

    controller.notifyListeners();
  }
}
  void _updateWeight(TextEditingController weightController,
      TextEditingController intensityController, StateSetter setState) async {
    final intensity = double.tryParse(intensityController.text) ?? 0;
    final latestMaxWeight = await getLatestMaxWeight(
        usersService,
        controller.athleteIdController.text,
        controller.program.weeks[weekIndex].workouts[workoutIndex]
            .exercises[exerciseIndex].exerciseId!);
    final calculatedWeight =
        calculateWeightFromIntensity(latestMaxWeight, intensity);
    final roundedWeight = roundWeight(
        calculatedWeight,
        controller.program.weeks[weekIndex].workouts[workoutIndex]
            .exercises[exerciseIndex].type);
    setState(() {
      weightController.text = roundedWeight.toStringAsFixed(2);
    });
  }

  void _updateIntensity(TextEditingController weightController,
      TextEditingController intensityController, StateSetter setState) async {
    final weight = double.tryParse(weightController.text) ?? 0;
    final latestMaxWeight = await getLatestMaxWeight(
        usersService,
        controller.athleteIdController.text,
        controller.program.weeks[weekIndex].workouts[workoutIndex]
            .exercises[exerciseIndex].exerciseId!);

    if (weight > 0 && latestMaxWeight > 0) {
      final calculatedIntensity =
          calculateIntensityFromWeight(weight, latestMaxWeight);
      setState(() {
        intensityController.text = calculatedIntensity.toStringAsFixed(2);
      });
    } else {
      setState(() {
        intensityController.clear();
      });
    }
  }

  void _updateWeightAndIntensity(
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController rpeController,
    TextEditingController intensityController,
    StateSetter setState,
  ) async {
    final rpeText = rpeController.text;
    if (rpeText.isNotEmpty) {
      final rpe = double.parse(rpeText);
      final reps = int.tryParse(repsController.text) ?? 0;
      final latestMaxWeight = await getLatestMaxWeight(
          usersService,
          controller.athleteIdController.text,
          controller.program.weeks[weekIndex].workouts[workoutIndex]
              .exercises[exerciseIndex].exerciseId!);
      final percentage = getRPEPercentage(rpe, reps);
      final calculatedWeight = latestMaxWeight * percentage;
      final roundedWeight = roundWeight(
          calculatedWeight,
          controller.program.weeks[weekIndex].workouts[workoutIndex]
              .exercises[exerciseIndex].type);

      setState(() {
        weightController.text = roundedWeight.toStringAsFixed(2);
        final calculatedIntensity =
            calculateIntensityFromWeight(roundedWeight, latestMaxWeight);
        intensityController.text = calculatedIntensity.toStringAsFixed(2);
      });
    }
  }

  void _updateRPE(
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController rpeController,
    TextEditingController intensityController,
    StateSetter setState,
  ) async {
    final weight = double.tryParse(weightController.text) ?? 0;
    final reps = int.tryParse(repsController.text) ?? 0;
    final latestMaxWeight = await getLatestMaxWeight(
        usersService,
        controller.athleteIdController.text,
        controller.program.weeks[weekIndex].workouts[workoutIndex]
            .exercises[exerciseIndex].exerciseId!);
    final calculatedRPE = calculateRPE(weight, latestMaxWeight, reps);

    if (calculatedRPE != null) {
      setState(() {
        rpeController.text = calculatedRPE.toStringAsFixed(1);
        final percentage = getRPEPercentage(calculatedRPE, reps);
        intensityController.text = (percentage * 100).toStringAsFixed(2);
      });
    } else {
      setState(() {
        rpeController.clear();
        intensityController.clear();
      });
    }
  }
}