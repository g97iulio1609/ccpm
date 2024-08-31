import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const SeriesForm({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRangeTextField(controller.repsController, 'Reps', controller.repsNode),
        if (!controller.isIndividualEdit)
          _buildRangeTextField(controller.setsController, 'Sets', controller.setsNode),
        _buildRangeTextField(controller.intensityController, 'Intensità (%)', controller.intensityNode),
        _buildRangeTextField(controller.rpeController, 'RPE', controller.rpeNode),
        _buildRangeTextField(controller.weightController, 'Peso (kg)', controller.weightNode),
      ],
    );
  }

  Widget _buildRangeTextField(TextEditingController controller, String label, FocusNode focusNode) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9./-]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Valore singolo, Min/Max o Serie1-Serie2-...',
      ),
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
      repsController.text = _getGroupedValue(currentSeriesGroup, (s) => s.reps.toString(), (s) => s.maxReps?.toString());
      setsController.text = isIndividualEdit ? '1' : currentSeriesGroup.length.toString();
      intensityController.text = _getGroupedValue(currentSeriesGroup, (s) => s.intensity, (s) => s.maxIntensity);
      rpeController.text = _getGroupedValue(currentSeriesGroup, (s) => s.rpe, (s) => s.maxRpe);
      weightController.text = _getGroupedValue(currentSeriesGroup, (s) => s.weight.toString(), (s) => s.maxWeight?.toString());
    } else {
      setsController.text = '1';
    }
  }

  String _getGroupedValue(List<Series> series, String Function(Series) getValue, String? Function(Series) getMaxValue) {
    var values = series.map((s) {
      String value = getValue(s);
      String? maxValue = getMaxValue(s);
      return maxValue != null && maxValue != value ? '$value/$maxValue' : value;
    }).toSet().toList();
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

  List<Series> createSeries(int currentSeriesCount) {
    if (_isMultiSeriesInput()) {
      return _createMultipleSeries(currentSeriesCount);
    } else {
      return _createIntervalSeries(currentSeriesCount);
    }
  }

  bool _isMultiSeriesInput() {
    return repsController.text.contains('-') ||
           setsController.text.contains('-') ||
           intensityController.text.contains('-') ||
           rpeController.text.contains('-') ||
           weightController.text.contains('-');
  }

  List<Series> _createIntervalSeries(int currentSeriesCount) {
    final reps = _parseIntervalValues(repsController.text);
    final sets = int.tryParse(setsController.text) ?? 1;
    final intensity = _parseIntervalValues(intensityController.text);
    final rpe = _parseIntervalValues(rpeController.text);
    final weight = _parseIntervalValues(weightController.text);

    List<Series> newSeries = [];
    int currentOrder = currentSeriesCount + 1;

    for (int i = 0; i < sets; i++) {
      newSeries.add(Series(
        serieId: generateRandomId(16),
        reps: reps[0].toInt(),
        sets: 1,
        intensity: intensity[0].toString(),
        rpe: rpe[0].toString(),
        weight: weight[0],
        order: currentOrder++,
        done: false,
        reps_done: 0,
        weight_done: 0.0,
        maxReps: reps.length > 1 ? reps[1].toInt() : null,
        maxSets: null,
        maxIntensity: intensity.length > 1 ? intensity[1].toString() : null,
        maxRpe: rpe.length > 1 ? rpe[1].toString() : null,
        maxWeight: weight.length > 1 ? weight[1] : null,
      ));
    }

    return newSeries;
  }

  List<Series> _createMultipleSeries(int currentSeriesCount) {
    final reps = _parseMultipleValues(repsController.text);
    final sets = _parseMultipleValues(setsController.text);
    final intensity = _parseMultipleValues(intensityController.text);
    final rpe = _parseMultipleValues(rpeController.text);
    final weight = _parseMultipleValues(weightController.text);

    int maxLength = [reps.length, sets.length, intensity.length, rpe.length, weight.length]
        .reduce((a, b) => a > b ? a : b);

    List<Series> newSeries = [];
    int currentOrder = currentSeriesCount + 1;

    for (int i = 0; i < maxLength; i++) {
      newSeries.add(Series(
        serieId: generateRandomId(16),
        reps: i < reps.length ? reps[i].toInt() : reps.last.toInt(),
        sets: i < sets.length ? sets[i].toInt() : sets.last.toInt(),
        intensity: i < intensity.length ? intensity[i].toString() : intensity.last.toString(),
        rpe: i < rpe.length ? rpe[i].toString() : rpe.last.toString(),
        weight: i < weight.length ? weight[i] : weight.last,
        order: currentOrder++,
        done: false,
        reps_done: 0,
        weight_done: 0.0,
      ));
    }

    return newSeries;
  }

  List<double> _parseIntervalValues(String input) {
    if (input.isEmpty) {
      return [0.0];
    }

    List<String> parts = input.split('/');
    return parts.map((part) => _parseDouble(part.trim())).toList();
  }

  List<double> _parseMultipleValues(String input) {
    if (input.isEmpty) {
      return [0.0];
    }

    List<String> parts = input.split('-');
    return parts.map((part) => _parseDouble(part.trim())).toList();
  }

  double _parseDouble(String value) {
    try {
      return double.parse(value);
    } catch (e) {
      print('Error parsing double: $value');
      return 0.0;
    }
  }

  void updateRelatedFields() {
    if (_isMultiSeriesInput()) {
      _updateFieldsForMultiSeriesInput();
    } else if (_isIntervalInput()) {
      _updateFieldsForIntervalInput();
    } else {
      _updateFieldsForSingleInput();
    }
  }

  bool _isIntervalInput() {
    return repsController.text.contains('/') ||
           intensityController.text.contains('/') ||
           rpeController.text.contains('/') ||
           weightController.text.contains('/');
  }

  void _updateFieldsForMultiSeriesInput() {
    switch (_lastEditedField) {
      case 'weight':
        _updateIntensityAndRPEForMultiWeight();
        break;
      case 'intensity':
        _updateWeightAndRPEForMultiIntensity();
        break;
      case 'rpe':
        _updateWeightAndIntensityForMultiRPE();
        break;
    }
  }

  void _updateIntensityAndRPEForMultiWeight() {
    final weights = _parseMultipleValues(weightController.text);
    final reps = _parseMultipleValues(repsController.text);
    final intensities = weights.map((weight) =>
      SeriesUtils.calculateIntensityFromWeight(weight, latestMaxWeight).toStringAsFixed(2)
    ).toList();
    final rpes = List.generate(weights.length, (index) {
      final repsValue = index < reps.length ? reps[index].toInt() : reps.last.toInt();
      return SeriesUtils.calculateRPE(weights[index], latestMaxWeight, repsValue)?.toStringAsFixed(1) ?? '';
    });
    intensityController.text = intensities.join('-');
    rpeController.text = rpes.join('-');
  }

  void _updateWeightAndRPEForMultiIntensity() {
    final intensities = _parseMultipleValues(intensityController.text);
    final reps = _parseMultipleValues(repsController.text);
    final weights = intensities.map((intensity) {
      final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
      return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
    }).toList();
    final rpes = List.generate(intensities.length, (index) {
      final repsValue = index < reps.length ? reps[index].toInt() : reps.last.toInt();
      return SeriesUtils.calculateRPE(double.parse(weights[index]), latestMaxWeight, repsValue)?.toStringAsFixed(1) ?? '';
    });
    weightController.text = weights.join('-');
    rpeController.text = rpes.join('-');
  }

void _updateWeightAndIntensityForMultiRPE() {
    final rpes = _parseMultipleValues(rpeController.text);
    final reps = _parseMultipleValues(repsController.text);
    final weights = List.generate(rpes.length, (index) {
      final repsValue = index < reps.length ? reps[index].toInt() : reps.last.toInt();
      final percentage = SeriesUtils.getRPEPercentage(rpes[index], repsValue);
      final calculatedWeight = latestMaxWeight.toDouble() * percentage;
      return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
    });
    final intensities = weights.map((weight) =>
      SeriesUtils.calculateIntensityFromWeight(double.parse(weight), latestMaxWeight).toStringAsFixed(2)
    ).toList();
    weightController.text = weights.join('-');
    intensityController.text = intensities.join('-');
  }

  void _updateFieldsForIntervalInput() {
    switch (_lastEditedField) {
      case 'weight':
        _updateIntensityForWeightInterval();
        break;
      case 'intensity':
        _updateWeightForIntensityInterval();
        break;
      case 'rpe':
        _updateWeightForRPEInterval();
        break;
    }
  }

  void _updateIntensityForWeightInterval() {
    final weights = _parseIntervalValues(weightController.text);
    final intensities = weights.map((weight) =>
      SeriesUtils.calculateIntensityFromWeight(weight, latestMaxWeight).toStringAsFixed(2)
    ).toList();
    intensityController.text = intensities.join('/');
  }

  void _updateWeightForIntensityInterval() {
    final intensities = _parseIntervalValues(intensityController.text);
    final weights = intensities.map((intensity) {
      final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
      return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
    }).toList();
    weightController.text = weights.join('/');
  }

  void _updateWeightForRPEInterval() {
    final rpes = _parseIntervalValues(rpeController.text);
    final reps = int.tryParse(repsController.text.split('/')[0]) ?? 0;
    final weights = rpes.map((rpe) {
      final percentage = SeriesUtils.getRPEPercentage(rpe, reps);
      final calculatedWeight = latestMaxWeight.toDouble() * percentage;
      return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
    }).toList();
    weightController.text = weights.join('/');
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