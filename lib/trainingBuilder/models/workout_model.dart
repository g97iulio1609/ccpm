import 'package:cloud_firestore/cloud_firestore.dart';

import 'exercise_model.dart';
import 'superseries_model.dart';

class Workout {
  String? id;
  int order;
  String? name;
  List<Exercise> exercises;
  List<SuperSet> superSets;

  Workout({
    this.id,
    required this.order,
    this.name,
    List<Exercise>? exercises,
    this.superSets = const [],
  }) : exercises = exercises ?? [];

  Workout copyWith({
    String? id,
    int? order,
    String? name,
    List<Exercise>? exercises,
    List<SuperSet>? superSets,
  }) {
    return Workout(
      id: id ?? this.id,
      order: order ?? this.order,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises.map((exercise) => exercise.copyWith()).toList(),
      superSets: superSets ?? this.superSets.map((superSet) => SuperSet.fromMap(superSet.toMap())).toList(),
    );
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'],
      order: map['order'],
      name: map['name'],
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
      order: data['order'] ?? 0,
      name: data['name'],
      exercises: [],  // Exercises will be loaded separately
      superSets: [],  // SuperSets will be loaded separately if needed
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order': order,
      'name': name,  // Add this line
      'exercises': exercises.map((x) => x.toMap()).toList(),
      'superSets': superSets.map((x) => x.toMap()).toList(),
    };
  }
}
