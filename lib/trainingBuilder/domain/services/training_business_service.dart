import '../../../shared/shared.dart'
    hide ValidationUtils, ModelUtils, ExerciseRepository, WeekRepository;
import '../repositories/training_repository.dart';
import '../../../ExerciseRecords/exercise_record_services.dart';
import '../../shared/utils/validation_utils.dart';
import '../../shared/utils/model_utils.dart';
import 'simple_copy_service.dart';

import '../../../shared/services/weight_calculation_service.dart';
import '../../services/exercise_service.dart' as tb_exercise_service;

/// Business service that handles training program business logic
/// Follows Single Responsibility Principle
class TrainingBusinessService {
  final TrainingRepository _trainingRepository;
  final ExerciseRecordService _exerciseRecordService;

  TrainingBusinessService({
    required TrainingRepository trainingRepository,
    required ExerciseRecordService exerciseRecordService,
  }) : _trainingRepository = trainingRepository,
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
      workouts: [Workout(id: '', name: 'Workout 1', order: 1, exercises: [])],
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
      name: 'Workout ${program.weeks[weekIndex].workouts.length + 1}',
      order: program.weeks[weekIndex].workouts.length + 1,
      exercises: [],
    );
    program.weeks[weekIndex].workouts.add(newWorkout);
  }

  /// Removes a workout from a week
  void removeWorkout(TrainingProgram program, int weekIndex, int workoutIndex) {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      throw ArgumentError('Invalid workout index');
    }

    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    _trackWorkoutForDeletion(program, workout);
    program.weeks[weekIndex].workouts.removeAt(workoutIndex);
    ModelUtils.updateWorkoutOrders(
      program.weeks[weekIndex].workouts,
      workoutIndex,
    );
  }

  /// Adds an exercise to a workout
  void addExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    Exercise exercise,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      throw ArgumentError('Invalid indices');
    }

    if (!ValidationUtils.isValidExercise(exercise)) {
      throw ArgumentError('Invalid exercise data');
    }

    final exerciseToAdd = exercise.copyWith(
      id: null,
      order:
          program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1,
      weekProgressions: List.generate(program.weeks.length, (_) => []),
    );
    program.weeks[weekIndex].workouts[workoutIndex].exercises.add(
      exerciseToAdd,
    );
  }

  /// Removes an exercise from a workout
  void removeExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    )) {
      throw ArgumentError('Invalid exercise index');
    }

    final exercise = program
        .weeks[weekIndex]
        .workouts[workoutIndex]
        .exercises[exerciseIndex];
    _trackExerciseForDeletion(program, exercise);
    program.weeks[weekIndex].workouts[workoutIndex].exercises.removeAt(
      exerciseIndex,
    );

    final exercises = program.weeks[weekIndex].workouts[workoutIndex].exercises;
    ModelUtils.updateExerciseOrders(exercises, exerciseIndex);
  }

  /// Removes multiple exercises from a workout in one pass (bulk)
  /// Optimized to track deletions and reorder only once.
  void removeExercisesBulkByIds(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    List<String> exerciseIds,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
    )) {
      throw ArgumentError('Invalid indices');
    }
    if (exerciseIds.isEmpty) return;

    final workout = program.weeks[weekIndex].workouts[workoutIndex];
    final idSet = exerciseIds.toSet();

    // Track all matched exercises for deletion and collect their indices
    final indicesToRemove = <int>[];
    for (int i = 0; i < workout.exercises.length; i++) {
      final ex = workout.exercises[i];
      final exId = ex.id;
      if (exId != null && idSet.contains(exId)) {
        _trackExerciseForDeletion(program, ex);
        indicesToRemove.add(i);
      }
    }

    if (indicesToRemove.isEmpty) return;

    // Clean up supersets in workout mapping (if present)
    final originalSuperSets = List<Map<String, dynamic>>.from(
      workout.superSets ?? const [],
    );
    final cleanedSuperSets = <Map<String, dynamic>>[];
    for (final ss in originalSuperSets) {
      final Map<String, dynamic> entry = Map<String, dynamic>.from(ss);
      final List<String> exIds = List<String>.from(entry['exerciseIds'] ?? []);
      final filtered = exIds.where((id) => !idSet.contains(id)).toList();
      if (filtered.isNotEmpty) {
        entry['exerciseIds'] = filtered;
        cleanedSuperSets.add(entry);
      }
    }

    // Remove exercises in descending index order to avoid shifting
    final remaining = List<Exercise>.from(workout.exercises);
    indicesToRemove.sort((a, b) => b.compareTo(a));
    for (final idx in indicesToRemove) {
      remaining.removeAt(idx);
    }
    ModelUtils.updateExerciseOrders(remaining, 0);

    // Write updated workout back into the program
    program.weeks[weekIndex].workouts[workoutIndex] = workout.copyWith(
      exercises: remaining,
      superSets: cleanedSuperSets.isEmpty ? null : cleanedSuperSets,
    );
  }

  /// Duplicates an exercise in a workout
  void duplicateExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
    )) {
      throw ArgumentError('Invalid exercise index');
    }

    final sourceExercise = program
        .weeks[weekIndex]
        .workouts[workoutIndex]
        .exercises[exerciseIndex];
    final duplicatedExercise = ModelUtils.copyExercise(
      sourceExercise,
      targetWeekIndex: weekIndex,
    );

    final exerciseWithNewOrder = duplicatedExercise.copyWith(
      order:
          program.weeks[weekIndex].workouts[workoutIndex].exercises.length + 1,
    );
    program.weeks[weekIndex].workouts[workoutIndex].exercises.add(
      exerciseWithNewOrder,
    );
  }

  /// Updates the number of a specific week
  void updateWeekNumber(
    TrainingProgram program,
    int weekIndex,
    int newWeekNumber,
  ) {
    if (!ValidationUtils.isValidProgramIndex(program, weekIndex)) {
      throw ArgumentError('Invalid week index');
    }

    if (newWeekNumber < 1) {
      throw ArgumentError('Week number must be greater than 0');
    }

    // Check if the new week number is already in use by another week
    final existingWeekIndex = program.weeks.indexWhere(
      (week) => week.number == newWeekNumber,
    );

    if (existingWeekIndex != -1 && existingWeekIndex != weekIndex) {
      // Swap the week numbers
      final currentWeek = program.weeks[weekIndex];
      final existingWeek = program.weeks[existingWeekIndex];

      program.weeks[weekIndex] = currentWeek.copyWith(number: newWeekNumber);
      program.weeks[existingWeekIndex] = existingWeek.copyWith(
        number: currentWeek.number,
      );

      // Update week progressions for all exercises in both weeks
      _updateWeekProgressionsForWeekNumberChange(
        program,
        weekIndex,
        existingWeekIndex,
      );
    } else {
      // Simply update the week number
      final currentWeek = program.weeks[weekIndex];
      program.weeks[weekIndex] = currentWeek.copyWith(number: newWeekNumber);

      // Update week progressions for all exercises in this week
      _updateWeekProgressionsForSingleWeek(program, weekIndex);
    }
  }

  /// Updates week progressions when week numbers are swapped
  void _updateWeekProgressionsForWeekNumberChange(
    TrainingProgram program,
    int weekIndex1,
    int weekIndex2,
  ) {
    for (int wIndex = 0; wIndex < program.weeks.length; wIndex++) {
      final week = program.weeks[wIndex];
      for (final workout in week.workouts) {
        for (int eIndex = 0; eIndex < workout.exercises.length; eIndex++) {
          final exercise = workout.exercises[eIndex];
          if (exercise.weekProgressions != null) {
            // Update week numbers in progressions
            for (
              int wpIndex = 0;
              wpIndex < exercise.weekProgressions!.length;
              wpIndex++
            ) {
              if (wpIndex == weekIndex1 || wpIndex == weekIndex2) {
                for (
                  int progIndex = 0;
                  progIndex < exercise.weekProgressions![wpIndex].length;
                  progIndex++
                ) {
                  final progression =
                      exercise.weekProgressions![wpIndex][progIndex];
                  final newWeekNumber = wpIndex == weekIndex1
                      ? program.weeks[weekIndex1].number
                      : program.weeks[weekIndex2].number;
                  exercise.weekProgressions![wpIndex][progIndex] = progression
                      .copyWith(weekNumber: newWeekNumber);
                }
              }
            }
          }
        }
      }
    }
  }

  /// Updates week progressions for a single week
  void _updateWeekProgressionsForSingleWeek(
    TrainingProgram program,
    int weekIndex,
  ) {
    final week = program.weeks[weekIndex];
    for (final workout in week.workouts) {
      for (int eIndex = 0; eIndex < workout.exercises.length; eIndex++) {
        final exercise = workout.exercises[eIndex];
        if (exercise.weekProgressions != null &&
            exercise.weekProgressions!.length > weekIndex) {
          for (
            int progIndex = 0;
            progIndex < exercise.weekProgressions![weekIndex].length;
            progIndex++
          ) {
            final progression =
                exercise.weekProgressions![weekIndex][progIndex];
            exercise.weekProgressions![weekIndex][progIndex] = progression
                .copyWith(weekNumber: week.number);
          }
        }
      }
    }
  }

  /// Copies a week following KISS principle - simply adds a new week with all new IDs
  /// No tracking lists, no complex ID management, just pure copying
  Future<void> copyWeek(
    TrainingProgram program,
    int sourceWeekIndex,
    int? destinationWeekIndex,
  ) async {
    if (!ValidationUtils.isValidProgramIndex(program, sourceWeekIndex)) {
      throw ArgumentError('Invalid source week index');
    }

    final sourceWeek = program.weeks[sourceWeekIndex];

    // KISS: Simply create a new week with the next available number
    final newWeekNumber = program.weeks.length + 1;
    final copiedWeek = SimpleCopyService.copyWeek(
      sourceWeek,
      targetWeekNumber: newWeekNumber,
    );

    // KISS: Just add it to the end - no complex positioning logic
    program.weeks.add(copiedWeek);
  }

  /// Copies a workout to another week
  Future<void> copyWorkout(
    TrainingProgram program,
    int sourceWeekIndex,
    int workoutIndex,
    int? destinationWeekIndex,
  ) async {
    if (!ValidationUtils.isValidProgramIndex(
      program,
      sourceWeekIndex,
      workoutIndex,
    )) {
      throw ArgumentError('Invalid source indices');
    }

    final sourceWorkout = program.weeks[sourceWeekIndex].workouts[workoutIndex];
    final copiedWorkout = ModelUtils.copyWorkout(
      sourceWorkout,
      targetWeekIndex: destinationWeekIndex,
    );

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
      // When destination is null, default to copying within the same source week
      if (destinationWeekIndex == null) {
        program.weeks[sourceWeekIndex].workouts.add(copiedWorkout);
        return;
      }

      // Destination provided but beyond current weeks -> create only what's necessary
      while (program.weeks.length <= destinationWeekIndex) {
        addWeek(program);
      }
      program.weeks[destinationWeekIndex].workouts.add(copiedWorkout);
    }
  }

  /// Updates exercise weights based on latest max weight
  Future<void> updateExerciseWeights(
    TrainingProgram program,
    String exerciseId,
    String exerciseType,
  ) async {
    final newMaxWeight = await _getLatestMaxWeight(
      program.athleteId,
      exerciseId,
    );

    for (final week in program.weeks) {
      for (final workout in week.workouts) {
        for (final exercise in workout.exercises) {
          if (exercise.exerciseId == exerciseId) {
            _updateExerciseWeightsInternal(
              exercise,
              newMaxWeight.toDouble(),
              exerciseType,
            );
          }
        }
      }
    }
  }

  /// Gets latest max weight for an exercise
  Future<num> _getLatestMaxWeight(String athleteId, String exerciseId) async {
    if (exerciseId.isEmpty) return 0;
    // Delegato a ExerciseService centralizzato (DRY)
    return await tb_exercise_service.ExerciseService.getLatestMaxWeight(
      _exerciseRecordService,
      athleteId,
      exerciseId,
    );
  }

  /// Updates weights for an exercise and its series
  void _updateExerciseWeightsInternal(
    Exercise exercise,
    double maxWeight,
    String exerciseType,
  ) {
    // Update series weights
    for (int i = 0; i < exercise.series.length; i++) {
      final series = exercise.series[i];
      final intensity = series.intensity?.isNotEmpty == true
          ? double.tryParse(series.intensity!)
          : null;
      if (intensity != null) {
        final calculatedWeight =
            WeightCalculationService.calculateWeightFromIntensity(
              maxWeight,
              intensity,
            );
        exercise.series[i] = series.copyWith(
          weight: WeightCalculationService.roundWeight(
            calculatedWeight,
            exerciseType,
          ),
        );
      }
    }

    // Update week progressions weights
    if (exercise.weekProgressions != null) {
      for (final weekProgressions in exercise.weekProgressions!) {
        for (final progression in weekProgressions) {
          for (int i = 0; i < progression.series.length; i++) {
            final series = progression.series[i];
            final intensity = series.intensity?.isNotEmpty == true
                ? double.tryParse(series.intensity!)
                : null;
            if (intensity != null) {
              final calculatedWeight =
                  WeightCalculationService.calculateWeightFromIntensity(
                    maxWeight,
                    intensity,
                  );
              progression.series[i] = series.copyWith(
                weight: WeightCalculationService.roundWeight(
                  calculatedWeight,
                  exerciseType,
                ),
              );
            }
          }
        }
      }
    }
  }

  /// Tracks week for deletion
  void _trackWeekForDeletion(TrainingProgram program, Week week) {
    if (week.id != null) {
      program.trackToDeleteWeeks.add(week.id!);
    }
    for (final workout in week.workouts) {
      _trackWorkoutForDeletion(program, workout);
    }
  }

  /// Tracks workout for deletion
  void _trackWorkoutForDeletion(TrainingProgram program, Workout workout) {
    if (workout.id != null) {
      program.trackToDeleteWorkouts.add(workout.id!);
    }
    for (final exercise in workout.exercises) {
      _trackExerciseForDeletion(program, exercise);
    }
  }

  /// Tracks exercise for deletion
  void _trackExerciseForDeletion(TrainingProgram program, Exercise exercise) {
    if (exercise.id != null) {
      program.trackToDeleteExercises.add(exercise.id!);
    }
    for (final series in exercise.series) {
      _trackSeriesForDeletion(program, series);
    }
  }

  /// Tracks series for deletion
  void _trackSeriesForDeletion(TrainingProgram program, Series series) {
    program.markSeriesForDeletion(series);
  }
}
