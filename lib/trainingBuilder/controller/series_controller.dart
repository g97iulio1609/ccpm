import 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/series_dialog.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';
import 'package:alphanessone/trainingBuilder/domain/services/series_business_service.dart';
import 'package:flutter/material.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';

class SeriesController {
  final ExerciseRecordService exerciseRecordService;
  final ValueNotifier<double> weightNotifier;

  SeriesController(this.exerciseRecordService, this.weightNotifier);

  Future<void> addSeries(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    BuildContext context,
  ) async {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    // Use the exerciseId as originalExerciseId
    final originalExerciseId = exercise.exerciseId;

    final latestMaxWeight = await ExerciseService.getLatestMaxWeight(
      exerciseRecordService,
      program.athleteId,
      originalExerciseId ?? '',
    );

    if (!context.mounted) return;

    final seriesList = await _showSeriesDialog(
      context,
      exercise,
      program.athleteId,
      weekIndex,
      null,
      exercise.type,
      latestMaxWeight,
    );

    if (seriesList != null && seriesList.isNotEmpty) {
      // Set originalExerciseId for each series
      final updatedSeriesList = seriesList
          .map((series) => series.copyWith(originalExerciseId: originalExerciseId))
          .toList();

      exercise.series.addAll(updatedSeriesList);
      await SeriesUtils.updateSeriesWeights(
        program,
        weekIndex,
        workoutIndex,
        exerciseIndex,
        exerciseRecordService,
      );
      // State update delegated to outer controller
    }
  }

  Future<List<Series>?> _showSeriesDialog(
    BuildContext context,
    Exercise exercise,
    String athleteId,
    int weekIndex,
    List<Series>? currentSeriesGroup,
    String? exerciseType,
    num? latestMaxWeight,
  ) async {
    if (!context.mounted) return null;

    return await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        exerciseRecordService: exerciseRecordService,
        athleteId: athleteId,
        exerciseId: exercise.exerciseId ?? '',
        weekIndex: weekIndex,
        exercise: exercise,
        currentSeriesGroup: currentSeriesGroup,
        latestMaxWeight: latestMaxWeight ?? 0,
        weightNotifier: weightNotifier,
        exerciseType: exerciseType ?? '',
      ),
    );
  }

  Future<void> editSeries(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    List<Series> currentSeriesGroup,
    BuildContext context,
    num latestMaxWeight,
    String exerciseType,
  ) async {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    if (!context.mounted) return;

    final updatedSeries = await _showSeriesDialog(
      context,
      exercise,
      program.athleteId,
      weekIndex,
      currentSeriesGroup,
      exerciseType, // Use the passed exerciseType parameter
      latestMaxWeight,
    );

    if (updatedSeries != null) {
      final startIndex = exercise.series.indexOf(currentSeriesGroup.first);
      if (startIndex != -1) {
        // Remove old series from database
        for (var series in currentSeriesGroup) {
          if (series.serieId != null) {
            program.trackToDeleteSeries.add(series.serieId!);
          }
        }

        // Sostituzione immutabile e ricalcolo order via business service
        final List<Series> newSeriesList = List<Series>.from(exercise.series)
          ..removeRange(startIndex, startIndex + currentSeriesGroup.length)
          ..insertAll(startIndex, updatedSeries);
        final List<Series> recalculated = SeriesBusinessService.recalculateOrders(newSeriesList);
        final updatedExercise = exercise.copyWith(series: recalculated);
        program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;

        await SeriesUtils.updateSeriesWeights(
          program,
          weekIndex,
          workoutIndex,
          exerciseIndex,
          exerciseRecordService,
        );
      }
    }
  }

  void removeAllSeriesForExercise(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    for (final series in exercise.series) {
      removeSeriesData(program, series);
    }
    exercise.series.clear();
    // State update delegated to outer controller
  }

  void removeSeries(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int groupIndex,
    int seriesIndex,
  ) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final totalIndex = groupIndex * 1 + seriesIndex;

    if (totalIndex < 0 || totalIndex >= exercise.series.length) {
      return;
    }

    final series = exercise.series[totalIndex];
    removeSeriesData(program, series);
    exercise.series.removeAt(totalIndex);
    _updateSeriesOrders(program, weekIndex, workoutIndex, exerciseIndex, totalIndex);
    // State update delegated to outer controller
  }

  void removeSeriesData(TrainingProgram program, Series series) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
    }
    // State update delegated to outer controller
  }

  void updateSeries(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    List<Series> updatedSeries,
  ) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedExercise = exercise.copyWith(series: updatedSeries);
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;
  }

  void _updateSeriesOrders(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int startIndex,
  ) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final recalculated = SeriesBusinessService.recalculateOrders(
      exercise.series,
      startIndex: startIndex,
    );
    final updatedExercise = exercise.copyWith(series: recalculated);
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;
  }

  void reorderSeries(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int oldIndex,
    int newIndex,
  ) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    if (oldIndex < 0 ||
        oldIndex >= exercise.series.length ||
        newIndex < 0 ||
        newIndex > exercise.series.length) {
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final List<Series> reordered = SeriesBusinessService.reorderSeries(
      exercise.series,
      oldIndex,
      newIndex,
    );
    final updatedExercise = exercise.copyWith(series: reordered);
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;
  }

  bool _isValidIndex(TrainingProgram program, int weekIndex, int workoutIndex, int exerciseIndex) {
    return weekIndex >= 0 &&
        weekIndex < program.weeks.length &&
        workoutIndex >= 0 &&
        workoutIndex < program.weeks[weekIndex].workouts.length &&
        exerciseIndex >= 0 &&
        exerciseIndex < program.weeks[weekIndex].workouts[workoutIndex].exercises.length;
  }

  Future<void> updateSeriesWeights(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
  ) async {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    await SeriesUtils.updateSeriesWeights(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      exerciseRecordService,
    );
  }

  Future<void> updateSeriesRange(
    TrainingProgram program,
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int seriesIndex,
    String field,
    dynamic value,
    dynamic maxValue,
  ) async {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    if (seriesIndex < 0 || seriesIndex >= exercise.series.length) {
      return;
    }

    final series = exercise.series[seriesIndex];
    final updatedSeries = SeriesBusinessService.updateRangeField(
      series,
      field: field,
      value: value,
      maxValue: maxValue,
    );

    final updatedExercise = exercise.copyWith(
      series: SeriesBusinessService.replaceAt(exercise.series, seriesIndex, updatedSeries),
    );
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex] = updatedExercise;

    await updateSeriesWeights(program, weekIndex, workoutIndex, exerciseIndex);
  }
}
