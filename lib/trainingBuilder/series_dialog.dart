import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'training_model.dart';
import '../users_services.dart';
import 'training_program_controller.dart';
import 'utility_functions.dart';

class SeriesDialog extends ConsumerWidget {
  final UsersService usersService;
  final String athleteId;
  final String exerciseId;
  final int weekIndex;
  final Exercise exercise;
  final Series? currentSeries;

  const SeriesDialog({
    required this.usersService,
    required this.athleteId,
    required this.exerciseId,
    required this.weekIndex,
    required this.exercise,
    this.currentSeries,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(trainingProgramControllerProvider);
    final repsController = TextEditingController(text: currentSeries?.reps.toString() ?? '');
    final setsController = TextEditingController(text: currentSeries?.sets.toString() ?? '');
    final intensityController = TextEditingController(text: currentSeries?.intensity ?? '');
    final rpeController = TextEditingController(text: currentSeries?.rpe ?? '');
    final weightController = TextEditingController(text: currentSeries?.weight.toStringAsFixed(2) ?? '');

    FocusNode repsFocusNode = FocusNode();
    FocusNode setsFocusNode = FocusNode();
    FocusNode intensityFocusNode = FocusNode();
    FocusNode rpeFocusNode = FocusNode();
    FocusNode weightFocusNode = FocusNode();

    return AlertDialog(
      title: Text(currentSeries == null ? 'Add New Series' : 'Edit Series'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(repsController, 'Reps', focusNode: repsFocusNode, onChanged: (_) {
              _updateRPE(repsController, weightController, rpeController, intensityController, rpeFocusNode, weightFocusNode);
            }),
            _buildTextField(setsController, 'Sets', focusNode: setsFocusNode),
            _buildNumberField(intensityController, 'Intensity (%)', focusNode: intensityFocusNode, onChanged: (value) {
              _updateWeight(weightController, intensityController, weightFocusNode, intensityFocusNode);
            }),
            _buildNumberField(rpeController, 'RPE', focusNode: rpeFocusNode, stepValue: 0.5, stepIncrement: 0.5, minValue: 6.0, maxValue: 10.0, onChanged: (value) {
              _updateWeightAndIntensity(controller, repsController, weightController, rpeController, intensityController, rpeFocusNode, weightFocusNode, intensityFocusNode);
            }),
            _buildWeightField(weightController, focusNode: weightFocusNode, onChanged: (value) {
              _updateIntensity(weightController, intensityController, weightFocusNode, intensityFocusNode);
              _updateRPE(repsController, weightController, rpeController, intensityController, rpeFocusNode, weightFocusNode);
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
          child: Text(currentSeries == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, {required FocusNode focusNode, ValueChanged<String>? onChanged}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
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

  Widget _buildNumberField(TextEditingController controller, String labelText, {required FocusNode focusNode, double? minValue, double? maxValue, double? stepValue, double? stepIncrement, required ValueChanged<String> onChanged}) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
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
                    onChanged(controller.text);
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
                    onChanged(controller.text);
                  }
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildWeightField(TextEditingController controller, {required FocusNode focusNode, required ValueChanged<String> onChanged}) {
    final formatter = NumberFormat.decimalPattern();
    return TextField(
      controller: controller,
      focusNode: focusNode,
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

  void _updateWeight(TextEditingController weightController, TextEditingController intensityController, FocusNode weightFocusNode, FocusNode intensityFocusNode) async {
    if (intensityFocusNode.hasFocus) {
      final intensity = double.tryParse(intensityController.text) ?? 0;
      final latestMaxWeight = await getLatestMaxWeight(usersService, athleteId, exerciseId);
      final calculatedWeight = calculateWeightFromIntensity(latestMaxWeight, intensity);
      final roundedWeight = roundWeight(calculatedWeight, exercise.type);
      weightController.text = roundedWeight.toStringAsFixed(2);
    }
  }

  void _updateIntensity(TextEditingController weightController, TextEditingController intensityController, FocusNode weightFocusNode, FocusNode intensityFocusNode) async {
    if (weightFocusNode.hasFocus) {
      final weight = double.tryParse(weightController.text) ?? 0;
      final latestMaxWeight = await getLatestMaxWeight(usersService, athleteId, exerciseId);
      final calculatedIntensity = calculateIntensityFromWeight(weight, latestMaxWeight);
      intensityController.text = calculatedIntensity.toStringAsFixed(2);
    }
  }

  void _updateWeightAndIntensity(
    TrainingProgramController controller,
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController rpeController,
    TextEditingController intensityController,
    FocusNode rpeFocusNode,
    FocusNode weightFocusNode,
    FocusNode intensityFocusNode,
  ) async {
    if (rpeFocusNode.hasFocus) {
      final rpeText = rpeController.text;
      if (rpeText.isNotEmpty) {
        final rpe = double.parse(rpeText);
        final reps = int.tryParse(repsController.text) ?? 0;
        final latestMaxWeight = await getLatestMaxWeight(usersService, athleteId, exerciseId);
        final percentage = getRPEPercentage(rpe, reps);
        final calculatedWeight = latestMaxWeight * percentage;
        final roundedWeight = roundWeight(calculatedWeight, exercise.type);

        weightController.text = roundedWeight.toStringAsFixed(2);
        final calculatedIntensity = calculateIntensityFromWeight(roundedWeight, latestMaxWeight);
        intensityController.text = calculatedIntensity.toStringAsFixed(2);
      }
    }
  }

  void _updateRPE(
    TextEditingController repsController,
    TextEditingController weightController,
    TextEditingController rpeController,
    TextEditingController intensityController,
    FocusNode rpeFocusNode,
    FocusNode weightFocusNode,
  ) async {
    if (!rpeFocusNode.hasFocus && !weightFocusNode.hasFocus) {
      final weight = double.tryParse(weightController.text) ?? 0;
      final reps = int.tryParse(repsController.text) ?? 0;
      final latestMaxWeight = await getLatestMaxWeight(usersService, athleteId, exerciseId);
      final calculatedRPE = calculateRPE(weight, latestMaxWeight, reps);

      if (calculatedRPE != null) {
        rpeController.text = calculatedRPE.toStringAsFixed(1);
        final percentage = getRPEPercentage(calculatedRPE, reps);
        intensityController.text = (percentage * 100).toStringAsFixed(2);
      } else {
        rpeController.clear();
        intensityController.clear();
      }
    }
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
    final reps = int.tryParse(repsController.text) ?? 0;
    final sets = int.tryParse(setsController.text) ?? 0;
    final intensity = intensityController.text;
    final rpe = rpeController.text;
    final weight = double.tryParse(weightController.text) ?? 0;

    final newSeries = Series(
      id: currentSeries?.id,
      serieId: currentSeries?.serieId ?? '',
      reps: reps,
      sets: 1,
      intensity: intensity,
      rpe: rpe,
      weight: weight,
      order: currentSeries?.order ?? 1,
      done: currentSeries?.done ?? false,
      reps_done: currentSeries?.reps_done ?? 0,
      weight_done: currentSeries?.weight_done ?? 0.0,
    );

    if (newSeries.serieId.isEmpty) {
      newSeries.serieId = '${DateTime.now().millisecondsSinceEpoch}_0';
    }

    final seriesList = [newSeries];

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
      reps: reps,
      sets: sets,
      intensity: intensity,
      rpe: rpe,
      weight: weight,
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