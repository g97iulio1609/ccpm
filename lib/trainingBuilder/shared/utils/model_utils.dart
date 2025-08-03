import '../../models/exercise_model.dart';
import '../../models/series_model.dart';
import '../../models/week_model.dart';
import '../../models/workout_model.dart';
import '../../models/superseries_model.dart';
import '../../utility_functions.dart';

/// Utility class for common model operations following DRY principle
class ModelUtils {
  ModelUtils._();

  /// Creates a deep copy of an exercise with new IDs
  static Exercise copyExercise(Exercise source) {
    return source.copyWith(
      id: generateRandomId(16).toString(),
      series: source.series.map((s) => copySeries(s)).toList(),
      superSetId: null, // Reset superset assignment
    );
  }

  /// Creates a deep copy of a series with new ID and reset state
  static Series copySeries(Series source) {
    return source.copyWith(
      serieId: generateRandomId(16).toString(),
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
  }

  /// Creates a deep copy of a workout with new IDs
  static Workout copyWorkout(Workout source,
      {Map<String, String>? exerciseIdMap}) {
    final newExerciseIdMap = <String, String>{};

    final copiedExercises = source.exercises.map((exercise) {
      final copiedExercise = copyExercise(exercise);
      if (exercise.id != null) {
        newExerciseIdMap[exercise.id!] = copiedExercise.id!;
      }
      return copiedExercise;
    }).toList();

    final copiedSuperSets = source.superSets.map((superSet) {
      final newSuperSetId = generateRandomId(16);
      final newExerciseIds =
          superSet.exerciseIds.map((id) => newExerciseIdMap[id] ?? id).toList();

      // Update superset IDs in exercises
      for (final exerciseId in newExerciseIds) {
        final exercise = copiedExercises.firstWhere(
          (e) => e.id == exerciseId,
          orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
        );
        if (exercise.id != null) {
          exercise.superSetId = newSuperSetId;
        }
      }

      return SuperSet(
        id: newSuperSetId,
        name: superSet.name,
        exerciseIds: newExerciseIds,
      );
    }).toList();

    return source.copyWith(
      id: null,
      exercises: copiedExercises,
      superSets: copiedSuperSets,
    );
  }

  /// Creates a deep copy of a week with new IDs
  static Week copyWeek(Week source) {
    return source.copyWith(
      id: null,
      workouts: source.workouts.map((w) => copyWorkout(w)).toList(),
    );
  }

  /// Updates order for a list of items with order property
  static void updateOrders<T>(List<T> items, int Function(T) getOrder,
      void Function(T, int) setOrder, int startIndex) {
    for (int i = startIndex; i < items.length; i++) {
      setOrder(items[i], i + 1);
    }
  }

  /// Updates exercise orders
  static void updateExerciseOrders(List<Exercise> exercises, int startIndex) {
    updateOrders(
      exercises,
      (exercise) => exercise.order,
      (exercise, order) => exercise.order = order,
      startIndex,
    );
  }

  /// Updates series orders
  static void updateSeriesOrders(List<Series> series, int startIndex) {
    updateOrders(
      series,
      (s) => s.order,
      (s, order) => s.order = order,
      startIndex,
    );
  }

  /// Updates workout orders
  static void updateWorkoutOrders(List<Workout> workouts, int startIndex) {
    updateOrders(
      workouts,
      (workout) => workout.order,
      (workout, order) => workout.order = order,
      startIndex,
    );
  }

  /// Updates week numbers
  static void updateWeekNumbers(List<Week> weeks, int startIndex) {
    updateOrders(
      weeks,
      (week) => week.number,
      (week, number) => week.number = number,
      startIndex,
    );
  }

  /// Groups series by similar properties
  static List<List<Series>> groupSimilarSeries(List<Series> series) {
    if (series.isEmpty) return [];

    final groups = <List<Series>>[];
    List<Series> currentGroup = [series[0]];

    for (int i = 1; i < series.length; i++) {
      if (_areSeriesSimilar(series[i], series[i - 1])) {
        currentGroup.add(series[i]);
      } else {
        groups.add(List.from(currentGroup));
        currentGroup = [series[i]];
      }
    }

    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    return groups;
  }

  /// Checks if two series are similar (same parameters except sets)
  static bool _areSeriesSimilar(Series a, Series b) {
    return a.reps == b.reps &&
        a.maxReps == b.maxReps &&
        a.intensity == b.intensity &&
        a.maxIntensity == b.maxIntensity &&
        a.rpe == b.rpe &&
        a.maxRpe == b.maxRpe &&
        a.weight == b.weight &&
        a.maxWeight == b.maxWeight;
  }

  /// Creates a representative series for a group
  static Series createRepresentativeSeries(List<Series> group) {
    if (group.isEmpty) {
      throw ArgumentError('Group cannot be empty');
    }

    final first = group.first;
    return first.copyWith(sets: group.length);
  }

  /// Expands a representative series into individual series
  static List<Series> expandRepresentativeSeries(Series representative) {
    return List.generate(
      representative.sets,
      (index) => representative.copyWith(
        serieId: generateRandomId(16).toString(),
        sets: 1,
        order: index + 1,
      ),
    );
  }
}
