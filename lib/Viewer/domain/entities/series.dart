import 'package:cloud_firestore/cloud_firestore.dart';

class Series {
  final String id;
  final String exerciseId; // ID dell'esercizio a cui questa serie appartiene
  final String?
      originalExerciseId; // ID dell'esercizio originale se è stato sostituito
  final int order; // Ordine della serie all'interno dell'esercizio

  // Valori target
  final int reps;
  final int? maxReps;
  final double weight;
  final double? maxWeight;
  final String? intensity; // es. "80%"
  final String? maxIntensity;
  final String? rpe; // es. "8"
  final String? rpeMax;
  final int? restTimeSeconds; // Tempo di riposo dopo questa serie
  final String? type; // es. 'normal', 'drop_set', 'myo_reps'

  // Valori eseguiti dall'utente
  final int? repsDone;
  final double? weightDone;
  final bool isCompleted;

  Series({
    required this.id,
    required this.exerciseId,
    this.originalExerciseId,
    required this.order,
    required this.reps,
    this.maxReps,
    required this.weight,
    this.maxWeight,
    this.intensity,
    this.maxIntensity,
    this.rpe,
    this.rpeMax,
    this.restTimeSeconds,
    this.type,
    this.repsDone,
    this.weightDone,
    this.isCompleted = false,
  });

  factory Series.empty() {
    return Series(
      id: '',
      exerciseId: '',
      order: 0,
      reps: 0,
      weight: 0.0,
      isCompleted: false,
    );
  }

  Series copyWith({
    String? id,
    String? exerciseId,
    String? originalExerciseId,
    int? order,
    int? reps,
    int? maxReps,
    double? weight,
    double? maxWeight,
    String? intensity,
    String? maxIntensity,
    String? rpe,
    String? rpeMax,
    int? restTimeSeconds,
    String? type,
    int? repsDone,
    double? weightDone,
    bool? isCompleted,
  }) {
    return Series(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      originalExerciseId: originalExerciseId ?? this.originalExerciseId,
      order: order ?? this.order,
      reps: reps ?? this.reps,
      maxReps: maxReps ?? this.maxReps,
      weight: weight ?? this.weight,
      maxWeight: maxWeight ?? this.maxWeight,
      intensity: intensity ?? this.intensity,
      maxIntensity: maxIntensity ?? this.maxIntensity,
      rpe: rpe ?? this.rpe,
      rpeMax: rpeMax ?? this.rpeMax,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      type: type ?? this.type,
      repsDone: repsDone ?? this.repsDone,
      weightDone: weightDone ?? this.weightDone,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id' non viene solitamente salvato nella mappa, è l'ID del documento
      'exerciseId': exerciseId,
      'originalExerciseId': originalExerciseId,
      'order': order,
      'reps': reps,
      'maxReps': maxReps,
      'weight': weight,
      'maxWeight': maxWeight,
      'intensity': intensity,
      'maxIntensity': maxIntensity,
      'rpe': rpe,
      'rpeMax': rpeMax,
      'restTimeSeconds': restTimeSeconds,
      'type': type,
      'reps_done': repsDone, // Firestore usa snake_case per convenzione
      'weight_done': weightDone,
      'done': isCompleted, // 'done' è il campo usato in Firestore
    };
  }

  factory Series.fromMap(Map<String, dynamic> map, String documentId) {
    return Series(
      id: documentId,
      exerciseId: map['exerciseId'] as String,
      originalExerciseId: map['originalExerciseId'] as String?,
      order: map['order'] as int,
      reps: map['reps'] as int,
      maxReps: map['maxReps'] as int?,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      maxWeight: (map['maxWeight'] as num?)?.toDouble(),
      intensity: map['intensity'] as String?,
      maxIntensity: map['maxIntensity'] as String?,
      rpe: map['rpe'] as String?,
      rpeMax: map['rpeMax'] as String?,
      restTimeSeconds: map['restTimeSeconds'] as int?,
      type: map['type'] as String?,
      repsDone: map['reps_done'] as int?,
      weightDone: (map['weight_done'] as num?)?.toDouble(),
      isCompleted: map['done'] as bool? ?? false,
    );
  }
}
