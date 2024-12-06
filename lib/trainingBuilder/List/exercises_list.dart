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
          color: colorScheme.primaryContainer.withOpacity(0.3),
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
                      color: colorScheme.primaryContainer.withOpacity(0.3),
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
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
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
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
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
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
          color: colorScheme.primaryContainer.withOpacity(0.3),
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
            ref.read(bulkSeriesControllersProvider.notifier).updateControllersForExercises(exercises);

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
                color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
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
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
    final dateFormat = DateFormat('yyyy-MM-dd');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Exercises List
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == exercises.length) {
                        return _buildAddExerciseButton(
                            context, colorScheme, theme);
                      }
                      return _buildExerciseCard(
                        context,
                        exercises[index],
                        exerciseRecordService,
                        athleteId,
                        dateFormat,
                        theme,
                        colorScheme,
                      );
                    },
                    childCount: exercises.length + 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final superSets = controller
        .program.weeks[weekIndex].workouts[workoutIndex].superSets
        .where((ss) => ss.exerciseIds.contains(exercise.id))
        .toList();

    return FutureBuilder<num>(
      future: getLatestMaxWeight(
        exerciseRecordService,
        athleteId,
        exercise.exerciseId ?? '',
      ),
      builder: (context, snapshot) {
        final latestMaxWeight = snapshot.data ?? 0;

        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
            boxShadow: AppTheme.elevations.small,
          ),
          child: Slidable(
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) =>
                      controller.addExercise(weekIndex, workoutIndex, context),
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(AppTheme.radii.lg),
                  ),
                  icon: Icons.add,
                  label: 'Add',
                ),
              ],
            ),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => controller.removeExercise(
                    weekIndex,
                    workoutIndex,
                    exercise.order - 1,
                  ),
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(AppTheme.radii.lg),
                  ),
                  icon: Icons.delete_outline,
                  label: 'Delete',
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToExerciseDetails(context,
                    userId: controller.program.athleteId,
                    programId: controller.program.id,
                    weekId: controller.program.weeks[weekIndex].id,
                    workoutId: controller
                        .program.weeks[weekIndex].workouts[workoutIndex].id,
                    exerciseId: exercise.id,
                    superSets: superSets,
                    superSetExerciseIndex:
                        superSets.indexOf(superSets.firstWhere(
                      (ss) => ss.exerciseIds.contains(exercise.id),
                      orElse: () => SuperSet(id: '', exerciseIds: []),
                    )),
                    seriesList: exercise.series,
                    startIndex: 0),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Exercise Type Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing.md,
                              vertical: AppTheme.spacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radii.xxl),
                            ),
                            child: Text(
                              exercise.type,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () => _showExerciseOptions(
                              context,
                              exercise,
                              exerciseRecordService,
                              athleteId,
                              dateFormat,
                              latestMaxWeight,
                              colorScheme,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: AppTheme.spacing.md),

                      // Exercise Name and Variant
                      Text(
                        exercise.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),

                      if (exercise.variant.isNotEmpty &&
                          exercise.variant != '') ...[
                        SizedBox(height: AppTheme.spacing.xs),
                        Text(
                          exercise.variant,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],

                      SizedBox(height: AppTheme.spacing.lg),

                      // Series List
                      TrainingProgramSeriesList(
                        controller: controller,
                        exerciseRecordService: exerciseRecordService,
                        weekIndex: weekIndex,
                        workoutIndex: workoutIndex,
                        exerciseIndex: exercise.order - 1,
                        exerciseType: exercise.type,
                      ),

                      // Superset Badge
                      if (superSets.isNotEmpty) ...[
                        SizedBox(height: AppTheme.spacing.md),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.md,
                            vertical: AppTheme.spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color:
                                colorScheme.secondaryContainer.withOpacity(0.3),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radii.lg),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.group_work,
                                size: 18,
                                color: colorScheme.secondary,
                              ),
                              SizedBox(width: AppTheme.spacing.xs),
                              Text(
                                'Superset',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddExerciseButton(
    BuildContext context,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.addExercise(weekIndex, workoutIndex, context),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.lg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'Add Exercise',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExerciseOptions(
    BuildContext context,
    Exercise exercise,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    num latestMaxWeight,
    ColorScheme colorScheme,
  ) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final superSet = workout.superSets.firstWhere(
      (ss) => ss.exerciseIds.contains(exercise.id),
      orElse: () => SuperSet(id: '', exerciseIds: []),
    );
    final isInSuperSet = superSet.id.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: exercise.name,
        subtitle: exercise.variant,
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Modifica',
            icon: Icons.edit_outlined,
            onTap: () => controller.editExercise(
              weekIndex,
              workoutIndex,
              exercise.order - 1,
              context,
            ),
          ),
          BottomMenuItem(
            title: 'Gestione Serie in Bulk',
            icon: Icons.format_list_numbered,
            onTap: () => _showBulkSeriesDialog(
              context,
              exercise,
              colorScheme,
            ),
          ),
          BottomMenuItem(
            title: 'Sposta Esercizio',
            icon: Icons.move_up,
            onTap: () => _showMoveExerciseDialog(
              context,
              weekIndex,
              workoutIndex,
              exercise,
            ),
          ),
          BottomMenuItem(
            title: 'Duplica Esercizio',
            icon: Icons.content_copy_outlined,
            onTap: () => controller.duplicateExercise(
              weekIndex,
              workoutIndex,
              exercise.order - 1,
            ),
          ),
          if (!isInSuperSet)
            BottomMenuItem(
              title: 'Aggiungi a Super Set',
              icon: Icons.group_add_outlined,
              onTap: () => _showAddToSuperSetDialog(
                context,
                exercise,
                colorScheme,
              ),
            ),
          if (isInSuperSet)
            BottomMenuItem(
              title: 'Rimuovi da Super Set',
              icon: Icons.group_remove_outlined,
              onTap: () => controller.removeExerciseFromSuperSet(
                weekIndex,
                workoutIndex,
                superSet.id,
                exercise.id!,
              ),
            ),
          BottomMenuItem(
            title: 'Imposta Progressione',
            icon: Icons.trending_up,
            onTap: () => _showSetProgressionScreen(
              context,
              exercise,
              latestMaxWeight,
              colorScheme,
            ),
          ),
          BottomMenuItem(
            title: 'Aggiorna Max RM',
            icon: Icons.fitness_center,
            onTap: () => _addOrUpdateMaxRM(
              exercise,
              context,
              exerciseRecordService,
              athleteId,
              dateFormat,
              colorScheme,
            ),
          ),
          BottomMenuItem(
            title: 'Elimina',
            icon: Icons.delete_outline,
            onTap: () => controller.removeExercise(
              weekIndex,
              workoutIndex,
              exercise.order - 1,
            ),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _showMoveExerciseDialog(
    BuildContext context,
    int weekIndex,
    int sourceWorkoutIndex,
    Exercise exercise,
  ) {
    final sourceExerciseIndex = exercise.order - 1;
    final week = controller.program.weeks[weekIndex];

    showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
            onChanged: (value) {
              Navigator.pop(dialogContext, value);
            },
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
        );
      },
    ).then((destinationWorkoutIndex) {
      if (destinationWorkoutIndex != null &&
          destinationWorkoutIndex != sourceWorkoutIndex) {
        controller.moveExercise(
          weekIndex,
          sourceWorkoutIndex,
          sourceExerciseIndex,
          weekIndex,
          destinationWorkoutIndex,
        );
      }
    });
  }

  void _addOrUpdateMaxRM(
    Exercise exercise,
    BuildContext context,
    ExerciseRecordService exerciseRecordService,
    String athleteId,
    DateFormat dateFormat,
    ColorScheme colorScheme,
  ) {
    exerciseRecordService
        .getLatestExerciseRecord(
      userId: athleteId,
      exerciseId: exercise.exerciseId!,
    )
        .then((record) {
      final maxWeightController =
          TextEditingController(text: record?.maxWeight.toString() ?? '');
      final repetitionsController =
          TextEditingController(text: record?.repetitions.toString() ?? '');

      repetitionsController.addListener(() {
        var repetitions = int.tryParse(repetitionsController.text) ?? 0;
        if (repetitions > 1) {
          final maxWeight = double.tryParse(maxWeightController.text) ?? 0;
          final calculatedMaxWeight = roundWeight(
              maxWeight / (1.0278 - (0.0278 * repetitions)), exercise.type);
          maxWeightController.text = calculatedMaxWeight.toString();
          repetitionsController.text = '1';
        }
      });

      showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              'Aggiorna Max RM',
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
            content: _buildMaxRMInputFields(
                maxWeightController, repetitionsController, colorScheme),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'Annulla',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Salva'),
              ),
            ],
          );
        },
      ).then((result) {
        if (result == true) {
          _saveMaxRM(
            record,
            athleteId,
            exercise,
            maxWeightController,
            repetitionsController,
            exerciseRecordService,
            dateFormat,
            exercise.type,
          );
        }
      });
    });
  }

  Widget _buildMaxRMInputFields(
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
    ColorScheme colorScheme,
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
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Peso Massimo',
            labelStyle: TextStyle(
              color: colorScheme.onSurface,
            ),
          ),
        ),
        TextField(
          controller: repetitionsController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: 'Ripetizioni',
            labelStyle: TextStyle(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  void _saveMaxRM(
    ExerciseRecord? record,
    String athleteId,
    Exercise exercise,
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
    ExerciseRecordService exerciseRecordService,
    DateFormat dateFormat,
    String exerciseType,
  ) {
    final maxWeight = double.tryParse(maxWeightController.text) ?? 0;
    final roundedMaxWeight = roundWeight(maxWeight, exercise.type);

    if (record != null) {
      exerciseRecordService.updateExerciseRecord(
        userId: athleteId,
        exerciseId: exercise.exerciseId!,
        recordId: record.id,
        maxWeight: roundedMaxWeight.round(),
        repetitions: 1,
      );
    } else {
      exerciseRecordService.addExerciseRecord(
        userId: athleteId,
        exerciseId: exercise.exerciseId!,
        exerciseName: exercise.name,
        maxWeight: roundedMaxWeight.round(),
        repetitions: 1,
        date: dateFormat.format(DateTime.now()),
      );
    }

    controller.updateExercise(exercise);
  }

  void _showReorderExercisesDialog(
      BuildContext context, int weekIndex, int workoutIndex) {
    final exerciseNames = controller
        .program.weeks[weekIndex].workouts[workoutIndex].exercises
        .map((exercise) => exercise.name)
        .toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: exerciseNames,
        onReorder: (oldIndex, newIndex) => controller.reorderExercises(
            weekIndex, workoutIndex, oldIndex, newIndex),
      ),
    );
  }

  void _showAddToSuperSetDialog(
    BuildContext context,
    Exercise exercise,
    ColorScheme colorScheme,
  ) {
    String? selectedSuperSetId;
    final superSets =
        controller.program.weeks[weekIndex].workouts[workoutIndex].superSets;

    if (superSets.isEmpty) {
      controller.createSuperSet(weekIndex, workoutIndex);
      selectedSuperSetId = controller
          .program.weeks[weekIndex].workouts[workoutIndex].superSets.first.id;
      controller.addExerciseToSuperSet(
        weekIndex,
        workoutIndex,
        selectedSuperSetId,
        exercise.id!,
      );
    } else {
      showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext builderContext, setState) {
              return AlertDialog(
                backgroundColor: colorScheme.surface,
                title: Text(
                  'Aggiungi al Superset',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
                content: DropdownButtonFormField<String>(
                  value: selectedSuperSetId,
                  items: superSets.map((ss) {
                    return DropdownMenuItem<String>(
                      value: ss.id,
                      child: Text(
                        ss.name ?? '',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSuperSetId = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Seleziona il Superset',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: Text(
                      'Annulla',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (superSets.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        controller.createSuperSet(weekIndex, workoutIndex);
                        setState(() {});
                        Navigator.of(dialogContext).pop(superSets.last.id);
                      },
                      child: Text(
                        'Crea Nuovo Superset',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(selectedSuperSetId),
                    child: Text(
                      'Aggiungi',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ).then((result) {
        if (result != null) {
          controller.addExerciseToSuperSet(
            weekIndex,
            workoutIndex,
            result,
            exercise.id!,
          );
        }
      });
    }
  }

  void _showSetProgressionScreen(
    BuildContext context,
    Exercise exercise,
    num latestMaxWeight,
    ColorScheme colorScheme,
  ) {
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
        controller.updateExercise(updatedExercise);
      }
    });
  }

  void _navigateToExerciseDetails(BuildContext context,
      {required String? userId,
      required String? programId,
      required String? weekId,
      required String? workoutId,
      required String? exerciseId,
      required List<SuperSet> superSets,
      required int superSetExerciseIndex,
      required List<Series> seriesList,
      required int startIndex}) {
    if (userId == null ||
        programId == null ||
        weekId == null ||
        workoutId == null ||
        exerciseId == null) return;

    context.go(
        '/user_programs/training_viewer/week_details/workout_details/exercise_details',
        extra: {
          'programId': programId,
          'weekId': weekId,
          'workoutId': workoutId,
          'exerciseId': exerciseId,
          'userId': userId,
          'superSetExercises': superSets.map((s) => s.toMap()).toList(),
          'superSetExerciseIndex': superSetExerciseIndex,
          'seriesList': seriesList.map((s) => s.toMap()).toList(),
          'startIndex': startIndex
        });
  }

  void _showBulkSeriesDialog(
    BuildContext context,
    Exercise exercise,
    ColorScheme colorScheme,
  ) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];

    showDialog(
      context: context,
      builder: (context) => BulkSeriesSelectionDialog(
        initialExercise: exercise,
        workoutExercises: workout.exercises,
        colorScheme: colorScheme,
        onNext: (selectedExercises) {
          _showBulkSeriesManagementDialog(
            context,
            selectedExercises,
            colorScheme,
          );
        },
      ),
    );
  }

  void _showBulkSeriesManagementDialog(
    BuildContext context,
    List<Exercise> exercises,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => BulkSeriesConfigurationDialog(
        exercises: exercises,
        colorScheme: colorScheme,
        controller: controller,
        weekIndex: weekIndex,
        workoutIndex: workoutIndex,
      ),
    );
  }
}
