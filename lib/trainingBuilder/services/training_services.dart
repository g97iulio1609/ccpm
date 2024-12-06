import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_model.dart';
import '../models/week_model.dart';
import '../models/workout_model.dart';
import '../models/exercise_model.dart';
import '../models/series_model.dart';

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
      String programId, Map<String, dynamic> programData) async {
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
      WriteBatch batch, String workoutId) async {
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
      print('DEBUG: Fetching training program with ID: $programId');
      DocumentSnapshot<Map<String, dynamic>> doc = await _db.collection('programs').doc(programId).get();
      
      if (!doc.exists || doc.data() == null) {
        print('DEBUG: No document found for program ID: $programId');
        throw Exception('No training program found with ID: $programId');
      }
      
      Map<String, dynamic> data = doc.data()!;
      print('DEBUG: Raw data from Firestore: $data');
      
      // Create a new program with default values if any field is missing
      TrainingProgram program = TrainingProgram(
        id: doc.id,
        name: data['name'] as String? ?? '',
        hide: data['hide'] as bool? ?? false,
        description: data['description'] as String? ?? '',
        athleteId: data['athleteId'] as String? ?? '',
        status: data['status'] as String? ?? 'private',
        mesocycleNumber: data['mesocycleNumber'] as int? ?? 1,
      );
      
      print('DEBUG: Parsed program data - Weeks count: ${program.weeks.length}');
      if (program.weeks.isNotEmpty) {
        print('DEBUG: First week workouts count: ${program.weeks.first.workouts.length}');
      }
      
      program.weeks = await _fetchWeeks(programId);
      return program;
    } catch (e) {
      print('Error fetching training program: $e');
      rethrow;
    }
  }

  Future<List<Week>> _fetchWeeks(String programId) async {
    try {
      print('DEBUG: Fetching weeks for program: $programId');
      QuerySnapshot<Map<String, dynamic>> weeksSnapshot = await _db
          .collection('weeks')
          .where('programId', isEqualTo: programId)
          .orderBy('number')
          .get();

      List<Week> weeks = weeksSnapshot.docs.map((doc) => Week.fromFirestore(doc)).toList();
      print('DEBUG: Found ${weeks.length} weeks');

      // Fetch workouts for each week in parallel
      List<Future<void>> fetchWorkoutsFutures = [];
      for (Week week in weeks) {
        fetchWorkoutsFutures.add(_fetchWorkouts(week.id!).then((workouts) {
          week.workouts = workouts;
          print('DEBUG: Week ${week.number} has ${workouts.length} workouts');
        }));
      }
      await Future.wait(fetchWorkoutsFutures);

      return weeks;
    } catch (e) {
      print('Error fetching weeks: $e');
      rethrow;
    }
  }

  Future<List<Workout>> _fetchWorkouts(String weekId) async {
    try {
      print('DEBUG: Fetching workouts for week: $weekId');
      QuerySnapshot<Map<String, dynamic>> workoutsSnapshot = await _db
          .collection('workouts')
          .where('weekId', isEqualTo: weekId)
          .orderBy('order')
          .get();

      List<Workout> workouts = workoutsSnapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
      print('DEBUG: Found ${workouts.length} workouts');

      // Fetch exercises for each workout in parallel
      List<Future<void>> fetchExercisesFutures = [];
      for (Workout workout in workouts) {
        fetchExercisesFutures.add(_fetchExercises(workout.id!).then((exercises) {
          workout.exercises = exercises;
          print('DEBUG: Workout ${workout.name} has ${exercises.length} exercises');
        }));
      }
      await Future.wait(fetchExercisesFutures);

      return workouts;
    } catch (e) {
      print('Error fetching workouts: $e');
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
      exercise.superSetId =
          (doc.data() as Map<String, dynamic>)['superSetId'] as String?;
      return exercise;
    }).toList();

    // Esegui le query delle serie in parallelo
    List<Future<void>> fetchSeriesFutures = [];
    for (Exercise exercise in exercises) {
      fetchSeriesFutures.add(_fetchSeries(exercise.id!).then((series) {
        exercise.series = series;
      }));
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
      program.id = programId;

      await _addOrUpdateProgram(batch, program);
      await _addOrUpdateWeeks(batch, program);

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _addOrUpdateProgram(
      WriteBatch batch, TrainingProgram program) async {
    DocumentReference programRef = _db.collection('programs').doc(program.id);
    batch.set(
      programRef,
      program.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> _addOrUpdateWeeks(
      WriteBatch batch, TrainingProgram program) async {
    for (Week week in program.weeks) {
      String weekId = week.id?.trim().isEmpty ?? true
          ? _db.collection('weeks').doc().id
          : week.id!;
      week.id = weekId;

      await _addOrUpdateWeek(batch, week, program.id!);
      await _addOrUpdateWorkouts(batch, week);
    }
  }

  Future<void> _addOrUpdateWeek(
      WriteBatch batch, Week week, String programId) async {
    DocumentReference weekRef = _db.collection('weeks').doc(week.id);
    batch.set(
      weekRef,
      {
        'number': week.number,
        'programId': programId,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _addOrUpdateWorkouts(WriteBatch batch, Week week) async {
    for (Workout workout in week.workouts) {
      String workoutId = workout.id?.trim().isEmpty ?? true
          ? _db.collection('workouts').doc().id
          : workout.id!;
      workout.id = workoutId;

      await _addOrUpdateWorkout(batch, workout, week.id!);
      await _addOrUpdateExercises(batch, workout);
    }
  }

  Future<void> _addOrUpdateWorkout(
      WriteBatch batch, Workout workout, String weekId) async {
    DocumentReference workoutRef = _db.collection('workouts').doc(workout.id);
    batch.set(
      workoutRef,
      {
        'order': workout.order,
        'weekId': weekId,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _addOrUpdateExercises(WriteBatch batch, Workout workout) async {
    for (Exercise exercise in workout.exercises) {
      String exerciseId = exercise.id?.trim().isEmpty ?? true
          ? _db.collection('exercisesWorkout').doc().id
          : exercise.id!;
      exercise.id = exerciseId;

      await _addOrUpdateExercise(batch, exercise, workout.id!);
      await _addOrUpdateSeries(batch, exercise);
    }
  }

  Future<void> _addOrUpdateExercise(
      WriteBatch batch, Exercise exercise, String workoutId) async {
    DocumentReference exerciseRef =
        _db.collection('exercisesWorkout').doc(exercise.id);
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
      SetOptions(merge: true),
    );
  }

  Future<void> _addOrUpdateSeries(WriteBatch batch, Exercise exercise) async {
    for (int i = 0; i < exercise.series.length; i++) {
      Series series = exercise.series[i];
      String seriesId = series.serieId.trim().isEmpty ?? true
          ? _db.collection('series').doc().id
          : series.serieId;
      series.serieId = seriesId;

      await _addOrUpdateSingleSeries(
          batch, series, exercise.id!, i + 1, exercise.exerciseId);
    }
  }

  Future<void> _addOrUpdateSingleSeries(WriteBatch batch, Series series,
      String exerciseId, int order, String? originalExerciseId) async {
    DocumentReference seriesRef = _db.collection('series').doc(series.serieId);
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
        //new interval
        'maxReps': series.maxReps,
        'maxSets': series.maxSets,
        'maxIntensity': series.maxIntensity,
        'maxRpe': series.maxRpe,
        'maxWeight': series.maxWeight,
      },
      SetOptions(merge: true),
    );
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
      WriteBatch batch, List<String> workoutIds) async {
    for (String workoutId in workoutIds) {
      DocumentReference workoutRef = _db.collection('workouts').doc(workoutId);
      batch.delete(workoutRef);
    }
  }

  Future<void> _removeExercises(
      WriteBatch batch, List<String> exerciseIds) async {
    for (String exerciseId in exerciseIds) {
      DocumentReference exerciseRef =
          _db.collection('exercisesWorkout').doc(exerciseId);
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
