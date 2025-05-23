import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/List/progressions_list.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../controller/training_program_controller.dart';
import 'series_list.dart';
import '../dialog/reorder_dialog.dart';
import '../../UI/components/dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/models/superseries_model.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/UI/components/weight_input_fields.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/exercise_components.dart';
import 'package:alphanessone/trainingBuilder/dialogs/bulk_series_dialogs.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart';

// Controller per i range di valori
class RangeControllers {
  final TextEditingController min;
  final TextEditingController max;

  RangeControllers()
      : min = TextEditingController(),
        max = TextEditingController();

  void dispose() {
    min.dispose();
    max.dispose();
  }

  String get displayText {
    final minText = formatNumber(min.text);
    final maxText = formatNumber(max.text);
    if (maxText.isEmpty) return minText;
    if (minText.isEmpty) return maxText;
    return "$minText-$maxText";
  }

  void updateFromDialog(String minValue, String maxValue) {
    min.text = minValue;
    max.text = maxValue;
  }
}

// Controller per tutti i campi di una serie
class SeriesControllers {
  final RangeControllers reps;
  final TextEditingController sets;
  final RangeControllers intensity;
  final RangeControllers rpe;
  final RangeControllers weight;

  SeriesControllers()
      : reps = RangeControllers(),
        sets = TextEditingController(text: '1'),
        intensity = RangeControllers(),
        rpe = RangeControllers(),
        weight = RangeControllers();

  void dispose() {
    reps.dispose();
    sets.dispose();
    intensity.dispose();
    rpe.dispose();
    weight.dispose();
  }

  void initializeFromSeries(Series series) {
    reps.min.text = formatNumber(series.reps);
    reps.max.text = formatNumber(series.maxReps);
    sets.text = formatNumber(series.sets);
    intensity.min.text = formatNumber(series.intensity);
    intensity.max.text = formatNumber(series.maxIntensity);
    rpe.min.text = formatNumber(series.rpe);
    rpe.max.text = formatNumber(series.maxRpe);
    weight.min.text = formatNumber(series.weight);
    weight.max.text = formatNumber(series.maxWeight);
  }
}

// Notifier per gestire lo stato dei controller
class BulkSeriesControllersNotifier
    extends StateNotifier<List<SeriesControllers>> {
  BulkSeriesControllersNotifier() : super([]);

  void initialize(List<Exercise> exercises) {
    state = exercises.map((_) => SeriesControllers()).toList();
  }

  void updateControllers(int index, Series series) {
    if (index >= 0 && index < state.length) {
      state[index].initializeFromSeries(series);
      state = [...state];
    }
  }

  void addControllers() {
    state = [...state, SeriesControllers()];
  }

  void removeControllers(int index) {
    if (index >= 0 && index < state.length) {
      final newState = List<SeriesControllers>.from(state);
      newState.removeAt(index);
      state = newState;
    }
  }

  void updateControllersForExercises(List<Exercise> exercises) {
    final newState = List<SeriesControllers>.from(state);
    for (int i = 0; i < exercises.length && i < state.length; i++) {
      if (exercises[i].series.isNotEmpty) {
        newState[i].initializeFromSeries(exercises[i].series.first);
      }
    }
    state = newState;
  }
}

// Provider per i controller
final bulkSeriesControllersProvider = StateNotifierProvider<
    BulkSeriesControllersNotifier, List<SeriesControllers>>((ref) {
  return BulkSeriesControllersNotifier();
});

// Utility per formattare i numeri
String formatNumber(dynamic value) {
  if (value == null) return '';
  if (value is int) return value.toString();
  if (value is double) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
  if (value is String) {
    if (value.isEmpty) return '';
    final doubleValue = double.tryParse(value);
    return doubleValue != null ? formatNumber(doubleValue) : value;
  }
  return value.toString();
}

class BulkSeriesSelectionDialog extends HookConsumerWidget {
  final Exercise initialExercise;
  final List<Exercise> workoutExercises;
  final ColorScheme colorScheme;
  final Function(List<Exercise>) onNext;

  const BulkSeriesSelectionDialog({
    required this.initialExercise,
    required this.workoutExercises,
    required this.colorScheme,
    required this.onNext,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedExercises = useState<List<Exercise>>([initialExercise]);

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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleziona gli Esercizi',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: AppTheme.spacing.md),
            ...workoutExercises.map((e) => CheckboxListTile(
                  value: selectedExercises.value.contains(e),
                  onChanged: (checked) {
                    if (checked ?? false) {
                      selectedExercises.value = [...selectedExercises.value, e];
                    } else {
                      selectedExercises.value = selectedExercises.value
                          .where((selected) => selected.id != e.id)
                          .toList();
                    }
                  },
                  title: Text(
                    e.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                  subtitle: e.variant.isNotEmpty
                      ? Text(
                          e.variant,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      e.type,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                    ),
                  ),
                )),
          ],
        ),
      ],
    );
  }
}

class BulkSeriesConfigurationDialog extends HookConsumerWidget {
  final List<Exercise> exercises;
  final ColorScheme colorScheme;
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;

  const BulkSeriesConfigurationDialog({
    required this.exercises,
    required this.colorScheme,
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);

    // Stato per i massimali e il rebuild
    final maxWeights = useState<Map<String, num>>({});
    final forceUpdate = useState(0);

    // Map per i controller dei pesi di ogni esercizio
    final exerciseWeightControllers =
        useMemoized(() => <String, RangeControllers>{}, []);

    // Crea un controller locale per gestire i campi
    final localController = useMemoized(() => SeriesControllers(), []);

    // Carica i massimali all'inizializzazione
    useEffect(() {
      Future<void> loadMaxWeights() async {
        final Map<String, num> weights = {};
        for (var exercise in exercises) {
          if (exercise.exerciseId != null) {
            final record = await exerciseRecordService.getLatestExerciseRecord(
              userId: controller.program.athleteId,
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

    // Pulisci il controller quando il widget viene distrutto
    useEffect(() {
      return () {
        localController.dispose();
        for (var controller in exerciseWeightControllers.values) {
          controller.dispose();
        }
      };
    }, [localController, exerciseWeightControllers]);

    // Funzione per ottenere il massimale di un esercizio
    num getMaxWeight(Exercise exercise) {
      if (exercise.exerciseId == null) return 0;
      return maxWeights.value[exercise.exerciseId] ?? 0;
    }

    // Funzione per calcolare il peso in base all'intensità
    double calculateWeight(num maxWeight, double intensity) {
      return SeriesUtils.calculateWeightFromIntensity(
        maxWeight.toDouble(),
        intensity,
      );
    }

    // Funzione per calcolare l'intensità in base al peso
    num calculateIntensity(double weight, num maxWeight) {
      return SeriesUtils.calculateIntensityFromWeight(
        weight,
        maxWeight.toDouble(),
      );
    }

    // Funzione per aggiornare tutti i pesi in base all'intensità
    void updateAllWeightsFromIntensity(
        double minIntensity, double? maxIntensity) {
      for (var exercise in exercises) {
        if (exercise.exerciseId == null) continue;

        final maxWeight = getMaxWeight(exercise);
        if (maxWeight <= 0) continue;

        final controllers = exerciseWeightControllers[exercise.exerciseId];
        if (controllers == null) continue;

        final minWeight = calculateWeight(maxWeight, minIntensity);
        controllers.min.text = formatNumber(minWeight);

        if (maxIntensity != null) {
          final maxWeightValue = calculateWeight(maxWeight, maxIntensity);
          controllers.max.text = formatNumber(maxWeightValue);
        } else {
          controllers.max.text = '';
        }
      }

      forceUpdate.value++;
    }

    // Funzione per aggiornare i pesi in base all'intensità
    void updateWeightsFromIntensity(String min, String max) {
      final minIntensity = double.tryParse(min) ?? 0;
      final maxIntensity = double.tryParse(max);

      // Aggiorna i pesi di tutti gli esercizi
      updateAllWeightsFromIntensity(minIntensity, maxIntensity);
    }

    // Funzione per aggiornare l'intensità in base al peso

    Widget buildRangeField({
      required String label,
      required RangeControllers controllers,
      required IconData icon,
      String? hint,
      String? maxHint,
      Function(String, String)? onChanged,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(77),
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(128),
                    ),
                  ),
                  child: TextField(
                    controller: controllers.min,
                    keyboardType: TextInputType.number,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(AppTheme.spacing.md),
                      hintText: hint ?? 'Min',
                      prefixIcon: Icon(
                        icon,
                        color: colorScheme.onSurfaceVariant.withAlpha(128),
                        size: 20,
                      ),
                    ),
                    onChanged: (value) {
                      if (onChanged != null) {
                        onChanged(value, controllers.max.text);
                      }
                      // Forza l'aggiornamento della UI
                      forceUpdate.value++;
                    },
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacing.md),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(77),
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(128),
                    ),
                  ),
                  child: TextField(
                    controller: controllers.max,
                    keyboardType: TextInputType.number,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(AppTheme.spacing.md),
                      hintText: maxHint ?? 'Max',
                      prefixIcon: Icon(
                        Icons.arrow_upward,
                        color: colorScheme.onSurfaceVariant.withAlpha(128),
                        size: 20,
                      ),
                    ),
                    onChanged: (value) {
                      if (onChanged != null) {
                        onChanged(controllers.min.text, value);
                      }
                      // Forza l'aggiornamento della UI
                      forceUpdate.value++;
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

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
          onPressed: () {
            final sets = int.tryParse(localController.sets.text) ?? 1;
            final reps = int.tryParse(localController.reps.min.text) ?? 12;
            final maxReps = localController.reps.max.text.isNotEmpty
                ? int.tryParse(localController.reps.max.text)
                : null;
            final intensity = localController.intensity.min.text;
            final maxIntensity = localController.intensity.max.text.isNotEmpty
                ? localController.intensity.max.text
                : null;
            final rpe = localController.rpe.min.text;
            final maxRpe = localController.rpe.max.text.isNotEmpty
                ? localController.rpe.max.text
                : null;

            for (var exercise in exercises) {
              // Ottieni i pesi calcolati per questo esercizio
              final maxWeight = getMaxWeight(exercise);
              final minIntensity = double.tryParse(intensity) ?? 0;
              final maxIntensityValue = double.tryParse(maxIntensity ?? '');

              final calculatedWeight =
                  maxWeight > 0 ? calculateWeight(maxWeight, minIntensity) : 0;
              final calculatedMaxWeight =
                  maxIntensityValue != null && maxWeight > 0
                      ? calculateWeight(maxWeight, maxIntensityValue)
                      : null;

              final newSeries = List.generate(
                  sets,
                  (index) => Series(
                        serieId: generateRandomId(16),
                        reps: reps,
                        maxReps: maxReps,
                        sets: 1,
                        intensity: intensity,
                        maxIntensity: maxIntensity,
                        rpe: rpe,
                        maxRpe: maxRpe,
                        weight: calculatedWeight.toDouble(),
                        maxWeight: calculatedMaxWeight?.toDouble(),
                        order: index + 1,
                        done: false,
                        reps_done: 0,
                        weight_done: 0,
                      ));

              exercise.series = newSeries;
            }
            ref
                .read(bulkSeriesControllersProvider.notifier)
                .updateControllersForExercises(exercises);

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Serie aggiornate per ${exercises.length} esercizi'),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurazione Serie',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: AppTheme.spacing.lg),

            // Sets per serie
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(77),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(
                  color: colorScheme.outline.withAlpha(128),
                ),
              ),
              child: TextField(
                controller: localController.sets,
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
            ),
            SizedBox(height: AppTheme.spacing.lg),

            // Ripetizioni
            buildRangeField(
              label: 'Ripetizioni',
              controllers: localController.reps,
              icon: Icons.repeat,
              hint: 'Ripetizioni',
              maxHint: 'Max Ripetizioni',
            ),
            SizedBox(height: AppTheme.spacing.lg),

            // Intensità
            buildRangeField(
              label: 'Intensità (%)',
              controllers: localController.intensity,
              icon: Icons.speed,
              hint: 'Intensità',
              maxHint: 'Max Intensità',
              onChanged: (min, max) {
                // Aggiorna i pesi quando cambia l'intensità
                for (var exercise in exercises) {
                  final maxWeight = getMaxWeight(exercise);
                  final minIntensity = double.tryParse(min) ?? 0;
                  final maxIntensity = double.tryParse(max);

                  final calculatedWeight = maxWeight > 0
                      ? calculateWeight(maxWeight, minIntensity)
                      : 0;
                  final calculatedMaxWeight =
                      maxIntensity != null && maxWeight > 0
                          ? calculateWeight(maxWeight, maxIntensity)
                          : null;

                  // Aggiorna i valori delle serie
                  for (var series in exercise.series) {
                    series.weight = calculatedWeight.toDouble();
                    series.maxWeight = calculatedMaxWeight?.toDouble();
                  }
                }
                forceUpdate.value++;
              },
            ),
            SizedBox(height: AppTheme.spacing.lg),

            // RPE
            buildRangeField(
              label: 'RPE',
              controllers: localController.rpe,
              icon: Icons.trending_up,
              hint: 'RPE',
              maxHint: 'Max RPE',
              onChanged: (min, max) => forceUpdate.value++,
            ),
            SizedBox(height: AppTheme.spacing.lg),

            // Lista degli esercizi con i loro campi peso
            Text(
              'Pesi per Esercizio',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: AppTheme.spacing.md),
            ...exercises.map((exercise) {
              return WeightInputFields(
                maxWeight: getMaxWeight(exercise),
                intensity: localController.intensity.min.text,
                maxIntensity: localController.intensity.max.text,
                exerciseName: exercise.name,
                onWeightChanged: (weight) {
                  for (var series in exercise.series) {
                    series.weight = weight;
                  }
                  forceUpdate.value++;
                },
                onMaxWeightChanged: (maxWeight) {
                  for (var series in exercise.series) {
                    series.maxWeight = maxWeight;
                  }
                  forceUpdate.value++;
                },
              );
            }),
          ],
        ),
      ],
    );
  }
}

/// Widget for displaying and managing exercise list
class TrainingProgramExerciseList extends HookConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;

  const TrainingProgramExerciseList({
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final exercises = workout.exercises;
    final usersService = ref.watch(usersServiceProvider);
    final exerciseRecordService = usersService.exerciseRecordService;
    final athleteId = controller.athleteIdController.text;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _ExerciseListView(
      controller: controller,
      weekIndex: weekIndex,
      workoutIndex: workoutIndex,
      exercises: exercises,
      exerciseRecordService: exerciseRecordService,
      athleteId: athleteId,
      theme: theme,
      colorScheme: colorScheme,
    );
  }
}

/// Separated widget for exercise list view following SRP
class _ExerciseListView extends StatefulWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;
  final List<Exercise> exercises;
  final ExerciseRecordService exerciseRecordService;
  final String athleteId;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ExerciseListView({
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
    required this.exercises,
    required this.exerciseRecordService,
    required this.athleteId,
    required this.theme,
    required this.colorScheme,
  });

  @override
  State<_ExerciseListView> createState() => _ExerciseListViewState();
}

class _ExerciseListViewState extends State<_ExerciseListView>
    with TrainingListMixin {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 600;
    final spacing = isCompact ? AppTheme.spacing.sm : AppTheme.spacing.md;
    final padding = EdgeInsets.all(
      isCompact ? AppTheme.spacing.md : AppTheme.spacing.lg,
    );

    return Scaffold(
      backgroundColor: widget.colorScheme.surface,
      body: Container(
        decoration: _buildBackgroundGradient(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: padding,
                sliver: widget.exercises.isEmpty
                    ? _buildEmptyState(isCompact)
                    : _buildExerciseGrid(isCompact, spacing),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.exercises.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => _showReorderExercisesDialog(),
              backgroundColor: widget.colorScheme.primaryContainer,
              foregroundColor: widget.colorScheme.onPrimaryContainer,
              icon: const Icon(Icons.reorder),
              label: Text(
                isCompact ? 'Riordina' : 'Riordina Esercizi',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radii.xl),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState(bool isCompact) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: widget.colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: BorderRadius.circular(AppTheme.radii.xl),
              ),
              child: Icon(
                Icons.fitness_center_outlined,
                size: isCompact ? 48 : 64,
                color: widget.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppTheme.spacing.lg),
            Text(
              'Nessun esercizio disponibile',
              style: widget.theme.textTheme.titleLarge?.copyWith(
                color: widget.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing.sm),
            Text(
              'Aggiungi il primo esercizio per iniziare',
              style: widget.theme.textTheme.bodyLarge?.copyWith(
                color: widget.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppTheme.spacing.xl),
            _buildAddExerciseButton(isCompact),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          widget.colorScheme.surface,
          widget.colorScheme.surfaceContainerHighest.withAlpha(128),
        ],
        stops: const [0.0, 1.0],
      ),
    );
  }

  Widget _buildExerciseGrid(bool isCompact, double spacing) {
    return isCompact ? _buildListView(spacing) : _buildGridView(spacing);
  }

  Widget _buildListView(double spacing) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == widget.exercises.length) {
            return Padding(
              padding: EdgeInsets.only(top: spacing),
              child: _buildAddExerciseButton(true),
            );
          }
          return Padding(
            padding: EdgeInsets.only(bottom: spacing),
            child: _buildExerciseCard(widget.exercises[index]),
          );
        },
        childCount: widget.exercises.length + 1,
      ),
    );
  }

  Widget _buildGridView(double spacing) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == widget.exercises.length) {
            return _buildAddExerciseButton(false);
          }
          return _buildExerciseCard(widget.exercises[index]);
        },
        childCount: widget.exercises.length + 1,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900 ? 2 : 1,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.75,
        mainAxisExtent: null,
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final superSets = _getSuperSets(exercise);

    return FutureBuilder<num>(
      future: ExerciseService.getLatestMaxWeight(
        widget.exerciseRecordService,
        widget.athleteId,
        exercise.exerciseId ?? '',
      ),
      builder: (context, snapshot) {
        return Slidable(
          startActionPane: _buildStartActionPane(),
          endActionPane: _buildEndActionPane(exercise),
          child: ExerciseCard(
            exercise: exercise,
            superSets: superSets,
            seriesSection: _buildSeriesSection(exercise),
            onTap: () => _navigateToExerciseDetails(exercise, superSets),
            onOptionsPressed: () => _showExerciseOptions(
              exercise,
              snapshot.data ?? 0,
            ),
          ),
        );
      },
    );
  }

  ActionPane _buildStartActionPane() {
    return ActionPane(
      motion: const ScrollMotion(),
      children: [
        SlidableAction(
          onPressed: (_) => widget.controller
              .addExercise(widget.weekIndex, widget.workoutIndex, context),
          backgroundColor: widget.colorScheme.primaryContainer,
          foregroundColor: widget.colorScheme.onPrimaryContainer,
          borderRadius: BorderRadius.horizontal(
            left: Radius.circular(AppTheme.radii.lg),
          ),
          icon: Icons.add,
          label: 'Add',
        ),
      ],
    );
  }

  ActionPane _buildEndActionPane(Exercise exercise) {
    return ActionPane(
      motion: const ScrollMotion(),
      children: [
        SlidableAction(
          onPressed: (_) => widget.controller.removeExercise(
            widget.weekIndex,
            widget.workoutIndex,
            exercise.order - 1,
          ),
          backgroundColor: widget.colorScheme.errorContainer,
          foregroundColor: widget.colorScheme.onErrorContainer,
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppTheme.radii.lg),
          ),
          icon: Icons.delete_outline,
          label: 'Delete',
        ),
      ],
    );
  }

  Widget _buildSeriesSection(Exercise exercise) {
    return TrainingProgramSeriesList(
      controller: widget.controller,
      exerciseRecordService: widget.exerciseRecordService,
      weekIndex: widget.weekIndex,
      workoutIndex: widget.workoutIndex,
      exerciseIndex: exercise.order - 1,
      exerciseType: exercise.type,
    );
  }

  Widget _buildAddExerciseButton(bool isCompact) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isCompact ? double.infinity : 300,
        ),
        child: AppButton(
          label: 'Add Exercise',
          icon: Icons.add_circle_outline,
          variant: AppButtonVariant.primary,
          size: isCompact ? AppButtonSize.sm : AppButtonSize.md,
          block: true,
          onPressed: () => widget.controller
              .addExercise(widget.weekIndex, widget.workoutIndex, context),
        ),
      ),
    );
  }

  List<SuperSet> _getSuperSets(Exercise exercise) {
    final workout = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex];
    return workout.superSets
        .where((ss) => ss.exerciseIds.contains(exercise.id))
        .toList();
  }

  void _showExerciseOptions(Exercise exercise, num latestMaxWeight) {
    final superSets = _getSuperSets(exercise);
    final isInSuperSet = superSets.isNotEmpty;
    final superSet = isInSuperSet ? superSets.first : null;

    showOptionsBottomSheet(
      context,
      title: exercise.name,
      subtitle: exercise.variant,
      leadingIcon: Icons.fitness_center,
      items: [
        BottomMenuItem(
          title: 'Modifica',
          icon: Icons.edit_outlined,
          onTap: () => widget.controller.editExercise(
            widget.weekIndex,
            widget.workoutIndex,
            exercise.order - 1,
            context,
          ),
        ),
        BottomMenuItem(
          title: 'Gestione Serie in Bulk',
          icon: Icons.format_list_numbered,
          onTap: () => _showBulkSeriesDialog(exercise),
        ),
        BottomMenuItem(
          title: 'Sposta Esercizio',
          icon: Icons.move_up,
          onTap: () => _showMoveExerciseDialog(exercise),
        ),
        BottomMenuItem(
          title: 'Duplica Esercizio',
          icon: Icons.content_copy_outlined,
          onTap: () => widget.controller.duplicateExercise(
            widget.weekIndex,
            widget.workoutIndex,
            exercise.order - 1,
          ),
        ),
        if (!isInSuperSet)
          BottomMenuItem(
            title: 'Aggiungi a Super Set',
            icon: Icons.group_add_outlined,
            onTap: () => _showAddToSuperSetDialog(exercise),
          ),
        if (isInSuperSet && superSet != null)
          BottomMenuItem(
            title: 'Rimuovi da Super Set',
            icon: Icons.group_remove_outlined,
            onTap: () => widget.controller.removeExerciseFromSuperSet(
              widget.weekIndex,
              widget.workoutIndex,
              superSet.id,
              exercise.id!,
            ),
          ),
        BottomMenuItem(
          title: 'Imposta Progressione',
          icon: Icons.trending_up,
          onTap: () => _navigateToProgressions(exercise, latestMaxWeight),
        ),
        BottomMenuItem(
          title: 'Aggiorna Max RM',
          icon: Icons.fitness_center,
          onTap: () => _showUpdateMaxRMDialog(exercise),
        ),
        BottomMenuItem(
          title: 'Elimina',
          icon: Icons.delete_outline,
          onTap: () => widget.controller.removeExercise(
            widget.weekIndex,
            widget.workoutIndex,
            exercise.order - 1,
          ),
          isDestructive: true,
        ),
      ],
    );
  }

  void _showBulkSeriesDialog(Exercise exercise) {
    final workout = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex];

    showDialog(
      context: context,
      builder: (context) => BulkSeriesSelectionDialog(
        initialExercise: exercise,
        workoutExercises: workout.exercises,
        colorScheme: widget.colorScheme,
        onNext: (selectedExercises) =>
            _showBulkConfigurationDialog(selectedExercises),
      ),
    );
  }

  void _showBulkConfigurationDialog(List<Exercise> exercises) {
    showDialog(
      context: context,
      builder: (context) => BulkSeriesConfigurationDialog(
        exercises: exercises,
        colorScheme: widget.colorScheme,
        controller: widget.controller,
        weekIndex: widget.weekIndex,
        workoutIndex: widget.workoutIndex,
      ),
    );
  }

  void _showMoveExerciseDialog(Exercise exercise) {
    final week = widget.controller.program.weeks[widget.weekIndex];

    showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Seleziona l\'Allenamento di Destinazione'),
        content: DropdownButtonFormField<int>(
          value: null,
          items: List.generate(
            week.workouts.length,
            (index) => DropdownMenuItem(
              value: index,
              child: Text('Allenamento ${week.workouts[index].order}'),
            ),
          ),
          onChanged: (value) => Navigator.pop(dialogContext, value),
          decoration: const InputDecoration(
            labelText: 'Allenamento di Destinazione',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
        ],
      ),
    ).then((destinationWorkoutIndex) {
      if (destinationWorkoutIndex != null &&
          destinationWorkoutIndex != widget.workoutIndex) {
        widget.controller.moveExercise(
          widget.weekIndex,
          widget.workoutIndex,
          exercise.order - 1,
          widget.weekIndex,
          destinationWorkoutIndex,
        );
      }
    });
  }

  void _showAddToSuperSetDialog(Exercise exercise) {
    final superSets = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].superSets;

    if (superSets.isEmpty) {
      widget.controller.createSuperSet(widget.weekIndex, widget.workoutIndex);
      final newSuperSetId = widget.controller.program.weeks[widget.weekIndex]
          .workouts[widget.workoutIndex].superSets.first.id;
      widget.controller.addExerciseToSuperSet(
        widget.weekIndex,
        widget.workoutIndex,
        newSuperSetId,
        exercise.id!,
      );
    } else {
      _showSuperSetSelectionDialog(exercise, superSets);
    }
  }

  void _showSuperSetSelectionDialog(
      Exercise exercise, List<SuperSet> superSets) {
    String? selectedSuperSetId;

    showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext builderContext, setState) => AlertDialog(
          backgroundColor: widget.colorScheme.surface,
          title: Text(
            'Aggiungi al Superset',
            style: TextStyle(color: widget.colorScheme.onSurface),
          ),
          content: DropdownButtonFormField<String>(
            value: selectedSuperSetId,
            items: superSets
                .map((ss) => DropdownMenuItem<String>(
                      value: ss.id,
                      child: Text(
                        ss.name ?? '',
                        style: TextStyle(color: widget.colorScheme.onSurface),
                      ),
                    ))
                .toList(),
            onChanged: (value) => setState(() => selectedSuperSetId = value),
            decoration: InputDecoration(
              hintText: 'Seleziona il Superset',
              hintStyle: TextStyle(color: widget.colorScheme.onSurface),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(
                'Annulla',
                style: TextStyle(color: widget.colorScheme.onSurface),
              ),
            ),
            if (superSets.isNotEmpty)
              TextButton(
                onPressed: () {
                  widget.controller
                      .createSuperSet(widget.weekIndex, widget.workoutIndex);
                  setState(() {});
                  Navigator.of(dialogContext).pop(superSets.last.id);
                },
                child: Text(
                  'Crea Nuovo Superset',
                  style: TextStyle(color: widget.colorScheme.onSurface),
                ),
              ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(selectedSuperSetId),
              child: Text(
                'Aggiungi',
                style: TextStyle(color: widget.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result != null) {
        widget.controller.addExerciseToSuperSet(
          widget.weekIndex,
          widget.workoutIndex,
          result,
          exercise.id!,
        );
      }
    });
  }

  void _showUpdateMaxRMDialog(Exercise exercise) {
    final maxWeightController = TextEditingController();
    final repetitionsController = TextEditingController(text: '1');

    repetitionsController.addListener(() {
      final repetitions = int.tryParse(repetitionsController.text) ?? 1;
      if (repetitions > 1) {
        final maxWeight = double.tryParse(maxWeightController.text) ?? 0;
        final calculatedMaxWeight =
            ExerciseService.calculateMaxRM(maxWeight, repetitions);
        maxWeightController.text =
            FormatUtils.formatNumber(calculatedMaxWeight);
        repetitionsController.text = '1';
      }
    });

    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: widget.colorScheme.surface,
        title: Text(
          'Aggiorna Max RM',
          style: TextStyle(color: widget.colorScheme.onSurface),
        ),
        content:
            _buildMaxRMInputFields(maxWeightController, repetitionsController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Annulla',
              style: TextStyle(color: widget.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.colorScheme.primary,
              foregroundColor: widget.colorScheme.onPrimary,
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    ).then((result) {
      if (result == true) {
        _saveMaxRM(exercise, maxWeightController, repetitionsController);
      }
    });
  }

  Widget _buildMaxRMInputFields(
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: maxWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              final text = newValue.text.replaceAll(',', '.');
              return newValue.copyWith(
                text: text,
                selection: TextSelection.collapsed(offset: text.length),
              );
            }),
          ],
          style: TextStyle(color: widget.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Peso Massimo',
            labelStyle: TextStyle(color: widget.colorScheme.onSurface),
          ),
        ),
        TextField(
          controller: repetitionsController,
          keyboardType: TextInputType.number,
          style: TextStyle(color: widget.colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Ripetizioni',
            labelStyle: TextStyle(color: widget.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Future<void> _saveMaxRM(
    Exercise exercise,
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
  ) async {
    final maxWeight = double.tryParse(maxWeightController.text) ?? 0;
    final repetitions = int.tryParse(repetitionsController.text) ?? 1;

    try {
      await ExerciseService.updateMaxRM(
        exerciseRecordService: widget.exerciseRecordService,
        athleteId: widget.athleteId,
        exercise: exercise,
        maxWeight: maxWeight,
        repetitions: repetitions,
        exerciseType: exercise.type,
      );

      widget.controller.updateExercise(exercise);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'aggiornamento: $e'),
            backgroundColor: widget.colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToProgressions(Exercise exercise, num latestMaxWeight) {
    Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => ProgressionsList(
          exerciseId: exercise.exerciseId!,
          exercise: exercise,
          latestMaxWeight: latestMaxWeight,
        ),
      ),
    ).then((updatedExercise) {
      if (updatedExercise != null) {
        widget.controller.updateExercise(updatedExercise);
      }
    });
  }

  void _navigateToExerciseDetails(Exercise exercise, List<SuperSet> superSets) {
    final superSetExerciseIndex = superSets.isNotEmpty
        ? superSets.indexWhere((ss) => ss.exerciseIds.contains(exercise.id))
        : 0;

    context.go(
      '/user_programs/training_viewer/week_details/workout_details/exercise_details',
      extra: {
        'programId': widget.controller.program.id,
        'weekId': widget.controller.program.weeks[widget.weekIndex].id,
        'workoutId': widget.controller.program.weeks[widget.weekIndex]
            .workouts[widget.workoutIndex].id,
        'exerciseId': exercise.id,
        'userId': widget.controller.program.athleteId,
        'superSetExercises': superSets.map((s) => s.toMap()).toList(),
        'superSetExerciseIndex': superSetExerciseIndex,
        'seriesList': exercise.series.map((s) => s.toMap()).toList(),
        'startIndex': 0,
      },
    );
  }

  void _showReorderExercisesDialog() {
    final workout = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex];

    final exerciseNames = workout.exercises
        .map((exercise) =>
            '${exercise.order}. ${exercise.name}${exercise.variant.isNotEmpty ? ' (${exercise.variant})' : ''}')
        .toList();

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: exerciseNames,
        onReorder: (oldIndex, newIndex) {
          widget.controller.reorderExercises(
            widget.weekIndex,
            widget.workoutIndex,
            oldIndex,
            newIndex,
          );

          // Mostra notifica di successo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: widget.colorScheme.onPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text('Esercizi riordinati con successo'),
                ],
              ),
              backgroundColor: widget.colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}
