import '../models/exercise_model.dart';
import '../models/progressions_model.dart';
import '../models/series_model.dart';
import '../models/week_model.dart';
import '../models/workout_model.dart';
import '../models/progression_view_model.dart';
import '../shared/utils/validation_utils.dart';
import '../shared/utils/model_utils.dart';

/// Optimized business service for progression operations
/// Follows SOLID principles and reduces complexity
class ProgressionBusinessServiceOptimized {
  ProgressionBusinessServiceOptimized._();

  /// Creates week progressions for an exercise with improved performance
  static List<List<WeekProgression>> buildWeekProgressions(
    List<Week> weeks,
    Exercise exercise,
  ) {
    if (weeks.isEmpty || exercise.exerciseId == null) {
      return [];
    }

    return weeks.asMap().entries.map((weekEntry) {
      final weekIndex = weekEntry.key;
      final week = weekEntry.value;

      return week.workouts.map((workout) {
        final exerciseInWorkout =
            _findExerciseInWorkout(workout, exercise.exerciseId!);

        if (exerciseInWorkout == null) {
          return WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: workout.order,
            series: [],
          );
        }

        return _createWeekProgression(
          weekIndex,
          workout.order,
          exerciseInWorkout,
          exercise.weekProgressions,
        );
      }).toList();
    }).toList();
  }

  /// Adds a series group with validation and error handling
  static void addSeriesGroup({
    required int weekIndex,
    required int sessionIndex,
    required int groupIndex,
    required List<List<WeekProgression>> weekProgressions,
    required Exercise exercise,
  }) {
    if (!ValidationUtils.isValidProgressionIndex(
        weekProgressions, weekIndex, sessionIndex)) {
      throw ArgumentError('Invalid progression indices');
    }

    try {
      final newSeries = _createDefaultSeries(groupIndex);
      final currentSession = weekProgressions[weekIndex][sessionIndex];

      currentSession.series = List.from(currentSession.series)..add(newSeries);
      weekProgressions[weekIndex][sessionIndex] = currentSession;
    } catch (e) {
      throw Exception('Failed to add series group: $e');
    }
  }

  /// Removes a series group with improved error handling
  static void removeSeriesGroup({
    required int weekIndex,
    required int sessionIndex,
    required int groupIndex,
    required List<List<WeekProgression>> weekProgressions,
  }) {
    if (!ValidationUtils.isValidProgressionIndex(
        weekProgressions, weekIndex, sessionIndex)) {
      throw ArgumentError('Invalid progression indices');
    }

    try {
      final session = weekProgressions[weekIndex][sessionIndex];
      final groupedSeries = ModelUtils.groupSimilarSeries(session.series);

      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        groupedSeries.removeAt(groupIndex);
        session.series = groupedSeries.expand((group) => group).toList();
      }
    } catch (e) {
      throw Exception('Failed to remove series group: $e');
    }
  }

  /// Updates series with improved validation and null safety
  static void updateSeries({
    required SeriesUpdateParams params,
    required List<List<WeekProgression>> weekProgressions,
  }) {
    if (!ValidationUtils.isValidProgressionIndex(
        weekProgressions, params.weekIndex, params.sessionIndex)) {
      throw ArgumentError('Invalid progression indices');
    }

    try {
      final session = weekProgressions[params.weekIndex][params.sessionIndex];
      if (session.series.isEmpty) return;

      final groupedSeries = ModelUtils.groupSimilarSeries(session.series);

      if (!_isValidGroupIndex(params.groupIndex, groupedSeries.length)) {
        throw ArgumentError('Invalid group index');
      }

      final currentGroup = groupedSeries[params.groupIndex];
      if (currentGroup.isEmpty) return;

      final updatedGroup = currentGroup.map((series) {
        return _updateSeriesFromParams(series, params);
      }).toList();

      groupedSeries[params.groupIndex] = updatedGroup;
      session.series = groupedSeries.expand((group) => group).toList();

      weekProgressions[params.weekIndex][params.sessionIndex] = session;
    } catch (e) {
      throw Exception('Failed to update series: $e');
    }
  }

  /// Validates progression data comprehensively
  static bool validateProgression({
    required Exercise exercise,
    required List<List<WeekProgression>> weekProgressions,
  }) {
    if (!ValidationUtils.isValidExercise(exercise)) {
      return false;
    }

    if (exercise.exerciseId?.isEmpty ?? true) {
      return false;
    }

    return weekProgressions.every((week) {
      return week.every((session) {
        return session.series.every((series) {
          return ValidationUtils.isValidSeries(series);
        });
      });
    });
  }

  /// Creates updated week progressions from controllers with optimized logic
  static List<List<WeekProgression>> createUpdatedWeekProgressions(
    List<List<List<dynamic>>> controllers,
    int Function(String) parseInt,
    double Function(String) parseDouble,
  ) {
    return controllers.asMap().entries.map((weekEntry) {
      final weekIndex = weekEntry.key;
      final weekControllers = weekEntry.value;

      return weekControllers.asMap().entries.map((sessionEntry) {
        final sessionIndex = sessionEntry.key;
        final sessionControllers = sessionEntry.value;

        final series = _createSeriesFromControllers(
          sessionControllers,
          parseInt,
          parseDouble,
        );

        return WeekProgression(
          weekNumber: weekIndex + 1,
          sessionNumber: sessionIndex + 1,
          series: series,
        );
      }).toList();
    }).toList();
  }

  /// Gets the representative series for a group with null safety
  static Series getRepresentativeSeries(List<Series> group, int groupIndex) {
    if (group.isEmpty) {
      throw ArgumentError('Group cannot be empty');
    }

    final firstSeries = group.first;
    return firstSeries.copyWith(sets: group.length);
  }

  // Private helper methods

  /// Finds exercise in workout by exercise ID
  static Exercise? _findExerciseInWorkout(Workout workout, String exerciseId) {
    try {
      return workout.exercises.firstWhere(
        (e) => e.exerciseId == exerciseId,
        orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
      );
    } catch (e) {
      return null;
    }
  }

  /// Creates week progression for a specific week and session
  static WeekProgression _createWeekProgression(
    int weekIndex,
    int sessionOrder,
    Exercise exerciseInWorkout,
    List<List<WeekProgression>> existingProgressions,
  ) {
    // Check for existing progressions
    if (existingProgressions.isNotEmpty &&
        weekIndex < existingProgressions.length) {
      final existingProgression = existingProgressions[weekIndex].firstWhere(
        (progression) => progression.sessionNumber == sessionOrder,
        orElse: () => WeekProgression(
          weekNumber: weekIndex + 1,
          sessionNumber: sessionOrder,
          series: [],
        ),
      );

      if (existingProgression.series.isNotEmpty) {
        return _createProgressionFromExisting(
            existingProgression, weekIndex, sessionOrder);
      }
    }

    // Create from exercise series
    return _createProgressionFromExercise(
        exerciseInWorkout, weekIndex, sessionOrder);
  }

  /// Creates progression from existing progression data
  static WeekProgression _createProgressionFromExisting(
    WeekProgression existingProgression,
    int weekIndex,
    int sessionOrder,
  ) {
    final groupedSeries =
        ModelUtils.groupSimilarSeries(existingProgression.series);
    final representativeSeries =
        groupedSeries.map(ModelUtils.createRepresentativeSeries).toList();

    return WeekProgression(
      weekNumber: weekIndex + 1,
      sessionNumber: sessionOrder,
      series: representativeSeries,
    );
  }

  /// Creates progression from exercise series
  static WeekProgression _createProgressionFromExercise(
    Exercise exercise,
    int weekIndex,
    int sessionOrder,
  ) {
    final groupedSeries = ModelUtils.groupSimilarSeries(exercise.series);
    final representativeSeries =
        groupedSeries.map(ModelUtils.createRepresentativeSeries).toList();

    return WeekProgression(
      weekNumber: weekIndex + 1,
      sessionNumber: sessionOrder,
      series: representativeSeries,
    );
  }

  /// Creates a default series for new groups
  static Series _createDefaultSeries(int order) {
    return Series(
      serieId: DateTime.now().millisecondsSinceEpoch.toString(),
      reps: 0,
      sets: 1,
      intensity: '',
      rpe: '',
      weight: 0.0,
      order: order + 1,
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
  }

  /// Creates series from controllers with error handling
  static List<Series> _createSeriesFromControllers(
    List<dynamic> controllers,
    int Function(String) parseInt,
    double Function(String) parseDouble,
  ) {
    final series = <Series>[];

    for (int i = 0; i < controllers.length; i++) {
      final controller = controllers[i];
      final sets = parseInt(_getControllerText(controller, 'sets'));

      for (int j = 0; j < sets; j++) {
        series.add(Series(
          serieId: '${DateTime.now().millisecondsSinceEpoch}_${i}_$j',
          reps: parseInt(_getControllerText(controller, 'reps', 'min')),
          maxReps:
              _parseOptionalInt(_getControllerText(controller, 'reps', 'max')),
          sets: 1,
          intensity: _getControllerText(controller, 'intensity', 'min'),
          maxIntensity: _parseOptionalString(
              _getControllerText(controller, 'intensity', 'max')),
          rpe: _getControllerText(controller, 'rpe', 'min'),
          maxRpe: _parseOptionalString(
              _getControllerText(controller, 'rpe', 'max')),
          weight: parseDouble(_getControllerText(controller, 'weight', 'min')),
          maxWeight: _parseOptionalDouble(
              _getControllerText(controller, 'weight', 'max')),
          order: series.length + 1,
          done: false,
          reps_done: 0,
          weight_done: 0.0,
        ));
      }
    }

    return series;
  }

  /// Safely gets text from controller
  static String _getControllerText(dynamic controller, String field,
      [String? subField]) {
    try {
      dynamic fieldController = controller;

      // Navigate to the field
      if (fieldController.hasProperty(field)) {
        fieldController = fieldController.getProperty(field);
      }

      // Navigate to the subfield if provided
      if (subField != null && fieldController.hasProperty(subField)) {
        fieldController = fieldController.getProperty(subField);
      }

      // Get text if it has a text property
      if (fieldController.hasProperty('text')) {
        return fieldController.getProperty('text').toString();
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  /// Updates series from parameters with safe parsing
  static Series _updateSeriesFromParams(
      Series series, SeriesUpdateParams params) {
    return series.copyWith(
      reps: _parseIntOrKeepOriginal(params.reps, series.reps),
      maxReps: _parseOptionalInt(params.maxReps),
      sets: _parseIntOrKeepOriginal(params.sets, series.sets),
      intensity: _parseStringOrKeepOriginal(params.intensity, series.intensity),
      maxIntensity: _parseOptionalString(params.maxIntensity),
      rpe: _parseStringOrKeepOriginal(params.rpe, series.rpe),
      maxRpe: _parseOptionalString(params.maxRpe),
      weight: _parseDoubleOrKeepOriginal(params.weight, series.weight),
      maxWeight: _parseOptionalDouble(params.maxWeight),
    );
  }

  /// Validates group index
  static bool _isValidGroupIndex(int groupIndex, int maxGroups) {
    return groupIndex >= 0 && groupIndex < maxGroups;
  }

  // Safe parsing methods

  static int _parseIntOrKeepOriginal(String? value, int original) {
    if (value?.isEmpty ?? true) return original;
    return int.tryParse(value!) ?? original;
  }

  static double _parseDoubleOrKeepOriginal(String? value, double original) {
    if (value?.isEmpty ?? true) return original;
    return double.tryParse(value!) ?? original;
  }

  static String _parseStringOrKeepOriginal(String? value, String original) {
    return value?.isEmpty ?? true ? original : value!;
  }

  static int? _parseOptionalInt(String? value) {
    if (value?.isEmpty ?? true) return null;
    return int.tryParse(value!);
  }

  static double? _parseOptionalDouble(String? value) {
    if (value?.isEmpty ?? true) return null;
    return double.tryParse(value!);
  }

  static String? _parseOptionalString(String? value) {
    return value?.isEmpty ?? true ? null : value;
  }
}

/// Extension to check if dynamic object has property (placeholder)
extension DynamicExtension on dynamic {
  bool hasProperty(String property) {
    try {
      // This would need actual implementation based on your controller structure
      return true;
    } catch (e) {
      return false;
    }
  }

  dynamic getProperty(String property) {
    try {
      // This would need actual implementation based on your controller structure
      return this;
    } catch (e) {
      return null;
    }
  }
}
