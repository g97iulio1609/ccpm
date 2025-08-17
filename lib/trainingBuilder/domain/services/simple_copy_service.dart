import '../../../shared/shared.dart';
import '../../utility_functions.dart';

/// Simple copy service following KISS, SOLID, DRY principles
/// Single Responsibility: Only handles copying operations
class SimpleCopyService {
  SimpleCopyService._();

  /// Creates a complete copy of a week with all new IDs
  /// KISS: Simple deep copy without any tracking logic
  static Week copyWeek(Week sourceWeek, {int? targetWeekNumber}) {
    return Week(
      id: null, // Always null - new week gets new ID from database
      number: targetWeekNumber ?? (sourceWeek.number + 1),
      workouts: sourceWeek.workouts.map((workout) => _copyWorkout(workout)).toList(),
    );
  }

  /// Creates a complete copy of a workout with all new IDs
  static Workout _copyWorkout(Workout sourceWorkout) {
    return Workout(
      id: null, // Always null - new workout gets new ID from database
      name: sourceWorkout.name,
      order: sourceWorkout.order,
      exercises: sourceWorkout.exercises.map((exercise) => _copyExercise(exercise)).toList(),
      superSets: sourceWorkout.superSets?.map((superSetData) => Map<String, dynamic>.from(superSetData)).toList(),
    );
  }

  /// Creates a complete copy of an exercise with all new IDs
  static Exercise _copyExercise(Exercise sourceExercise) {
    return Exercise(
      id: null, // Always null - new exercise gets new ID from database
      exerciseId: sourceExercise.exerciseId,
      name: sourceExercise.name,
      variant: sourceExercise.variant,
      order: sourceExercise.order,
      type: sourceExercise.type,
      latestMaxWeight: sourceExercise.latestMaxWeight,
      superSetId: null, // Reset superset assignment for copied exercise
      series: sourceExercise.series.map((series) => _copySeries(series)).toList(),
      weekProgressions: _copyWeekProgressions(sourceExercise.weekProgressions),
    );
  }

  /// Creates a complete copy of a series with all new IDs and reset completion data
  static Series _copySeries(Series sourceSeries) {
    return Series(
      serieId: null, // Always null - new series gets new ID from database
      exerciseId: sourceSeries.exerciseId,
      reps: sourceSeries.reps,
      maxReps: sourceSeries.maxReps,
      sets: sourceSeries.sets,
      maxSets: sourceSeries.maxSets,
      intensity: sourceSeries.intensity,
      maxIntensity: sourceSeries.maxIntensity,
      rpe: sourceSeries.rpe,
      maxRpe: sourceSeries.maxRpe,
      weight: sourceSeries.weight,
      maxWeight: sourceSeries.maxWeight,
      order: sourceSeries.order,
      // Reset completion data for copied series
      done: false,
      repsDone: 0,
      weightDone: 0.0,
    );
  }

  /// Creates a copy of week progressions with reset completion data
  static List<List<WeekProgression>>? _copyWeekProgressions(List<List<WeekProgression>>? sourceProgressions) {
    if (sourceProgressions == null) return null;

    return sourceProgressions.map((weekProgression) {
      return weekProgression.map((progression) {
        return WeekProgression(
          weekNumber: progression.weekNumber,
          sessionNumber: progression.sessionNumber,
          series: progression.series.map((series) => _copySeries(series)).toList(),
        );
      }).toList();
    }).toList();
  }
}