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
    await _addOrUpdateRecord(
      userId: userId,
      exerciseId: exerciseId,
      data: {
        'date': Timestamp.fromDate(DateTime.parse(date)),
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'maxWeight': maxWeight,
        'repetitions': repetitions,
        'userId': userId,
      },
    );
  }

  Future<void> updateExerciseRecord({
    required String userId,
    required String exerciseId,
    required String recordId,
    required num maxWeight,
    required int repetitions,
  }) async {
    await _addOrUpdateRecord(
      userId: userId,
      exerciseId: exerciseId,
      recordId: recordId,
      data: {'maxWeight': maxWeight, 'repetitions': repetitions},
    );
  }

  Future<void> updateIntensityForProgram(String userId, String exerciseId, num newMaxWeight) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentProgramId = userDoc.data()?['currentProgram'];
    if (currentProgramId != null) {
      await _updateIntensityForProgram(currentProgramId, exerciseId, newMaxWeight);
    }
  }

  Future<void> updateWeightsForProgram(String userId, String exerciseId, num newMaxWeight) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentProgramId = userDoc.data()?['currentProgram'];
    if (currentProgramId != null) {
      await _updateWeightsForProgram(currentProgramId, exerciseId, newMaxWeight);
    }
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

  Future<void> _addOrUpdateRecord({
    required String userId,
    required String exerciseId,
    String? recordId,
    required Map<String, dynamic> data,
  }) async {
    final recordRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('records')
        .doc(recordId);

    if (recordId == null) {
      await recordRef.set(data);
    } else {
      await recordRef.update(data);
    }
  }

  Future<void> _updateIntensityForProgram(
    String programId,
    String exerciseId,
    num newMaxWeight,
  ) async {
    final weeks = await _getDocuments('weeks', 'programId', programId);
    for (var week in weeks) {
      final workouts = await _getDocuments('workouts', 'weekId', week.id);
      for (var workout in workouts) {
        final exercises = await _getDocuments('exercisesWorkout', 'workoutId', workout.id);
        for (var exercise in exercises) {
          if (exercise['exerciseId'] == exerciseId) {
            final series = await _getDocuments('series', 'exerciseId', exercise.id);
            for (var serie in series) {
              final weight = serie['weight'];
              final newIntensity = ((weight / newMaxWeight) * 100).toStringAsFixed(2);
              await _firestore.collection('series').doc(serie.id).update({
                'intensity': newIntensity,
              });
            }
          }
        }
      }
    }
  }

  Future<void> _updateWeightsForProgram(
    String programId,
    String exerciseId,
    num newMaxWeight,
  ) async {
    final weeks = await _getDocuments('weeks', 'programId', programId);
    for (var week in weeks) {
      final workouts = await _getDocuments('workouts', 'weekId', week.id);
      for (var workout in workouts) {
        final exercises = await _getDocuments('exercisesWorkout', 'workoutId', workout.id);
        for (var exercise in exercises) {
          if (exercise['exerciseId'] == exerciseId) {
            final series = await _getDocuments('series', 'exerciseId', exercise.id);
            for (var serie in series) {
              final intensity = double.parse(serie['intensity']);
              final calculatedWeight = (newMaxWeight * intensity) / 100;
              await _firestore.collection('series').doc(serie.id).update({
                'weight': calculatedWeight,
              });
            }
          }
        }
      }
    }
  }

  Future<List<DocumentSnapshot>> _getDocuments(
    String collection,
    String field,
    String value,
  ) async {
    final snapshot = await _firestore.collection(collection).where(field, isEqualTo: value).get();
    return snapshot.docs;
  }
}
