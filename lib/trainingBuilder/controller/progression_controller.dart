import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/models/progressions_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
    debugPrint('Updating exercise progressions for exercise: ${exercise.name}');

    for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
      final week = program.weeks[weekIndex];
      debugPrint('Processing week ${weekIndex + 1}');
      for (int workoutIndex = 0; workoutIndex < week.workouts.length; workoutIndex++) {
        final workout = week.workouts[workoutIndex];
        final exerciseIndex = workout.exercises.indexWhere((e) => e.exerciseId == exercise.exerciseId);
        if (exerciseIndex != -1) {
          final currentExercise = workout.exercises[exerciseIndex];
          debugPrint('Found exercise in week ${weekIndex + 1}, workout ${workoutIndex + 1}, exercise index $exerciseIndex');

          if (currentExercise.weekProgressions.length <= weekIndex) {
            currentExercise.weekProgressions = List.generate(program.weeks.length, (_) => []);
          }

          if (weekIndex < updatedProgressions.length) {
            currentExercise.weekProgressions[weekIndex] = updatedProgressions[weekIndex];
            debugPrint('Updated weekProgressions for week ${weekIndex + 1}: ${updatedProgressions[weekIndex]}');
          }

          final sessionIndex = workoutIndex;
          final exerciseProgressions = currentExercise.weekProgressions[weekIndex];
          if (sessionIndex < exerciseProgressions.length) {
            final progression = exerciseProgressions[sessionIndex];
            debugPrint('Applying progression for week ${weekIndex + 1}, session ${sessionIndex + 1}: $progression');

            currentExercise.series = _createSeriesFromProgression(progression);
            debugPrint('Updated exercise series: ${currentExercise.series}');
          } else {
            debugPrint('Invalid session index for week ${weekIndex + 1}, session ${sessionIndex + 1}');
          }
        }
      }
    }
    debugPrint('Finished updating exercise progressions');

    notifyListeners();
  }

  List<Series> _createSeriesFromProgression(WeekProgression progression) {
    return progression.series.expand((series) {
      final List<Series> expandedSeries = [];
      for (int i = 0; i < series.sets; i++) {
        expandedSeries.add(Series(
          serieId: generateRandomId(16).toString(),
          reps: series.reps,
          maxReps: series.maxReps ?? 0,  // Use null-aware operator
          sets: 1,
          intensity: series.intensity,
          maxIntensity: series.maxIntensity ?? '',  // Use null-aware operator
          rpe: series.rpe,
          maxRpe: series.maxRpe ?? '',  // Use null-aware operator
          weight: series.weight,
          maxWeight: series.maxWeight ?? 0,  // Use null-aware operator
          order: expandedSeries.length + 1,
          done: false,
          reps_done: 0,
          weight_done: 0.0,
        ));
      }
      return expandedSeries;
    }).toList();
  }

  List<List<dynamic>> _groupSeries(List<Series> series) {
    final groupedSeries = <List<dynamic>>[];
    List<Series> currentGroup = [];

    for (int i = 0; i < series.length; i++) {
      final currentSeries = series[i];
      if (i == 0 || !_isSameGroup(currentSeries, series[i - 1])) {
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

  bool _isSameGroup(Series a, Series b) {
    return a.reps == b.reps &&
           a.maxReps == b.maxReps &&
           a.intensity == b.intensity &&
           a.maxIntensity == b.maxIntensity &&
           a.rpe == b.rpe &&
           a.maxRpe == b.maxRpe &&
           a.weight == b.weight &&
           a.maxWeight == b.maxWeight;
  }

  List<List<WeekProgression>> buildWeekProgressions(List<Week> weeks, Exercise exercise) {
    final progressions = List.generate(weeks.length, (weekIndex) {
      final week = weeks[weekIndex];
      final workouts = week.workouts;
      debugPrint('Week ${weekIndex + 1}:');
      final exerciseProgressions = workouts.map((workout) {
        debugPrint('  Workout ${workout.order}:');
        final exerciseInWorkout = workout.exercises.firstWhere(
          (e) => e.exerciseId == exercise.exerciseId,
          orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
        );

        final existingProgressions = exerciseInWorkout.weekProgressions;
        if (existingProgressions.isNotEmpty && existingProgressions.length > weekIndex) {
          final sessionProgression = existingProgressions[weekIndex].firstWhere(
            (progression) => progression.sessionNumber == workout.order,
            orElse: () => WeekProgression(
              weekNumber: weekIndex + 1,
              sessionNumber: workout.order,
              series: [],
            ),
          );
          if (sessionProgression.series.isNotEmpty) {
            debugPrint('    Existing progression found for session ${workout.order}');
            return sessionProgression;
          } else {
            debugPrint('    No existing progression found for session ${workout.order}');
            final groupedSeries = _groupSeries(exerciseInWorkout.series);
            return WeekProgression(
              weekNumber: weekIndex + 1,
              sessionNumber: workout.order,
              series: _createGroupedSeries(groupedSeries),
            );
          }
        } else {
          debugPrint('    No existing progression found for session ${workout.order}');
          final groupedSeries = _groupSeries(exerciseInWorkout.series);
          return WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: workout.order,
            series: _createGroupedSeries(groupedSeries),
          );
        }
      }).toList();

      debugPrint('  Progressions for week ${weekIndex + 1}: $exerciseProgressions');
      return exerciseProgressions;
    });

    debugPrint('Final progressions: $progressions');
    return progressions;
  }

  List<Series> _createGroupedSeries(List<List<dynamic>> groupedSeries) {
    return groupedSeries.map((group) {
      final series = group.first as Series;
      return Series(
        serieId: series.serieId,
        reps: series.reps,
        maxReps: series.maxReps,
        sets: group.length,
        intensity: series.intensity,
        maxIntensity: series.maxIntensity,
        rpe: series.rpe,
        maxRpe: series.maxRpe,
        weight: series.weight,
        maxWeight: series.maxWeight,
        order: series.order,
        done: series.done,
        reps_done: series.reps_done,
        weight_done: series.weight_done,
      );
    }).toList();
  }

  Future<void> addSeriesToProgression(TrainingProgram program, int weekIndex, int workoutIndex, int exerciseIndex) async {
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
  }
}