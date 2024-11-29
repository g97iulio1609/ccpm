import 'package:alphanessone/Main/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WeightInputFields extends HookConsumerWidget {
  final num maxWeight;
  final String? intensity;
  final String? maxIntensity;
  final Function(double weight) onWeightChanged;
  final Function(double? maxWeight) onMaxWeightChanged;
  final String? initialWeight;
  final String? initialMaxWeight;
  final String exerciseName;

  const WeightInputFields({
    super.key,
    required this.maxWeight,
    required this.intensity,
    required this.maxIntensity,
    required this.onWeightChanged,
    required this.onMaxWeightChanged,
    required this.exerciseName,
    this.initialWeight,
    this.initialMaxWeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightController = useTextEditingController();
    final maxWeightController = useTextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    // Calcola i pesi basati su intensità
    final minIntensity = double.tryParse(intensity ?? '') ?? 0;
    final maxIntensityValue = double.tryParse(maxIntensity ?? '');

    final calculatedWeight =
        maxWeight > 0 ? (maxWeight.toDouble() * minIntensity / 100) : 0;
    final calculatedMaxWeight = maxIntensityValue != null && maxWeight > 0
        ? (maxWeight.toDouble() * maxIntensityValue / 100)
        : null;

    // Imposta i valori iniziali dei controller
    useEffect(() {
      if (initialWeight != null) {
        weightController.text = initialWeight!;
      } else {
        weightController.text = calculatedWeight.toStringAsFixed(1);
      }

      if (initialMaxWeight != null) {
        maxWeightController.text = initialMaxWeight!;
      } else if (calculatedMaxWeight != null) {
        maxWeightController.text = calculatedMaxWeight.toStringAsFixed(1);
      }
      return null;
    }, [calculatedWeight, calculatedMaxWeight]);

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
            SizedBox(height: AppTheme.spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Peso (kg)',
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
                    },
                  ),
                ),
                SizedBox(width: AppTheme.spacing.md),
                Expanded(
                  child: TextField(
                    controller: maxWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Peso Max (kg)',
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
