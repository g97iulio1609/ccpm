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
  List<List<TextEditingController>> _repsControllers = [];
  List<List<TextEditingController>> _setsControllers = [];
  List<List<TextEditingController>> _weightControllers = [];
  List<List<TextEditingController>> _intensityControllers = [];
  List<List<FocusNode>> _repsFocusNodes = [];
  List<List<FocusNode>> _setsFocusNodes = [];
  List<List<FocusNode>> _weightFocusNodes = [];
  List<List<FocusNode>> _intensityFocusNodes = [];

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
            (sessionIndex) => TextEditingController(
                text: weekProgressions[weekIndex][sessionIndex]
                    .reps
                    .toString())));

    _setsControllers = List.generate(
        weekProgressions.length,
        (weekIndex) => List.generate(
            weekProgressions[weekIndex].length,
            (sessionIndex) => TextEditingController(
                text: weekProgressions[weekIndex][sessionIndex]
                    .sets
                    .toString())));

    _weightControllers = List.generate(
        weekProgressions.length,
        (weekIndex) => List.generate(
            weekProgressions[weekIndex].length,
            (sessionIndex) => TextEditingController(
                text: weekProgressions[weekIndex][sessionIndex]
                    .weight
                    .toString())));

    _intensityControllers = List.generate(
        weekProgressions.length,
        (weekIndex) => List.generate(
            weekProgressions[weekIndex].length,
            (sessionIndex) => TextEditingController(
                text: weekProgressions[weekIndex][sessionIndex].intensity)));

    _repsFocusNodes = List.generate(
        weekProgressions.length,
        (weekIndex) => List.generate(
            weekProgressions[weekIndex].length, (sessionIndex) => FocusNode()));

    _setsFocusNodes = List.generate(
        weekProgressions.length,
        (weekIndex) => List.generate(
            weekProgressions[weekIndex].length, (sessionIndex) => FocusNode()));

    _weightFocusNodes = List.generate(
        weekProgressions.length,
        (weekIndex) => List.generate(
            weekProgressions[weekIndex].length, (sessionIndex) => FocusNode()));

    _intensityFocusNodes = List.generate(
        weekProgressions.length,
        (weekIndex) => List.generate(
            weekProgressions[weekIndex].length, (sessionIndex) => FocusNode()));
  }

  @override
  void dispose() {
    for (var weekControllers in _repsControllers) {
      for (var controller in weekControllers) {
        controller.dispose();
      }
    }
    for (var weekControllers in _setsControllers) {
      for (var controller in weekControllers) {
        controller.dispose();
      }
    }
    for (var weekControllers in _weightControllers) {
      for (var controller in weekControllers) {
        controller.dispose();
      }
    }
    for (var weekControllers in _intensityControllers) {
      for (var controller in weekControllers) {
        controller.dispose();
      }
    }
    for (var weekFocusNodes in _repsFocusNodes) {
      for (var focusNode in weekFocusNodes) {
        focusNode.dispose();
      }
    }
    for (var weekFocusNodes in _setsFocusNodes) {
      for (var focusNode in weekFocusNodes) {
        focusNode.dispose();
      }
    }
    for (var weekFocusNodes in _weightFocusNodes) {
      for (var focusNode in weekFocusNodes) {
        focusNode.dispose();
      }
    }
    for (var weekFocusNodes in _intensityFocusNodes) {
      for (var focusNode in weekFocusNodes) {
        focusNode.dispose();
      }
    }
    super.dispose();
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

    void updateProgression(int weekIndex, int sessionIndex, int reps, int sets,
        String intensity, String rpe, double weight) {
      final currentProgression = weekProgressions[weekIndex][sessionIndex];

      currentProgression.reps = reps;
      currentProgression.sets = sets;
      currentProgression.intensity = intensity;
      currentProgression.rpe = rpe;
      currentProgression.weight = weight;
    }

    void updateWeightFromIntensity(
        int weekIndex, int sessionIndex, String intensity) {
      final currentProgression = weekProgressions[weekIndex][sessionIndex];

      if (intensity.isNotEmpty &&
          !_weightFocusNodes[weekIndex][sessionIndex].hasFocus) {
        final calculatedWeight = calculateWeightFromIntensity(
            widget.latestMaxWeight.toDouble(), double.parse(intensity));
        currentProgression.weight =
            roundWeight(calculatedWeight, widget.exercise?.type);
        _weightControllers[weekIndex][sessionIndex].text =
            currentProgression.weight.toString();
      }
    }

    void updateWeightFromRPE(
        int weekIndex, int sessionIndex, String rpe, int reps) {
      final currentProgression = weekProgressions[weekIndex][sessionIndex];

      if (rpe.isNotEmpty &&
          !_weightFocusNodes[weekIndex][sessionIndex].hasFocus) {
        final rpePercentage =
            SeriesUtils.getRPEPercentage(double.parse(rpe), reps);
        final calculatedWeight =
            widget.latestMaxWeight.toDouble() * rpePercentage;
        currentProgression.weight =
            roundWeight(calculatedWeight, widget.exercise?.type);
        _weightControllers[weekIndex][sessionIndex].text =
            currentProgression.weight.toString();
      }
    }

    void updateIntensityFromWeight(
        int weekIndex, int sessionIndex, double weight) {
      final currentProgression = weekProgressions[weekIndex][sessionIndex];

      if (weight != 0 &&
          !_intensityFocusNodes[weekIndex][sessionIndex].hasFocus) {
        currentProgression.intensity = calculateIntensityFromWeight(
                weight, widget.latestMaxWeight.toDouble())
            .toStringAsFixed(2);
        _intensityControllers[weekIndex][sessionIndex].text =
            currentProgression.intensity;
      }
    }

    Widget buildTextField({
      TextEditingController? controller,
      FocusNode? focusNode,
      String? initialValue,
      String? labelText,
      TextInputType keyboardType = TextInputType.text,
      required Function(String) onChanged,
      required bool isDarkMode,
      required ColorScheme colorScheme,
    }) {
      return Expanded(
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          initialValue: initialValue,
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
          onChanged: onChanged,
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDarkMode ? colorScheme.background : colorScheme.surface,
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
                                Row(
                                  children: [
                                    buildTextField(
                                      controller: _repsControllers[weekIndex]
                                          [sessionIndex],
                                      focusNode: _repsFocusNodes[weekIndex]
                                          [sessionIndex],
                                      labelText: 'Reps',
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => updateProgression(
                                        weekIndex,
                                        sessionIndex,
                                        int.tryParse(value) ?? 0,
                                        progression.sets,
                                        progression.intensity,
                                        progression.rpe,
                                        progression.weight,
                                      ),
                                      isDarkMode: isDarkMode,
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 8),
                                    buildTextField(
                                      controller: _setsControllers[weekIndex]
                                          [sessionIndex],
                                      focusNode: _setsFocusNodes[weekIndex]
                                          [sessionIndex],
                                      labelText: 'Sets',
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => updateProgression(
                                        weekIndex,
                                        sessionIndex,
                                        progression.reps,
                                        int.tryParse(value) ?? 0,
                                        progression.intensity,
                                        progression.rpe,
                                        progression.weight,
                                      ),
                                      isDarkMode: isDarkMode,
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 8),
                                    buildTextField(
                                      controller:
                                          _intensityControllers[weekIndex]
                                              [sessionIndex],
                                      focusNode: _intensityFocusNodes[weekIndex]
                                          [sessionIndex],
                                      labelText: '1RM%',
                                      onChanged: (value) {
                                        updateProgression(
                                          weekIndex,
                                          sessionIndex,
                                          progression.reps,
                                          progression.sets,
                                          value,
                                          progression.rpe,
                                          progression.weight,
                                        );
                                        updateWeightFromIntensity(
                                            weekIndex, sessionIndex, value);
                                      },
                                      isDarkMode: isDarkMode,
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 8),
                                    buildTextField(
                                      initialValue: progression.rpe,
                                      labelText: 'RPE',
                                      onChanged: (value) {
                                        updateProgression(
                                          weekIndex,
                                          sessionIndex,
                                          progression.reps,
                                          progression.sets,
                                          progression.intensity,
                                          value,
                                          progression.weight,
                                        );
                                        updateWeightFromRPE(
                                            weekIndex,
                                            sessionIndex,
                                            value,
                                            progression.reps);
                                      },
                                      isDarkMode: isDarkMode,
                                      colorScheme: colorScheme,
                                    ),
                                    const SizedBox(width: 8),
                                    buildTextField(
                                      controller: _weightControllers[weekIndex]
                                          [sessionIndex],
                                      focusNode: _weightFocusNodes[weekIndex]
                                          [sessionIndex],
                                      labelText: 'Weight',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (value) {
                                        final weight =
                                            double.tryParse(value) ?? 0;
                                        updateProgression(
                                          weekIndex,
                                          sessionIndex,
                                          progression.reps,
                                          progression.sets,
                                          progression.intensity,
                                          progression.rpe,
                                          weight,
                                        );
                                        updateIntensityFromWeight(
                                            weekIndex, sessionIndex, weight);
                                      },
                                      isDarkMode: isDarkMode,
                                      colorScheme: colorScheme,
                                    ),
                                  ],
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
                    context);
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
