// trainingstoreservices.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'trainingprogrammodel.dart';

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
   if (program.id == null) {
     // If the ID is null, then it's a new document and needs to be added
     var ref = await _db.collection('programs').add({
       'name': program.name,
       'description': program.description,
       'athleteId': program.athleteId,
       'mesocycleNumber': program.mesocycleNumber,
       'createdAt': FieldValue.serverTimestamp(), // Add a server timestamp
     });
     program.id = ref.id; // Update the program's ID with the new document ID
   } else {
     // If the ID is not null, then the document exists and needs to be updated
     await _db.collection('programs').doc(program.id).update({
       'name': program.name,
       'description': program.description,
       'athleteId': program.athleteId,
       'mesocycleNumber': program.mesocycleNumber,
       // Note: createdAt is not updated in an update operation
     });
   }

   // Handle the weeks data
   if (program.weeks != null) {
     for (var week in program.weeks!) {
       if (week.id == null) {
         // If the week ID is null, it's a new week and needs to be added
         var weekRef = await addWeekToProgram(program.id!, week.toMap());
         week.id = weekRef;
       } else {
         // If the week ID is not null, the week exists and needs to be updated
         await updateWeek(week.id!, week.toMap());
       }

       // Handle the workouts data
       if (week.workouts != null) {
         for (var workout in week.workouts!) {
           if (workout.id == null) {
             // If the workout ID is null, it's a new workout and needs to be added
             var workoutRef = await addWorkoutToWeek(week.id!, workout.toMap());
             workout.id = workoutRef;
           } else {
             // If the workout ID is not null, the workout exists and needs to be updated
             await updateWorkout(workout.id!, workout.toMap());
           }

           // Handle the exercises data
           if (workout.exercises != null) {
             for (var exercise in workout.exercises!) {
               if (exercise.id == null) {
                 // If the exercise ID is null, it's a new exercise and needs to be added
                 var exerciseRef = await addExerciseToWorkout(workout.id!, exercise.toMap());
                 exercise.id = exerciseRef;
               } else {
                 // If the exercise ID is not null, the exercise exists and needs to be updated
                 await updateExercise(exercise.id!, exercise.toMap());
               }

               // Handle the series data
               if (exercise.series != null) {
                 for (var series in exercise.series!) {
                   if (series.id == null) {
                     // If the series ID is null, it's a new series and needs to be added
                     var seriesRef = await addSeriesToExercise(exercise.id!, series.toMap());
                     series.id = seriesRef;
                   } else {
                     // If the series ID is not null, the series exists and needs to be updated
                     await updateSeries(series.id!, series.toMap());
                   }
                 }
               }
             }
           }
         }
       }
     }
   }
 }
}