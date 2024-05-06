import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/controller/progression_controller.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
  ConsumerState<SetProgressionScreen> createState() =>
      _SetProgressionScreenState();
}

class _SetProgressionScreenState extends ConsumerState<SetProgressionScreen> {
  List<List<List<TextEditingController>>> _repsControllers = [];
  List<List<List<TextEditingController>>> _setsControllers = [];
  List<List<List<TextEditingController>>> _weightControllers = [];
  List<List<List<TextEditingController>>> _intensityControllers = [];
  List<List<List<TextEditingController>>> _rpeControllers = [];
  List<List<List<FocusNode>>> _repsFocusNodes = [];
  List<List<List<FocusNode>>> _setsFocusNodes = [];
  List<List<List<FocusNode>>> _weightFocusNodes = [];
  List<List<List<FocusNode>>> _intensityFocusNodes = [];

  @override
  void initState() {
    super.initState();
    final programController = ref.read(trainingProgramControllerProvider);
    final progressionController = ref.read(progressionControllerProvider);
    final weekProgressions = progressionController.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    _repsControllers = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => TextEditingController(
            text: weekProgressions[weekIndex][sessionIndex]
                .series[seriesIndex]
                .reps
                .toString(),
          ),
        ),
      ),
    );

    _setsControllers = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => TextEditingController(
            text: weekProgressions[weekIndex][sessionIndex]
                .series[seriesIndex]
                .sets
                .toString(),
          ),
        ),
      ),
    );

    _weightControllers = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => TextEditingController(
            text: weekProgressions[weekIndex][sessionIndex]
                .series[seriesIndex]
                .weight
                .toString(),
          ),
        ),
      ),
    );

    _intensityControllers = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => TextEditingController(
            text: weekProgressions[weekIndex][sessionIndex]
                .series[seriesIndex]
                .intensity,
          ),
        ),
      ),
    );

    _rpeControllers = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => TextEditingController(
            text: weekProgressions[weekIndex][sessionIndex]
                .series[seriesIndex]
                .rpe,
          ),
        ),
      ),
    );

    _repsFocusNodes = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => FocusNode(),
        ),
      ),
    );

    _setsFocusNodes = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => FocusNode(),
        ),
      ),
    );

    _weightFocusNodes = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => FocusNode(),
        ),
      ),
    );

    _intensityFocusNodes = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) => List.generate(
          weekProgressions[weekIndex][sessionIndex].series.length,
          (seriesIndex) => FocusNode(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var weekControllers in _repsControllers) {
      for (var sessionControllers in weekControllers) {
        for (var controller in sessionControllers) {
          controller.dispose();
        }
      }
    }
    for (var weekControllers in _setsControllers) {
      for (var sessionControllers in weekControllers) {
        for (var controller in sessionControllers) {
          controller.dispose();
        }
      }
    }
    for (var weekControllers in _weightControllers) {
      for (var sessionControllers in weekControllers) {
        for (var controller in sessionControllers) {
          controller.dispose();
        }
      }
    }
    for (var weekControllers in _intensityControllers) {
      for (var sessionControllers in weekControllers) {
        for (var controller in sessionControllers) {
          controller.dispose();
        }
      }
    }
    for (var weekControllers in _rpeControllers) {
      for (var sessionControllers in weekControllers) {
        for (var controller in sessionControllers) {
          controller.dispose();
        }
      }
    }
    for (var weekFocusNodes in _repsFocusNodes) {
      for (var sessionFocusNodes in weekFocusNodes) {
        for (var focusNode in sessionFocusNodes) {
          focusNode.dispose();
        }
      }
    }
    for (var weekFocusNodes in _setsFocusNodes) {
      for (var sessionFocusNodes in weekFocusNodes) {
        for (var focusNode in sessionFocusNodes) {
          focusNode.dispose();
        }
      }
    }
    for (var weekFocusNodes in _weightFocusNodes) {
      for (var sessionFocusNodes in weekFocusNodes) {
        for (var focusNode in sessionFocusNodes) {
          focusNode.dispose();
        }
      }
    }
    for (var weekFocusNodes in _intensityFocusNodes) {
      for (var sessionFocusNodes in weekFocusNodes) {
        for (var focusNode in sessionFocusNodes) {
          focusNode.dispose();
        }
      }
    }
    super.dispose();
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

  void updateWeightFromIntensity(int weekIndex, int sessionIndex,
      int groupIndex, String intensity) {
    final programController = ref.read(trainingProgramControllerProvider);
    final progressionController = ref.read(progressionControllerProvider);
    final weekProgressions = progressionController.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    final seriesGroup =
        _groupSeries(weekProgressions[weekIndex][sessionIndex].series);

    for (final currentProgression in seriesGroup[groupIndex]) {
      if (intensity.isNotEmpty) {
        final calculatedWeight = SeriesUtils.calculateWeightFromIntensity(
            widget.latestMaxWeight.toDouble(), double.parse(intensity));
        currentProgression.weight =
            SeriesUtils.roundWeight(calculatedWeight, widget.exercise?.type);
      } else {
        currentProgression.weight = 0.0;
      }
      currentProgression.intensity = intensity;
    }

    _weightControllers[weekIndex][sessionIndex][groupIndex].text =
        seriesGroup[groupIndex].first.weight.toStringAsFixed(2);
    _intensityControllers[weekIndex][sessionIndex][groupIndex].text = intensity;
    _intensityControllers[weekIndex][sessionIndex][groupIndex].selection =
        TextSelection.collapsed(offset: intensity.length);
  }

  void updateWeightFromRPE(int weekIndex, int sessionIndex, int groupIndex,
      String rpe, int reps) {
    final programController = ref.read(trainingProgramControllerProvider);
    final progressionController = ref.read(progressionControllerProvider);
    final weekProgressions = progressionController.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    final seriesGroup =
        _groupSeries(weekProgressions[weekIndex][sessionIndex].series);

    for (final currentProgression in seriesGroup[groupIndex]) {
      SeriesUtils.updateWeightFromRPE(
        _repsControllers[weekIndex][sessionIndex][groupIndex],
        _weightControllers[weekIndex][sessionIndex][groupIndex],
        _rpeControllers[weekIndex][sessionIndex][groupIndex],
        _intensityControllers[weekIndex][sessionIndex][groupIndex],
        widget.exercise?.type ?? '',
        widget.latestMaxWeight,
        ValueNotifier<double>(0.0),
      );
    }
  }

  void updateIntensityFromWeight(
      int weekIndex, int sessionIndex, int groupIndex, double weight) {
    final programController = ref.read(trainingProgramControllerProvider);
    final progressionController = ref.read(progressionControllerProvider);
    final weekProgressions = progressionController.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    final seriesGroup =
        _groupSeries(weekProgressions[weekIndex][sessionIndex].series);

    for (final currentProgression in seriesGroup[groupIndex]) {
      if (weight != 0 &&
          !_intensityFocusNodes[weekIndex][sessionIndex][groupIndex].hasFocus) {
        currentProgression.intensity = SeriesUtils.calculateIntensityFromWeight(
                weight, widget.latestMaxWeight.toDouble())
            .toStringAsFixed(2);
        _intensityControllers[weekIndex][sessionIndex][groupIndex].text =
            currentProgression.intensity;
      }
    }
  }

void updateProgression(int weekIndex, int sessionIndex, int groupIndex,
    int reps, String intensity, String rpe, double weight) {
  debugPrint('updateProgression: weekIndex=$weekIndex, sessionIndex=$sessionIndex, groupIndex=$groupIndex');

  final programController = ref.read(trainingProgramControllerProvider);
  final progressionController = ref.read(progressionControllerProvider);
  final weekProgressions = progressionController.buildWeekProgressions(
      programController.program.weeks, widget.exercise!);

  debugPrint('Progressioni delle settimane: $weekProgressions');

  final seriesGroup =
      _groupSeries(weekProgressions[weekIndex][sessionIndex].series);

  debugPrint('Gruppo di serie: $seriesGroup');

  final seriesInGroup = seriesGroup[groupIndex] as List<Series>;
  final sets = seriesInGroup.length;

  debugPrint('Serie nel gruppo: $seriesInGroup');
  debugPrint('Numero di set: $sets');

  for (final currentProgression in seriesInGroup) {
    debugPrint('Serie corrente: $currentProgression');
    currentProgression.reps = reps;
    currentProgression.sets = sets;
    currentProgression.intensity = intensity;
    currentProgression.rpe = rpe;
    currentProgression.weight = weight;
    debugPrint('Serie aggiornata: $currentProgression');
  }
}

  @override
  Widget build(BuildContext context) {
    final programController = ref.watch(trainingProgramControllerProvider);
    final progressionController = ref.watch(progressionControllerProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    List<List<WeekProgression>> weekProgressions =
        progressionController.buildWeekProgressions(
            programController.program.weeks, widget.exercise!);

    List<List<List<List<dynamic>>>> groupedWeekProgressions = List.generate(
      weekProgressions.length,
      (weekIndex) => List.generate(
        weekProgressions[weekIndex].length,
        (sessionIndex) =>
            _groupSeries(weekProgressions[weekIndex][sessionIndex].series),
      ),
    );

    Widget buildTextField({
      TextEditingController? controller,
      FocusNode? focusNode,
      String? labelText,
      TextInputType keyboardType = TextInputType.text,
      required Function(String) onChanged,
      required bool isDarkMode,
      required ColorScheme colorScheme,
      int? groupIndex,
      int? weekIndex,
      int? sessionIndex,
      Series? series,
    }) {
      return Expanded(
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          style: TextStyle(
            color:
                isDarkMode ? colorScheme.onBackground : colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(
              color:
                  isDarkMode ? colorScheme.onBackground : colorScheme.onSurface,
            ),
            filled: true,
            fillColor: isDarkMode ? colorScheme.surface : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            if (labelText == 'Sets' &&
                groupIndex != null &&
                weekIndex != null &&
                sessionIndex != null &&
                series != null) {
              updateProgression(
                weekIndex,
                sessionIndex,
                groupIndex,
                series.reps,
                series.intensity,
                series.rpe,
                series.weight,
              );
            } else {
              onChanged(value);
            }
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDarkMode ?colorScheme.background : colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: weekProgressions.length,
                itemBuilder: (context, weekIndex) {
                  final weekProgression = weekProgressions[weekIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week ${weekIndex + 1}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? colorScheme.onBackground
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: weekProgression.length,
                        itemBuilder: (context, sessionIndex) {
                          final progression = weekProgression[sessionIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Session ${sessionIndex + 1}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? colorScheme.onBackground
                                        : colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: groupedWeekProgressions[weekIndex]
                                          [sessionIndex]
                                      .length,
                                  itemBuilder: (context, groupIndex) {
                                    final seriesGroup =
                                        groupedWeekProgressions[weekIndex]
                                            [sessionIndex][groupIndex];
                                    final series = seriesGroup.first;
                                    final sets = seriesGroup.length;
                                    return Row(
                                      children: [
                                        buildTextField(
                                          controller:
                                              _repsControllers[weekIndex]
                                                  [sessionIndex][groupIndex],
                                          focusNode: _repsFocusNodes[weekIndex]
                                              [sessionIndex][groupIndex],
                                          labelText: 'Reps',
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) =>
                                              updateProgression(
                                            weekIndex,
                                            sessionIndex,
                                            groupIndex,
                                            int.tryParse(value) ?? 0,
                                            series.intensity,
                                            series.rpe,
                                            series.weight,
                                          ),
                                          isDarkMode: isDarkMode,
                                          colorScheme: colorScheme,
                                        ),
                                        const SizedBox(width: 8),
                                        buildTextField(
                                          controller:
                                              _setsControllers[weekIndex]
                                                  [sessionIndex][groupIndex],
                                          focusNode: _setsFocusNodes[weekIndex]
                                              [sessionIndex][groupIndex],
                                          labelText: 'Sets',
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {},
                                          isDarkMode: isDarkMode,
                                          colorScheme: colorScheme,
                                          groupIndex: groupIndex,
                                          weekIndex: weekIndex,
                                          sessionIndex: sessionIndex,
                                          series: series,
                                        ),
                                        const SizedBox(width: 8),
                                        buildTextField(
                                          controller:
                                              _intensityControllers[weekIndex]
                                                  [sessionIndex][groupIndex],
                                          focusNode:
                                              _intensityFocusNodes[weekIndex]
                                                  [sessionIndex][groupIndex],
                                          labelText: '1RM%',
                                          onChanged: (value) {
                                            updateProgression(
                                              weekIndex,
                                              sessionIndex,
                                              groupIndex,
                                              series.reps,
                                              value,
                                              series.rpe,
                                              series.weight,
                                            );
                                            updateWeightFromIntensity(
                                              weekIndex,
                                              sessionIndex,
                                              groupIndex,
                                              value,
                                            );
                                          },
                                          isDarkMode: isDarkMode,
                                          colorScheme: colorScheme,
                                        ),
                                        const SizedBox(width: 8),
                                        buildTextField(
                                          controller: _rpeControllers[weekIndex]
                                              [sessionIndex][groupIndex],
                                          labelText: 'RPE',
                                          onChanged: (value) {
                                            updateProgression(
                                              weekIndex,
                                              sessionIndex,
                                              groupIndex,
                                              series.reps,
                                              series.intensity,
                                              value,
                                              series.weight,
                                            );
                                            updateWeightFromRPE(
                                              weekIndex,
                                              sessionIndex,
                                              groupIndex,
                                              value,
                                              series.reps,
                                            );
                                          },
                                          isDarkMode: isDarkMode,
                                          colorScheme: colorScheme,
                                        ),
                                        const SizedBox(width: 8),
                                        buildTextField(
                                          controller:
                                              _weightControllers[weekIndex]
                                                  [sessionIndex][groupIndex],
                                          focusNode: _weightFocusNodes[weekIndex]
                                              [sessionIndex][groupIndex],
                                          labelText: 'Weight',
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          onChanged: (value) {
                                            final weight =
                                                double.tryParse(value) ?? 0;
                                            updateProgression(
                                              weekIndex,
                                              sessionIndex,
                                              groupIndex,
                                              series.reps,
                                              series.intensity,
                                              series.rpe,
                                              weight,
                                            );
                                            updateIntensityFromWeight(
                                              weekIndex,
                                              sessionIndex,
                                              groupIndex,
                                              weight,
                                            );
                                          },
                                          isDarkMode: isDarkMode,
                                          colorScheme: colorScheme,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await progressionController.updateExerciseProgressions(
                    widget.exercise!, weekProgressions, context);
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
                backgroundColor:
                    isDarkMode ? colorScheme.primary : colorScheme.secondary,
                foregroundColor: isDarkMode
                    ? colorScheme.onPrimary
                    : colorScheme.onSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
}