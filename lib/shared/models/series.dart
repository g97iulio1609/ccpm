import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified Series model combining features from trainingBuilder and Viewer
/// Eliminates code duplication while maintaining backward compatibility
class Series {
  // Core identification fields
  final String? id;
  final String? serieId; // TrainingBuilder compatibility
  final String exerciseId;
  final String? originalExerciseId;
  final int order;

  // Target values (what should be performed)
  final int reps;
  final int? maxReps;
  final int sets;
  final int? maxSets;
  final double weight;
  final double? maxWeight;
  final String? intensity;
  final String? maxIntensity;
  final String? rpe;
  final String? maxRpe;
  final String? rpeMax; // Viewer compatibility

  // Execution values (what was actually performed)
  final int repsDone;
  final double weightDone;
  final bool done; // TrainingBuilder naming
  final bool isCompleted; // Viewer naming

  // Additional fields
  final int? restTimeSeconds;
  final String? type; // 'normal', 'drop_set', 'myo_reps', etc.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Series({
    this.id,
    this.serieId,
    required this.exerciseId,
    this.originalExerciseId,
    required this.order,
    required this.reps,
    this.maxReps,
    this.sets = 1,
    this.maxSets,
    required this.weight,
    this.maxWeight,
    this.intensity,
    this.maxIntensity,
    this.rpe,
    this.maxRpe,
    this.rpeMax,
    this.repsDone = 0,
    this.weightDone = 0.0,
    this.done = false,
    this.isCompleted = false,
    this.restTimeSeconds,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor for empty series
  factory Series.empty() {
    return const Series(exerciseId: '', order: 0, reps: 0, weight: 0.0);
  }

  /// Factory constructor from Firestore document
  factory Series.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Series.fromMap(data, doc.id);
  }

  /// Factory constructor from Map with optional document ID
  factory Series.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Series(
      id: documentId ?? map['id'],
      serieId: map['serieId'],
      exerciseId: map['exerciseId'] ?? '',
      originalExerciseId: map['originalExerciseId'],
      order: map['order'] ?? 0,
      reps: map['reps'] ?? 0,
      maxReps: map['maxReps'],
      sets: map['sets'] ?? 1,
      maxSets: map['maxSets'],
      weight: (map['weight'] ?? 0.0).toDouble(),
      maxWeight: map['maxWeight']?.toDouble(),
      intensity: map['intensity'],
      maxIntensity: map['maxIntensity'],
      rpe: map['rpe'],
      maxRpe: map['maxRpe'],
      rpeMax: map['rpeMax'],
      repsDone: map['reps_done'] ?? map['repsDone'] ?? 0,
      weightDone: (map['weight_done'] ?? map['weightDone'] ?? 0.0).toDouble(),
      done: map['done'] ?? false,
      isCompleted: map['isCompleted'] ?? map['done'] ?? false,
      restTimeSeconds: map['restTimeSeconds'],
      type: map['type'],
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// Copy with method for immutable updates
  Series copyWith({
    String? id,
    String? serieId,
    String? exerciseId,
    String? originalExerciseId,
    int? order,
    int? reps,
    int? maxReps,
    int? sets,
    int? maxSets,
    double? weight,
    double? maxWeight,
    String? intensity,
    String? maxIntensity,
    String? rpe,
    String? maxRpe,
    String? rpeMax,
    int? repsDone,
    double? weightDone,
    bool? done,
    bool? isCompleted,
    int? restTimeSeconds,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Series(
      id: id ?? this.id,
      serieId: serieId ?? this.serieId,
      exerciseId: exerciseId ?? this.exerciseId,
      originalExerciseId: originalExerciseId ?? this.originalExerciseId,
      order: order ?? this.order,
      reps: reps ?? this.reps,
      maxReps: maxReps ?? this.maxReps,
      sets: sets ?? this.sets,
      maxSets: maxSets ?? this.maxSets,
      weight: weight ?? this.weight,
      maxWeight: maxWeight ?? this.maxWeight,
      intensity: intensity ?? this.intensity,
      maxIntensity: maxIntensity ?? this.maxIntensity,
      rpe: rpe ?? this.rpe,
      maxRpe: maxRpe ?? this.maxRpe,
      rpeMax: rpeMax ?? this.rpeMax,
      repsDone: repsDone ?? this.repsDone,
      weightDone: weightDone ?? this.weightDone,
      done: done ?? this.done,
      isCompleted: isCompleted ?? this.isCompleted,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serieId != null) 'serieId': serieId,
      'exerciseId': exerciseId,
      if (originalExerciseId != null) 'originalExerciseId': originalExerciseId,
      'order': order,
      'reps': reps,
      if (maxReps != null) 'maxReps': maxReps,
      'sets': sets,
      if (maxSets != null) 'maxSets': maxSets,
      'weight': weight,
      if (maxWeight != null) 'maxWeight': maxWeight,
      if (intensity != null) 'intensity': intensity,
      if (maxIntensity != null) 'maxIntensity': maxIntensity,
      if (rpe != null) 'rpe': rpe,
      if (maxRpe != null) 'maxRpe': maxRpe,
      if (rpeMax != null) 'rpeMax': rpeMax,
      'repsDone': repsDone,
      'weightDone': weightDone,
      'done': done,
      'isCompleted': isCompleted,
      if (restTimeSeconds != null) 'restTimeSeconds': restTimeSeconds,
      if (type != null) 'type': type,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  /// Helper method for parsing timestamps
  static DateTime? _parseTimestamp(dynamic data) {
    if (data == null) return null;
    if (data is Timestamp) return data.toDate();
    if (data is DateTime) return data;
    return null;
  }

  /// Check if series has range values (min-max)
  bool get hasRange =>
      maxReps != null ||
      maxWeight != null ||
      maxIntensity != null ||
      maxRpe != null;

  /// Get completion status (unified from both naming conventions)
  bool get completionStatus => done || isCompleted;

  /// Check if series is actually completed (has execution data)
  bool get hasExecutionData => repsDone > 0 || weightDone > 0;

  /// Equality and hashCode for value comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Series &&
        other.id == id &&
        other.serieId == serieId &&
        other.exerciseId == exerciseId &&
        other.originalExerciseId == originalExerciseId &&
        other.order == order &&
        other.reps == reps &&
        other.sets == sets &&
        other.weight == weight &&
        other.intensity == intensity &&
        other.rpe == rpe &&
        other.repsDone == repsDone &&
        other.weightDone == weightDone &&
        other.done == done &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      serieId,
      exerciseId,
      originalExerciseId,
      order,
      reps,
      sets,
      weight,
      intensity,
      rpe,
      repsDone,
      weightDone,
      done,
      isCompleted,
    );
  }

  @override
  String toString() {
    return 'Series(id: $id, exerciseId: $exerciseId, reps: $reps, weight: $weight, done: $completionStatus)';
  }
}

/// Extension methods for backward compatibility
extension SeriesCompatibility on Series {
  /// Viewer compatibility - get repsDone
  int get repsDoneCompat => repsDone;

  /// Viewer compatibility - get weightDone
  double get weightDoneCompat => weightDone;

  /// Unified completion check
  bool get isDone => completionStatus;

  /// Check if this is a range series
  bool get isRange => hasRange;

  /// Get display text for reps (handles ranges)
  String get repsDisplay {
    if (maxReps != null && maxReps != reps) {
      return '$reps-$maxReps';
    }
    return reps.toString();
  }

  /// Get display text for weight (handles ranges)
  String get weightDisplay {
    if (maxWeight != null && maxWeight != weight) {
      return '${weight.toStringAsFixed(1)}-${maxWeight!.toStringAsFixed(1)}';
    }
    return weight.toStringAsFixed(1);
  }

  /// Get display text for RPE (handles ranges)
  String get rpeDisplay {
    final rpeValue = rpe ?? '';
    final maxRpeValue = maxRpe ?? rpeMax ?? '';

    if (maxRpeValue.isNotEmpty && maxRpeValue != rpeValue) {
      return '$rpeValue-$maxRpeValue';
    }
    return rpeValue;
  }
}
