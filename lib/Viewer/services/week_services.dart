import 'package:cloud_firestore/cloud_firestore.dart';

class WeekService {
  Stream<QuerySnapshot> getWorkouts(String weekId) {
    return FirebaseFirestore.instance
        .collection('workouts')
        .where('weekId', isEqualTo: weekId)
        .orderBy('order')
        .snapshots();
  }
}
