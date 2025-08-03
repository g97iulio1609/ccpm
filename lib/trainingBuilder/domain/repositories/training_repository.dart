import '../../models/training_model.dart';
import '../../models/exercise_model.dart';
import '../../models/series_model.dart';
import '../../models/week_model.dart';
import '../../models/workout_model.dart';

abstract class TrainingRepository {
  Future<TrainingProgram?> getTrainingProgram(String programId);
  Future<void> saveTrainingProgram(TrainingProgram program);
  Future<void> deleteTrainingProgram(String programId);
  Stream<List<TrainingProgram>> streamTrainingPrograms();
  Future<void> removeToDeleteItems(TrainingProgram program);
}

abstract class ExerciseRepository {
  Future<String> addExerciseToWorkout(
      String workoutId, Map<String, dynamic> exerciseData);
  Future<void> updateExercise(
      String exerciseId, Map<String, dynamic> exerciseData);
  Future<void> removeExercise(String exerciseId);
  Future<List<Exercise>> getExercisesByWorkoutId(String workoutId);
}

abstract class SeriesRepository {
  Future<String> addSeriesToExercise(String exerciseId, Series series,
      {String? originalExerciseId});
  Future<void> updateSeries(String seriesId, Series series);
  Future<void> removeSeries(String seriesId);
  Future<List<Series>> getSeriesByExerciseId(String exerciseId);
}

abstract class WeekRepository {
  Future<String> addWeekToProgram(
      String programId, Map<String, dynamic> weekData);
  Future<void> updateWeek(String weekId, Map<String, dynamic> weekData);
  Future<void> removeWeek(String weekId);
  Future<List<Week>> getWeeksByProgramId(String programId);
}

abstract class WorkoutRepository {
  Future<String> addWorkoutToWeek(
      String weekId, Map<String, dynamic> workoutData);
  Future<void> updateWorkout(
      String workoutId, Map<String, dynamic> workoutData);
  Future<void> removeWorkout(String workoutId);
  Future<List<Workout>> getWorkoutsByWeekId(String weekId);
}
