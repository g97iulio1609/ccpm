import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';
import '../models/series.dart';
import 'base_repository.dart';

/// Repository for Exercise operations
/// Consolidates exercise data access from both trainingBuilder and Viewer modules
class ExerciseRepository extends BaseRepository<Exercise>
    with RepositoryMixin<Exercise> {
  static const String collectionName = 'exercises';

  @override
  CollectionReference get collection =>
      FirebaseFirestore.instance.collection(collectionName);

  @override
  Exercise fromFirestore(DocumentSnapshot doc) {
    return Exercise.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(Exercise model) {
    validateModel(model);
    return model.toFirestore();
  }

  @override
  void validateModel(Exercise model) {
    if (model.name.isEmpty) {
      throw RepositoryException('Exercise name cannot be empty');
    }
    if (model.exerciseId?.isEmpty ?? true) {
      throw RepositoryException('Exercise ID cannot be empty');
    }
  }

  /// Get exercises by workout ID
  Future<List<Exercise>> getByWorkoutId(String workoutId) async {
    try {
      logOperation('getByWorkoutId', {'workoutId': workoutId});
      return await getWhere(field: 'workoutId', value: workoutId);
    } catch (e) {
      handleError('get exercises by workout ID', e);
    }
  }

  /// Get exercises by original exercise ID (for tracking variations)
  Future<List<Exercise>> getByOriginalExerciseId(
    String originalExerciseId,
  ) async {
    try {
      logOperation('getByOriginalExerciseId', {
        'originalExerciseId': originalExerciseId,
      });
      return await getWhere(
        field: 'originalExerciseId',
        value: originalExerciseId,
      );
    } catch (e) {
      handleError('get exercises by original exercise ID', e);
    }
  }

  /// Get exercises by type
  Future<List<Exercise>> getByType(String type) async {
    try {
      logOperation('getByType', {'type': type});
      return await getWhere(field: 'type', value: type);
    } catch (e) {
      handleError('get exercises by type', e);
    }
  }

  /// Get exercises in a superset
  Future<List<Exercise>> getBySuperSetId(String superSetId) async {
    try {
      logOperation('getBySuperSetId', {'superSetId': superSetId});
      return await getWhere(field: 'superSetId', value: superSetId);
    } catch (e) {
      handleError('get exercises by superset ID', e);
    }
  }

  /// Get exercises ordered by their position
  Future<List<Exercise>> getOrderedByWorkout(String workoutId) async {
    try {
      logOperation('getOrderedByWorkout', {'workoutId': workoutId});
      return await getWhere(
        field: 'workoutId',
        value: workoutId,
        queryBuilder: (query) => query.orderBy('order'),
      );
    } catch (e) {
      handleError('get ordered exercises by workout', e);
    }
  }

  /// Update exercise series
  Future<void> updateSeries(String exerciseId, List<Series> series) async {
    try {
      logOperation('updateSeries', {
        'exerciseId': exerciseId,
        'seriesCount': series.length,
      });

      await updateFields(exerciseId, {
        'series': series.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('update exercise series', e);
    }
  }

  /// Add series to exercise
  Future<void> addSeries(String exerciseId, Series series) async {
    try {
      logOperation('addSeries', {
        'exerciseId': exerciseId,
        'seriesOrder': series.order,
      });

      await updateFields(exerciseId, {
        'series': FieldValue.arrayUnion([series.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('add series to exercise', e);
    }
  }

  /// Remove series from exercise
  Future<void> removeSeries(String exerciseId, String seriesId) async {
    try {
      logOperation('removeSeries', {
        'exerciseId': exerciseId,
        'seriesId': seriesId,
      });

      // Get current exercise to find and remove the specific series
      final exercise = await getById(exerciseId);
      if (exercise != null) {
        final updatedSeries = exercise.series
            .where((s) => s.id != seriesId)
            .map((s) => s.toMap())
            .toList();

        await updateFields(exerciseId, {
          'series': updatedSeries,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      handleError('remove series from exercise', e);
    }
  }

  /// Update exercise completion status
  Future<void> updateCompletionStatus(
    String exerciseId,
    bool isCompleted,
  ) async {
    try {
      logOperation('updateCompletionStatus', {
        'exerciseId': exerciseId,
        'isCompleted': isCompleted,
      });

      await updateFields(exerciseId, {
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('update exercise completion status', e);
    }
  }

  /// Update exercise notes
  Future<void> updateNotes(String exerciseId, String notes) async {
    try {
      logOperation('updateNotes', {
        'exerciseId': exerciseId,
        'notesLength': notes.length,
      });

      await updateFields(exerciseId, {
        'note': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('update exercise notes', e);
    }
  }

  /// Duplicate exercise with new order
  Future<String> duplicateExercise(String exerciseId, int newOrder) async {
    try {
      logOperation('duplicateExercise', {
        'originalExerciseId': exerciseId,
        'newOrder': newOrder,
      });

      final originalExercise = await getById(exerciseId);
      if (originalExercise == null) {
        throw RepositoryException(
          'Exercise not found for duplication: $exerciseId',
        );
      }

      final duplicatedExercise = originalExercise.copyWith(
        id: null, // Will be auto-generated
        order: newOrder,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Reset series completion status
        series: originalExercise.series
            .map(
              (s) => s.copyWith(
                id: null,
                done: false,
                repsDone: 0,
                weightDone: 0.0,
              ),
            )
            .toList(),
      );

      return await create(duplicatedExercise);
    } catch (e) {
      handleError('duplicate exercise', e);
    }
  }

  /// Reorder exercises in a workout
  Future<void> reorderExercises(List<Exercise> exercises) async {
    try {
      logOperation('reorderExercises', {'exerciseCount': exercises.length});

      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        if (exercise.id != null) {
          batch.update(collection.doc(exercise.id), {
            'order': i,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      handleError('reorder exercises', e);
    }
  }

  /// Get exercise statistics
  Future<ExerciseStats> getExerciseStats(String originalExerciseId) async {
    try {
      logOperation('getExerciseStats', {
        'originalExerciseId': originalExerciseId,
      });

      final exercises = await getByOriginalExerciseId(originalExerciseId);

      if (exercises.isEmpty) {
        return ExerciseStats.empty();
      }

      int totalPerformances = 0;
      double maxWeight = 0.0;
      int totalSeries = 0;
      int completedSeries = 0;
      DateTime? lastPerformed;

      for (final exercise in exercises) {
        if (exercise.isCompleted) {
          totalPerformances++;
          if (exercise.updatedAt != null) {
            if (lastPerformed == null ||
                exercise.updatedAt!.isAfter(lastPerformed)) {
              lastPerformed = exercise.updatedAt;
            }
          }
        }

        for (final series in exercise.series) {
          totalSeries++;
          if (series.completionStatus) {
            completedSeries++;
            if (series.weightDone > maxWeight) {
              maxWeight = series.weightDone;
            }
          }
        }
      }

      return ExerciseStats(
        totalPerformances: totalPerformances,
        maxWeight: maxWeight,
        totalSeries: totalSeries,
        completedSeries: completedSeries,
        lastPerformed: lastPerformed,
        completionRate: totalSeries > 0
            ? (completedSeries / totalSeries) * 100
            : 0.0,
      );
    } catch (e) {
      handleError('get exercise statistics', e);
    }
  }

  /// Listen to exercises by workout ID
  Stream<List<Exercise>> listenByWorkoutId(String workoutId) {
    logOperation('listenByWorkoutId', {'workoutId': workoutId});
    return listenToWhere(
      field: 'workoutId',
      value: workoutId,
      queryBuilder: (query) => query.orderBy('order'),
    );
  }

  /// Listen to exercises by superset ID
  Stream<List<Exercise>> listenBySuperSetId(String superSetId) {
    logOperation('listenBySuperSetId', {'superSetId': superSetId});
    return listenToWhere(
      field: 'superSetId',
      value: superSetId,
      queryBuilder: (query) => query.orderBy('order'),
    );
  }
}

/// Exercise statistics data class
class ExerciseStats {
  final int totalPerformances;
  final double maxWeight;
  final int totalSeries;
  final int completedSeries;
  final DateTime? lastPerformed;
  final double completionRate;

  const ExerciseStats({
    required this.totalPerformances,
    required this.maxWeight,
    required this.totalSeries,
    required this.completedSeries,
    this.lastPerformed,
    required this.completionRate,
  });

  factory ExerciseStats.empty() {
    return const ExerciseStats(
      totalPerformances: 0,
      maxWeight: 0.0,
      totalSeries: 0,
      completedSeries: 0,
      completionRate: 0.0,
    );
  }

  @override
  String toString() {
    return 'ExerciseStats(performances: $totalPerformances, maxWeight: $maxWeight, completion: ${completionRate.toStringAsFixed(1)}%)';
  }
}

/// Cached version of ExerciseRepository for better performance
class CachedExerciseRepository extends CachedRepository<Exercise>
    with RepositoryMixin<Exercise> {
  final ExerciseRepository _baseRepository = ExerciseRepository();

  CachedExerciseRepository({super.cacheDuration});

  @override
  CollectionReference get collection => _baseRepository.collection;

  @override
  Exercise fromFirestore(DocumentSnapshot doc) =>
      _baseRepository.fromFirestore(doc);

  @override
  Map<String, dynamic> toFirestore(Exercise model) =>
      _baseRepository.toFirestore(model);

  @override
  void validateModel(Exercise model) => _baseRepository.validateModel(model);

  // Delegate methods to base repository
  Future<List<Exercise>> getByWorkoutId(String workoutId) =>
      _baseRepository.getByWorkoutId(workoutId);
  Future<List<Exercise>> getByOriginalExerciseId(String originalExerciseId) =>
      _baseRepository.getByOriginalExerciseId(originalExerciseId);
  Future<List<Exercise>> getByType(String type) =>
      _baseRepository.getByType(type);
  Future<List<Exercise>> getBySuperSetId(String superSetId) =>
      _baseRepository.getBySuperSetId(superSetId);
  Future<List<Exercise>> getOrderedByWorkout(String workoutId) =>
      _baseRepository.getOrderedByWorkout(workoutId);
  Future<void> updateSeries(String exerciseId, List<Series> series) =>
      _baseRepository.updateSeries(exerciseId, series);
  Future<void> addSeries(String exerciseId, Series series) =>
      _baseRepository.addSeries(exerciseId, series);
  Future<void> removeSeries(String exerciseId, String seriesId) =>
      _baseRepository.removeSeries(exerciseId, seriesId);
  Future<void> updateCompletionStatus(String exerciseId, bool isCompleted) =>
      _baseRepository.updateCompletionStatus(exerciseId, isCompleted);
  Future<void> updateNotes(String exerciseId, String notes) =>
      _baseRepository.updateNotes(exerciseId, notes);
  Future<String> duplicateExercise(String exerciseId, int newOrder) =>
      _baseRepository.duplicateExercise(exerciseId, newOrder);
  Future<void> reorderExercises(List<Exercise> exercises) =>
      _baseRepository.reorderExercises(exercises);
  Future<ExerciseStats> getExerciseStats(String originalExerciseId) =>
      _baseRepository.getExerciseStats(originalExerciseId);
  Stream<List<Exercise>> listenByWorkoutId(String workoutId) =>
      _baseRepository.listenByWorkoutId(workoutId);
  Stream<List<Exercise>> listenBySuperSetId(String superSetId) =>
      _baseRepository.listenBySuperSetId(superSetId);
}
