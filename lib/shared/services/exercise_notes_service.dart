import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseNotesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, String>> fetchNotesForWorkout(String workoutId) async {
    final snapshot = await _db
        .collection('exercise_notes')
        .where('workoutId', isEqualTo: workoutId)
        .get();
    final notes = <String, String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final exerciseId = data['exerciseId'] as String?;
      final note = data['note'] as String?;
      if (exerciseId != null && note != null) {
        notes[exerciseId] = note;
      }
    }
    return notes;
  }

  Stream<Map<String, String>> notesStreamForWorkout(String workoutId) {
    return _db
        .collection('exercise_notes')
        .where('workoutId', isEqualTo: workoutId)
        .snapshots()
        .map((snapshot) {
      final notes = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final exerciseId = data['exerciseId'] as String?;
        final note = data['note'] as String?;
        if (exerciseId != null && note != null) {
          notes[exerciseId] = note;
        }
      }
      return notes;
    });
  }

  Future<void> saveNote({
    required String workoutId,
    required String exerciseId,
    required String note,
  }) async {
    await _db.collection('exercise_notes').doc('${workoutId}_$exerciseId').set({
      'workoutId': workoutId,
      'exerciseId': exerciseId,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote({
    required String workoutId,
    required String exerciseId,
  }) async {
    await _db.collection('exercise_notes').doc('${workoutId}_$exerciseId').delete();
  }
}


