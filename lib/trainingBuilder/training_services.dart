import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'training_model.dart';

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
  return snapshot.docs.map((doc) {
    final data = doc.data();
    return Exercise.fromFirestore(doc).copyWith(exerciseId: data['exerciseId']);
  }).toList();
}

 Future<List<Series>> fetchSeriesByExerciseId(String exerciseId) async {
   var snapshot = await _db.collection('series').where('exerciseId', isEqualTo: exerciseId).get();
   return snapshot.docs.map((doc) => Series.fromFirestore(doc)).toList();
 }

Future<void> addOrUpdateTrainingProgram(TrainingProgram program) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  WriteBatch batch = db.batch();

  // Assicurati che il programma abbia un ID univoco
  String programId = program.id?.trim().isEmpty ?? true ? db.collection('programs').doc().id : program.id!;
  program.id = programId; // Aggiorna l'ID nel tuo oggetto programma
  DocumentReference programRef = db.collection('programs').doc(programId);
  batch.set(programRef, {
    'name': program.name,
    'description': program.description,
    'athleteId': program.athleteId,
    'mesocycleNumber': program.mesocycleNumber,
    'hide':program.hide,
  }, SetOptions(merge: true));

  for (var week in program.weeks) {
    String weekId = week.id?.trim().isEmpty ?? true ? db.collection('weeks').doc().id : week.id!;
    week.id = weekId;
    DocumentReference weekRef = db.collection('weeks').doc(weekId);
    batch.set(weekRef, {
      'number': week.number,
      'programId': programId,
    }, SetOptions(merge: true));

    for (var workout in week.workouts) {
      String workoutId = workout.id?.trim().isEmpty ?? true ? db.collection('workouts').doc().id : workout.id!;
      workout.id = workoutId;
      DocumentReference workoutRef = db.collection('workouts').doc(workoutId);
      batch.set(workoutRef, {
        'order': workout.order,
        'weekId': weekId,
      }, SetOptions(merge: true));

      for (var exercise in workout.exercises) {
        String exerciseId = exercise.id?.trim().isEmpty ?? true ? db.collection('exercisesWorkout').doc().id : exercise.id!;
        exercise.id = exerciseId;
        DocumentReference exerciseRef = db.collection('exercisesWorkout').doc(exerciseId);
        batch.set(exerciseRef, {
          'name': exercise.name,
          'order': exercise.order,
          'variant': exercise.variant,
          'workoutId': workoutId,
          'exerciseId': exercise.exerciseId, // Aggiungi questa riga per salvare exerciseId
        }, SetOptions(merge: true));

 for (int i = 0; i < exercise.series.length; i++) {
      var series = exercise.series[i];

      String seriesId;
      if (series.serieId != null && series.serieId!.trim().isNotEmpty) {
        seriesId = series.serieId!;
      } else {
        seriesId = db.collection('series').doc().id;
        series.serieId = seriesId;
      }
      //print('Debug: Saving series ${i + 1} with serieId: $seriesId');

      DocumentReference seriesRef = db.collection('series').doc(seriesId);
      batch.set(seriesRef, {
        'reps': series.reps,
        'sets': series.sets,
        'intensity': series.intensity,
        'rpe': series.rpe,
        'weight': series.weight,
        'exerciseId': exerciseId,
        'serieId': seriesId,
        'order': i + 1, // Usa l'indice della serie come valore per 'order'
        'done': series.done,
        'reps_done': series.reps_done,
        'weight_done': series.weight_done
      }, SetOptions(merge: true));
        }
      }
    }
  }

  await batch.commit();
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

Future<void> removeToDeleteItems(TrainingProgram program) async {
  WriteBatch batch = _db.batch();

  // Add operations to the batch for weeks marked for deletion
  for (String weekId in program.trackToDeleteWeeks) {
    DocumentReference weekRef = _db.collection('weeks').doc(weekId);
    batch.delete(weekRef);
  }
  // Add operations to the batch for workouts marked for deletion
  for (String workoutId in program.trackToDeleteWorkouts) {
    DocumentReference workoutRef = _db.collection('workouts').doc(workoutId);
    batch.delete(workoutRef);
  }
  // Add operations to the batch for exercises marked for deletion
  for (String exerciseId in program.trackToDeleteExercises) {
    DocumentReference exerciseRef = _db.collection('exercisesWorkout').doc(exerciseId);
    batch.delete(exerciseRef);
  }
  // Add operations to the batch for series marked for deletion
  for (String seriesId in program.trackToDeleteSeries) {
    DocumentReference seriesRef = _db.collection('series').doc(seriesId);
    batch.delete(seriesRef);
  }

  // Commit the batch
  await batch.commit();
}


}