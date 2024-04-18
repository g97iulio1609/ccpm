import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/controller/progression_controller.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
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
  ConsumerState<SetProgressionScreen> createState() => _SetProgressionScreenState();
}

class _SetProgressionScreenState extends ConsumerState<SetProgressionScreen> {
  List<TextEditingController> _weightControllers = [];

  @override
  void initState() {
    super.initState();
    final programController = ref.read(trainingProgramControllerProvider);
    final progressionController = ref.read(progressionControllerProvider);
    final weekProgressions = progressionController.buildWeekProgressions(programController.program.weeks, widget.exercise!);
    _weightControllers = List.generate(weekProgressions.length, (index) => TextEditingController(text: weekProgressions[index].weight.toString()));
  }

  @override
  void dispose() {
    for (var controller in _weightControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programController = ref.watch(trainingProgramControllerProvider);
    final progressionController = ref.watch(progressionControllerProvider);

    List<WeekProgression> weekProgressions = progressionController
        .buildWeekProgressions(programController.program.weeks, widget.exercise!);

    void updateProgression(int weekIndex, int reps, int sets, String intensity,
        String rpe, double weight) {
      final currentProgression = weekProgressions[weekIndex];

      currentProgression.reps = reps;
      currentProgression.sets = sets;
      currentProgression.intensity = intensity;
      currentProgression.rpe = rpe;
      currentProgression.weight = weight;

      debugPrint('Updating progression for week ${currentProgression.weekNumber}');
      debugPrint('Reps: ${currentProgression.reps}, Sets: ${currentProgression.sets}, Intensity: ${currentProgression.intensity}, RPE: ${currentProgression.rpe}, Weight: ${currentProgression.weight}');
    }

    void updateWeightFromIntensity(int weekIndex, String intensity) {
      final currentProgression = weekProgressions[weekIndex];

      if (intensity.isNotEmpty) {
        debugPrint('Calculating weight from intensity: $intensity');
        final calculatedWeight = calculateWeightFromIntensity(widget.latestMaxWeight.toDouble(), double.parse(intensity));
        currentProgression.weight = roundWeight(calculatedWeight, widget.exercise?.type);
        _weightControllers[weekIndex].text = currentProgression.weight.toString();
        debugPrint('Calculated weight: ${currentProgression.weight}');
      }
    }

    void updateWeightFromRPE(int weekIndex, String rpe, int reps) {
      final currentProgression = weekProgressions[weekIndex];

      if (rpe.isNotEmpty) {
        debugPrint('Calculating weight from RPE: $rpe');
        final rpePercentage = getRPEPercentage(double.parse(rpe), reps);
        final calculatedWeight = widget.latestMaxWeight.toDouble() * rpePercentage;
        currentProgression.weight = roundWeight(calculatedWeight, widget.exercise?.type);
        _weightControllers[weekIndex].text = currentProgression.weight.toString();
        debugPrint('Calculated weight: ${currentProgression.weight}');
      }
    }

    void updateIntensityFromWeight(int weekIndex, double weight) {
      final currentProgression = weekProgressions[weekIndex];

      if (weight != 0) {
        debugPrint('Updating intensity based on weight: $weight');
        currentProgression.intensity = calculateIntensityFromWeight(weight, widget.latestMaxWeight.toDouble()).toStringAsFixed(2);
        debugPrint('Updated intensity: ${currentProgression.intensity}');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Progression'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
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
            tooltip: 'Apply Progression',
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16.0,
          columns: const [
            DataColumn(label: Text('Week')),
            DataColumn(label: Text('Reps')),
            DataColumn(label: Text('Sets')),
            DataColumn(label: Text('Intensity')),
            DataColumn(label: Text('RPE')),
            DataColumn(label: Text('Weight')),
          ],
          rows: List.generate(
            weekProgressions.length,
            (weekIndex) {
              final progression = weekProgressions[weekIndex];

              return DataRow(
                cells: [
                  DataCell(Text('${progression.weekNumber}')),
                  DataCell(
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: progression.reps.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final reps = int.tryParse(value) ?? 0;
                          updateProgression(
                            weekIndex,
                            reps,
                            progression.sets,
                            progression.intensity,
                            progression.rpe,
                            progression.weight,
                          );
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: progression.sets.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final sets = int.tryParse(value) ?? 0;
                          updateProgression(
                            weekIndex,
                            progression.reps,
                            sets,
                            progression.intensity,
                            progression.rpe,
                            progression.weight,
                          );
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: progression.intensity,
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          updateProgression(
                            weekIndex,
                            progression.reps,
                            progression.sets,
                            value,
                            progression.rpe,
                            progression.weight,
                          );
                          updateWeightFromIntensity(weekIndex, value);
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: progression.rpe,
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          updateProgression(
                            weekIndex,
                            progression.reps,
                            progression.sets,
                            progression.intensity,
                            value,
                            progression.weight,
                          );
                          updateWeightFromRPE(weekIndex, value, progression.reps);
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _weightControllers[weekIndex],
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final weight = double.tryParse(value) ?? 0;
                          updateProgression(
                            weekIndex,
                            progression.reps,
                            progression.sets,
                            progression.intensity,
                            progression.rpe,
                            weight,
                          );
                          updateIntensityFromWeight(weekIndex, weight);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}