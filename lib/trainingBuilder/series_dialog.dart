import 'package:alphanessone/trainingBuilder/utility_functions.dart';

import 'package:alphanessone/trainingBuilder/training_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../users_services.dart';

class SeriesDialog extends StatefulWidget {
  final UsersService usersService;
  final String athleteId;
  final String exerciseId;
  final int weekIndex;
  final Exercise exercise;
  final String exerciseType;

  final Series? currentSeries;
  final num latestMaxWeight;
  final ValueNotifier<double> weightNotifier;

  const SeriesDialog({
    required this.usersService,
    required this.athleteId,
    required this.exerciseId,
    required this.exerciseType,
    required this.weekIndex,
    required this.exercise,
    this.currentSeries,
    required this.latestMaxWeight,
    required this.weightNotifier,
    super.key,
  });

  @override
  _SeriesDialogState createState() => _SeriesDialogState();
}

class _SeriesDialogState extends State<SeriesDialog> {
  late TextEditingController _repsController;
  late TextEditingController _setsController;
  late TextEditingController _intensityController;
  late TextEditingController _rpeController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
        text: widget.currentSeries?.reps.toString() ?? '');
    _setsController = TextEditingController(
        text: widget.currentSeries?.sets.toString() ?? '1');
    _intensityController = TextEditingController(
        text: widget.currentSeries?.intensity.toString() ?? '');
    _rpeController =
        TextEditingController(text: widget.currentSeries?.rpe.toString() ?? '');
    _weightController = TextEditingController(
        text: widget.currentSeries?.weight.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _repsController.dispose();
    _setsController.dispose();
    _intensityController.dispose();
    _rpeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.currentSeries != null ? 'Edit Series' : 'Add Series'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
              onChanged: (_) => _updateRPE(),
            ),
            TextField(
              controller: _setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sets'),
            ),
            TextField(
              controller: _intensityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(',', '.');
                  return newValue.copyWith(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ],
              decoration: const InputDecoration(labelText: 'Intensity (%)'),
              onChanged: (value) {
                final intensity = double.tryParse(value) ?? 0;
                _updateWeight(intensity);
              },
            ),
            TextField(
              controller: _rpeController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(',', '.');
                  return newValue.copyWith(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ],
              decoration: const InputDecoration(labelText: 'RPE'),
              onChanged: (_) => _updateWeightFromRPE(),
            ),
            TextField(
              controller: _weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(',', '.');
                  return newValue.copyWith(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ],
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              onChanged: (value) {
                final newWeight = double.tryParse(value) ?? 0;
                widget.weightNotifier.value = newWeight;
                _updateIntensity(newWeight);
                _updateRPE();
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
          onPressed: () {
            final reps = int.tryParse(_repsController.text) ?? 0;
            final sets = int.tryParse(_setsController.text) ?? 1;
            final intensity = _intensityController.text;
            final rpe = _rpeController.text;
            final weight = double.tryParse(_weightController.text) ?? 0;

            if (widget.currentSeries != null) {
              widget.currentSeries!.reps = reps;
              widget.currentSeries!.sets = sets;
              widget.currentSeries!.intensity = intensity;
              widget.currentSeries!.rpe = rpe;
              widget.currentSeries!.weight = weight;
              Navigator.pop(context, [widget.currentSeries!]);
            } else {
              final series = List.generate(
                sets,
                (index) => Series(
                  serieId: generateRandomId(16).toString(),
                  reps: reps,
                  sets: 1,
                  intensity: intensity,
                  rpe: rpe,
                  weight: weight,
                  order: widget.exercise.series.length + index + 1,
                  done: false,
                  reps_done: 0,
                  weight_done: 0.0,
                ),
              );
              Navigator.pop(context, series);
            }
          },
          child: Text(widget.currentSeries != null ? 'Save' : 'Add'),
        ),
      ],
    );
  }

 void _updateWeight(double intensity) {
  final calculatedWeight = calculateWeightFromIntensity(widget.latestMaxWeight, intensity);
  final roundedWeight = roundWeight(calculatedWeight, widget.exerciseType);
  widget.weightNotifier.value = roundedWeight;
  _weightController.text = roundedWeight.toStringAsFixed(2);
}

  void _updateIntensity(double weight) {
    final calculatedIntensity =
        calculateIntensityFromWeight(weight, widget.latestMaxWeight);
    _intensityController.text = calculatedIntensity.toStringAsFixed(2);
  }

void _updateWeightFromRPE() {
  final reps = int.tryParse(_repsController.text) ?? 0;
  final rpe = double.tryParse(_rpeController.text) ?? 0;
  final percentage = getRPEPercentage(rpe, reps);
  final calculatedWeight = widget.latestMaxWeight * percentage;
  final roundedWeight = roundWeight(calculatedWeight, widget.exerciseType);
  widget.weightNotifier.value = roundedWeight;
  _weightController.text = roundedWeight.toStringAsFixed(2);
}

 void _updateRPE() {
  final reps = int.tryParse(_repsController.text) ?? 0;
  final weight = double.tryParse(_weightController.text) ?? 0;
  final calculatedRPE = calculateRPE(weight, widget.latestMaxWeight, reps);
  if (calculatedRPE != null) {
    _rpeController.text = calculatedRPE.toStringAsFixed(1);
    final intensity = calculateIntensityFromWeight(weight, widget.latestMaxWeight);
    _intensityController.text = intensity.toStringAsFixed(2);
  }
}
}
