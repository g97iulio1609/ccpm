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

    final updatedSeries = await _showSeriesDialog(
      context,
      exercise,
      weekIndex,
      currentSeriesGroup,
      exercise.type,
      latestMaxWeight,
    );

    if (updatedSeries != null) {
      final startIndex = exercise.series.indexOf(currentSeriesGroup.first);
      if (startIndex != -1) {
        // Remove old series from database
        for (var series in currentSeriesGroup) {
          program.trackToDeleteSeries.add(series.serieId!);
                }

        // Replace old series with updated ones
        exercise.series.replaceRange(startIndex, startIndex + currentSeriesGroup.length, updatedSeries);

        // Update series order
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
    program.trackToDeleteSeries.add(series.serieId!);
    notifyListeners();
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

  Future<void> updateSeriesWeights(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex) async {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    await SeriesUtils.updateSeriesWeights(
        program, weekIndex, workoutIndex, exerciseIndex, exerciseRecordService);
    notifyListeners();
  }

  List<Series> _groupSeries(List<Series> series) {
    final groupedSeries = <Series>[];
    Series? currentGroup;

    for (final series in series) {
      if (currentGroup == null ||
          series.reps != currentGroup.reps ||
          series.maxReps != currentGroup.maxReps ||
          series.weight != currentGroup.weight ||
          series.maxWeight != currentGroup.maxWeight) {
        currentGroup = series.copyWith(sets: 1);
        groupedSeries.add(currentGroup);
      } else {
        currentGroup.sets += 1;
        if (series.maxSets != null) {
          currentGroup.maxSets = (currentGroup.maxSets ?? 0) + 1;
        }
      }
    }

    return groupedSeries;
  }

  List<Series> _ungroupSeries(List<Series> groupedSeries) {
    final ungroupedSeries = <Series>[];

    for (final group in groupedSeries) {
      for (int i = 0; i < group.sets; i++) {
        ungroupedSeries.add(group.copyWith(
          sets: 1,
          maxSets: null,
          order: ungroupedSeries.length + 1,
        ));
      }
    }

    return ungroupedSeries;
  }

  Future<void> updateSeriesRange(TrainingProgram program, int weekIndex, int workoutIndex,
      int exerciseIndex, int seriesIndex, String field, dynamic value, dynamic maxValue) async {
    if (!_isValidIndex(program, weekIndex, workoutIndex, exerciseIndex)) {
      debugPrint('Invalid indices provided');
      return;
    }

    final exercise = program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    if (seriesIndex < 0 || seriesIndex >= exercise.series.length) {
      debugPrint('Invalid series index');
      return;
    }

    final series = exercise.series[seriesIndex];
    switch (field) {
      case 'reps':
        series.reps = value;
        series.maxReps = maxValue;
        break;
      case 'sets':
        series.sets = value;
        series.maxSets = maxValue;
        break;
      case 'intensity':
        series.intensity = value;
        series.maxIntensity = maxValue;
        break;
      case 'rpe':
        series.rpe = value;
        series.maxRpe = maxValue;
        break;
      case 'weight':
        series.weight = value;
        series.maxWeight = maxValue;
        break;
      default:
        debugPrint('Invalid field: $field');
        return;
    }

    await updateSeriesWeights(program, weekIndex, workoutIndex, exerciseIndex);
  }
}