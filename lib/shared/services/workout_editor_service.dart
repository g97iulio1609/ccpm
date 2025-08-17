import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/shared/services/weight_calculation_service.dart';

/// Servizio unificato per le modifiche agli esercizi e alle serie
/// Usabile sia dal Viewer che dal TrainingBuilder per rispettare KISS/SOLID/DRY
class WorkoutEditorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ExerciseService _exerciseService = ExerciseService();
  // Manteniamo solo ExerciseService; le operazioni serie sono gestite via batch locale
  final WeightCalculationService _weightCalculationService;

  WorkoutEditorService({required ExerciseRecordService exerciseRecordService})
    : _weightCalculationService = WeightCalculationService(
        exerciseRecordService: exerciseRecordService,
      );

  /// Cambia l'esercizio mantenendo serie/originalExerciseId e ricalcolando i pesi
  Future<void> changeExercise({
    required Map<String, dynamic> currentExercise,
    required Exercise newExercise,
    required String targetUserId,
  }) async {
    final Map<String, dynamic> updatedExerciseMap = {
      ...currentExercise,
      'name': newExercise.name,
      'exerciseId': newExercise.exerciseId ?? '',
      'type': newExercise.type,
      'variant': newExercise.variant,
    };

    final Map<String, dynamic> tbExerciseData = {
      'name': newExercise.name,
      'exerciseId': newExercise.exerciseId ?? '',
      'type': newExercise.type,
      'variant': newExercise.variant,
      if (updatedExerciseMap['series'] != null)
        'series': updatedExerciseMap['series'],
    };

    // Aggiorna il documento esercizio (e le serie se passate) con la logica TrainingBuilder
    await _exerciseService.updateExercise(
      currentExercise['id'],
      tbExerciseData,
    );

    // Ricalcola pesi serie in base al nuovo esercizio originale
    if ((newExercise.exerciseId ?? '').isNotEmpty) {
      await _weightCalculationService.updateExerciseWeightsFromMap(
        updatedExerciseMap,
        targetUserId,
        newExercise.exerciseId ?? '',
        newExercise.type,
      );
    }
  }

  /// Applica le modifiche alle serie per un esercizio specifico
  /// Restituisce la lista di serie finale (con eventuali nuovi ID)
  Future<List<Series>> applySeriesChanges({
    required Map<String, dynamic> exercise,
    required List<Series> newSeriesList,
  }) async {
    final String exerciseDocId = exercise['id'];
    final String originalExerciseIdForNewSeries =
        (exercise['exerciseId'] as String?) ??
        (exercise['originalExerciseId'] as String?) ??
        '';

    // Serie correnti (vecchie)
    final List<Series> oldSeries = List<Series>.from(
      (exercise['series'] as List).map(
        (s) => Series.fromMap(s as Map<String, dynamic>),
      ),
    );

    final batch = _db.batch();

    // Elimina eventuali serie in eccesso
    if (newSeriesList.length < oldSeries.length) {
      for (var i = newSeriesList.length; i < oldSeries.length; i++) {
        final seriesRef = _db.collection('series').doc(oldSeries[i].id);
        batch.delete(seriesRef);
      }
    }

    // Aggiorna o crea serie necessarie
    final updatedResult = <Series>[];
    for (final series in newSeriesList) {
      if (series.id != null) {
        final seriesRef = _db.collection('series').doc(series.id);
        final data = series.copyWith(exerciseId: exerciseDocId).toMap();
        data['exerciseId'] = exerciseDocId;
        batch.update(seriesRef, data);
        updatedResult.add(series.copyWith(exerciseId: exerciseDocId));
      } else {
        final seriesRef = _db.collection('series').doc();
        final newSeries = series.copyWith(
          id: seriesRef.id,
          serieId: seriesRef.id,
          exerciseId: exerciseDocId,
          originalExerciseId:
              series.originalExerciseId ?? originalExerciseIdForNewSeries,
        );
        final data = newSeries.toMap();
        data['exerciseId'] = exerciseDocId;
        batch.set(seriesRef, data);
        updatedResult.add(newSeries);
      }
    }

    await batch.commit();
    return updatedResult;
  }
}
