import 'package:cloud_firestore/cloud_firestore.dart';
import 'series.dart';
import '../../trainingBuilder/models/progressions_model.dart';

/// Unified Exercise model combining features from trainingBuilder and Viewer
/// Maintains backward compatibility while eliminating code duplication
class Exercise {
  // Core identification fields
  final String? id;
  final String? exerciseId; // For trainingBuilder compatibility
  final String? originalExerciseId; // For Viewer compatibility
  final String name;
  final String type;
  final String? variant;
  final int order;
  final String? superSetId;

  // Viewer-specific fields
  final String? workoutId;
  final String? note;

  // TrainingBuilder-specific fields
  final List<List<WeekProgression>>? weekProgressions;
  final num? latestMaxWeight;

  // Bodyweight and exercise type fields
  final bool isBodyweight;        // TRUE per esercizi a corpo libero
  final String? repType;          // 'fixed', 'range', 'min_reps', 'amrap'

  // Common fields
  final List<Series> series;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Exercise({
    this.id,
    this.exerciseId,
    this.originalExerciseId,
    required this.name,
    required this.type,
    this.variant,
    required this.order,
    this.superSetId,
    this.workoutId,
    this.note,
    this.weekProgressions,
    this.latestMaxWeight,
    this.isBodyweight = false,
    this.repType = 'fixed',
    this.series = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor for empty exercise
  factory Exercise.empty() {
    return const Exercise(name: '', type: 'weight', order: 0, series: []);
  }

  /// Factory constructor from Firestore document
  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Exercise.fromMap(data, doc.id);
  }

  /// Factory constructor from Map with document ID
  factory Exercise.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Exercise(
      id: documentId ?? map['id'],
      exerciseId: map['exerciseId'],
      originalExerciseId: map['originalExerciseId'],
      name: map['name'] ?? '',
      type: map['type'] ?? 'weight',
      variant: map['variant'],
      order: map['order'] ?? 0,
      superSetId: map['superSetId'],
      workoutId: map['workoutId'],
      note: map['note'],
      weekProgressions: _parseWeekProgressions(map['weekProgressions']),
      latestMaxWeight: map['latestMaxWeight'],
      isBodyweight: map['isBodyweight'] ?? false,
      repType: map['repType'] ?? 'fixed',
      series: _parseSeries(map['series']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  /// Copy with method for immutable updates
  Exercise copyWith({
    String? id,
    String? exerciseId,
    String? originalExerciseId,
    String? name,
    String? type,
    String? variant,
    int? order,
    String? superSetId,
    bool clearSuperSetId = false,
    String? workoutId,
    String? note,
    List<List<WeekProgression>>? weekProgressions,
    num? latestMaxWeight,
    bool? isBodyweight,
    String? repType,
    List<Series>? series,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      originalExerciseId: originalExerciseId ?? this.originalExerciseId,
      name: name ?? this.name,
      type: type ?? this.type,
      variant: variant ?? this.variant,
      order: order ?? this.order,
      superSetId: clearSuperSetId ? null : (superSetId ?? this.superSetId),
      workoutId: workoutId ?? this.workoutId,
      note: note ?? this.note,
      weekProgressions: weekProgressions ?? this.weekProgressions,
      latestMaxWeight: latestMaxWeight ?? this.latestMaxWeight,
      isBodyweight: isBodyweight ?? this.isBodyweight,
      repType: repType ?? this.repType,
      series: series ?? this.series.map((s) => s.copyWith()).toList(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (exerciseId != null) 'exerciseId': exerciseId,
      if (originalExerciseId != null) 'originalExerciseId': originalExerciseId,
      'name': name,
      'type': type,
      if (variant != null) 'variant': variant,
      'order': order,
      if (superSetId != null) 'superSetId': superSetId,
      if (workoutId != null) 'workoutId': workoutId,
      if (note != null) 'note': note,
      if (weekProgressions != null)
        'weekProgressions': weekProgressions!
            .map((week) => week.map((prog) => prog.toMap()).toList())
            .toList(),
      if (latestMaxWeight != null) 'latestMaxWeight': latestMaxWeight,
      'isBodyweight': isBodyweight,
      if (repType != null) 'repType': repType,
      'series': series.map((s) => s.toMap()).toList(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Convert to Firestore format (excludes nested collections)
  Map<String, dynamic> toFirestore() {
    final map = toMap();
    // Remove nested collections that should be stored separately
    map.remove('series');
    return map;
  }

  /// Helper methods for parsing complex fields
  static List<List<WeekProgression>>? _parseWeekProgressions(dynamic data) {
    if (data == null) return null;
    return List<List<WeekProgression>>.from(
      data.map(
        (week) => List<WeekProgression>.from(week.map((prog) => WeekProgression.fromMap(prog))),
      ),
    );
  }

  static List<Series> _parseSeries(dynamic data) {
    if (data == null) return [];

    // If it's already a List, map each entry to Series
    if (data is List) {
      return data
          .where((e) => e != null)
          .map((seriesData) => Series.fromMap(seriesData as Map<String, dynamic>))
          .toList();
    }

    // If it's a Map (e.g., IdentityMap from Firestore), convert its values
    if (data is Map) {
      return data.values
          .where((e) => e != null)
          .map((seriesData) => Series.fromMap(Map<String, dynamic>.from(seriesData as Map)))
          .toList();
    }

    // Fallback: unsupported shape
    return [];
  }

  static DateTime? _parseTimestamp(dynamic data) {
    if (data == null) return null;
    if (data is Timestamp) return data.toDate();
    if (data is DateTime) return data;
    return null;
  }

  /// Equality and hashCode for value comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Exercise &&
        other.id == id &&
        other.exerciseId == exerciseId &&
        other.originalExerciseId == originalExerciseId &&
        other.name == name &&
        other.type == type &&
        other.variant == variant &&
        other.order == order &&
        other.superSetId == superSetId &&
        other.workoutId == workoutId &&
        other.note == note &&
        other.latestMaxWeight == latestMaxWeight;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      exerciseId,
      originalExerciseId,
      name,
      type,
      variant,
      order,
      superSetId,
      workoutId,
      note,
      latestMaxWeight,
    );
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, type: $type, order: $order)';
  }
}

/// Extension methods for backward compatibility
extension ExerciseCompatibility on Exercise {
  /// TrainingBuilder compatibility getter
  String? get exerciseIdCompat => exerciseId ?? originalExerciseId;

  /// Viewer compatibility getter
  String? get originalExerciseIdCompat => originalExerciseId ?? exerciseId;

  /// Check if exercise has progressions (TrainingBuilder feature)
  bool get hasProgressions => weekProgressions != null && weekProgressions!.isNotEmpty;

  /// Check if exercise belongs to a workout (Viewer feature)
  bool get belongsToWorkout => workoutId != null;

  /// Check if exercise is completed (all series are done)
  bool get isCompleted => series.isNotEmpty && series.every((s) => s.done);
}
