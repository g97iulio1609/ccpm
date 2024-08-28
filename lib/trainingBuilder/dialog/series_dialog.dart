import 'dart:math';

import 'package:alphanessone/trainingBuilder/models/range_series_translator.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
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
  final List<Series>? currentSeriesGroup;
  final num latestMaxWeight;
  final ValueNotifier<double> weightNotifier;
  final bool isIndividualEdit;

  const SeriesDialog({
    Key? key,
    required this.exerciseRecordService,
    required this.athleteId,
    required this.exerciseId,
    required this.exerciseType,
    required this.weekIndex,
    required this.exercise,
    this.currentSeriesGroup,
    required this.latestMaxWeight,
    required this.weightNotifier,
    this.isIndividualEdit = false,
  }) : super(key: key);

  @override
  SeriesDialogState createState() => SeriesDialogState();
}

class SeriesDialogState extends State<SeriesDialog> {
  late TextEditingController _repsController;
  late TextEditingController _setsController;
  late TextEditingController _intensityController;
  late TextEditingController _rpeController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    if (widget.currentSeriesGroup != null && widget.currentSeriesGroup!.isNotEmpty) {
      Series firstSeries = widget.currentSeriesGroup!.first;
      _repsController = TextEditingController(text: firstSeries.reps.toString());
      _setsController = TextEditingController(text: widget.isIndividualEdit ? '1' : widget.currentSeriesGroup!.length.toString());
      _intensityController = TextEditingController(text: firstSeries.intensity.toString());
      _rpeController = TextEditingController(text: firstSeries.rpe.toString());
      _weightController = TextEditingController(text: firstSeries.weight.toString());
    } else {
      _repsController = TextEditingController();
      _setsController = TextEditingController(text: '1');
      _intensityController = TextEditingController();
      _rpeController = TextEditingController();
      _weightController = TextEditingController();
    }
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
      title: Text(widget.currentSeriesGroup != null 
        ? (widget.isIndividualEdit ? 'Modifica Serie' : 'Modifica Gruppo Serie') 
        : 'Aggiungi Serie'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Reps'),
              onChanged: (_) => _updateRelatedFields(),
            ),
            if (!widget.isIndividualEdit)
              TextField(
                controller: _setsController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: 'Sets'),
              ),
            TextField(
              controller: _intensityController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Intensità (%)'),
              onChanged: (_) => _updateRelatedFields(),
            ),
            TextField(
              controller: _rpeController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'RPE'),
              onChanged: (_) => _updateRelatedFields(),
            ),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
              onChanged: (_) => _updateRelatedFields(),
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
          onPressed: _handleSubmit,
          child: Text(widget.currentSeriesGroup != null ? 'Salva' : 'Aggiungi'),
        ),
      ],
    );
  }

  void _updateRelatedFields() {
    if (_isRangeInput()) {
      _updateWeightForIntensityRange();
    } else {
      SeriesUtils.updateRPE(
        _repsController,
        _weightController,
        _rpeController,
        _intensityController,
        widget.latestMaxWeight,
      );

      SeriesUtils.updateWeightFromIntensity(
        _weightController,
        _intensityController,
        widget.exerciseType,
        widget.latestMaxWeight,
        widget.weightNotifier,
      );

      SeriesUtils.updateWeightFromRPE(
        _repsController,
        _weightController,
        _rpeController,
        _intensityController,
        widget.exerciseType,
        widget.latestMaxWeight,
        widget.weightNotifier,
      );
    }
  }

  void _updateWeightForIntensityRange() {
    final intensities = _parseStringList(_intensityController.text);
    final weights = _calculateWeightsForIntensityRange(intensities);
    _weightController.text = weights.join('-');
  }

  List<String> _calculateWeightsForIntensityRange(List<String> intensities) {
    return intensities.map((intensity) {
      double intensityValue = double.tryParse(intensity) ?? 0.0;
      double weight = (widget.latestMaxWeight * intensityValue / 100).roundToDouble();
      return SeriesUtils.roundWeight(weight, widget.exerciseType).toString();
    }).toList();
  }

  bool _isRangeInput() {
    return _repsController.text.contains('-') ||
           _setsController.text.contains('-') ||
           _intensityController.text.contains('-') ||
           _rpeController.text.contains('-') ||
           _weightController.text.contains('-');
  }

  void _handleSubmit() {
    final series = _createSeries();
    Navigator.pop(context, series);
  }

List<Series> _createSeries() {
  if (widget.isIndividualEdit && widget.currentSeriesGroup != null && widget.currentSeriesGroup!.isNotEmpty) {
    // Modifica individuale di un set esistente
    Series updatedSeries = widget.currentSeriesGroup!.first.copyWith(
      reps: int.tryParse(_repsController.text) ?? 0,
      intensity: _intensityController.text,
      rpe: _rpeController.text,
      weight: double.tryParse(_weightController.text) ?? 0.0,
    );
    return [updatedSeries];
  } else {
    // Creazione di nuove serie o modifica di gruppo
    final reps = _parseIntList(_repsController.text);
    final sets = _parseIntList(_setsController.text);
    final intensity = _parseStringList(_intensityController.text);
    final rpe = _parseStringList(_rpeController.text);
    final weight = _parseDoubleList(_weightController.text);

    List<Series> newSeries = [];
    int currentOrder = widget.exercise.series.length + 1;

    for (int i = 0; i < reps.length; i++) {
      int currentSets = i < sets.length ? sets[i] : sets.last;
      for (int j = 0; j < currentSets; j++) {
        newSeries.add(Series(
          serieId: generateRandomId(16),
          reps: reps[i],
          sets: 1,
          intensity: i < intensity.length ? intensity[i] : intensity.last,
          rpe: i < rpe.length ? rpe[i] : rpe.last,
          weight: i < weight.length ? weight[i] : weight.last,
          order: currentOrder++,
          done: false,
          reps_done: 0,
          weight_done: 0.0,
        ));
      }
    }

    if (widget.currentSeriesGroup != null) {
      for (int i = 0; i < newSeries.length && i < widget.currentSeriesGroup!.length; i++) {
        newSeries[i] = newSeries[i].copyWith(serieId: widget.currentSeriesGroup![i].serieId);
      }
    }

    return newSeries;
  }
}


List<int> _parseIntList(String input) {
  final list = input.split('-').map((e) => int.tryParse(e.trim()) ?? 0).toList();
  return list.isEmpty ? [0] : list;
}

List<String> _parseStringList(String input) {
  final list = input.split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  return list.isEmpty ? ['0'] : list;
}

List<double> _parseDoubleList(String input) {
  final list = input.split('-').map((e) => double.tryParse(e.trim()) ?? 0.0).toList();
  return list.isEmpty ? [0.0] : list;
}

}