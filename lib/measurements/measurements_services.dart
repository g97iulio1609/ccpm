import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/measurement_model.dart';

class MeasurementsService {
  final FirebaseFirestore _firestore;

  MeasurementsService(this._firestore);

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
          'userId': userId,
        });
  }

  Future<String> addMeasurement({
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
    final measurementData = {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'bodyFatPercentage': bodyFatPercentage,
      'waistCircumference': waistCircumference,
      'hipCircumference': hipCircumference,
      'chestCircumference': chestCircumference,
      'bicepsCircumference': bicepsCircumference,
      'userId': userId,
    };

    final measurementDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .add(measurementData);

    return measurementDoc.id;
  }

  Stream<List<MeasurementModel>> getMeasurements({required String userId}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MeasurementModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Future<void> deleteMeasurement({required String userId, required String measurementId}) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('measurements')
        .doc(measurementId)
        .delete();
  }
}
