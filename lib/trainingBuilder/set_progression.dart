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
  List<TextEditingController> _repsControllers = [];
  List<TextEditingController> _setsControllers = [];
  List<TextEditingController> _weightControllers = [];
  List<TextEditingController> _intensityControllers = [];
  List<FocusNode> _repsFocusNodes = [];
  List<FocusNode> _setsFocusNodes = [];
  List<FocusNode> _weightFocusNodes = [];
  List<FocusNode> _intensityFocusNodes = [];

  @override
  void initState() {
    super.initState();
    final programController = ref.read(trainingProgramControllerProvider);
    final progressionController = ref.read(progressionControllerProvider);
    final weekProgressions = progressionController.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);
    _repsControllers = List.generate(
        weekProgressions.length,
        (index) => TextEditingController(
            text: weekProgressions[index].reps.toString()));
    _setsControllers = List.generate(
        weekProgressions.length,
        (index) => TextEditingController(
            text: weekProgressions[index].sets.toString()));
    _weightControllers = List.generate(
        weekProgressions.length,
        (index) => TextEditingController(
            text: weekProgressions[index].weight.toString()));
    _intensityControllers = List.generate(
        weekProgressions.length,
        (index) =>
            TextEditingController(text: weekProgressions[index].intensity));
    _repsFocusNodes =
        List.generate(weekProgressions.length, (index) => FocusNode());
    _setsFocusNodes =
        List.generate(weekProgressions.length, (index) => FocusNode());
    _weightFocusNodes =
        List.generate(weekProgressions.length, (index) => FocusNode());
    _intensityFocusNodes =
        List.generate(weekProgressions.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _repsControllers) {
      controller.dispose();
    }
    for (var controller in _setsControllers) {
      controller.dispose();
    }
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    for (var controller in _intensityControllers) {
      controller.dispose();
    }
    for (var focusNode in _repsFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _setsFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _weightFocusNodes) {
      focusNode.dispose();
    }
    for (var focusNode in _intensityFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programController = ref.watch(trainingProgramControllerProvider);
    final progressionController = ref.watch(progressionControllerProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    List<WeekProgression> weekProgressions =
        progressionController.buildWeekProgressions(
            programController.program.weeks, widget.exercise!);

    void updateProgression(int weekIndex, int reps, int sets, String intensity,
        String rpe, double weight) {
      final currentProgression = weekProgressions[weekIndex];

      currentProgression.reps = reps;
      currentProgression.sets = sets;
      currentProgression.intensity = intensity;
      currentProgression.rpe = rpe;
      currentProgression.weight = weight;

      debugPrint(
          'Updating progression for week ${currentProgression.weekNumber}');
      debugPrint(
          'Reps: ${currentProgression.reps}, Sets: ${currentProgression.sets}, Intensity: ${currentProgression.intensity}, RPE: ${currentProgression.rpe}, Weight: ${currentProgression.weight}');
    }

    void updateWeightFromIntensity(int weekIndex, String intensity) {
      final currentProgression = weekProgressions[weekIndex];

      if (intensity.isNotEmpty && !_weightFocusNodes[weekIndex].hasFocus) {
        debugPrint('Calculating weight from intensity: $intensity');
        final calculatedWeight = calculateWeightFromIntensity(
            widget.latestMaxWeight.toDouble(), double.parse(intensity));
        currentProgression.weight =
            roundWeight(calculatedWeight, widget.exercise?.type);
        _weightControllers[weekIndex].text =
            currentProgression.weight.toString();
        debugPrint('Calculated weight: ${currentProgression.weight}');
      }
    }

    void updateWeightFromRPE(int weekIndex, String rpe, int reps) {
      final currentProgression = weekProgressions[weekIndex];

      if (rpe.isNotEmpty && !_weightFocusNodes[weekIndex].hasFocus) {
        debugPrint('Calculating weight from RPE: $rpe');
        final rpePercentage = getRPEPercentage(double.parse(rpe), reps);
        final calculatedWeight =
            widget.latestMaxWeight.toDouble() * rpePercentage;
        currentProgression.weight =
            roundWeight(calculatedWeight, widget.exercise?.type);
        _weightControllers[weekIndex].text =
            currentProgression.weight.toString();
        debugPrint('Calculated weight: ${currentProgression.weight}');
      }
    }

    void updateIntensityFromWeight(int weekIndex, double weight) {
      final currentProgression = weekProgressions[weekIndex];

      if (weight != 0 && !_intensityFocusNodes[weekIndex].hasFocus) {
        debugPrint('Updating intensity based on weight: $weight');
        currentProgression.intensity = calculateIntensityFromWeight(
                weight, widget.latestMaxWeight.toDouble())
            .toStringAsFixed(2);
        _intensityControllers[weekIndex].text = currentProgression.intensity;
        debugPrint('Updated intensity: ${currentProgression.intensity}');
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
    double? widthSize,
  }) {
    return SizedBox(
      width: widthSize,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        initialValue: initialValue,
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
  body: Flex(
    direction: Axis.vertical,
    children: [
      Expanded(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...weekProgressions.map((progression) {
                  final weekIndex = weekProgressions.indexOf(progression);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week ${progression.weekNumber}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? colorScheme.onBackground
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              buildTextField(
                                controller: _repsControllers[weekIndex],
                                focusNode: _repsFocusNodes[weekIndex],
                                labelText: 'Reps',
                                keyboardType: TextInputType.number,
                                onChanged: (value) => updateProgression(
                                  weekIndex,
                                  int.tryParse(value) ?? 0,
                                  progression.sets,
                                  progression.intensity,
                                  progression.rpe,
                                  progression.weight,
                                ),
                                isDarkMode: isDarkMode,
                                colorScheme: colorScheme,
                                widthSize: 53,
                              ),
                              buildTextField(
                                controller: _setsControllers[weekIndex],
                                focusNode: _setsFocusNodes[weekIndex],
                                labelText: 'Sets',
                                keyboardType: TextInputType.number,
                                onChanged: (value) => updateProgression(
                                  weekIndex,
                                  progression.reps,
                                  int.tryParse(value) ?? 0,
                                  progression.intensity,
                                  progression.rpe,
                                  progression.weight,
                                ),
                                isDarkMode: isDarkMode,
                                colorScheme: colorScheme,
                                widthSize: 53,
                              ),
                              buildTextField(
                                controller: _intensityControllers[weekIndex],
                                focusNode: _intensityFocusNodes[weekIndex],
                                labelText: '1RM%',
                                onChanged: (value) {
                                  updateProgression(
                                    weekIndex,
                                    progression.reps,
                                    progression.sets,
                                    value,
                                    progression.rpe,
                                    progression.weight,
                                  );
                                  updateWeightFromIntensity(
                                      weekIndex, value);
                                },
                                isDarkMode: isDarkMode,
                                colorScheme: colorScheme,
                                widthSize: 75,
                              ),
                              buildTextField(
                                initialValue: progression.rpe,
                                labelText: 'RPE',
                                onChanged: (value) {
                                  updateProgression(
                                    weekIndex,
                                    progression.reps,
                                    progression.sets,
                                    progression.intensity,
                                    value,
                                    progression.weight,
                                  );
                                  updateWeightFromRPE(
                                      weekIndex, value, progression.reps);
                                },
                                isDarkMode: isDarkMode,
                                colorScheme: colorScheme,
                                widthSize: 55,
                              ),
                              buildTextField(
                                controller: _weightControllers[weekIndex],
                                focusNode: _weightFocusNodes[weekIndex],
                                labelText: 'Weight',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (value) {
                                  final weight =
                                      double.tryParse(value) ?? 0;
                                  updateProgression(
                                    weekIndex,
                                    progression.reps,
                                    progression.sets,
                                    progression.intensity,
                                    progression.rpe,
                                    weight,
                                  );
                                  updateIntensityFromWeight(
                                      weekIndex, weight);
                                },
                                isDarkMode: isDarkMode,
                                colorScheme: colorScheme,
                                widthSize: 75,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
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
            foregroundColor:
                isDarkMode ? colorScheme.onPrimary : colorScheme.onSecondary,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Salva',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  ),
);

}}