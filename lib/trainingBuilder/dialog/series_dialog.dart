import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/weight_input_fields.dart';
import 'package:alphanessone/UI/components/series_input_fields.dart';

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
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                    maxController: _formController.maxRepsController,
                    label: 'Ripetizioni',
                    hint: 'Ripetizioni',
                    maxHint: 'Max Ripetizioni',
                    icon: Icons.repeat,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.repsNode,
                    maxFocusNode: _formController.maxRepsNode,
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
                    maxController: _formController.maxIntensityController,
                    label: 'Intensità (%)',
                    hint: 'Intensità',
                    maxHint: 'Max Intensità',
                    icon: Icons.speed,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.intensityNode,
                    maxFocusNode: _formController.maxIntensityNode,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  _buildFormField(
                    controller: _formController.rpeController,
                    maxController: _formController.maxRpeController,
                    label: 'RPE',
                    hint: 'RPE',
                    maxHint: 'Max RPE',
                    icon: Icons.trending_up,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.rpeNode,
                    maxFocusNode: _formController.maxRpeNode,
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  _buildFormField(
                    controller: _formController.weightController,
                    maxController: _formController.maxWeightController,
                    label: 'Peso (kg)',
                    hint: 'Peso',
                    maxHint: 'Max Peso',
                    icon: Icons.fitness_center,
                    theme: theme,
                    colorScheme: colorScheme,
                    focusNode: _formController.weightNode,
                    maxFocusNode: _formController.maxWeightNode,
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                            widget.currentSeriesGroup != null
                                ? 'Salva'
                                : 'Aggiungi',
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
    TextEditingController? maxController,
    String? maxHint,
    FocusNode? maxFocusNode,
  }) {
    bool isWeightRelatedField() {
      return label == 'Intensità (%)' || label == 'Peso (kg)';
    }

    void handleFieldChange() {
      if (isWeightRelatedField()) {
        // Se questo campo ha il focus, diventa il master
        if (focusNode.hasFocus) {
          if (label == 'Intensità (%)') {
            _formController.updateWeightFromIntensity();
          } else if (label == 'Peso (kg)') {
            _formController.updateIntensityFromWeight();
          }
          return;
        }

        if (maxFocusNode?.hasFocus == true) {
          if (label == 'Intensità (%)') {
            _formController.updateMaxWeightFromMaxIntensity();
          } else if (label == 'Peso (kg)') {
            _formController.updateMaxIntensityFromMaxWeight();
          }
          return;
        }

        // Se nessun campo peso ha il focus, non fare nulla
        if (_formController.intensityNode.hasFocus ||
            _formController.maxIntensityNode.hasFocus ||
            _formController.weightNode.hasFocus ||
            _formController.maxWeightNode.hasFocus) {
          return;
        }
      }

      // Per tutti gli altri campi, aggiorna normalmente
      _formController.updateRelatedFields();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: colorScheme.primary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing.md),
            ),
            onChanged: (_) => handleFieldChange(),
          ),
        ),
        if (maxController != null &&
            maxFocusNode != null &&
            maxHint != null) ...[
          SizedBox(height: AppTheme.spacing.sm),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: TextField(
              controller: maxController,
              focusNode: maxFocusNode,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                hintText: maxHint,
                prefixIcon: Icon(icon, color: colorScheme.primary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(AppTheme.spacing.md),
              ),
              onChanged: (_) => handleFieldChange(),
            ),
          ),
        ],
      ],
    );
  }

  String _getDialogTitle() {
    if (widget.currentSeriesGroup != null) {
      return widget.isIndividualEdit
          ? 'Modifica Serie'
          : 'Modifica Gruppo Serie';
    }
    return 'Aggiungi Serie';
  }

  void _handleSubmit() {
    final updatedSeries =
        _formController.createSeries(widget.exercise.series.length);
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
  final TextEditingController maxRepsController;
  final TextEditingController setsController;
  final TextEditingController intensityController;
  final TextEditingController maxIntensityController;
  final TextEditingController rpeController;
  final TextEditingController maxRpeController;
  final TextEditingController weightController;
  final TextEditingController maxWeightController;

  final FocusNode repsNode;
  final FocusNode maxRepsNode;
  final FocusNode setsNode;
  final FocusNode intensityNode;
  final FocusNode maxIntensityNode;
  final FocusNode rpeNode;
  final FocusNode maxRpeNode;
  final FocusNode weightNode;
  final FocusNode maxWeightNode;

  final bool isIndividualEdit;
  final num latestMaxWeight;
  final List<Series>? currentSeriesGroup;

  SeriesFormController({
    List<Series>? currentSeriesGroup,
    required this.isIndividualEdit,
    required this.latestMaxWeight,
    required String exerciseType,
  })  : repsController = TextEditingController(),
        maxRepsController = TextEditingController(),
        setsController = TextEditingController(text: '1'),
        intensityController = TextEditingController(),
        maxIntensityController = TextEditingController(),
        rpeController = TextEditingController(),
        maxRpeController = TextEditingController(),
        weightController = TextEditingController(),
        maxWeightController = TextEditingController(),
        repsNode = FocusNode(),
        maxRepsNode = FocusNode(),
        setsNode = FocusNode(),
        intensityNode = FocusNode(),
        maxIntensityNode = FocusNode(),
        rpeNode = FocusNode(),
        maxRpeNode = FocusNode(),
        weightNode = FocusNode(),
        maxWeightNode = FocusNode(),
        currentSeriesGroup = currentSeriesGroup {
    if (currentSeriesGroup != null && currentSeriesGroup.isNotEmpty) {
      final firstSeries = currentSeriesGroup.first;
      repsController.text = firstSeries.reps.toString();
      maxRepsController.text = firstSeries.maxReps?.toString() ?? '';

      if (!isIndividualEdit) {
        setsController.text = currentSeriesGroup.length.toString();
      }

      intensityController.text = firstSeries.intensity ?? '';
      maxIntensityController.text = firstSeries.maxIntensity ?? '';
      rpeController.text = firstSeries.rpe ?? '';
      maxRpeController.text = firstSeries.maxRpe ?? '';
      weightController.text = firstSeries.weight?.toString() ?? '';
      maxWeightController.text = firstSeries.maxWeight?.toString() ?? '';
    }
  }

  void dispose() {
    repsController.dispose();
    maxRepsController.dispose();
    setsController.dispose();
    intensityController.dispose();
    maxIntensityController.dispose();
    rpeController.dispose();
    maxRpeController.dispose();
    weightController.dispose();
    maxWeightController.dispose();

    repsNode.dispose();
    maxRepsNode.dispose();
    setsNode.dispose();
    intensityNode.dispose();
    maxIntensityNode.dispose();
    rpeNode.dispose();
    maxRpeNode.dispose();
    weightNode.dispose();
    maxWeightNode.dispose();
  }

  void updateWeightFromIntensity() {
    final intensity = double.tryParse(intensityController.text) ?? 0.0;
    if (intensity > 0) {
      final weight = (latestMaxWeight * intensity / 100).toStringAsFixed(1);
      weightController.text = weight;
    }
  }

  void updateIntensityFromWeight() {
    final weight = double.tryParse(weightController.text) ?? 0.0;
    if (weight > 0 && latestMaxWeight > 0) {
      final intensity = ((weight / latestMaxWeight) * 100).toStringAsFixed(1);
      intensityController.text = intensity;
    }
  }

  void updateMaxWeightFromMaxIntensity() {
    final maxIntensity = double.tryParse(maxIntensityController.text) ?? 0.0;
    if (maxIntensity > 0) {
      final maxWeight =
          (latestMaxWeight * maxIntensity / 100).toStringAsFixed(1);
      maxWeightController.text = maxWeight;
    }
  }

  void updateMaxIntensityFromMaxWeight() {
    final maxWeight = double.tryParse(maxWeightController.text) ?? 0.0;
    if (maxWeight > 0 && latestMaxWeight > 0) {
      final maxIntensity =
          ((maxWeight / latestMaxWeight) * 100).toStringAsFixed(1);
      maxIntensityController.text = maxIntensity;
    }
  }

  void updateRelatedFields() {
    // Questo metodo rimane per compatibilità ma non fa nulla
    // poiché ora gestiamo gli aggiornamenti in modo più specifico
  }

  List<Series> createSeries(int currentSeriesCount) {
    final reps = int.tryParse(repsController.text) ?? 0;
    final maxReps = int.tryParse(maxRepsController.text);
    final sets = int.tryParse(setsController.text) ?? 1;
    final intensity = intensityController.text;
    final maxIntensity = maxIntensityController.text;
    final rpe = rpeController.text;
    final maxRpe = maxRpeController.text;
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final maxWeight = double.tryParse(maxWeightController.text);

    List<Series> newSeries = [];
    int currentOrder = currentSeriesCount + 1;
    List<String?> existingIds = isIndividualEdit
        ? []
        : currentSeriesGroup?.map((s) => s.serieId).toList() ?? [];

    for (int i = 0; i < sets; i++) {
      String serieId = existingIds.isNotEmpty
          ? existingIds.removeAt(0) ?? generateRandomId(16)
          : generateRandomId(16);

      newSeries.add(Series(
        serieId: serieId,
        reps: reps,
        maxReps: maxReps,
        sets: 1,
        intensity: intensity,
        maxIntensity: maxIntensity.isNotEmpty ? maxIntensity : null,
        rpe: rpe,
        maxRpe: maxRpe.isNotEmpty ? maxRpe : null,
        weight: weight,
        maxWeight: maxWeight,
        order: currentOrder++,
        done: false,
        reps_done: 0,
        weight_done: 0.0,
      ));
    }

    return newSeries;
  }
}
