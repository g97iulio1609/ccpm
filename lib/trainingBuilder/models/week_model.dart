import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout_model.dart';

class Week {
  String? id;
  int number;
  List<Workout> workouts;

  Week({
    this.id,
    required this.number,
    List<Workout>? workouts,
  }) : workouts = workouts ?? [];

  Week copyWith({
    String? id,
    int? number,
    List<Workout>? workouts,
  }) {
    return Week(
      id: id ?? this.id,
      number: number ?? this.number,
      workouts: workouts ?? this.workouts.map((workout) => workout.copyWith()).toList(),
    );
  }

  factory Week.fromMap(Map<String, dynamic> map) {
    return Week(
      id: map['id'],
      number: map['number'],
      workouts: List<Workout>.from(
          map['workouts']?.map((x) => Workout.fromMap(x)) ?? []),
    );
  }

  factory Week.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Week(
      id: doc.id,
      number: data['number'],
      workouts: (data['workouts'] as List<dynamic>? ?? [])
          .map((doc) => Workout.fromFirestore(doc))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'workouts': workouts.map((x) => x.toMap()).toList(),
    };
  }
}
