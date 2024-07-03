import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/progressions_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/week_model.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final controllerProvider = StateNotifierProvider.autoDispose<ControllerNotifier, List<List<TextEditingController>>>((ref) {
  return ControllerNotifier([]);
});

class ControllerNotifier extends StateNotifier<List<List<TextEditingController>>> {
  ControllerNotifier(super.state);

  void initialize(int count) {
    final controllers = List.generate(
      count,
      (index) => List.generate(
        5,
        (seriesIndex) => TextEditingController(),
      ),
    );
    state = [...controllers];
  }


 void updateController(int outerIndex, int innerIndex, String text) {
    if (outerIndex < 0 || outerIndex >= state.length || innerIndex < 0 || innerIndex >= state[outerIndex].length) {
      debugPrint('LOG: Invalid indices for updateController: $outerIndex, $innerIndex');
      return;
    }
    final updatedState = List<List<TextEditingController>>.from(state);
    updatedState[outerIndex][innerIndex].text = text;
    state = updatedState;
  }

  TextEditingController? getController(int outerIndex, int innerIndex) {
    if (outerIndex < 0 || outerIndex >= state.length || innerIndex < 0 || innerIndex >= state[outerIndex].length) {
      debugPrint('LOG: Invalid indices for getController: $outerIndex, $innerIndex');
      return null;
    }
    return state[outerIndex][innerIndex];
  }

  void deleteSeries(int count) {
    if (state.length > count) {
      state = state.sublist(0, count);
    }
  }

  int get length => state.length;

 @override
  void dispose() {
    for (final controllerList in state) {
      for (final controller in controllerList) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}


final focusNodesProvider = StateNotifierProvider.autoDispose<FocusNodesNotifier, List<FocusNode>>((ref) {
  return FocusNodesNotifier([]);
});

class FocusNodesNotifier extends StateNotifier<List<FocusNode>> {
  FocusNodesNotifier(super.state);

  void initialize(int count) {
    final focusNodes = List<FocusNode>.generate(count, (_) => FocusNode());
    state = [...focusNodes];
  }

  FocusNode? getFocusNode(int index) {
    if (index < 0 || index >= state.length) {
      debugPrint('LOG: Invalid index for getFocusNode: $index');
      return null;
    }
    return state[index];
  }

  @override
  void dispose() {
    for (final focusNode in state) {
      focusNode.dispose();
    }
    super.dispose();
  }
}

class SetProgressionScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final Exercise? exercise;
  final num latestMaxWeight;

  const SetProgressionScreen({
    required this.exerciseId,
    this.exercise,
    required this.latestMaxWeight,
    super.key,
  });

  @override
  ConsumerState<SetProgressionScreen> createState() => _SetProgressionScreenState();
}

class _SetProgressionScreenState extends ConsumerState<SetProgressionScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

void _initializeControllers() {
  final programController = ref.read(trainingProgramControllerProvider);
  final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

  // Calcola il numero totale di serie
  final totalSeriesCount = weekProgressions.fold<int>(0, (sum, week) {
    return sum + week.fold<int>(0, (innerSum, session) {
      return innerSum + session.series.length;
    });
  });

  debugPrint('LOG: Total series count: $totalSeriesCount');
  final controllerNotifier = ref.read(controllerProvider.notifier);
  controllerNotifier.initialize(totalSeriesCount);
  controllerNotifier.deleteSeries(totalSeriesCount);  // Rimuovi i controller in eccesso
  ref.read(focusNodesProvider.notifier).initialize(totalSeriesCount);

  int controllerIndex = 0;
  for (final weekProgression in weekProgressions) {
    for (final sessionProgression in weekProgression) {
      for (final series in sessionProgression.series) {
        debugPrint('LOG: Initializing controller for series: ${series.serieId} at index $controllerIndex');
        _updateControllerValues(controllerIndex, series);
        controllerIndex++;
      }
    }
  }
}

void _updateControllerValues(int controllerIndex, Series series) {
  debugPrint('LOG: Updating controller values for index: $controllerIndex, series: ${series.serieId}');
  final controllerNotifier = ref.read(controllerProvider.notifier);
  controllerNotifier.updateController(controllerIndex, 0, series.reps.toString());
  controllerNotifier.updateController(controllerIndex, 1, series.sets.toString());
  controllerNotifier.updateController(controllerIndex, 2, series.intensity);
  controllerNotifier.updateController(controllerIndex, 3, series.rpe);
  controllerNotifier.updateController(controllerIndex, 4, series.weight.toString());
}


  List<List<Series>> groupSeries(List<Series> series) {
    final groupedSeries = <List<Series>>[];
    List<Series> currentGroup = [];

    for (int i = 0; i < series.length; i++) {
      final currentSeries = series[i];

      if (i == 0 ||
          currentSeries.reps != series[i - 1].reps ||
          currentSeries.weight != series[i - 1].weight) {
        if (currentGroup.isNotEmpty) {
          groupedSeries.add(currentGroup);
          currentGroup = [];
        }
        currentGroup.add(currentSeries);
      } else {
        currentGroup.add(currentSeries);
      }
    }

    if (currentGroup.isNotEmpty) {
      groupedSeries.add(currentGroup);
    }

    return groupedSeries;
  }

void updateWeightFromIntensity(int controllerIndex, String intensity) {
  final programController = ref.read(trainingProgramControllerProvider);
  final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

  final seriesIndex = controllerIndex ~/ 5;
  final groupedSeries = groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());

  if (seriesIndex < 0 || seriesIndex >= groupedSeries.length) {
    debugPrint('Invalid seriesIndex: $seriesIndex');
    return;
  }

  for (final currentProgression in groupedSeries[seriesIndex]) {
    if (intensity.isNotEmpty) {
      final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(widget.latestMaxWeight.toDouble(), double.parse(intensity));
      currentProgression.weight = SeriesUtils.roundWeight(calculatedWeight, widget.exercise?.type);
    } else {
      currentProgression.weight = 0.0;
    }
    currentProgression.intensity = intensity;

    updateSeriesInProgressions(weekProgressions, currentProgression);
  }

  for (int i = 0; i < groupedSeries[seriesIndex].length; i++) {
    final weightControllerIndex = controllerIndex + (i * 5) + 2;
    ref.read(controllerProvider.notifier).updateController(seriesIndex, weightControllerIndex % 5, groupedSeries[seriesIndex][i].weight.toStringAsFixed(2));
  }
}

void _updateWeightFromRPE(int controllerIndex, String rpe, int reps) {
  final programController = ref.read(trainingProgramControllerProvider);
  final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

  final seriesIndex = controllerIndex ~/ 5;
  final groupedSeries = groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());

  if (seriesIndex < 0 || seriesIndex >= groupedSeries.length) {
    debugPrint('Invalid seriesIndex: $seriesIndex');
    return;
  }

  for (final currentProgression in groupedSeries[seriesIndex]) {
    final repsController = ref.read(controllerProvider.notifier).getController(controllerIndex, 0);
    final weightController = ref.read(controllerProvider.notifier).getController(controllerIndex, 4);
    final rpeController = ref.read(controllerProvider.notifier).getController(controllerIndex, 3);
    final intensityController = ref.read(controllerProvider.notifier).getController(controllerIndex, 2);

    if (repsController != null && weightController != null && rpeController != null && intensityController != null) {
      SeriesUtils.updateWeightFromRPE(
        repsController,
        weightController,
        rpeController,
        intensityController,
        widget.exercise?.type ?? '',
        widget.latestMaxWeight,
        ValueNotifier<double>(0.0),
      );
    }

    updateSeriesInProgressions(weekProgressions, currentProgression);
  }

  for (int i = 0; i < groupedSeries[seriesIndex].length; i++) {
    final rpeControllerIndex = controllerIndex + (i * 5) + 4;
    ref.read(controllerProvider.notifier).updateController(seriesIndex, rpeControllerIndex % 5, groupedSeries[seriesIndex][i].weight.toStringAsFixed(2));
  }
}


void updateIntensityFromWeight(int controllerIndex, double weight) {
  final programController = ref.read(trainingProgramControllerProvider);
  final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

  final seriesIndex = controllerIndex ~/ 5;
  final groupedSeries = groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());
  final focusNodesNotifier = ref.read(focusNodesProvider.notifier);

  if (seriesIndex < 0 || seriesIndex >= groupedSeries.length) {
    debugPrint('LOG: Invalid seriesIndex: $seriesIndex');
    return;
  }

  for (final currentProgression in groupedSeries[seriesIndex]) {
    final focusNode = focusNodesNotifier.getFocusNode(controllerIndex + 2);
    if (weight != 0 && focusNode != null && !focusNode.hasFocus) {
      final calculatedIntensity = SeriesUtils.calculateIntensityFromWeight(weight, widget.latestMaxWeight.toDouble());
      currentProgression.intensity = calculatedIntensity.toStringAsFixed(2);
      final intensityControllerIndex = controllerIndex + 2;
      ref.read(controllerProvider.notifier).updateController(seriesIndex, intensityControllerIndex % 5, currentProgression.intensity);
    }

    updateSeriesInProgressions(weekProgressions, currentProgression);
  }

  for (int i = 0; i < groupedSeries[seriesIndex].length; i++) {
    final intensityControllerIndex = controllerIndex + (i * 5) + 2;
    ref.read(controllerProvider.notifier).updateController(seriesIndex, intensityControllerIndex % 5, double.parse(groupedSeries[seriesIndex][i].intensity).toStringAsFixed(2));
  }
}



void updateProgression(int controllerIndex, int reps, String intensity, String rpe, double weight) {
  final programController = ref.read(trainingProgramControllerProvider);
  final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

  final seriesIndex = controllerIndex ~/ 5;
  final groupedSeries = groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());

  if (seriesIndex < 0 || seriesIndex >= groupedSeries.length) {
    debugPrint('LOG: Invalid seriesIndex: $seriesIndex');
    return;
  }

  final seriesInGroup = groupedSeries[seriesIndex];
  final sets = seriesInGroup.length;

  debugPrint('LOG: Updating progression for series group index: $seriesIndex with reps: $reps, intensity: $intensity, rpe: $rpe, weight: $weight');

  for (final currentProgression in seriesInGroup) {
    currentProgression.reps = reps;
    currentProgression.sets = sets;
    currentProgression.intensity = intensity;
    currentProgression.rpe = rpe;
    currentProgression.weight = weight;

    debugPrint('LOG: Updated series: ${currentProgression.serieId}');
    updateSeriesInProgressions(weekProgressions, currentProgression);
  }

  for (int i = 0; i < seriesInGroup.length; i++) {
    final progressionControllerIndex = controllerIndex + (i * 5);
    debugPrint('LOG: Updating controller for progression index: $progressionControllerIndex');
    ref.read(controllerProvider.notifier).updateController(progressionControllerIndex ~/ 5, 0, reps.toString());
    ref.read(controllerProvider.notifier).updateController(progressionControllerIndex ~/ 5, 1, sets.toString());
    ref.read(controllerProvider.notifier).updateController(progressionControllerIndex ~/ 5, 2, intensity);
    ref.read(controllerProvider.notifier).updateController(progressionControllerIndex ~/ 5, 3, rpe);
    ref.read(controllerProvider.notifier).updateController(progressionControllerIndex ~/ 5, 4, weight.toString());
  }
}


 void updateSeriesInProgressions(List<List<WeekProgression>> weekProgressions, Series updatedSeries) {
  for (int weekIndex = 0; weekIndex < weekProgressions.length; weekIndex++) {
    for (int sessionIndex = 0; sessionIndex < weekProgressions[weekIndex].length; sessionIndex++) {
      final sessionProgression = weekProgressions[weekIndex][sessionIndex];
      final seriesIndex = sessionProgression.series.indexWhere((s) => s.serieId == updatedSeries.serieId);
      if (seriesIndex != -1) {
        weekProgressions[weekIndex][sessionIndex].series[seriesIndex] = updatedSeries;
      }
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final programController = ref.watch(trainingProgramControllerProvider);
    ref.watch(controllerProvider);
    ref.watch(focusNodesProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);
    final groupedSeries = groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());

    return Scaffold(
      backgroundColor: isDarkMode ? colorScheme.surface : colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: groupedSeries.length,
                itemBuilder: (context, seriesIndex) {
                  if (seriesIndex < 0 || seriesIndex >= groupedSeries.length) {
                    debugPrint('LOG: Invalid seriesIndex: $seriesIndex');
                    return const SizedBox.shrink();
                  }

                  final series = groupedSeries[seriesIndex];
                  final reps = series.first.reps;
                  final intensity = series.first.intensity;
                  final rpe = series.first.rpe;
                  final weight = series.first.weight;

                  WeekProgression? currentProgression;
                  int weekIndex = 0;
                  int sessionIndex = 0;
                  
                  for (int i = 0; i < weekProgressions.length; i++) {
                    for (int j = 0; j < weekProgressions[i].length; j++) {
                      final progression = weekProgressions[i][j];
                      if (progression.series.any((s) => series.contains(s))) {
                        currentProgression = progression;
                        weekIndex = i;
                        sessionIndex = j;
                        break;
                      }
                    }
                    if (currentProgression != null) {
                      break;
                    }
                  }

                  final previousProgression = seriesIndex > 0 ? groupedSeries[seriesIndex - 1].first : null;
                  final previousWeekIndex = previousProgression != null ? weekProgressions.indexWhere((week) => week.any((progression) => progression.series.contains(previousProgression))) : -1;
                  final previousSessionIndex = previousProgression != null && previousWeekIndex != -1 ? weekProgressions[previousWeekIndex].indexWhere((progression) => progression.series.contains(previousProgression)) : -1;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (seriesIndex == 0 || (previousWeekIndex != -1 && weekIndex != previousWeekIndex))
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 8),
                          child: Text('Week ${weekIndex + 1}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      if (seriesIndex == 0 || (previousSessionIndex != -1 && sessionIndex != previousSessionIndex))
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 24),
                          child: Text(
                            'Session ${sessionIndex + 1}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? colorScheme.onSurface : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          buildTextField(
                            index: seriesIndex * 5,
                            labelText: 'Reps',
                            keyboardType: TextInputType.number,
                            onChanged: (value) => updateProgression(
                              seriesIndex * 5,
                              int.tryParse(value) ?? 0,
                              intensity,
                              rpe,
                              weight,
                            ),
                          ),
                          buildTextField(
                            index: seriesIndex * 5 + 1,
                            labelText: 'Sets',
                            keyboardType: TextInputType.number,
                            onChanged: (value) {},
                          ),
                          buildTextField(
                            index: seriesIndex * 5 + 2,
                            labelText: '1RM%',
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              updateProgression(
                                seriesIndex * 5 + 2,
                                reps,
                                value,
                                rpe,
                                weight,
                              );
                              updateWeightFromIntensity(seriesIndex * 5 + 2, value);
                            },
                          ),
                          buildTextField(
                            index: seriesIndex * 5 + 3,
                            labelText: 'RPE',
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              updateProgression(
                                seriesIndex * 5 + 3,
                                reps,
                                intensity,
                                value,
                                weight,
                              );
                              _updateWeightFromRPE(seriesIndex * 5 + 3, value, reps);
                            },
                          ),
                          buildTextField(
                            index: seriesIndex * 5 + 4,
                            labelText: 'Weight',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              final weight = double.tryParse(value) ?? 0;
                              updateProgression(
                                seriesIndex * 5 + 4,
                                reps,
                                intensity,
                                rpe,
                                weight,
                              );
                              updateIntensityFromWeight(seriesIndex * 5 + 4, weight);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _handleSave(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.primary,
                foregroundColor: isDarkMode ? colorScheme.onPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField({
    required int index,
    required String labelText,
    required TextInputType keyboardType,
    required Function(String) onChanged,
  }) {
    final controller = ref.read(controllerProvider.notifier).getController(index ~/ 5, index % 5);
    final focusNode = FocusNode();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (controller == null) {
      debugPrint('LOG: Controller is null for index: $index');
      return const SizedBox.shrink();
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: const TextStyle(
              color: Colors.white,
            ),
            filled: true,
            fillColor: isDarkMode ? colorScheme.surface : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? colorScheme.onSurface.withOpacity(0.12) : colorScheme.onSurface.withOpacity(0.12),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDarkMode ? colorScheme.primary : colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

Future<void> _handleSave() async {
  final programController = ref.read(trainingProgramControllerProvider);
  final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);
  
  debugPrint('LOG: Handling save, updating progressions from fields for exercise: ${widget.exercise!.exerciseId}');
  updateProgressionsFromFields(weekProgressions);
  
  debugPrint('LOG: Applying progressions for exercise: ${widget.exercise!.exerciseId}');
  programController.updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);
  
  try {
    
    if (!mounted) return;
    
    // Tutte le operazioni che utilizzano BuildContext vengono eseguite qui
    _showSuccessMessage();
    _navigateBack();
  } catch (e) {
    debugPrint('ERROR: Failed to save changes: $e');
    if (!mounted) return;
    _showErrorMessage(e.toString());
  }
}

void _showSuccessMessage() {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Progressioni salvate con successo')),
  );
}

void _showErrorMessage(String errorMessage) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Errore durante il salvataggio delle progressioni: $errorMessage')),
  );
}

void _navigateBack() {
  Navigator.of(context).pop();
}

void updateProgressionsFromFields(List<List<WeekProgression>> weekProgressions) {
  final controllerNotifier = ref.read(controllerProvider.notifier);
  final programController = ref.read(trainingProgramControllerProvider);
  final program = programController.program;

  int controllerIndex = 0;
  for (int weekIndex = 0; weekIndex < weekProgressions.length; weekIndex++) {
    final weekProgression = weekProgressions[weekIndex];
    for (int workoutIndex = 0; workoutIndex < weekProgression.length; workoutIndex++) {
      final sessionProgression = weekProgression[workoutIndex];
      List<Series> newSeriesList = [];

      for (int seriesGroupIndex = 0; seriesGroupIndex < sessionProgression.series.length; seriesGroupIndex++) {
        final setsController = controllerNotifier.getController(controllerIndex, 1);
        final repsController = controllerNotifier.getController(controllerIndex, 0);
        final intensityController = controllerNotifier.getController(controllerIndex, 2);
        final rpeController = controllerNotifier.getController(controllerIndex, 3);
        final weightController = controllerNotifier.getController(controllerIndex, 4);

        if (setsController != null && repsController != null && intensityController != null &&
            rpeController != null && weightController != null) {
          final newSets = int.tryParse(setsController.text) ?? 1;
          final reps = int.tryParse(repsController.text) ?? 0;
          final intensity = intensityController.text;
          final rpe = rpeController.text;
          final weight = double.tryParse(weightController.text) ?? 0.0;

          for (int i = 0; i < newSets; i++) {
            Series newSeries = Series(
              serieId: generateRandomId(16).toString(),
              reps: reps,
              sets: 1,
              intensity: intensity,
              rpe: rpe,
              weight: weight,
              order: seriesGroupIndex + 1,
              done: false,
              reps_done: 0,
              weight_done: 0.0,
            );
            newSeriesList.add(newSeries);
          }

          debugPrint('LOG: Updated series group - Week: $weekIndex, Workout: $workoutIndex, Series Group: ${seriesGroupIndex + 1}, Sets: $newSets, Reps: $reps, Intensity: $intensity, RPE: $rpe, Weight: $weight');
        }

        controllerIndex++;
        if (controllerIndex >= controllerNotifier.length) {
          break;
        }
      }

      // Sostituisci le vecchie serie con le nuove serie
      sessionProgression.series = newSeriesList;
      debugPrint('LOG: Total series for Week $weekIndex, Workout $workoutIndex: ${newSeriesList.length}');

      if (controllerIndex >= controllerNotifier.length) {
        break;
      }
    }
  }

  // Aggiorna il programma con le progressioni modificate
  programController.updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);
}

Future<void> applyWeekProgressions(int exerciseIndex, List<List<WeekProgression>> progressions) async {
  final programController = ref.read(trainingProgramControllerProvider);
  final exercise = programController.program.weeks
      .expand((week) => week.workouts)
      .expand((workout) => workout.exercises)
      .toList()[exerciseIndex];

  for (int weekIndex = 0; weekIndex < programController.program.weeks.length; weekIndex++) {
    final week = programController.program.weeks[weekIndex];
    for (int workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
      final workout = week.workouts[workoutIndex];
      final exerciseIndexInWorkout = workout.exercises.indexWhere((e) => e.exerciseId == exercise.exerciseId);

      if (exerciseIndexInWorkout != -1) {
        final currentExercise = workout.exercises[exerciseIndexInWorkout];
        currentExercise.weekProgressions = progressions;
        debugPrint('LOG: Applied week progressions to exercise: ${currentExercise.exerciseId}');
      }
    }
  }

  debugPrint('LOG: Program saved successfully');
}



 
  Future<void> updateExerciseProgressions(Exercise exercise, List<List<WeekProgression>> updatedProgressions) async {
    final programController = ref.read(trainingProgramControllerProvider);

    for (int weekIndex = 0; weekIndex < programController.program.weeks.length; weekIndex++) {
      final week = programController.program.weeks[weekIndex];
      for (int workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
        final workout = week.workouts[workoutIndex];
        final exerciseIndex = workout.exercises.indexWhere((e) => e.exerciseId == exercise.exerciseId);
        if (exerciseIndex != -1) {
          final currentExercise = workout.exercises[exerciseIndex];

          if (currentExercise.weekProgressions.length <= weekIndex) {
            currentExercise.weekProgressions = List.generate(programController.program.weeks.length, (_) => []);
          }

          if (weekIndex < updatedProgressions.length) {
            currentExercise.weekProgressions[weekIndex] = updatedProgressions[weekIndex];
          }

          final sessionIndex = workoutIndex;
          final exerciseProgressions = currentExercise.weekProgressions[weekIndex];
          if (sessionIndex < exerciseProgressions.length) {
            final progression = exerciseProgressions[sessionIndex];

            currentExercise.series = progression.series.map((series) {
              return Series(
                serieId: series.serieId,
                reps: series.reps,
                sets: series.sets,
                intensity: series.intensity,
                rpe: series.rpe,
                weight: series.weight,
                order: series.order,
                done: false,
                reps_done: 0,
                weight_done: 0.0,
              );
            }).toList();
          }
        }
      }
    }
  }

  List<List<WeekProgression>> buildWeekProgressions(List<Week> weeks, Exercise exercise) {
    final progressions = List.generate(weeks.length, (weekIndex) {
      final week = weeks[weekIndex];
      final workouts = week.workouts;
      final exerciseProgressions = workouts.map((workout) {
        final exerciseInWorkout = workout.exercises.firstWhere(
          (e) => e.exerciseId == exercise.exerciseId,
          orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
        );

        final existingProgressions = exerciseInWorkout.weekProgressions;
        WeekProgression? sessionProgression;
        if (existingProgressions.isNotEmpty && existingProgressions.length > weekIndex) {
          sessionProgression = existingProgressions[weekIndex].firstWhere(
            (progression) => progression.sessionNumber == workout.order,
            orElse: () => WeekProgression(weekNumber: weekIndex + 1, sessionNumber: workout.order, series: []),
          );
        }

        if (sessionProgression != null && sessionProgression.series.isNotEmpty) {
          final groupedSeries = groupSeries(sessionProgression.series);
          return WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: workout.order,
            series: groupedSeries.map((group) {
              final series = group.first;
              return Series(
                serieId: series.serieId,
                reps: series.reps,
                sets: group.length,
                intensity: series.intensity,
                rpe: series.rpe,
                weight: series.weight,
                order: series.order,
                done: series.done,
                reps_done: series.reps_done,
                weight_done: series.weight_done,
              );
            }).toList(),
          );
        } else {
          final groupedSeries = groupSeries(exerciseInWorkout.series);
          return WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: workout.order,
            series: groupedSeries.map((group) {
              final series = group.first;
              return Series(
                serieId: series.serieId,
                reps: series.reps,
                sets: group.length,
                intensity: series.intensity,
                rpe: series.rpe,
                weight: series.weight,
                order: series.order,
                done: series.done,
                reps_done: series.reps_done,
                weight_done: series.weight_done,
              );
            }).toList(),
          );
        }
      }).toList();

      return exerciseProgressions;
    });

    return progressions;
  }
}


