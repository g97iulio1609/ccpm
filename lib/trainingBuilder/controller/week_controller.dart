import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/week_model.dart';
import 'package:alphanessone/trainingBuilder/models/workout_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';

import '../models/exercise_model.dart';

class WeekController {
  void addWeek(TrainingProgram program) {
    final newWeek = Week(
      id: null,
      number: program.weeks.length + 1,
      workouts: [
        Workout(
          id: '',
          order: 1,
          exercises: [],
        ),
      ],
    );

    program.weeks.add(newWeek);
  }

  void removeWeek(TrainingProgram program, int index) {
    final week = program.weeks[index];
    _removeWeekAndRelatedData(program, week);
    program.weeks.removeAt(index);
    _updateWeekNumbers(program, index);
  }

  void _removeWeekAndRelatedData(TrainingProgram program, Week week) {
    if (week.id != null) {
      program.trackToDeleteWeeks.add(week.id!);
    }
    for (var workout in week.workouts) {
      _removeWorkoutAndRelatedData(program, workout);
    }
  }

  void _removeWorkoutAndRelatedData(TrainingProgram program, Workout workout) {
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    for (var exercise in workout.exercises) {
      _removeExerciseAndRelatedData(program, exercise);
    }
  }

  void _removeExerciseAndRelatedData(TrainingProgram program, Exercise exercise) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    for (var series in exercise.series) {
      _removeSeriesData(program, series);
    }
  }

  void _removeSeriesData(TrainingProgram program, Series series) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
  }

  void _updateWeekNumbers(TrainingProgram program, int startIndex) {
    for (int i = startIndex; i < program.weeks.length; i++) {
      program.weeks[i].number = i + 1;
    }
  }

  Future<void> copyWeek(TrainingProgram program, int sourceWeekIndex, BuildContext context) async {
    final destinationWeekIndex = await _showCopyWeekDialog(program, context);
    if (destinationWeekIndex != null) {
      final sourceWeek = program.weeks[sourceWeekIndex];
      final copiedWeek = _copyWeek(sourceWeek);

      if (destinationWeekIndex < program.weeks.length) {
        final destinationWeek = program.weeks[destinationWeekIndex];
        program.trackToDeleteWeeks.add(destinationWeek.id!);
        program.weeks[destinationWeekIndex] = copiedWeek;
      } else {
        copiedWeek.number = program.weeks.length + 1;
        program.weeks.add(copiedWeek);
      }
    }
  }

  Week _copyWeek(Week sourceWeek) {
    final copiedWorkouts =
        sourceWeek.workouts.map((workout) => _copyWorkout(workout)).toList();

    return Week(
      id: null,
      number: sourceWeek.number,
      workouts: copiedWorkouts,
    );
  }

  Future<int?> _showCopyWeekDialog(TrainingProgram program, BuildContext context) async {
    return showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Copy Week'),
          content: DropdownButtonFormField<int>(
            value: null,
            items: List.generate(
              program.weeks.length + 1,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(index < program.weeks.length
                    ? 'Week ${program.weeks[index].number}'
                    : 'New Week'),
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
    final copiedSeries =
        sourceExercise.series.map((series) => _copySeries(series)).toList();

    return sourceExercise.copyWith(
      id: generateRandomId(16).toString(),
      exerciseId: sourceExercise.exerciseId,
      series: copiedSeries,
    );
  }

  Series _copySeries(Series sourceSeries) {
    return sourceSeries.copyWith(
      serieId: generateRandomId(16).toString(),
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
  }

  void reorderWeeks(TrainingProgram program, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final week = program.weeks.removeAt(oldIndex);
    program.weeks.insert(newIndex, week);
    _updateWeekNumbers(program, newIndex);
  }

  void updateWeek(TrainingProgram program, int weekIndex, Week updatedWeek) {
    program.weeks[weekIndex] = updatedWeek;
  }
}