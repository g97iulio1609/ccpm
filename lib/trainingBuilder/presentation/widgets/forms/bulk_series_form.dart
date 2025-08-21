import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

import 'package:alphanessone/shared/services/weight_calculation_service.dart';

import 'package:alphanessone/providers/providers.dart';
import '../../../shared/widgets/number_input_field.dart';
import 'package:alphanessone/UI/components/button.dart';

class BulkSeriesForm extends HookConsumerWidget {
  final List<Exercise> exercises;
  final Function(List<Exercise>) onApply;

  const BulkSeriesForm({super.key, required this.exercises, required this.onApply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Controllers per i campi del form
    final repsController = useTextEditingController();
    final maxRepsController = useTextEditingController();
    final setsController = useTextEditingController(text: '1');
    final intensityController = useTextEditingController();
    final maxIntensityController = useTextEditingController();
    final rpeController = useTextEditingController();
    final maxRpeController = useTextEditingController();

    // Stato per i massimali
    final maxWeights = useState<Map<String, num>>({});

    // Carica i massimali all'inizializzazione
    useEffect(() {
      Future<void> loadMaxWeights() async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        final Map<String, num> weights = {};
        for (var exercise in exercises) {
          if (exercise.exerciseId != null) {
            final record = await exerciseRecordService.getLatestExerciseRecord(
              userId: currentUser.uid,
              exerciseId: exercise.exerciseId!,
            );
            weights[exercise.exerciseId!] = record?.maxWeight ?? 0;
          }
        }
        maxWeights.value = weights;
      }

      loadMaxWeights();
      return null;
    }, []);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurazione Serie',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppTheme.spacing.lg),

          // Sets
          NumberInputField(
            label: 'Sets per Serie',
            controller: setsController,
            icon: Icons.repeat_one,
            isDecimal: false,
          ),
          SizedBox(height: AppTheme.spacing.lg),

          // Ripetizioni
          _buildRangeFields(
            label: 'Ripetizioni',
            minController: repsController,
            maxController: maxRepsController,
            icon: Icons.repeat,
            theme: theme,
            colorScheme: colorScheme,
          ),
          SizedBox(height: AppTheme.spacing.lg),

          // Intensità
          _buildRangeFields(
            label: 'Intensità (%)',
            minController: intensityController,
            maxController: maxIntensityController,
            icon: Icons.speed,
            theme: theme,
            colorScheme: colorScheme,
            onChanged: () => _updateWeightsFromIntensity(
              intensityController.text,
              maxIntensityController.text,
              maxWeights.value,
            ),
          ),
          SizedBox(height: AppTheme.spacing.lg),

          // RPE
          _buildRangeFields(
            label: 'RPE',
            minController: rpeController,
            maxController: maxRpeController,
            icon: Icons.trending_up,
            theme: theme,
            colorScheme: colorScheme,
          ),
          SizedBox(height: AppTheme.spacing.lg),

          // Preview dei pesi per esercizio
          _buildWeightPreview(
            exercises,
            maxWeights.value,
            intensityController.text,
            theme,
            colorScheme,
          ),

          SizedBox(height: AppTheme.spacing.xl),

          // Pulsante di applicazione
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Applica Serie',
              onPressed: () => _handleApply(
                exercises,
                repsController.text,
                maxRepsController.text,
                setsController.text,
                intensityController.text,
                maxIntensityController.text,
                rpeController.text,
                maxRpeController.text,
                maxWeights.value,
              ),
              variant: AppButtonVariant.primary,
              block: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeFields({
    required String label,
    required TextEditingController minController,
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
                controller: minController,
                icon: icon,
                onChanged: onChanged != null ? (value) => onChanged() : null,
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: NumberInputField(
                label: 'Max',
                controller: maxController,
                icon: Icons.arrow_upward,
                onChanged: onChanged != null ? (value) => onChanged() : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeightPreview(
    List<Exercise> exercises,
    Map<String, num> maxWeights,
    String intensity,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (intensity.isEmpty) return const SizedBox.shrink();

    final intensityValue = double.tryParse(intensity) ?? 0.0;
    if (intensityValue <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anteprima Pesi',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        ...exercises.map((exercise) {
          final maxWeight = maxWeights[exercise.exerciseId] ?? 0;
          final calculatedWeight = maxWeight > 0
              ? WeightCalculationService.calculateWeightFromIntensity(
                  maxWeight.toDouble(),
                  intensityValue,
                )
              : 0.0;

          return Container(
            margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.circular(AppTheme.radii.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                  ),
                ),
                Text(
                  '${calculatedWeight.toStringAsFixed(1)} kg',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _updateWeightsFromIntensity(String min, String max, Map<String, num> maxWeights) {
    // Logica per aggiornare i pesi basati sull'intensità
    // Implementata nel widget parent per aggiornare la UI
  }

  void _handleApply(
    List<Exercise> exercises,
    String reps,
    String maxReps,
    String sets,
    String intensity,
    String maxIntensity,
    String rpe,
    String maxRpe,
    Map<String, num> maxWeights,
  ) {
    // Note: Exercise series is immutable, this should be handled by the parent component
    // The parent should update the exercise with the new series
    onApply(exercises);
  }
}
