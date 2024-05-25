import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementModel {
  final String id;
  final String userId;
  final DateTime date;
  final double weight;
  final double height;
  final double bmi;
  final double bodyFatPercentage;
  final double waistCircumference;
  final double hipCircumference;
  final double chestCircumference;
  final double bicepsCircumference;

  MeasurementModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.bodyFatPercentage,
    required this.waistCircumference,
    required this.hipCircumference,
    required this.chestCircumference,
    required this.bicepsCircumference,
  });

  factory MeasurementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeasurementModel(
      id: doc.id,
      userId: data['userId'],
      date: (data['date'] as Timestamp).toDate(),
      weight: data['weight'],
      height: data['height'],
      bmi: data['bmi'],
      bodyFatPercentage: data['bodyFatPercentage'],
      waistCircumference: data['waistCircumference'],
      hipCircumference: data['hipCircumference'],
      chestCircumference: data['chestCircumference'],
      bicepsCircumference: data['bicepsCircumference'],
    );
  }
}