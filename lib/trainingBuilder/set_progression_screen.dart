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
    debugPrint('Exercise: $exercise');
    debugPrint('Week progressions: $weekProgressions');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Progression'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              controller.updateExerciseProgressions(exercise!, weekProgressions);
              controller.applyWeekProgressions(
                  exercise!.order - 1, weekProgressions);
              Navigator.pop(context);
            },
            tooltip: 'Apply Progression',
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 16,
            horizontalMargin: 16,
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
                debugPrint('Reps: ${progression.reps}');
                debugPrint('Sets: ${progression.sets}');
                debugPrint('Intensity: ${progression.intensity}');
                debugPrint('RPE: ${progression.rpe}');
                debugPrint('Weight: ${progression.weight}');

                return DataRow(
                  cells: [
                    DataCell(Text('${progression.weekNumber}')),
                    DataCell(
                      TextFormField(
                        initialValue: progression.reps.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final reps = int.tryParse(value) ?? 0;
                          weekProgressions[weekIndex] =
                              progression.copyWith(reps: reps);
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      TextFormField(
                        initialValue: progression.sets.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final sets = int.tryParse(value) ?? 0;
                          weekProgressions[weekIndex] =
                              progression.copyWith(sets: sets);
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      TextFormField(
                        initialValue: progression.intensity,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          weekProgressions[weekIndex] =
                              progression.copyWith(intensity: value);
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      TextFormField(
                        initialValue: progression.rpe,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          weekProgressions[weekIndex] =
                              progression.copyWith(rpe: value);
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    DataCell(
                      TextFormField(
                        initialValue: progression.weight.toString(),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final weight = double.tryParse(value) ?? 0;
                          weekProgressions[weekIndex] =
                              progression.copyWith(weight: weight);
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}