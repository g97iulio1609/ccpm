import 'package:alphanessone/viewer/domain/entities/series.dart';

// Potremmo definire un'entità o un semplice tipo per i parametri se diventano complessi
class CompleteSeriesParams {
  final String seriesId;
  final bool isDone;
  final int repsDone;
  final double weightDone;
  // Eventuali altri parametri, es. workoutId, exerciseId se servono per logiche aggiuntive

  CompleteSeriesParams({
    required this.seriesId,
    required this.isDone,
    required this.repsDone,
    required this.weightDone,
  });
}

abstract class CompleteSeriesUseCase {
  Future<void> call(CompleteSeriesParams params);
}
