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

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      bmi: (json['bmi'] as num).toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num).toDouble(),
      waistCircumference: (json['waistCircumference'] as num).toDouble(),
      hipCircumference: (json['hipCircumference'] as num).toDouble(),
      chestCircumference: (json['chestCircumference'] as num).toDouble(),
      bicepsCircumference: (json['bicepsCircumference'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'bodyFatPercentage': bodyFatPercentage,
      'waistCircumference': waistCircumference,
      'hipCircumference': hipCircumference,
      'chestCircumference': chestCircumference,
      'bicepsCircumference': bicepsCircumference,
    };
  }

  MeasurementModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    double? height,
    double? bmi,
    double? bodyFatPercentage,
    double? waistCircumference,
    double? hipCircumference,
    double? chestCircumference,
    double? bicepsCircumference,
  }) {
    return MeasurementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      waistCircumference: waistCircumference ?? this.waistCircumference,
      hipCircumference: hipCircumference ?? this.hipCircumference,
      chestCircumference: chestCircumference ?? this.chestCircumference,
      bicepsCircumference: bicepsCircumference ?? this.bicepsCircumference,
    );
  }
}
