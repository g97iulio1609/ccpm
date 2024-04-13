import 'package:alphanessone/trainingBuilder/controller/week_controller.dart';
import 'package:flutter/material.dart';

import '../training_model.dart';

class WorkoutController {
  void addWorkout(TrainingProgram program, int weekIndex) {
    final newWorkout = Workout(
      order: program.weeks[weekIndex].workouts.length + 1,
      exercises: [],
    );
    program.weeks[weekIndex].workouts.add(newWorkout);
  }

  void removeWorkout(TrainingProgram program, int weekIndex, int workoutOrder) {
    final workoutIndex = workoutOrder - 1;
    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    _removeWorkoutAndRelatedData(program, workout);
    program.weeks[weekIndex].workouts.removeAt(workoutIndex);
    _updateWorkoutOrders(program, weekIndex, workoutIndex);
  }

  void _removeWorkoutAndRelatedData(TrainingProgram program, Workout workout) {
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    workout.exercises.forEach((exercise) => _removeExerciseAndRelatedData(program, exercise));
  }

  void _removeExerciseAndRelatedData(TrainingProgram program, Exercise exercise) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    exercise.series.forEach((series) => _removeSeriesData(program, series));
  }

  void _removeSeriesData(TrainingProgram program, Series series) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
  }

  void _updateWorkoutOrders(TrainingProgram program, int weekIndex, int startIndex) {
    for (int i = startIndex; i < program.weeks[weekIndex].workouts.length; i++) {
      program.weeks[weekIndex].workouts[i].order = i + 1;
    }
  }

  Future<void> copyWorkout(TrainingProgram program, int sourceWeekIndex,
      int workoutIndex, BuildContext context) async {
    final destinationWeekIndex = await _showCopyWorkoutDialog(program, context);
    if (destinationWeekIndex != null) {
      final sourceWorkout = program.weeks[sourceWeekIndex].workouts[workoutIndex];
      final copiedWorkout = _copyWorkout(sourceWorkout);

      if (destinationWeekIndex < program.weeks.length) {
        final destinationWeek = program.weeks[destinationWeekIndex];
        final existingWorkoutIndex = destinationWeek.workouts.indexWhere(
          (workout) => workout.order == sourceWorkout.order,
        );

        if (existingWorkoutIndex != -1) {
          final existingWorkout = destinationWeek.workouts[existingWorkoutIndex];
          if (existingWorkout.id != null) {
            program.trackToDeleteWorkouts.add(existingWorkout.id!);
          }
          destinationWeek.workouts[existingWorkoutIndex] = copiedWorkout;
        } else {
          destinationWeek.workouts.add(copiedWorkout);
        }
      } else {
        while (program.weeks.length <= destinationWeekIndex) {
          WeekController().addWeek(program);
        }
        program.weeks[destinationWeekIndex].workouts.add(copiedWorkout);
      }
    }
  }

  Workout _copyWorkout(Workout sourceWorkout) {
    final copiedExercises = sourceWorkout.exercises
        .map((exercise) => _copyExercise(exercise))
        .toList();

    return Workout(
      id: null,
      order: sourceWorkout.order,
      exercises: copiedExercises,
    );
  }

  Exercise _copyExercise(Exercise sourceExercise) {
    final copiedSeries = sourceExercise.series.map((series) => _copySeries(series)).toList();

    return sourceExercise.copyWith(
      id: UniqueKey().toString(),
      exerciseId: sourceExercise.exerciseId,
      series: copiedSeries,
    );
  }

  Series _copySeries(Series sourceSeries) {
    return sourceSeries.copyWith(
      serieId: UniqueKey().toString(),
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
  }

  Future<int?> _showCopyWorkoutDialog(TrainingProgram program, BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Copy Workout'),
          content: DropdownButtonFormField<int>(
            value: null,
            items: List.generate(
              program.weeks.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text('Week ${index + 1}'),
              ),
            ),
            onChanged: (value) {
              Navigator.pop(context, value);
            },
            decoration: const InputDecoration(
              labelText: 'Destination Week',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void reorderWorkouts(TrainingProgram program, int weekIndex, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final workout = program.weeks[weekIndex].workouts.removeAt(oldIndex);
    program.weeks[weekIndex].workouts.insert(newIndex, workout);
    _updateWorkoutOrders(program, weekIndex, newIndex);
  }
}