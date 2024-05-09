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
    for (final series in seriesList) {

      exercise.series.add(series);
    }
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
  num latestMaxWeight,
) async {
  final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  final exerciseId = exercise.exerciseId;
  final athleteId = program.athleteId;



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
    for (int i = 0; i < updatedSeriesList.length; i++) {
      final updatedSeries = updatedSeriesList[i];

      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
          .series[seriesIndex + i] = updatedSeries;
    }

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

void removeAllSeriesForExercise(
    TrainingProgram program, int weekIndex, int workoutIndex, int exerciseIndex) {
  final exercise =
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
  for (final series in exercise.series) {
    removeSeriesData(program, series);
  }
  exercise.series.clear();
  notifyListeners();
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
    removeSeriesData(program, series);
    exercise.series.removeAt(groupIndex * 1 + seriesIndex);
    _updateSeriesOrders(program, weekIndex, workoutIndex, exerciseIndex,
        groupIndex * 1 + seriesIndex);
    notifyListeners();
  }

  void removeSeriesData(TrainingProgram program, Series series) {
    if (series.serieId != null) {
      program.trackToDeleteSeries.add(series.serieId!);
          notifyListeners();

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
