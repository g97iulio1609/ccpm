import '../../../shared/shared.dart';

/// Training-specific repository interface
/// Handles training program operations that are specific to the training builder
abstract class TrainingRepository {
  Future<TrainingProgram?> getTrainingProgram(String programId);
  Future<void> saveTrainingProgram(TrainingProgram program);
  Future<void> deleteTrainingProgram(String programId);
  Stream<List<TrainingProgram>> streamTrainingPrograms();
  Future<void> removeToDeleteItems(TrainingProgram program);
}

/// Training Builder specific Exercise Repository interface
/// Provides simplified interface for training builder operations
abstract class ExerciseRepository {
  Future<String> addExerciseToWorkout(String workoutId, Map<String, dynamic> exerciseData);
  Future<void> updateExercise(String exerciseId, Map<String, dynamic> exerciseData);
  Future<void> removeExercise(String exerciseId);
  Future<List<Exercise>> getExercisesByWorkoutId(String workoutId);
}

/// Series repository interface specific to training builder
/// Handles series operations with training-specific features
abstract class SeriesRepository {
  Future<String> addSeriesToExercise(
    String exerciseId,
    Series series, {
    String? originalExerciseId,
  });
  Future<void> updateSeries(String seriesId, Series series);
  Future<void> removeSeries(String seriesId);
  Future<List<Series>> getSeriesByExerciseId(String exerciseId);
}

/// Training Builder specific Week Repository interface
/// Provides simplified interface for training builder operations
abstract class WeekRepository {
  Future<String> addWeekToProgram(String programId, Map<String, dynamic> weekData);
  Future<void> updateWeek(String weekId, Map<String, dynamic> weekData);
  Future<void> removeWeek(String weekId);
  Future<List<Week>> getWeeksByProgramId(String programId);
}

/// Training Builder specific Workout Repository interface
/// Provides simplified interface for training builder operations
abstract class WorkoutRepository {
  Future<String> addWorkoutToWeek(String weekId, Map<String, dynamic> workoutData);
  Future<void> updateWorkout(String workoutId, Map<String, dynamic> workoutData);
  Future<void> removeWorkout(String workoutId);
  Future<List<Workout>> getWorkoutsByWeekId(String weekId);
}
