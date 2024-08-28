import 'package:alphanessone/trainingBuilder/models/range_series_translator.dart';
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
        text: widget.currentSeries?.weight.toString() ?? '');
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
      title: Text(widget.currentSeries != null ? 'Modifica Serie' : 'Aggiungi Serie'),
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
          child: Text(widget.currentSeries != null ? 'Salva' : 'Aggiungi'),
        ),
      ],
    );
  }

  void _updateRelatedFields() {
    if (!_isRangeInput()) {
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
    final reps = _parseIntList(_repsController.text);
    final sets = _parseIntList(_setsController.text);
    final intensity = _parseStringList(_intensityController.text);
    final rpe = _parseStringList(_rpeController.text);
    final weight = _calculateWeights(intensity);

    return RangeSeriesTranslator.translateRangeToSeries(
      reps, 
      sets, 
      intensity, 
      rpe, 
      weight,
      widget.exercise.series.length + 1
    );
  }

  List<double> _calculateWeights(List<String> intensities) {
    return intensities.map((intensity) {
      double intensityValue = double.tryParse(intensity) ?? 0.0;
      return (widget.latestMaxWeight * intensityValue / 100).roundToDouble();
    }).toList();
  }

  List<int> _parseIntList(String input) {
    final list = input.split('-').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    return list.isEmpty ? [0] : list;
  }

  List<String> _parseStringList(String input) {
    final list = input.split('-').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return list.isEmpty ? ['0'] : list;
  }

}