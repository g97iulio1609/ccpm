import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_record.dart';

class ExerciseRecordService {
  final FirebaseFirestore _firestore;

  ExerciseRecordService(this._firestore);

  Stream<List<ExerciseRecord>> getExerciseRecords({
    required String userId,
    required String exerciseId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ExerciseRecord.fromFirestore(doc)).toList());
  }

  Future<void> addExerciseRecord({
    required String userId,
    required String exerciseId,
    required String exerciseName,
    required num maxWeight,
    required int repetitions,
    required String date,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .add({
      'date': date,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'maxWeight': maxWeight,
      'repetitions': repetitions,
      'userId': userId,
    });
    await _updateCurrentProgramWeights(userId, exerciseId, maxWeight);
  }

  Future<void> updateExerciseRecord({
    required String userId,
    required String exerciseId,
    required String recordId,
    required num maxWeight,
    required int repetitions,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .doc(recordId)
        .update({
      'maxWeight': maxWeight,
      'repetitions': repetitions,
    });
    await _updateCurrentProgramWeights(userId, exerciseId, maxWeight);
  }

  Future<ExerciseRecord?> getLatestExerciseRecord({
    required String userId,
    required String exerciseId,
  }) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return ExerciseRecord.fromFirestore(snapshot.docs.first);
    } else {
      return null;
    }
  }

  Future<void> deleteExerciseRecord({
    required String userId,
    required String exerciseId,
    required String recordId,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .doc(recordId)
        .delete();
  }

  Future<void> _updateCurrentProgramWeights(String userId, String exerciseId, num newMaxWeight) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentProgramId = userDoc.data()?['currentProgram'];
    if (currentProgramId != null) {
      await _updateWeeksWeights(currentProgramId, exerciseId, newMaxWeight);
    }
  }

  Future<List<Map<String, dynamic>>> _updateWeeksWeights(
      String programId, String exerciseId, num newMaxWeight) async {
    final weeksSnapshot = await _firestore
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .get();
    return await Future.wait(weeksSnapshot.docs.map((weekDoc) async {
      final weekData = weekDoc.data();
      final updatedWorkouts = await _updateWorkoutsWeights(weekDoc.id, exerciseId, newMaxWeight);
      return {
        'id': weekDoc.id,
        ...weekData,
        'workouts': updatedWorkouts.map((workout) => workout['id']).toList(),
      };
    }));
  }

  Future<List<Map<String, dynamic>>> _updateWorkoutsWeights(
      String weekId, String exerciseId, num newMaxWeight) async {
    final workoutsSnapshot = await _firestore
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .get();
    return await Future.wait(workoutsSnapshot.docs.map((workoutDoc) async {
      final workoutData = workoutDoc.data();
      final updatedExercises = await _updateExercisesWeights(workoutDoc.id, exerciseId, newMaxWeight);
      return {
        'id': workoutDoc.id,
        ...workoutData,
        'exercises': updatedExercises.map((exercise) => exercise['id']).toList(),
      };
    }));
  }

  Future<List<Map<String, dynamic>>> _updateExercisesWeights(
      String workoutId, String exerciseId, num newMaxWeight) async {
    final exercisesSnapshot = await _firestore
        .collection('exercisesWorkout')
        .where('workoutId', isEqualTo: workoutId)
        .get();
    return await Future.wait(exercisesSnapshot.docs.map((exerciseDoc) async {
      final exerciseData = exerciseDoc.data();
      if (exerciseData['exerciseId'] == exerciseId) {
        final updatedSeries = await _updateSeriesWeights(exerciseDoc.id, newMaxWeight);
        return {
          'id': exerciseDoc.id,
          ...exerciseData,
          'series': updatedSeries.map((serie) => serie['id']).toList(),
        };
      }
      return {
        'id': exerciseDoc.id,
        ...exerciseData,
      };
    }));
  }

  Future<List<Map<String, dynamic>>> _updateSeriesWeights(
      String exerciseWorkoutId, num newMaxWeight) async {
    final seriesSnapshot = await _firestore
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseWorkoutId)
        .get();
    return await Future.wait(seriesSnapshot.docs.map((serieDoc) async {
      final serieData = serieDoc.data();
      final intensity = double.parse(serieData['intensity']);
      final calculatedWeight = (newMaxWeight * intensity) / 100;
      await _firestore.collection('series').doc(serieDoc.id).update({'weight': calculatedWeight});
      return {
        'id': serieDoc.id,
        ...serieData,
        'weight': calculatedWeight,
      };
    }));
  }
}
