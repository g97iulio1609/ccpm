import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:alphanessone/Main/app_theme.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: AppTheme.elevations.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Icon(
                      widget.currentSeriesGroup != null 
                          ? Icons.edit_outlined 
                          : Icons.add_circle_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Text(
                    _getDialogTitle(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormField(
                    controller: _formController.repsController,
                    label: 'Ripetizioni',
                    hint: 'Valore singolo, Min/Max o Serie1-Serie2-...',
                    icon: Icons.repeat,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.repsNode,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),

                  if (!_formController.isIndividualEdit) ...[
                    _buildFormField(
                      controller: _formController.setsController,
                      label: 'Serie',
                      hint: 'Numero di serie',
                      icon: Icons.format_list_numbered,
                      theme: theme,
                      colorScheme: colorScheme,
                      focusNode: _formController.setsNode,
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                  ],

                  _buildFormField(
                    controller: _formController.intensityController,
                    label: 'Intensità (%)',
                    hint: 'Percentuale del massimale',
                    icon: Icons.speed,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.intensityNode,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),

                  _buildFormField(
                    controller: _formController.rpeController,
                    label: 'RPE',
                    hint: 'Rating of Perceived Exertion',
                    icon: Icons.trending_up,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.rpeNode,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),

                  _buildFormField(
                    controller: _formController.weightController,
                    label: 'Peso (kg)',
                    hint: 'Peso in chilogrammi',
                    icon: Icons.fitness_center,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.weightNode,
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.lg,
                        vertical: AppTheme.spacing.md,
                      ),
                    ),
                    child: Text(
                      'Annulla',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleSubmit,
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                            vertical: AppTheme.spacing.md,
                          ),
                          child: Text(
                            widget.currentSeriesGroup != null ? 'Salva' : 'Aggiungi',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required FocusNode focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing.md),
            ),
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9./-]')),
            ],
            onChanged: (_) => _formController.updateRelatedFields(),
          ),
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
    final updatedSeries = _formController.createSeries(widget.exercise.series.length);
    if (widget.currentSeriesGroup != null) {
      // Modifica delle serie esistenti
      Navigator.pop(context, {
        'action': 'update',
        'series': updatedSeries,
        'originalGroup': widget.currentSeriesGroup,
      });
    } else {
      // Aggiunta di nuove serie
      Navigator.pop(context, {
        'action': 'add',
        'series': updatedSeries,
      });
    }
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
  final List<Series>? currentSeriesGroup;

  SeriesFormController({
    this.currentSeriesGroup,
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
    if (_isComplexInput()) {
      return _createComplexSeries(currentSeriesCount);
    } else if (_isIntervalInput()) {
      return _createIntervalSeries(currentSeriesCount);
    } else {
      return _createSimpleSeries(currentSeriesCount);
    }
  }

  bool _isComplexInput() {
    return repsController.text.contains('-') ||
           setsController.text.contains('-') ||
           intensityController.text.contains('-') ||
           rpeController.text.contains('-') ||
           weightController.text.contains('-');
  }

  bool _isIntervalInput() {
    return repsController.text.contains('/') ||
           intensityController.text.contains('/') ||
           rpeController.text.contains('/') ||
           weightController.text.contains('/');
  }

  List<Series> _createComplexSeries(int currentSeriesCount) {
    final reps = _parseComplexValues(repsController.text);
    final sets = _parseComplexValues(setsController.text);
    final intensity = _parseComplexValues(intensityController.text);
    final rpe = _parseComplexValues(rpeController.text);
    final weight = _parseComplexValues(weightController.text);

    int totalSets = sets.length == 1 ? sets[0][0].toInt() : sets.map((s) => s[0].toInt()).reduce((a, b) => a + b);
    List<Series> newSeries = [];
    int currentOrder = currentSeriesCount + 1;
    List<String?> existingIds = isIndividualEdit ? [] : currentSeriesGroup?.map((s) => s.serieId).toList() ?? [];

    for (int i = 0; i < reps.length; i++) {
      int currentSets = sets.length == 1 ? (totalSets ~/ reps.length) : sets[i][0].toInt();
      for (int j = 0; j < currentSets; j++) {
        String serieId = existingIds.isNotEmpty ? existingIds.removeAt(0) ?? generateRandomId(16) : generateRandomId(16);
        newSeries.add(Series(
          serieId: serieId,
          reps: reps[i][0].toInt(),
          sets: 1,
          intensity: intensity[i][0].toString(),
          rpe: rpe.length > i ? rpe[i][0].toString() : '',
          weight: weight[i][0],
          order: currentOrder++,
          done: false,
          reps_done: 0,
          weight_done: 0.0,
          maxReps: reps[i].length > 1 ? reps[i][1].toInt() : null,
          maxSets: null,
          maxIntensity: intensity[i].length > 1 ? intensity[i][1].toString() : null,
          maxRpe: rpe.length > i && rpe[i].length > 1 ? rpe[i][1].toString() : null,
          maxWeight: weight[i].length > 1 ? weight[i][1] : null,
        ));
      }
    }

    return newSeries;
  }

  List<Series> _createIntervalSeries(int currentSeriesCount) {
    final reps = _parseIntervalValues(repsController.text);
    final sets = int.tryParse(setsController.text) ?? 1;
    final intensity = _parseIntervalValues(intensityController.text);
    final rpe = _parseIntervalValues(rpeController.text);
    final weight = _parseIntervalValues(weightController.text);

    List<Series> newSeries = [];
    int currentOrder = currentSeriesCount + 1;
    List<String?> existingIds = isIndividualEdit ? [] : currentSeriesGroup?.map((s) => s.serieId).toList() ?? [];

    for (int i = 0; i < sets; i++) {
      String serieId = existingIds.isNotEmpty ? existingIds.removeAt(0) ?? generateRandomId(16) : generateRandomId(16);
      newSeries.add(Series(
        serieId: serieId,
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

  List<Series> _createSimpleSeries(int currentSeriesCount) {
    final reps = int.tryParse(repsController.text) ?? 0;
    final sets = int.tryParse(setsController.text) ?? 1;
    final intensity = intensityController.text;
    final rpe = rpeController.text;
    final weight = double.tryParse(weightController.text) ?? 0.0;

    List<Series> newSeries = [];
    int currentOrder = currentSeriesCount + 1;
    List<String?> existingIds = isIndividualEdit ? [] : currentSeriesGroup?.map((s) => s.serieId).toList() ?? [];

    for (int i = 0; i < sets; i++) {
      String serieId = existingIds.isNotEmpty ? existingIds.removeAt(0) ?? generateRandomId(16) : generateRandomId(16);
      newSeries.add(Series(
        serieId: serieId,
        reps: reps,
        sets: 1,
        intensity: intensity,
        rpe: rpe,
        weight: weight,
        order: currentOrder++,
        done: false,
        reps_done: 0,
        weight_done: 0.0,
      ));
    }

    return newSeries;
  }

  List<List<double>> _parseComplexValues(String input) {
    if (input.isEmpty || input == '-' || input == '/') {
      return [[0.0]];
    }

    List<String> groups = input.split('-');
    return groups.map((group) {
      List<String> parts = group.split('/');
      return parts.map((part) => _parseDouble(part.trim())).toList();}).toList();
  }

  List<double> _parseIntervalValues(String input) {
    if (input.isEmpty || input == '-' || input == '/') {
      return [0.0];
    }

    List<String> parts = input.split('/');
    return parts.map((part) => _parseDouble(part.trim())).toList();
  }

  double _parseDouble(String value) {
    if (value.isEmpty || value == '-' || value == '/') {
      return 0.0;
    }
    return double.tryParse(value) ?? 0.0;
  }

  void updateRelatedFields() {
    if (_isComplexInput()) {
      _updateFieldsForComplexInput();
    } else if (_isIntervalInput()) {
      _updateFieldsForIntervalInput();
    } else {
      _updateFieldsForSingleInput();
    }
  }

  bool _isValidInput(String input) {
    return input.isNotEmpty && input != '-' && input != '/';
  }

  void _updateFieldsForComplexInput() {
    switch (_lastEditedField) {
      case 'weight':
        if (_isValidInput(weightController.text)) {
          _updateIntensityAndRPEForComplexWeight();
        }
        break;
      case 'intensity':
        if (_isValidInput(intensityController.text)) {
          _updateWeightAndRPEForComplexIntensity();
        }
        break;
      case 'rpe':
        if (_isValidInput(rpeController.text)) {
          _updateWeightAndIntensityForComplexRPE();
        }
        break;
    }
  }

  void _updateIntensityAndRPEForComplexWeight() {
    final weights = _parseComplexValues(weightController.text);
    final reps = _parseComplexValues(repsController.text);
    final intensities = weights.map((weightGroup) =>
      weightGroup.map((weight) =>
        SeriesUtils.calculateIntensityFromWeight(weight, latestMaxWeight).toStringAsFixed(2)
      ).join('/')
    ).toList();
    final rpes = List.generate(weights.length, (index) {
      final repsGroup = index < reps.length ? reps[index] : reps.last;
      return weights[index].map((weight) {
        final repsValue = repsGroup[0].toInt();
        return SeriesUtils.calculateRPE(weight, latestMaxWeight, repsValue)?.toStringAsFixed(1) ?? '';
      }).join('/');
    });
    intensityController.text = intensities.join('-');
    rpeController.text = rpes.join('-');
  }

  void _updateWeightAndRPEForComplexIntensity() {
    final intensities = _parseComplexValues(intensityController.text);
    final reps = _parseComplexValues(repsController.text);
    final weights = intensities.map((intensityGroup) =>
      intensityGroup.map((intensity) {
        final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
        return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
      }).join('/')
    ).toList();
    final rpes = List.generate(intensities.length, (index) {
      final repsGroup = index < reps.length ? reps[index] : reps.last;
      return intensities[index].map((intensity) {
        final weight = SeriesUtils.calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
        final repsValue = repsGroup[0].toInt();
        return SeriesUtils.calculateRPE(weight, latestMaxWeight, repsValue)?.toStringAsFixed(1) ?? '';
      }).join('/');
    });
    weightController.text = weights.join('-');
    rpeController.text = rpes.join('-');
  }

  void _updateWeightAndIntensityForComplexRPE() {
    final rpes = _parseComplexValues(rpeController.text);
    final reps = _parseComplexValues(repsController.text);
    final weights = List.generate(rpes.length, (index) {
      final repsGroup = index < reps.length ? reps[index] : reps.last;
      return rpes[index].map((rpe) {
        final repsValue = repsGroup[0].toInt();
        final percentage = SeriesUtils.getRPEPercentage(rpe, repsValue);
        final calculatedWeight = latestMaxWeight.toDouble() * percentage;
        return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
      }).join('/');
    });
    final intensities = weights.map((weightGroup) =>
      weightGroup.split('/').map((weight) =>
        SeriesUtils.calculateIntensityFromWeight(double.parse(weight), latestMaxWeight).toStringAsFixed(2)
      ).join('/')
    ).toList();
    weightController.text = weights.join('-');
    intensityController.text = intensities.join('-');
  }

  void _updateFieldsForIntervalInput() {
    switch (_lastEditedField) {
      case 'weight':
        if (_isValidInput(weightController.text)) {
          _updateIntensityAndRPEForWeightInterval();
        }
        break;
      case 'intensity':
        if (_isValidInput(intensityController.text)) {
          _updateWeightAndRPEForIntensityInterval();
        }
        break;
      case 'rpe':
        if (_isValidInput(rpeController.text)) {
          _updateWeightAndIntensityForRPEInterval();
        }
        break;
    }
  }

  void _updateIntensityAndRPEForWeightInterval() {
    final weights = _parseIntervalValues(weightController.text);
    final reps = int.tryParse(repsController.text.split('/')[0]) ?? 0;
    final intensities = weights.map((weight) =>
      SeriesUtils.calculateIntensityFromWeight(weight, latestMaxWeight).toStringAsFixed(2)
    ).toList();
    final rpes = weights.map((weight) =>
      SeriesUtils.calculateRPE(weight, latestMaxWeight, reps)?.toStringAsFixed(1) ?? ''
    ).toList();
    intensityController.text = intensities.join('/');
    rpeController.text = rpes.join('/');
  }

  void _updateWeightAndRPEForIntensityInterval() {
    final intensities = _parseIntervalValues(intensityController.text);
    final reps = int.tryParse(repsController.text.split('/')[0]) ?? 0;
    final weights = intensities.map((intensity) {
      final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
      return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
    }).toList();
    final rpes = weights.map((weight) =>
      SeriesUtils.calculateRPE(double.parse(weight), latestMaxWeight, reps)?.toStringAsFixed(1) ?? ''
    ).toList();
    weightController.text = weights.join('/');
    rpeController.text = rpes.join('/');
  }

  void _updateWeightAndIntensityForRPEInterval() {
    final rpes = _parseIntervalValues(rpeController.text);
    final reps = int.tryParse(repsController.text.split('/')[0]) ?? 0;
    final weights = rpes.map((rpe) {
      final percentage = SeriesUtils.getRPEPercentage(rpe, reps);
      final calculatedWeight = latestMaxWeight.toDouble() * percentage;
      return SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
    }).toList();
    final intensities = weights.map((weight) =>
      SeriesUtils.calculateIntensityFromWeight(double.parse(weight), latestMaxWeight).toStringAsFixed(2)
    ).toList();
    weightController.text = weights.join('/');
    intensityController.text = intensities.join('/');
  }

  void _updateFieldsForSingleInput() {
    final reps = int.tryParse(repsController.text) ?? 0;
    final weight = _parseDouble(weightController.text);
    final intensity = _parseDouble(intensityController.text);
    final rpe = _parseDouble(rpeController.text);

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
        if (rpe > 0 && reps > 0) {
          final percentage = SeriesUtils.getRPEPercentage(rpe, reps);
          final calculatedWeight = latestMaxWeight.toDouble() * percentage;
          weightController.text = SeriesUtils.roundWeight(calculatedWeight, exerciseType).toStringAsFixed(2);
          intensityController.text = SeriesUtils.calculateIntensityFromWeight(calculatedWeight, latestMaxWeight).toStringAsFixed(2);
        }
        break;
      case 'reps':
        if (rpe > 0 && reps > 0) {
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