import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/controller/progression_controller.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SetProgressionScreen extends ConsumerWidget {
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
Widget build(BuildContext context, WidgetRef ref) {
  final programController = ref.watch(trainingProgramControllerProvider);
  final progressionController = ref.watch(progressionControllerProvider);

  List<WeekProgression> weekProgressions = progressionController
      .buildWeekProgressions(programController.program.weeks, exercise!);

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

    // Aggiorna il valore di weight in base all'intensità o all'RPE
    if (intensity.isNotEmpty) {
      debugPrint('Calculating weight from intensity: $intensity');
      final calculatedWeight = calculateWeightFromIntensity(latestMaxWeight.toDouble(), double.parse(intensity));
      currentProgression.weight = roundWeight(calculatedWeight, exercise?.type);
      debugPrint('Calculated weight: ${currentProgression.weight}');
    } else if (rpe.isNotEmpty) {
      debugPrint('Calculating weight from RPE: $rpe');
      final rpePercentage = getRPEPercentage(double.parse(rpe), reps);
      final calculatedWeight = latestMaxWeight.toDouble() * rpePercentage;
      currentProgression.weight = roundWeight(calculatedWeight, exercise?.type);
      debugPrint('Calculated weight: ${currentProgression.weight}');
    }

    // Aggiorna l'intensità in base al peso
    if (currentProgression.weight != 0) {
      debugPrint('Updating intensity based on weight: ${currentProgression.weight}');
      currentProgression.intensity = calculateIntensityFromWeight(currentProgression.weight, latestMaxWeight.toDouble()).toStringAsFixed(2);
      debugPrint('Updated intensity: ${currentProgression.intensity}');
    }

    // Aggiorna l'RPE in base al peso e alle ripetizioni
    final calculatedRPE = calculateRPE(currentProgression.weight, latestMaxWeight.toDouble(), reps);
    currentProgression.rpe = calculatedRPE != null ? calculatedRPE.toStringAsFixed(1) : '';
    debugPrint('Updated RPE: ${currentProgression.rpe}');
  }


  return Scaffold(
    appBar: AppBar(
      title: const Text('Set Progression'),
      actions: [
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: () async {
            await progressionController.updateExerciseProgressions(
                exercise!, weekProgressions, context);
            await programController.applyWeekProgressions(
                programController.program.weeks
                    .expand((week) => week.workouts)
                    .expand((workout) => workout.exercises)
                    .toList()
                    .indexOf(exercise!),
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
                      },
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: progression.weight.toString(),
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
}}