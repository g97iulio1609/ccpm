import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/shared.dart';

class TrainingProgramService {
  final FirestoreService _service;

  TrainingProgramService(this._service);

  Future<TrainingProgram?> fetchTrainingProgram(String programId) async {
    try {
      return await _service.fetchTrainingProgram(programId);
    } catch (e) {
      return null;
    }
  }

  Future<void> addOrUpdateTrainingProgram(TrainingProgram program) async {
    try {
      await _service.addOrUpdateTrainingProgram(program);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeToDeleteItems(TrainingProgram program) async {
    try {
      await _service.removeToDeleteItems(program);
    } catch (e) {
      rethrow;
    }
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TrainingProgram>> streamTrainingPrograms() {
    return _db.collection('programs').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TrainingProgram.fromFirestore(doc))
          .toList();
    });
  }

  Future<String> addProgram(Map<String, dynamic> programData) async {
    try {
      DocumentReference ref = await _db.collection('programs').add(programData);
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProgram(
    String programId,
    Map<String, dynamic> programData,
  ) async {
    try {
      await _db.collection('programs').doc(programId).update(programData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeProgram(String programId) async {
    try {
      WriteBatch batch = _db.batch();

      QuerySnapshot weeksSnapshot = await _db
          .collection('weeks')
          .where('programId', isEqualTo: programId)
          .get();

      for (var weekDoc in weeksSnapshot.docs) {
        String weekId = weekDoc.id;
        await _removeRelatedWorkouts(batch, weekId);
        batch.delete(weekDoc.reference);
      }

      batch.delete(_db.collection('programs').doc(programId));

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _removeRelatedWorkouts(WriteBatch batch, String weekId) async {
    QuerySnapshot workoutsSnapshot = await _db
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .get();

    for (var workoutDoc in workoutsSnapshot.docs) {
      String workoutId = workoutDoc.id;
      await _removeRelatedExercises(batch, workoutId);
      batch.delete(workoutDoc.reference);
    }
  }

  Future<void> _removeRelatedExercises(
    WriteBatch batch,
    String workoutId,
  ) async {
    QuerySnapshot exercisesSnapshot = await _db
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .get();

    for (var exerciseDoc in exercisesSnapshot.docs) {
      String exerciseId = exerciseDoc.id;
      await _removeRelatedSeries(batch, exerciseId);
      batch.delete(exerciseDoc.reference);
    }
  }

  Future<void> _removeRelatedSeries(WriteBatch batch, String exerciseId) async {
    QuerySnapshot seriesSnapshot = await _db
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseId)
        .get();

    for (var seriesDoc in seriesSnapshot.docs) {
      batch.delete(seriesDoc.reference);
    }
  }

  Future<TrainingProgram> fetchTrainingProgram(String programId) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _db
          .collection('programs')
          .doc(programId)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw Exception('No training program found with ID: $programId');
      }

      Map<String, dynamic> data = doc.data()!;

      TrainingProgram program = TrainingProgram(
        id: doc.id,
        name: data['name'] as String? ?? '',
        hide: data['hide'] as bool? ?? false,
        description: data['description'] as String? ?? '',
        athleteId: data['athleteId'] as String? ?? '',
        status: data['status'] as String? ?? 'private',
        mesocycleNumber: data['mesocycleNumber'] as int? ?? 1,
      );

      program.weeks = await _fetchWeeks(programId);
      return program;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Week>> _fetchWeeks(String programId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> weeksSnapshot = await _db
          .collection('weeks')
          .where('programId', isEqualTo: programId)
          .orderBy('number')
          .get();

      List<Week> weeks = weeksSnapshot.docs
          .map((doc) => Week.fromFirestore(doc))
          .toList();

      List<Future<void>> fetchWorkoutsFutures = [];
      for (int i = 0; i < weeks.length; i++) {
        fetchWorkoutsFutures.add(
          _fetchWorkouts(weeks[i].id!).then((workouts) {
            weeks[i] = weeks[i].copyWith(workouts: workouts);
          }),
        );
      }
      await Future.wait(fetchWorkoutsFutures);

      return weeks;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Workout>> _fetchWorkouts(String weekId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> workoutsSnapshot = await _db
          .collection('workouts')
          .where('weekId', isEqualTo: weekId)
          .orderBy('order')
          .get();

      List<Workout> workouts = workoutsSnapshot.docs
          .map((doc) => Workout.fromFirestore(doc))
          .toList();

      List<Future<void>> fetchExercisesFutures = [];
      for (int i = 0; i < workouts.length; i++) {
        fetchExercisesFutures.add(
          _fetchExercises(workouts[i].id!).then((exercises) {
            workouts[i] = workouts[i].copyWith(exercises: exercises);
          }),
        );
      }
      await Future.wait(fetchExercisesFutures);

      return workouts;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Exercise>> _fetchExercises(String workoutId) async {
    QuerySnapshot exercisesSnapshot = await _db
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('order')
        .get();

    List<Exercise> exercises = exercisesSnapshot.docs.map((doc) {
      Exercise exercise = Exercise.fromFirestore(doc);
      String? superSetId =
          (doc.data() as Map<String, dynamic>)['superSetId'] as String?;
      return exercise.copyWith(superSetId: superSetId);
    }).toList();

    List<Future<void>> fetchSeriesFutures = [];
    for (int i = 0; i < exercises.length; i++) {
      fetchSeriesFutures.add(
        _fetchSeries(exercises[i].id!).then((series) {
          exercises[i] = exercises[i].copyWith(series: series);
        }),
      );
    }
    await Future.wait(fetchSeriesFutures);

    return exercises;
  }

  Future<List<Series>> _fetchSeries(String exerciseId) async {
    QuerySnapshot seriesSnapshot = await _db
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('order')
        .get();

    return seriesSnapshot.docs.map((doc) => Series.fromFirestore(doc)).toList();
  }

  Future<void> addOrUpdateTrainingProgram(TrainingProgram program) async {
    WriteBatch batch = _db.batch();
    try {
      String programId = program.id?.trim().isEmpty ?? true
          ? _db.collection('programs').doc().id
          : program.id!;
      
      program = program.copyWith(id: programId);

      await _addOrUpdateProgram(batch, program);
      await _addOrUpdateWeeks(batch, program);

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _addOrUpdateProgram(
    WriteBatch batch,
    TrainingProgram program,
  ) async {
    DocumentReference programRef = _db.collection('programs').doc(program.id);
    batch.set(programRef, program.toMap(), SetOptions(merge: true));
  }

  Future<void> _addOrUpdateWeeks(
    WriteBatch batch,
    TrainingProgram program,
  ) async {
    // 1) Mappa le settimane esistenti per numero così da riutilizzare l'ID se presente
    final Map<int, String> existingWeekIdByNumber = {};
    if (program.id != null && (program.id?.isNotEmpty ?? false)) {
      final qs = await _db
          .collection('weeks')
          .where('programId', isEqualTo: program.id)
          .get();
      for (final doc in qs.docs) {
        final data = doc.data();
        final number = (data['number'] as int?) ?? 0;
        // Tieni il primo per quel numero; eventuali duplicati verranno rimossi a fine salvataggio
        existingWeekIdByNumber.putIfAbsent(number, () => doc.id);
      }
    }

    // 2) Salva/aggiorna settimane riutilizzando ID esistenti in base al number
    for (int i = 0; i < program.weeks.length; i++) {
      final currentWeek = program.weeks[i];
      final int weekNumber = (currentWeek.number > 0) ? currentWeek.number : (i + 1);
      
      // Priorità: usa l'ID già presente nella settimana, poi quello esistente per quel numero, infine uno nuovo
      String weekId;
      if (currentWeek.id?.trim().isNotEmpty == true) {
        weekId = currentWeek.id!;
        // Rimuovi questo ID dalla mappa per evitare conflitti
        existingWeekIdByNumber.removeWhere((key, value) => value == weekId);
      } else {
        weekId = existingWeekIdByNumber[weekNumber] ?? _db.collection('weeks').doc().id;
        // Rimuovi questo mapping per evitare riutilizzo
        existingWeekIdByNumber.remove(weekNumber);
      }

      final updatedWeek = currentWeek.copyWith(id: weekId, number: weekNumber);

      // Propaga l'ID in memoria per evitare duplicazioni al prossimo salvataggio
      program.weeks[i] = updatedWeek;

      await _addOrUpdateWeek(batch, updatedWeek, program.id!);
      await _addOrUpdateWorkoutsAndUpdate(batch, program, i);
    }

    // 3) Cleanup finale: rimuove settimane fuori range e deduplica settimane con stesso numero
    await _cleanupExtraWeeks(batch, program);
    await _dedupWeeksByNumber(batch, program);
  }

  /// Aggiunge/aggiorna tutti i workout della settimana e aggiorna gli ID in memoria
  Future<void> _addOrUpdateWorkoutsAndUpdate(
    WriteBatch batch,
    TrainingProgram program,
    int weekIndex,
  ) async {
    final week = program.weeks[weekIndex];

    // Mappa workout esistenti per order
    final Map<int, String> existingWorkoutIdByOrder = {};
    if (week.id != null && week.id!.isNotEmpty) {
      final ws = await _db
          .collection('workouts')
          .where('weekId', isEqualTo: week.id)
          .get();
      for (final d in ws.docs) {
        final data = d.data();
        final order = (data['order'] as int?) ?? 0;
        existingWorkoutIdByOrder.putIfAbsent(order, () => d.id);
      }
    }

    for (int wi = 0; wi < week.workouts.length; wi++) {
      final workout = week.workouts[wi];
      final int workoutOrder = workout.order > 0 ? workout.order : (wi + 1);
      final String workoutId = workout.id?.trim().isNotEmpty == true
          ? workout.id!
          : (existingWorkoutIdByOrder[workoutOrder] ?? _db.collection('workouts').doc().id);
      final updatedWorkout = workout.copyWith(id: workoutId, order: workoutOrder);
      program.weeks[weekIndex].workouts[wi] = updatedWorkout;

      await _addOrUpdateWorkout(batch, updatedWorkout, week.id!);

      // Mappa esercizi esistenti per order per questo workout
      final Map<int, String> existingExerciseIdByOrder = {};
      final es = await _db
          .collection('exercisesWorkout')
          .where('workoutId', isEqualTo: workoutId)
          .get();
      for (final d in es.docs) {
        final data = d.data();
        final order = (data['order'] as int?) ?? 0;
        existingExerciseIdByOrder.putIfAbsent(order, () => d.id);
      }

      // Esercizi
      for (int ei = 0; ei < updatedWorkout.exercises.length; ei++) {
        final exercise = updatedWorkout.exercises[ei];
        final int exerciseOrder = exercise.order > 0 ? exercise.order : (ei + 1);
        final String exerciseId = exercise.id?.trim().isNotEmpty == true
            ? exercise.id!
            : (existingExerciseIdByOrder[exerciseOrder] ?? _db.collection('exercisesWorkout').doc().id);
        final updatedExercise = exercise.copyWith(id: exerciseId, order: exerciseOrder);
        program.weeks[weekIndex].workouts[wi].exercises[ei] = updatedExercise;

        await _addOrUpdateExercise(batch, updatedExercise, workoutId);

        // Serie
        for (int si = 0; si < updatedExercise.series.length; si++) {
          final series = updatedExercise.series[si];
          final String seriesId = (series.serieId?.trim().isEmpty ?? true)
              ? _db.collection('series').doc().id
              : series.serieId!;
          final updatedSeries = series.copyWith(serieId: seriesId);
          program.weeks[weekIndex]
              .workouts[wi]
              .exercises[ei]
              .series[si] = updatedSeries;

          await _addOrUpdateSingleSeries(
            batch,
            updatedSeries,
            exerciseId,
            si + 1,
            updatedExercise.exerciseId,
          );
        }
      }
    }
  }

  /// Simplified deduplication - only removes weeks that are explicitly marked for deletion
  /// KISS: No complex logic, just preserve all weeks currently in memory
  Future<void> _dedupWeeksByNumber(
    WriteBatch batch,
    TrainingProgram program,
  ) async {
    if (program.id == null || (program.id?.isEmpty ?? true)) return;

    // KISS: Create a simple set of all week IDs that should be preserved
    final preserveIds = program.weeks
        .map((w) => w.id)
        .where((id) => id != null && id!.isNotEmpty)
        .toSet();

    // Only process orphaned weeks (weeks in DB that are not in current program structure)
    final qs = await _db
        .collection('weeks')
        .where('programId', isEqualTo: program.id)
        .get();

    for (final doc in qs.docs) {
      final data = doc.data();
      final number = (data['number'] as int?) ?? 0;
      
      // Only delete if:
      // 1. Week number is invalid (< 1), OR
      // 2. Week ID is not in our preserve list (orphaned)
      if (number < 1 || !preserveIds.contains(doc.id)) {
        await _removeRelatedWorkouts(batch, doc.id);
        batch.delete(doc.reference);
      }
    }
  }

  /// Rimuove dal DB le settimane con number > program.weeks.length,
  /// cancellando anche i relativi workout/esercizi/serie nello stesso batch.
  Future<void> _cleanupExtraWeeks(
    WriteBatch batch,
    TrainingProgram program,
  ) async {
    if (program.id == null || (program.id?.isEmpty ?? true)) return;
    final int maxNumber = program.weeks.length;

    final qs = await _db
        .collection('weeks')
        .where('programId', isEqualTo: program.id)
        .get();

    for (final doc in qs.docs) {
      final data = doc.data();
      final number = (data['number'] as int?) ?? 0;
      if (number > maxNumber) {
        // Elimina anche i dati correlati
        await _removeRelatedWorkouts(batch, doc.id);
        batch.delete(doc.reference);
      }
    }
  }

  Future<void> _addOrUpdateWeek(
    WriteBatch batch,
    Week week,
    String programId,
  ) async {
    DocumentReference weekRef = _db.collection('weeks').doc(week.id);
    batch.set(weekRef, {
      'number': week.number,
      'programId': programId,
    }, SetOptions(merge: true));
  }

  // Metodo legacy rimosso (sostituito da _addOrUpdateWorkoutsAndUpdate)

  Future<void> _addOrUpdateWorkout(
    WriteBatch batch,
    Workout workout,
    String weekId,
  ) async {
    DocumentReference workoutRef = _db.collection('workouts').doc(workout.id);
    batch.set(workoutRef, {
      'order': workout.order,
      'weekId': weekId,
  'name': workout.name,
    }, SetOptions(merge: true));
  }

  // Metodo legacy rimosso (sostituito da _addOrUpdateWorkoutsAndUpdate)

  Future<void> _addOrUpdateExercise(
    WriteBatch batch,
    Exercise exercise,
    String workoutId,
  ) async {
    DocumentReference exerciseRef = _db
        .collection('exercisesWorkout')
        .doc(exercise.id);
    batch.set(exerciseRef, {
      'name': exercise.name,
      'order': exercise.order,
      'variant': exercise.variant,
      'workoutId': workoutId,
      'exerciseId': exercise.exerciseId,
      'type': exercise.type,
      'superSetId': exercise.superSetId,
      'latestMaxWeight': exercise.latestMaxWeight,
    }, SetOptions(merge: true));
  }

  // Metodo legacy rimosso (sostituito da _addOrUpdateWorkoutsAndUpdate)

  Future<void> _addOrUpdateSingleSeries(
    WriteBatch batch,
    Series series,
    String exerciseId,
    int order,
    String? originalExerciseId,
  ) async {
    DocumentReference seriesRef = _db
        .collection('series')
        .doc(series.serieId ?? series.id ?? '');
    batch.set(seriesRef, {
      'reps': series.reps,
      'sets': series.sets,
      'intensity': series.intensity,
      'rpe': series.rpe,
      'weight': series.weight,
      'exerciseId': exerciseId,
      'serieId': series.serieId ?? series.id,
      'originalExerciseId': originalExerciseId,
      'order': order,
      'done': series.done,
      'reps_done': series.repsDone,
      'weight_done': series.weightDone,
      //new interval
      'maxReps': series.maxReps,
      'maxSets': series.maxSets,
      'maxIntensity': series.maxIntensity,
      'maxRpe': series.maxRpe,
      'maxWeight': series.maxWeight,
    }, SetOptions(merge: true));
  }

  Future<void> removeToDeleteItems(TrainingProgram program) async {
    WriteBatch batch = _db.batch();
    try {
      await _removeWeeks(batch, program.trackToDeleteWeeks);
      await _removeWorkouts(batch, program.trackToDeleteWorkouts);
      await _removeExercises(batch, program.trackToDeleteExercises);
      await _removeSeries(batch, program.trackToDeleteSeries);

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _removeWeeks(WriteBatch batch, List<String> weekIds) async {
    for (String weekId in weekIds) {
      DocumentReference weekRef = _db.collection('weeks').doc(weekId);
      batch.delete(weekRef);
    }
  }

  Future<void> _removeWorkouts(
    WriteBatch batch,
    List<String> workoutIds,
  ) async {
    for (String workoutId in workoutIds) {
      DocumentReference workoutRef = _db.collection('workouts').doc(workoutId);
      batch.delete(workoutRef);
    }
  }

  Future<void> _removeExercises(
    WriteBatch batch,
    List<String> exerciseIds,
  ) async {
    for (String exerciseId in exerciseIds) {
      DocumentReference exerciseRef = _db
          .collection('exercisesWorkout')
          .doc(exerciseId);
      batch.delete(exerciseRef);
    }
  }

  Future<void> _removeSeries(WriteBatch batch, List<String> seriesIds) async {
    for (String seriesId in seriesIds) {
      DocumentReference seriesRef = _db.collection('series').doc(seriesId);
      batch.delete(seriesRef);
    }
  }
}
