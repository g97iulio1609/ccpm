import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/controller/progression_controller.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SetProgressionScreen extends ConsumerWidget {
  final String exerciseId;
  final Exercise? exercise;

  const SetProgressionScreen({
    required this.exerciseId,
    this.exercise,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programController = ref.watch(trainingProgramControllerProvider);
    final progressionController = ref.watch(progressionControllerProvider);

    List<WeekProgression> weekProgressions =
        progressionController.buildWeekProgressions(programController.program.weeks, exercise!);

  void updateProgression(int weekIndex, int reps, int sets, String intensity,
    String rpe, double weight) {
  final currentProgression = weekProgressions[weekIndex];

  currentProgression.reps = reps;
  currentProgression.sets = sets;
  currentProgression.intensity = intensity;
  currentProgression.rpe = rpe;
  currentProgression.weight = weight;

  debugPrint('Updated progression for week ${weekIndex + 1}:');
  debugPrint('Reps: $reps');
  debugPrint('Sets: $sets');
  debugPrint('Intensity: $intensity');
  debugPrint('RPE: $rpe');
  debugPrint('Weight: $weight');
}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Progression'),
        actions: [
          IconButton(
     icon: const Icon(Icons.check),
  onPressed: () async {
    debugPrint('Set Progression clicked');
    debugPrint('Week progressions: $weekProgressions');
    await progressionController.updateExerciseProgressions(
        exercise!, weekProgressions, context);
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
                          );},
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