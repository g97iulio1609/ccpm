import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

import 'package:alphanessone/shared/services/weight_calculation_service.dart';
import '../../../shared/widgets/number_input_field.dart';

class SeriesFormFields extends StatefulWidget {
  final Series series;
  final num maxWeight;
  final String exerciseName;
  final Function(Series)? onSeriesUpdated;

  const SeriesFormFields({
    super.key,
    required this.series,
    required this.maxWeight,
    required this.exerciseName,
    this.onSeriesUpdated,
  });

  @override
  State<SeriesFormFields> createState() => _SeriesFormFieldsState();
}

class _SeriesFormFieldsState extends State<SeriesFormFields> {
  late TextEditingController _repsController;
  late TextEditingController _maxRepsController;
  late TextEditingController _setsController;
  late TextEditingController _intensityController;
  late TextEditingController _maxIntensityController;
  late TextEditingController _rpeController;
  late TextEditingController _maxRpeController;
  late TextEditingController _weightController;
  late TextEditingController _maxWeightController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _repsController = TextEditingController(
      text: widget.series.reps.toString(),
    );
    _maxRepsController = TextEditingController(
      text: widget.series.maxReps?.toString() ?? '',
    );
    _setsController = TextEditingController(
      text: widget.series.sets.toString(),
    );
    _intensityController = TextEditingController(text: widget.series.intensity ?? '');
    _maxIntensityController = TextEditingController(
      text: widget.series.maxIntensity ?? '',
    );
    _rpeController = TextEditingController(text: widget.series.rpe ?? '');
    _maxRpeController = TextEditingController(text: widget.series.maxRpe ?? '');
    _weightController = TextEditingController(
      text: widget.series.weight.toString(),
    );
    _maxWeightController = TextEditingController(
      text: widget.series.maxWeight?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _repsController.dispose();
    _maxRepsController.dispose();
    _setsController.dispose();
    _intensityController.dispose();
    _maxIntensityController.dispose();
    _rpeController.dispose();
    _maxRpeController.dispose();
    _weightController.dispose();
    _maxWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildRangeField(
                label: 'Ripetizioni',
                controller: _repsController,
                maxController: _maxRepsController,
                icon: Icons.repeat,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: NumberInputField(
                label: 'Sets',
                controller: _setsController,
                icon: Icons.format_list_numbered,
                onChanged: (value) => _updateSeries(),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.md),
        Row(
          children: [
            Expanded(
              child: _buildRangeField(
                label: 'Intensità (%)',
                controller: _intensityController,
                maxController: _maxIntensityController,
                icon: Icons.speed,
                theme: theme,
                colorScheme: colorScheme,
                onChanged: _onIntensityChanged,
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: _buildRangeField(
                label: 'RPE',
                controller: _rpeController,
                maxController: _maxRpeController,
                icon: Icons.trending_up,
                theme: theme,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.md),
        _buildRangeField(
          label: 'Peso (kg)',
          controller: _weightController,
          maxController: _maxWeightController,
          icon: Icons.fitness_center,
          theme: theme,
          colorScheme: colorScheme,
          onChanged: _onWeightChanged,
        ),
      ],
    );
  }

  Widget _buildRangeField({
    required String label,
    required TextEditingController controller,
    required TextEditingController maxController,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    VoidCallback? onChanged,
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
        Row(
          children: [
            Expanded(
              child: NumberInputField(
                label: 'Min',
                controller: controller,
                icon: icon,
                onChanged: (value) {
                  onChanged?.call();
                  _updateSeries();
                },
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: NumberInputField(
                label: 'Max',
                controller: maxController,
                icon: Icons.arrow_upward,
                onChanged: (value) {
                  onChanged?.call();
                  _updateSeries();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onIntensityChanged() {
    final intensity = double.tryParse(_intensityController.text) ?? 0.0;
    if (intensity > 0 && widget.maxWeight > 0) {
      final weight = WeightCalculationService.calculateWeightFromIntensity(
        widget.maxWeight.toDouble(),
        intensity,
      );
      _weightController.text = weight.toStringAsFixed(1);

      final maxIntensity = double.tryParse(_maxIntensityController.text);
      if (maxIntensity != null && maxIntensity > 0) {
        final maxWeight = WeightCalculationService.calculateWeightFromIntensity(
          widget.maxWeight.toDouble(),
          maxIntensity,
        );
        _maxWeightController.text = maxWeight.toStringAsFixed(1);
      }
    }
  }

  void _onWeightChanged() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    if (weight > 0 && widget.maxWeight > 0) {
      final intensity = WeightCalculationService.calculateIntensityFromWeight(
        weight,
        widget.maxWeight.toDouble(),
      );
      _intensityController.text = intensity.toStringAsFixed(1);

      final maxWeight = double.tryParse(_maxWeightController.text);
      if (maxWeight != null && maxWeight > 0) {
        final maxIntensity =
            WeightCalculationService.calculateIntensityFromWeight(
              maxWeight,
              widget.maxWeight.toDouble(),
            );
        _maxIntensityController.text = maxIntensity.toStringAsFixed(1);
      }
    }
  }

  void _updateSeries() {
    if (widget.onSeriesUpdated != null) {
      final updatedSeries = widget.series.copyWith(
        reps: int.tryParse(_repsController.text) ?? widget.series.reps,
        maxReps: int.tryParse(_maxRepsController.text),
        sets: int.tryParse(_setsController.text) ?? widget.series.sets,
        intensity: _intensityController.text.isNotEmpty ? _intensityController.text : null,
        maxIntensity: _maxIntensityController.text.isNotEmpty
            ? _maxIntensityController.text
            : null,
        rpe: _rpeController.text.isNotEmpty ? _rpeController.text : null,
        maxRpe: _maxRpeController.text.isNotEmpty
            ? _maxRpeController.text
            : null,
        weight: double.tryParse(_weightController.text) ?? widget.series.weight,
        maxWeight: double.tryParse(_maxWeightController.text),
      );
      widget.onSeriesUpdated!(updatedSeries);
    }
  }
}
