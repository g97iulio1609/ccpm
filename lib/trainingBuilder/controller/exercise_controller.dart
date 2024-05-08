import 'package:alphanessone/trainingBuilder/controller/series_controller.dart';
import 'package:alphanessone/trainingBuilder/exercise_dialog.dart';
import 'package:alphanessone/users_services.dart';
import 'package:flutter/material.dart';
import '../training_model.dart';
import '../utility_functions.dart';

class ExerciseController extends ChangeNotifier {
  final UsersService _usersService;
  final SeriesController _seriesController;

  ExerciseController(this._usersService, this._seriesController);

Future<void> addExercise(TrainingProgram program, int weekIndex,
    int workoutIndex, BuildContext context) async {
  final exercise =
      await _showExerciseDialog(context, null, program.athleteId);
  if (exercise != null) {
    exercise.id = null;
    exercise.order =
        program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
    exercise.weekProgressions = List.generate(program.weeks.length, (_) => []); // Inizializza weekProgressions con le settimane del programma
    program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);
    notifyListeners();
    await updateExercise(program, exercise.exerciseId!,
        exercise.type); // Pass exercise.type here
  }
}

  Future<Exercise?> _showExerciseDialog(
      BuildContext context, Exercise? exercise, String athleteId) async {
    final result = await showDialog<Exercise>(
      context: context,
      builder: (context) => ExerciseDialog(
        usersService: _usersService,
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
      updatedExercise.order = exercise.order;
      updatedExercise.weekProgressions ??= [];
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] =
          updatedExercise;
      await updateExercise(program, updatedExercise.exerciseId ?? '',
          updatedExercise.type); // Pass updatedExercise.type here
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
    final newMaxWeight =
        await getLatestMaxWeight(_usersService, program.athleteId, exerciseId);

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
    final newMaxWeight =
        await getLatestMaxWeight(_usersService, program.athleteId, exerciseId);

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
    Exercise exercise,
    num newMaxWeight,
    String exerciseType,
) {
  _updateSeriesWeights(exercise.series, newMaxWeight, exerciseType);
  if (exercise.weekProgressions != null && exercise.weekProgressions.isNotEmpty) {
    _updateWeekProgressionWeights(
      exercise.weekProgressions,
      newMaxWeight,
      exerciseType,
    );
  }
}

  void _updateSeriesWeights(
      List<Series>? series, num maxWeight, String exerciseType) {
    if (series != null) {
      for (final item in series) {
        final intensity =
            item.intensity.isNotEmpty ? double.tryParse(item.intensity) : null;

        if (intensity != null) {
          final calculatedWeight =
              calculateWeightFromIntensity(maxWeight, intensity);

          item.weight = roundWeight(calculatedWeight, exerciseType);
        }
      }
    }
  }

void _updateWeekProgressionWeights(
    List<List<WeekProgression>>? progressions,
    num maxWeight,
    String exerciseType,
) {
  if (progressions != null && progressions.isNotEmpty) {
    for (final weekProgressions in progressions) {
      for (final progression in weekProgressions) {
        for (int seriesIndex = 0; seriesIndex < progression.series.length; seriesIndex++) {
          final series = progression.series[seriesIndex];
          final intensity = series.intensity.isNotEmpty ? double.tryParse(series.intensity) : null;
          if (intensity != null) {
            final calculatedWeight = calculateWeightFromIntensity(maxWeight, intensity);
            progression.series[seriesIndex] = series.copyWith(weight: roundWeight(calculatedWeight, exerciseType));
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
      program.weeks[weekIndex].workouts[workoutIndex].exercises[i].order =
          i + 1;
    }
  }

  Future<void> addSeriesToProgression(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, BuildContext context) async {
      debugPrint("Calling ExerciseController");
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
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

  void duplicateExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    final sourceExercise =
        program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final duplicatedExercise = _copyExercise(sourceExercise);

    // Aggiorna l'ordine del nuovo esercizio
    duplicatedExercise.order =
        program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;

    // Aggiungi il nuovo esercizio alla stessa posizione
    program.weeks[weekIndex].workouts[workoutIndex].exercises.add(duplicatedExercise);
  }

  Exercise _copyExercise(Exercise sourceExercise) {
    final copiedSeries = sourceExercise.series.map((series) => _copySeries(series)).toList();

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

  void moveExercise(
    TrainingProgram program,
    int sourceWeekIndex,
    int sourceWorkoutIndex,
    int sourceExerciseIndex,
    int destinationWeekIndex,
    int destinationWorkoutIndex,
  ) {
    final exercise = program.weeks[sourceWeekIndex].workouts[sourceWorkoutIndex]
        .exercises[sourceExerciseIndex];

    // Rimuovi l'esercizio dalla posizione originale
    program.weeks[sourceWeekIndex].workouts[sourceWorkoutIndex].exercises
        .removeAt(sourceExerciseIndex);

    // Aggiorna l'ordine dell'esercizio spostato
    exercise.order =
        program.weeks[destinationWeekIndex].workouts[destinationWorkoutIndex].exercises.length +
            1;

    // Aggiungi l'esercizio alla nuova posizione
    program.weeks[destinationWeekIndex].workouts[destinationWorkoutIndex].exercises
        .add(exercise);
  }
}