import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../training_model.dart';
import 'training_program_controller.dart';

final progressionControllerProvider = ChangeNotifierProvider((ref) {
  final trainingProgramController = ref.watch(trainingProgramControllerProvider);
  return ProgressionController(trainingProgramController);
});

class ProgressionController extends ChangeNotifier {
  final TrainingProgramController _trainingProgramController;

  ProgressionController(this._trainingProgramController);

  TrainingProgram get program => _trainingProgramController.program;

Future<void> updateExerciseProgressions(Exercise exercise, List<List<WeekProgression>> updatedProgressions, BuildContext context) async {
  for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
    final week = program.weeks[weekIndex];
    for (int workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
      final workout = week.workouts[workoutIndex];
      final exerciseIndex = workout.exercises.indexWhere((e) => e.exerciseId == exercise.exerciseId);
      if (exerciseIndex != -1) {
        final currentExercise = workout.exercises[exerciseIndex];
        
        // Update the weekProgressions property of the exercise
        if (weekIndex < updatedProgressions.length) {
          currentExercise.weekProgressions[weekIndex] = updatedProgressions[weekIndex];
        }
        
        // Update the series of the exercise based on the current session's progression
        final sessionIndex = workoutIndex;
        final progression = weekIndex < updatedProgressions.length && sessionIndex < updatedProgressions[weekIndex].length
            ? updatedProgressions[weekIndex][sessionIndex]
            : WeekProgression(
                weekNumber: weekIndex + 1,
                sessionNumber: sessionIndex + 1,
                reps: 0,
                sets: 0,
                intensity: '',
                rpe: '',
                weight: 0.0,
              );
        
        currentExercise.series.clear();
        for (int i = 0; i < progression.sets; i++) {
          final newSeries = Series(
            serieId: generateRandomId(16).toString(),
            reps: progression.reps,
            sets: 1,
            intensity: progression.intensity,
            rpe: progression.rpe,
            weight: progression.weight,
            order: i + 1,
            done: false,
            reps_done: 0,
            weight_done: 0.0,
          );
          currentExercise.series.add(newSeries);
        }
      }
    }
  }
  notifyListeners();
}

List<List<WeekProgression>> buildWeekProgressions(List<Week> weeks, Exercise exercise) {
  final progressions = List.generate(weeks.length, (weekIndex) {
    final week = weeks[weekIndex];
    final workouts = week.workouts;
    final exerciseProgressions = List.generate(workouts.length, (workoutIndex) {
      final workout = workouts[workoutIndex];
      final exerciseInWorkout = workout.exercises.firstWhere(
        (e) => e.exerciseId == exercise.exerciseId,
        orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
      );

      final existingProgressions = exerciseInWorkout.weekProgressions;
      if (existingProgressions.isNotEmpty && existingProgressions.length > weekIndex && existingProgressions[weekIndex].isNotEmpty) {
        return existingProgressions[weekIndex][0];
      } else {
        final firstSeries = exerciseInWorkout.series.isNotEmpty ? exerciseInWorkout.series.first : null;

        return WeekProgression(
          weekNumber: weekIndex + 1,
          sessionNumber: workoutIndex + 1,
          reps: firstSeries?.reps ?? 0,
          sets: exerciseInWorkout.series.length,
          intensity: firstSeries?.intensity ?? '',
          rpe: firstSeries?.rpe ?? '',
          weight: firstSeries?.weight ?? 0.0,
        );
      }
    });

    return exerciseProgressions;
  });

  return progressions;
}

Future<void> addSeriesToProgression(TrainingProgram program, int weekIndex,
    int workoutIndex, int exerciseIndex) async {
  final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  final newSeriesOrder = exercise.series.length + 1;
  final newSeries = Series(
    serieId: generateRandomId(16).toString(),
    reps: 0,
    sets: 1,
    intensity: '',
    rpe: '',
    weight: 0.0,
    order: newSeriesOrder,
    done: false,
    reps_done: 0,
    weight_done: 0.0,
  );
  exercise.series.add(newSeries);
}}