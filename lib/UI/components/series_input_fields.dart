import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../Main/app_theme.dart';

class SeriesInputFields extends HookConsumerWidget {
  final num maxWeight;
  final String exerciseName;
  final String? initialIntensity;
  final String? initialMaxIntensity;
  final String? initialRpe;
  final String? initialMaxRpe;
  final String? initialWeight;
  final String? initialMaxWeight;
  final Function(double intensity) onIntensityChanged;
  final Function(double? maxIntensity) onMaxIntensityChanged;
  final Function(double rpe) onRpeChanged;
  final Function(double? maxRpe) onMaxRpeChanged;
  final Function(double weight) onWeightChanged;
  final Function(double? maxWeight) onMaxWeightChanged;

  const SeriesInputFields({
    super.key,
    required this.maxWeight,
    required this.exerciseName,
    required this.onIntensityChanged,
    required this.onMaxIntensityChanged,
    required this.onRpeChanged,
    required this.onMaxRpeChanged,
    required this.onWeightChanged,
    required this.onMaxWeightChanged,
    this.initialIntensity,
    this.initialMaxIntensity,
    this.initialRpe,
    this.initialMaxRpe,
    this.initialWeight,
    this.initialMaxWeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intensityController =
        useTextEditingController(text: initialIntensity);
    final maxIntensityController =
        useTextEditingController(text: initialMaxIntensity);
    final rpeController = useTextEditingController(text: initialRpe);
    final maxRpeController = useTextEditingController(text: initialMaxRpe);
    final weightController = useTextEditingController(text: initialWeight);
    final maxWeightController =
        useTextEditingController(text: initialMaxWeight);

    final colorScheme = Theme.of(context).colorScheme;

    // Funzione per calcolare il peso dall'intensità
    void updateWeightFromIntensity(String intensity, [String? maxIntensity]) {
      final intensityValue = double.tryParse(intensity) ?? 0;
      final calculatedWeight =
          maxWeight > 0 ? (maxWeight.toDouble() * intensityValue / 100) : 0.0;
      weightController.text = calculatedWeight.toStringAsFixed(1);
      onWeightChanged(calculatedWeight);

      if (maxIntensity != null && maxIntensity.isNotEmpty) {
        final maxIntensityValue = double.tryParse(maxIntensity) ?? 0;
        final calculatedMaxWeight = maxWeight > 0
            ? (maxWeight.toDouble() * maxIntensityValue / 100)
            : 0.0;
        maxWeightController.text = calculatedMaxWeight.toStringAsFixed(1);
        onMaxWeightChanged(calculatedMaxWeight);
      } else {
        maxWeightController.text = '';
        onMaxWeightChanged(null);
      }
    }

    // Funzione per calcolare l'intensità dal peso
    void updateIntensityFromWeight(String weightStr, [String? maxWeightStr]) {
      final weightValue = double.tryParse(weightStr) ?? 0;
      final maxWeightRef = maxWeight.toDouble();

      if (maxWeightRef > 0) {
        final intensityValue = (weightValue / maxWeightRef) * 100;
        intensityController.text = intensityValue.toStringAsFixed(1);
        onIntensityChanged(intensityValue);
      }

      if (maxWeightStr != null && maxWeightStr.isNotEmpty) {
        final maxWeightValue = double.tryParse(maxWeightStr) ?? 0;
        if (maxWeightRef > 0) {
          final maxIntensityValue = (maxWeightValue / maxWeightRef) * 100;
          maxIntensityController.text = maxIntensityValue.toStringAsFixed(1);
          onMaxIntensityChanged(maxIntensityValue);
        }
      } else {
        maxIntensityController.text = '';
        onMaxIntensityChanged(null);
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exerciseName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (maxWeight > 0)
                  Text(
                    'Max: ${maxWeight.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.md),

            // Intensità
            Text(
              'Intensità (%)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppTheme.spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: intensityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Intensità',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.sm,
                      ),
                    ),
                    onChanged: (value) {
                      final intensity = double.tryParse(value) ?? 0;
                      onIntensityChanged(intensity);
                      updateWeightFromIntensity(
                          value, maxIntensityController.text);
                    },
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  child: TextField(
                    controller: maxIntensityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Intensità Max',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.sm,
                      ),
                    ),
                    onChanged: (value) {
                      final maxIntensity = double.tryParse(value);
                      onMaxIntensityChanged(maxIntensity);
                      updateWeightFromIntensity(
                          intensityController.text, value);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.md),

            // RPE
            Text(
              'RPE',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppTheme.spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rpeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'RPE',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.sm,
                      ),
                    ),
                    onChanged: (value) {
                      final rpe = double.tryParse(value) ?? 0;
                      onRpeChanged(rpe);
                    },
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  child: TextField(
                    controller: maxRpeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'RPE Max',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.sm,
                      ),
                    ),
                    onChanged: (value) {
                      final maxRpe = double.tryParse(value);
                      onMaxRpeChanged(maxRpe);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.md),

            // Peso
            Text(
              'Peso (kg)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            SizedBox(height: AppTheme.spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Peso',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.sm,
                      ),
                    ),
                    onChanged: (value) {
                      final weight = double.tryParse(value) ?? 0;
                      onWeightChanged(weight);
                      updateIntensityFromWeight(
                          value, maxWeightController.text);
                    },
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  child: TextField(
                    controller: maxWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Peso Max',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.sm,
                      ),
                    ),
                    onChanged: (value) {
                      final maxWeight = double.tryParse(value);
                      onMaxWeightChanged(maxWeight);
                      updateIntensityFromWeight(weightController.text, value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
