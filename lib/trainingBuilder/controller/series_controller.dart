import 'package:alphanessone/trainingBuilder/series_dialog.dart';
import 'package:flutter/material.dart';
import '../training_model.dart';
import 'package:alphanessone/users_services.dart';
import '../utility_functions.dart';

class SeriesController extends ChangeNotifier {
  final UsersService usersService;
  final ValueNotifier<double> weightNotifier;

  SeriesController(this.usersService, this.weightNotifier);

   void notifyListeners() {
    super.notifyListeners();
  }

  Future<void> addSeries(TrainingProgram program, int weekIndex,
    int workoutIndex, int exerciseIndex, BuildContext context) async {
  final exercise = program
      .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];

    // Ottieni il peso massimo più recente
    final latestMaxWeight = await getLatestMaxWeight(
        usersService, program.athleteId, exercise.exerciseId ?? '');

    // Converti latestMaxWeight in double o utilizza un valore predefinito
    final num maxWeight = latestMaxWeight ?? 100.0;

  final seriesList = await _showSeriesDialog(context, exercise, weekIndex, null, exercise.type, maxWeight);

    if (seriesList != null) {
      exercise.series.addAll(seriesList);
      // Aggiorna i pesi delle serie dopo averle aggiunte
      await updateSeriesWeights(
          program, weekIndex, workoutIndex, exerciseIndex);
    }
  }

Future<List<Series>?> _showSeriesDialog(
  BuildContext context,
  Exercise exercise,
  int weekIndex, [
  Series? currentSeries,
  String? exerciseType,
  num? latestMaxWeight,
]) async {
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
  ) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final updatedSeriesList =
        await _showSeriesDialog(context, exercise, weekIndex, currentSeries, exercise.type);
    if (updatedSeriesList != null) {
      final seriesIndex = exercise.series.indexOf(currentSeries);
      program.weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex]
          .series
          .replaceRange(seriesIndex, seriesIndex + 1, updatedSeriesList);

      // Calcola il peso per la serie modificata
      final latestMaxWeight = await getLatestMaxWeight(usersService, program.athleteId, exercise.exerciseId ?? '');
      if (latestMaxWeight != null) {
        _calculateWeight(updatedSeriesList.first, exercise.type, latestMaxWeight);
      }

      // Aggiorna i pesi delle serie dopo averle modificate
      await updateSeriesWeights(
          program, weekIndex, workoutIndex, exerciseIndex);
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
        _calculateWeight(series, exercise.type, latestMaxWeight);
      }
    }
  }

  // Aggiungi questa riga per notificare i listener delle modifiche
  notifyListeners();
}

  void _calculateWeight(
      Series series, String? exerciseType, num? latestMaxWeight) {
    double calculatedWeight = 0;

    if (latestMaxWeight != null) {
      if (series.intensity.isNotEmpty) {
        final intensity = double.tryParse(series.intensity) ?? 0;
        if (intensity > 0) {
          calculatedWeight = calculateWeightFromIntensity(
              latestMaxWeight.toDouble(), intensity);
          series.weight = roundWeight(calculatedWeight, exerciseType);
          updateWeightNotifier(series.weight);
        }
      } else if (series.rpe.isNotEmpty) {
        final rpe = double.tryParse(series.rpe) ?? 0;
        if (rpe > 0) {
          final rpePercentage = getRPEPercentage(rpe, series.reps);
          calculatedWeight = latestMaxWeight.toDouble() * rpePercentage;
          series.weight = roundWeight(calculatedWeight, exerciseType);
          updateWeightNotifier(series.weight);
        }
      } else {
        series.intensity = calculateIntensityFromWeight(
                series.weight, latestMaxWeight.toDouble())
            .toStringAsFixed(2);
        final rpe = calculateRPE(
            series.weight, latestMaxWeight.toDouble(), series.reps);
        series.rpe = rpe != null ? rpe.toStringAsFixed(1) : '';
      }
    } else {}
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
