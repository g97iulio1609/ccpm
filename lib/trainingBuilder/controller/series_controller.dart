import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../training_model.dart';
import 'package:alphanessone/users_services.dart';
import '../utility_functions.dart';

class SeriesController {
  SeriesController();

  Future<void> addSeries(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final seriesList = await _showSeriesDialog(context, exercise, weekIndex);
    if (seriesList != null) {
      for (final series in seriesList) {
        series.serieId = null;
        _calculateWeight(series, exercise.type, context, program.athleteId, exercise.exerciseId!);
      }
      exercise.series.addAll(seriesList);
    }
  }

  Future<List<Series>?> _showSeriesDialog(
      BuildContext context, Exercise exercise, int weekIndex,
      [Series? currentSeries]) async {
    final usersService = ProviderScope.containerOf(context).read(usersServiceProvider);
    return await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        usersService: usersService,
        athleteId: exercise.exerciseId ?? '',
        exerciseId: exercise.exerciseId ?? '',
        weekIndex: weekIndex,
        exercise: exercise,
        currentSeries: currentSeries,
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
      for (final series in updatedSeriesList) {
        _calculateWeight(series, exercise.type, context, program.athleteId, exercise.exerciseId!);
      }
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
          .series
          .replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);
    }
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

  void _calculateWeight(Series series, String? exerciseType, BuildContext context, String athleteId, String exerciseId) async {
    if (series.intensity.isNotEmpty) {
      final intensity = double.tryParse(series.intensity) ?? 0;
      final latestMaxWeight = await getLatestMaxWeight(
        ProviderScope.containerOf(context).read(usersServiceProvider),
        athleteId,
        exerciseId,
      );
      final calculatedWeight = calculateWeightFromIntensity(latestMaxWeight, intensity);
      series.weight = roundWeight(calculatedWeight, exerciseType);
    } else if (series.rpe.isNotEmpty) {
      final rpe = double.tryParse(series.rpe) ?? 0;
      final rpePercentage = getRPEPercentage(rpe, series.reps);
      final latestMaxWeight = await getLatestMaxWeight(
        ProviderScope.containerOf(context).read(usersServiceProvider),
        athleteId,
        exerciseId,
      );
      final calculatedWeight = latestMaxWeight * rpePercentage;
      series.weight = roundWeight(calculatedWeight, exerciseType);
    } else {
      series.intensity = calculateIntensityFromWeight(
        series.weight,
        await getLatestMaxWeight(
          ProviderScope.containerOf(context).read(usersServiceProvider),
          athleteId,
          exerciseId,
        ),
      ).toStringAsFixed(2);
      
      final rpe = calculateRPE(
        series.weight,
        await getLatestMaxWeight(
          ProviderScope.containerOf(context).read(usersServiceProvider),
          athleteId,
          exerciseId,
        ),
        series.reps,
      );
      series.rpe = rpe != null ? rpe.toStringAsFixed(1) : '';
    }
  }
}