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

    for (int i = 0; i < reps.length; i++) {
      for (int j = 0; j < (sets[i] > 0 ? sets[i] : 1); j++) {
        translatedSeries.add(Series(
          serieId: generateRandomId(16),
          reps: reps[i],
          sets: 1,
          intensity: intensity[i],
          rpe: rpe[i],
          weight: weight[i],
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