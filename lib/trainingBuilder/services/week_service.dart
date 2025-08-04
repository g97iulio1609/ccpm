import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphanessone/shared/shared.dart';

class WeekService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> addWeekToProgram(
      String programId, Map<String, dynamic> weekData) async {
    DocumentReference ref = await _db.collection('weeks').add({
      ...weekData,
      'programId': programId,
    });
    return ref.id;
  }

  Future<void> updateWeek(String weekId, Map<String, dynamic> weekData) async {
    await _db.collection('weeks').doc(weekId).update(weekData);
  }

  Future<void> removeWeek(String weekId) async {
    await _db.collection('weeks').doc(weekId).delete();
  }

  Future<List<Week>> fetchWeeksByProgramId(String programId) async {
    var snapshot = await _db
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .orderBy('number')
        .get();
    var weeks = snapshot.docs.map((doc) => Week.fromFirestore(doc)).toList();
    return weeks;
  }
}
