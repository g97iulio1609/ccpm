import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout.dart';

/// Unified Week model combining features from trainingBuilder and Viewer
/// Eliminates code duplication while maintaining backward compatibility
class Week {
  // Core identification fields
  final String? id;
  final String? programId; // Viewer compatibility
  final int number;
  final String? name; // Viewer compatibility
  final String? description; // Viewer compatibility

  // Content fields
  final List<Workout> workouts;

  // Status and tracking fields
  final bool isCompleted; // Viewer compatibility
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional metadata
  final Map<String, dynamic>? metadata;
  final String? notes;
  final List<String>? tags;
  final int? targetWorkoutsPerWeek;
  final bool isActive;

  const Week({
    this.id,
    this.programId,
    required this.number,
    this.name,
    this.description,
    this.workouts = const [],
    this.isCompleted = false,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.metadata,
    this.notes,
    this.tags,
    this.targetWorkoutsPerWeek,
    this.isActive = false,
  });

  /// Factory constructor for empty week
  factory Week.empty() {
    return const Week(number: 1, workouts: []);
  }

  /// Factory constructor from Firestore document
  factory Week.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Week.fromMap(data, doc.id);
  }

  /// Factory constructor from Map with optional document ID
  factory Week.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Week(
      id: documentId ?? map['id'],
      programId: map['programId'],
      number: map['number'] ?? 1,
      name: map['name'],
      description: map['description'],
      workouts: _parseWorkouts(map['workouts']),
      isCompleted: map['isCompleted'] ?? false,
      startDate: _parseTimestamp(map['startDate']),
      endDate: _parseTimestamp(map['endDate']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      metadata: map['metadata'] as Map<String, dynamic>?,
      notes: map['notes'],
      tags: _parseStringList(map['tags']),
      targetWorkoutsPerWeek: map['targetWorkoutsPerWeek'],
      isActive: map['isActive'] ?? false,
    );
  }

  /// Copy with method for immutable updates
  Week copyWith({
    String? id,
    String? programId,
    int? number,
    String? name,
    String? description,
    List<Workout>? workouts,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? notes,
    List<String>? tags,
    int? targetWorkoutsPerWeek,
    bool? isActive,
  }) {
    return Week(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      number: number ?? this.number,
      name: name ?? this.name,
      description: description ?? this.description,
      workouts: workouts ?? this.workouts,
      isCompleted: isCompleted ?? this.isCompleted,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      targetWorkoutsPerWeek:
          targetWorkoutsPerWeek ?? this.targetWorkoutsPerWeek,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (programId != null) 'programId': programId,
      'number': number,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      'workouts': workouts.map((w) => w.toMap()).toList(),
      'isCompleted': isCompleted,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (metadata != null) 'metadata': metadata,
      if (notes != null) 'notes': notes,
      if (tags != null) 'tags': tags,
      if (targetWorkoutsPerWeek != null)
        'targetWorkoutsPerWeek': targetWorkoutsPerWeek,
      'isActive': isActive,
    };
  }

  /// Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  /// Helper method for parsing workouts list
  static List<Workout> _parseWorkouts(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];

    return data
        .map((item) {
          if (item is Map<String, dynamic>) {
            return Workout.fromMap(item);
          }
          return null;
        })
        .where((item) => item != null)
        .cast<Workout>()
        .toList();
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

  /// Get total number of workouts
  int get totalWorkouts => workouts.length;

  /// Get completed workouts count
  int get completedWorkouts => workouts.where((w) => w.isCompleted).length;

  /// Get week completion percentage
  double get completionPercentage {
    if (workouts.isEmpty) return 0.0;
    return (completedWorkouts / workouts.length) * 100;
  }

  /// Check if week has any workouts
  bool get hasWorkouts => workouts.isNotEmpty;

  /// Check if week is fully completed
  bool get isFullyCompleted =>
      workouts.isNotEmpty && workouts.every((w) => w.isCompleted);

  /// Get total exercises across all workouts
  int get totalExercises =>
      workouts.fold(0, (total, workout) => total + workout.totalExercises);

  /// Get total series across all workouts
  int get totalSeries =>
      workouts.fold(0, (total, workout) => total + workout.totalSeries);

  /// Get estimated total duration for the week
  int get estimatedTotalDuration =>
      workouts.fold(0, (total, workout) => total + workout.estimatedDuration);

  /// Check if week is current (within date range)
  bool get isCurrent {
    final now = DateTime.now();
    if (startDate != null && endDate != null) {
      return now.isAfter(startDate!) && now.isBefore(endDate!);
    }
    return isActive;
  }

  /// Check if week is in the past
  bool get isPast {
    if (endDate != null) {
      return DateTime.now().isAfter(endDate!);
    }
    return false;
  }

  /// Check if week is in the future
  bool get isFuture {
    if (startDate != null) {
      return DateTime.now().isBefore(startDate!);
    }
    return false;
  }

  /// Get week progress status
  WeekStatus get status {
    if (isCompleted) return WeekStatus.completed;
    if (completedWorkouts > 0) return WeekStatus.inProgress;
    if (isCurrent) return WeekStatus.current;
    if (isPast) return WeekStatus.overdue;
    return WeekStatus.upcoming;
  }

  /// Get display name for the week
  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return 'Week $number';
  }

  /// Get workouts sorted by order
  List<Workout> get sortedWorkouts {
    final sorted = List<Workout>.from(workouts);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// Equality and hashCode for value comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Week &&
        other.id == id &&
        other.programId == programId &&
        other.number == number &&
        other.name == name &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return Object.hash(id, programId, number, name, isCompleted);
  }

  @override
  String toString() {
    return 'Week(id: $id, number: $number, workouts: ${workouts.length}, completed: $isCompleted)';
  }
}

/// Enum for week status
enum WeekStatus { upcoming, current, inProgress, completed, overdue }

/// Extension methods for backward compatibility and additional functionality
extension WeekCompatibility on Week {
  /// TrainingBuilder compatibility - get workouts list
  List<Workout> get workoutsList => workouts;

  /// Viewer compatibility - check if week was started
  bool get wasStarted => completedWorkouts > 0;

  /// Get week number as string
  String get weekNumber => number.toString();

  /// Get completion status as string
  String get statusText {
    switch (status) {
      case WeekStatus.completed:
        return 'Completed';
      case WeekStatus.inProgress:
        return 'In Progress';
      case WeekStatus.current:
        return 'Current';
      case WeekStatus.overdue:
        return 'Overdue';
      case WeekStatus.upcoming:
        return 'Upcoming';
    }
  }

  /// Get formatted duration string for the week
  String get durationText {
    final duration = estimatedTotalDuration;
    if (duration < 60) {
      return '${duration}min';
    } else {
      final hours = duration ~/ 60;
      final minutes = duration % 60;
      if (minutes == 0) {
        return '${hours}h';
      }
      return '${hours}h ${minutes}min';
    }
  }

  /// Get progress text (e.g., "2/4 workouts")
  String get progressText {
    return '$completedWorkouts/$totalWorkouts workouts';
  }

  /// Create a copy with updated completion status
  Week markAsCompleted() {
    return copyWith(isCompleted: true, updatedAt: DateTime.now());
  }

  /// Create a copy with reset completion status
  Week resetCompletion() {
    return copyWith(isCompleted: false, updatedAt: DateTime.now());
  }

  /// Add workout to week
  Week addWorkout(Workout workout) {
    final updatedWorkouts = List<Workout>.from(workouts);
    updatedWorkouts.add(workout);
    return copyWith(workouts: updatedWorkouts, updatedAt: DateTime.now());
  }

  /// Remove workout from week
  Week removeWorkout(String workoutId) {
    final updatedWorkouts = workouts.where((w) => w.id != workoutId).toList();
    return copyWith(workouts: updatedWorkouts, updatedAt: DateTime.now());
  }

  /// Update workout in week
  Week updateWorkout(Workout updatedWorkout) {
    final updatedWorkouts = workouts
        .map((w) => w.id == updatedWorkout.id ? updatedWorkout : w)
        .toList();
    return copyWith(workouts: updatedWorkouts, updatedAt: DateTime.now());
  }

  /// Reorder workouts
  Week reorderWorkouts(List<Workout> reorderedWorkouts) {
    return copyWith(workouts: reorderedWorkouts, updatedAt: DateTime.now());
  }

  /// Get next workout to perform
  Workout? get nextWorkout {
    return workouts
        .where((w) => !w.isCompleted)
        .fold<Workout?>(
          null,
          (next, workout) =>
              next == null || workout.order < next.order ? workout : next,
        );
  }

  /// Get last completed workout
  Workout? get lastCompletedWorkout {
    return workouts
        .where((w) => w.isCompleted)
        .fold<Workout?>(
          null,
          (last, workout) =>
              last == null || workout.order > last.order ? workout : last,
        );
  }

  /// Check if week meets target workouts
  bool get meetsTarget {
    if (targetWorkoutsPerWeek == null) return true;
    return completedWorkouts >= targetWorkoutsPerWeek!;
  }

  /// Get remaining workouts to meet target
  int get remainingWorkoutsForTarget {
    if (targetWorkoutsPerWeek == null) return 0;
    return (targetWorkoutsPerWeek! - completedWorkouts)
        .clamp(0, double.infinity)
        .toInt();
  }
}
