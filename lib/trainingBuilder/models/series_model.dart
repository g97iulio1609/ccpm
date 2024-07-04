import 'package:cloud_firestore/cloud_firestore.dart';

class Series {
  String? id;
  String? serieId;
  int reps;
  int sets;
  String intensity;
  String rpe;
  double weight;
  int order;
  bool done;
  int reps_done;
  double weight_done;

  Series({
    this.id,
    required this.serieId,
    required this.reps,
    required this.sets,
    required this.intensity,
    required this.rpe,
    required this.weight,
    required this.order,
    this.done = false,
    this.reps_done = 0,
    this.weight_done = 0.0,
  });

  factory Series.fromMap(Map<String, dynamic> map) {
    return Series(
      id: map['id'],
      serieId: map['serieId'] ?? '',
      reps: int.tryParse(map['reps']?.toString() ?? '0') ?? 0,
      sets: int.tryParse(map['sets']?.toString() ?? '0') ?? 0,
      intensity: map['intensity'] ?? '',
      rpe: map['rpe'] ?? '',
      weight: map['weight']?.toDouble() ?? 0.0,
      order: int.tryParse(map['order']?.toString() ?? '0') ?? 0,
      done: map['done'] ?? false,
      reps_done: int.tryParse(map['reps_done']?.toString() ?? '0') ?? 0,
      weight_done: map['weight_done']?.toDouble() ?? 0.0,
    );
  }

  Series copyWith({
    String? serieId,
    int? reps,
    int? sets,
    String? intensity,
    String? rpe,
    double? weight,
    int? order,
    bool? done,
    int? reps_done,
    double? weight_done,
  }) {
    return Series(
      serieId: serieId ?? this.serieId,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      intensity: intensity ?? this.intensity,
      rpe: rpe ?? this.rpe,
      weight: weight ?? this.weight,
      order: order ?? this.order,
      done: done ?? this.done,
      reps_done: reps_done ?? this.reps_done,
      weight_done: weight_done ?? this.weight_done,
    );
  }

  factory Series.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Series(
      id: doc.id,
      serieId: data['serieId'] ?? '',
      reps: int.tryParse(data['reps']?.toString() ?? '0') ?? 0,
      sets: int.tryParse(data['sets']?.toString() ?? '0') ?? 0,
      intensity: data['intensity'] ?? '',
      rpe: data['rpe'] ?? '',
      weight: data['weight']?.toDouble() ?? 0.0,
      order: int.tryParse(data['order']?.toString() ?? '0') ?? 0,
      done: data['done'] ?? false,
      reps_done: int.tryParse(data['reps_done']?.toString() ?? '0') ?? 0,
      weight_done: data['weight_done']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,'serieId': serieId,
      'reps': reps,
      'sets': sets,
      'intensity': intensity,
      'rpe': rpe,
      'weight': weight,
      'order': order,
      'done': done,
      'reps_done': reps_done,
      'weight_done': weight_done,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reps': reps,
      'sets': sets,
      'intensity': intensity,
      'rpe': rpe,
      'weight': weight,
      'id': id,
      'serieId': serieId,
      'order': order,
      'done': done,
      'reps_done': reps_done,
      'weight_done': weight_done,
    };
  }
}