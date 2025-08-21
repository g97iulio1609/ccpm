import 'dart:async';
import 'package:alphanessone/Viewer/services/training_program_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/Viewer/UI/workout_provider.dart';
import 'package:logging/logging.dart';
import 'package:alphanessone/shared/services/exercise_notes_service.dart';
import 'package:alphanessone/shared/services/series_completion_utils.dart';
import 'package:alphanessone/shared/services/workout_editor_service.dart';
import 'package:alphanessone/shared/services/weight_calculation_service.dart';

class WorkoutService {
  final Ref ref;
  static final Logger _logger = Logger('WorkoutService');
  final TrainingProgramServices trainingProgramServices;
  final ExerciseRecordService exerciseRecordService;
  final ExerciseNotesService _notesService = ExerciseNotesService();
  // Manteniamo il servizio pesi dentro WorkoutEditorService per evitare duplicazioni
  late final WorkoutEditorService _workoutEditorService;

  final Map<String, ValueNotifier<double>> _weightNotifiers = {};
  final Map<String, StreamSubscription> _seriesSubscriptionsByExerciseId = {};
  final Map<String, Map<String?, List<Map<String, dynamic>>>> _groupedExercisesCache = {};
  final Map<String, List<Map<String, dynamic>>> _workoutCache = {};

  WorkoutService({
    required this.ref,
    required this.trainingProgramServices,
    required this.exerciseRecordService,
  }) {
    // Rimosso WeightCalculationService locale; è gestito dal servizio condiviso
    _workoutEditorService = WorkoutEditorService(exerciseRecordService: exerciseRecordService);
  }

  void dispose() {
    for (final sub in _seriesSubscriptionsByExerciseId.values) {
      sub.cancel();
    }
    _seriesSubscriptionsByExerciseId.clear();
  }

  Future<void> loadExerciseNotes(String workoutId) async {
    try {
      final notes = await _notesService.fetchNotesForWorkout(workoutId);
      ref.read(exerciseNotesProvider.notifier).state = notes;
    } catch (e, st) {
      _logger.warning('Failed to load exercise notes for workout $workoutId', e, st);
    }
  }

  Future<void> showNoteDialog(
    String exerciseId,
    String exerciseName,
    String workoutId,
    String note,
  ) async {
    await _notesService.saveNote(workoutId: workoutId, exerciseId: exerciseId, note: note);
    final currentNotes = Map<String, String>.from(ref.read(exerciseNotesProvider));
    currentNotes[exerciseId] = note;
    ref.read(exerciseNotesProvider.notifier).state = currentNotes;
  }

  Future<void> deleteNote(String exerciseId, String workoutId) async {
    try {
      await _notesService.deleteNote(workoutId: workoutId, exerciseId: exerciseId);
      final currentNotes = Map<String, String>.from(ref.read(exerciseNotesProvider));
      currentNotes.remove(exerciseId);
      ref.read(exerciseNotesProvider.notifier).state = currentNotes;
    } catch (e, st) {
      _logger.warning(
        'Failed to delete note for exercise $exerciseId in workout $workoutId',
        e,
        st,
      );
    }
  }

  Future<void> prefetchWorkout(String workoutId) async {
    // Se il workout è già in cache, non fare nulla
    if (_workoutCache.containsKey(workoutId)) return;

    try {
      // Fetch workout name and exercises in parallel
      final futures = await Future.wait([
        trainingProgramServices.fetchWorkoutName(workoutId),
        trainingProgramServices.fetchExercises(workoutId),
      ]);

      final workoutName = futures[0] as String;
      final exercises = futures[1] as List<Map<String, dynamic>>;

      // Salva nella cache
      _workoutCache[workoutId] = exercises;

      // Cache exercise data
      _cacheExerciseData(exercises);

      // Aggiorna la cache del nome del workout
      final workoutNames = Map<String, String>.from(ref.read(workoutNameCacheProvider));
      workoutNames[workoutId] = workoutName;
      ref.read(workoutNameCacheProvider.notifier).state = workoutNames;
    } catch (e, st) {
      _logger.warning('Failed prefetching workout $workoutId', e, st);
    }
  }

  Future<void> prefetchWeekWorkouts(List<String> workoutIds) async {
    for (final workoutId in workoutIds) {
      prefetchWorkout(workoutId);
    }
  }

  Future<void> initializeWorkout(String workoutId) async {
    ref.read(loadingProvider.notifier).state = true;
    ref.read(workoutIdProvider.notifier).state = workoutId;
    ref.read(exercisesProvider.notifier).state = []; // Reset exercises immediately

    try {
      // Check if workout is in cache
      if (_workoutCache.containsKey(workoutId)) {
        final exercises = _workoutCache[workoutId]!;
        final workoutName = ref.read(workoutNameCacheProvider)[workoutId] ?? '';

        ref.read(currentWorkoutNameProvider.notifier).state = workoutName;
        ref.read(exercisesProvider.notifier).state = exercises;
        return;
      }

      // If not in cache, fetch normally
      final futures = await Future.wait([
        trainingProgramServices.fetchWorkoutName(workoutId),
        trainingProgramServices.fetchExercises(workoutId),
      ]);

      final workoutName = futures[0] as String;
      final exercises = futures[1] as List<Map<String, dynamic>>;

      // Update providers with fetched data
      ref.read(currentWorkoutNameProvider.notifier).state = workoutName;
      ref.read(exercisesProvider.notifier).state = exercises;

      // Cache the data for future use
      _workoutCache[workoutId] = exercises;
      _cacheExerciseData(exercises);
    } catch (e) {
      _logger.severe('Error initializing workout', e);
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  void _cacheExerciseData(List<Map<String, dynamic>> exercises) {
    final exerciseCache = <String, List<Map<String, dynamic>>>{};

    for (final exercise in exercises) {
      final superSetId = exercise['superSetId'];
      if (superSetId != null) {
        exerciseCache.putIfAbsent(superSetId, () => []).add(exercise);
      }
    }

    _groupedExercisesCache.clear();
    _groupedExercisesCache[ref.read(workoutIdProvider) ?? ''] = exerciseCache;
  }

  Future<void> updateWorkoutName(String workoutId) async {
    final currentName = ref.read(currentWorkoutNameProvider);
    if (currentName != workoutId) {
      final cachedName = ref.read(workoutNameCacheProvider)[workoutId];
      if (cachedName != null) {
        ref.read(currentWorkoutNameProvider.notifier).state = cachedName;
        return;
      }

      final workoutName = await trainingProgramServices.fetchWorkoutName(workoutId);
      ref.read(currentWorkoutNameProvider.notifier).state = workoutName;

      final cache = Map<String, String>.from(ref.read(workoutNameCacheProvider));
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

      final cache = Map<String, List<Map<String, dynamic>>>.from(ref.read(exerciseCacheProvider));
      cache[workoutId] = exercises;
      ref.read(exerciseCacheProvider.notifier).state = cache;

      for (final exercise in exercises) {
        subscribeToSeriesUpdates(exercise, workoutId);
      }
    } catch (e, st) {
      _logger.severe('Error fetching exercises for workout $workoutId', e, st);
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  void subscribeToSeriesUpdates(Map<String, dynamic> exercise, String workoutId) {
    final exerciseId = exercise['id'] as String?;
    if (exerciseId == null || exerciseId.isEmpty) return;
    // Annulla eventuale subscription precedente per questo esercizio
    _seriesSubscriptionsByExerciseId[exerciseId]?.cancel();

    final seriesQuery = FirebaseFirestore.instance
        .collection('series')
        .where('exerciseId', isEqualTo: exercise['id'])
        .orderBy('order');

    final subscription = seriesQuery.snapshots().listen((querySnapshot) {
      final updatedExercises = ref.read(exercisesProvider);
      final index = updatedExercises.indexWhere((e) => e['id'] == exerciseId);
      if (index != -1) {
        final newExercises = List<Map<String, dynamic>>.from(updatedExercises);
        newExercises[index] = Map<String, dynamic>.from(newExercises[index]);
        newExercises[index]['series'] = querySnapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();

        ref.read(exercisesProvider.notifier).state = newExercises;

        final cache = Map<String, List<Map<String, dynamic>>>.from(ref.read(exerciseCacheProvider));
        cache[workoutId] = newExercises;
        ref.read(exerciseCacheProvider.notifier).state = cache;
      }
    });

    _seriesSubscriptionsByExerciseId[exerciseId] = subscription;
  }

  Future<void> updateExercise(
    Map<String, dynamic> currentExercise,
    Exercise newExercise, {
    String? targetUserId,
  }) async {
    // Prepara la mappa aggiornata indipendentemente dallo stato dei provider
    final Map<String, dynamic> updatedExerciseMap = {
      ...currentExercise,
      'name': newExercise.name,
      'exerciseId': newExercise.exerciseId ?? '',
      'type': newExercise.type,
      'variant': newExercise.variant,
    };

    // Usa servizio condiviso per allineare la logica con TrainingBuilder
    final String effectiveTargetUserId = (targetUserId?.isNotEmpty ?? false)
        ? targetUserId!
        : (ref.read(targetUserIdProvider).isNotEmpty
              ? ref.read(targetUserIdProvider)
              : (ref.read(userIdProvider) ?? ''));

    await _workoutEditorService.changeExercise(
      currentExercise: currentExercise,
      newExercise: newExercise,
      targetUserId: effectiveTargetUserId,
    );

    // Ricalcolo pesi già gestito dal servizio condiviso

    // Aggiorna lo stato locale solo se presente (back-compat)
    final exercisesState = ref.read(exercisesProvider);
    if (exercisesState.isNotEmpty) {
      final exerciseIndex = exercisesState.indexWhere((e) => e['id'] == currentExercise['id']);
      if (exerciseIndex != -1) {
        final updatedExercises = List<Map<String, dynamic>>.from(exercisesState);
        updatedExercises[exerciseIndex] = updatedExerciseMap;
        ref.read(exercisesProvider.notifier).state = updatedExercises;
      }
    }
  }

  Future<void> applySeriesChanges(Map<String, dynamic> exercise, List<Series> newSeriesList) async {
    // Usa servizio condiviso per allineare la logica con TrainingBuilder
    final editor = WorkoutEditorService(exerciseRecordService: exerciseRecordService);

    final updatedResult = await editor.applySeriesChanges(
      exercise: exercise,
      newSeriesList: newSeriesList,
    );

    // Aggiorna lo stato locale
    final exercises = ref.read(exercisesProvider);
    final index = exercises.indexWhere((e) => e['id'] == exercise['id']);
    if (index == -1) return;

    final updatedExercises = List<Map<String, dynamic>>.from(exercises);
    updatedExercises[index] = {
      ...updatedExercises[index],
      'series': updatedResult.map((s) => s.toMap()).toList(),
    };
    ref.read(exercisesProvider.notifier).state = updatedExercises;
  }

  bool isSeriesDone(Map<String, dynamic> seriesData) => SeriesCompletionUtils.isDoneMap(seriesData);

  Future<void> toggleSeriesDone(Map<String, dynamic> series) async {
    final seriesId = series['id'].toString();
    final currentlyDone = isSeriesDone(series);
    final reps = series['reps'] ?? 0;
    final maxReps = series['maxReps'];
    final weight = (series['weight'] ?? 0.0).toDouble();
    final maxWeight = series['maxWeight']?.toDouble();

    if (!currentlyDone &&
        (series['reps_done'] == null || series['reps_done'] == 0) &&
        (series['weight_done'] == null || series['weight_done'] == 0.0)) {
      await trainingProgramServices.updateSeriesWithMaxValues(
        seriesId,
        reps,
        maxReps,
        weight,
        maxWeight,
        maxReps ?? reps,
        maxWeight ?? weight,
      );

      final exercises = List<Map<String, dynamic>>.from(ref.read(exercisesProvider));
      for (int i = 0; i < exercises.length; i++) {
        final seriesList = List<Map<String, dynamic>>.from(exercises[i]['series'] ?? []);
        for (int j = 0; j < seriesList.length; j++) {
          if (seriesList[j]['id'] == seriesId) {
            seriesList[j] = {
              ...seriesList[j],
              'reps_done': maxReps ?? reps,
              'weight_done': maxWeight ?? weight,
            };
            exercises[i] = {...exercises[i], 'series': seriesList};
            break;
          }
        }
      }
      ref.read(exercisesProvider.notifier).state = exercises;
    } else if (currentlyDone) {
      await trainingProgramServices.updateSeriesWithMaxValues(
        seriesId,
        reps,
        maxReps,
        weight,
        maxWeight,
        0,
        0.0,
      );

      final exercises = List<Map<String, dynamic>>.from(ref.read(exercisesProvider));
      for (int i = 0; i < exercises.length; i++) {
        final seriesList = List<Map<String, dynamic>>.from(exercises[i]['series'] ?? []);
        for (int j = 0; j < seriesList.length; j++) {
          if (seriesList[j]['id'] == seriesId) {
            seriesList[j] = {...seriesList[j], 'reps_done': 0, 'weight_done': 0.0};
            exercises[i] = {...exercises[i], 'series': seriesList};
            break;
          }
        }
      }
      ref.read(exercisesProvider.notifier).state = exercises;
    }
  }

  int findFirstNotDoneSeriesIndex(List<Map<String, dynamic>> seriesList) {
    return seriesList.indexWhere((serie) => !isSeriesDone(serie));
  }

  Map<String?, List<Map<String, dynamic>>> groupExercisesBySuperSet(
    List<Map<String, dynamic>> exercises,
  ) {
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
    bool keepCurrentWeights = false,
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

    // Allinea calcolo/arrotondamento pesi con servizio condiviso
    final String exerciseType = (exercise['type'] as String?) ?? 'weight';
    if (!keepCurrentWeights) {
      for (var serie in series) {
        final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;

        if (seriesMap['intensity'] != null) {
          final double intensity = double.tryParse(seriesMap['intensity'].toString()) ?? 0.0;
          final double calculated = WeightCalculationService.calculateWeightFromIntensity(
            newMaxWeight.toDouble(),
            intensity,
          );
          seriesMap['weight'] = WeightCalculationService.roundWeight(calculated, exerciseType);
        }

        if (seriesMap['maxIntensity'] != null) {
          final double maxIntensity = double.tryParse(seriesMap['maxIntensity'].toString()) ?? 0.0;
          final double calculated = WeightCalculationService.calculateWeightFromIntensity(
            newMaxWeight.toDouble(),
            maxIntensity,
          );
          seriesMap['maxWeight'] = WeightCalculationService.roundWeight(calculated, exerciseType);
        }
      }
    } else {
      for (var serie in series) {
        final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;

        if (seriesMap['weight'] != null) {
          final double currentWeight = double.tryParse(seriesMap['weight'].toString()) ?? 0.0;
          final double intensity = WeightCalculationService.calculateIntensityFromWeight(
            currentWeight,
            newMaxWeight.toDouble(),
          );
          seriesMap['intensity'] = intensity;
        }

        if (seriesMap['maxWeight'] != null) {
          final double currentMaxWeight = double.tryParse(seriesMap['maxWeight'].toString()) ?? 0.0;
          final double maxIntensity = WeightCalculationService.calculateIntensityFromWeight(
            currentMaxWeight,
            newMaxWeight.toDouble(),
          );
          seriesMap['maxIntensity'] = maxIntensity;
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

  Future<void> updateSeriesData(String exerciseId, Map<String, dynamic> seriesData) async {
    final seriesId = seriesData['id'];
    if (seriesId == null) return;

    // Update Firestore
    final seriesRef = FirebaseFirestore.instance.collection('series').doc(seriesId);
    await seriesRef.update({
      'reps_done': seriesData['reps_done'],
      'weight_done': seriesData['weight_done'],
    });

    // Update local state
    final exercises = List<Map<String, dynamic>>.from(ref.read(exercisesProvider));
    bool updated = false;

    for (int i = 0; i < exercises.length && !updated; i++) {
      final seriesList = List<Map<String, dynamic>>.from(exercises[i]['series'] ?? []);
      for (int j = 0; j < seriesList.length && !updated; j++) {
        if (seriesList[j]['id'] == seriesId) {
          seriesList[j] = {
            ...seriesList[j],
            'reps_done': seriesData['reps_done'],
            'weight_done': seriesData['weight_done'],
          };
          exercises[i] = {...exercises[i], 'series': seriesList};
          updated = true;
        }
      }
    }

    if (updated) {
      ref.read(exercisesProvider.notifier).state = exercises;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
