import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseService {
  Future<void> updateSeriesData(String seriesId, int? repsDone, double? weightDone) async {
    await FirebaseFirestore.instance.collection('series').doc(seriesId).update({
      'done': repsDone != null && weightDone != null,
      'reps_done': repsDone,
      'weight_done': weightDone,
    });
  }
}
