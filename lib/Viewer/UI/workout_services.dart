import 'dart:async';
import 'package:alphanessone/Viewer/services/training_program_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'workout_provider.dart';


class WorkoutService {
  final Ref ref;
  final TrainingProgramServices trainingProgramServices;
  final ExerciseRecordService exerciseRecordService;

  final Map<String, ValueNotifier<double>> _weightNotifiers = {};
  final List<StreamSubscription> _subscriptions = [];
  final Map<String, Map<String?, List<Map<String, dynamic>>>>
      _groupedExercisesCache = {};

  WorkoutService({
    required this.ref,
    required this.trainingProgramServices,
    required this.exerciseRecordService,
  });

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }

  Future<void> loadExerciseNotes(String workoutId) async {
    try {
      final notesSnapshot = await FirebaseFirestore.instance
          .collection('exercise_notes')
          .where('workoutId', isEqualTo: workoutId)
          .get();

      final notes = {
        for (var doc in notesSnapshot.docs)
          doc['exerciseId'] as String: doc['note'] as String
      };

      ref.read(exerciseNotesProvider.notifier).state = notes;
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> showNoteDialog(
      String exerciseId, String exerciseName, String workoutId, String note) async {
    final docRef = FirebaseFirestore.instance
        .collection('exercise_notes')
        .doc('${workoutId}_$exerciseId');

    await docRef.set({
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final currentNotes = Map<String, String>.from(ref.read(exerciseNotesProvider));
    currentNotes[exerciseId] = note;
    ref.read(exerciseNotesProvider.notifier).state = currentNotes;
  }

  Future<void> deleteNote(String exerciseId, String workoutId) async {
    try {
      await FirebaseFirestore.instance
          .collection('exercise_notes')
          .doc('${workoutId}_$exerciseId')
          .delete();

      final currentNotes = Map<String, String>.from(ref.read(exerciseNotesProvider));
      currentNotes.remove(exerciseId);
      ref.read(exerciseNotesProvider.notifier).state = currentNotes;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> initializeWorkout(String programId, String weekId, String workoutId) async {
    ref.read(workoutIdProvider.notifier).update((state) => workoutId);
    await updateWorkoutName(workoutId);
    await fetchExercises(workoutId);
    await loadExerciseNotes(workoutId);
  }

  Future<void> updateWorkoutName(String workoutId) async {
    final currentName = ref.read(currentWorkoutNameProvider);
    if (currentName != workoutId) {
      final cachedName = ref.read(workoutNameCacheProvider)[workoutId];
      if (cachedName != null) {
        ref.read(currentWorkoutNameProvider.notifier).state = cachedName;
        return;
      }

      final workoutName =
          await trainingProgramServices.fetchWorkoutName(workoutId);
      ref.read(currentWorkoutNameProvider.notifier).state = workoutName;

      final cache =
          Map<String, String>.from(ref.read(workoutNameCacheProvider));
      cache[workoutId] = workoutName;
      ref.read(workoutNameCacheProvider.notifier).state = cache;
    }
  }

  Future<void> fetchExercises(String workoutId) async {
    final cachedExercises = ref.read(exerciseCacheProvider)[workoutId];
    if (cachedExercises != null) {
      ref.read(exercisesProvider.notifier).state = cachedExercises;
      for (final exercise in cachedExercises) {
        subscribeToSeriesUpdates(exercise, workoutId);
      }
      return;
    }

    ref.read(loadingProvider.notifier).state = true;
    try {
      final exercises = await trainingProgramServices.fetchExercises(workoutId);
      ref.read(exercisesProvider.notifier).state = exercises;

      final cache =
          Map<String, List<Map<String, dynamic>>>.from(ref.read(exerciseCacheProvider));
      cache[workoutId] = exercises;
      ref.read(exerciseCacheProvider.notifier).state = cache;

      for (final exercise in exercises) {
        subscribeToSeriesUpdates(exercise, workoutId);
      }
    } catch (e) {
      // Handle error
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  void subscribeToSeriesUpdates(Map<String, dynamic> exercise, String workoutId) {
    _subscriptions.removeWhere((sub) {
      if (sub.hashCode.toString().contains(exercise['id'])) {
        sub.cancel();
        return true;
      }
      return false;
    });

    final seriesQuery = FirebaseFirestore.instance
        .collection('series')
        .where('exerciseId', isEqualTo: exercise['id'])
        .orderBy('order');

    final subscription = seriesQuery.snapshots().listen((querySnapshot) {
      final updatedExercises = ref.read(exercisesProvider);
      final index = updatedExercises.indexWhere((e) => e['id'] == exercise['id']);
      if (index != -1) {
        final newExercises = List<Map<String, dynamic>>.from(updatedExercises);
        newExercises[index] = Map<String, dynamic>.from(newExercises[index]);
        newExercises[index]['series'] = querySnapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();

        ref.read(exercisesProvider.notifier).state = newExercises;

        final cache = Map<String, List<Map<String, dynamic>>>.from(
            ref.read(exerciseCacheProvider));
        cache[workoutId] = newExercises;
        ref.read(exerciseCacheProvider.notifier).state = cache;
      }
    });

    _subscriptions.add(subscription);
  }

  Future<void> updateExercise(
      Map<String, dynamic> currentExercise, Exercise newExercise) async {
    final exercises = ref.read(exercisesProvider.notifier).state;
    final exerciseIndex = exercises.indexWhere((e) => e['id'] == currentExercise['id']);

    if (exerciseIndex != -1) {
      final updatedExercises = List<Map<String, dynamic>>.from(exercises);
      updatedExercises[exerciseIndex] = {
        ...updatedExercises[exerciseIndex],
        'name': newExercise.name,
        'exerciseId': newExercise.exerciseId ?? '',
        'type': newExercise.type,
        'variant': newExercise.variant,
      };

      ref.read(exercisesProvider.notifier).state = updatedExercises;

      await recalculateWeights(updatedExercises[exerciseIndex], newExercise.exerciseId ?? '');

      await trainingProgramServices.updateExercise(currentExercise['id'], updatedExercises[exerciseIndex]);
    }
  }

  Future<void> recalculateWeights(
      Map<String, dynamic> exercise, String newExerciseId) async {
    final series = exercise['series'] as List<dynamic>;
    final originalExerciseId = newExerciseId;

    final targetUserId = ref.read(targetUserIdProvider);
    
    final recordsStream = exerciseRecordService
        .getExerciseRecords(
          userId: targetUserId,
          exerciseId: originalExerciseId,
        )
        .map((records) {
          if (records.isEmpty) return null;
          final record = records.firstWhere(
            (record) => record.exerciseId == originalExerciseId,
            orElse: () => records.first,
          );
          return record;
        });

    final latestRecord = await recordsStream.first;
    num latestMaxWeight = latestRecord?.maxWeight ?? 0.0;

    _weightNotifiers[exercise['id']] ??= ValueNotifier(0.0);
    _weightNotifiers[exercise['id']]!.value = latestMaxWeight.toDouble();

    final batch = FirebaseFirestore.instance.batch();
    
    for (var serie in series) {
      final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;
      
      seriesMap['originalExerciseId'] = originalExerciseId;
      
      if (seriesMap['intensity'] != null) {
        final double intensity = double.parse(seriesMap['intensity'].toString());
        final double newWeight = (latestMaxWeight * intensity / 100).roundToDouble();
        seriesMap['weight'] = newWeight;
      }
      
      if (seriesMap['maxIntensity'] != null) {
        final double maxIntensity = double.parse(seriesMap['maxIntensity'].toString());
        final double newMaxWeight = (latestMaxWeight * maxIntensity / 100).roundToDouble();
        seriesMap['maxWeight'] = newMaxWeight;
      }

      final seriesId = seriesMap['id'];
      if (seriesId != null) {
        final seriesRef = FirebaseFirestore.instance.collection('series').doc(seriesId);
        final updateData = {
          'weight': seriesMap['weight'],
          'maxWeight': seriesMap['maxWeight'],
          'intensity': seriesMap['intensity'].toString(),
          'maxIntensity': seriesMap['maxIntensity']?.toString(),
          'originalExerciseId': originalExerciseId,
        };
        batch.update(seriesRef, updateData);
      }
    }

    await batch.commit();

    final exercises = ref.read(exercisesProvider);
    final index = exercises.indexWhere((e) => e['id'] == exercise['id']);
    if (index != -1) {
      final updatedExercises = List<Map<String, dynamic>>.from(exercises);
      updatedExercises[index] = {
        ...exercise,
        'series': series,
      };
      ref.read(exercisesProvider.notifier).state = updatedExercises;
    }
  }

  Future<void> applySeriesChanges(
      Map<String, dynamic> exercise, List<Series> newSeriesList) async {
    final exercises = ref.read(exercisesProvider);
    final index = exercises.indexWhere((e) => e['id'] == exercise['id']);
    if (index == -1) return;

    final oldSeries = (exercises[index]['series'] as List)
        .map((s) => Series.fromMap(s as Map<String, dynamic>))
        .toList();

    final batch = FirebaseFirestore.instance.batch();

    if (newSeriesList.length < oldSeries.length) {
      for (var i = newSeriesList.length; i < oldSeries.length; i++) {
        final seriesRef = FirebaseFirestore.instance
            .collection('series')
            .doc(oldSeries[i].id);
        batch.delete(seriesRef);
      }
    }

    final updatedResult = <Series>[];
    for (var series in newSeriesList) {
      if (series.id != null) {
        final seriesRef = FirebaseFirestore.instance
            .collection('series')
            .doc(series.id);
        batch.update(seriesRef, series.toMap());
        updatedResult.add(series);
      } else {
        final seriesRef = FirebaseFirestore.instance
            .collection('series')
            .doc();
        final newSeries = series.copyWith(
          id: seriesRef.id,
          serieId: seriesRef.id,
          exerciseId: exercise['id'],
        );
        final Map<String, dynamic> seriesData = newSeries.toMap();
        seriesData['exerciseId'] = exercise['id']; 
        batch.set(seriesRef, seriesData);
        updatedResult.add(newSeries);
      }
    }

    try {
      await batch.commit();

      final updatedExercises = List<Map<String, dynamic>>.from(ref.read(exercisesProvider));
      updatedExercises[index] = {
        ...updatedExercises[index],
        'series': updatedResult.map((s) {
          final map = s.toMap();
          map['exerciseId'] = exercise['id']; 
          return map;
        }).toList(),
      };
      ref.read(exercisesProvider.notifier).state = updatedExercises;

    } catch (e) {
      rethrow;
    }
  }

  bool isSeriesDone(Map<String, dynamic> seriesData) {
    final repsDone = seriesData['reps_done'] ?? 0;
    final weightDone = seriesData['weight_done'] ?? 0.0;
    final reps = seriesData['reps'] ?? 0;
    final maxReps = seriesData['maxReps'];
    final weight = seriesData['weight'] ?? 0.0;
    final maxWeight = seriesData['maxWeight'];

    bool repsCompleted = maxReps != null
        ? repsDone >= reps && (repsDone <= maxReps || repsDone > maxReps)
        : repsDone >= reps;

    bool weightCompleted = maxWeight != null
        ? weightDone >= weight &&
            (weightDone <= maxWeight || weightDone > maxWeight)
        : weightDone >= weight;

    return repsCompleted && weightCompleted;
  }

  Future<void> toggleSeriesDone(Map<String, dynamic> series) async {
    final seriesId = series['id'].toString();
    final currentlyDone = isSeriesDone(series);
    final reps = series['reps'] ?? 0;
    final maxReps = series['maxReps'];
    final weight = (series['weight'] ?? 0.0).toDouble();
    final maxWeight = series['maxWeight']?.toDouble();

    if (!currentlyDone) {
      await trainingProgramServices.updateSeriesWithMaxValues(
        seriesId,
        reps,
        maxReps,
        weight,
        maxWeight,
        maxReps ?? reps,
        maxWeight ?? weight,
      );
    } else {
      await trainingProgramServices.updateSeriesWithMaxValues(
        seriesId,
        reps,
        maxReps,
        weight,
        maxWeight,
        0,
        0.0,
      );
    }
  }

  int findFirstNotDoneSeriesIndex(List<Map<String, dynamic>> seriesList) {
    return seriesList.indexWhere((serie) => !isSeriesDone(serie));
  }

  Map<String?, List<Map<String, dynamic>>> groupExercisesBySuperSet(
      List<Map<String, dynamic>> exercises) {
    final cacheKey = exercises.map((e) => e['id']).join('_');
    if (_groupedExercisesCache.containsKey(cacheKey)) {
      return _groupedExercisesCache[cacheKey]!;
    }

    final groupedExercises = <String?, List<Map<String, dynamic>>>{};
    for (final exercise in exercises) {
      final superSetId = exercise['superSetId'];
      groupedExercises.putIfAbsent(superSetId, () => []).add(exercise);
    }

    _groupedExercisesCache[cacheKey] = groupedExercises;
    return groupedExercises;
  }

  ValueNotifier<double>? getWeightNotifier(String exerciseId) {
    return _weightNotifiers[exerciseId];
  }

  Future<void> updateMaxWeight(
      Map<String, dynamic> exercise,
      num newMaxWeight,
      String targetUserId, {
      int repetitions = 1,
      bool keepCurrentWeights = false
  }) async {
    final series = exercise['series'] as List<dynamic>;
    final originalExerciseId = exercise['series'].first['originalExerciseId'] as String?;
    final exerciseId = originalExerciseId;
    final exerciseName = exercise['name'] as String?;

    if (targetUserId.isEmpty) {
      throw Exception('Target User ID is not set');
    }
    if (exerciseId == null || exerciseId.isEmpty) {
      throw Exception('Exercise ID is missing or empty');
    }
    if (exerciseName == null || exerciseName.isEmpty) {
      throw Exception('Exercise name is missing or empty');
    }

    await exerciseRecordService.addExerciseRecord(
      userId: targetUserId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      maxWeight: newMaxWeight,
      repetitions: repetitions,
      date: DateTime.now().toIso8601String(),
    );

    _weightNotifiers[exerciseId]?.value = newMaxWeight.toDouble();

    if (!keepCurrentWeights) {
      for (var serie in series) {
        final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;
        
        if (seriesMap['intensity'] != null) {
          final double intensity = double.parse(seriesMap['intensity'].toString());
          seriesMap['weight'] = (newMaxWeight * intensity / 100).roundToDouble();
        }
        
        if (seriesMap['maxIntensity'] != null) {
          final double maxIntensity = double.parse(seriesMap['maxIntensity'].toString());
          seriesMap['maxWeight'] = (newMaxWeight * maxIntensity / 100).roundToDouble();
        }
      }
    } else {
      for (var serie in series) {
        final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;
        
        if (seriesMap['weight'] != null) {
          final double currentWeight = double.parse(seriesMap['weight'].toString());
          seriesMap['intensity'] = ((currentWeight / newMaxWeight) * 100).roundToDouble();
        }
        
        if (seriesMap['maxWeight'] != null) {
          final double currentMaxWeight = double.parse(seriesMap['maxWeight'].toString());
          seriesMap['maxIntensity'] = ((currentMaxWeight / newMaxWeight) * 100).roundToDouble();
        }
      }
    }

    final batch = FirebaseFirestore.instance.batch();
    
    for (var serie in series) {
      final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;
      final seriesId = seriesMap['id'];
      if (seriesId != null) {
        final seriesRef = FirebaseFirestore.instance.collection('series').doc(seriesId);
        batch.update(seriesRef, {
          'weight': seriesMap['weight'],
          'maxWeight': seriesMap['maxWeight'],
          'intensity': seriesMap['intensity'].toString(),
          'maxIntensity': seriesMap['maxIntensity']?.toString(),
        });
      }
    }
    
    await batch.commit();

    await trainingProgramServices.updateExercise(exercise['id'], exercise);
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
