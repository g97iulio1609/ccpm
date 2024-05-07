import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/training_model.dart';
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

class _SetProgressionScreenState extends ConsumerState<SetProgressionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final programController = ref.read(trainingProgramControllerProvider);
      final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

      final controllerCount = weekProgressions.expand((week) => week.expand((session) => session.series)).length;
      ref.read(controllerProvider.notifier).initialize(controllerCount);
      ref.read(focusNodesProvider.notifier).initialize(controllerCount);

      int controllerIndex = 0;
      for (final weekProgression in weekProgressions) {
        for (final sessionProgression in weekProgression) {
          for (final series in sessionProgression.series) {
            ref.read(controllerProvider.notifier).state[controllerIndex][0].text = series.reps.toString();
            ref.read(controllerProvider.notifier).state[controllerIndex][1].text = series.sets.toString();
            ref.read(controllerProvider.notifier).state[controllerIndex][2].text = series.weight.toString();
            ref.read(controllerProvider.notifier).state[controllerIndex][3].text = series.intensity;
            ref.read(controllerProvider.notifier).state[controllerIndex][4].text = series.rpe;
            controllerIndex++;
          }
        }
      }
    });
  }

  List<List<dynamic>> _groupSeries(List<Series> series) {
    final groupedSeries = <List<dynamic>>[];
    List<Series> currentGroup = [];

    for (int i = 0; i < series.length; i++) {
      final currentSeries = series[i];
      if (i == 0 || currentSeries.reps != series[i - 1].reps || currentSeries.weight != series[i - 1].weight) {
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

  void _updateWeightFromIntensity(int index, String intensity) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

    final groupedSeries = _groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());

    for (final currentProgression in groupedSeries[index]) {
      if (intensity.isNotEmpty) {
        final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(widget.latestMaxWeight.toDouble(), double.parse(intensity));
        currentProgression.weight = SeriesUtils.roundWeight(calculatedWeight, widget.exercise?.type);
      } else {
        currentProgression.weight = 0.0;
      }
      currentProgression.intensity = intensity;

      _updateSeriesInProgressions(weekProgressions, currentProgression);
    }

    final intensityControllerIndex = index * 5 + 3;
    ref.read(controllerProvider.notifier).state[index][intensityControllerIndex].text = intensity;
    ref.read(controllerProvider.notifier).state[index][intensityControllerIndex].selection = TextSelection.collapsed(offset: intensity.length);

    final weightControllerIndex = index * 5 + 2;
    ref.read(controllerProvider.notifier).state[index][weightControllerIndex].text = groupedSeries[index].first.weight.toStringAsFixed(2);
  }

  void _updateWeightFromRPE(int index, String rpe, int reps) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

    final groupedSeries = _groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());

    for (final currentProgression in groupedSeries[index]) {
      SeriesUtils.updateWeightFromRPE(
        ref.read(controllerProvider.notifier).state[index][index * 5],
        ref.read(controllerProvider.notifier).state[index][index * 5 + 2],
        ref.read(controllerProvider.notifier).state[index][index * 5 + 4],
        ref.read(controllerProvider.notifier).state[index][index * 5 + 3],
        widget.exercise?.type ?? '',
        widget.latestMaxWeight,
        ValueNotifier<double>(0.0),
      );

      _updateSeriesInProgressions(weekProgressions, currentProgression);
    }
  }

  void _updateIntensityFromWeight(int index, double weight) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

    final groupedSeries = _groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());
    final focusNodes = ref.read(focusNodesProvider);

    for (final currentProgression in groupedSeries[index]) {
      if (weight != 0 && !focusNodes[index * 4 + 3].hasFocus) {
        currentProgression.intensity = SeriesUtils.calculateIntensityFromWeight(weight, widget.latestMaxWeight.toDouble()).toStringAsFixed(2);
        final intensityControllerIndex = index * 5 + 3;
        ref.read(controllerProvider.notifier).state[index][intensityControllerIndex].text = currentProgression.intensity;
      }

      _updateSeriesInProgressions(weekProgressions, currentProgression);
    }
  }

  void _updateProgression(int index, int reps, String intensity, String rpe, double weight) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

    final groupedSeries = _groupSeries(weekProgressions.expand((week) => week.expand((session) => session.series)).toList());

    final seriesInGroup = groupedSeries[index] as List<Series>;
    final sets = seriesInGroup.length;

    for (final currentProgression in seriesInGroup) {
      currentProgression.reps = reps;
      currentProgression.sets = sets;
      currentProgression.intensity = intensity;
      currentProgression.rpe = rpe;
      currentProgression.weight = weight;

      _updateSeriesInProgressions(weekProgressions, currentProgression);
    }
  }

  void _updateSeriesInProgressions(List<List<WeekProgression>> weekProgressions, Series updatedSeries) {
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
  final controllers = ref.watch(controllerProvider);
  final focusNodes = ref.watch(focusNodesProvider);
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;

  final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);
  final series = weekProgressions.expand((week) => week.expand((session) => session.series)).toList();
  final groupedSeries = _groupSeries(series);

Widget buildTextField({
  required int index,
  required String labelText,
  required TextInputType keyboardType,
  required Function(String) onChanged,
}) {
  final controller = controllers[index ~/ 5][index % 5];
  final focusNode = FocusNode();
  return Expanded(
    child: TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDarkMode ? colorScheme.onBackground : colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: isDarkMode ? colorScheme.onBackground : colorScheme.onSurface,
        ),
        filled: true,
        fillColor: isDarkMode ? colorScheme.surface : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    ),
  );
}

 return Scaffold(
    backgroundColor: isDarkMode ? colorScheme.background : colorScheme.surface,
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: groupedSeries.length,
              itemBuilder: (context, seriesIndex) {
                final series = groupedSeries[seriesIndex];
                final reps = series.first.reps;
                final sets = series.length;
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
                      Text(
                        'Week ${weekIndex + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? colorScheme.onBackground : colorScheme.onSurface,
                        ),
                      ),
                    if (seriesIndex == 0 || (previousSessionIndex != -1 && sessionIndex != previousSessionIndex))
                      Text(
                        'Session ${sessionIndex + 1}',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? colorScheme.onBackground : colorScheme.onSurface,
                        ),
                      ),
                  
                    Row(
                      children: [
                        buildTextField(
                          index: seriesIndex * 5,
                          labelText: 'Reps',
                          keyboardType: TextInputType.number,
                          onChanged: (value) => _updateProgression(
                            seriesIndex,
                            int.tryParse(value) ?? 0,
                            intensity,
                            rpe,
                            weight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        buildTextField(
                          index: seriesIndex * 5 + 1,
                          labelText: 'Sets',
                          keyboardType: TextInputType.number,
                          onChanged: (value) {},
                        ),
                        const SizedBox(width: 8),
                        buildTextField(
                          index: seriesIndex * 5 + 3,
                          labelText: '1RM%',
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateProgression(
                              seriesIndex,
                              reps,
                              value,
                              rpe,
                              weight,
                            );
                            _updateWeightFromIntensity(seriesIndex, value);
                          },
                        ),
                        const SizedBox(width: 8),
                        buildTextField(
                          index: seriesIndex * 5 + 4,
                          labelText: 'RPE',
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _updateProgression(
                              seriesIndex,
                              reps,
                              intensity,
                              value,
                              weight,
                            );
                            _updateWeightFromRPE(seriesIndex, value, reps);
                          },
                        ),
                        const SizedBox(width: 8),
                        buildTextField(
                          index: seriesIndex * 5 + 2,
                          labelText: 'Weight',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (value) {
                            final weight = double.tryParse(value) ?? 0;
                            _updateProgression(
                              seriesIndex,
                              reps,
                              intensity,
                              rpe,
                              weight,
                            );
                            _updateIntensityFromWeight(seriesIndex, weight);
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
            ElevatedButton(
              onPressed: () async {
                final programController = ref.read(trainingProgramControllerProvider);
                final weekProgressions = buildWeekProgressions(programController.program.weeks, widget.exercise!);

                _updateProgressionsFromFields(weekProgressions);

                await updateExerciseProgressions(widget.exercise!, weekProgressions, context);
                await programController.applyWeekProgressions(
                  programController.program.weeks
                      .expand((week) => week.workouts)
                      .expand((workout) => workout.exercises)
                      .toList()
                      .indexOf(widget.exercise!),
                  weekProgressions,
                  context,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? colorScheme.primary : colorScheme.secondary,
                foregroundColor: isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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

  void _updateProgressionsFromFields(List<List<WeekProgression>> weekProgressions) {
    final controllers = ref.read(controllerProvider);
    int progressionIndex = 0;

    for (final weekProgression in weekProgressions) {
      for (final sessionProgression in weekProgression) {
        for (final series in sessionProgression.series) {
          series.reps = int.parse(controllers[progressionIndex][0].text);
          series.sets = int.parse(controllers[progressionIndex][1].text);
          series.weight = double.parse(controllers[progressionIndex][2].text);
          series.intensity = controllers[progressionIndex][3].text;
          series.rpe = controllers[progressionIndex][4].text;
          progressionIndex++;
        }
      }
    }
  }

  Future<void> updateExerciseProgressions(Exercise exercise, List<List<WeekProgression>> updatedProgressions, BuildContext context) async {
    debugPrint('Updating exercise progressions for exercise: ${exercise.name}');

    final programController = ref.read(trainingProgramControllerProvider);

    for (int weekIndex = 0; weekIndex < programController.program.weeks.length; weekIndex++) {
      final week = programController.program.weeks[weekIndex];
      debugPrint('Processing week ${weekIndex + 1}');
      for (int workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
        final workout = week.workouts[workoutIndex];
        final exerciseIndex = workout.exercises.indexWhere((e) => e.exerciseId == exercise.exerciseId);
        if (exerciseIndex != -1) {
          final currentExercise = workout.exercises[exerciseIndex];
          debugPrint('Found exercise in week ${weekIndex + 1}, workout ${workoutIndex + 1}, exercise index $exerciseIndex');

          // Assicurati che la lista weekProgressions dell'esercizio corrente sia inizializzata
          if (currentExercise.weekProgressions.length <= weekIndex) {
            currentExercise.weekProgressions = List.generate(programController.program.weeks.length, (_) => []);
          }

          // Aggiorna la proprietà weekProgressions dell'esercizio
          if (weekIndex < updatedProgressions.length) {
            currentExercise.weekProgressions[weekIndex] = updatedProgressions[weekIndex];
            debugPrint('Updated weekProgressions for week ${weekIndex + 1}: ${updatedProgressions[weekIndex]}');
          }

          // Aggiorna le serie dell'esercizio in base alla progressione della sessione corrente
          final sessionIndex = workoutIndex;
          final exerciseProgressions = currentExercise.weekProgressions[weekIndex];
          if (sessionIndex < exerciseProgressions.length) {
            final progression = exerciseProgressions[sessionIndex];
            debugPrint('Applying progression for week ${weekIndex + 1}, session ${sessionIndex + 1}: $progression');

            // Utilizza i valori inseriti nella schermata SetProgressionScreen
            currentExercise.series = List.generate(progression.series.length, (index) {
              final series = progression.series[index];
              final newSeries = Series(
                serieId: generateRandomId(16).toString(),
                reps: series.reps,
                sets: series.sets,
                intensity: series.intensity,
                rpe: series.rpe,
                weight: series.weight,
                order: index + 1,
                done: false,
                reps_done: 0,
                weight_done: 0.0,
              );
              debugPrint('Generated series: reps=${newSeries.reps}, sets=${newSeries.sets}, intensity=${newSeries.intensity}, rpe=${newSeries.rpe}, weight=${newSeries.weight}');
              return newSeries;
            });
            debugPrint('Updated exercise series: ${currentExercise.series}');
          } else {
            debugPrint('Invalid session index for week ${weekIndex + 1}, session ${sessionIndex + 1}');
          }
        }
      }
    }
    debugPrint('Finished updating exercise progressions');

    programController.notifyListeners();
  }

List<List<WeekProgression>> buildWeekProgressions(List<Week> weeks, Exercise exercise) {
  final progressions = List.generate(weeks.length, (weekIndex) {
    final week = weeks[weekIndex];
    final workouts = week.workouts;
    debugPrint('Week ${weekIndex + 1}:');
    final exerciseProgressions = workouts.map((workout) {
      debugPrint('  Workout ${workout.order}:');
      final exerciseInWorkout = workout.exercises.firstWhere(
        (e) => e.exerciseId == exercise.exerciseId,
        orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
      );

      final existingProgressions = exerciseInWorkout.weekProgressions;
      WeekProgression? sessionProgression;
      if (existingProgressions.isNotEmpty && existingProgressions.length > weekIndex) {
        sessionProgression = existingProgressions[weekIndex].firstWhere(
          (progression) => progression.sessionNumber == workout.order,
        );
      }

      if (sessionProgression != null && sessionProgression.series.isNotEmpty) {
        debugPrint('    Progressione esistente trovata per la sessione ${workout.order}');
        return sessionProgression;
      } else {
        debugPrint('    Nessuna progressione esistente trovata per la sessione ${workout.order}');
        final groupedSeries = _groupSeries(exerciseInWorkout.series);
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

    debugPrint('  Progressioni per la settimana ${weekIndex + 1}: $exerciseProgressions');
    return exerciseProgressions;
  });

  debugPrint('Progressioni finali: $progressions');
  return progressions;
}
}
