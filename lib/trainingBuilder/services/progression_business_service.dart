import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/models/progression_view_model.dart';
import 'package:alphanessone/trainingBuilder/services/progression_service.dart';
import 'package:alphanessone/trainingBuilder/controllers/progression_controllers.dart';

/// Business service for progression operations following dependency inversion principle
class ProgressionBusinessService {
  static List<List<WeekProgression>> buildWeekProgressions(
    List<Week> weeks,
    Exercise exercise,
  ) {
    return ProgressionService.buildWeekProgressions(weeks, exercise);
  }

  /// Adds a new series group to the specified position
  static void addSeriesGroup({
    required int weekIndex,
    required int sessionIndex,
    required int groupIndex,
    required List<List<WeekProgression>> weekProgressions,
    required Exercise exercise,
  }) {
    if (!ProgressionService.isValidIndex(
        weekProgressions, weekIndex, sessionIndex)) {
      return;
    }

    final newSeries = ProgressionService.createNewSeries(
      weekIndex: weekIndex,
      sessionIndex: sessionIndex,
      groupIndex: groupIndex,
    );

    final currentSession = weekProgressions[weekIndex][sessionIndex];
    final updatedSeries = List<Series>.from(currentSession.series)
      ..add(newSeries);
    currentSession.series = updatedSeries;

    weekProgressions[weekIndex][sessionIndex] = currentSession;
  }

  /// Removes a series group from the specified position
  static void removeSeriesGroup({
    required int weekIndex,
    required int sessionIndex,
    required int groupIndex,
    required List<List<WeekProgression>> weekProgressions,
  }) {
    if (!ProgressionService.isValidIndex(
        weekProgressions, weekIndex, sessionIndex)) {
      return;
    }

    final groupedSeries = ProgressionService.groupSeries(
        weekProgressions[weekIndex][sessionIndex].series);

    if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
      groupedSeries.removeAt(groupIndex);
      weekProgressions[weekIndex][sessionIndex].series =
          groupedSeries.expand((group) => group).toList();
    }
  }

  /// Updates series with new values - Fixed null handling
  static void updateSeries({
    required SeriesUpdateParams params,
    required List<List<WeekProgression>> weekProgressions,
  }) {
    if (!ProgressionService.isValidIndex(
        weekProgressions, params.weekIndex, params.sessionIndex)) {
      return;
    }

    try {
      final session = weekProgressions[params.weekIndex][params.sessionIndex];
      if (session.series.isEmpty) return;

      final groupedSeries = ProgressionService.groupSeries(session.series);

      if (params.groupIndex >= 0 && params.groupIndex < groupedSeries.length) {
        final currentGroup = groupedSeries[params.groupIndex];

        // Ensure we have valid series to update
        if (currentGroup.isEmpty) return;

        final updatedGroup = currentGroup.map((series) {
          return _updateSeriesFromParams(series, params);
        }).toList();

        // Validate updated group
        if (updatedGroup.isEmpty) {
          throw Exception('Failed to update series: invalid series data');
        }

        groupedSeries[params.groupIndex] = updatedGroup;
        session.series = groupedSeries.expand((group) => group).toList();

        // Update the session in weekProgressions
        weekProgressions[params.weekIndex][params.sessionIndex] = session;
      }
    } catch (e) {
      throw Exception('Error updating series: $e');
    }
  }

  /// Creates updated week progressions from controllers
  static List<List<WeekProgression>> createUpdatedWeekProgressions(
    List<List<List<ProgressionControllers>>> controllers,
    int Function(String) parseInt,
    double Function(String) parseDouble,
  ) {
    return ProgressionService.createUpdatedWeekProgressions(
      controllers,
      parseInt,
      parseDouble,
    );
  }

  /// Validates progression data
  static bool validateProgression({
    required Exercise exercise,
    required List<List<WeekProgression>> weekProgressions,
  }) {
    if (exercise.exerciseId == null || exercise.exerciseId!.isEmpty) {
      return false;
    }

    for (final week in weekProgressions) {
      for (final session in week) {
        if (session.series.isEmpty) continue;

        for (final series in session.series) {
          if (!_isValidSeries(series)) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// Gets the representative series for a group - Fixed null handling
  static Series getRepresentativeSeries(
    List<Series> group,
    int groupIndex,
  ) {
    if (group.isEmpty) {
      throw ArgumentError('Group cannot be empty');
    }

    final firstSeries = group.first;

    try {
      return firstSeries.copyWith(sets: group.length);
    } catch (e) {
      throw Exception('Failed to create representative series: $e');
    }
  }

  /// Checks if indices are valid for progression operations
  static bool isValidIndex(
    List<List<WeekProgression>> weekProgressions,
    int weekIndex,
    int sessionIndex, [
    int? groupIndex,
  ]) {
    return ProgressionService.isValidIndex(
      weekProgressions,
      weekIndex,
      sessionIndex,
      groupIndex,
    );
  }

  /// Updates series from parameters with improved null safety
  static Series _updateSeriesFromParams(
      Series series, SeriesUpdateParams params) {
    try {
      return series.copyWith(
        reps: _parseIntOrKeepOriginal(params.reps, series.reps),
        maxReps: _parseOptionalInt(params.maxReps),
        sets: _parseIntOrKeepOriginal(params.sets, series.sets),
        intensity: _parseOptionalString(params.intensity),
        maxIntensity: _parseOptionalString(params.maxIntensity),
        rpe: _parseOptionalString(params.rpe),
        maxRpe: _parseOptionalString(params.maxRpe),
        weight: _parseDoubleOrKeepOriginal(params.weight, series.weight),
        maxWeight: _parseOptionalDouble(params.maxWeight),
      );
    } catch (e) {
      throw Exception('Failed to update series from params: $e');
    }
  }

  /// Helper methods for safe parsing
  static int _parseIntOrKeepOriginal(String? value, int original) {
    if (value == null || value.isEmpty) return original;
    return int.tryParse(value) ?? original;
  }

  static int? _parseOptionalInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  static double _parseDoubleOrKeepOriginal(String? value, double original) {
    if (value == null || value.isEmpty) return original;
    return double.tryParse(value) ?? original;
  }

  static double? _parseOptionalDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }

  static String? _parseOptionalString(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static bool _isValidSeries(Series series) {
    try {
      // Basic validation for series data
      if (series.reps < 0 || series.sets < 0) return false;
      if (series.weight < 0) return false;
      if (series.maxReps != null && series.maxReps! < series.reps) return false;
      if (series.maxWeight != null && series.maxWeight! < series.weight) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
