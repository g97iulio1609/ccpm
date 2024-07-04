import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_model.dart';
import 'superseries_model.dart';

class Workout {
  String? id;
  int order;
  List<Exercise> exercises;
  List<SuperSet> superSets;

  Workout({
    this.id,
    required this.order,
    List<Exercise>? exercises,
    this.superSets = const [],
  }) : exercises = exercises ?? [];

  Workout copyWith({
    String? id,
    int? order,
    List<Exercise>? exercises,
    List<SuperSet>? superSets,
  }) {
    return Workout(
      id: id ?? this.id,
      order: order ?? this.order,
      exercises: exercises ?? this.exercises.map((exercise) => exercise.copyWith()).toList(),
      superSets: superSets ?? this.superSets.map((superSet) => SuperSet.fromMap(superSet.toMap())).toList(),
    );
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      order: map['order'],
      exercises: List<Exercise>.from(
          map['exercises']?.map((x) => Exercise.fromMap(x)) ?? []),
      superSets: List<SuperSet>.from(
        (map['superSets'] ?? []).map((x) => SuperSet.fromMap(x)),
      ),
    );
  }

  factory Workout.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Workout(
      id: doc.id,
      order: data['order'],
      exercises: (data['exercises'] as List<dynamic>? ?? [])
          .map((doc) => Exercise.fromFirestore(doc))
          .toList(),
      superSets: (data['superSets'] as List<dynamic>? ?? [])
          .map((doc) => SuperSet.fromMap(doc))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order': order,
      'exercises': exercises.map((x) => x.toMap()).toList(),
      'superSets': superSets.map((x) => x.toMap()).toList(),
    };
  }
}
