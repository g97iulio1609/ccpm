import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/models/progressions_model.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/range_controllers.dart';

import 'package:alphanessone/trainingBuilder/services/progression_service.dart';

/// Controller for progression data following single responsibility principle
class ProgressionControllers {
  final RangeControllers reps;
  final TextEditingController sets;
  final RangeControllers intensity;
  final RangeControllers rpe;
  final RangeControllers weight;

  ProgressionControllers()
      : reps = RangeControllers(),
        sets = TextEditingController(),
        intensity = RangeControllers(),
        rpe = RangeControllers(),
        weight = RangeControllers();

  void dispose() {
    reps.dispose();
    sets.dispose();
    intensity.dispose();
    rpe.dispose();
    weight.dispose();
  }

  void updateFromSeries(Series series) {
    try {
      // Safely update all fields with null checks
      reps.min.text = _formatNumber(series.reps.toString());
      reps.max.text = _formatNumber(series.maxReps?.toString() ?? '');
      sets.text = _formatNumber(series.sets.toString());
      intensity.min.text = _formatNumber(series.intensity ?? '');
      intensity.max.text = _formatNumber(series.maxIntensity ?? '');
      rpe.min.text = _formatNumber(series.rpe ?? '');
      rpe.max.text = _formatNumber(series.maxRpe ?? '');
      weight.min.text = _formatNumber(series.weight.toString());
      weight.max.text = _formatNumber(series.maxWeight?.toString() ?? '');
    } catch (e) {
      debugPrint('WARNING: Error updating controllers from series: $e');
      // Set safe defaults in case of error
      _setSafeDefaults();
    }
  }

  String _formatNumber(String value) {
    if (value.isEmpty) return '';
    final num? parsed = num.tryParse(value);
    if (parsed == null) return value;
    return parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toStringAsFixed(1);
  }

  /// Sets safe default values to prevent null errors
  void _setSafeDefaults() {
    reps.min.text = '0';
    reps.max.text = '';
    sets.text = '1';
    intensity.min.text = '';
    intensity.max.text = '';
    rpe.min.text = '';
    rpe.max.text = '';
    weight.min.text = '0';
    weight.max.text = '';
  }

  /// Gets the display text for load field
  String getLoadDisplayText(double latestMaxWeight) {
    try {
      return ProgressionService.getLoadDisplayText(
        minIntensity: intensity.min.text,
        maxIntensity: intensity.max.text,
        minRpe: rpe.min.text,
        maxRpe: rpe.max.text,
        latestMaxWeight: latestMaxWeight,
      );
    } catch (e) {
      debugPrint('WARNING: Error getting load display text: $e');
      return 'N/A';
    }
  }
}

/// StateNotifier for managing progression controllers following dependency inversion
class ProgressionControllersNotifier
    extends StateNotifier<List<List<List<ProgressionControllers>>>> {
  ProgressionControllersNotifier() : super([]);

  void initialize(List<List<WeekProgression>> weekProgressions) {
    state = weekProgressions
        .map((week) => week
            .map((session) =>
                session.series.map((_) => ProgressionControllers()).toList())
            .toList())
        .toList();

    _initializeFromProgressions(weekProgressions);
  }

  void _initializeFromProgressions(
      List<List<WeekProgression>> weekProgressions) {
    for (int weekIndex = 0; weekIndex < weekProgressions.length; weekIndex++) {
      for (int sessionIndex = 0;
          sessionIndex < weekProgressions[weekIndex].length;
          sessionIndex++) {
        final seriesFromProgressions =
            weekProgressions[weekIndex][sessionIndex].series;
        for (int seriesIndex = 0;
            seriesIndex < seriesFromProgressions.length;
            seriesIndex++) {
          final series = seriesFromProgressions[seriesIndex];
          updateControllers(weekIndex, sessionIndex, seriesIndex, series);
        }
      }
    }
  }

  void updateControllers(
      int weekIndex, int sessionIndex, int groupIndex, Series series) {
    if (ProgressionService.isValidIndex(
        state, weekIndex, sessionIndex, groupIndex)) {
      final controllers = state[weekIndex][sessionIndex][groupIndex];
      controllers.updateFromSeries(series);
      state = [...state];
    }
  }

  void addControllers(int weekIndex, int sessionIndex, int groupIndex) {
    if (ProgressionService.isValidIndex(state, weekIndex, sessionIndex)) {
      final newControllers = ProgressionControllers();
      final newState = List<List<List<ProgressionControllers>>>.from(state);
      newState[weekIndex][sessionIndex].insert(groupIndex, newControllers);
      state = newState;
    }
  }

  void removeControllers(int weekIndex, int sessionIndex, int groupIndex) {
    if (ProgressionService.isValidIndex(
        state, weekIndex, sessionIndex, groupIndex)) {
      final newState = List<List<List<ProgressionControllers>>>.from(state);
      newState[weekIndex][sessionIndex].removeAt(groupIndex);
      state = newState;
    }
  }
}

/// Provider for progression controllers
final progressionControllersProvider = StateNotifierProvider<
    ProgressionControllersNotifier,
    List<List<List<ProgressionControllers>>>>((ref) {
  return ProgressionControllersNotifier();
});
