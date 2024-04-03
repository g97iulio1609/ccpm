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
    debugPrint('Building SetProgressionScreen');
    debugPrint('Received exerciseId: $exerciseId');
    debugPrint('Received exercise: $exercise');

    final controller = ref.watch(trainingProgramControllerProvider);
    debugPrint('Fetched controller: $controller');

    List<WeekProgression> weekProgressions =
        _buildWeekProgressions(controller.program.weeks, exercise);
    debugPrint('Initial weekProgressions: $weekProgressions');

    void updateProgression(
        int weekIndex, int reps, int sets, String intensity, String rpe, double weight) {
      final currentProgression = weekProgressions[weekIndex];

      debugPrint('Updating progression for weekIndex: $weekIndex');
      debugPrint('Input values: reps=$reps, sets=$sets, intensity=$intensity, rpe=$rpe, weight=$weight');

      currentProgression.reps = reps;
      currentProgression.sets = sets;
      currentProgression.intensity = intensity;
      currentProgression.rpe = rpe;
      currentProgression.weight = weight;

      debugPrint('Updated progression: $currentProgression');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Progression'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              debugPrint('Apply Progression button pressed');
              await controller.updateExerciseProgressions(exercise!, weekProgressions, context);
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
              debugPrint('Building DataRow for weekIndex: $weekIndex');
              debugPrint('progression: $progression');

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
  }

  List<WeekProgression> _buildWeekProgressions(List<Week> weeks, Exercise? exercise) {
    debugPrint('Building weekProgressions');
    debugPrint('weeks: $weeks');
    debugPrint('exercise: $exercise');

    return List.generate(weeks.length, (weekIndex) {
      final week = weeks[weekIndex];
      debugPrint('Processing week: $week');

      final workout = week.workouts.firstWhere(
        (workout) => workout.exercises.any((e) => e.id == exercise?.id),
        orElse: () => Workout(order: 0, exercises: []),
      );
      debugPrint('Found workout: $workout');

      final series = workout.exercises
          .firstWhere((e) => e.id == exercise?.id, orElse: () => Exercise(name: '', variant: '', order: 0))
          .series;
      debugPrint('Found series: $series');

      if (series.isNotEmpty) {
        final firstSeries = series.first;
        debugPrint('Using first series: $firstSeries');

        return WeekProgression(
          weekNumber: weekIndex + 1,
          reps: firstSeries.reps,
          sets: series.length,
          intensity: firstSeries.intensity,
          rpe: firstSeries.rpe,
          weight: firstSeries.weight,
        );
      } else {
        debugPrint('No series found, returning default progression');

        return WeekProgression(
          weekNumber: weekIndex + 1,
          reps: 0,
          sets: 0,
          intensity: '',
          rpe: '',
          weight: 0.0,
        );
      }
    });
  }
}