import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/measurement_model.dart';

class MeasurementsService {
  final FirebaseFirestore _firestore;

  MeasurementsService(this._firestore);

  Future<List<MeasurementModel>> getMeasurements(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('measurements')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => MeasurementModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      throw Exception('Errore nel recupero delle misurazioni: $e');
    }
  }

  Future<void> addMeasurement({
    required String userId,
    required DateTime date,
    required double weight,
    required double height,
    required double bmi,
    required double bodyFatPercentage,
    required double waistCircumference,
    required double hipCircumference,
    required double chestCircumference,
    required double bicepsCircumference,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('measurements')
          .add({
            'date': Timestamp.fromDate(date),
            'weight': weight,
            'height': height,
            'bmi': bmi,
            'bodyFatPercentage': bodyFatPercentage,
            'waistCircumference': waistCircumference,
            'hipCircumference': hipCircumference,
            'chestCircumference': chestCircumference,
            'bicepsCircumference': bicepsCircumference,
          });
    } catch (e) {
      throw Exception('Errore nell\'aggiunta della misurazione: $e');
    }
  }

  Future<void> updateMeasurement({
    required String userId,
    required String measurementId,
    required DateTime date,
    required double weight,
    required double height,
    required double bmi,
    required double bodyFatPercentage,
    required double waistCircumference,
    required double hipCircumference,
    required double chestCircumference,
    required double bicepsCircumference,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('measurements')
          .doc(measurementId)
          .update({
            'date': Timestamp.fromDate(date),
            'weight': weight,
            'height': height,
            'bmi': bmi,
            'bodyFatPercentage': bodyFatPercentage,
            'waistCircumference': waistCircumference,
            'hipCircumference': hipCircumference,
            'chestCircumference': chestCircumference,
            'bicepsCircumference': bicepsCircumference,
          });
    } catch (e) {
      throw Exception('Errore nell\'aggiornamento della misurazione: $e');
    }
  }

  Future<void> deleteMeasurement({
    required String userId,
    required String measurementId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('measurements')
          .doc(measurementId)
          .delete();
    } catch (e) {
      throw Exception('Errore nella cancellazione della misurazione: $e');
    }
  }
}

final measurementsServiceProvider = Provider<MeasurementsService>((ref) {
  return MeasurementsService(FirebaseFirestore.instance);
});
