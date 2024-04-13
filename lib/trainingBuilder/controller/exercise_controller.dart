import 'package:alphanessone/trainingBuilder/controller/series_controller.dart';
import 'package:alphanessone/trainingBuilder/exercise_dialog.dart';
import 'package:alphanessone/users_services.dart';
import 'package:flutter/material.dart';
import '../training_model.dart';
import '../utility_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ExerciseController {
  final UsersService _usersService;
  final SeriesController _seriesController;

  ExerciseController(this._usersService, this._seriesController);

  Future<void> addExercise(TrainingProgram program, int weekIndex,
      int workoutIndex, BuildContext context) async {
    final exercise = await _showExerciseDialog(context, null, program.athleteId);
    if (exercise != null) {
      exercise.id = null;
      exercise.order =
          program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
      program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);
    }
  }

  Future<Exercise?> _showExerciseDialog(
      BuildContext context, Exercise? exercise, String athleteId) async {
    return await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseDialog(
        usersService: _usersService,
        athleteId: athleteId,
        exercise: exercise,
      ),
    );
  }

  Future<void> editExercise(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedExercise = await _showExerciseDialog(context, exercise, program.athleteId);
    if (updatedExercise != null) {
      updatedExercise.order = exercise.order;
      program.weeks[weekIndex].workouts[workoutIndex]
          .exercises[exerciseIndex] = updatedExercise;
      await updateExercise(program, updatedExercise.exerciseId ?? '');
    }
  }

  void removeExercise(TrainingProgram program, int weekIndex, int workoutIndex, int exerciseIndex) {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    _removeExerciseAndRelatedData(program, exercise);
    program.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(exerciseIndex);
    _updateExerciseOrders(program, weekIndex, workoutIndex, exerciseIndex);
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

  Future<void> updateExercise(TrainingProgram program, String exerciseId) async {
    await _onExerciseChanged(program, exerciseId);
  }

  Future<void> _onExerciseChanged(TrainingProgram program, String exerciseId) async {
    Exercise? changedExercise = _findExerciseById(program, exerciseId);

    if (changedExercise != null) {
      final newMaxWeight = await getLatestMaxWeight(
          _usersService, program.athleteId, exerciseId);
      _updateExerciseWeights(changedExercise, newMaxWeight as double);
    }
  }

  Exercise? _findExerciseById(TrainingProgram program, String exerciseId) {
    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          if (exercise.exerciseId == exerciseId) {
            return exercise;
          }
        }
      }
    }
    return null;
  }

  void _updateExerciseWeights(Exercise exercise, double newMaxWeight) {
    final exerciseType = exercise.type ?? '';
    _updateSeriesWeights(exercise.series, newMaxWeight, exerciseType);
    _updateWeekProgressionWeights(exercise.weekProgressions, newMaxWeight, exerciseType);
  }

  void _updateSeriesWeights(
      List<Series> series, double maxWeight, String exerciseType) {
    for (final item in series) {
      final intensity = double.tryParse(item.intensity) ?? 0;
      final calculatedWeight = calculateWeightFromIntensity(maxWeight, intensity);
      item.weight = roundWeight(calculatedWeight, exerciseType);
    }
  }

  void _updateWeekProgressionWeights(
      List<WeekProgression> progressions, double maxWeight, String exerciseType) {
    for (final item in progressions) {
      final intensity = double.tryParse(item.intensity) ?? 0;
      final calculatedWeight = calculateWeightFromIntensity(maxWeight, intensity);
      item.weight = roundWeight(calculatedWeight, exerciseType);
    }
  }

  void _updateExerciseOrders(TrainingProgram program, int weekIndex,
      int workoutIndex, int startIndex) {
    for (int i = startIndex;
        i < program.weeks[weekIndex].workouts[workoutIndex].exercises.length;
        i++) {
      program.weeks[weekIndex].workouts[workoutIndex].exercises[i].order =
          i + 1;
    }
  }

  Future<void> applyWeekProgressions(TrainingProgram program, int exerciseIndex,
      List<WeekProgression> weekProgressions, BuildContext context) async {
    for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
      final week = program.weeks[weekIndex];

      for (int workoutIndex = 0;
          workoutIndex < week.workouts.length;
          workoutIndex++) {
        final workout = week.workouts[workoutIndex];

        for (int currentExerciseIndex = 0;
            currentExerciseIndex < workout.exercises.length;
            currentExerciseIndex++) {
          final exercise = workout.exercises[currentExerciseIndex];

          if (currentExerciseIndex == exerciseIndex) {
            final progression = weekIndex < weekProgressions.length
                ? weekProgressions[weekIndex]
                : weekProgressions.last;

            await _updateOrCreateSeries(program, exercise, progression, weekIndex,
                workoutIndex, currentExerciseIndex, context);
            _updateWeekProgression(
                program, weekIndex, workoutIndex, currentExerciseIndex, progression);
          }
        }
      }
    }
  }

  Future<void> _updateOrCreateSeries(
      TrainingProgram program,
      Exercise exercise,
      WeekProgression progression,
      int weekIndex,
      int workoutIndex,
      int exerciseIndex,
      BuildContext context) async {
    final existingSeries = exercise.series
        .where((series) => series.order ~/ 100 == weekIndex)
        .toList();

    await _adjustSeriesCount(program, existingSeries, progression.sets, weekIndex,
        workoutIndex, exerciseIndex, context);

    for (int i = 0; i < progression.sets; i++) {
      final series = existingSeries[i];
      series.reps = progression.reps;
      series.intensity = progression.intensity;
      series.rpe = progression.rpe;
      series.weight = progression.weight;
    }
  }

  Future<void> _adjustSeriesCount(
      TrainingProgram program,
      List<Series> existingSeries,
      int newSeriesCount,
      int weekIndex,
      int workoutIndex,
      int exerciseIndex,
      BuildContext context) async {
    if (existingSeries.length < newSeriesCount) {
      for (int i = existingSeries.length; i < newSeriesCount; i++) {
        await addSeriesToProgression(program, weekIndex, workoutIndex, exerciseIndex, context);
      }
    } else if (existingSeries.length > newSeriesCount) {
      for (int i = newSeriesCount; i < existingSeries.length; i++) {
        final seriesIndex = existingSeries[i].order % 100 - 1;
        _seriesController.removeSeries(program, weekIndex, workoutIndex, exerciseIndex, 0, seriesIndex);
      }
    }
  }

  Future<void> addSeriesToProgression(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final newSeriesOrder = exercise.series.length + 1;
    final newSeries = Series(
      serieId: UniqueKey().toString(),
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

  void _updateWeekProgression(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, WeekProgression progression) {
    final exercise =
        program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    if (exercise.weekProgressions.length <= weekIndex) {
      exercise.weekProgressions.add(progression);
    } else {
      exercise.weekProgressions[weekIndex] = progression;
    }
  }

  Future<void> updateExerciseProgressions(TrainingProgram program,
      Exercise exercise, List<WeekProgression> updatedProgressions, BuildContext context) async {
    for (int weekIndex = 0; weekIndex < program.weeks.length; weekIndex++) {
      final week = program.weeks[weekIndex];

      for (int workoutIndex = 0;
          workoutIndex < week.workouts.length;
          workoutIndex++) {
        final workout = week.workouts[workoutIndex];
        final exerciseIndex =
        workout.exercises.indexWhere((e) => e.id == exercise.id);
        if (exerciseIndex != -1) {
          final currentExercise = workout.exercises[exerciseIndex];
          currentExercise.weekProgressions = updatedProgressions;

          final progression = weekIndex < updatedProgressions.length
              ? updatedProgressions[weekIndex]
              : updatedProgressions.last;

          currentExercise.series.clear();

          await Future.forEach<int>(
              List.generate(progression.sets, (index) => index), (index) async {
            await addSeriesToProgression(program, weekIndex, workoutIndex, exerciseIndex, context);
            final latestSeries = currentExercise.series[index];
            latestSeries.reps = progression.reps;
            latestSeries.intensity = progression.intensity;
            latestSeries.rpe = progression.rpe;
            latestSeries.weight = progression.weight;
          });
        }
      }
    }
  }

  void reorderExercises(TrainingProgram program, int weekIndex,
      int workoutIndex, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(oldIndex);
    program.weeks[weekIndex].workouts[workoutIndex].exercises
        .insert(newIndex, exercise);
    _updateExerciseOrders(program, weekIndex, workoutIndex, newIndex);
  }
}
