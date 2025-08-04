import '../../../shared/shared.dart';
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
      repsDone: 0,
      weightDone: 0.0,
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

    final copiedSuperSets = source.superSets?.map((superSetData) {
      final newSuperSetId = generateRandomId(16).toString();
      final exerciseIds = superSetData['exerciseIds'] as List<dynamic>? ?? [];
      final newExerciseIds =
          exerciseIds.map((id) => newExerciseIdMap[id.toString()] ?? id.toString()).toList();

      // Update superset IDs in exercises by creating new instances
      for (int i = 0; i < copiedExercises.length; i++) {
        if (newExerciseIds.contains(copiedExercises[i].id)) {
          copiedExercises[i] = copiedExercises[i].copyWith(superSetId: newSuperSetId);
        }
      }

      return {
        'id': newSuperSetId,
        'name': superSetData['name'] ?? '',
        'exerciseIds': newExerciseIds,
      };
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
    for (int i = startIndex; i < exercises.length; i++) {
      // Create new exercise with updated order since order is final
      exercises[i] = exercises[i].copyWith(order: i + 1);
    }
  }

  /// Updates series orders
  static void updateSeriesOrders(List<Series> series, int startIndex) {
    for (int i = startIndex; i < series.length; i++) {
      // Create new series with updated order since order is final
      series[i] = series[i].copyWith(order: i + 1);
    }
  }

  /// Updates workout orders
  static void updateWorkoutOrders(List<Workout> workouts, int startIndex) {
    for (int i = startIndex; i < workouts.length; i++) {
      // Create new workout with updated order since order is final
      workouts[i] = workouts[i].copyWith(order: i + 1);
    }
  }

  /// Updates week numbers
  static void updateWeekNumbers(List<Week> weeks, int startIndex) {
    for (int i = startIndex; i < weeks.length; i++) {
      // Create new week with updated number since number is final
      weeks[i] = weeks[i].copyWith(number: i + 1);
    }
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
