import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';

class SeriesDialog extends StatefulWidget {
  final ExerciseRecordService exerciseRecordService;
  final String athleteId;
  final String exerciseId;
  final int weekIndex;
  final Exercise exercise;
  final String exerciseType;
  final Series? currentSeries;
  final num latestMaxWeight;
  final ValueNotifier<double> weightNotifier;

  const SeriesDialog({
    required this.exerciseRecordService,
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
  SeriesDialogState createState() => SeriesDialogState();
}

class SeriesDialogState extends State<SeriesDialog> {
  late num latestMaxWeight;

  late TextEditingController _repsController;
  late TextEditingController _setsController;
  late TextEditingController _intensityController;
  late TextEditingController _rpeController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    latestMaxWeight = widget.latestMaxWeight;

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
      title: Text(
          widget.currentSeries != null ? 'Modifica Serie' : 'Aggiungi Serie'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
              onChanged: (_) => SeriesUtils.updateRPE(
                  _repsController,
                  _weightController,
                  _rpeController,
                  _intensityController,
                  widget.latestMaxWeight),
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
              decoration: const InputDecoration(labelText: 'Intensità (%)'),
              onChanged: (value) {
                SeriesUtils.updateWeightFromIntensity(
                    _weightController,
                    _intensityController,
                    widget.exerciseType,
                    widget.latestMaxWeight,
                    widget.weightNotifier);
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
              onChanged: (_) => SeriesUtils.updateWeightFromRPE(
                  _repsController,
                  _weightController,
                  _rpeController,
                  _intensityController,
                  widget.exerciseType,
                  widget.latestMaxWeight,
                  widget.weightNotifier),
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
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              onChanged: (value) {
                final newWeight = double.tryParse(value) ?? 0;
                widget.weightNotifier.value = newWeight;
                SeriesUtils.updateIntensityFromWeight(
                  _weightController,
                  _intensityController,
                  latestMaxWeight.toDouble(),
                );
                SeriesUtils.updateRPE(
                  _repsController,
                  _weightController,
                  _rpeController,
                  _intensityController,
                  latestMaxWeight,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
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
                  serieId: '',
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
          child: Text(widget.currentSeries != null ? 'Salva' : 'Aggiungi'),
        ),
      ],
    );
  }
}
