// trainingstoreservices.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trainingModel.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TrainingProgram>> streamTrainingPrograms() {
    return _db.collection('programs').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => TrainingProgram.fromFirestore(doc)).toList());
  }

  Future<String> addProgram(Map<String, dynamic> programData) async {
    DocumentReference ref = await _db.collection('programs').add(programData);
    return ref.id; // Return the new document ID
  }
  Future<String> addWeekToProgram(String programId, Map<String, dynamic> weekData) async {
    DocumentReference ref = await _db.collection('weeks').add({
      ...weekData,
      'programId': programId,
    });
    return ref.id;
  }

  Future<String> addWorkoutToWeek(String weekId, Map<String, dynamic> workoutData) async {
    DocumentReference ref = await _db.collection('workouts').add({
      ...workoutData,
      'weekId': weekId,
    });
    return ref.id;
  }

  Future<String> addExerciseToWorkout(String workoutId, Map<String, dynamic> exerciseData) async {
    DocumentReference ref = await _db.collection('exercisesWorkout').add({
      ...exerciseData,
      'workoutId': workoutId,
    });
    return ref.id;
  }

  Future<String> addSeriesToExercise(String exerciseId, Map<String, dynamic> seriesData) async {
    DocumentReference ref = await _db.collection('series').add({
      ...seriesData,
      'exerciseId': exerciseId,
    });
    return ref.id;
  }
  Future<void> updateProgram(String programId, Map<String, dynamic> programData) async {
    await _db.collection('programs').doc(programId).update(programData);
  }

  Future<void> updateWeek(String weekId, Map<String, dynamic> weekData) async {
    await _db.collection('weeks').doc(weekId).update(weekData);
  }

  Future<void> updateWorkout(String workoutId, Map<String, dynamic> workoutData) async {
    await _db.collection('workouts').doc(workoutId).update(workoutData);
  }

  Future<void> updateExercise(String exerciseId, Map<String, dynamic> exerciseData) async {
    await _db.collection('exercisesWorkout').doc(exerciseId).update(exerciseData);
  }

  Future<void> updateSeries(String seriesId, Map<String, dynamic> seriesData) async {
    await _db.collection('series').doc(seriesId).update(seriesData);
  }

  Future<void> removeProgram(String programId) async {
    await _db.collection('programs').doc(programId).delete();

    var weekSnapshot = await _db.collection('weeks').where('programId', isEqualTo: programId).get();
    for (var weekDoc in weekSnapshot.docs) {
      await removeWeek(weekDoc.id);
    }
  }

  Future<void> removeWeek(String weekId) async {
    await _db.collection('weeks').doc(weekId).delete();

    var workoutSnapshot = await _db.collection('workouts').where('weekId', isEqualTo: weekId).get();
    for (var workoutDoc in workoutSnapshot.docs) {
      await removeWorkout(workoutDoc.id);
    }
  }

  Future<void> removeWorkout(String workoutId) async {
    await _db.collection('workouts').doc(workoutId).delete();

    var exerciseSnapshot = await _db.collection('exercisesWorkout').where('workoutId', isEqualTo: workoutId).get();
    for (var exerciseDoc in exerciseSnapshot.docs) {
      await removeExercise(exerciseDoc.id);
    }
  }
  Future<void> removeExercise(String exerciseId) async {
   await _db.collection('exercisesWorkout').doc(exerciseId).delete();

   var seriesSnapshot = await _db.collection('series').where('exerciseId', isEqualTo: exerciseId).get();
   for (var seriesDoc in seriesSnapshot.docs) {
     await removeSeries(seriesDoc.id);
   }
 }

 Future<void> removeSeries(String seriesId) async {
   await _db.collection('series').doc(seriesId).delete();
 }

 Future<List<TrainingProgram>> fetchTrainingPrograms() async {
   var snapshot = await _db.collection('programs').get();
   return snapshot.docs.map((doc) => TrainingProgram.fromFirestore(doc)).toList();
 }

 Future<List<Week>> fetchWeeksByProgramId(String programId) async {
   var snapshot = await _db.collection('weeks').where('programId', isEqualTo: programId).get();
   return snapshot.docs.map((doc) => Week.fromFirestore(doc)).toList();
 }

 Future<List<Workout>> fetchWorkoutsByWeekId(String weekId) async {
   var snapshot = await _db.collection('workouts').where('weekId', isEqualTo: weekId).get();
   return snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList();
 }

 Future<List<Exercise>> fetchExercisesByWorkoutId(String workoutId) async {
   var snapshot = await _db.collection('exercisesWorkout').where('workoutId', isEqualTo: workoutId).get();
   return snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
 }

 Future<List<Series>> fetchSeriesByExerciseId(String exerciseId) async {
   var snapshot = await _db.collection('series').where('exerciseId', isEqualTo: exerciseId).get();
   return snapshot.docs.map((doc) => Series.fromFirestore(doc)).toList();
 }

Future<void> addOrUpdateTrainingProgram(TrainingProgram program) async {
  FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create or update the program document
  DocumentReference programRef;
  if (program.id == null) {
    // New program
    programRef = await _db.collection('programs').add({
      'name': program.name,
      'description': program.description,
      'athleteId': program.athleteId,
      'mesocycleNumber': program.mesocycleNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
    program.id = programRef.id;
  } else {
    // Existing program
    programRef = _db.collection('programs').doc(program.id);
    await programRef.update({
      'name': program.name,
      'description': program.description,
      'athleteId': program.athleteId,
      'mesocycleNumber': program.mesocycleNumber,
    });
  }

  // Iterate through each week and add or update them independently
  for (var week in program.weeks) {
    DocumentReference weekRef;
    if (week.id == null) {
      // New week
      weekRef = await _db.collection('weeks').add({
        'number': week.number,
        'programId': program.id,
        'createdAt': Timestamp.now(),
      });
      week.id = weekRef.id;
    } else {
      // Existing week
      weekRef = _db.collection('weeks').doc(week.id);
      await weekRef.update({
        'number': week.number,
        'programId': program.id,
      });
    }

    // Iterate through each workout and add or update them independently
    for (var workout in week.workouts) {
      DocumentReference workoutRef;
      if (workout.id == null) {
        // New workout
        workoutRef = await _db.collection('workouts').add({
          'order': workout.order,
          'weekId': week.id,
          'createdAt': Timestamp.now(),
        });
        workout.id = workoutRef.id;
      } else {
        // Existing workout
        workoutRef = _db.collection('workouts').doc(workout.id);
        await workoutRef.update({
          'order': workout.order,
          'weekId': week.id,
        });
      }

      // Iterate through each exercise and add them independently
      for (var exercise in workout.exercises) {
        // New exercise
        DocumentReference exerciseRef = await _db.collection('exercisesWorkout').add({
          'id':exercise.id,
          'name': exercise.name,
          'order': exercise.order,
          'variant': exercise.variant,
          'workoutId': workout.id,
          'createdAt': Timestamp.now(),
        });
        exercise.id = exerciseRef.id;

        // Iterate through each series and add them independently
        for (var series in exercise.series) {
          // New series
          await _db.collection('series').add({
            'reps': series.reps,
            'sets': series.sets,
            'intensity': series.intensity,
            'rpe': series.rpe,
            'weight': series.weight,
            'exerciseId': exercise.id,
            'createdAt': Timestamp.now(),
            'order': series.order,
          });
        }
      }
    }
  }
}

Future<TrainingProgram> fetchTrainingProgram(String programId) async {
  DocumentSnapshot programSnapshot = await _db.collection('programs').doc(programId).get();
  if (!programSnapshot.exists) {
    throw Exception('Training program not found');
  }

  TrainingProgram program = TrainingProgram.fromFirestore(programSnapshot);

  List<Week> weeks = await fetchWeeksByProgramId(programId);
  for (Week week in weeks) {
    List<Workout> workouts = await fetchWorkoutsByWeekId(week.id!);
    for (Workout workout in workouts) {
      List<Exercise> exercises = await fetchExercisesByWorkoutId(workout.id!);
      for (Exercise exercise in exercises) {
        List<Series> seriesList = await fetchSeriesByExerciseId(exercise.id!);
        exercise.series = seriesList;
      }
      workout.exercises = exercises;
    }
    week.workouts = workouts;
  }

  program.weeks = weeks;

  return program;
}


}