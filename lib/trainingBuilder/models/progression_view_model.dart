import 'package:flutter/material.dart';
import 'package:alphanessone/shared/shared.dart';

import 'package:alphanessone/trainingBuilder/controllers/progression_controllers.dart';

/// View model for progression data following MVVM pattern
class ProgressionViewModel {
  final String exerciseId;
  final Exercise? exercise;
  final num latestMaxWeight;
  final List<List<WeekProgression>> weekProgressions;
  final List<List<List<ProgressionControllers>>> controllers;
  final ColorScheme colorScheme;
  final ThemeData theme;

  const ProgressionViewModel({
    required this.exerciseId,
    required this.exercise,
    required this.latestMaxWeight,
    required this.weekProgressions,
    required this.controllers,
    required this.colorScheme,
    required this.theme,
  });

  /// Gets maximum sessions across all weeks
  int get maxSessions => weekProgressions.fold<int>(
    0,
    (max, week) => week.length > max ? week.length : max,
  );

  /// Gets non-empty session numbers
  List<int> getNonEmptySessions() {
    final nonEmptySessions = <int>[];
    for (int sessionNumber = 0; sessionNumber < maxSessions; sessionNumber++) {
      bool hasData = false;
      for (
        int weekIndex = 0;
        weekIndex < weekProgressions.length;
        weekIndex++
      ) {
        if (weekIndex < controllers.length &&
            sessionNumber < controllers[weekIndex].length &&
            controllers[weekIndex][sessionNumber].isNotEmpty) {
          hasData = true;
          break;
        }
      }
      if (hasData) {
        nonEmptySessions.add(sessionNumber);
      }
    }
    return nonEmptySessions;
  }

  /// Checks if controllers are available for given indices
  bool hasControllersFor(int weekIndex, int sessionIndex) {
    return weekIndex < controllers.length &&
        sessionIndex < controllers[weekIndex].length &&
        controllers[weekIndex][sessionIndex].isNotEmpty;
  }

  /// Gets session controllers for given indices
  List<ProgressionControllers>? getSessionControllers(
    int weekIndex,
    int sessionIndex,
  ) {
    if (hasControllersFor(weekIndex, sessionIndex)) {
      return controllers[weekIndex][sessionIndex];
    }
    return null;
  }

  /// Checks if device is small screen
  bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  /// Checks if device is very small screen
  bool isVerySmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Creates a copy with updated values
  ProgressionViewModel copyWith({
    String? exerciseId,
    Exercise? exercise,
    num? latestMaxWeight,
    List<List<WeekProgression>>? weekProgressions,
    List<List<List<ProgressionControllers>>>? controllers,
    ColorScheme? colorScheme,
    ThemeData? theme,
  }) {
    return ProgressionViewModel(
      exerciseId: exerciseId ?? this.exerciseId,
      exercise: exercise ?? this.exercise,
      latestMaxWeight: latestMaxWeight ?? this.latestMaxWeight,
      weekProgressions: weekProgressions ?? this.weekProgressions,
      controllers: controllers ?? this.controllers,
      colorScheme: colorScheme ?? this.colorScheme,
      theme: theme ?? this.theme,
    );
  }
}

/// Parameters for series update operations
class SeriesUpdateParams {
  final int weekIndex;
  final int sessionIndex;
  final int groupIndex;
  final String? reps;
  final String? maxReps;
  final String? sets;
  final String? intensity;
  final String? maxIntensity;
  final String? rpe;
  final String? maxRpe;
  final String? weight;
  final String? maxWeight;

  const SeriesUpdateParams({
    required this.weekIndex,
    required this.sessionIndex,
    required this.groupIndex,
    this.reps,
    this.maxReps,
    this.sets,
    this.intensity,
    this.maxIntensity,
    this.rpe,
    this.maxRpe,
    this.weight,
    this.maxWeight,
  });
}

/// Load update parameters for handling different load types
class LoadUpdateParams {
  final String type;
  final String minValue;
  final String maxValue;
  final String field;

  const LoadUpdateParams({
    required this.type,
    required this.minValue,
    required this.maxValue,
    required this.field,
  });
}
