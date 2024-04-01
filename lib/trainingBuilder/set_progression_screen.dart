import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:alphanessone/trainingBuilder/training_program_controller.dart';
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
  final controller = ref.watch(trainingProgramControllerProvider);
  final weekProgressions = exercise?.weekProgressions ??
      List.generate(controller.program.weeks.length, (index) => WeekProgression(
            weekNumber: index + 1,
            reps: 0,
            sets: 0,
            intensity: '',
            rpe: '',
            weight: 0.0,
          ));

  debugPrint('Building SetProgressionScreen');
  debugPrint('Week progressions: $weekProgressions');

  return Scaffold(
    appBar: AppBar(
      title: const Text('Set Progression'),
      actions: [
      IconButton(
  icon: const Icon(Icons.check),
  onPressed: () async {
    debugPrint('Apply Progression button pressed');
    debugPrint('Week progressions before applying: $weekProgressions');

    // Aggiorna i valori di reps, sets, intensity e rpe nelle progressioni settimanali
    for (int i = 0; i < weekProgressions.length; i++) {
      final progression = weekProgressions[i];
      weekProgressions[i] = progression.copyWith(
        reps: int.tryParse(progression.reps.toString()) ?? 0,
        sets: int.tryParse(progression.sets.toString()) ?? 0,
        intensity: progression.intensity,
        rpe: progression.rpe,
        weight: double.tryParse(progression.weight.toString()) ?? 0.0,
      );
    }

    await controller.updateExerciseProgressions(exercise!, weekProgressions);
    await controller.applyWeekProgressions(exercise!.order - 1, weekProgressions);

    debugPrint('Week progressions after applying: $weekProgressions');

    Navigator.pop(context);
  },
  tooltip: 'Apply Progression',
),
      ],
    ),
    body: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
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

            debugPrint('Generating row for week: $weekIndex');
            debugPrint('Progression: $progression');

            return DataRow(
              cells: [
                DataCell(Text('${progression.weekNumber}')),
                DataCell(
                  TextFormField(
                    initialValue: progression.reps.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final reps = int.tryParse(value) ?? 0;
                      weekProgressions[weekIndex] = progression.copyWith(reps: reps);
                      debugPrint('Reps changed for week $weekIndex: $reps');
                    },
                  ),
                ),
                DataCell(
                  TextFormField(
                    initialValue: progression.sets.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final sets = int.tryParse(value) ?? 0;
                      weekProgressions[weekIndex] = progression.copyWith(sets: sets);
                      debugPrint('Sets changed for week $weekIndex: $sets');
                    },
                  ),
                ),
                DataCell(
                  TextFormField(
                    initialValue: progression.intensity,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      weekProgressions[weekIndex] = progression.copyWith(intensity: value);
                      debugPrint('Intensity changed for week $weekIndex: $value');
                    },
                  ),
                ),
                DataCell(
                  TextFormField(
                    initialValue: progression.rpe,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      weekProgressions[weekIndex] = progression.copyWith(rpe: value);
                      debugPrint('RPE changed for week $weekIndex: $value');
                    },
                  ),
                ),
                DataCell(
                  TextFormField(
                    initialValue: progression.weight.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final weight = double.tryParse(value) ?? 0;
                      weekProgressions[weekIndex] = progression.copyWith(weight: weight);
                      debugPrint('Weight changed for week $weekIndex: $weight');
                    },
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