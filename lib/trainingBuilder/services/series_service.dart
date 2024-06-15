import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/series_model.dart';

class SeriesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> addSeriesToExercise(
      String exerciseId, Map<String, dynamic> seriesData) async {
    DocumentReference ref = await _db.collection('series').add({
      ...seriesData,
      'exerciseId': exerciseId,
    });
    return ref.id;
  }

  Future<void> updateSeries(
      String seriesId, Map<String, dynamic> seriesData) async {
    await _db.collection('series').doc(seriesId).update(seriesData);
  }

  Future<void> removeSeries(String seriesId) async {
    await _db.collection('series').doc(seriesId).delete();
  }

  Future<List<Series>> fetchSeriesByExerciseId(String exerciseId) async {
    var snapshot = await _db
        .collection('series')
        .where('exerciseId', isEqualTo: exerciseId)
        .orderBy('order')
        .get();
    var seriesList =
        snapshot.docs.map((doc) => Series.fromFirestore(doc)).toList();
    return seriesList;
  }
}
