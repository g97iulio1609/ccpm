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
      exercise.weekProgressions = []; // Initialize weekProgressions
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
                exercise, newMaxWeight!.toDouble(), exerciseType);
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
      _updateExerciseWeights(exercise, newMaxWeight!.toDouble(), exerciseType);
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
    debugPrint(
        "from _updateExerciseWeights: exercise.id ${exercise.id} newMaxWeight: ${newMaxWeight} exerciseType:${exerciseType}");
    _updateSeriesWeights(exercise.series, newMaxWeight, exerciseType);
    if (exercise.weekProgressions != null &&
        exercise.weekProgressions.isNotEmpty) {
      _updateWeekProgressionWeights(
          exercise.weekProgressions, newMaxWeight, exerciseType);
    }
  }

  void _updateSeriesWeights(
      List<Series>? series, num maxWeight, String exerciseType) {
    if (series != null) {
      debugPrint(
          "from _updateSeriesWeights: maxWeight ${maxWeight} exerciseType: ${exerciseType}");

      for (final item in series) {
        final intensity =
            item.intensity.isNotEmpty ? double.tryParse(item.intensity) : null;
        debugPrint("from _updateSeriesWeights: intensity ${intensity}");

        if (intensity != null) {
          final calculatedWeight =
              calculateWeightFromIntensity(maxWeight, intensity);
          debugPrint(
              "from _updateSeriesWeights: calculateWeightFromIntensity ${calculatedWeight}");

          item.weight = roundWeight(calculatedWeight, exerciseType);
        }
      }
    }
  }

  void _updateWeekProgressionWeights(
      List<WeekProgression>? progressions, num maxWeight, String exerciseType) {
    if (progressions != null && progressions.isNotEmpty) {
      for (final item in progressions) {
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
}
