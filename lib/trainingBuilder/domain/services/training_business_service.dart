import '../../models/training_model.dart';
import '../../models/exercise_model.dart';
import '../../models/series_model.dart';
import '../../models/week_model.dart';
import '../../models/workout_model.dart';
import '../repositories/training_repository.dart';
import '../../../ExerciseRecords/exercise_record_services.dart';
import '../../shared/utils/validation_utils.dart';
import '../../shared/utils/model_utils.dart';

/// Business service that handles training program business logic
/// Follows Single Responsibility Principle
class TrainingBusinessService {
  final TrainingRepository _trainingRepository;
  final ExerciseRepository _exerciseRepository;
  final SeriesRepository _seriesRepository;
  final WeekRepository _weekRepository;
  final WorkoutRepository _workoutRepository;
  final ExerciseRecordService _exerciseRecordService;

  TrainingBusinessService({
    required TrainingRepository trainingRepository,
    required ExerciseRepository exerciseRepository,
    required SeriesRepository seriesRepository,
    required WeekRepository weekRepository,
    required WorkoutRepository workoutRepository,
    required ExerciseRecordService exerciseRecordService,
  })  : _trainingRepository = trainingRepository,
        _exerciseRepository = exerciseRepository,
        _seriesRepository = seriesRepository,
        _weekRepository = weekRepository,
        _workoutRepository = workoutRepository,
        _exerciseRecordService = exerciseRecordService;

  /// Validates and saves a training program
  Future<void> saveTrainingProgram(TrainingProgram program) async {
    if (!ValidationUtils.isValidTrainingProgram(program)) {
      throw ArgumentError('Invalid training program data');
    }

    await _trainingRepository.removeToDeleteItems(program);
    await _trainingRepository.saveTrainingProgram(program);

    // Clear tracking lists after successful save
    program.trackToDeleteSeries.clear();
    program.trackToDeleteExercises.clear();
    program.trackToDeleteWorkouts.clear();
    program.trackToDeleteWeeks.clear();
  }

  /// Adds a week to a training program
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

  /// Removes a week from a training program
  void removeWeek(TrainingProgram program, int weekIndex) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex)) {
      throw ArgumentError('Invalid week index');
    }

    final week = program.weeks[weekIndex];
    _trackWeekForDeletion(program, week);
    program.weeks.removeAt(weekIndex);
    ModelUtils.updateWeekNumbers(program.weeks, weekIndex);
  }

  /// Adds a workout to a week
  void addWorkout(TrainingProgram program, int weekIndex) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex)) {
      throw ArgumentError('Invalid week index');
    }

    final newWorkout = Workout(
      order: program.weeks[weekIndex].workouts.length + 1,
      exercises: [],
    );
    program.weeks[weekIndex].workouts.add(newWorkout);
  }

  /// Removes a workout from a week
  void removeWorkout(TrainingProgram program, int weekIndex, int workoutIndex) {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex)) {
      throw ArgumentError('Invalid workout index');
    }

    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    _trackWorkoutForDeletion(program, workout);
    program.weeks[weekIndex].workouts.removeAt(workoutIndex);
    ModelUtils.updateWorkoutOrders(
        program.weeks[weekIndex].workouts, workoutIndex);
  }

  /// Adds an exercise to a workout
  void addExercise(TrainingProgram program, int weekIndex, int workoutIndex,
      Exercise exercise) {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex)) {
      throw ArgumentError('Invalid indices');
    }

    if (!ValidationUtils.isValidExercise(exercise)) {
      throw ArgumentError('Invalid exercise data');
    }

    exercise.id = null;
    exercise.order =
        program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
    exercise.weekProgressions = List.generate(program.weeks.length, (_) => []);
    program.weeks[weekIndex].workouts[workoutIndex].exercises.add(exercise);
  }

  /// Removes an exercise from a workout
  void removeExercise(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex) {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex, exerciseIndex)) {
      throw ArgumentError('Invalid exercise index');
    }

    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    _trackExerciseForDeletion(program, exercise);
    program.weeks[weekIndex].workouts[workoutIndex].exercises
        .removeAt(exerciseIndex);

    final exercises = program.weeks[weekIndex].workouts[workoutIndex].exercises;
    ModelUtils.updateExerciseOrders(exercises, exerciseIndex);
  }

  /// Duplicates an exercise in a workout
  void duplicateExercise(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex) {
    if (!ValidationUtils.isValidProgramIndex(
        program, weekIndex, workoutIndex, exerciseIndex)) {
      throw ArgumentError('Invalid exercise index');
    }

    final sourceExercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final duplicatedExercise = ModelUtils.copyExercise(sourceExercise);

    duplicatedExercise.order =
        program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1;
    program.weeks[weekIndex].workouts[workoutIndex].exercises
        .add(duplicatedExercise);
  }

  /// Copies a week to another position
  Future<void> copyWeek(TrainingProgram program, int sourceWeekIndex,
      int? destinationWeekIndex) async {
    if (!ValidationUtils.isValidProgramIndex(program, sourceWeekIndex)) {
      throw ArgumentError('Invalid source week index');
    }

    final sourceWeek = program.weeks[sourceWeekIndex];
    final copiedWeek = ModelUtils.copyWeek(sourceWeek);

    if (destinationWeekIndex != null &&
        destinationWeekIndex < program.weeks.length) {
      final destinationWeek = program.weeks[destinationWeekIndex];
      if (destinationWeek.id != null) {
        program.trackToDeleteWeeks.add(destinationWeek.id!);
      }
      program.weeks[destinationWeekIndex] = copiedWeek;
    } else {
      copiedWeek.number = program.weeks.length + 1;
      program.weeks.add(copiedWeek);
    }
  }

  /// Copies a workout to another week
  Future<void> copyWorkout(TrainingProgram program, int sourceWeekIndex,
      int workoutIndex, int? destinationWeekIndex) async {
    if (!ValidationUtils.isValidProgramIndex(
        program, sourceWeekIndex, workoutIndex)) {
      throw ArgumentError('Invalid source indices');
    }

    final sourceWorkout = program.weeks[sourceWeekIndex].workouts[workoutIndex];
    final copiedWorkout = ModelUtils.copyWorkout(sourceWorkout);

    if (destinationWeekIndex != null &&
        destinationWeekIndex < program.weeks.length) {
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
      // Create new weeks if needed
      while (program.weeks.length <=
          (destinationWeekIndex ?? program.weeks.length)) {
        addWeek(program);
      }
      program.weeks[destinationWeekIndex ?? program.weeks.length - 1].workouts
          .add(copiedWorkout);
    }
  }

  /// Updates exercise weights based on latest max weight
  Future<void> updateExerciseWeights(
      TrainingProgram program, String exerciseId, String exerciseType) async {
    final newMaxWeight =
        await _getLatestMaxWeight(program.athleteId, exerciseId);

    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          if (exercise.exerciseId == exerciseId) {
            _updateExerciseWeightsInternal(
                exercise, newMaxWeight.toDouble(), exerciseType);
          }
        }
      }
    }
  }

  /// Gets latest max weight for an exercise
  Future<num> _getLatestMaxWeight(String athleteId, String exerciseId) async {
    if (exerciseId.isEmpty) return 0;

    try {
      final record = await _exerciseRecordService.getLatestExerciseRecord(
        userId: athleteId,
        exerciseId: exerciseId,
      );
      return record?.maxWeight ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Updates weights for an exercise and its series
  void _updateExerciseWeightsInternal(
      Exercise exercise, double maxWeight, String exerciseType) {
    // Update series weights
    for (final series in exercise.series) {
      final intensity = series.intensity.isNotEmpty
          ? double.tryParse(series.intensity)
          : null;
      if (intensity != null) {
        final calculatedWeight =
            _calculateWeightFromIntensity(maxWeight, intensity);
        series.weight = _roundWeight(calculatedWeight, exerciseType);
      }
    }

    // Update week progressions weights
    for (final weekProgressions in exercise.weekProgressions) {
      for (final progression in weekProgressions) {
        for (int i = 0; i < progression.series.length; i++) {
          final series = progression.series[i];
          final intensity = series.intensity.isNotEmpty
              ? double.tryParse(series.intensity)
              : null;
          if (intensity != null) {
            final calculatedWeight =
                _calculateWeightFromIntensity(maxWeight, intensity);
            progression.series[i] = series.copyWith(
              weight: _roundWeight(calculatedWeight, exerciseType),
            );
          }
        }
      }
    }
  }

  /// Calculates weight from intensity percentage
  double _calculateWeightFromIntensity(double maxWeight, double intensity) {
    if (maxWeight <= 0 || intensity <= 0) return 0;
    return maxWeight * (intensity / 100);
  }

  /// Rounds weight based on exercise type
  double _roundWeight(double weight, String exerciseType) {
    // Logic for rounding weights can be implemented here
    // For now, return the weight rounded to 1 decimal place
    return double.parse(weight.toStringAsFixed(1));
  }

  /// Tracks week for deletion
  void _trackWeekForDeletion(TrainingProgram program, Week week) {
    if (week.id != null) {
      program.trackToDeleteWeeks.add(week.id!);
    }
    for (var workout in week.workouts) {
      _trackWorkoutForDeletion(program, workout);
    }
  }

  /// Tracks workout for deletion
  void _trackWorkoutForDeletion(TrainingProgram program, Workout workout) {
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    for (var exercise in workout.exercises) {
      _trackExerciseForDeletion(program, exercise);
    }
  }

  /// Tracks exercise for deletion
  void _trackExerciseForDeletion(TrainingProgram program, Exercise exercise) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    for (var series in exercise.series) {
      _trackSeriesForDeletion(program, series);
    }
  }

  /// Tracks series for deletion
  void _trackSeriesForDeletion(TrainingProgram program, Series series) {
    program.trackToDeleteSeries.add(series.serieId);
  }
}
