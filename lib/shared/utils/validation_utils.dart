/// Shared validation utilities for training models
/// Consolidates validation logic from both trainingBuilder and Viewer modules
class ValidationUtils {
  // Private constructor to prevent instantiation
  ValidationUtils._();

  /// Validation result class
  static const ValidationResult valid = ValidationResult._(true, null);

  static ValidationResult invalid(String message) => ValidationResult._(false, message);

  // Exercise validation
  static ValidationResult validateExerciseName(String name) {
    if (name.trim().isEmpty) {
      return invalid('Exercise name cannot be empty');
    }
    if (name.trim().length < 2) {
      return invalid('Exercise name must be at least 2 characters long');
    }
    if (name.length > 100) {
      return invalid('Exercise name cannot exceed 100 characters');
    }
    return valid;
  }

  static ValidationResult validateExerciseType(String type) {
    const validTypes = {
      'strength',
      'cardio',
      'flexibility',
      'balance',
      'plyometric',
      'compound',
      'isolation',
      'functional',
    };

    if (type.trim().isEmpty) {
      return invalid('Exercise type cannot be empty');
    }
    if (!validTypes.contains(type.toLowerCase())) {
      return invalid('Invalid exercise type: $type');
    }
    return valid;
  }

  static ValidationResult validateExerciseOrder(int order) {
    if (order < 0) {
      return invalid('Exercise order cannot be negative');
    }
    if (order > 1000) {
      return invalid('Exercise order cannot exceed 1000');
    }
    return valid;
  }

  // Series validation
  static ValidationResult validateReps(int reps) {
    if (reps < 0) {
      return invalid('Reps cannot be negative');
    }
    if (reps > 1000) {
      return invalid('Reps cannot exceed 1000');
    }
    return valid;
  }

  static ValidationResult validateSets(int sets) {
    if (sets < 0) {
      return invalid('Sets cannot be negative');
    }
    if (sets > 100) {
      return invalid('Sets cannot exceed 100');
    }
    return valid;
  }

  static ValidationResult validateWeight(double weight) {
    if (weight < 0) {
      return invalid('Weight cannot be negative');
    }
    if (weight > 10000) {
      return invalid('Weight cannot exceed 10000kg');
    }
    return valid;
  }

  static ValidationResult validateRpe(String? rpe) {
    if (rpe == null || rpe.trim().isEmpty) {
      return valid; // RPE is optional
    }

    final rpeValue = double.tryParse(rpe);
    if (rpeValue == null) {
      return invalid('RPE must be a valid number');
    }
    if (rpeValue < 1 || rpeValue > 10) {
      return invalid('RPE must be between 1 and 10');
    }
    return valid;
  }

  static ValidationResult validateIntensity(String? intensity) {
    if (intensity == null || intensity.trim().isEmpty) {
      return valid; // Intensity is optional
    }

    // Check if it's a percentage
    if (intensity.endsWith('%')) {
      final percentValue = double.tryParse(intensity.substring(0, intensity.length - 1));
      if (percentValue == null) {
        return invalid('Intensity percentage must be a valid number');
      }
      if (percentValue < 0 || percentValue > 100) {
        return invalid('Intensity percentage must be between 0% and 100%');
      }
      return valid;
    }

    // Check if it's a decimal value
    final decimalValue = double.tryParse(intensity);
    if (decimalValue == null) {
      return invalid('Intensity must be a valid number or percentage');
    }
    if (decimalValue < 0 || decimalValue > 1) {
      return invalid('Intensity decimal value must be between 0 and 1');
    }
    return valid;
  }

  static ValidationResult validateRestTime(int? restTimeSeconds) {
    if (restTimeSeconds == null) {
      return valid; // Rest time is optional
    }
    if (restTimeSeconds < 0) {
      return invalid('Rest time cannot be negative');
    }
    if (restTimeSeconds > 3600) {
      return invalid('Rest time cannot exceed 1 hour (3600 seconds)');
    }
    return valid;
  }

  // Workout validation
  static ValidationResult validateWorkoutName(String name) {
    if (name.trim().isEmpty) {
      return invalid('Workout name cannot be empty');
    }
    if (name.trim().length < 2) {
      return invalid('Workout name must be at least 2 characters long');
    }
    if (name.length > 100) {
      return invalid('Workout name cannot exceed 100 characters');
    }
    return valid;
  }

  static ValidationResult validateWorkoutOrder(int order) {
    if (order < 0) {
      return invalid('Workout order cannot be negative');
    }
    if (order > 100) {
      return invalid('Workout order cannot exceed 100');
    }
    return valid;
  }

  static ValidationResult validateEstimatedDuration(int? durationMinutes) {
    if (durationMinutes == null) {
      return valid; // Duration is optional
    }
    if (durationMinutes < 0) {
      return invalid('Estimated duration cannot be negative');
    }
    if (durationMinutes > 480) {
      return invalid('Estimated duration cannot exceed 8 hours (480 minutes)');
    }
    return valid;
  }

  // Week validation
  static ValidationResult validateWeekNumber(int number) {
    if (number <= 0) {
      return invalid('Week number must be positive');
    }
    if (number > 104) {
      return invalid('Week number cannot exceed 104 (2 years)');
    }
    return valid;
  }

  static ValidationResult validateWeekName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return valid; // Week name is optional
    }
    if (name.length > 100) {
      return invalid('Week name cannot exceed 100 characters');
    }
    return valid;
  }

  static ValidationResult validateDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return valid; // Date range is optional
    }
    if (startDate.isAfter(endDate)) {
      return invalid('Start date cannot be after end date');
    }
    if (endDate.difference(startDate).inDays > 14) {
      return invalid('Week duration cannot exceed 14 days');
    }
    return valid;
  }

  static ValidationResult validateTargetWorkouts(int? targetWorkouts) {
    if (targetWorkouts == null) {
      return valid; // Target workouts is optional
    }
    if (targetWorkouts < 0) {
      return invalid('Target workouts cannot be negative');
    }
    if (targetWorkouts > 14) {
      return invalid('Target workouts cannot exceed 14 per week');
    }
    return valid;
  }

  // Range validation
  static ValidationResult validateRange(int min, int? max, String fieldName) {
    if (max == null) {
      return valid; // Max is optional
    }
    if (min > max) {
      return invalid('$fieldName minimum cannot be greater than maximum');
    }
    if (max - min > 100) {
      return invalid('$fieldName range cannot exceed 100');
    }
    return valid;
  }

  static ValidationResult validateWeightRange(double min, double? max) {
    if (max == null) {
      return valid; // Max is optional
    }
    if (min > max) {
      return invalid('Minimum weight cannot be greater than maximum weight');
    }
    if (max - min > 1000) {
      return invalid('Weight range cannot exceed 1000kg');
    }
    return valid;
  }

  // Text validation
  static ValidationResult validateNotes(String? notes) {
    if (notes == null || notes.trim().isEmpty) {
      return valid; // Notes are optional
    }
    if (notes.length > 1000) {
      return invalid('Notes cannot exceed 1000 characters');
    }
    return valid;
  }

  static ValidationResult validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return valid; // Description is optional
    }
    if (description.length > 500) {
      return invalid('Description cannot exceed 500 characters');
    }
    return valid;
  }

  // ID validation
  static ValidationResult validateId(String? id, String fieldName) {
    if (id == null || id.trim().isEmpty) {
      return invalid('$fieldName ID cannot be empty');
    }
    if (id.length < 3) {
      return invalid('$fieldName ID must be at least 3 characters long');
    }
    if (id.length > 50) {
      return invalid('$fieldName ID cannot exceed 50 characters');
    }
    // Check for valid characters (alphanumeric, hyphens, underscores)
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      return invalid('$fieldName ID can only contain letters, numbers, hyphens, and underscores');
    }
    return valid;
  }

  // Email validation
  static ValidationResult validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return invalid('Email cannot be empty');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return invalid('Invalid email format');
    }
    return valid;
  }

  // Composite validation methods
  static List<ValidationResult> validateExercise({
    required String name,
    required String type,
    required int order,
    String? exerciseId,
    String? notes,
  }) {
    return [
      validateExerciseName(name),
      validateExerciseType(type),
      validateExerciseOrder(order),
      if (exerciseId != null) validateId(exerciseId, 'Exercise'),
      validateNotes(notes),
    ].where((result) => !result.isValid).toList();
  }

  static List<ValidationResult> validateSeries({
    required int reps,
    required int sets,
    required double weight,
    String? rpe,
    String? intensity,
    int? restTimeSeconds,
    int? maxReps,
    double? maxWeight,
  }) {
    return [
      validateReps(reps),
      validateSets(sets),
      validateWeight(weight),
      validateRpe(rpe),
      validateIntensity(intensity),
      validateRestTime(restTimeSeconds),
      validateRange(reps, maxReps, 'Reps'),
      validateWeightRange(weight, maxWeight),
    ].where((result) => !result.isValid).toList();
  }

  // Cardio-specific validation
  static ValidationResult validateDurationSeconds(int? seconds) {
    if (seconds == null) return valid;
    if (seconds < 0) return invalid('Duration cannot be negative');
    if (seconds > 24 * 3600) return invalid('Duration too long');
    return valid;
  }

  static ValidationResult validateDistanceMeters(int? meters) {
    if (meters == null) return valid;
    if (meters < 0) return invalid('Distance cannot be negative');
    if (meters > 1000000) return invalid('Distance too large');
    return valid;
  }

  static ValidationResult validateSpeedKmh(double? speed) {
    if (speed == null) return valid;
    if (speed < 0) return invalid('Speed cannot be negative');
    if (speed > 60) return invalid('Speed too large (>60 km/h)');
    return valid;
  }

  static ValidationResult validatePaceSecPerKm(int? pace) {
    if (pace == null) return valid;
    if (pace <= 0) return invalid('Pace must be > 0');
    if (pace > 1800) return invalid('Pace too slow (>30:00/km)');
    return valid;
  }

  static ValidationResult validateInclinePercent(double? incline) {
    if (incline == null) return valid;
    if (incline < 0 || incline > 30) return invalid('Incline must be 0–30%');
    return valid;
  }

  static ValidationResult validateHrPercent(double? hrPercent) {
    if (hrPercent == null) return valid;
    if (hrPercent < 0 || hrPercent > 100) return invalid('HR% must be 0–100');
    return valid;
  }

  static ValidationResult validateHrBpm(int? hrBpm) {
    if (hrBpm == null) return valid;
    if (hrBpm < 0 || hrBpm > 240) return invalid('HR bpm must be 0–240');
    return valid;
  }

  static List<ValidationResult> validateCardio({
    int? durationSeconds,
    int? distanceMeters,
    double? speedKmh,
    int? paceSecPerKm,
    double? inclinePercent,
    double? hrPercent,
    int? hrBpm,
    int? kcal,
  }) {
    final results = <ValidationResult>[
      validateDurationSeconds(durationSeconds),
      validateDistanceMeters(distanceMeters),
      validateSpeedKmh(speedKmh),
      validatePaceSecPerKm(paceSecPerKm),
      validateInclinePercent(inclinePercent),
      validateHrPercent(hrPercent),
      validateHrBpm(hrBpm),
    ];
    // Ensure at least duration or distance present for cardio targets
    final hasOne = (durationSeconds ?? 0) > 0 || (distanceMeters ?? 0) > 0;
    if (!hasOne) {
      results.add(invalid('For cardio, set duration and/or distance'));
    }
    return results.where((r) => !r.isValid).toList();
  }

  static List<ValidationResult> validateWorkout({
    required String name,
    required int order,
    String? description,
    int? estimatedDurationMinutes,
    String? notes,
  }) {
    return [
      validateWorkoutName(name),
      validateWorkoutOrder(order),
      validateDescription(description),
      validateEstimatedDuration(estimatedDurationMinutes),
      validateNotes(notes),
    ].where((result) => !result.isValid).toList();
  }

  static List<ValidationResult> validateWeek({
    required int number,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? targetWorkoutsPerWeek,
    String? notes,
  }) {
    return [
      validateWeekNumber(number),
      validateWeekName(name),
      validateDescription(description),
      validateDateRange(startDate, endDate),
      validateTargetWorkouts(targetWorkoutsPerWeek),
      validateNotes(notes),
    ].where((result) => !result.isValid).toList();
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult._(this.isValid, this.message);

  bool get isInvalid => !isValid;

  @override
  String toString() {
    return isValid ? 'Valid' : 'Invalid: $message';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValidationResult && other.isValid == isValid && other.message == message;
  }

  @override
  int get hashCode => Object.hash(isValid, message);
}

/// Extension methods for easier validation
extension ValidationExtensions on List<ValidationResult> {
  /// Check if all validations passed
  bool get allValid => every((result) => result.isValid);

  /// Check if any validation failed
  bool get anyInvalid => any((result) => result.isInvalid);

  /// Get all error messages
  List<String> get errorMessages {
    return where((result) => result.isInvalid).map((result) => result.message!).toList();
  }

  /// Get first error message
  String? get firstError {
    final invalid = where((result) => result.isInvalid).firstOrNull;
    return invalid?.message;
  }

  /// Combine all error messages
  String get combinedErrors {
    return errorMessages.join('; ');
  }
}

/// Validation exception for throwing validation errors
class ValidationException implements Exception {
  final List<ValidationResult> validationResults;

  const ValidationException(this.validationResults);

  List<String> get errorMessages => validationResults.errorMessages;

  String get message => validationResults.combinedErrors;

  @override
  String toString() {
    return 'ValidationException: $message';
  }
}

/// Mixin for adding validation capabilities to models
mixin Validatable {
  /// Validate the model and return validation results
  List<ValidationResult> validate();

  /// Check if the model is valid
  bool get isValid => validate().allValid;

  /// Get validation error messages
  List<String> get validationErrors => validate().errorMessages;

  /// Validate and throw exception if invalid
  void validateOrThrow() {
    final results = validate();
    if (results.anyInvalid) {
      throw ValidationException(results);
    }
  }
}
