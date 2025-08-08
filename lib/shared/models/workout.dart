import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

/// Unified Workout model combining features from trainingBuilder and Viewer
/// Eliminates code duplication while maintaining backward compatibility
class Workout {
  // Core identification fields
  final String? id;
  final String? weekId; // Viewer compatibility
  final int order;
  final String name;
  final String? description; // Viewer compatibility

  // Content fields
  final List<Exercise> exercises;
  final List<Map<String, dynamic>>? superSets; // TrainingBuilder compatibility

  // Status and tracking fields
  final DateTime? lastPerformed; // Viewer compatibility
  final bool isCompleted; // Viewer compatibility
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional metadata
  final Map<String, dynamic>? metadata;
  final String? notes;
  final int? estimatedDurationMinutes;
  final List<String>? tags;

  const Workout({
    this.id,
    this.weekId,
    required this.order,
    required this.name,
    this.description,
    this.exercises = const [],
    this.superSets,
    this.lastPerformed,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
    this.metadata,
    this.notes,
    this.estimatedDurationMinutes,
    this.tags,
  });

  /// Factory constructor for empty workout
  factory Workout.empty() {
    return const Workout(order: 0, name: '', exercises: []);
  }

  /// Factory constructor from Firestore document
  factory Workout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Workout.fromMap(data, doc.id);
  }

  /// Factory constructor from Map with optional document ID
  factory Workout.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Workout(
      id: documentId ?? map['id'],
      weekId: map['weekId'],
      order: map['order'] ?? 0,
      name: map['name'] ?? '',
      description: map['description'],
      exercises: _parseExercises(map['exercises']),
      superSets: _parseSuperSets(map['superSets']),
      lastPerformed: _parseTimestamp(map['lastPerformed']),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      metadata: map['metadata'] as Map<String, dynamic>?,
      notes: map['notes'],
      estimatedDurationMinutes: map['estimatedDurationMinutes'],
      tags: _parseStringList(map['tags']),
    );
  }

  /// Copy with method for immutable updates
  Workout copyWith({
    String? id,
    String? weekId,
    int? order,
    String? name,
    String? description,
    List<Exercise>? exercises,
    List<Map<String, dynamic>>? superSets,
    DateTime? lastPerformed,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? notes,
    int? estimatedDurationMinutes,
    List<String>? tags,
  }) {
    return Workout(
      id: id ?? this.id,
      weekId: weekId ?? this.weekId,
      order: order ?? this.order,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      superSets: superSets ?? this.superSets,
      lastPerformed: lastPerformed ?? this.lastPerformed,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      tags: tags ?? this.tags,
    );
  }

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (weekId != null) 'weekId': weekId,
      'order': order,
      'name': name,
      if (description != null) 'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      if (superSets != null) 'superSets': superSets,
      if (lastPerformed != null)
        'lastPerformed': Timestamp.fromDate(lastPerformed!),
      'isCompleted': isCompleted,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (metadata != null) 'metadata': metadata,
      if (notes != null) 'notes': notes,
      if (estimatedDurationMinutes != null)
        'estimatedDurationMinutes': estimatedDurationMinutes,
      if (tags != null) 'tags': tags,
    };
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  /// Helper method for parsing exercises list
  static List<Exercise> _parseExercises(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];

    return data
        .map((item) {
          if (item is Map<String, dynamic>) {
            return Exercise.fromMap(item);
          }
          return null;
        })
        .where((item) => item != null)
        .cast<Exercise>()
        .toList();
  }

  /// Helper method for parsing superSets
  static List<Map<String, dynamic>>? _parseSuperSets(dynamic data) {
    if (data == null) return null;
    if (data is! List) return null;

    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  /// Helper method for parsing timestamps
  static DateTime? _parseTimestamp(dynamic data) {
    if (data == null) return null;
    if (data is Timestamp) return data.toDate();
    if (data is DateTime) return data;
    return null;
  }

  /// Helper method for parsing string lists
  static List<String>? _parseStringList(dynamic data) {
    if (data == null) return null;
    if (data is! List) return null;

    return data.map((item) => item.toString()).toList();
  }

  /// Get total number of exercises
  int get totalExercises => exercises.length;

  /// Get total number of series across all exercises
  int get totalSeries =>
      exercises.fold(0, (total, exercise) => total + exercise.series.length);

  /// Get completed exercises count
  int get completedExercises => exercises.where((e) => e.isCompleted).length;

  /// Get workout completion percentage
  double get completionPercentage {
    if (exercises.isEmpty) return 0.0;
    return (completedExercises / exercises.length) * 100;
  }

  /// Check if workout has any exercises
  bool get hasExercises => exercises.isNotEmpty;

  /// Check if workout is fully completed
  bool get isFullyCompleted =>
      exercises.isNotEmpty && exercises.every((e) => e.isCompleted);

  /// Get estimated duration in minutes
  int get estimatedDuration {
    if (estimatedDurationMinutes != null) {
      return estimatedDurationMinutes!;
    }

    // Calculate based on exercises and series
    int totalSets = totalSeries;
    int estimatedMinutes = (totalSets * 2.5).round(); // ~2.5 minutes per set
    return estimatedMinutes;
  }

  /// Get exercises grouped by supersets
  Map<String?, List<Exercise>> get exercisesBySuperset {
    final Map<String?, List<Exercise>> grouped = {};

    for (final exercise in exercises) {
      final supersetId = exercise.superSetId;
      if (!grouped.containsKey(supersetId)) {
        grouped[supersetId] = [];
      }
      grouped[supersetId]!.add(exercise);
    }

    return grouped;
  }

  /// Get exercises that are part of supersets
  List<Exercise> get supersetExercises {
    return exercises.where((e) => e.superSetId != null).toList();
  }

  /// Get exercises that are not part of supersets
  List<Exercise> get regularExercises {
    return exercises.where((e) => e.superSetId == null).toList();
  }

  /// Equality and hashCode for value comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workout &&
        other.id == id &&
        other.weekId == weekId &&
        other.order == order &&
        other.name == name &&
        other.description == description &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return Object.hash(id, weekId, order, name, description, isCompleted);
  }

  @override
  String toString() {
    return 'Workout(id: $id, name: $name, exercises: ${exercises.length}, completed: $isCompleted)';
  }
}

/// Extension methods for backward compatibility and additional functionality
extension WorkoutCompatibility on Workout {
  /// TrainingBuilder compatibility - get exercises list
  List<Exercise> get exercisesList => exercises;

  /// Viewer compatibility - check if workout was performed
  bool get wasPerformed => lastPerformed != null;

  /// Get days since last performed
  int? get daysSinceLastPerformed {
    if (lastPerformed == null) return null;
    return DateTime.now().difference(lastPerformed!).inDays;
  }

  /// Check if workout is overdue (more than 7 days since last performed)
  bool get isOverdue {
    final days = daysSinceLastPerformed;
    return days != null && days > 7;
  }

  /// Get workout status as string
  String get statusText {
    if (isCompleted) return 'Completed';
    if (completedExercises > 0) return 'In Progress';
    return 'Not Started';
  }

  /// Get formatted duration string
  String get durationText {
    final duration = estimatedDuration;
    if (duration < 60) {
      return '${duration}min';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      return '${hours}h ${minutes}min';
    }
  }

  /// Create a copy with updated completion status
  Workout markAsCompleted() {
    return copyWith(
      isCompleted: true,
      lastPerformed: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with reset completion status
  Workout resetCompletion() {
    return copyWith(isCompleted: false, updatedAt: DateTime.now());
  }

  /// Add exercise to workout
  Workout addExercise(Exercise exercise) {
    final updatedExercises = List<Exercise>.from(exercises);
    updatedExercises.add(exercise);
    return copyWith(exercises: updatedExercises, updatedAt: DateTime.now());
  }

  /// Remove exercise from workout
  Workout removeExercise(String exerciseId) {
    final updatedExercises = exercises
        .where((e) => e.id != exerciseId)
        .toList();
    return copyWith(exercises: updatedExercises, updatedAt: DateTime.now());
  }

  /// Update exercise in workout
  Workout updateExercise(Exercise updatedExercise) {
    final updatedExercises = exercises
        .map((e) => e.id == updatedExercise.id ? updatedExercise : e)
        .toList();
    return copyWith(exercises: updatedExercises, updatedAt: DateTime.now());
  }

  /// Reorder exercises
  Workout reorderExercises(List<Exercise> reorderedExercises) {
    return copyWith(exercises: reorderedExercises, updatedAt: DateTime.now());
  }
}
