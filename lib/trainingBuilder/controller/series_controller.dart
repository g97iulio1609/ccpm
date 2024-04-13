import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../training_model.dart';
import 'package:alphanessone/users_services.dart';
import '../utility_functions.dart';

class SeriesController {
  final UsersService usersService;
  final ValueNotifier<double> weightNotifier;

  SeriesController(this.usersService, this.weightNotifier);

Future<void> addSeries(TrainingProgram program, int weekIndex,
    int workoutIndex, int exerciseIndex, BuildContext context) async {
  final exercise = program
      .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

  // Ottieni il peso massimo più recente
  final latestMaxWeight =
      await getLatestMaxWeight(usersService, program.athleteId, exercise.exerciseId ?? '');

  // Converti latestMaxWeight in double o utilizza un valore predefinito
  final double maxWeight = latestMaxWeight != null ? latestMaxWeight.toDouble() : 100.0;

  final seriesList = await _showSeriesDialog(context, exercise, weekIndex, null, maxWeight);
  if (seriesList != null) {
    exercise.series.addAll(seriesList);
    // Aggiorna i pesi delle serie dopo averle aggiunte
    await updateSeriesWeights(program, weekIndex, workoutIndex, exerciseIndex);
  }
}

Future<List<Series>?> _showSeriesDialog(
    BuildContext context, Exercise exercise, int weekIndex,
    [Series? currentSeries, double? latestMaxWeight]) async {
  return await showDialog<List<Series>>(
    context: context,
    builder: (context) => SeriesDialog(
      usersService: usersService,
      athleteId: exercise.exerciseId ?? '',
      exerciseId: exercise.exerciseId ?? '',
      weekIndex: weekIndex,
      exercise: exercise,
      currentSeries: currentSeries,
      latestMaxWeight: latestMaxWeight ?? 100.0,
      weightNotifier: weightNotifier,
    ),
  );
}

  Future<void> editSeries(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    Series currentSeries,
    BuildContext context,
  ) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedSeriesList =
        await _showSeriesDialog(context, exercise, weekIndex, currentSeries);
    if (updatedSeriesList != null) {
      final groupIndex = exercise.series.indexWhere(
        (series) => series.serieId == currentSeries.serieId,
      );
      final seriesIndex = exercise.series.indexOf(currentSeries);
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
          .series
          .replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);
      // Aggiorna i pesi delle serie dopo averle modificate
      await updateSeriesWeights(program, weekIndex, workoutIndex, exerciseIndex);
    }
  }

  Future<void> updateSeriesWeights(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final exerciseId = exercise.exerciseId;
    final athleteId = program.athleteId;
    if (exerciseId != null) {
      final latestMaxWeight =
          await getLatestMaxWeight(usersService, athleteId, exerciseId);
      if (latestMaxWeight != null) {
        for (final series in exercise.series) {
          _calculateWeight(series, exercise.type, latestMaxWeight as double);
        }
      }
    }
  }

  void _calculateWeight(Series series, String? exerciseType, double? latestMaxWeight) {
    debugPrint('Latest Max Weight: $latestMaxWeight');
    debugPrint('Exercise Type: $exerciseType');
    debugPrint('Series Intensity: ${series.intensity}');
    debugPrint('Series RPE: ${series.rpe}');
    debugPrint('Series Reps: ${series.reps}');
    debugPrint('Series Weight: ${series.weight}');

    double calculatedWeight = 0;

    if (latestMaxWeight != null) {
      if (series.intensity.isNotEmpty) {
        final intensity = double.tryParse(series.intensity) ?? 0;
        if (intensity > 0) {
          debugPrint('Intensity: $intensity');
          calculatedWeight = calculateWeightFromIntensity(latestMaxWeight, intensity);
          series.weight = roundWeight(calculatedWeight, exerciseType);
          updateWeightNotifier(series.weight);
        }
      } else if (series.rpe.isNotEmpty) {
        final rpe = double.tryParse(series.rpe) ?? 0;
        if (rpe > 0) {
          debugPrint('RPE: $rpe');
          final rpePercentage = getRPEPercentage(rpe, series.reps);
          calculatedWeight = latestMaxWeight * rpePercentage;
          series.weight = roundWeight(calculatedWeight, exerciseType);
          updateWeightNotifier(series.weight);
        }
      } else {
        series.intensity = calculateIntensityFromWeight(series.weight, latestMaxWeight).toStringAsFixed(2);
        final rpe = calculateRPE(series.weight, latestMaxWeight, series.reps);
        series.rpe = rpe != null ? rpe.toStringAsFixed(1) : '';
      }
    } else {
      debugPrint('Latest Max Weight is null');
    }
  }

  void updateWeightNotifier(double weight) {
    // Update the weight value in the notifier
    weightNotifier.value = weight;
  }

  void removeSeries(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int groupIndex,
    int seriesIndex,
  ) {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final series = exercise.series[groupIndex * 1 + seriesIndex];
    _removeSeriesData(program, series);
    exercise.series.removeAt(groupIndex * 1 + seriesIndex);
    _updateSeriesOrders(program, weekIndex, workoutIndex, exerciseIndex,
        groupIndex * 1 + seriesIndex);
  }

  void _removeSeriesData(TrainingProgram program, Series series) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
  }

  void updateSeries(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex, List<Series> updatedSeries) {
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
        .series = updatedSeries;
  }

  void _updateSeriesOrders(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, int startIndex) {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    for (int i = startIndex; i < exercise.series.length; i++) {
      exercise.series[i].order = i + 1;
    }
  }

  void reorderSeries(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final series = exercise.series.removeAt(oldIndex);
    exercise.series.insert(newIndex, series);
    _updateSeriesOrders(
        program, weekIndex, workoutIndex, exerciseIndex, newIndex);
  }
}