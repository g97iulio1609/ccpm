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
  // Controllers for text fields
  late final TextEditingController _repsController;
  late final TextEditingController _setsController;
  late final TextEditingController _intensityController;
  late final TextEditingController _rpeController;
  late final TextEditingController _weightController;

  // Focus nodes for text fields
  final FocusNode _repsNode = FocusNode();
  final FocusNode _setsNode = FocusNode();
  final FocusNode _intensityNode = FocusNode();
  final FocusNode _rpeNode = FocusNode();
  final FocusNode _weightNode = FocusNode();

  // Track the last edited field for related field updates
  String _lastEditedField = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupFocusListeners();
  }

  void _initializeControllers() {
    // Initialize controllers based on whether we are editing an existing series group or creating a new one
    if (widget.currentSeriesGroup != null && widget.currentSeriesGroup!.isNotEmpty) {
      _repsController = TextEditingController(text: _getGroupedValue(widget.currentSeriesGroup!, (s) => s.reps.toString()));
      _setsController = TextEditingController(text: widget.isIndividualEdit ? '1' : widget.currentSeriesGroup!.length.toString());
      _intensityController = TextEditingController(text: _getGroupedValue(widget.currentSeriesGroup!, (s) => s.intensity));
      _rpeController = TextEditingController(text: _getGroupedValue(widget.currentSeriesGroup!, (s) => s.rpe));
      _weightController = TextEditingController(text: _getGroupedValue(widget.currentSeriesGroup!, (s) => s.weight.toString()));
    } else {
      _repsController = TextEditingController();
      _setsController = TextEditingController(text: '1');
      _intensityController = TextEditingController();
      _rpeController = TextEditingController();
      _weightController = TextEditingController();
    }
  }

  // Helper function to get a grouped value from a list of series
  String _getGroupedValue(List<Series> series, String Function(Series) getValue) {
    var values = series.map(getValue).toSet().toList();
    return values.length == 1 ? values.first : values.join('-');
  }

  // Setup focus listeners for tracking the last edited field
  void _setupFocusListeners() {
    _repsNode.addListener(() => _onFocusChange(_repsNode, 'reps'));
    _setsNode.addListener(() => _onFocusChange(_setsNode, 'sets'));
    _intensityNode.addListener(() => _onFocusChange(_intensityNode, 'intensity'));
    _rpeNode.addListener(() => _onFocusChange(_rpeNode, 'rpe'));
    _weightNode.addListener(() => _onFocusChange(_weightNode, 'weight'));
  }

  // Update the last edited field when a field gains focus
  void _onFocusChange(FocusNode node, String fieldName) {
    if (node.hasFocus) {
      setState(() {
        _lastEditedField = fieldName;
      });
    }
  }

  @override
  void dispose() {
    // Dispose of controllers and focus nodes to prevent memory leaks
    _repsController.dispose();
    _setsController.dispose();
    _intensityController.dispose();
    _rpeController.dispose();
    _weightController.dispose();
    _repsNode.dispose();
    _setsNode.dispose();
    _intensityNode.dispose();
    _rpeNode.dispose();
    _weightNode.dispose();
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
            _buildTextField(_repsController, 'Reps', _repsNode),
            if (!widget.isIndividualEdit) 
              _buildTextField(_setsController, 'Sets', _setsNode),
            _buildTextField(_intensityController, 'Intensità (%)', _intensityNode),
            _buildTextField(_rpeController, 'RPE', _rpeNode),
            _buildTextField(_weightController, 'Peso (kg)', _weightNode),
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

  // Widget to build a text field with label and focus node
  Widget _buildTextField(TextEditingController controller, String label, FocusNode focusNode) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => _updateRelatedFields(),
    );
  }

  // Update related fields based on changes in a field
  void _updateRelatedFields() {
    if (_isRangeInput()) {
      _updateFieldsForRangeInput();
    } else {
      _updateFieldsForSingleInput();
    }
  }

  // Check if any field has range input (e.g., "1-2-3")
  bool _isRangeInput() {
    return _repsController.text.contains('-') ||
           _setsController.text.contains('-') ||
           _intensityController.text.contains('-') ||
           _rpeController.text.contains('-') ||
           _weightController.text.contains('-');
  }

  // Update related fields when range input is detected
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

  // Update related fields when single input is detected
  void _updateFieldsForSingleInput() {
    final reps = int.tryParse(_repsController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final intensity = double.tryParse(_intensityController.text) ?? 0.0;
    final rpe = double.tryParse(_rpeController.text) ?? 0.0;

    switch (_lastEditedField) {
      case 'weight':
        if (weight > 0) {
          _intensityController.text = SeriesUtils.calculateIntensityFromWeight(weight, widget.latestMaxWeight).toStringAsFixed(2);
          _rpeController.text = SeriesUtils.calculateRPE(weight, widget.latestMaxWeight, reps)?.toStringAsFixed(1) ?? '';
        }
        break;
      case 'intensity':
        if (intensity > 0) {
          final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(widget.latestMaxWeight.toDouble(), intensity);
          _weightController.text = SeriesUtils.roundWeight(calculatedWeight, widget.exerciseType).toStringAsFixed(2);
          _rpeController.text = SeriesUtils.calculateRPE(calculatedWeight, widget.latestMaxWeight, reps)?.toStringAsFixed(1) ?? '';
        }
        break;
      case 'rpe':
        if (rpe > 0) {
          final percentage = SeriesUtils.getRPEPercentage(rpe, reps);
          final calculatedWeight = widget.latestMaxWeight.toDouble() * percentage;
          _weightController.text = SeriesUtils.roundWeight(calculatedWeight, widget.exerciseType).toStringAsFixed(2);
          _intensityController.text = SeriesUtils.calculateIntensityFromWeight(calculatedWeight, widget.latestMaxWeight).toStringAsFixed(2);
        }
        break;
    }
  }

  // Update intensity based on a range of weights
  void _updateIntensityForWeightRange() {
    final weights = _parseDoubleList(_weightController.text);
    final intensities = weights.map((weight) =>
      SeriesUtils.calculateIntensityFromWeight(weight, widget.latestMaxWeight).toStringAsFixed(2)
    ).toList();
    _intensityController.text = intensities.join('-');
  }

  // Update weight based on a range of intensities
  void _updateWeightForIntensityRange() {
    final intensities = _parseDoubleList(_intensityController.text);
    final weights = intensities.map((intensity) {
      final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(widget.latestMaxWeight.toDouble(), intensity);
      return SeriesUtils.roundWeight(calculatedWeight, widget.exerciseType).toStringAsFixed(2);
    }).toList();
    _weightController.text = weights.join('-');
  }

  // Update weight based on a range of RPE values
  void _updateWeightForRPERange() {
    final rpes = _parseDoubleList(_rpeController.text);
    final reps = int.tryParse(_repsController.text) ?? 0;
    final weights = rpes.map((rpe) {
      final percentage = SeriesUtils.getRPEPercentage(rpe, reps);
      final calculatedWeight = widget.latestMaxWeight.toDouble() * percentage;
      return SeriesUtils.roundWeight(calculatedWeight, widget.exerciseType).toStringAsFixed(2);
    }).toList();
    _weightController.text = weights.join('-');
  }

  // Handle form submission and create series objects
  void _handleSubmit() {
    final series = _createSeries();
    Navigator.pop(context, series);
  }

  // Create a list of Series objects based on user input
  List<Series> _createSeries() {
    final reps = _parseIntList(_repsController.text);
    final sets = _parseIntList(_setsController.text);
    final intensity = _parseStringList(_intensityController.text);
    final rpe = _parseStringList(_rpeController.text);
    final weight = _parseDoubleList(_weightController.text);

    List<Series> newSeries = [];
    int currentOrder = widget.exercise.series.length + 1;

    // Determine if sets is a range or a single value
    bool isSetsRange = sets.length > 1;
    int totalSets = isSetsRange ? sets.reduce((a, b) => a + b) : sets[0];

    int setCounter = 0;
    int listIndex = 0;

    if (isSetsRange) {
      // Handle sets as a range
      for (int i = 0; i < sets.length; i++) {
        for (int j = 0; j < sets[i]; j++) {
          newSeries.add(_createSerie(reps, intensity, rpe, weight, currentOrder++, listIndex));
          setCounter++;
        }
        listIndex++;
      }
    } else {
      // Handle sets as a single value
      for (int i = 0; i < totalSets; i++) {
        newSeries.add(_createSerie(reps, intensity, rpe, weight, currentOrder++, listIndex));
        listIndex++;
      }
    }

    return newSeries;
  }

  // Helper function to create a single Series object
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

  // Helper functions to parse input strings into lists of ints, strings, and doubles
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