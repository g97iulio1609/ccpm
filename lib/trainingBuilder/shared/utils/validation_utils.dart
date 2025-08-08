import '../../../shared/shared.dart';

/// Utility class for common validations following DRY principle
class ValidationUtils {
  ValidationUtils._();

  /// Validates if indices are within bounds for a training program
  static bool isValidProgramIndex(
    TrainingProgram program,
    int weekIndex, [
    int? workoutIndex,
    int? exerciseIndex,
  ]) {
    if (weekIndex < 0 || weekIndex >= program.weeks.length) return false;

    if (workoutIndex != null) {
      if (workoutIndex < 0 ||
          workoutIndex >= program.weeks[weekIndex].workouts.length) {
        return false;
      }

      if (exerciseIndex != null) {
        return exerciseIndex >= 0 &&
            exerciseIndex <
                program
                    .weeks[weekIndex]
                    .workouts[workoutIndex]
                    .exercises
                    .length;
      }
    }

    return true;
  }

  /// Validates if progression indices are valid
  static bool isValidProgressionIndex(
    List<List<dynamic>> weekProgressions,
    int weekIndex,
    int sessionIndex, [
    int? groupIndex,
  ]) {
    if (weekIndex < 0 || weekIndex >= weekProgressions.length) return false;
    if (sessionIndex < 0 ||
        sessionIndex >= weekProgressions[weekIndex].length) {
      return false;
    }

    if (groupIndex != null) {
      return groupIndex >= 0 &&
          groupIndex < weekProgressions[weekIndex][sessionIndex].length;
    }

    return true;
  }

  /// Validates exercise data
  static bool isValidExercise(Exercise exercise) {
  // Nota: l'ordine viene assegnato dal business service in fase di aggiunta.
  // Non blocchiamo la validazione se order è 0 durante la creazione.
  return exercise.name.isNotEmpty && exercise.type.isNotEmpty;
  }

  /// Validates series data
  static bool isValidSeries(Series series) {
    return series.reps >= 0 &&
        series.sets >= 0 &&
        series.weight >= 0 &&
        (series.maxReps == null || series.maxReps! >= series.reps) &&
        (series.maxWeight == null || series.maxWeight! >= series.weight);
  }

  /// Validates training program data
  static bool isValidTrainingProgram(TrainingProgram program) {
    return program.name.isNotEmpty &&
        program.athleteId.isNotEmpty &&
        program.mesocycleNumber > 0;
  }

  /// Validates string is not null or empty
  static bool isValidString(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Validates numeric value is positive
  static bool isPositive(num? value) {
    return value != null && value > 0;
  }

  /// Validates numeric value is non-negative
  static bool isNonNegative(num? value) {
    return value != null && value >= 0;
  }
}
