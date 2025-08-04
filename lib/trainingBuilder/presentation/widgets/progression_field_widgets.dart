import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/progression_components.dart';
import 'package:alphanessone/trainingBuilder/controllers/progression_controllers.dart';
import 'package:alphanessone/trainingBuilder/models/progression_view_model.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/services/progression_service.dart';

/// Widget for progression group fields following single responsibility principle
class ProgressionGroupFields extends StatelessWidget {
  final ProgressionControllers controllers;
  final Exercise exercise;
  final num latestMaxWeight;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isSmallScreen;
  final ValueChanged<SeriesUpdateParams> onUpdateSeries;
  final SeriesUpdateParams updateParams;

  const ProgressionGroupFields({
    super.key,
    required this.controllers,
    required this.exercise,
    required this.latestMaxWeight,
    required this.colorScheme,
    required this.theme,
    required this.isSmallScreen,
    required this.onUpdateSeries,
    required this.updateParams,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reps field
        Expanded(
          child: _buildRepsField(context),
        ),
        SizedBox(width: AppTheme.spacing.xs),
        // Sets field
        Expanded(
          child: _buildSetsField(),
        ),
        SizedBox(width: AppTheme.spacing.xs),
        // Load field
        Expanded(
          flex: isSmallScreen ? 2 : 1,
          child: _buildLoadField(context),
        ),
      ],
    );
  }

  Widget _buildRepsField(BuildContext context) {
    return ProgressionFieldContainer(
      label: 'Reps',
      value: controllers.reps.displayText,
      onTap: () => _showRepsDialog(context),
      colorScheme: colorScheme,
      theme: theme,
      isLoadField: false,
      isSmallScreen: isSmallScreen,
    );
  }

  Widget _buildSetsField() {
    return ProgressionTextField(
      controller: controllers.sets,
      labelText: 'Sets',
      keyboardType: TextInputType.number,
      onChanged: (value) => onUpdateSeries(
        updateParams.copyWith(sets: value),
      ),
      colorScheme: colorScheme,
      theme: theme,
    );
  }

  Widget _buildLoadField(BuildContext context) {
    return ProgressionFieldContainer(
      label: 'Load',
      value: controllers.getLoadDisplayText(latestMaxWeight.toDouble()),
      onTap: () => _showLoadDialog(context),
      colorScheme: colorScheme,
      theme: theme,
      isLoadField: true,
      isSmallScreen: isSmallScreen,
    );
  }

  void _showRepsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgressionRangeEditDialog(
        title: 'Ripetizioni',
        initialMin: controllers.reps.min.text,
        initialMax: controllers.reps.max.text,
        onSave: (min, max) {
          if (min != null) controllers.reps.min.text = min;
          if (max != null) controllers.reps.max.text = max;

          onUpdateSeries(updateParams.copyWith(
            reps: min,
            maxReps: max,
          ));

          Navigator.pop(context);
        },
        onChanged: (min, max) {
          // Real-time update se necessario
        },
      ),
    );
  }

  void _showLoadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgressionCombinedLoadDialog(
        intensityControllers: controllers.intensity,
        rpeControllers: controllers.rpe,
        weightControllers: controllers.weight,
        colorScheme: colorScheme,
        theme: theme,
        onRealTimeUpdate: (type, minValue, maxValue, field) {
          _handleLoadUpdate(
            LoadUpdateParams(
              type: type,
              minValue: minValue,
              maxValue: maxValue,
              field: field,
            ),
            context,
          );
        },
      ),
    );
  }

  void _handleLoadUpdate(LoadUpdateParams params, BuildContext context) {
    try {
      switch (params.type) {
        case 'Intensity':
          _handleIntensityUpdate(params);
          break;
        case 'Weight':
          _handleWeightUpdate(params);
          break;
        case 'RPE':
          _handleRpeUpdate(params);
          break;
        default:
          debugPrint('WARNING: Unknown load update type: ${params.type}');
      }
    } catch (e) {
      debugPrint('ERROR: Failed to handle load update: $e');
      // Show user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating load: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleIntensityUpdate(LoadUpdateParams params) {
    try {
      ProgressionService.updateWeightFromIntensity(
        minIntensity: params.minValue,
        maxIntensity: params.maxValue,
        latestMaxWeight: latestMaxWeight.toDouble(),
        exerciseType: exercise.type,
        onUpdate: (minWeight, maxWeight) {
          _updateControllersSafely(
            weightMin: minWeight,
            weightMax: maxWeight,
            intensityMin: params.minValue,
            intensityMax: params.maxValue,
          );
        },
      );
    } catch (e) {
      throw Exception('Failed to update intensity: $e');
    }
  }

  void _handleWeightUpdate(LoadUpdateParams params) {
    try {
      ProgressionService.updateIntensityFromWeight(
        minWeight: params.minValue,
        maxWeight: params.maxValue,
        latestMaxWeight: latestMaxWeight.toDouble(),
        onUpdate: (minIntensity, maxIntensity) {
          _updateControllersSafely(
            weightMin: params.minValue,
            weightMax: params.maxValue,
            intensityMin: minIntensity,
            intensityMax: maxIntensity,
          );
        },
      );
    } catch (e) {
      throw Exception('Failed to update weight: $e');
    }
  }

  void _handleRpeUpdate(LoadUpdateParams params) {
    try {
      _updateControllersSafely(
        rpeMin: params.minValue,
        rpeMax: params.maxValue,
      );
    } catch (e) {
      throw Exception('Failed to update RPE: $e');
    }
  }

  /// Safely updates controllers and triggers series update
  void _updateControllersSafely({
    String? weightMin,
    String? weightMax,
    String? intensityMin,
    String? intensityMax,
    String? rpeMin,
    String? rpeMax,
  }) {
    try {
      // Update controllers if values are provided
      if (weightMin != null) controllers.weight.min.text = weightMin;
      if (weightMax != null) controllers.weight.max.text = weightMax;
      if (intensityMin != null) controllers.intensity.min.text = intensityMin;
      if (intensityMax != null) controllers.intensity.max.text = intensityMax;

      // Create update parameters safely
      final seriesUpdateParams = SeriesUpdateParams(
        weekIndex: updateParams.weekIndex,
        sessionIndex: updateParams.sessionIndex,
        groupIndex: updateParams.groupIndex,
        intensity: intensityMin?.isNotEmpty == true ? intensityMin : null,
        maxIntensity: intensityMax?.isNotEmpty == true ? intensityMax : null,
        weight: weightMin?.isNotEmpty == true ? weightMin : null,
        maxWeight: weightMax?.isNotEmpty == true ? weightMax : null,
        rpe: rpeMin?.isNotEmpty == true ? rpeMin : null,
        maxRpe: rpeMax?.isNotEmpty == true ? rpeMax : null,
      );

      onUpdateSeries(seriesUpdateParams);
    } catch (e) {
      throw Exception('Failed to update controllers: $e');
    }
  }
}

/// Extension to add copyWith method to SeriesUpdateParams
extension SeriesUpdateParamsExtension on SeriesUpdateParams {
  SeriesUpdateParams copyWith({
    int? weekIndex,
    int? sessionIndex,
    int? groupIndex,
    String? reps,
    String? maxReps,
    String? sets,
    String? intensity,
    String? maxIntensity,
    String? rpe,
    String? maxRpe,
    String? weight,
    String? maxWeight,
  }) {
    return SeriesUpdateParams(
      weekIndex: weekIndex ?? this.weekIndex,
      sessionIndex: sessionIndex ?? this.sessionIndex,
      groupIndex: groupIndex ?? this.groupIndex,
      reps: reps ?? this.reps,
      maxReps: maxReps ?? this.maxReps,
      sets: sets ?? this.sets,
      intensity: intensity ?? this.intensity,
      maxIntensity: maxIntensity ?? this.maxIntensity,
      rpe: rpe ?? this.rpe,
      maxRpe: maxRpe ?? this.maxRpe,
      weight: weight ?? this.weight,
      maxWeight: maxWeight ?? this.maxWeight,
    );
  }
}
