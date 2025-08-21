import 'package:alphanessone/shared/models/series.dart';

class SeriesCompletionUtils {
  static bool isDoneValues({
    required int reps,
    int? maxReps,
    required double weight,
    double? maxWeight,
    required int repsDone,
    required double weightDone,
  }) {
    final repsCompleted = maxReps != null
        ? repsDone >= reps && repsDone <= maxReps
        : repsDone >= reps;

    final weightCompleted = maxWeight != null
        ? weightDone >= weight && weightDone <= maxWeight
        : weightDone >= weight;

    return repsCompleted && weightCompleted;
  }

  static bool isDoneMap(Map<String, dynamic> s) {
    final reps = (s['reps'] ?? 0) as int;
    final maxReps = s['maxReps'] as int?;
    final weight = (s['weight'] ?? 0.0).toDouble();
    final maxWeightRaw = s['maxWeight'];
    final double? maxWeight = maxWeightRaw is num ? maxWeightRaw.toDouble() : null;
    final repsDone = (s['reps_done'] ?? s['repsDone'] ?? 0) as int;
    final weightDone = (s['weight_done'] ?? s['weightDone'] ?? 0.0).toDouble();
    return isDoneValues(
      reps: reps,
      maxReps: maxReps,
      weight: weight,
      maxWeight: maxWeight,
      repsDone: repsDone,
      weightDone: weightDone,
    );
  }

  static bool isDoneModel(Series s) {
    return isDoneValues(
      reps: s.reps,
      maxReps: s.maxReps,
      weight: s.weight,
      maxWeight: s.maxWeight,
      repsDone: s.repsDone,
      weightDone: s.weightDone,
    );
  }
}
