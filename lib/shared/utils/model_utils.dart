import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import '../models/series.dart';
import '../models/workout.dart';
import '../models/week.dart';

/// Shared model utilities for training entities
/// Consolidates model operations from both trainingBuilder and Viewer modules
class ModelUtils {
  // Private constructor to prevent instantiation
  ModelUtils._();
  
  /// Generate unique ID for models
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (DateTime.now().microsecond % 1000).toString().padLeft(3, '0');
  }
  
  /// Generate Firestore document ID
  static String generateFirestoreId() {
    return FirebaseFirestore.instance.collection('temp').doc().id;
  }
  
  /// Create timestamp for Firestore
  static Timestamp createTimestamp([DateTime? dateTime]) {
    return Timestamp.fromDate(dateTime ?? DateTime.now());
  }
  
  /// Convert Firestore timestamp to DateTime
  static DateTime? timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }
  
  /// Safe map access with type checking
  static T? safeGet<T>(Map<String, dynamic>? map, String key, [T? defaultValue]) {
    if (map == null || !map.containsKey(key)) return defaultValue;
    final value = map[key];
    if (value is T) return value;
    return defaultValue;
  }
  
  /// Safe list access with type checking
  static List<T> safeGetList<T>(Map<String, dynamic>? map, String key, [List<T>? defaultValue]) {
    if (map == null || !map.containsKey(key)) return defaultValue ?? <T>[];
    final value = map[key];
    if (value is List) {
      return value.whereType<T>().toList();
    }
    return defaultValue ?? <T>[];
  }
  
  /// Safe map list access
  static List<Map<String, dynamic>> safeGetMapList(Map<String, dynamic>? map, String key) {
    if (map == null || !map.containsKey(key)) return [];
    final value = map[key];
    if (value is List) {
      return value.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }
  
  /// Convert dynamic value to string safely
  static String safeString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    return value.toString();
  }
  
  /// Convert dynamic value to int safely
  static int safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  /// Convert dynamic value to double safely
  static double safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  /// Convert dynamic value to bool safely
  static bool safeBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return defaultValue;
  }
  
  /// Deep copy a map
  static Map<String, dynamic> deepCopyMap(Map<String, dynamic> original) {
    final copy = <String, dynamic>{};
    for (final entry in original.entries) {
      if (entry.value is Map<String, dynamic>) {
        copy[entry.key] = deepCopyMap(entry.value);
      } else if (entry.value is List) {
        copy[entry.key] = deepCopyList(entry.value);
      } else {
        copy[entry.key] = entry.value;
      }
    }
    return copy;
  }
  
  /// Deep copy a list
  static List<dynamic> deepCopyList(List<dynamic> original) {
    return original.map((item) {
      if (item is Map<String, dynamic>) {
        return deepCopyMap(item);
      } else if (item is List) {
        return deepCopyList(item);
      } else {
        return item;
      }
    }).toList();
  }
  
  /// Merge two maps, with the second map taking precedence
  static Map<String, dynamic> mergeMaps(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    final result = deepCopyMap(map1);
    for (final entry in map2.entries) {
      if (entry.value is Map<String, dynamic> && result[entry.key] is Map<String, dynamic>) {
        result[entry.key] = mergeMaps(result[entry.key], entry.value);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
  
  /// Remove null values from map
  static Map<String, dynamic> removeNulls(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value != null) {
        if (entry.value is Map<String, dynamic>) {
          final cleaned = removeNulls(entry.value);
          if (cleaned.isNotEmpty) {
            result[entry.key] = cleaned;
          }
        } else if (entry.value is List) {
          final cleanedList = (entry.value as List).where((item) => item != null).toList();
          if (cleanedList.isNotEmpty) {
            result[entry.key] = cleanedList;
          }
        } else {
          result[entry.key] = entry.value;
        }
      }
    }
    return result;
  }
  
  /// Check if two objects are deeply equal
  static bool deepEquals(dynamic obj1, dynamic obj2) {
    if (identical(obj1, obj2)) return true;
    if (obj1.runtimeType != obj2.runtimeType) return false;
    
    if (obj1 is Map && obj2 is Map) {
      if (obj1.length != obj2.length) return false;
      for (final key in obj1.keys) {
        if (!obj2.containsKey(key) || !deepEquals(obj1[key], obj2[key])) {
          return false;
        }
      }
      return true;
    }
    
    if (obj1 is List && obj2 is List) {
      if (obj1.length != obj2.length) return false;
      for (int i = 0; i < obj1.length; i++) {
        if (!deepEquals(obj1[i], obj2[i])) return false;
      }
      return true;
    }
    
    return obj1 == obj2;
  }
  
  /// Calculate hash code for complex objects
  static int deepHashCode(dynamic obj) {
    if (obj == null) return 0;
    
    if (obj is Map) {
      int hash = 0;
      for (final entry in obj.entries) {
        hash ^= entry.key.hashCode ^ deepHashCode(entry.value);
      }
      return hash;
    }
    
    if (obj is List) {
      int hash = 0;
      for (int i = 0; i < obj.length; i++) {
        hash ^= i.hashCode ^ deepHashCode(obj[i]);
      }
      return hash;
    }
    
    return obj.hashCode;
  }
}

/// Exercise-specific utilities
class ExerciseUtils {
  /// Create a duplicate of an exercise with new ID
  static Exercise duplicateExercise(Exercise exercise, {String? newId, String? newName}) {
    return exercise.copyWith(
      id: newId ?? ModelUtils.generateId(),
      name: newName ?? '${exercise.name} (Copy)',
      series: exercise.series.map((s) => SharedSeriesUtils.duplicateSeries(s)).toList(),
    );
  }
  
  /// Reset exercise completion status
  static Exercise resetExercise(Exercise exercise) {
    return exercise.copyWith(
      series: exercise.series.map((s) => SharedSeriesUtils.resetSeries(s)).toList(),
    );
  }
  
  /// Calculate total volume for exercise
  static double calculateVolume(Exercise exercise) {
    return exercise.series.fold(0.0, (total, series) => 
        total + SharedSeriesUtils.calculateSeriesVolume(series));
  }
  
  /// Calculate completion percentage
  static double calculateCompletionPercentage(Exercise exercise) {
    if (exercise.series.isEmpty) return 0.0;
    final completedSeries = exercise.series.where((s) => s.isCompleted).length;
    return (completedSeries / exercise.series.length) * 100;
  }
  
  /// Get exercise summary
  static Map<String, dynamic> getExerciseSummary(Exercise exercise) {
    return {
      'totalSeries': exercise.series.length,
      'completedSeries': exercise.series.where((s) => s.isCompleted).length,
      'totalVolume': calculateVolume(exercise),
      'completionPercentage': calculateCompletionPercentage(exercise),
      'isCompleted': exercise.isCompleted,
      'type': exercise.type,
      'supersetId': exercise.superSetId,
    };
  }
  
  /// Group exercises by superset
  static Map<String?, List<Exercise>> groupBySuperset(List<Exercise> exercises) {
    final grouped = <String?, List<Exercise>>{};
    for (final exercise in exercises) {
      final key = exercise.superSetId;
      grouped.putIfAbsent(key, () => []).add(exercise);
    }
    return grouped;
  }
  
  /// Reorder exercises
  static List<Exercise> reorderExercises(List<Exercise> exercises, int oldIndex, int newIndex) {
    final reordered = List<Exercise>.from(exercises);
    final exercise = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, exercise.copyWith(order: newIndex));
    
    // Update order for all exercises
    for (int i = 0; i < reordered.length; i++) {
      reordered[i] = reordered[i].copyWith(order: i);
    }
    
    return reordered;
  }
}

/// Series-specific utilities
class SharedSeriesUtils {
  /// Create a duplicate of a series with new ID
  static Series duplicateSeries(Series series, {String? newId}) {
    return series.copyWith(
      id: newId ?? ModelUtils.generateId(),
      isCompleted: false,
      done: false,
      repsDone: 0,
      weightDone: 0.0,
    );
  }
  
  /// Reset series completion status
  static Series resetSeries(Series series) {
    return series.copyWith(
      isCompleted: false,
      done: false,
      repsDone: 0,
      weightDone: 0.0,
    );
  }
  
  /// Calculate volume for a series
  static double calculateSeriesVolume(Series series) {
    final weight = series.weightDone > 0 ? series.weightDone : series.weight;
    final reps = series.repsDone > 0 ? series.repsDone : series.reps;
    return weight * reps;
  }
  
  /// Check if series is completed
  static bool isSeriesCompleted(Series series) {
    return series.isCompleted && series.done;
  }
  
  /// Get series performance ratio (executed vs target)
  static Map<String, double> getPerformanceRatio(Series series) {
    final targetReps = series.reps;
    final targetWeight = series.weight;
    final executedReps = series.repsDone;
    final executedWeight = series.weightDone;
    
    return {
      'repsRatio': targetReps > 0 ? executedReps / targetReps : 0.0,
      'weightRatio': targetWeight > 0 ? executedWeight / targetWeight : 0.0,
      'volumeRatio': calculateSeriesVolume(Series(
        exerciseId: '',
        order: 0,
        reps: targetReps,
        weight: targetWeight,
      )) > 0 ? calculateSeriesVolume(series) / calculateSeriesVolume(Series(
        exerciseId: '',
        order: 0,
        reps: targetReps,
        weight: targetWeight,
      )) : 0.0,
    };
  }
}

/// Workout-specific utilities
class WorkoutUtils {
  /// Create a duplicate of a workout with new ID
  static Workout duplicateWorkout(Workout workout, {String? newId, String? newName}) {
    return workout.copyWith(
      id: newId ?? ModelUtils.generateId(),
      name: newName ?? '${workout.name} (Copy)',
      exercises: workout.exercises.map((e) => ExerciseUtils.duplicateExercise(e)).toList(),
    );
  }
  
  /// Reset workout completion status
  static Workout resetWorkout(Workout workout) {
    return workout.copyWith(
      exercises: workout.exercises.map((e) => ExerciseUtils.resetExercise(e)).toList(),
    );
  }
  
  /// Calculate total volume for workout
  static double calculateWorkoutVolume(Workout workout) {
    return workout.exercises.fold(0.0, (total, exercise) => 
        total + ExerciseUtils.calculateVolume(exercise));
  }
  
  /// Calculate completion percentage
  static double calculateWorkoutCompletionPercentage(Workout workout) {
    if (workout.exercises.isEmpty) return 0.0;
    final completedExercises = workout.exercises.where((e) => e.isCompleted).length;
    return (completedExercises / workout.exercises.length) * 100;
  }
  
  /// Get workout summary
  static Map<String, dynamic> getWorkoutSummary(Workout workout) {
    final totalSeries = workout.exercises.fold(0, (total, exercise) => 
        total + exercise.series.length);
    final completedSeries = workout.exercises.fold(0, (total, exercise) => 
        total + exercise.series.where((s) => s.isCompleted).length);
    
    return {
      'totalExercises': workout.exercises.length,
      'completedExercises': workout.exercises.where((e) => e.isCompleted).length,
      'totalSeries': totalSeries,
      'completedSeries': completedSeries,
      'totalVolume': calculateWorkoutVolume(workout),
      'completionPercentage': calculateWorkoutCompletionPercentage(workout),
      'isCompleted': workout.isCompleted,
      'estimatedDuration': workout.estimatedDuration,
    };
  }
  
  /// Reorder exercises in workout
  static Workout reorderWorkoutExercises(Workout workout, int oldIndex, int newIndex) {
    final reorderedExercises = ExerciseUtils.reorderExercises(
        workout.exercises, oldIndex, newIndex);
    return workout.copyWith(exercises: reorderedExercises);
  }
}

/// Week-specific utilities
class WeekUtils {
  /// Create a duplicate of a week with new ID
  static Week duplicateWeek(Week week, {String? newId, int? newNumber}) {
    return week.copyWith(
      id: newId ?? ModelUtils.generateId(),
      number: newNumber ?? week.number,
      workouts: week.workouts.map((w) => WorkoutUtils.duplicateWorkout(w)).toList(),
    );
  }
  
  /// Reset week completion status
  static Week resetWeek(Week week) {
    return week.copyWith(
      workouts: week.workouts.map((w) => WorkoutUtils.resetWorkout(w)).toList(),
    );
  }
  
  /// Calculate total volume for week
  static double calculateWeekVolume(Week week) {
    return week.workouts.fold(0.0, (total, workout) => 
        total + WorkoutUtils.calculateWorkoutVolume(workout));
  }
  
  /// Calculate completion percentage
  static double calculateWeekCompletionPercentage(Week week) {
    if (week.workouts.isEmpty) return 0.0;
    final completedWorkouts = week.workouts.where((w) => w.isCompleted).length;
    return (completedWorkouts / week.workouts.length) * 100;
  }
  
  /// Get week summary
  static Map<String, dynamic> getWeekSummary(Week week) {
    final totalExercises = week.workouts.fold(0, (total, workout) => 
        total + workout.exercises.length);
    final completedExercises = week.workouts.fold(0, (total, workout) => 
        total + workout.exercises.where((e) => e.isCompleted).length);
    
    return {
      'totalWorkouts': week.workouts.length,
      'completedWorkouts': week.workouts.where((w) => w.isCompleted).length,
      'totalExercises': totalExercises,
      'completedExercises': completedExercises,
      'totalVolume': calculateWeekVolume(week),
      'completionPercentage': calculateWeekCompletionPercentage(week),
      'isCompleted': week.isCompleted,
      'isActive': week.isActive,
      'weekNumber': week.number,
    };
  }
  
  /// Reorder workouts in week
  static Week reorderWeekWorkouts(Week week, int oldIndex, int newIndex) {
    final reordered = List<Workout>.from(week.workouts);
    final workout = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, workout.copyWith(order: newIndex));
    
    // Update order for all workouts
    for (int i = 0; i < reordered.length; i++) {
      reordered[i] = reordered[i].copyWith(order: i);
    }
    
    return week.copyWith(workouts: reordered);
  }
}

/// Firestore helper utilities
class FirestoreUtils {
  /// Convert model to Firestore data
  static Map<String, dynamic> toFirestoreData(dynamic model) {
    if (model is Exercise) return model.toFirestore();
    if (model is Series) return model.toFirestore();
    if (model is Workout) return model.toFirestore();
    if (model is Week) return model.toFirestore();
    throw ArgumentError('Unsupported model type: ${model.runtimeType}');
  }
  
  /// Create model from Firestore data
  static T fromFirestoreData<T>(Map<String, dynamic> data, String id) {
    switch (T) {
      case Exercise _:
        return Exercise.fromMap(data, id) as T;
      case Series _:
        return Series.fromMap(data, id) as T;
      case Workout _:
        return Workout.fromMap(data, id) as T;
      case Week _:
        return Week.fromMap(data, id) as T;
      default:
        throw ArgumentError('Unsupported model type: $T');
    }
  }
  
  /// Batch write operations
  static Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = FirebaseFirestore.instance.batch();
    
    for (final operation in operations) {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final docId = operation['docId'] as String;
      final data = operation['data'] as Map<String, dynamic>?;
      
      final docRef = FirebaseFirestore.instance.collection(collection).doc(docId);
      
      switch (type) {
        case 'set':
          batch.set(docRef, data!);
          break;
        case 'update':
          batch.update(docRef, data!);
          break;
        case 'delete':
          batch.delete(docRef);
          break;
      }
    }
    
    await batch.commit();
  }
  
  /// Create Firestore query with common filters
  static Query<Map<String, dynamic>> createQuery(
    String collection, {
    String? orderBy,
    bool descending = false,
    int? limit,
    Map<String, dynamic>? where,
    dynamic startAfter,
  }) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(collection);
    
    // Apply where clauses
    if (where != null) {
      for (final entry in where.entries) {
        if (entry.value is List && (entry.value as List).length == 2) {
          final operator = (entry.value as List)[0] as String;
          final value = (entry.value as List)[1];
          query = query.where(entry.key, isEqualTo: operator == '==' ? value : null,
                             isGreaterThan: operator == '>' ? value : null,
                             isLessThan: operator == '<' ? value : null,
                             isGreaterThanOrEqualTo: operator == '>=' ? value : null,
                             isLessThanOrEqualTo: operator == '<=' ? value : null,
                             arrayContains: operator == 'array-contains' ? value : null);
        } else {
          query = query.where(entry.key, isEqualTo: entry.value);
        }
      }
    }
    
    // Apply ordering
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    // Apply pagination
    if (startAfter != null) {
      query = query.startAfter([startAfter]);
    }
    
    // Apply limit
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query;
  }
}