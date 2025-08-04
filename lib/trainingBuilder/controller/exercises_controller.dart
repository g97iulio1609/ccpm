import 'package:alphanessone/trainingBuilder/dialog/exercise_dialog.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/models/progressions_model.dart';
import 'package:flutter/material.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import '../utility_functions.dart';

class ExerciseController extends ChangeNotifier {
  final ExerciseRecordService _exerciseRecordService;

  ExerciseController(this._exerciseRecordService);

  Future<void> addExercise(TrainingProgram program, int weekIndex,
      int workoutIndex, BuildContext context) async {
    final exercise =
        await _showExerciseDialog(context, null, program.athleteId);
    if (exercise != null) {
      final updatedExercise = exercise.copyWith(
        id: null,
        order: program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1,
        weekProgressions: List.generate(program.weeks.length, (_) => []),
      );
      program.weeks[weekIndex].workouts[workoutIndex].exercises.add(updatedExercise);
      notifyListeners();
      await updateExercise(program, exercise.exerciseId!, exercise.type);
    }
  }

  Future<Exercise?> _showExerciseDialog(
      BuildContext context, Exercise? exercise, String athleteId) async {
    final result = await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseDialog(
        exerciseRecordService: _exerciseRecordService,
        athleteId: athleteId,
        exercise: exercise,
      ),
    );
    return result;
  }

  Future<void> editExercise(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    final updatedExercise =
        await _showExerciseDialog(context, exercise, program.athleteId);
    if (updatedExercise != null) {
      final finalExercise = updatedExercise.copyWith(
        order: exercise.order,
        weekProgressions: exercise.weekProgressions,
      );
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] =
          finalExercise;
      await updateExercise(
          program, updatedExercise.exerciseId ?? '', updatedExercise.type);
    }
  }

  void removeExercise(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex) {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    _removeExerciseAndRelatedData(program, exercise);
    program.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(exerciseIndex);
    _updateExerciseOrders(program, weekIndex, workoutIndex, exerciseIndex);
  }

  void _removeExerciseAndRelatedData(
      TrainingProgram program, Exercise exercise) {
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

  Future<void> updateExercise(
      TrainingProgram program, String exerciseId, String exerciseType) async {
    final newMaxWeight = await getLatestMaxWeight(
        _exerciseRecordService, program.athleteId, exerciseId);

    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          if (exercise.exerciseId == exerciseId) {
            _updateExerciseWeights(
                exercise, newMaxWeight.toDouble(), exerciseType);
          }
        }
      }
    }
  }

  Future<void> updateNewProgramExercises(
      TrainingProgram program, String exerciseId, String exerciseType) async {
    final newMaxWeight = await getLatestMaxWeight(
        _exerciseRecordService, program.athleteId, exerciseId);

    final exercise = _findExerciseById(program, exerciseId);
    if (exercise != null) {
      _updateExerciseWeights(exercise, newMaxWeight.toDouble(), exerciseType);
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

  void _updateExerciseWeights(
      Exercise exercise, num newMaxWeight, String exerciseType) {
    _updateSeriesWeights(exercise.series, newMaxWeight, exerciseType);
    if (exercise.weekProgressions?.isNotEmpty ?? false) {
      _updateWeekProgressionWeights(
          exercise.weekProgressions!, newMaxWeight, exerciseType);
    }
  }

  void _updateSeriesWeights(
      List<Series>? series, num maxWeight, String exerciseType) {
    if (series != null) {
      for (final item in series) {
        final intensity = item.intensity != null && item.intensity!.isNotEmpty 
            ? double.tryParse(item.intensity!) : null;

        if (intensity != null) {
          final calculatedWeight =
              calculateWeightFromIntensity(maxWeight, intensity);

          // Note: Series is immutable, weight updates should be handled differently
          // This might need to be refactored to use copyWith or similar approach
        }
      }
    }
  }

  void _updateWeekProgressionWeights(List<List<WeekProgression>>? progressions,
      num maxWeight, String exerciseType) {
    if (progressions?.isNotEmpty ?? false) {
      for (final weekProgressions in progressions!) {
        for (final progression in weekProgressions) {
          for (int seriesIndex = 0;
              seriesIndex < progression.series.length;
              seriesIndex++) {
            final series = progression.series[seriesIndex];
            final intensity = series.intensity != null && series.intensity!.isNotEmpty
                ? double.tryParse(series.intensity!)
                : null;
            if (intensity != null) {
              final calculatedWeight =
                  calculateWeightFromIntensity(maxWeight, intensity);
              progression.series[seriesIndex] = series.copyWith(
                  weight: roundWeight(calculatedWeight, exerciseType));
            }
          }
        }
      }
    }
  }

  void _updateExerciseOrders(TrainingProgram program, int weekIndex,
      int workoutIndex, int startIndex) {
    for (int i = startIndex;
        i < program.weeks[weekIndex].workouts[workoutIndex].exercises.length;
        i++) {
      program.weeks[weekIndex].workouts[workoutIndex].exercises[i] = 
          program.weeks[weekIndex].workouts[workoutIndex].exercises[i].copyWith(order: i + 1);
    }
  }

  Future<void> addSeriesToProgression(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final newSeriesOrder = exercise.series.length + 1;
    final newSeries = Series(
      exerciseId: exercise.exerciseId ?? '',
      serieId: generateRandomId(16).toString(),
      reps: 0,
      sets: 1,
      intensity: '',
      rpe: '',
      weight: 0.0,
      order: newSeriesOrder,
      done: false,
      repsDone: 0,
      weightDone: 0.0,
    );
    exercise.series.add(newSeries);
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

  void duplicateExercise(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex) {
    final sourceExercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final duplicatedExercise = _copyExercise(sourceExercise);

    final finalDuplicatedExercise = duplicatedExercise.copyWith(
      order: program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1,
    );

    program.weeks[weekIndex].workouts[workoutIndex].exercises
        .add(finalDuplicatedExercise);
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
      repsDone: 0,
      weightDone: 0.0,
    );
  }

  void moveExercise(
      TrainingProgram program,
      int sourceWeekIndex,
      int sourceWorkoutIndex,
      int sourceExerciseIndex,
      int destinationWeekIndex,
      int destinationWorkoutIndex) {
    final sourceWorkout =
        program.weeks[sourceWeekIndex].workouts[sourceWorkoutIndex];
    final destinationWorkout =
        program.weeks[destinationWeekIndex].workouts[destinationWorkoutIndex];

    // Rimuovi l'esercizio dall'allenamento di origine
    final exercise = sourceWorkout.exercises.removeAt(sourceExerciseIndex);

    // Aggiorna gli ordini degli esercizi nell'allenamento di origine
    for (int i = sourceExerciseIndex; i < sourceWorkout.exercises.length; i++) {
      sourceWorkout.exercises[i] = sourceWorkout.exercises[i].copyWith(order: i + 1);
    }

    // Aggiungi l'esercizio all'allenamento di destinazione
    final updatedExercise = exercise.copyWith(order: destinationWorkout.exercises.length + 1);
    destinationWorkout.exercises.add(updatedExercise);

    // Aggiorna gli ordini degli esercizi nell'allenamento di destinazione
    for (int i = 0; i < destinationWorkout.exercises.length; i++) {
      destinationWorkout.exercises[i] = destinationWorkout.exercises[i].copyWith(order: i + 1);
    }

    notifyListeners();
  }
}
