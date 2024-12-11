import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseRecord {
  final String id;
  final String exerciseId;
  final num maxWeight;
  final int repetitions;
  final DateTime date;

  ExerciseRecord({
    required this.id,
    required this.exerciseId,
    required this.maxWeight,
    required this.repetitions,
    required this.date,
  });

  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'exerciseId':
        return exerciseId;
      case 'maxWeight':
        return maxWeight;
      case 'repetitions':
        return repetitions;
      case 'date':
        return date;
      default:
        return null;
    }
  }

  factory ExerciseRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExerciseRecord(
      id: doc.id,
      exerciseId: data['exerciseId'],
      maxWeight: data['maxWeight'],
      repetitions: data['repetitions'],
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'maxWeight': maxWeight,
      'repetitions': repetitions,
      'date': Timestamp.fromDate(date),
    };
  }
}
