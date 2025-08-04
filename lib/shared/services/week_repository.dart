import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/week.dart';
import '../models/workout.dart';
import 'base_repository.dart';
import 'workout_repository.dart';

/// Repository for Week operations
/// Consolidates week data access from both trainingBuilder and Viewer modules
class WeekRepository extends BaseRepository<Week> with RepositoryMixin<Week> {
  static const String collectionName = 'weeks';
  final WorkoutRepository _workoutRepository = WorkoutRepository();
  
  @override
  CollectionReference get collection => FirebaseFirestore.instance.collection(collectionName);
  
  @override
  Week fromFirestore(DocumentSnapshot doc) {
    return Week.fromFirestore(doc);
  }
  
  @override
  Map<String, dynamic> toFirestore(Week model) {
    validateModel(model);
    return model.toFirestore();
  }
  
  @override
  void validateModel(Week model) {
    if (model.number <= 0) {
      throw RepositoryException('Week number must be positive');
    }
  }
  
  /// Get weeks by program ID
  Future<List<Week>> getByProgramId(String programId) async {
    try {
      logOperation('getByProgramId', {'programId': programId});
      return await getWhere(
        field: 'programId',
        value: programId,
        queryBuilder: (query) => query.orderBy('number'),
      );
    } catch (e) {
      handleError('get weeks by program ID', e);
    }
  }
  
  /// Get weeks by completion status
  Future<List<Week>> getByCompletionStatus(bool isCompleted) async {
    try {
      logOperation('getByCompletionStatus', {'isCompleted': isCompleted});
      return await getWhere(
        field: 'isCompleted',
        value: isCompleted,
        queryBuilder: (query) => query.orderBy('number'),
      );
    } catch (e) {
      handleError('get weeks by completion status', e);
    }
  }
  
  /// Get active weeks
  Future<List<Week>> getActive() async {
    try {
      logOperation('getActive');
      return await getWhere(
        field: 'isActive',
        value: true,
        queryBuilder: (query) => query.orderBy('number'),
      );
    } catch (e) {
      handleError('get active weeks', e);
    }
  }
  
  /// Get current week (active and within date range)
  Future<Week?> getCurrentWeek() async {
    try {
      logOperation('getCurrentWeek');
      final now = DateTime.now();
      
      final weeks = await getWhere(
        queryBuilder: (query) => query
            .where('isActive', isEqualTo: true)
            .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
            .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .limit(1),
      );
      
      return weeks.isNotEmpty ? weeks.first : null;
    } catch (e) {
      handleError('get current week', e);
    }
  }
  
  /// Get week with workouts populated
  Future<Week?> getWithWorkouts(String weekId) async {
    try {
      logOperation('getWithWorkouts', {'weekId': weekId});
      
      final week = await getById(weekId);
      if (week == null) return null;
      
      final workouts = await _workoutRepository.getOrderedByWeek(weekId);
      
      return week.copyWith(workouts: workouts);
    } catch (e) {
      handleError('get week with workouts', e);
    }
  }
  
  /// Get weeks in date range
  Future<List<Week>> getInDateRange(DateTime startDate, DateTime endDate) async {
    try {
      logOperation('getInDateRange', {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      
      return await getWhere(
        queryBuilder: (query) => query
            .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            .orderBy('startDate'),
      );
    } catch (e) {
      handleError('get weeks in date range', e);
    }
  }
  
  /// Update week completion status
  Future<void> updateCompletionStatus(String weekId, bool isCompleted) async {
    try {
      logOperation('updateCompletionStatus', {
        'weekId': weekId,
        'isCompleted': isCompleted,
      });
      
      await updateFields(weekId, {
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('update week completion status', e);
    }
  }
  
  /// Mark week as completed
  Future<void> markAsCompleted(String weekId) async {
    await updateCompletionStatus(weekId, true);
  }
  
  /// Reset week completion
  Future<void> resetCompletion(String weekId) async {
    try {
      logOperation('resetCompletion', {'weekId': weekId});
      
      await updateFields(weekId, {
        'isCompleted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Also reset all workouts in this week
      final workouts = await _workoutRepository.getByWeekId(weekId);
      for (final workout in workouts) {
        if (workout.id != null) {
          await _workoutRepository.resetCompletion(workout.id!);
        }
      }
    } catch (e) {
      handleError('reset week completion', e);
    }
  }
  
  /// Update week active status
  Future<void> updateActiveStatus(String weekId, bool isActive) async {
    try {
      logOperation('updateActiveStatus', {
        'weekId': weekId,
        'isActive': isActive,
      });
      
      await updateFields(weekId, {
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('update week active status', e);
    }
  }
  
  /// Set week as current (deactivate others and activate this one)
  Future<void> setAsCurrent(String weekId) async {
    try {
      logOperation('setAsCurrent', {'weekId': weekId});
      
      final batch = FirebaseFirestore.instance.batch();
      
      // Deactivate all other weeks
      final activeWeeks = await getActive();
      for (final week in activeWeeks) {
        if (week.id != null && week.id != weekId) {
          batch.update(
            collection.doc(week.id),
            {
              'isActive': false,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
      
      // Activate the target week
      batch.update(
        collection.doc(weekId),
        {
          'isActive': true,
          'startDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      await batch.commit();
    } catch (e) {
      handleError('set week as current', e);
    }
  }
  
  /// Update week notes
  Future<void> updateNotes(String weekId, String notes) async {
    try {
      logOperation('updateNotes', {
        'weekId': weekId,
        'notesLength': notes.length,
      });
      
      await updateFields(weekId, {
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('update week notes', e);
    }
  }
  
  /// Update week date range
  Future<void> updateDateRange(String weekId, DateTime startDate, DateTime endDate) async {
    try {
      logOperation('updateDateRange', {
        'weekId': weekId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      
      await updateFields(weekId, {
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      handleError('update week date range', e);
    }
  }
  
  /// Duplicate week with new number
  Future<String> duplicateWeek(String weekId, int newNumber, {String? newProgramId}) async {
    try {
      logOperation('duplicateWeek', {
        'originalWeekId': weekId,
        'newNumber': newNumber,
        'newProgramId': newProgramId,
      });
      
      final originalWeek = await getWithWorkouts(weekId);
      if (originalWeek == null) {
        throw RepositoryException('Week not found for duplication: $weekId');
      }
      
      // Create duplicated week
      final duplicatedWeek = originalWeek.copyWith(
        id: null, // Will be auto-generated
        programId: newProgramId ?? originalWeek.programId,
        number: newNumber,
        isCompleted: false,
        isActive: false,
        startDate: null,
        endDate: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        workouts: [], // Will be added separately
      );
      
      final newWeekId = await create(duplicatedWeek);
      
      // Duplicate workouts
      for (final workout in originalWeek.workouts) {
        if (workout.id != null) {
          await _workoutRepository.duplicateWorkout(
            workout.id!,
            workout.order,
            newWeekId: newWeekId,
          );
        }
      }
      
      return newWeekId;
    } catch (e) {
      handleError('duplicate week', e);
    }
  }
  
  /// Reorder weeks in a program
  Future<void> reorderWeeks(List<Week> weeks) async {
    try {
      logOperation('reorderWeeks', {
        'weekCount': weeks.length,
      });
      
      final batch = FirebaseFirestore.instance.batch();
      
      for (int i = 0; i < weeks.length; i++) {
        final week = weeks[i];
        if (week.id != null) {
          batch.update(
            collection.doc(week.id),
            {
              'number': i + 1,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      }
      
      await batch.commit();
    } catch (e) {
      handleError('reorder weeks', e);
    }
  }
  
  /// Get week statistics
  Future<WeekStats> getWeekStats(String weekId) async {
    try {
      logOperation('getWeekStats', {'weekId': weekId});
      
      final week = await getWithWorkouts(weekId);
      if (week == null) {
        return WeekStats.empty();
      }
      
      int totalWorkouts = week.workouts.length;
      int completedWorkouts = week.workouts.where((w) => w.isCompleted).length;
      int totalExercises = 0;
      int completedExercises = 0;
      int totalSeries = 0;
      int completedSeries = 0;
      double totalVolume = 0.0;
      int totalDuration = 0;
      
      for (final workout in week.workouts) {
        totalExercises += workout.totalExercises;
        completedExercises += workout.completedExercises;
        totalSeries += workout.totalSeries;
        totalDuration += workout.estimatedDuration;
        
        for (final exercise in workout.exercises) {
          for (final series in exercise.series) {
            if (series.completionStatus) {
              completedSeries++;
              totalVolume += series.weightDone * series.repsDone;
            }
          }
        }
      }
      
      return WeekStats(
        totalWorkouts: totalWorkouts,
        completedWorkouts: completedWorkouts,
        totalExercises: totalExercises,
        completedExercises: completedExercises,
        totalSeries: totalSeries,
        completedSeries: completedSeries,
        totalVolume: totalVolume,
        workoutCompletionRate: totalWorkouts > 0 ? (completedWorkouts / totalWorkouts) * 100 : 0.0,
        exerciseCompletionRate: totalExercises > 0 ? (completedExercises / totalExercises) * 100 : 0.0,
        seriesCompletionRate: totalSeries > 0 ? (completedSeries / totalSeries) * 100 : 0.0,
        estimatedTotalDuration: totalDuration,
        weekNumber: week.number,
        isActive: week.isActive,
        startDate: week.startDate,
        endDate: week.endDate,
      );
    } catch (e) {
      handleError('get week statistics', e);
    }
  }
  
  /// Get program statistics (all weeks)
  Future<ProgramStats> getProgramStats(String programId) async {
    try {
      logOperation('getProgramStats', {'programId': programId});
      
      final weeks = await getByProgramId(programId);
      
      if (weeks.isEmpty) {
        return ProgramStats.empty();
      }
      
      int totalWeeks = weeks.length;
      int completedWeeks = weeks.where((w) => w.isCompleted).length;
      int totalWorkouts = 0;
      int completedWorkouts = 0;
      double totalVolume = 0.0;
      int totalDuration = 0;
      Week? currentWeek;
      
      for (final week in weeks) {
        if (week.isActive) {
          currentWeek = week;
        }
        
        totalWorkouts += week.totalWorkouts;
        completedWorkouts += week.completedWorkouts;
        totalDuration += week.estimatedTotalDuration;
        
        // Get detailed stats for volume calculation
        final weekStats = await getWeekStats(week.id!);
        totalVolume += weekStats.totalVolume;
      }
      
      return ProgramStats(
        totalWeeks: totalWeeks,
        completedWeeks: completedWeeks,
        totalWorkouts: totalWorkouts,
        completedWorkouts: completedWorkouts,
        totalVolume: totalVolume,
        weekCompletionRate: totalWeeks > 0 ? (completedWeeks / totalWeeks) * 100 : 0.0,
        workoutCompletionRate: totalWorkouts > 0 ? (completedWorkouts / totalWorkouts) * 100 : 0.0,
        estimatedTotalDuration: totalDuration,
        currentWeekNumber: currentWeek?.number,
        programId: programId,
      );
    } catch (e) {
      handleError('get program statistics', e);
    }
  }
  
  /// Delete week and all its workouts
  Future<void> deleteWithWorkouts(String weekId) async {
    try {
      logOperation('deleteWithWorkouts', {'weekId': weekId});
      
      // Delete all workouts first
      final workouts = await _workoutRepository.getByWeekId(weekId);
      for (final workout in workouts) {
        if (workout.id != null) {
          await _workoutRepository.deleteWithExercises(workout.id!);
        }
      }
      
      // Then delete the week
      await delete(weekId);
    } catch (e) {
      handleError('delete week with workouts', e);
    }
  }
  
  /// Listen to weeks by program ID
  Stream<List<Week>> listenByProgramId(String programId) {
    logOperation('listenByProgramId', {'programId': programId});
    return listenToWhere(
      field: 'programId',
      value: programId,
      queryBuilder: (query) => query.orderBy('number'),
    );
  }
  
  /// Listen to current week
  Stream<Week?> listenToCurrent() {
    logOperation('listenToCurrent');
    return listenToWhere(
      field: 'isActive',
      value: true,
      queryBuilder: (query) => query.limit(1),
    ).map((weeks) => weeks.isNotEmpty ? weeks.first : null);
  }
  
  /// Listen to week with workouts
  Stream<Week?> listenWithWorkouts(String weekId) {
    logOperation('listenWithWorkouts', {'weekId': weekId});
    
    return listenById(weekId).asyncMap((week) async {
      if (week == null) return null;
      
      final workouts = await _workoutRepository.getOrderedByWeek(weekId);
      return week.copyWith(workouts: workouts);
    });
  }
}

/// Week statistics data class
class WeekStats {
  final int totalWorkouts;
  final int completedWorkouts;
  final int totalExercises;
  final int completedExercises;
  final int totalSeries;
  final int completedSeries;
  final double totalVolume;
  final double workoutCompletionRate;
  final double exerciseCompletionRate;
  final double seriesCompletionRate;
  final int estimatedTotalDuration;
  final int weekNumber;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  
  const WeekStats({
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.totalExercises,
    required this.completedExercises,
    required this.totalSeries,
    required this.completedSeries,
    required this.totalVolume,
    required this.workoutCompletionRate,
    required this.exerciseCompletionRate,
    required this.seriesCompletionRate,
    required this.estimatedTotalDuration,
    required this.weekNumber,
    required this.isActive,
    this.startDate,
    this.endDate,
  });
  
  factory WeekStats.empty() {
    return const WeekStats(
      totalWorkouts: 0,
      completedWorkouts: 0,
      totalExercises: 0,
      completedExercises: 0,
      totalSeries: 0,
      completedSeries: 0,
      totalVolume: 0.0,
      workoutCompletionRate: 0.0,
      exerciseCompletionRate: 0.0,
      seriesCompletionRate: 0.0,
      estimatedTotalDuration: 0,
      weekNumber: 0,
      isActive: false,
    );
  }
  
  @override
  String toString() {
    return 'WeekStats(week: $weekNumber, workouts: $completedWorkouts/$totalWorkouts, volume: ${totalVolume.toStringAsFixed(1)}kg)';
  }
}

/// Program statistics data class
class ProgramStats {
  final int totalWeeks;
  final int completedWeeks;
  final int totalWorkouts;
  final int completedWorkouts;
  final double totalVolume;
  final double weekCompletionRate;
  final double workoutCompletionRate;
  final int estimatedTotalDuration;
  final int? currentWeekNumber;
  final String programId;
  
  const ProgramStats({
    required this.totalWeeks,
    required this.completedWeeks,
    required this.totalWorkouts,
    required this.completedWorkouts,
    required this.totalVolume,
    required this.weekCompletionRate,
    required this.workoutCompletionRate,
    required this.estimatedTotalDuration,
    this.currentWeekNumber,
    required this.programId,
  });
  
  factory ProgramStats.empty() {
    return const ProgramStats(
      totalWeeks: 0,
      completedWeeks: 0,
      totalWorkouts: 0,
      completedWorkouts: 0,
      totalVolume: 0.0,
      weekCompletionRate: 0.0,
      workoutCompletionRate: 0.0,
      estimatedTotalDuration: 0,
      programId: '',
    );
  }
  
  @override
  String toString() {
    return 'ProgramStats(weeks: $completedWeeks/$totalWeeks, workouts: $completedWorkouts/$totalWorkouts, volume: ${totalVolume.toStringAsFixed(1)}kg)';
  }
}

/// Cached version of WeekRepository for better performance
class CachedWeekRepository extends CachedRepository<Week> with RepositoryMixin<Week> {
  final WeekRepository _baseRepository = WeekRepository();
  
  CachedWeekRepository({super.cacheDuration});
  
  @override
  CollectionReference get collection => _baseRepository.collection;
  
  @override
  Week fromFirestore(DocumentSnapshot doc) => _baseRepository.fromFirestore(doc);
  
  @override
  Map<String, dynamic> toFirestore(Week model) => _baseRepository.toFirestore(model);
  
  @override
  void validateModel(Week model) => _baseRepository.validateModel(model);
  
  // Delegate methods to base repository
  Future<List<Week>> getByProgramId(String programId) => _baseRepository.getByProgramId(programId);
  Future<List<Week>> getByCompletionStatus(bool isCompleted) => _baseRepository.getByCompletionStatus(isCompleted);
  Future<List<Week>> getActive() => _baseRepository.getActive();
  Future<Week?> getCurrentWeek() => _baseRepository.getCurrentWeek();
  Future<Week?> getWithWorkouts(String weekId) => _baseRepository.getWithWorkouts(weekId);
  Future<List<Week>> getInDateRange(DateTime startDate, DateTime endDate) => _baseRepository.getInDateRange(startDate, endDate);
  Future<void> updateCompletionStatus(String weekId, bool isCompleted) => _baseRepository.updateCompletionStatus(weekId, isCompleted);
  Future<void> markAsCompleted(String weekId) => _baseRepository.markAsCompleted(weekId);
  Future<void> resetCompletion(String weekId) => _baseRepository.resetCompletion(weekId);
  Future<void> updateActiveStatus(String weekId, bool isActive) => _baseRepository.updateActiveStatus(weekId, isActive);
  Future<void> setAsCurrent(String weekId) => _baseRepository.setAsCurrent(weekId);
  Future<void> updateNotes(String weekId, String notes) => _baseRepository.updateNotes(weekId, notes);
  Future<void> updateDateRange(String weekId, DateTime startDate, DateTime endDate) => _baseRepository.updateDateRange(weekId, startDate, endDate);
  Future<String> duplicateWeek(String weekId, int newNumber, {String? newProgramId}) => _baseRepository.duplicateWeek(weekId, newNumber, newProgramId: newProgramId);
  Future<void> reorderWeeks(List<Week> weeks) => _baseRepository.reorderWeeks(weeks);
  Future<WeekStats> getWeekStats(String weekId) => _baseRepository.getWeekStats(weekId);
  Future<ProgramStats> getProgramStats(String programId) => _baseRepository.getProgramStats(programId);
  Future<void> deleteWithWorkouts(String weekId) => _baseRepository.deleteWithWorkouts(weekId);
  Stream<List<Week>> listenByProgramId(String programId) => _baseRepository.listenByProgramId(programId);
  Stream<Week?> listenToCurrent() => _baseRepository.listenToCurrent();
  Stream<Week?> listenWithWorkouts(String weekId) => _baseRepository.listenWithWorkouts(weekId);
}