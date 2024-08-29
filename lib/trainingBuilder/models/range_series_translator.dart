import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';

class RangeSeriesTranslator {
  static List<Series> translateRangeToSeries(
    List<int> reps,
    List<int> sets,
    List<String> intensity,
    List<String> rpe,
    List<double> weight,
    int startOrder
  ) {
    List<Series> translatedSeries = [];
    int currentOrder = startOrder;

    bool isSetRange = sets.length > 1;
    int totalSets = isSetRange ? sets.reduce((a, b) => a + b) : sets[0];

    int maxLength = [reps.length, intensity.length, rpe.length, weight.length]
        .reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < maxLength; i++) {
      int currentReps = i < reps.length ? reps[i] : reps.last;
      int currentSets = isSetRange ? (i < sets.length ? sets[i] : sets.last) : 1;
      String currentIntensity = i < intensity.length ? intensity[i] : intensity.last;
      String currentRpe = i < rpe.length ? rpe[i] : rpe.last;
      double currentWeight = i < weight.length ? weight[i] : weight.last;

      for (int j = 0; j < (isSetRange ? currentSets : totalSets); j++) {
        translatedSeries.add(Series(
          serieId: generateRandomId(16),
          reps: currentReps,
          sets: 1,
          intensity: currentIntensity,
          rpe: currentRpe,
          weight: currentWeight,
          order: currentOrder++,
          done: false,
          reps_done: 0,
          weight_done: 0.0,
        ));
      }
    }

    return translatedSeries;
  }
}