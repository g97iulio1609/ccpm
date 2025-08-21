import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import 'base_repository.dart';
import 'exercise_repository.dart';

/// Repository for Workout operations
/// Consolidates workout data access from both trainingBuilder and Viewer modules
class WorkoutRepository extends BaseRepository<Workout> with RepositoryMixin<Workout> {
  static const String collectionName = 'workouts';
  final ExerciseRepository _exerciseRepository = ExerciseRepository();

  @override
  CollectionReference get collection => FirebaseFirestore.instance.collection(collectionName);

  @override
  Workout fromFirestore(DocumentSnapshot doc) {
    return Workout.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(Workout model) {
    validateModel(model);
    return model.toFirestore();
  }

  @override
  void validateModel(Workout model) {
    if (model.name.isEmpty) {
      throw RepositoryException('Workout name cannot be empty');
    }
    if (model.order < 0) {
      throw RepositoryException('Workout order must be non-negative');
    }
  }

  /// Get workouts by week ID
  Future<List<Workout>> getByWeekId(String weekId) async {
    try {
      logOperation('getByWeekId', {'weekId': weekId});
      return await getWhere(
        field: 'weekId',
        value: weekId,
        queryBuilder: (query) => query.orderBy('order'),
      );
    } catch (e) {
      handleError('get workouts by week ID', e);
    }
  }

  /// Get completed workouts
  Future<List<Workout>> getCompleted() async {
    try {
      logOperation('getCompleted');
      return await getWhere(
        field: 'isCompleted',
        value: true,
        queryBuilder: (query) => query.orderBy('lastPerformed', descending: true),
      );
    } catch (e) {
      handleError('get completed workouts', e);
    }
  }

  /// Get workouts by completion status
  Future<List<Workout>> getByCompletionStatus(bool isCompleted) async {
    try {
      logOperation('getByCompletionStatus', {'isCompleted': isCompleted});
      return await getWhere(field: 'isCompleted', value: isCompleted);
    } catch (e) {
      handleError('get workouts by completion status', e);
    }
  }

  /// Get workouts ordered by their position in week
  Future<List<Workout>> getOrderedByWeek(String weekId) async {
    try {
      logOperation('getOrderedByWeek', {'weekId': weekId});
      return await getWhere(
        field: 'weekId',
        value: weekId,
        queryBuilder: (query) => query.orderBy('order'),
      );
    } catch (e) {
      handleError('get ordered workouts by week', e);
    }
  }

  /// Get workout with exercises populated
  Future<Workout?> getWithExercises(String workoutId) async {
    try {
      logOperation('getWithExercises', {'workoutId': workoutId});

      final workout = await getById(workoutId);
      if (workout == null) return null;

      final exercises = await _exerciseRepository.getOrderedByWorkout(workoutId);

      return workout.copyWith(exercises: exercises);
    } catch (e) {
      handleError('get workout with exercises', e);
    }
  }

  /// Update workout completion status
  Future<void> updateCompletionStatus(String workoutId, bool isCompleted) async {
    try {
      logOperation('updateCompletionStatus', {'workoutId': workoutId, 'isCompleted': isCompleted});

      final updateData = {'isCompleted': isCompleted, 'updatedAt': FieldValue.serverTimestamp()};

      if (isCompleted) {
        updateData['lastPerformed'] = FieldValue.serverTimestamp();
      }

      await updateFields(workoutId, updateData);
    } catch (e) {
      handleError('update workout completion status', e);
    }
  }

  /// Mark workout as completed
  Future<void> markAsCompleted(String workoutId) async {
    await updateCompletionStatus(workoutId, true);
  }

  /// Reset workout completion
  Future<void> resetCompletion(String workoutId) async {
    try {
      logOperation('resetCompletion', {'workoutId': workoutId});

      await updateFields(workoutId, {
        'isCompleted': false,
        'lastPerformed': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also reset all exercises in this workout
      final exercises = await _exerciseRepository.getByWorkoutId(workoutId);
      for (final exercise in exercises) {
        if (exercise.id != null) {
          await _exerciseRepository.updateCompletionStatus(exercise.id!, false);
        }
      }
    } catch (e) {
      handleError('reset workout completion', e);
    }
  }

  /// Update workout notes
  Future<void> updateNotes(String workoutId, String notes) async {
    try {
      logOperation('updateNotes', {'workoutId': workoutId, 'notesLength': notes.length});

      await updateFields(workoutId, {'notes': notes, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      handleError('update workout notes', e);
    }
  }

  /// Update estimated duration
  Future<void> updateEstimatedDuration(String workoutId, int durationMinutes) async {
    try {
      logOperation('updateEstimatedDuration', {
        'workoutId': workoutId,
        'durationMinutes': durationMinutes,
      });

      await updateFields(workoutId, {
        'estimatedDurationMinutes': durationMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('update workout estimated duration', e);
    }
  }

  /// Duplicate workout with new order
  Future<String> duplicateWorkout(String workoutId, int newOrder, {String? newWeekId}) async {
    try {
      logOperation('duplicateWorkout', {
        'originalWorkoutId': workoutId,
        'newOrder': newOrder,
        'newWeekId': newWeekId,
      });

      final originalWorkout = await getWithExercises(workoutId);
      if (originalWorkout == null) {
        throw RepositoryException('Workout not found for duplication: $workoutId');
      }

      // Create duplicated workout
      final duplicatedWorkout = originalWorkout.copyWith(
        id: null, // Will be auto-generated
        weekId: newWeekId ?? originalWorkout.weekId,
        order: newOrder,
        isCompleted: false,
        lastPerformed: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        exercises: [], // Will be added separately
      );

      final newWorkoutId = await create(duplicatedWorkout);

      // Duplicate exercises
      for (final exercise in originalWorkout.exercises) {
        final duplicatedExercise = exercise.copyWith(
          id: null,
          workoutId: newWorkoutId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          // Reset series completion status
          series: exercise.series
              .map(
                (s) => s.copyWith(
                  id: null,
                  done: false,
                  isCompleted: false,
                  repsDone: 0,
                  weightDone: 0.0,
                ),
              )
              .toList(),
        );

        await _exerciseRepository.create(duplicatedExercise);
      }

      return newWorkoutId;
    } catch (e) {
      handleError('duplicate workout', e);
    }
  }

  /// Reorder workouts in a week
  Future<void> reorderWorkouts(List<Workout> workouts) async {
    try {
      logOperation('reorderWorkouts', {'workoutCount': workouts.length});

      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < workouts.length; i++) {
        final workout = workouts[i];
        if (workout.id != null) {
          batch.update(collection.doc(workout.id), {
            'order': i,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      handleError('reorder workouts', e);
    }
  }

  /// Get workout statistics
  Future<WorkoutStats> getWorkoutStats(String workoutId) async {
    try {
      logOperation('getWorkoutStats', {'workoutId': workoutId});

      final workout = await getWithExercises(workoutId);
      if (workout == null) {
        return WorkoutStats.empty();
      }

      int totalExercises = workout.exercises.length;
      int completedExercises = workout.exercises.where((e) => e.isCompleted).length;
      int totalSeries = 0;
      int completedSeries = 0;
      double totalVolume = 0.0;

      for (final exercise in workout.exercises) {
        for (final series in exercise.series) {
          totalSeries++;
          if (series.completionStatus) {
            completedSeries++;
            totalVolume += series.weightDone * series.repsDone;
          }
        }
      }

      return WorkoutStats(
        totalExercises: totalExercises,
        completedExercises: completedExercises,
        totalSeries: totalSeries,
        completedSeries: completedSeries,
        totalVolume: totalVolume,
        exerciseCompletionRate: totalExercises > 0
            ? (completedExercises / totalExercises) * 100
            : 0.0,
        seriesCompletionRate: totalSeries > 0 ? (completedSeries / totalSeries) * 100 : 0.0,
        estimatedDuration: workout.estimatedDuration,
        lastPerformed: workout.lastPerformed,
      );
    } catch (e) {
      handleError('get workout statistics', e);
    }
  }

  /// Get workouts performed in date range
  Future<List<Workout>> getPerformedInDateRange(DateTime startDate, DateTime endDate) async {
    try {
      logOperation('getPerformedInDateRange', {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });

      return await getWhere(
        queryBuilder: (query) => query
            .where('isCompleted', isEqualTo: true)
            .where('lastPerformed', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('lastPerformed', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .orderBy('lastPerformed', descending: true),
      );
    } catch (e) {
      handleError('get workouts performed in date range', e);
    }
  }

  /// Delete workout and all its exercises
  Future<void> deleteWithExercises(String workoutId) async {
    try {
      logOperation('deleteWithExercises', {'workoutId': workoutId});

      // Delete all exercises first
      final exercises = await _exerciseRepository.getByWorkoutId(workoutId);
      for (final exercise in exercises) {
        if (exercise.id != null) {
          await _exerciseRepository.delete(exercise.id!);
        }
      }

      // Then delete the workout
      await delete(workoutId);
    } catch (e) {
      handleError('delete workout with exercises', e);
    }
  }

  /// Listen to workouts by week ID
  Stream<List<Workout>> listenByWeekId(String weekId) {
    logOperation('listenByWeekId', {'weekId': weekId});
    return listenToWhere(
      field: 'weekId',
      value: weekId,
      queryBuilder: (query) => query.orderBy('order'),
    );
  }

  /// Listen to workout with exercises
  Stream<Workout?> listenWithExercises(String workoutId) {
    logOperation('listenWithExercises', {'workoutId': workoutId});

    return listenById(workoutId).asyncMap((workout) async {
      if (workout == null) return null;

      final exercises = await _exerciseRepository.getOrderedByWorkout(workoutId);
      return workout.copyWith(exercises: exercises);
    });
  }
}

/// Workout statistics data class
class WorkoutStats {
  final int totalExercises;
  final int completedExercises;
  final int totalSeries;
  final int completedSeries;
  final double totalVolume;
  final double exerciseCompletionRate;
  final double seriesCompletionRate;
  final int estimatedDuration;
  final DateTime? lastPerformed;

  const WorkoutStats({
    required this.totalExercises,
    required this.completedExercises,
    required this.totalSeries,
    required this.completedSeries,
    required this.totalVolume,
    required this.exerciseCompletionRate,
    required this.seriesCompletionRate,
    required this.estimatedDuration,
    this.lastPerformed,
  });

  factory WorkoutStats.empty() {
    return const WorkoutStats(
      totalExercises: 0,
      completedExercises: 0,
      totalSeries: 0,
      completedSeries: 0,
      totalVolume: 0.0,
      exerciseCompletionRate: 0.0,
      seriesCompletionRate: 0.0,
      estimatedDuration: 0,
    );
  }

  @override
  String toString() {
    return 'WorkoutStats(exercises: $completedExercises/$totalExercises, series: $completedSeries/$totalSeries, volume: ${totalVolume.toStringAsFixed(1)}kg)';
  }
}

/// Cached version of WorkoutRepository for better performance
class CachedWorkoutRepository extends CachedRepository<Workout> with RepositoryMixin<Workout> {
  final WorkoutRepository _baseRepository = WorkoutRepository();

  CachedWorkoutRepository({super.cacheDuration});

  @override
  CollectionReference get collection => _baseRepository.collection;

  @override
  Workout fromFirestore(DocumentSnapshot doc) => _baseRepository.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Workout model) => _baseRepository.toFirestore(model);

  @override
  void validateModel(Workout model) => _baseRepository.validateModel(model);

  // Delegate methods to base repository
  Future<List<Workout>> getByWeekId(String weekId) => _baseRepository.getByWeekId(weekId);
  Future<List<Workout>> getCompleted() => _baseRepository.getCompleted();
  Future<List<Workout>> getByCompletionStatus(bool isCompleted) =>
      _baseRepository.getByCompletionStatus(isCompleted);
  Future<List<Workout>> getOrderedByWeek(String weekId) => _baseRepository.getOrderedByWeek(weekId);
  Future<Workout?> getWithExercises(String workoutId) =>
      _baseRepository.getWithExercises(workoutId);
  Future<void> updateCompletionStatus(String workoutId, bool isCompleted) =>
      _baseRepository.updateCompletionStatus(workoutId, isCompleted);
  Future<void> markAsCompleted(String workoutId) => _baseRepository.markAsCompleted(workoutId);
  Future<void> resetCompletion(String workoutId) => _baseRepository.resetCompletion(workoutId);
  Future<void> updateNotes(String workoutId, String notes) =>
      _baseRepository.updateNotes(workoutId, notes);
  Future<void> updateEstimatedDuration(String workoutId, int durationMinutes) =>
      _baseRepository.updateEstimatedDuration(workoutId, durationMinutes);
  Future<String> duplicateWorkout(String workoutId, int newOrder, {String? newWeekId}) =>
      _baseRepository.duplicateWorkout(workoutId, newOrder, newWeekId: newWeekId);
  Future<void> reorderWorkouts(List<Workout> workouts) => _baseRepository.reorderWorkouts(workouts);
  Future<WorkoutStats> getWorkoutStats(String workoutId) =>
      _baseRepository.getWorkoutStats(workoutId);
  Future<List<Workout>> getPerformedInDateRange(DateTime startDate, DateTime endDate) =>
      _baseRepository.getPerformedInDateRange(startDate, endDate);
  Future<void> deleteWithExercises(String workoutId) =>
      _baseRepository.deleteWithExercises(workoutId);
  Stream<List<Workout>> listenByWeekId(String weekId) => _baseRepository.listenByWeekId(weekId);
  Stream<Workout?> listenWithExercises(String workoutId) =>
      _baseRepository.listenWithExercises(workoutId);
}
