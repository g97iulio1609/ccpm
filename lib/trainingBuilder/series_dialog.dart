import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'trainingModel.dart';
import '../usersServices.dart';
import 'training_program_controller.dart';

class SeriesDialog extends ConsumerWidget {
  final UsersService usersService;
  final String athleteId;
  final String exerciseId;
  final int weekIndex;
  final Exercise exercise;
  final Series? series;

  const SeriesDialog({
    required this.usersService,
    required this.athleteId,
    required this.exerciseId,
    required this.weekIndex,
    required this.exercise,
    this.series,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(trainingProgramControllerProvider);

    final repsController = TextEditingController(text: series?.reps.toString() ?? '');
    final setsController = TextEditingController(text: series?.sets.toString() ?? '');
    final intensityController = TextEditingController(text: series?.intensity ?? '');
    final rpeController = TextEditingController(text: series?.rpe ?? '');
    final weightController = TextEditingController(text: series?.weight.toStringAsFixed(2) ?? '');
    int latestMaxWeight = 0;
    final intensityFocusNode = FocusNode();
    final weightFocusNode = FocusNode();
    final rpeFocusNode = FocusNode();

    // Retrieve the WeekProgression for the current week
    final weekProgression = exercise.weekProgressions
        .firstWhere((progression) => progression.weekNumber == weekIndex + 1, orElse: () => WeekProgression(weekNumber: weekIndex + 1, reps: 0, sets: 0, intensity: '', rpe: '', weight: 0));

    // Set the initial values of the form fields based on the WeekProgression
    repsController.text = weekProgression.reps.toString();
    setsController.text = weekProgression.sets.toString();
    intensityController.text = weekProgression.intensity;
    rpeController.text = weekProgression.rpe;
    weightController.text = weekProgression.weight.toStringAsFixed(2);

    usersService.getExerciseRecords(userId: athleteId, exerciseId: exerciseId).first.then((records) {
      if (records.isNotEmpty && exerciseId.isNotEmpty) {
        final latestRecord = records.first;
        latestMaxWeight = latestRecord.maxWeight;
      }
    }).catchError((error) {
      // Handle error
    });

    void updateWeight() {
      final intensity = double.tryParse(intensityController.text) ?? 0;
      final calculatedWeight = (latestMaxWeight * intensity) / 100;
      weightController.text = calculatedWeight.toStringAsFixed(2);
    }

    void updateIntensity() {
      final weight = double.tryParse(weightController.text) ?? 0;
      final calculatedIntensity = (weight / latestMaxWeight) * 100;
      intensityController.text = calculatedIntensity.toStringAsFixed(2);
    }

    void updateWeightFromRPE() {
      final rpe = double.tryParse(rpeController.text) ?? 0;
      final reps = int.tryParse(repsController.text) ?? 0;

      // Tabella powerlifting di Mike Tuchscherer estesa fino a 10 reps
      final rpeTable = {
        10.0: {1: 1.0, 2: 0.955, 3: 0.922, 4: 0.892, 5: 0.863, 6: 0.837, 7: 0.811, 8: 0.786, 9: 0.762, 10: 0.739},
        9.5: {1: 0.978, 2: 0.939, 3: 0.907, 4: 0.878, 5: 0.850, 6: 0.824, 7: 0.799, 8: 0.774, 9: 0.751, 10: 0.728},
        9.0: {1: 0.955, 2: 0.922, 3: 0.892, 4: 0.863, 5: 0.837, 6: 0.811, 7: 0.786, 8: 0.762, 9: 0.739, 10: 0.717},
        8.5: {1: 0.939, 2: 0.907, 3: 0.878, 4: 0.850, 5: 0.824, 6: 0.799, 7: 0.774, 8: 0.751, 9: 0.728, 10: 0.706},
        8.0: {1: 0.922, 2: 0.892, 3: 0.863, 4: 0.837, 5: 0.811, 6: 0.786, 7: 0.762, 8: 0.739, 9: 0.717, 10: 0.696},
        7.5: {1: 0.907, 2: 0.878, 3: 0.850, 4: 0.824, 5: 0.799, 6: 0.774, 7: 0.751, 8: 0.728, 9: 0.706, 10: 0.685},
        7.0: {1: 0.892, 2: 0.863, 3: 0.837, 4: 0.811, 5: 0.786, 6: 0.762, 7: 0.739, 8: 0.717, 9: 0.696, 10: 0.675},
        6.5: {1: 0.878, 2: 0.850, 3: 0.824, 4: 0.799, 5: 0.774, 6: 0.751, 7: 0.728, 8: 0.706, 9: 0.685, 10: 0.665},
        6.0: {1: 0.863, 2: 0.837, 3: 0.811, 4: 0.786, 5: 0.762, 6: 0.739, 7: 0.717, 8: 0.696, 9: 0.675, 10: 0.655},
      };

      final percentage = rpeTable[rpe]?[reps] ?? 1.0;
      final calculatedWeight = latestMaxWeight * percentage;

      weightController.text = calculatedWeight.toStringAsFixed(2);
      intensityController.text = (percentage * 100).toStringAsFixed(2);
    }

    void updateRPE() {
      final weight = double.tryParse(weightController.text) ?? 0;
      final reps = int.tryParse(repsController.text) ?? 0;
      final intensity = weight / latestMaxWeight;

      // Tabella powerlifting di Mike Tuchscherer estesa fino a 10 reps
      final rpeTable = {
        10.0: {1: 1.0, 2: 0.955, 3: 0.922, 4: 0.892, 5: 0.863, 6: 0.837, 7: 0.811, 8: 0.786, 9: 0.762, 10: 0.739},
        9.5: {1: 0.978, 2: 0.939, 3: 0.907, 4: 0.878, 5: 0.850, 6: 0.824, 7: 0.799, 8: 0.774, 9: 0.751, 10: 0.728},
        9.0: {1: 0.955, 2: 0.922, 3: 0.892, 4: 0.863, 5: 0.837, 6: 0.811, 7: 0.786, 8: 0.762, 9: 0.739, 10: 0.717},
        8.5: {1: 0.939, 2: 0.907, 3: 0.878, 4: 0.850, 5: 0.824, 6: 0.799, 7: 0.774, 8: 0.751, 9: 0.728, 10: 0.706},
        8.0: {1: 0.922, 2: 0.892, 3: 0.863, 4: 0.837, 5: 0.811, 6: 0.786, 7: 0.762, 8: 0.739, 9: 0.717, 10: 0.696},
        7.5: {1: 0.907, 2: 0.878, 3: 0.850, 4: 0.824, 5: 0.799, 6: 0.774, 7: 0.751, 8: 0.728, 9: 0.706, 10: 0.685},
        7.0: {1: 0.892, 2: 0.863, 3: 0.837, 4: 0.811, 5: 0.786, 6: 0.762, 7: 0.739, 8: 0.717, 9: 0.696, 10: 0.675},
        6.5: {1: 0.878, 2: 0.850, 3: 0.824, 4: 0.799, 5: 0.774, 6: 0.751, 7: 0.728, 8: 0.706, 9: 0.685, 10: 0.665},
        6.0: {1: 0.863, 2: 0.837, 3: 0.811, 4: 0.786, 5: 0.762, 6: 0.739, 7: 0.717, 8: 0.696, 9: 0.675, 10: 0.655},
      };

      double? calculatedRPE;
      rpeTable.forEach((rpe, repPercentages) {
        repPercentages.forEach((rep, percentage) {
          if ((intensity - percentage).abs() < 0.01 && rep == reps) {
            calculatedRPE = rpe;
          }
        });
      });

      if (calculatedRPE != null) {
        rpeController.text = calculatedRPE!.toStringAsFixed(1);
      } else {
        rpeController.text = '';
      }
    }

    intensityController.addListener(() {
      if (intensityFocusNode.hasFocus) {
        updateWeight();
      }
    });

    weightController.addListener(() {
      if (weightFocusNode.hasFocus) {
        updateIntensity();
        updateRPE();
      }
    });

    rpeController.addListener(() {
      if (rpeFocusNode.hasFocus) {
        updateWeightFromRPE();
      }
    });

    repsController.addListener(() {
      if (rpeFocusNode.hasFocus) {
        updateWeightFromRPE();
      } else {
        updateRPE();
      }
    });

    return AlertDialog(
      title: Text(series == null ? 'Add New Series' : 'Edit Series'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: setsController,
              decoration: const InputDecoration(labelText: 'Sets'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: intensityController,
              focusNode: intensityFocusNode,
              decoration: const InputDecoration(labelText: 'Intensity (%)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: rpeController,
              focusNode: rpeFocusNode,
              decoration: const InputDecoration(labelText: 'RPE'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: weightController,
              focusNode: weightFocusNode,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newSeries = Series(
              id: series?.id,
              serieId: series?.serieId ?? '',
              reps: int.parse(repsController.text),
              sets: int.parse(setsController.text),
              intensity: intensityController.text,
              rpe: rpeController.text,
              weight: double.parse(weightController.text),
              order: series?.order ?? 1,
              done: series?.done ?? false,
              reps_done: series?.reps_done ?? 0,
              weight_done: series?.weight_done ?? 0.0,
            );

            if (newSeries.serieId.isEmpty) {
              newSeries.serieId = '${DateTime.now().millisecondsSinceEpoch}_0';
            }

            final seriesList = [newSeries];
            final sets = int.parse(setsController.text);

            if (sets > 1) {
              for (int i = 1; i < sets; i++) {
                final baseId = DateTime.now().millisecondsSinceEpoch;
                final automatedSeriesId = '${baseId}_$i';
                final automatedSeries = Series(
                  serieId: automatedSeriesId,
                  reps: newSeries.reps,
                  sets: 1,
                  intensity: newSeries.intensity,
                  rpe: newSeries.rpe,
                  weight: newSeries.weight,
                  order: i + 1,
                  done: false,
                  reps_done: 0,
                  weight_done: 0.0,
                );
                seriesList.add(automatedSeries);
              }
            }

            // Update the WeekProgression with the new values
            final updatedWeekProgression = WeekProgression(
              weekNumber: weekIndex + 1,
              reps: int.parse(repsController.text),
              sets: int.parse(setsController.text),
              intensity: intensityController.text,
              rpe: rpeController.text,
              weight: double.parse(weightController.text),
            );

            int exerciseIndex = exercise.order - 1;
            if (exerciseIndex >= 0 && exerciseIndex < controller.program.weeks[weekIndex].workouts.length) {
              if (controller.program.weeks[weekIndex].workouts.isNotEmpty) {
                int workoutIndex = 0;
                if (controller.program.weeks[weekIndex].workouts[workoutIndex].exercises.length > exerciseIndex) {
                  controller.updateWeekProgression(weekIndex, workoutIndex, exerciseIndex, updatedWeekProgression);
                }
              }
            } else {
              // Gestisci l'errore o ignoralo se necessario
            }

            Navigator.pop(context,seriesList);
          },
          child: Text(series == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}