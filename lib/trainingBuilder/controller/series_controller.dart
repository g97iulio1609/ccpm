import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:flutter/material.dart';
import '../training_model.dart';
import 'package:alphanessone/users_services.dart';

class SeriesController extends ChangeNotifier {
  final UsersService usersService;
  final ValueNotifier<double> weightNotifier;

  SeriesController(this.usersService, this.weightNotifier);

  Future<void> addSeries(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, BuildContext context) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final latestMaxWeight = await SeriesUtils.getLatestMaxWeight(
        usersService, program.athleteId, exercise.exerciseId ?? '');

    final num maxWeight = latestMaxWeight ?? 100.0;

    final seriesList = await _showSeriesDialog(
        context, exercise, weekIndex, null, exercise.type, maxWeight);

    if (seriesList != null) {
      exercise.series.addAll(seriesList);
      await SeriesUtils.updateSeriesWeights(
          program, weekIndex, workoutIndex, exerciseIndex, usersService);
      notifyListeners();
    }
  }

Future<List<Series>?> _showSeriesDialog(
  BuildContext context,
  Exercise exercise,
  int weekIndex,
  Series? currentSeries,
  String? exerciseType,
  num? latestMaxWeight,
) async {
  return await showDialog<List<Series>>(
    context: context,
    builder: (context) => SeriesDialog(
      usersService: usersService,
      athleteId: exercise.exerciseId ?? '',
      exerciseId: exercise.exerciseId ?? '',
      weekIndex: weekIndex,
      exercise: exercise,
      currentSeries: currentSeries,
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
  Series currentSeries,
  BuildContext context,
  latestMaxWeight
) async {
  final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  final exerciseId = exercise.exerciseId;
  final athleteId = program.athleteId;

  // Ottieni il latestMaxWeight corretto per l'esercizio
  final latestMaxWeight = await SeriesUtils.getLatestMaxWeight(
    usersService,
    athleteId,
    exerciseId ?? '',
  );
  debugPrint('editSeries - latestMaxWeight: $latestMaxWeight');

  final updatedSeriesList = await _showSeriesDialog(
    context,
    exercise,
    weekIndex,
    currentSeries,
    exercise.type,
    latestMaxWeight,
  );

  if (updatedSeriesList != null) {
    final seriesIndex = exercise.series.indexOf(currentSeries);
    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
        .series
        .replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);

    await SeriesUtils.updateSeriesWeights(
      program,
      weekIndex,
      workoutIndex,
      exerciseIndex,
      usersService,
    );
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
  }
}
