import 'package:cloud_firestore/cloud_firestore.dart';

class Series {
  String? id;
  String serieId;
  String? originalExerciseId;
  String? exerciseId;
  int reps;
  int sets;
  String intensity;
  String rpe;
  double weight;
  int order;
  bool done;
  int reps_done;
  double weight_done;

  // New fields for ranges
  int? maxReps;
  int? maxSets;
  String? maxIntensity;
  String? maxRpe;
  double? maxWeight;

  Series({
    this.id,
    required this.serieId,
    this.originalExerciseId,
    this.exerciseId,
    required this.reps,
    required this.sets,
    required this.intensity,
    required this.rpe,
    required this.weight,
    required this.order,
    this.done = false,
    this.reps_done = 0,
    this.weight_done = 0.0,
    this.maxReps,
    this.maxSets,
    this.maxIntensity,
    this.maxRpe,
    this.maxWeight,
  });

  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      id: map['id'],
      serieId: map['serieId'] ?? '',
      originalExerciseId: map['originalExerciseId'],
      exerciseId: map['exerciseId'],
      reps: map['reps'] ?? 0,
      sets: map['sets'] ?? 1,
      intensity: map['intensity'] ?? '0',
      rpe: map['rpe'] ?? '0',
      weight: (map['weight'] ?? 0.0).toDouble(),
      order: map['order'] ?? 0,
      done: map['done'] ?? false,
      reps_done: map['reps_done'] ?? 0,
      weight_done: (map['weight_done'] ?? 0.0).toDouble(),
      maxReps: map['maxReps'],
      maxSets: map['maxSets'],
      maxIntensity: map['maxIntensity'],
      maxRpe: map['maxRpe'],
      maxWeight: map['maxWeight']?.toDouble(),
    );
  }

  factory Series.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Series(
      id: doc.id,
      serieId: data['serieId'] ?? '',
      originalExerciseId: data['originalExerciseId'],
      exerciseId: data['exerciseId'],
      reps: data['reps'] ?? 0,
      sets: data['sets'] ?? 1,
      intensity: data['intensity'] ?? '0',
      rpe: data['rpe'] ?? '0',
      weight: (data['weight'] ?? 0.0).toDouble(),
      order: data['order'] ?? 0,
      done: data['done'] ?? false,
      reps_done: data['reps_done'] ?? 0,
      weight_done: (data['weight_done'] ?? 0.0).toDouble(),
      maxReps: data['maxReps'],
      maxSets: data['maxSets'],
      maxIntensity: data['maxIntensity'],
      maxRpe: data['maxRpe'],
      maxWeight: data['maxWeight']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serieId': serieId,
      'originalExerciseId': originalExerciseId,
      'exerciseId': exerciseId,
      'reps': reps,
      'sets': sets,
      'intensity': intensity,
      'rpe': rpe,
      'weight': weight,
      'order': order,
      'done': done,
      'reps_done': reps_done,
      'weight_done': weight_done,
      'maxReps': maxReps,
      'maxSets': maxSets,
      'maxIntensity': maxIntensity,
      'maxRpe': maxRpe,
      'maxWeight': maxWeight,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serieId': serieId,
      'originalExerciseId': originalExerciseId,
      'exerciseId': exerciseId,
      'reps': reps,
      'sets': sets,
      'intensity': intensity,
      'rpe': rpe,
      'weight': weight,
      'order': order,
      'done': done,
      'reps_done': reps_done,
      'weight_done': weight_done,
      'maxReps': maxReps,
      'maxSets': maxSets,
      'maxIntensity': maxIntensity,
      'maxRpe': maxRpe,
      'maxWeight': maxWeight,
    };
  }

  Series copyWith({
    String? id,
    String? serieId,
    String? originalExerciseId,
    String? exerciseId,
    int? reps,
    int? sets,
    String? intensity,
    String? rpe,
    double? weight,
    int? order,
    bool? done,
    int? reps_done,
    double? weight_done,
    int? maxReps,
    int? maxSets,
    String? maxIntensity,
    String? maxRpe,
    double? maxWeight,
  }) {
    return Series(
      id: id ?? this.id,
      serieId: serieId ?? this.serieId,
      originalExerciseId: originalExerciseId ?? this.originalExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      intensity: intensity ?? this.intensity,
      rpe: rpe ?? this.rpe,
      weight: weight ?? this.weight,
      order: order ?? this.order,
      done: done ?? this.done,
      reps_done: reps_done ?? this.reps_done,
      weight_done: weight_done ?? this.weight_done,
      maxReps: maxReps ?? this.maxReps,
      maxSets: maxSets ?? this.maxSets,
      maxIntensity: maxIntensity ?? this.maxIntensity,
      maxRpe: maxRpe ?? this.maxRpe,
      maxWeight: maxWeight ?? this.maxWeight,
    );
  }

  @override
  String toString() {
    return 'Series(id: $id, serieId: $serieId, originalExerciseId: $originalExerciseId, exerciseId: $exerciseId, reps: $reps, sets: $sets, intensity: $intensity, rpe: $rpe, weight: $weight, order: $order, done: $done, reps_done: $reps_done, weight_done: $weight_done, maxReps: $maxReps, maxSets: $maxSets, maxIntensity: $maxIntensity, maxRpe: $maxRpe, maxWeight: $maxWeight)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Series &&
      other.id == id &&
      other.serieId == serieId &&
      other.originalExerciseId == originalExerciseId &&
      other.exerciseId == exerciseId &&
      other.reps == reps &&
      other.sets == sets &&
      other.intensity == intensity &&
      other.rpe == rpe &&
      other.weight == weight &&
      other.order == order &&
      other.done == done &&
      other.reps_done == reps_done &&
      other.weight_done == weight_done &&
      other.maxReps == maxReps &&
      other.maxSets == maxSets &&
      other.maxIntensity == maxIntensity &&
      other.maxRpe == maxRpe &&
      other.maxWeight == maxWeight;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      serieId.hashCode ^
      originalExerciseId.hashCode ^
      exerciseId.hashCode ^
      reps.hashCode ^
      sets.hashCode ^
      intensity.hashCode ^
      rpe.hashCode ^
      weight.hashCode ^
      order.hashCode ^
      done.hashCode ^
      reps_done.hashCode ^
      weight_done.hashCode ^
      maxReps.hashCode ^
      maxSets.hashCode ^
      maxIntensity.hashCode ^
      maxRpe.hashCode ^
      maxWeight.hashCode;
  }
}