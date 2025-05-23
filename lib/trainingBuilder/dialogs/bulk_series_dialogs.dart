import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/dialog.dart';
import 'package:alphanessone/UI/components/weight_input_fields.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/range_input_field.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/range_controllers.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';

/// Dialog for selecting exercises for bulk series management
class BulkSeriesSelectionDialog extends HookWidget {
  final Exercise initialExercise;
  final List<Exercise> workoutExercises;
  final Function(List<Exercise>) onNext;

  const BulkSeriesSelectionDialog({
    super.key,
    required this.initialExercise,
    required this.workoutExercises,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final selectedExercises = useState<List<Exercise>>([initialExercise]);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      title: 'Gestione Serie in Bulk',
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(
          Icons.format_list_numbered,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      actions: [
        AppDialog.buildCancelButton(context: context),
        AppDialog.buildActionButton(
          context: context,
          label: 'Gestisci Serie',
          icon: Icons.playlist_add,
          onPressed: () {
            Navigator.pop(context);
            onNext(selectedExercises.value);
          },
        ),
      ],
      children: [
        _buildExerciseSelection(context, selectedExercises, theme, colorScheme),
      ],
    );
  }

  Widget _buildExerciseSelection(
    BuildContext context,
    ValueNotifier<List<Exercise>> selectedExercises,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleziona gli Esercizi',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        ...workoutExercises.map((exercise) => _buildExerciseCheckbox(
              exercise,
              selectedExercises,
              theme,
              colorScheme,
            )),
      ],
    );
  }

  Widget _buildExerciseCheckbox(
    Exercise exercise,
    ValueNotifier<List<Exercise>> selectedExercises,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return CheckboxListTile(
      value: selectedExercises.value.contains(exercise),
      onChanged: (checked) {
        if (checked ?? false) {
          selectedExercises.value = [...selectedExercises.value, exercise];
        } else {
          selectedExercises.value = selectedExercises.value
              .where((selected) => selected.id != exercise.id)
              .toList();
        }
      },
      title: Text(
        exercise.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: exercise.variant.isNotEmpty
          ? Text(
              exercise.variant,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      secondary: Container(
        padding: EdgeInsets.all(AppTheme.spacing.xs),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Text(
          exercise.type,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Dialog for configuring bulk series
class BulkSeriesConfigurationDialog extends HookConsumerWidget {
  final List<Exercise> exercises;
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;

  const BulkSeriesConfigurationDialog({
    super.key,
    required this.exercises,
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Controllers for form inputs
    final setsController = useTextEditingController(text: '1');
    final repsControllers = useMemoized(() => RangeControllers());
    final intensityControllers = useMemoized(() => RangeControllers());
    final rpeControllers = useMemoized(() => RangeControllers());

    // State for max weights and UI updates
    final maxWeights = useState<Map<String, num>>({});
    final forceUpdate = useState(0);

    // Load max weights on init
    useEffect(() {
      _loadMaxWeights(maxWeights);
      return () {
        repsControllers.dispose();
        intensityControllers.dispose();
        rpeControllers.dispose();
      };
    }, []);

    return AppDialog(
      title: 'Configura Serie',
      subtitle: 'Le serie verranno applicate a ${exercises.length} esercizi',
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(
          Icons.playlist_add_check,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      actions: [
        AppDialog.buildCancelButton(context: context),
        AppDialog.buildActionButton(
          context: context,
          label: 'Applica',
          icon: Icons.check,
          onPressed: () => _applySeriesToExercises(
            context,
            setsController,
            repsControllers,
            intensityControllers,
            rpeControllers,
            maxWeights.value,
            ref,
          ),
        ),
      ],
      children: [
        _buildConfigurationForm(
          context,
          setsController,
          repsControllers,
          intensityControllers,
          rpeControllers,
          maxWeights,
          forceUpdate,
          theme,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildConfigurationForm(
    BuildContext context,
    TextEditingController setsController,
    RangeControllers repsControllers,
    RangeControllers intensityControllers,
    RangeControllers rpeControllers,
    ValueNotifier<Map<String, num>> maxWeights,
    ValueNotifier<int> forceUpdate,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
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
        _buildSetsField(setsController, theme, colorScheme),
        SizedBox(height: AppTheme.spacing.lg),
        RangeInputField(
          label: 'Ripetizioni',
          controllers: repsControllers,
          icon: Icons.repeat,
          hint: 'Ripetizioni',
          maxHint: 'Max Ripetizioni',
        ),
        SizedBox(height: AppTheme.spacing.lg),
        RangeInputField(
          label: 'Intensità (%)',
          controllers: intensityControllers,
          icon: Icons.speed,
          hint: 'Intensità',
          maxHint: 'Max Intensità',
          onChanged: (min, max) => _updateWeightsFromIntensity(
            min,
            max,
            maxWeights,
            forceUpdate,
          ),
        ),
        SizedBox(height: AppTheme.spacing.lg),
        RangeInputField(
          label: 'RPE',
          controllers: rpeControllers,
          icon: Icons.trending_up,
          hint: 'RPE',
          maxHint: 'Max RPE',
        ),
        SizedBox(height: AppTheme.spacing.lg),
        _buildExerciseWeights(maxWeights.value, forceUpdate, context),
      ],
    );
  }

  Widget _buildSetsField(
    TextEditingController controller,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(128),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.spacing.md),
          labelText: 'Sets per Serie',
          prefixIcon: Icon(
            Icons.repeat_one,
            color: colorScheme.onSurfaceVariant.withAlpha(128),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseWeights(
    Map<String, num> maxWeights,
    ValueNotifier<int> forceUpdate,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pesi per Esercizio',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        ...exercises.map((exercise) => WeightInputFields(
              maxWeight: maxWeights[exercise.exerciseId] ?? 0,
              intensity: '',
              maxIntensity: '',
              exerciseName: exercise.name,
              onWeightChanged: (weight) =>
                  _updateExerciseWeight(exercise, weight),
              onMaxWeightChanged: (maxWeight) =>
                  _updateExerciseMaxWeight(exercise, maxWeight),
            )),
      ],
    );
  }

  Future<void> _loadMaxWeights(
      ValueNotifier<Map<String, num>> maxWeights) async {
    final Map<String, num> weights = {};
    for (var exercise in exercises) {
      if (exercise.exerciseId != null) {
        // This would need to be injected properly in a real implementation
        // For now, we'll set a placeholder
        weights[exercise.exerciseId!] = 100; // Placeholder value
      }
    }
    maxWeights.value = weights;
  }

  void _updateWeightsFromIntensity(
    String min,
    String max,
    ValueNotifier<Map<String, num>> maxWeights,
    ValueNotifier<int> forceUpdate,
  ) {
    final minIntensity = double.tryParse(min) ?? 0;
    final maxIntensity = double.tryParse(max);

    for (var exercise in exercises) {
      final maxWeight = maxWeights.value[exercise.exerciseId] ?? 0;
      if (maxWeight <= 0) continue;

      final minWeight = maxWeight * (minIntensity / 100);
      final maxWeightValue =
          maxIntensity != null ? maxWeight * (maxIntensity / 100) : null;

      _updateExerciseWeight(exercise, minWeight.toDouble());
      if (maxWeightValue != null) {
        _updateExerciseMaxWeight(exercise, maxWeightValue);
      }
    }

    forceUpdate.value++;
  }

  void _updateExerciseWeight(Exercise exercise, double weight) {
    for (var series in exercise.series) {
      series.weight = weight;
    }
  }

  void _updateExerciseMaxWeight(Exercise exercise, double? maxWeight) {
    for (var series in exercise.series) {
      series.maxWeight = maxWeight;
    }
  }

  void _applySeriesToExercises(
    BuildContext context,
    TextEditingController setsController,
    RangeControllers repsControllers,
    RangeControllers intensityControllers,
    RangeControllers rpeControllers,
    Map<String, num> maxWeights,
    WidgetRef ref,
  ) {
    final sets = int.tryParse(setsController.text) ?? 1;
    final reps = int.tryParse(repsControllers.min.text) ?? 12;
    final maxReps = repsControllers.max.text.isNotEmpty
        ? int.tryParse(repsControllers.max.text)
        : null;

    ExerciseService.createBulkSeries(
      exercises: exercises,
      sets: sets,
      reps: reps,
      maxReps: maxReps,
      intensity: intensityControllers.min.text,
      maxIntensity: intensityControllers.max.text.isNotEmpty
          ? intensityControllers.max.text
          : null,
      rpe: rpeControllers.min.text,
      maxRpe:
          rpeControllers.max.text.isNotEmpty ? rpeControllers.max.text : null,
      exerciseMaxWeights: maxWeights,
    );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Serie aggiornate per ${exercises.length} esercizi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
