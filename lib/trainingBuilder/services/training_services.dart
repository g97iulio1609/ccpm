import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/shared.dart';

// Batching helper that automatically splits operations across multiple batches
// to stay safely under Firestore's 500 ops per commit limit.
// Keeps a conservative threshold (default 450) to account for any overhead.
// Provides a minimal WriteBatch-like API: set, update, delete, commitAll.
class BatchCollector {
  final FirebaseFirestore _db;
  final int maxOpsPerBatch;

  final List<WriteBatch> _batches = [];
  int _opsInCurrent = 0;
  int _totalOps = 0;

  BatchCollector(this._db, {this.maxOpsPerBatch = 450}) {
    _batches.add(_db.batch());
  }

  WriteBatch get _current => _batches.last;

  void _ensureCapacity(int additionalOps) {
    if (_opsInCurrent + additionalOps > maxOpsPerBatch) {
      _batches.add(_db.batch());
      _opsInCurrent = 0;
    }
  }

  void set(DocumentReference ref, Map<String, dynamic> data, [SetOptions? options]) {
    _ensureCapacity(1);
    _current.set(ref, data, options);
    _opsInCurrent += 1;
    _totalOps += 1;
  }

  void update(DocumentReference ref, Map<String, dynamic> data) {
    _ensureCapacity(1);
    _current.update(ref, data);
    _opsInCurrent += 1;
    _totalOps += 1;
  }

  void delete(DocumentReference ref) {
    _ensureCapacity(1);
    _current.delete(ref);
    _opsInCurrent += 1;
    _totalOps += 1;
  }

  Future<void> commitAll() async {
    for (final b in _batches) {
      await b.commit();
    }
  }

  int get totalOps => _totalOps;
  int get batchCount => _batches.length;
}

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
      return snapshot.docs.map((doc) => TrainingProgram.fromFirestore(doc)).toList();
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

  Future<void> updateProgram(String programId, Map<String, dynamic> programData) async {
    try {
      await _db.collection('programs').doc(programId).update(programData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeProgram(String programId) async {
    try {
      final batch = BatchCollector(_db);

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

      await batch.commitAll();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _removeRelatedWorkouts(BatchCollector batch, String weekId) async {
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

  Future<void> _removeRelatedExercises(BatchCollector batch, String workoutId) async {
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

  Future<void> _removeRelatedSeries(BatchCollector batch, String exerciseId) async {
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

      List<Week> weeks = weeksSnapshot.docs.map((doc) => Week.fromFirestore(doc)).toList();

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
      String? superSetId = (doc.data() as Map<String, dynamic>)['superSetId'] as String?;
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
    final batch = BatchCollector(_db);
    try {
      String programId = program.id?.trim().isEmpty ?? true
          ? _db.collection('programs').doc().id
          : program.id!;

      program = program.copyWith(id: programId);

      await _addOrUpdateProgram(batch, program);
      await _addOrUpdateWeeksOptimized(batch, program);

      await batch.commitAll();
    } catch (e) {
      rethrow;
    }
  }

  /// Optimized version of _addOrUpdateWeeks that minimizes Firestore reads by:
  /// - Prefetching existing workouts for all weeks using whereIn with chunking
  /// - Prefetching existing exercises for all workouts using whereIn with chunking
  /// - Avoiding nested awaits inside loops
  Future<void> _addOrUpdateWeeksOptimized(BatchCollector batch, TrainingProgram program) async {
    // 1) Map existing week IDs by number (reuse IDs when possible)
    final Map<int, String> existingWeekIdByNumber = {};
    if (program.id != null && (program.id?.isNotEmpty ?? false)) {
      final qs = await _db.collection('weeks').where('programId', isEqualTo: program.id).get();
      for (final doc in qs.docs) {
        final data = doc.data();
        final number = (data['number'] as int?) ?? 0;
        existingWeekIdByNumber.putIfAbsent(number, () => doc.id);
      }
    }

    // 2) Build updated weeks first (deterministic IDs and numbers)
    final List<Week> updatedWeeks = [];
    for (int i = 0; i < program.weeks.length; i++) {
      final currentWeek = program.weeks[i];
      final int weekNumber = (currentWeek.number > 0) ? currentWeek.number : (i + 1);
      String weekId;
      if (currentWeek.id?.trim().isNotEmpty == true) {
        weekId = currentWeek.id!;
        existingWeekIdByNumber.removeWhere((_, value) => value == weekId);
      } else {
        weekId = existingWeekIdByNumber[weekNumber] ?? _db.collection('weeks').doc().id;
        existingWeekIdByNumber.remove(weekNumber);
      }

      updatedWeeks.add(currentWeek.copyWith(id: weekId, number: weekNumber));
    }
    // Propagate updated weeks back to program
    for (int i = 0; i < updatedWeeks.length; i++) {
      program.weeks[i] = updatedWeeks[i];
    }

    // 3) Prefetch existing workouts for all week IDs, grouped by weekId and order
    final List<String> weekIds = updatedWeeks
        .map((w) => w.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    final existingWorkoutsByWeekAndOrder = await _fetchExistingWorkoutsByWeekIds(weekIds);

    // 4) Determine/update workouts with IDs and orders, accumulating the final workout IDs
    final List<String> allWorkoutIds = [];
    for (int wi = 0; wi < program.weeks.length; wi++) {
      final week = program.weeks[wi];
      final Map<int, String> existingByOrder = existingWorkoutsByWeekAndOrder[week.id] ?? {};

      for (int idx = 0; idx < week.workouts.length; idx++) {
        final workout = week.workouts[idx];
        final int workoutOrder = workout.order > 0 ? workout.order : (idx + 1);
        final existingId = workout.id;
        final String workoutId = (existingId != null && existingId.trim().isNotEmpty)
            ? existingId
            : (existingByOrder[workoutOrder] ?? _db.collection('workouts').doc().id);

        final updatedWorkout = workout.copyWith(id: workoutId, order: workoutOrder);
        program.weeks[wi].workouts[idx] = updatedWorkout;
        allWorkoutIds.add(workoutId);
      }
    }

    // 5) Prefetch existing exercises for all determined workout IDs, grouped by workoutId and order
    final existingExercisesByWorkoutAndOrder = await _fetchExistingExercisesByWorkoutIds(
      allWorkoutIds,
    );

    // 6) Write weeks and workouts to batch (queued into batch collector)
    for (final week in program.weeks) {
      await _addOrUpdateWeek(batch, week, program.id!);
      for (final workout in week.workouts) {
        await _addOrUpdateWorkout(batch, workout, week.id!);
      }
    }

    // 7) Assign exercise IDs using prefetch maps and queue writes; then queue series writes
    for (int wi = 0; wi < program.weeks.length; wi++) {
      final week = program.weeks[wi];
      for (int woi = 0; woi < week.workouts.length; woi++) {
        final workout = week.workouts[woi];
        final Map<int, String> existingExByOrder =
            existingExercisesByWorkoutAndOrder[workout.id] ?? {};

        for (int ei = 0; ei < workout.exercises.length; ei++) {
          final exercise = workout.exercises[ei];
          final int exerciseOrder = exercise.order > 0 ? exercise.order : (ei + 1);
          final String exerciseId = exercise.id?.trim().isNotEmpty == true
              ? exercise.id!
              : (existingExByOrder[exerciseOrder] ?? _db.collection('exercisesWorkout').doc().id);
          final updatedExercise = exercise.copyWith(id: exerciseId, order: exerciseOrder);
          program.weeks[wi].workouts[woi].exercises[ei] = updatedExercise;

          await _addOrUpdateExercise(batch, updatedExercise, workout.id!);

          // Series: ensure stable IDs or create new ones; queue writes
          for (int si = 0; si < updatedExercise.series.length; si++) {
            final series = updatedExercise.series[si];
            final String seriesId = (series.serieId?.trim().isEmpty ?? true)
                ? _db.collection('series').doc().id
                : series.serieId!;
            final updatedSeries = series.copyWith(serieId: seriesId);
            program.weeks[wi].workouts[woi].exercises[ei].series[si] = updatedSeries;

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

    // 8) Cleanup (weeks only as before). Workouts/exercises cleanup relies on reuse-by-order above.
    await _cleanupExtraWeeks(batch, program);
    await _dedupWeeksByNumber(batch, program);
  }

  /// Fetch existing workouts for all provided weekIds.
  /// Returns: { weekId: { order: workoutDocId } }
  Future<Map<String, Map<int, String>>> _fetchExistingWorkoutsByWeekIds(
    List<String> weekIds,
  ) async {
    final Map<String, Map<int, String>> result = {};
    if (weekIds.isEmpty) return result;

    // Firestore whereIn max 10 values (keep conservative)
    const int chunkSize = 10;
    for (int i = 0; i < weekIds.length; i += chunkSize) {
      final chunk = weekIds.sublist(
        i,
        i + chunkSize > weekIds.length ? weekIds.length : i + chunkSize,
      );
      final qs = await _db.collection('workouts').where('weekId', whereIn: chunk).get();
      for (final doc in qs.docs) {
        final data = doc.data();
        final wId = (data['weekId'] as String?) ?? '';
        if (wId.isEmpty) continue;
        final order = (data['order'] as int?) ?? 0;
        result.putIfAbsent(wId, () => {});
        // Preserve the first seen ID for an order
        result[wId]!.putIfAbsent(order, () => doc.id);
      }
    }
    return result;
  }

  /// Fetch existing exercises for all provided workoutIds.
  /// Returns: { workoutId: { order: exerciseDocId } }
  Future<Map<String, Map<int, String>>> _fetchExistingExercisesByWorkoutIds(
    List<String> workoutIds,
  ) async {
    final Map<String, Map<int, String>> result = {};
    if (workoutIds.isEmpty) return result;

    const int chunkSize = 10;
    for (int i = 0; i < workoutIds.length; i += chunkSize) {
      final chunk = workoutIds.sublist(
        i,
        i + chunkSize > workoutIds.length ? workoutIds.length : i + chunkSize,
      );
      final qs = await _db.collection('exercisesWorkout').where('workoutId', whereIn: chunk).get();
      for (final doc in qs.docs) {
        final data = doc.data();
        final wrkId = (data['workoutId'] as String?) ?? '';
        if (wrkId.isEmpty) continue;
        final order = (data['order'] as int?) ?? 0;
        result.putIfAbsent(wrkId, () => {});
        result[wrkId]!.putIfAbsent(order, () => doc.id);
      }
    }
    return result;
  }

  Future<void> _addOrUpdateProgram(BatchCollector batch, TrainingProgram program) async {
    DocumentReference programRef = _db.collection('programs').doc(program.id);
    batch.set(programRef, program.toMap(), SetOptions(merge: true));
  }

  // ignore: unused_element
  // Legacy method removed (superseded by _addOrUpdateWeeksOptimized)

  /// Aggiunge/aggiorna tutti i workout della settimana e aggiorna gli ID in memoria
  // Legacy method removed (superseded by optimized path)

  /// Simplified deduplication - only removes weeks that are explicitly marked for deletion
  /// KISS: No complex logic, just preserve all weeks currently in memory
  Future<void> _dedupWeeksByNumber(BatchCollector batch, TrainingProgram program) async {
    if (program.id == null || (program.id?.isEmpty ?? true)) return;

    // KISS: Create a simple set of all week IDs that should be preserved
    final preserveIds = program.weeks
        .map((w) => w.id)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    // Only process orphaned weeks (weeks in DB that are not in current program structure)
    final qs = await _db.collection('weeks').where('programId', isEqualTo: program.id).get();

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
  Future<void> _cleanupExtraWeeks(BatchCollector batch, TrainingProgram program) async {
    if (program.id == null || (program.id?.isEmpty ?? true)) return;
    final int maxNumber = program.weeks.length;

    final qs = await _db.collection('weeks').where('programId', isEqualTo: program.id).get();

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

  Future<void> _addOrUpdateWeek(BatchCollector batch, Week week, String programId) async {
    DocumentReference weekRef = _db.collection('weeks').doc(week.id);
    batch.set(weekRef, {'number': week.number, 'programId': programId}, SetOptions(merge: true));
  }

  // Metodo legacy rimosso (sostituito da _addOrUpdateWorkoutsAndUpdate)

  Future<void> _addOrUpdateWorkout(BatchCollector batch, Workout workout, String weekId) async {
    DocumentReference workoutRef = _db.collection('workouts').doc(workout.id);
    batch.set(workoutRef, {
      'order': workout.order,
      'weekId': weekId,
      'name': workout.name,
    }, SetOptions(merge: true));
  }

  // Metodo legacy rimosso (sostituito da _addOrUpdateWorkoutsAndUpdate)

  Future<void> _addOrUpdateExercise(
    BatchCollector batch,
    Exercise exercise,
    String workoutId,
  ) async {
    DocumentReference exerciseRef = _db.collection('exercisesWorkout').doc(exercise.id);
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
    BatchCollector batch,
    Series series,
    String exerciseId,
    int order,
    String? originalExerciseId,
  ) async {
    DocumentReference seriesRef = _db.collection('series').doc(series.serieId ?? series.id ?? '');
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
    final batch = BatchCollector(_db);
    try {
      await _removeWeeks(batch, program.trackToDeleteWeeks);
      await _removeWorkouts(batch, program.trackToDeleteWorkouts);
      await _removeExercises(batch, program.trackToDeleteExercises);
      await _removeSeries(batch, program.trackToDeleteSeries);

      await batch.commitAll();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _removeWeeks(BatchCollector batch, List<String> weekIds) async {
    for (String weekId in weekIds) {
      DocumentReference weekRef = _db.collection('weeks').doc(weekId);
      batch.delete(weekRef);
    }
  }

  Future<void> _removeWorkouts(BatchCollector batch, List<String> workoutIds) async {
    for (String workoutId in workoutIds) {
      DocumentReference workoutRef = _db.collection('workouts').doc(workoutId);
      batch.delete(workoutRef);
    }
  }

  Future<void> _removeExercises(BatchCollector batch, List<String> exerciseIds) async {
    for (String exerciseId in exerciseIds) {
      DocumentReference exerciseRef = _db.collection('exercisesWorkout').doc(exerciseId);
      batch.delete(exerciseRef);
    }
  }

  Future<void> _removeSeries(BatchCollector batch, List<String> seriesIds) async {
    for (String seriesId in seriesIds) {
      DocumentReference seriesRef = _db.collection('series').doc(seriesId);
      batch.delete(seriesRef);
    }
  }
}
