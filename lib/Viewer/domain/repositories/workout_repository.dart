import 'package:alphanessone/viewer/domain/entities/exercise.dart';
import 'package:alphanessone/viewer/domain/entities/series.dart';
import 'package:alphanessone/viewer/domain/entities/workout.dart';
import 'package:alphanessone/viewer/domain/entities/week.dart';

abstract class WorkoutRepository {
  // Week Operations
  Stream<List<Week>> getTrainingWeeks(String programId);
  Future<Week> getWeek(String weekId);
  Future<void> createWeek(Week week);
  Future<void> updateWeek(Week week);
  Future<void> deleteWeek(String weekId);
  Future<String> getWeekName(
      String weekId); // Spostato da TrainingProgramServices

  // Workout Operations
  Stream<List<Workout>> getWorkouts(String weekId);
  Future<Workout> getWorkout(String workoutId);
  Future<String> getWorkoutName(String workoutId);
  Future<void> createWorkout(Workout workout);
  Future<void> updateWorkout(Workout workout);
  Future<void> deleteWorkout(String workoutId);

  // Exercise Operations
  Stream<List<Exercise>> getExercisesForWorkout(String workoutId);
  Future<Exercise> getExercise(String exerciseId);
  Future<void> createExercise(Exercise exercise);
  Future<void> updateExercise(Exercise exercise);
  Future<void> deleteExercise(String exerciseId);
  Future<void> updateExercisesInWorkout(
      String workoutId, List<Exercise> exercises);

  // Series Operations
  Stream<List<Series>> getSeriesForExercise(String exerciseId);
  Future<Series> getSeries(String seriesId);
  Future<void> createSeries(Series series);
  Future<void> updateSeries(Series series);
  Future<void> deleteSeries(String seriesId);
  Future<void> updateMultipleSeries(List<Series> seriesList);
  Future<void> updateSeriesDoneStatus(
      String seriesId, bool isDone, int repsDone, double weightDone);
  Future<void> updateSeriesRepsAndWeight(
      String seriesId, int repsDone, double weightDone);

  // Note Operations
  Future<String?> getNoteForExercise(String workoutId, String exerciseId);
  Future<void> saveNoteForExercise(
      String workoutId, String exerciseId, String note);
  Future<void> deleteNoteForExercise(String workoutId, String exerciseId);
  Stream<Map<String, String>> getNotesForWorkoutStream(String workoutId);
}
