import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphanessone/shared/shared.dart';

class SeriesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> addSeriesToExercise(String exerciseId, Series series,
      {String? originalExerciseId}) async {
    // Assicuriamoci che l'originalExerciseId sia impostato
    if (originalExerciseId != null) {
      series = series.copyWith(originalExerciseId: originalExerciseId);
    }

    // Use the toFirestore method from the Series class
    Map<String, dynamic> seriesData = series.toFirestore();
    seriesData['exerciseId'] =
        exerciseId; // Add the exerciseId for the relationship

    DocumentReference ref = await _db.collection('series').add(seriesData);
    return ref.id;
  }

  Future<void> updateSeries(String seriesId, Series series) async {
    // Use the toFirestore method from the Series class
    await _db.collection('series').doc(seriesId).update(series.toFirestore());
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
