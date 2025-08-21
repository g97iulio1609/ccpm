import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/training_repository.dart';
import '../../../shared/shared.dart' hide ExerciseRepository, WeekRepository;

/// Firestore implementation of repository interfaces
/// Follows Dependency Inversion Principle
class FirestoreTrainingRepository implements TrainingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<TrainingProgram?> getTrainingProgram(String programId) async {
    try {
      final doc = await _db.collection('programs').doc(programId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final program = TrainingProgram.fromFirestore(doc);
      program.weeks = await _fetchWeeks(programId);
      return program;
    } catch (e) {
      throw Exception('Failed to fetch training program: $e');
    }
  }

  @override
  Future<void> saveTrainingProgram(TrainingProgram program) async {
    final batch = _db.batch();

    try {
      await _saveProgram(batch, program);
      await _saveWeeks(batch, program);
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to save training program: $e');
    }
  }

  @override
  Future<void> deleteTrainingProgram(String programId) async {
    final batch = _db.batch();

    try {
      // Delete related data first
      final weeks = await _fetchWeeks(programId);
      for (final week in weeks) {
        await _deleteWeekData(batch, week.id!);
      }

      // Delete program
      batch.delete(_db.collection('programs').doc(programId));
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete training program: $e');
    }
  }

  @override
  Stream<List<TrainingProgram>> streamTrainingPrograms() {
    return _db.collection('programs').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TrainingProgram.fromFirestore(doc)).toList();
    });
  }

  @override
  Future<void> removeToDeleteItems(TrainingProgram program) async {
    final batch = _db.batch();

    try {
      // Remove tracked items
      for (final seriesId in program.trackToDeleteSeries) {
        batch.delete(_db.collection('series').doc(seriesId));
      }

      for (final exerciseId in program.trackToDeleteExercises) {
        batch.delete(_db.collection('exercisesWorkout').doc(exerciseId));
      }

      for (final workoutId in program.trackToDeleteWorkouts) {
        batch.delete(_db.collection('workouts').doc(workoutId));
      }

      for (final weekId in program.trackToDeleteWeeks) {
        batch.delete(_db.collection('weeks').doc(weekId));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to remove tracked items: $e');
    }
  }

  // Private helper methods

  Future<List<Week>> _fetchWeeks(String programId) async {
    final snapshot = await _db
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .orderBy('number')
        .get();

    final weeks = snapshot.docs.map((doc) => Week.fromFirestore(doc)).toList();

    // Fetch workouts for each week in parallel
    final updatedWeeks = <Week>[];
    for (final week in weeks) {
      final workouts = await _fetchWorkouts(week.id!);
      updatedWeeks.add(week.copyWith(workouts: workouts));
    }

    return updatedWeeks;
  }

  Future<List<Workout>> _fetchWorkouts(String weekId) async {
    final snapshot = await _db
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .orderBy('order')
        .get();

    final workouts = snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();

    // Fetch exercises for each workout in parallel
    final updatedWorkouts = <Workout>[];
    for (final workout in workouts) {
      final exercises = await _fetchExercises(workout.id!);
      updatedWorkouts.add(workout.copyWith(exercises: exercises));
    }

    return updatedWorkouts;
  }

  Future<List<Exercise>> _fetchExercises(String workoutId) async {
    final snapshot = await _db
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('order')
        .get();

    final exercises = snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();

    // Fetch series for each exercise in parallel
    final updatedExercises = <Exercise>[];
    for (final exercise in exercises) {
      final series = await _fetchSeries(exercise.id!);
      updatedExercises.add(exercise.copyWith(series: series));
    }

    return updatedExercises;
  }

  Future<List<Series>> _fetchSeries(String exerciseId) async {
    final snapshot = await _db
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('order')
        .get();

    return snapshot.docs.map((doc) => Series.fromFirestore(doc)).toList();
  }

  Future<void> _saveProgram(WriteBatch batch, TrainingProgram program) async {
    final programId = program.id?.trim().isEmpty ?? true
        ? _db.collection('programs').doc().id
        : program.id!;

    // Create a new program with the correct ID if needed
    final programToSave = program.id != programId ? program.copyWith(id: programId) : program;

    final programRef = _db.collection('programs').doc(programId);
    batch.set(programRef, programToSave.toMap(), SetOptions(merge: true));
  }

  Future<void> _saveWeeks(WriteBatch batch, TrainingProgram program) async {
    for (final week in program.weeks) {
      await _saveWeek(batch, week, program.id!);
    }
  }

  Future<void> _saveWeek(WriteBatch batch, Week week, String programId) async {
    final weekId = week.id?.trim().isEmpty ?? true ? _db.collection('weeks').doc().id : week.id!;

    // Create a new week with the correct ID if needed
    final weekToSave = week.id != weekId ? week.copyWith(id: weekId) : week;

    final weekRef = _db.collection('weeks').doc(weekId);
    batch.set(weekRef, {
      'number': weekToSave.number,
      'programId': programId,
    }, SetOptions(merge: true));

    // Save workouts
    for (final workout in weekToSave.workouts) {
      await _saveWorkout(batch, workout, weekId);
    }
  }

  Future<void> _saveWorkout(WriteBatch batch, Workout workout, String weekId) async {
    final workoutId = workout.id?.trim().isEmpty ?? true
        ? _db.collection('workouts').doc().id
        : workout.id!;

    // Create a new workout with the correct ID if needed
    final workoutToSave = workout.id != workoutId ? workout.copyWith(id: workoutId) : workout;

    final workoutRef = _db.collection('workouts').doc(workoutId);
    batch.set(workoutRef, {
      'order': workoutToSave.order,
      'weekId': weekId,
      'name': workoutToSave.name,
    }, SetOptions(merge: true));

    // Save exercises
    for (final exercise in workoutToSave.exercises) {
      await _saveExercise(batch, exercise, workoutId);
    }
  }

  Future<void> _saveExercise(WriteBatch batch, Exercise exercise, String workoutId) async {
    final exerciseId = exercise.id?.trim().isEmpty ?? true
        ? _db.collection('exercisesWorkout').doc().id
        : exercise.id!;

    // Create a new exercise with the correct ID if needed
    final exerciseToSave = exercise.id != exerciseId ? exercise.copyWith(id: exerciseId) : exercise;

    final exerciseRef = _db.collection('exercisesWorkout').doc(exerciseId);
    batch.set(exerciseRef, {
      'name': exerciseToSave.name,
      'order': exerciseToSave.order,
      'variant': exerciseToSave.variant,
      'workoutId': workoutId,
      'exerciseId': exerciseToSave.exerciseId,
      'type': exerciseToSave.type,
      'superSetId': exerciseToSave.superSetId,
      'latestMaxWeight': exerciseToSave.latestMaxWeight,
    }, SetOptions(merge: true));

    // Save series
    for (int i = 0; i < exerciseToSave.series.length; i++) {
      await _saveSeries(
        batch,
        exerciseToSave.series[i],
        exerciseId,
        i + 1,
        exerciseToSave.exerciseId,
      );
    }
  }

  Future<void> _saveSeries(
    WriteBatch batch,
    Series series,
    String exerciseId,
    int order,
    String? originalExerciseId,
  ) async {
    final seriesId = series.serieId?.trim().isEmpty ?? true
        ? _db.collection('series').doc().id
        : series.serieId!;

    // Create a new series with the correct ID if needed
    final seriesToSave = series.serieId != seriesId ? series.copyWith(serieId: seriesId) : series;

    final seriesRef = _db.collection('series').doc(seriesId);
    batch.set(seriesRef, {
      'reps': seriesToSave.reps,
      'sets': seriesToSave.sets,
      'intensity': seriesToSave.intensity,
      'rpe': seriesToSave.rpe,
      'weight': seriesToSave.weight,
      'exerciseId': exerciseId,
      'serieId': seriesToSave.serieId,
      'originalExerciseId': originalExerciseId,
      'order': order,
      'done': seriesToSave.done,
      'reps_done': seriesToSave.repsDone,
      'weight_done': seriesToSave.weightDone,
      'maxReps': seriesToSave.maxReps,
      'maxSets': seriesToSave.maxSets,
      'maxIntensity': seriesToSave.maxIntensity,
      'maxRpe': seriesToSave.maxRpe,
      'maxWeight': seriesToSave.maxWeight,
    }, SetOptions(merge: true));
  }

  Future<void> _deleteWeekData(WriteBatch batch, String weekId) async {
    // Get workouts for this week
    final workoutsSnapshot = await _db
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .get();

    for (final workoutDoc in workoutsSnapshot.docs) {
      await _deleteWorkoutData(batch, workoutDoc.id);
      batch.delete(workoutDoc.reference);
    }

    batch.delete(_db.collection('weeks').doc(weekId));
  }

  Future<void> _deleteWorkoutData(WriteBatch batch, String workoutId) async {
    // Get exercises for this workout
    final exercisesSnapshot = await _db
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .get();

    for (final exerciseDoc in exercisesSnapshot.docs) {
      await _deleteExerciseData(batch, exerciseDoc.id);
      batch.delete(exerciseDoc.reference);
    }
  }

  Future<void> _deleteExerciseData(WriteBatch batch, String exerciseId) async {
    // Get series for this exercise
    final seriesSnapshot = await _db
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseId)
        .get();

    for (final seriesDoc in seriesSnapshot.docs) {
      batch.delete(seriesDoc.reference);
    }
  }
}

/// Implementation for Series Repository
class FirestoreSeriesRepository implements SeriesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<String> addSeriesToExercise(
    String exerciseId,
    Series series, {
    String? originalExerciseId,
  }) async {
    try {
      if (originalExerciseId != null) {
        series = series.copyWith(originalExerciseId: originalExerciseId);
      }

      final seriesData = series.toFirestore();
      seriesData['exerciseId'] = exerciseId;

      final ref = await _db.collection('series').add(seriesData);
      return ref.id;
    } catch (e) {
      throw Exception('Failed to add series: $e');
    }
  }

  @override
  Future<void> updateSeries(String seriesId, Series series) async {
    try {
      await _db.collection('series').doc(seriesId).update(series.toFirestore());
    } catch (e) {
      throw Exception('Failed to update series: $e');
    }
  }

  @override
  Future<void> removeSeries(String seriesId) async {
    try {
      await _db.collection('series').doc(seriesId).delete();
    } catch (e) {
      throw Exception('Failed to remove series: $e');
    }
  }

  @override
  Future<List<Series>> getSeriesByExerciseId(String exerciseId) async {
    try {
      final snapshot = await _db
          .collection('series')
          .where('exerciseId', isEqualTo: exerciseId)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) => Series.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch series: $e');
    }
  }
}
