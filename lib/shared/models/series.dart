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
  final String? seriesType; // 'standard', 'amrap', 'min_reps'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Cardio target fields (optional, non-breaking)
  final int? durationSeconds; // planned duration in seconds
  final int? distanceMeters; // planned distance in meters
  final double? speedKmh; // planned speed in km/h
  final int? paceSecPerKm; // planned pace in sec/km
  final double? inclinePercent; // treadmill incline %
  final double? hrPercent; // target HR as % of HRmax
  final int? hrBpm; // target HR in bpm
  final int? avgHr; // target average HR in bpm
  final int? kcal; // estimated calories

  // Cardio execution fields
  final int? executedDurationSeconds; // actual duration in seconds
  final int? executedDistanceMeters; // actual distance in meters
  final int? executedAvgHr; // actual avg HR in bpm

  // HIIT cardio fields
  final int? workIntervalSeconds; // work interval duration
  final int? restIntervalSeconds; // rest interval duration
  final int? rounds; // number of rounds/cycles
  final String? cardioType; // 'steady', 'hiit'

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
    this.seriesType = 'standard',
    this.createdAt,
    this.updatedAt,
    this.durationSeconds,
    this.distanceMeters,
    this.speedKmh,
    this.paceSecPerKm,
    this.inclinePercent,
    this.hrPercent,
    this.hrBpm,
    this.avgHr,
    this.kcal,
    this.executedDurationSeconds,
    this.executedDistanceMeters,
    this.executedAvgHr,
    this.workIntervalSeconds,
    this.restIntervalSeconds,
    this.rounds,
    this.cardioType = 'steady',
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
      seriesType: map['seriesType'] ?? 'standard',
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      durationSeconds: map['durationSeconds'],
      distanceMeters: map['distanceMeters'],
      speedKmh: (map['speedKmh'] as num?)?.toDouble(),
      paceSecPerKm: map['paceSecPerKm'],
      inclinePercent: (map['inclinePercent'] as num?)?.toDouble(),
      hrPercent: (map['hrPercent'] as num?)?.toDouble(),
      hrBpm: map['hrBpm'],
      avgHr: map['avgHr'],
      kcal: map['kcal'],
      executedDurationSeconds: map['executedDurationSeconds'],
      executedDistanceMeters: map['executedDistanceMeters'],
      executedAvgHr: map['executedAvgHr'],
      workIntervalSeconds: map['workIntervalSeconds'],
      restIntervalSeconds: map['restIntervalSeconds'],
      rounds: map['rounds'],
      cardioType: map['cardioType'] ?? 'steady',
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
    String? seriesType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? durationSeconds,
    int? distanceMeters,
    double? speedKmh,
    int? paceSecPerKm,
    double? inclinePercent,
    double? hrPercent,
    int? hrBpm,
    int? avgHr,
    int? kcal,
    int? executedDurationSeconds,
    int? executedDistanceMeters,
    int? executedAvgHr,
    int? workIntervalSeconds,
    int? restIntervalSeconds,
    int? rounds,
    String? cardioType,
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
      seriesType: seriesType ?? this.seriesType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      speedKmh: speedKmh ?? this.speedKmh,
      paceSecPerKm: paceSecPerKm ?? this.paceSecPerKm,
      inclinePercent: inclinePercent ?? this.inclinePercent,
      hrPercent: hrPercent ?? this.hrPercent,
      hrBpm: hrBpm ?? this.hrBpm,
      avgHr: avgHr ?? this.avgHr,
      kcal: kcal ?? this.kcal,
      executedDurationSeconds: executedDurationSeconds ?? this.executedDurationSeconds,
      executedDistanceMeters: executedDistanceMeters ?? this.executedDistanceMeters,
      executedAvgHr: executedAvgHr ?? this.executedAvgHr,
      workIntervalSeconds: workIntervalSeconds ?? this.workIntervalSeconds,
      restIntervalSeconds: restIntervalSeconds ?? this.restIntervalSeconds,
      rounds: rounds ?? this.rounds,
      cardioType: cardioType ?? this.cardioType,
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
      if (seriesType != null) 'seriesType': seriesType,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (distanceMeters != null) 'distanceMeters': distanceMeters,
      if (speedKmh != null) 'speedKmh': speedKmh,
      if (paceSecPerKm != null) 'paceSecPerKm': paceSecPerKm,
      if (inclinePercent != null) 'inclinePercent': inclinePercent,
      if (hrPercent != null) 'hrPercent': hrPercent,
      if (hrBpm != null) 'hrBpm': hrBpm,
      if (avgHr != null) 'avgHr': avgHr,
      if (kcal != null) 'kcal': kcal,
      if (executedDurationSeconds != null) 'executedDurationSeconds': executedDurationSeconds,
      if (executedDistanceMeters != null) 'executedDistanceMeters': executedDistanceMeters,
      if (executedAvgHr != null) 'executedAvgHr': executedAvgHr,
      if (workIntervalSeconds != null) 'workIntervalSeconds': workIntervalSeconds,
      if (restIntervalSeconds != null) 'restIntervalSeconds': restIntervalSeconds,
      if (rounds != null) 'rounds': rounds,
      if (cardioType != null) 'cardioType': cardioType,
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
      maxReps != null || maxWeight != null || maxIntensity != null || maxRpe != null;

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
  int get hashCode => Object.hashAll([
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
    durationSeconds,
    distanceMeters,
    speedKmh,
    paceSecPerKm,
    inclinePercent,
    hrPercent,
    hrBpm,
    avgHr,
    kcal,
    executedDurationSeconds,
    executedDistanceMeters,
    executedAvgHr,
  ]);

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

  /// ID to use for persistence operations (falls back to Firestore doc ID)
  String? get persistedSerieId =>
      (serieId != null && serieId!.isNotEmpty) ? serieId : (id?.isNotEmpty == true ? id : null);

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

  /// Cardio helpers (formatted display)
  String get durationDisplay {
    final sec = durationSeconds ?? executedDurationSeconds;
    if (sec == null) return '';
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get distanceDisplay {
    final m = distanceMeters ?? executedDistanceMeters;
    if (m == null) return '';
    return (m / 1000).toStringAsFixed(2);
  }

  String get paceDisplayCardio {
    final p = paceSecPerKm;
    if (p == null) return '';
    final m = (p ~/ 60).toString().padLeft(2, '0');
    final s = (p % 60).toString().padLeft(2, '0');
    return '$m:$s/km';
  }
}
