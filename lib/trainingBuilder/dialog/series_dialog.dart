import 'package:flutter/material.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';

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
    super.key,
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
  });

  @override
  State<SeriesDialog> createState() => _SeriesDialogState();
}

class _SeriesDialogState extends State<SeriesDialog> {
  late final SeriesFormController _formController;

  @override
  void initState() {
    super.initState();
    _formController = SeriesFormController(
      currentSeriesGroup: widget.currentSeriesGroup,
      isIndividualEdit: widget.isIndividualEdit,
      latestMaxWeight: widget.latestMaxWeight,
      exerciseType: widget.exerciseType,
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getDialogTitle()),
      content: SingleChildScrollView(
        child: SeriesForm(controller: _formController),
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

  String _getDialogTitle() {
    if (widget.currentSeriesGroup != null) {
      return widget.isIndividualEdit ? 'Modifica Serie' : 'Modifica Gruppo Serie';
    }
    return 'Aggiungi Serie';
  }

  void _handleSubmit() {
    final series = _formController.createSeries(widget.exercise.series.length);
    Navigator.pop(context, series);
  }
}

class SeriesForm extends StatelessWidget {
  final SeriesFormController controller;

  const SeriesForm({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField(controller.repsController, 'Reps', controller.repsNode),
        if (!controller.isIndividualEdit)
          _buildTextField(controller.setsController, 'Sets', controller.setsNode),
        _buildTextField(controller.intensityController, 'Intensità (%)', controller.intensityNode),
        _buildTextField(controller.rpeController, 'RPE', controller.rpeNode),
        _buildTextField(controller.weightController, 'Peso (kg)', controller.weightNode),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, FocusNode focusNode) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => this.controller.updateRelatedFields(),
    );
  }
}

class SeriesFormController {
  final TextEditingController repsController;
  final TextEditingController setsController;
  final TextEditingController intensityController;
  final TextEditingController rpeController;
  final TextEditingController weightController;

  final FocusNode repsNode;
  final FocusNode setsNode;
  final FocusNode intensityNode;
  final FocusNode rpeNode;
  final FocusNode weightNode;

  String _lastEditedField = '';
  final bool isIndividualEdit;
  final num latestMaxWeight;
  final String exerciseType;

  SeriesFormController({
    List<Series>? currentSeriesGroup,
    required this.isIndividualEdit,
    required this.latestMaxWeight,
    required this.exerciseType,
  }) : repsController = TextEditingController(),
       setsController = TextEditingController(),
       intensityController = TextEditingController(),
       rpeController = TextEditingController(),
       weightController = TextEditingController(),
       repsNode = FocusNode(),
       setsNode = FocusNode(),
       intensityNode = FocusNode(),
       rpeNode = FocusNode(),
       weightNode = FocusNode() {
    _initializeControllers(currentSeriesGroup);
    _setupFocusListeners();
  }

  void _initializeControllers(List<Series>? currentSeriesGroup) {
    if (currentSeriesGroup != null && currentSeriesGroup.isNotEmpty) {
      repsController.text = _getGroupedValue(currentSeriesGroup, (s) => s.reps.toString());
      setsController.text = isIndividualEdit ? '1' : currentSeriesGroup.length.toString();
      intensityController.text = _getGroupedValue(currentSeriesGroup, (s) => s.intensity);
      rpeController.text = _getGroupedValue(currentSeriesGroup, (s) => s.rpe);
      weightController.text = _getGroupedValue(currentSeriesGroup, (s) => s.weight.toString());
    } else {
      setsController.text = '1';
    }
  }

  String _getGroupedValue(List<Series> series, String Function(Series) getValue) {
    var values = series.map(getValue).toSet().toList();
    return values.length == 1 ? values.first : values.join('-');
  }

  void _setupFocusListeners() {
    repsNode.addListener(() => _onFocusChange(repsNode, 'reps'));
    setsNode.addListener(() => _onFocusChange(setsNode, 'sets'));
    intensityNode.addListener(() => _onFocusChange(intensityNode, 'intensity'));
    rpeNode.addListener(() => _onFocusChange(rpeNode, 'rpe'));
    weightNode.addListener(() => _onFocusChange(weightNode, 'weight'));
  }

  void _onFocusChange(FocusNode node, String fieldName) {
    if (node.hasFocus) {
      _lastEditedField = fieldName;
    }
  }

  void updateRelatedFields() {
    if (_isRangeInput()) {
      _updateFieldsForRangeInput();
    } else {
      _updateFieldsForSingleInput();
    }
  }

  bool _isRangeInput() {
    return repsController.text.contains('-') ||
           setsController.text.contains('-') ||
           intensityController.text.contains('-') ||
           rpeController.text.contains('-') ||
           weightController.text.contains('-');
  }

  void _updateFieldsForRangeInput() {
    switch (_lastEditedField) {
      case 'weight':
        _updateIntensityForWeightRange();
        break;
      case 'intensity':
        _updateWeightForIntensityRange();
        break;
      case 'rpe':
        _updateWeightForRPERange();
        break;
    }
  }

  void _updateFieldsForSingleInput() {
    final reps = int.tryParse(repsController.text) ?? 0;
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final intensity = double.tryParse(intensityController.text) ?? 0.0;
    final rpe = double.tryParse(rpeController.text) ?? 0.0;

    switch (_lastEditedField) {
      case 'weight':
        if (weight > 0) {
          intensityController.text = SeriesUtils.calculateIntensityFromWeight(weight, latestMaxWeight).toStringAsFixed(2);
          rpeController.text = SeriesUtils.calculateRPE(weight, latestMaxWeight, reps)?.toStringAsFixed(1) ?? '';
        }
        break;
      case 'intensity':
        if (intensity > 0) {
          final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
          weightController.text = SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
          rpeController.text = SeriesUtils.calculateRPE(calculatedWeight, latestMaxWeight, reps)?.toStringAsFixed(1) ?? '';
        }
        break;
      case 'rpe':
        if (rpe > 0) {
          final percentage = SeriesUtils.getRPEPercentage(rpe, reps);
          final calculatedWeight = latestMaxWeight.toDouble() * percentage;
          weightController.text = SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
          intensityController.text = SeriesUtils.calculateIntensityFromWeight(calculatedWeight, latestMaxWeight).toStringAsFixed(2);
        }
        break;
    }
  }

  void _updateIntensityForWeightRange() {
    final weights = _parseDoubleList(weightController.text);
    final intensities = weights.map((weight) =>
      SeriesUtils.calculateIntensityFromWeight(weight, latestMaxWeight).toStringAsFixed(2)
    ).toList();
    intensityController.text = intensities.join('-');
  }

  void _updateWeightForIntensityRange() {
    final intensities = _parseDoubleList(intensityController.text);
    final weights = intensities.map((intensity) {
      final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
      return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
    }).toList();
    weightController.text = weights.join('-');
  }

  void _updateWeightForRPERange() {
    final rpes = _parseDoubleList(rpeController.text);
    final reps = int.tryParse(repsController.text) ?? 0;
    final weights = rpes.map((rpe) {
      final percentage = SeriesUtils.getRPEPercentage(rpe, reps);
      final calculatedWeight = latestMaxWeight.toDouble() * percentage;
      return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
    }).toList();
    weightController.text = weights.join('-');
  }

  List<Series> createSeries(int currentSeriesCount) {
    final reps = _parseIntList(repsController.text);
    final sets = _parseIntList(setsController.text);
    final intensity = _parseStringList(intensityController.text);
    final rpe = _parseStringList(rpeController.text);
    final weight = _parseDoubleList(weightController.text);

    List<Series> newSeries = [];
    int currentOrder = currentSeriesCount + 1;

    bool isSetsRange = sets.length > 1;
    int totalSets = isSetsRange ? sets.reduce((a, b) => a + b) : sets[0];

    int listIndex = 0;

    if (isSetsRange) {
      for (int i = 0; i < sets.length; i++) {
        for (int j = 0; j < sets[i]; j++) {
          newSeries.add(_createSerie(reps, intensity, rpe, weight, currentOrder++, listIndex));
        }
        listIndex++;
      }
    } else {
      for (int i = 0; i < totalSets; i++) {
        newSeries.add(_createSerie(reps, intensity, rpe, weight, currentOrder++, listIndex));
        listIndex++;
      }
    }

    return newSeries;
  }

  Series _createSerie(List<int> reps, List<String> intensity, List<String> rpe, List<double> weight, int order, int listIndex) {
    return Series(
      serieId: generateRandomId(16),
      reps: reps[listIndex % reps.length],
      sets: 1,
      intensity: intensity[listIndex % intensity.length],
      rpe: rpe[listIndex % rpe.length],
      weight: weight[listIndex % weight.length],
      order: order,
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
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

  void dispose() {
    repsController.dispose();
    setsController.dispose();
    intensityController.dispose();
    rpeController.dispose();
    weightController.dispose();
    repsNode.dispose();
    setsNode.dispose();
    intensityNode.dispose();
    rpeNode.dispose();
    weightNode.dispose();
  }
}