import 'package:alphanessone/shared/shared.dart';

import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:alphanessone/shared/services/weight_calculation_service.dart';

/// Service for handling progression-related business logic
class ProgressionService {
  ProgressionService._();

  /// Groups series based on their properties
  static List<List<Series>> groupSeries(List<Series> series) {
    if (series.isEmpty) return [];

    final groupedSeries = <List<Series>>[];
    List<Series> currentGroup = [series[0]];

    for (int i = 1; i < series.length; i++) {
      final currentSeries = series[i];
      final previousSeries = series[i - 1];

      if (_isSameGroup(currentSeries, previousSeries)) {
        currentGroup.add(currentSeries);
      } else {
        groupedSeries.add(List<Series>.from(currentGroup));
        currentGroup = [currentSeries];
      }
    }

    if (currentGroup.isNotEmpty) {
      groupedSeries.add(currentGroup);
    }

    return groupedSeries;
  }

  /// Checks if two series belong to the same group
  static bool _isSameGroup(Series a, Series b) {
    return a.reps == b.reps &&
        a.maxReps == b.maxReps &&
        a.intensity == b.intensity &&
        a.maxIntensity == b.maxIntensity &&
        a.rpe == b.rpe &&
        a.maxRpe == b.maxRpe &&
        a.weight == b.weight &&
        a.maxWeight == b.maxWeight;
  }

  /// Builds week progressions for an exercise
  static List<List<WeekProgression>> buildWeekProgressions(List<Week> weeks, Exercise exercise) {
    return List.generate(weeks.length, (weekIndex) {
      final week = weeks[weekIndex];
      return week.workouts.map((workout) {
        final exerciseInWorkout = workout.exercises.firstWhere(
          (e) => e.exerciseId == exercise.exerciseId,
          orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
        );

        final existingProgressions = exerciseInWorkout.weekProgressions;
        WeekProgression? sessionProgression;

        if (existingProgressions?.isNotEmpty == true && existingProgressions!.length > weekIndex) {
          try {
            sessionProgression = existingProgressions[weekIndex].firstWhere(
              (progression) => progression.sessionNumber == workout.order,
            );
          } catch (e) {
            sessionProgression = WeekProgression(
              weekNumber: weekIndex + 1,
              sessionNumber: workout.order,
              series: [],
            );
          }
        }

        if (sessionProgression?.series.isNotEmpty == true) {
          final groupedSeries = groupSeries(sessionProgression!.series);
          return WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: workout.order,
            series: groupedSeries.map((group) {
              final firstSeries = group.first;
              return Series(
                serieId: firstSeries.serieId,
                reps: firstSeries.reps,
                maxReps: firstSeries.maxReps,
                sets: group.length,
                intensity: firstSeries.intensity,
                maxIntensity: firstSeries.maxIntensity,
                rpe: firstSeries.rpe,
                maxRpe: firstSeries.maxRpe,
                weight: firstSeries.weight,
                maxWeight: firstSeries.maxWeight,
                order: firstSeries.order,
                done: firstSeries.done,
                repsDone: firstSeries.repsDone,
                weightDone: firstSeries.weightDone,
                exerciseId: firstSeries.exerciseId,
              );
            }).toList(),
          );
        } else {
          final groupedSeries = groupSeries(exerciseInWorkout.series);
          return WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: workout.order,
            series: groupedSeries.map((group) {
              final firstSeries = group.first;
              return Series(
                serieId: firstSeries.serieId,
                reps: firstSeries.reps,
                maxReps: firstSeries.maxReps,
                sets: group.length,
                intensity: firstSeries.intensity,
                maxIntensity: firstSeries.maxIntensity,
                rpe: firstSeries.rpe,
                maxRpe: firstSeries.maxRpe,
                weight: firstSeries.weight,
                maxWeight: firstSeries.maxWeight,
                order: firstSeries.order,
                done: firstSeries.done,
                repsDone: firstSeries.repsDone,
                weightDone: firstSeries.weightDone,
                exerciseId: firstSeries.exerciseId,
              );
            }).toList(),
          );
        }
      }).toList();
    });
  }

  /// Updates weight based on intensity
  static void updateWeightFromIntensity({
    required String minIntensity,
    required String maxIntensity,
    required double latestMaxWeight,
    required String exerciseType,
    required void Function(String, String) onUpdate,
  }) {
    final minIntensityValue = double.tryParse(minIntensity) ?? 0;
    final minWeight = WeightCalculationService.calculateWeightFromIntensity(
      latestMaxWeight,
      minIntensityValue,
    );
    final roundedMinWeight = WeightCalculationService.roundWeight(minWeight, exerciseType);

    String maxWeightValue = '';
    if (maxIntensity.isNotEmpty) {
      final maxIntensityValue = double.tryParse(maxIntensity) ?? 0;
      final maxWeight = WeightCalculationService.calculateWeightFromIntensity(
        latestMaxWeight,
        maxIntensityValue,
      );
      final roundedMaxWeight = WeightCalculationService.roundWeight(maxWeight, exerciseType);
      maxWeightValue = roundedMaxWeight.toStringAsFixed(1);
    }

    onUpdate(roundedMinWeight.toStringAsFixed(1), maxWeightValue);
  }

  /// Updates intensity based on weight
  static void updateIntensityFromWeight({
    required String minWeight,
    required String maxWeight,
    required double latestMaxWeight,
    required void Function(String, String) onUpdate,
  }) {
    final minWeightValue = double.tryParse(minWeight) ?? 0;
    final minIntensity = WeightCalculationService.calculateIntensityFromWeight(
      minWeightValue,
      latestMaxWeight,
    );

    String maxIntensityValue = '';
    if (maxWeight.isNotEmpty) {
      final maxWeightValue = double.tryParse(maxWeight) ?? 0;
      final maxIntensity = WeightCalculationService.calculateIntensityFromWeight(
        maxWeightValue,
        latestMaxWeight,
      );
      maxIntensityValue = maxIntensity.toStringAsFixed(1);
    }

    onUpdate(minIntensity.toStringAsFixed(1), maxIntensityValue);
  }

  /// Creates a new series for progression
  static Series createNewSeries({
    required int weekIndex,
    required int sessionIndex,
    required int groupIndex,
  }) {
    return Series(
      serieId: generateRandomId(16).toString(),
      exerciseId: '',
      reps: 0,
      sets: 1,
      intensity: '',
      rpe: '',
      weight: 0.0,
      order: groupIndex + 1,
      done: false,
      repsDone: 0,
      weightDone: 0.0,
    );
  }

  /// Validates indices for progression operations
  static bool isValidIndex(List list, int index1, [int? index2, int? index3]) {
    return index1 >= 0 &&
        index1 < list.length &&
        (index2 == null || (index2 >= 0 && index2 < list[index1].length)) &&
        (index3 == null || (index3 >= 0 && index3 < list[index1][index2].length));
  }

  /// Creates updated week progressions with new series
  static List<List<WeekProgression>> createUpdatedWeekProgressions(
    List<List<List<dynamic>>> controllers,
    int Function(String) parseAndDefaultInt,
    double Function(String) parseAndDefaultDouble,
  ) {
    List<List<WeekProgression>> updatedWeekProgressions = [];

    for (int weekIndex = 0; weekIndex < controllers.length; weekIndex++) {
      List<WeekProgression> weekProgressions = [];
      for (int sessionIndex = 0; sessionIndex < controllers[weekIndex].length; sessionIndex++) {
        List<Series> updatedSeries = [];

        // Itera attraverso ogni gruppo
        for (
          int groupIndex = 0;
          groupIndex < controllers[weekIndex][sessionIndex].length;
          groupIndex++
        ) {
          final groupControllers = controllers[weekIndex][sessionIndex][groupIndex];
          final sets = parseAndDefaultInt(groupControllers.sets.text);

          // Crea il numero corretto di serie per questo gruppo
          for (int i = 0; i < sets; i++) {
            updatedSeries.add(
              Series(
                serieId: generateRandomId(16).toString(),
                exerciseId: '',
                reps: parseAndDefaultInt(groupControllers.reps.min.text),
                maxReps: int.tryParse(groupControllers.reps.max.text),
                sets: 1, // Ogni serie individuale ha sets=1
                intensity: groupControllers.intensity.min.text,
                maxIntensity: groupControllers.intensity.max.text.isNotEmpty
                    ? groupControllers.intensity.max.text
                    : null,
                rpe: groupControllers.rpe.min.text,
                maxRpe: groupControllers.rpe.max.text.isNotEmpty
                    ? groupControllers.rpe.max.text
                    : null,
                weight: parseAndDefaultDouble(groupControllers.weight.min.text),
                maxWeight: double.tryParse(groupControllers.weight.max.text),
                order: updatedSeries.length + 1,
                done: false,
                repsDone: 0,
                weightDone: 0.0,
              ),
            );
          }
        }

        weekProgressions.add(
          WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: sessionIndex + 1,
            series: updatedSeries,
          ),
        );
      }
      updatedWeekProgressions.add(weekProgressions);
    }

    return updatedWeekProgressions;
  }

  /// Gets load display text for UI
  static String getLoadDisplayText({
    required String minIntensity,
    required String maxIntensity,
    required String minRpe,
    required String maxRpe,
    required double latestMaxWeight,
  }) {
    final List<String> values = [];

    // Mostra percentuale e peso calcolato
    if (minIntensity.isNotEmpty) {
      final minIntensityValue = double.tryParse(minIntensity) ?? 0;
      final maxIntensityValue = maxIntensity.isNotEmpty ? double.tryParse(maxIntensity) : null;

      final minWeight = WeightCalculationService.calculateWeightFromIntensity(
        latestMaxWeight,
        minIntensityValue,
      );
      final maxWeight = maxIntensityValue != null
          ? WeightCalculationService.calculateWeightFromIntensity(
              latestMaxWeight,
              maxIntensityValue,
            )
          : null;

      String intensityText = minIntensityValue.toString();
      if (maxIntensityValue != null && maxIntensityValue > 0) {
        intensityText = '$minIntensityValue-$maxIntensityValue';
      }

      String weightText = minWeight.toStringAsFixed(1);
      if (maxWeight != null && maxWeight > minWeight) {
        weightText = '${minWeight.toStringAsFixed(1)}-${maxWeight.toStringAsFixed(1)}';
      }

      values.add('$intensityText% ($weightText kg)');
    }

    // RPE
    if (minRpe.isNotEmpty) {
      final minRpeValue = double.tryParse(minRpe) ?? 0;
      final maxRpeValue = maxRpe.isNotEmpty ? double.tryParse(maxRpe) : null;

      String rpeText = minRpeValue.toString();
      if (maxRpeValue != null && maxRpeValue > 0 && maxRpeValue != minRpeValue) {
        rpeText = '$minRpeValue-$maxRpeValue';
      }

      values.add('RPE: $rpeText');
    }

    return values.join('\n\n');
  }
}
