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
    final originalExerciseId = series.isNotEmpty
        ? (series.first as Map<String, dynamic>)['originalExerciseId'] ??
            newExerciseId
        : newExerciseId;

    final recordsStream = exerciseRecordService
        .getExerciseRecords(
          userId: ref.read(userIdProvider) ?? '',
          exerciseId: originalExerciseId,
        )
        .map((records) => records.isNotEmpty
            ? records.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
            : null);

    final latestRecord = await recordsStream.first;

    num latestMaxWeight = 0.0;
    if (latestRecord != null) {
      latestMaxWeight = latestRecord.maxWeight;
    }

    _weightNotifiers[exercise['id']] ??= ValueNotifier(0.0);
    // Questo metodo veniva chiamato per mostrare un dialog (SeriesDialog) 
    // nella UI, non lo spostiamo qui perché la UI deve mostrare il dialog.
    // Qui lasciamo la logica di calcolo, ma la visualizzazione resta in UI.
  }

  Future<void> applySeriesChanges(
      Map<String, dynamic> exercise, List<Series> newSeriesList) async {
    // Ottieni le serie originali
    final exercises = ref.read(exercisesProvider);
    final index = exercises.indexWhere((e) => e['id'] == exercise['id']);
    if (index == -1) return;

    final oldSeries = (exercises[index]['series'] as List)
        .map((s) => Series.fromMap(s as Map<String, dynamic>))
        .toList();

    final batch = FirebaseFirestore.instance.batch();

    // Se stiamo riducendo il numero di serie, eliminiamo quelle in eccesso
    if (newSeriesList.length < oldSeries.length) {
      for (var i = newSeriesList.length; i < oldSeries.length; i++) {
        final seriesRef = FirebaseFirestore.instance
            .collection('series')
            .doc(oldSeries[i].id);
        batch.delete(seriesRef);
      }
    }

    // Aggiorna o crea le serie rimanenti
    final updatedResult = <Series>[];
    for (var series in newSeriesList) {
      if (series.id != null) {
        // Update existing series
        final seriesRef = FirebaseFirestore.instance
            .collection('series')
            .doc(series.id);
        batch.update(seriesRef, series.toMap());
        updatedResult.add(series);
      } else {
        // Create new series
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
      // Gestione errore mostrata nella UI al chiamante
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
    print('DEBUG: Starting updateMaxWeight');
    print('DEBUG: targetUserId: $targetUserId');
    print('DEBUG: newMaxWeight: $newMaxWeight');
    print('DEBUG: repetitions: $repetitions');
    print('DEBUG: keepCurrentWeights: $keepCurrentWeights');
    print('DEBUG: exercise: $exercise');

    // Get originalExerciseId from the first series
    final series = exercise['series'] as List<dynamic>;
    final firstSeries = series.first as Map<String, dynamic>;
    final exerciseId = firstSeries['originalExerciseId'] as String?;
    final exerciseName = exercise['name'] as String?;

    print('DEBUG: exerciseId (original from series): $exerciseId');
    print('DEBUG: exerciseName: $exerciseName');

    if (targetUserId.isEmpty) {
      print('ERROR: Target User ID is empty');
      throw Exception('Target User ID is not set');
    }
    if (exerciseId == null || exerciseId.isEmpty) {
      print('ERROR: Exercise ID is missing or empty');
      throw Exception('Exercise ID is missing or empty');
    }
    if (exerciseName == null || exerciseName.isEmpty) {
      print('ERROR: Exercise name is missing or empty');
      throw Exception('Exercise name is missing or empty');
    }

    print('DEBUG: All validations passed, proceeding with update');

    // Add new record with updated max weight
    await exerciseRecordService.addExerciseRecord(
      userId: targetUserId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      maxWeight: newMaxWeight,
      repetitions: repetitions,
      date: DateTime.now().toIso8601String(),
    );

    print('DEBUG: Exercise record added, updating weight notifier');

    // Update the weight notifier
    _weightNotifiers[exerciseId]?.value = newMaxWeight.toDouble();

    print('DEBUG: Weight notifier updated');

    if (!keepCurrentWeights) {
      print('DEBUG: Recalculating series weights');
      // Recalculate weights for all series
      for (var serie in series) {
        final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;
        if (seriesMap['weight'] != null) {
          final double percentage = seriesMap['percentage'] ?? 100.0;
          seriesMap['weight'] = (newMaxWeight * percentage / 100).roundToDouble();
        }
      }
      print('DEBUG: Series weights recalculated');
    } else {
      print('DEBUG: Keeping current weights, updating intensities');
      // Update only the intensities based on the new max weight
      for (var serie in series) {
        final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;
        if (seriesMap['weight'] != null) {
          final double currentWeight = seriesMap['weight'] as double;
          seriesMap['percentage'] = ((currentWeight / newMaxWeight) * 100).roundToDouble();
        }
      }
      print('DEBUG: Series intensities updated');
    }

    print('DEBUG: Updating exercise in Firestore');
    // Update exercise in Firestore with the current exercise ID
    await trainingProgramServices.updateExercise(exercise['id'], exercise);

    print('DEBUG: Exercise updated in Firestore successfully');
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
