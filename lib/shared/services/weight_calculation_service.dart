import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/exercise.dart';
import '../../shared/models/series.dart';
import '../../ExerciseRecords/exercise_record_services.dart';

/// Servizio condiviso per il ricalcolo dei pesi degli esercizi
/// Utilizzato sia dal viewer che dal trainingBuilder per evitare duplicazioni
class WeightCalculationService {
  final ExerciseRecordService _exerciseRecordService;

  WeightCalculationService({
    required ExerciseRecordService exerciseRecordService,
  }) : _exerciseRecordService = exerciseRecordService;

  /// Calcola il peso basandosi sull'intensità percentuale
  static double calculateWeightFromIntensity(
    double maxWeight,
    double intensity,
  ) {
    if (maxWeight <= 0 || intensity <= 0) return 0;
    return maxWeight * (intensity / 100);
  }

  /// Calcola l'intensità percentuale basandosi sul peso
  static double calculateIntensityFromWeight(double weight, double maxWeight) {
    if (maxWeight <= 0 || weight <= 0) return 0;
    return (weight / maxWeight) * 100;
  }

  /// Arrotonda il peso basandosi sul tipo di esercizio
  static double roundWeight(double weight, String? exerciseType) {
    // Imposta un valore predefinito per exerciseType se è null o una stringa vuota
    final type = exerciseType?.toLowerCase() ?? '';

    if (weight <= 0) return 0;

    // Per esercizi a corpo libero o con elastici, arrotonda a 0.5
    if (type.contains('corpo libero') ||
        type.contains('elastico') ||
        type.contains('calisthenics')) {
      return (weight * 2).round() / 2;
    }

    // Per pesi leggeri (< 10kg), arrotonda a 0.5
    if (weight < 10) {
      return (weight * 2).round() / 2;
    }

    // Per pesi medi (10-50kg), arrotonda a 1.25
    if (weight < 50) {
      return (weight * 0.8).round() / 0.8;
    }

    // Per pesi pesanti (>= 50kg), arrotonda a 2.5
    return (weight / 2.5).round() * 2.5;
  }

  /// Ricalcola i pesi di un esercizio basandosi sui record più recenti
  Future<double> getLatestMaxWeight(String userId, String exerciseId) async {
    if (exerciseId.isEmpty || userId.isEmpty) {
      return 0.0;
    }

    try {
      final recordsStream = _exerciseRecordService.getExerciseRecords(
        userId: userId,
        exerciseId: exerciseId,
      );

      final records = await recordsStream.first;
      if (records.isEmpty) return 0.0;

      final latestRecord = records.firstWhere(
        (record) => record.exerciseId == exerciseId,
        orElse: () => records.first,
      );

      return latestRecord.maxWeight.toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  /// Ricalcola i pesi delle serie basandosi sul nuovo massimale
  void recalculateSeriesWeights(
    List<Series> series,
    double latestMaxWeight,
    String exerciseType,
  ) {
    for (int i = 0; i < series.length; i++) {
      final currentSeries = series[i];

      // Aggiorna weight basandosi sull'intensità
      if (currentSeries.intensity != null &&
          currentSeries.intensity!.isNotEmpty) {
        final intensity = double.tryParse(currentSeries.intensity!);
        if (intensity != null) {
          final calculatedWeight = calculateWeightFromIntensity(
            latestMaxWeight,
            intensity,
          );
          final newWeight = roundWeight(calculatedWeight, exerciseType);
          series[i] = currentSeries.copyWith(weight: newWeight);
        }
      }

      // Aggiorna maxWeight basandosi sulla maxIntensity
      if (currentSeries.maxIntensity != null &&
          currentSeries.maxIntensity!.isNotEmpty) {
        final maxIntensity = double.tryParse(currentSeries.maxIntensity!);
        if (maxIntensity != null) {
          final calculatedMaxWeight = calculateWeightFromIntensity(
            latestMaxWeight,
            maxIntensity,
          );
          final newMaxWeight = roundWeight(calculatedMaxWeight, exerciseType);
          series[i] = series[i].copyWith(maxWeight: newMaxWeight);
        }
      }
    }
  }

  /// Aggiorna i pesi delle progressioni settimanali
  void recalculateWeekProgressionWeights(
    List<Map<String, dynamic>> weekProgressions,
    double latestMaxWeight,
    String exerciseType,
  ) {
    for (int i = 0; i < weekProgressions.length; i++) {
      final progression = weekProgressions[i];
      final series = progression['series'] as List<dynamic>?;

      if (series != null) {
        final seriesList = series
            .map((s) => Series.fromMap(s as Map<String, dynamic>))
            .toList();
        recalculateSeriesWeights(seriesList, latestMaxWeight, exerciseType);
        weekProgressions[i] = {
          ...progression,
          'series': seriesList.map((s) => s.toMap()).toList(),
        };
      }
    }
  }

  /// Aggiorna completamente un esercizio con i nuovi pesi
  Future<Exercise> updateExerciseWeights(
    Exercise exercise,
    String userId,
    String newExerciseId,
    String exerciseType,
  ) async {
    final newLatestMaxWeight = await getLatestMaxWeight(userId, newExerciseId);

    // Crea una copia delle serie per il ricalcolo
    final updatedSeries = List<Series>.from(exercise.series);
    recalculateSeriesWeights(updatedSeries, newLatestMaxWeight, exerciseType);

    // Ricalcola i pesi delle progressioni settimanali se presenti
    if (exercise.weekProgressions != null &&
        exercise.weekProgressions!.isNotEmpty) {
      for (final weekList in exercise.weekProgressions!) {
        for (final progression in weekList) {
          recalculateSeriesWeights(
            progression.series,
            newLatestMaxWeight,
            exerciseType,
          );
        }
      }
    }

    // Restituisce una nuova istanza dell'esercizio con i valori aggiornati
    return exercise.copyWith(
      latestMaxWeight: newLatestMaxWeight,
      series: updatedSeries,
    );
  }

  /// Versione per Map con String e dynamic (compatibilità con viewer)
  Future<void> updateExerciseWeightsFromMap(
    Map<String, dynamic> exercise,
    String userId,
    String newExerciseId,
    String exerciseType,
  ) async {
    final latestMaxWeight = await getLatestMaxWeight(userId, newExerciseId);
    final series = exercise['series'] as List<dynamic>;

    final batch = FirebaseFirestore.instance.batch();

    for (var serie in series) {
      final Map<String, dynamic> seriesMap = serie as Map<String, dynamic>;

      seriesMap['originalExerciseId'] = newExerciseId;

      if (seriesMap['intensity'] != null) {
        final double intensity = double.parse(
          seriesMap['intensity'].toString(),
        );
        final double calculatedWeight = calculateWeightFromIntensity(
          latestMaxWeight,
          intensity,
        );
        final double newWeight = roundWeight(calculatedWeight, exerciseType);
        seriesMap['weight'] = newWeight;
      }

      if (seriesMap['maxIntensity'] != null) {
        final double maxIntensity = double.parse(
          seriesMap['maxIntensity'].toString(),
        );
        final double calculatedMaxWeight = calculateWeightFromIntensity(
          latestMaxWeight,
          maxIntensity,
        );
        final double newMaxWeight = roundWeight(
          calculatedMaxWeight,
          exerciseType,
        );
        seriesMap['maxWeight'] = newMaxWeight;
      }

      // Aggiorna su Firestore
      final seriesId = seriesMap['id'];
      if (seriesId != null) {
        final seriesRef = FirebaseFirestore.instance
            .collection('series')
            .doc(seriesId);
        final updateData = {
          'weight': seriesMap['weight'],
          'maxWeight': seriesMap['maxWeight'],
          'intensity': seriesMap['intensity']?.toString(),
          'maxIntensity': seriesMap['maxIntensity']?.toString(),
          'originalExerciseId': newExerciseId,
        };
        batch.update(seriesRef, updateData);
      }
    }

    await batch.commit();
  }
}
