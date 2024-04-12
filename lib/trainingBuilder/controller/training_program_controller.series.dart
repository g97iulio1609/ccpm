part of 'training_program_controller.dart';

extension SeriesExtension on TrainingProgramController {
  Future<void> addSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      BuildContext context) async {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final seriesList = await _showSeriesDialog(context, exercise, weekIndex);
    if (seriesList != null) {
      for (final series in seriesList) {
        series.serieId = null;
      }
      exercise.series.addAll(seriesList);
      notifyListeners();
    }
  }

  Future<List<Series>?> _showSeriesDialog(
      BuildContext context, Exercise exercise, int weekIndex,
      [Series? currentSeries]) async {
    return await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        usersService: _usersService,
        athleteId: _athleteIdController.text,
        exerciseId: exercise.exerciseId ?? '',
        weekIndex: weekIndex,
        exercise: exercise,
        currentSeries: currentSeries,
      ),
    );
  }

  Future<void> editSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    Series currentSeries,
    BuildContext context,
  ) async {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedSeriesList =
        await _showSeriesDialog(context, exercise, weekIndex, currentSeries);
    if (updatedSeriesList != null) {
      final groupIndex = exercise.series.indexWhere(
        (series) => series.serieId == currentSeries.serieId,
      );
      final seriesIndex = exercise.series.indexOf(currentSeries);
      _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
          .series
          .replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);
      notifyListeners();
    }
  }

  void removeSeries(
    int weekIndex,
    int workoutIndex,
    int exerciseIndex,
    int groupIndex,
    int seriesIndex,
  ) {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final series = exercise.series[groupIndex * 1 + seriesIndex];
    _removeSeriesData(series);
    exercise.series.removeAt(groupIndex * 1 + seriesIndex);
    _updateSeriesOrders(
        weekIndex, workoutIndex, exerciseIndex, groupIndex * 1 + seriesIndex);
    notifyListeners();
  }

  void _removeSeriesData(Series series) {
    if (series.serieId != null) {
      _program.trackToDeleteSeries.add(series.serieId!);
    }
  }

  void updateSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      List<Series> updatedSeries) {
    _program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
        .series = updatedSeries;
    notifyListeners();
  }

  void reorderSeries(int weekIndex, int workoutIndex, int exerciseIndex,
      int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final series = exercise.series.removeAt(oldIndex);
    exercise.series.insert(newIndex, series);
    _updateSeriesOrders(weekIndex, workoutIndex, exerciseIndex, newIndex);
    notifyListeners();
  }

  void _updateSeriesOrders(
      int weekIndex, int workoutIndex, int exerciseIndex, int startIndex) {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    for (int i = startIndex; i < exercise.series.length; i++) {
      exercise.series[i].order = i + 1;
    }
  }

  Future<void> addSeriesToProgression(int weekIndex, int workoutIndex,
      int exerciseIndex, BuildContext context) async {
    final exercise = _program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final newSeriesOrder = exercise.series.length + 1;
    final newSeries = Series(
      serieId: UniqueKey().toString(),
      reps: 0,
      sets: 1,
      intensity: '',
      rpe: '',
      weight: 0.0,
      order: newSeriesOrder,
      done: false,
      reps_done: 0,
      weight_done: 0.0,
    );
    exercise.series.add(newSeries);
    notifyListeners();
  }
}