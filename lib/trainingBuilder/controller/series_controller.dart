import 'package:alphanessone/trainingBuilder/dialog/series_dialog.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:flutter/material.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';

class SeriesController extends ChangeNotifier {
  final ExerciseRecordService exerciseRecordService;
  final ValueNotifier<double> weightNotifier;

  SeriesController(this.exerciseRecordService, this.weightNotifier);

  Future<void> addSeries(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, BuildContext context) async {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final latestMaxWeight = await SeriesUtils.getLatestMaxWeight(
        exerciseRecordService, program.athleteId, exercise.exerciseId ?? '');

    if (!context.mounted) return;

    final seriesList = await _showSeriesDialog(
        context, exercise, weekIndex, null, exercise.type, latestMaxWeight);

    if (seriesList != null && seriesList.isNotEmpty) {
      exercise.series.addAll(seriesList);
      await SeriesUtils.updateSeriesWeights(
          program, weekIndex, workoutIndex, exerciseIndex, exerciseRecordService);
      notifyListeners();
    }
  }

 Future<List<Series>?> _showSeriesDialog(BuildContext context, Exercise exercise,
      int weekIndex, List<Series>? currentSeriesGroup, String? exerciseType, num? latestMaxWeight) async {
    if (!context.mounted) return null;

    return await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        exerciseRecordService: exerciseRecordService,
        athleteId: exercise.exerciseId ?? '',
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


Future<void> editSeries(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex, List<Series> currentSeriesGroup, BuildContext context, num latestMaxWeight) async {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    if (!context.mounted) return;

    final updatedSeriesList = await _showSeriesDialog(
      context,
      exercise,
      weekIndex,
      currentSeriesGroup,
      exercise.type,
      latestMaxWeight,
    );

    if (updatedSeriesList != null && updatedSeriesList.isNotEmpty) {
      final startIndex = exercise.series.indexOf(currentSeriesGroup.first);
      if (startIndex != -1) {
        // Rimuovi le serie vecchie
        exercise.series.removeRange(startIndex, startIndex + currentSeriesGroup.length);

        // Inserisci le nuove serie
        exercise.series.insertAll(startIndex, updatedSeriesList);

        // Aggiorna l'ordine delle serie
        for (int i = 0; i < exercise.series.length; i++) {
          exercise.series[i].order = i + 1;
        }

        await SeriesUtils.updateSeriesWeights(
            program, weekIndex, workoutIndex, exerciseIndex, exerciseRecordService);
        notifyListeners();
      }
    }
  }
  void removeAllSeriesForExercise(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    for (final series in exercise.series) {
      removeSeriesData(program, series);
    }
    exercise.series.clear();
    notifyListeners();
  }

  void removeSeries(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex, int groupIndex, int seriesIndex) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final totalIndex = groupIndex * 1 + seriesIndex;

    if (totalIndex < 0 || totalIndex >= exercise.series.length) {
      debugPrint('Invalid series index');
      return;
    }

    final series = exercise.series[totalIndex];
    removeSeriesData(program, series);
    exercise.series.removeAt(totalIndex);
    _updateSeriesOrders(program, weekIndex, workoutIndex, exerciseIndex, totalIndex);
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
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
        .series = updatedSeries;
    notifyListeners();
  }

  void _updateSeriesOrders(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex, int startIndex) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    for (int i = startIndex; i < exercise.series.length; i++) {
      exercise.series[i].order = i + 1;
    }
  }

  void reorderSeries(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex, int oldIndex, int newIndex) {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    if (oldIndex < 0 || oldIndex >= exercise.series.length ||
        newIndex < 0 || newIndex > exercise.series.length) {
      debugPrint('Invalid oldIndex or newIndex');
      return;
    }

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final series = exercise.series.removeAt(oldIndex);
    exercise.series.insert(newIndex, series);
    _updateSeriesOrders(program, weekIndex, workoutIndex, exerciseIndex, newIndex);
    notifyListeners();
  }

  bool _isValidIndex(TrainingProgram program, int weekIndex, int workoutIndex, int exerciseIndex) {
    return weekIndex >= 0 && weekIndex < program.weeks.length &&
           workoutIndex >= 0 && workoutIndex < program.weeks[weekIndex].workouts.length &&
           exerciseIndex >= 0 && exerciseIndex < program.weeks[weekIndex].workouts[workoutIndex].exercises.length;
  }
}