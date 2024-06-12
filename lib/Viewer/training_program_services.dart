import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingService {
  Future<List<Map<String, dynamic>>> fetchTrainingWeeks(String programId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('weeks')
        .where('programId', isEqualTo: programId)
        .orderBy('number')
        .get();

    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }
}
