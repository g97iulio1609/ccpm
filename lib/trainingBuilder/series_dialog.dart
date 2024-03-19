import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'trainingModel.dart';
import '../users_services.dart';
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
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(trainingProgramControllerProvider);
    final repsController = TextEditingController(text: series?.reps.toString() ?? '');
    final setsController = TextEditingController(text: series?.sets.toString() ?? '');
    final intensityController = TextEditingController(text: series?.intensity ?? '');
    final rpeController = TextEditingController(text: series?.rpe ?? '');
    final weightController = TextEditingController(text: series?.weight.toStringAsFixed(2) ?? '');

    return AlertDialog(
      title: Text(series == null ? 'Add New Series' : 'Edit Series'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(repsController, 'Reps', onChanged: (_) {
              _updateWeightFromRPE(repsController, weightController, rpeController, intensityController);
            }),
            _buildTextField(setsController, 'Sets'),
            _buildNumberField(intensityController, 'Intensity (%)', onChanged: (_) {
              _updateWeight(weightController, intensityController);
            }),
            _buildNumberField(rpeController, 'RPE', stepValue: 0.5, stepIncrement: 0.5, minValue: 6.0, maxValue: 10.0, onChanged: (_) {
              _updateWeightFromRPE(repsController, weightController, rpeController, intensityController);
            }),
            _buildWeightField(weightController, onChanged: (_) {
              _updateIntensity(weightController, intensityController);
              _updateRPE(repsController, weightController, rpeController, intensityController);
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _saveSeries(context, controller, repsController, setsController, intensityController, rpeController, weightController),
          child: Text(series == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(TextEditingController controller, String labelText, {double? minValue, double? maxValue, double? stepValue, double? stepIncrement, ValueChanged<String>? onChanged}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
            ),
            keyboardType: TextInputType.number,
            onChanged: onChanged,
          ),
        ),
        if (stepValue != null && stepIncrement != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  final currentValue = double.tryParse(controller.text) ?? (minValue ?? 0.0);
                  final decrementedValue = currentValue - stepValue;
                  if (minValue == null || decrementedValue >= minValue) {
                    controller.text = decrementedValue.toStringAsFixed(1);
                    onChanged?.call(controller.text);
                  }
                },
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: () {
                  final currentValue = double.tryParse(controller.text) ?? (maxValue ?? double.infinity);
                  final incrementedValue = currentValue + stepIncrement;
                  if (maxValue == null || incrementedValue <= maxValue) {
                    controller.text = incrementedValue.toStringAsFixed(1);
                    onChanged?.call(controller.text);
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildWeightField(TextEditingController controller, {required ValueChanged<String> onChanged}) {
    final formatter = NumberFormat.decimalPattern();
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Weight (kg)',
        labelStyle: TextStyle(color: Colors.grey),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  void _updateWeight(TextEditingController weightController, TextEditingController intensityController) async {
    final intensity = double.tryParse(intensityController.text) ?? 0;
    final latestMaxWeight = await _getLatestMaxWeight();
    final calculatedWeight = (latestMaxWeight * intensity) / 100;
    weightController.text = calculatedWeight.toStringAsFixed(2);
  }

  void _updateIntensity(TextEditingController weightController, TextEditingController intensityController) async {
    final weight = double.tryParse(weightController.text) ?? 0;
    final latestMaxWeight = await _getLatestMaxWeight();
    if (latestMaxWeight != 0) {
      final calculatedIntensity = (weight / latestMaxWeight) * 100;
      intensityController.text = calculatedIntensity.toStringAsFixed(2);
    } else {
      intensityController.clear();
    }
  }

  void _updateWeightFromRPE(TextEditingController repsController, TextEditingController weightController, TextEditingController rpeController, TextEditingController intensityController) async {
    final rpe = double.tryParse(rpeController.text) ?? 0;
    final reps = int.tryParse(repsController.text) ?? 0;
    final latestMaxWeight = await _getLatestMaxWeight();
    final percentage = _getRPEPercentage(rpe, reps);
    final calculatedWeight = latestMaxWeight * percentage;

    weightController.text = calculatedWeight.toStringAsFixed(2);
    intensityController.text = (percentage * 100).toStringAsFixed(2);
  }

  void _updateRPE(TextEditingController repsController, TextEditingController weightController, TextEditingController rpeController, TextEditingController intensityController) async {
    final weight = double.tryParse(weightController.text) ?? 0;
    final reps = int.tryParse(repsController.text) ?? 0;
    final latestMaxWeight = await _getLatestMaxWeight();
    if (latestMaxWeight != 0) {
      final intensity = weight / latestMaxWeight;
      final calculatedRPE = _calculateRPE(intensity, reps);
      if (calculatedRPE != null) {
        rpeController.text = calculatedRPE.toStringAsFixed(1);
      } else {
        rpeController.clear();
      }
    } else {
      rpeController.clear();
      intensityController.clear();
    }
  }

  Future<int> _getLatestMaxWeight() async {
    int latestMaxWeight = 0;
    await usersService.getExerciseRecords(userId: athleteId, exerciseId: exerciseId).first.then((records) {
      if (records.isNotEmpty && exerciseId.isNotEmpty) {
        final latestRecord = records.first;
        latestMaxWeight = latestRecord.maxWeight;
      }
    }).catchError((error) {
      // Handle error
    });
    return latestMaxWeight;
  }

  double _getRPEPercentage(double rpe, int reps) {

    final rpeTable = {
      10: {1: 1.0, 2: 0.955, 3: 0.922, 4: 0.892, 5: 0.863, 6: 0.837, 7: 0.811, 8: 0.786, 9: 0.762, 10: 0.739},
      9: {1: 0.978, 2: 0.939, 3: 0.907, 4: 0.878, 5: 0.850, 6: 0.824, 7: 0.799, 8: 0.774, 9: 0.751, 10: 0.728},
      8: {1: 0.955, 2: 0.922, 3: 0.892, 4: 0.863, 5: 0.837, 6: 0.811, 7: 0.786, 8: 0.762, 9: 0.739, 10: 0.717},
      7: {1: 0.939, 2: 0.907, 3: 0.878, 4: 0.850, 5: 0.824, 6: 0.799, 7: 0.774, 8: 0.751, 9: 0.728, 10: 0.706},
      6: {1: 0.922, 2: 0.892, 3: 0.863, 4: 0.837, 5: 0.811, 6: 0.786, 7: 0.762, 8: 0.739, 9: 0.717, 10: 0.696},
      5: {1: 0.907, 2: 0.878, 3: 0.850, 4: 0.824, 5: 0.799, 6: 0.774, 7: 0.751, 8: 0.728, 9: 0.706, 10: 0.685},
      4: {1: 0.892, 2: 0.863, 3: 0.837, 4: 0.811, 5: 0.786, 6: 0.762, 7: 0.739, 8: 0.717, 9: 0.696, 10: 0.675},
      3: {1: 0.878, 2: 0.850, 3: 0.824, 4: 0.799, 5: 0.774, 6: 0.751, 7: 0.728, 8: 0.706, 9: 0.685, 10: 0.665},
      2: {1: 0.863, 2: 0.837, 3: 0.811, 4: 0.786, 5: 0.762, 6: 0.739, 7: 0.717, 8: 0.696, 9: 0.675, 10: 0.655},
    };

    return rpeTable[rpe.toInt()]?[reps] ?? 1.0;
  }

  double? _calculateRPE(double intensity, int reps) {
  
    final rpeTable = {
      10: {1: 1.0, 2: 0.955, 3: 0.922, 4: 0.892, 5: 0.863, 6: 0.837, 7: 0.811, 8: 0.786, 9: 0.762, 10: 0.739},
      9: {1: 0.978, 2: 0.939, 3: 0.907, 4: 0.878, 5: 0.850, 6: 0.824, 7: 0.799, 8: 0.774, 9: 0.751, 10: 0.728},
      8: {1: 0.955, 2: 0.922, 3: 0.892, 4: 0.863, 5: 0.837, 6: 0.811, 7: 0.786, 8: 0.762, 9: 0.739, 10: 0.717},
      7: {1: 0.939, 2: 0.907, 3: 0.878, 4: 0.850, 5: 0.824, 6: 0.799, 7: 0.774, 8: 0.751, 9: 0.728, 10: 0.706},
      6: {1: 0.922, 2: 0.892, 3: 0.863, 4: 0.837, 5: 0.811, 6: 0.786, 7: 0.762, 8: 0.739, 9: 0.717, 10: 0.696},
      5: {1: 0.907, 2: 0.878, 3: 0.850, 4: 0.824, 5: 0.799, 6: 0.774, 7: 0.751, 8: 0.728, 9: 0.706, 10: 0.685},
      4: {1: 0.892, 2: 0.863, 3: 0.837, 4: 0.811, 5: 0.786, 6: 0.762, 7: 0.739, 8: 0.717, 9: 0.696, 10: 0.675},
      3: {1: 0.878, 2: 0.850, 3: 0.824, 4: 0.799, 5: 0.774, 6: 0.751, 7: 0.728, 8: 0.706, 9: 0.685, 10: 0.665},
      2: {1: 0.863, 2: 0.837, 3: 0.811, 4: 0.786, 5: 0.762, 6: 0.739, 7: 0.717, 8: 0.696, 9: 0.675, 10: 0.655},
    };

    double? calculatedRPE;
    rpeTable.forEach((rpe, repPercentages) {
      repPercentages.forEach((rep, percentage) {
        if ((intensity - percentage).abs() < 0.01 && rep == reps) {
          calculatedRPE = rpe.toDouble();
        }
      });
    });return calculatedRPE;
  }

  void _saveSeries(
  BuildContext context,
  TrainingProgramController controller,
  TextEditingController repsController,
  TextEditingController setsController,
  TextEditingController intensityController,
  TextEditingController rpeController,
  TextEditingController weightController,
  ) {
    final newSeries = Series(
      id: series?.id,
      serieId: series?.serieId ?? '',
      reps: int.parse(repsController.text),
      sets: 1,
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

    final updatedWeekProgression = WeekProgression(
      weekNumber: weekIndex + 1,
      reps: int.parse(repsController.text),
      sets: int.parse(setsController.text),
      intensity: intensityController.text,
      rpe: rpeController.text,
      weight: double.parse(weightController.text),
    );

    final exerciseIndex = exercise.order - 1;
    if (exerciseIndex >= 0 && exerciseIndex < controller.program.weeks[weekIndex].workouts.length) {
      const workoutIndex = 0;
if (exerciseIndex >= 0 && exerciseIndex < controller.program.weeks[weekIndex].workouts[workoutIndex].exercises.length) {
    controller.updateWeekProgression(weekIndex, workoutIndex, exerciseIndex, updatedWeekProgression);
  }
    }

    Navigator.pop(context, seriesList);
  }
}