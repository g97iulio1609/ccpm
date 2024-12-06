import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:alphanessone/Main/app_theme.dart';

class SeriesDialog extends StatefulWidget {
  final ExerciseRecordService exerciseRecordService;
  final String athleteId;
  final String exerciseId; // This is the original exercise ID
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
      originalExerciseId:
          widget.exercise.exerciseId, // Pass the original exercise ID
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDialogTitle(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon:
                        Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
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
                    child: Text(
                      'Annulla',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  FilledButton(
                    onPressed: _handleSubmit,
                    child: Text(
                      'Conferma',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimary,
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
        _formController.createSeries(widget.currentSeriesGroup?.length ?? widget.exercise.series.length);
    
    // Se stiamo modificando serie esistenti, manteniamo gli ID originali
    if (widget.currentSeriesGroup != null) {
      for (var i = 0; i < updatedSeries.length; i++) {
        updatedSeries[i] = updatedSeries[i].copyWith(
          id: i < widget.currentSeriesGroup!.length ? widget.currentSeriesGroup![i].id : null,
          originalExerciseId: i < widget.currentSeriesGroup!.length ? widget.currentSeriesGroup![i].originalExerciseId : widget.exercise.id,
          order: i < widget.currentSeriesGroup!.length ? widget.currentSeriesGroup![i].order : i,
        );
      }
    }
    
    Navigator.pop(context, updatedSeries);
  }
}

class SeriesFormController {
  final TextEditingController repsController = TextEditingController();
  final TextEditingController maxRepsController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController intensityController = TextEditingController();
  final TextEditingController maxIntensityController = TextEditingController();
  final TextEditingController rpeController = TextEditingController();
  final TextEditingController maxRpeController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController maxWeightController = TextEditingController();

  final FocusNode repsNode = FocusNode();
  final FocusNode maxRepsNode = FocusNode();
  final FocusNode setsNode = FocusNode();
  final FocusNode intensityNode = FocusNode();
  final FocusNode maxIntensityNode = FocusNode();
  final FocusNode rpeNode = FocusNode();
  final FocusNode maxRpeNode = FocusNode();
  final FocusNode weightNode = FocusNode();
  final FocusNode maxWeightNode = FocusNode();

  final List<Series>? currentSeriesGroup;
  final bool isIndividualEdit;
  final num latestMaxWeight;
  final String? originalExerciseId;

  SeriesFormController({
    this.currentSeriesGroup,
    required this.isIndividualEdit,
    required this.latestMaxWeight,
    this.originalExerciseId,
  }) {
    if (currentSeriesGroup != null && currentSeriesGroup!.isNotEmpty) {
      final firstSeries = currentSeriesGroup!.first;
      repsController.text = firstSeries.reps.toString();
      setsController.text = currentSeriesGroup!.length.toString();
      intensityController.text = firstSeries.intensity;
      rpeController.text = firstSeries.rpe;
      weightController.text = firstSeries.weight.toString();

      if (firstSeries.maxReps != null) {
        maxRepsController.text = firstSeries.maxReps.toString();
      }
      if (firstSeries.maxIntensity != null) {
        maxIntensityController.text = firstSeries.maxIntensity!;
      }
      if (firstSeries.maxRpe != null) {
        maxRpeController.text = firstSeries.maxRpe!;
      }
      if (firstSeries.maxWeight != null) {
        maxWeightController.text = firstSeries.maxWeight.toString();
      }
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
        originalExerciseId: originalExerciseId,
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
