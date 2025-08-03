import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/training_repository.dart';
import '../../models/training_model.dart';
import '../../models/exercise_model.dart';
import '../../models/series_model.dart';
import '../../models/week_model.dart';
import '../../models/workout_model.dart';

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
      return snapshot.docs
          .map((doc) => TrainingProgram.fromFirestore(doc))
          .toList();
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
    await Future.wait(weeks.map((week) async {
      week.workouts = await _fetchWorkouts(week.id!);
    }));

    return weeks;
  }

  Future<List<Workout>> _fetchWorkouts(String weekId) async {
    final snapshot = await _db
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .orderBy('order')
        .get();

    final workouts =
        snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();

    // Fetch exercises for each workout in parallel
    await Future.wait(workouts.map((workout) async {
      workout.exercises = await _fetchExercises(workout.id!);
    }));

    return workouts;
  }

  Future<List<Exercise>> _fetchExercises(String workoutId) async {
    final snapshot = await _db
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .orderBy('order')
        .get();

    final exercises =
        snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();

    // Fetch series for each exercise in parallel
    await Future.wait(exercises.map((exercise) async {
      exercise.series = await _fetchSeries(exercise.id!);
    }));

    return exercises;
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
    program.id = programId;

    final programRef = _db.collection('programs').doc(programId);
    batch.set(programRef, program.toMap(), SetOptions(merge: true));
  }

  Future<void> _saveWeeks(WriteBatch batch, TrainingProgram program) async {
    for (final week in program.weeks) {
      await _saveWeek(batch, week, program.id!);
    }
  }

  Future<void> _saveWeek(WriteBatch batch, Week week, String programId) async {
    final weekId = week.id?.trim().isEmpty ?? true
        ? _db.collection('weeks').doc().id
        : week.id!;
    week.id = weekId;

    final weekRef = _db.collection('weeks').doc(weekId);
    batch.set(
        weekRef,
        {
          'number': week.number,
          'programId': programId,
        },
        SetOptions(merge: true));

    // Save workouts
    for (final workout in week.workouts) {
      await _saveWorkout(batch, workout, weekId);
    }
  }

  Future<void> _saveWorkout(
      WriteBatch batch, Workout workout, String weekId) async {
    final workoutId = workout.id?.trim().isEmpty ?? true
        ? _db.collection('workouts').doc().id
        : workout.id!;
    workout.id = workoutId;

    final workoutRef = _db.collection('workouts').doc(workoutId);
    batch.set(
        workoutRef,
        {
          'order': workout.order,
          'weekId': weekId,
          'name': workout.name,
        },
        SetOptions(merge: true));

    // Save exercises
    for (final exercise in workout.exercises) {
      await _saveExercise(batch, exercise, workoutId);
    }
  }

  Future<void> _saveExercise(
      WriteBatch batch, Exercise exercise, String workoutId) async {
    final exerciseId = exercise.id?.trim().isEmpty ?? true
        ? _db.collection('exercisesWorkout').doc().id
        : exercise.id!;
    exercise.id = exerciseId;

    final exerciseRef = _db.collection('exercisesWorkout').doc(exerciseId);
    batch.set(
        exerciseRef,
        {
          'name': exercise.name,
          'order': exercise.order,
          'variant': exercise.variant,
          'workoutId': workoutId,
          'exerciseId': exercise.exerciseId,
          'type': exercise.type,
          'superSetId': exercise.superSetId,
          'latestMaxWeight': exercise.latestMaxWeight,
        },
        SetOptions(merge: true));

    // Save series
    for (int i = 0; i < exercise.series.length; i++) {
      await _saveSeries(
          batch, exercise.series[i], exerciseId, i + 1, exercise.exerciseId);
    }
  }

  Future<void> _saveSeries(WriteBatch batch, Series series, String exerciseId,
      int order, String? originalExerciseId) async {
    final seriesId = series.serieId.trim().isEmpty
        ? _db.collection('series').doc().id
        : series.serieId;
    series.serieId = seriesId;

    final seriesRef = _db.collection('series').doc(seriesId);
    batch.set(
        seriesRef,
        {
          'reps': series.reps,
          'sets': series.sets,
          'intensity': series.intensity,
          'rpe': series.rpe,
          'weight': series.weight,
          'exerciseId': exerciseId,
          'serieId': series.serieId,
          'originalExerciseId': originalExerciseId,
          'order': order,
          'done': series.done,
          'reps_done': series.reps_done,
          'weight_done': series.weight_done,
          'maxReps': series.maxReps,
          'maxSets': series.maxSets,
          'maxIntensity': series.maxIntensity,
          'maxRpe': series.maxRpe,
          'maxWeight': series.maxWeight,
        },
        SetOptions(merge: true));
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

/// Implementation for Exercise Repository
class FirestoreExerciseRepository implements ExerciseRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<String> addExerciseToWorkout(
      String workoutId, Map<String, dynamic> exerciseData) async {
    try {
      final ref = await _db.collection('exercisesWorkout').add({
        ...exerciseData,
        'workoutId': workoutId,
      });
      return ref.id;
    } catch (e) {
      throw Exception('Failed to add exercise: $e');
    }
  }

  @override
  Future<void> updateExercise(
      String exerciseId, Map<String, dynamic> exerciseData) async {
    try {
      await _db
          .collection('exercisesWorkout')
          .doc(exerciseId)
          .update(exerciseData);
    } catch (e) {
      throw Exception('Failed to update exercise: $e');
    }
  }

  @override
  Future<void> removeExercise(String exerciseId) async {
    try {
      await _db.collection('exercisesWorkout').doc(exerciseId).delete();
    } catch (e) {
      throw Exception('Failed to remove exercise: $e');
    }
  }

  @override
  Future<List<Exercise>> getExercisesByWorkoutId(String workoutId) async {
    try {
      final snapshot = await _db
          .collection('exercisesWorkout')
          .where('workoutId', isEqualTo: workoutId)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch exercises: $e');
    }
  }
}

/// Implementation for Series Repository
class FirestoreSeriesRepository implements SeriesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<String> addSeriesToExercise(String exerciseId, Series series,
      {String? originalExerciseId}) async {
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

/// Implementation for Week Repository
class FirestoreWeekRepository implements WeekRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<String> addWeekToProgram(
      String programId, Map<String, dynamic> weekData) async {
    try {
      final ref = await _db.collection('weeks').add({
        ...weekData,
        'programId': programId,
      });
      return ref.id;
    } catch (e) {
      throw Exception('Failed to add week: $e');
    }
  }

  @override
  Future<void> updateWeek(String weekId, Map<String, dynamic> weekData) async {
    try {
      await _db.collection('weeks').doc(weekId).update(weekData);
    } catch (e) {
      throw Exception('Failed to update week: $e');
    }
  }

  @override
  Future<void> removeWeek(String weekId) async {
    try {
      await _db.collection('weeks').doc(weekId).delete();
    } catch (e) {
      throw Exception('Failed to remove week: $e');
    }
  }

  @override
  Future<List<Week>> getWeeksByProgramId(String programId) async {
    try {
      final snapshot = await _db
          .collection('weeks')
          .where('programId', isEqualTo: programId)
          .orderBy('number')
          .get();

      return snapshot.docs.map((doc) => Week.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch weeks: $e');
    }
  }
}

/// Implementation for Workout Repository
class FirestoreWorkoutRepository implements WorkoutRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<String> addWorkoutToWeek(
      String weekId, Map<String, dynamic> workoutData) async {
    try {
      final ref = await _db.collection('workouts').add({
        ...workoutData,
        'weekId': weekId,
      });
      return ref.id;
    } catch (e) {
      throw Exception('Failed to add workout: $e');
    }
  }

  @override
  Future<void> updateWorkout(
      String workoutId, Map<String, dynamic> workoutData) async {
    try {
      await _db.collection('workouts').doc(workoutId).update(workoutData);
    } catch (e) {
      throw Exception('Failed to update workout: $e');
    }
  }

  @override
  Future<void> removeWorkout(String workoutId) async {
    try {
      await _db.collection('workouts').doc(workoutId).delete();
    } catch (e) {
      throw Exception('Failed to remove workout: $e');
    }
  }

  @override
  Future<List<Workout>> getWorkoutsByWeekId(String weekId) async {
    try {
      final snapshot = await _db
          .collection('workouts')
          .where('weekId', isEqualTo: weekId)
          .orderBy('order')
          .get();

      return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch workouts: $e');
    }
  }
}
