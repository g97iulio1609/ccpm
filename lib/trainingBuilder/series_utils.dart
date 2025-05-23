import 'package:flutter/material.dart'; // Per TextEditingController e ValueNotifier

import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/training_model.dart';

// Utility per calcoli relativi alle serie di allenamento.
// Fornisce metodi per calcolare peso, intensità, RPE e per aggiornare
// i controller di testo in base a questi valori.
class SeriesUtils {
  // Evita di istanziare la classe, tutti i metodi sono statici.
  SeriesUtils._();

  // Tabella RPE (Rate of Perceived Exertion) per calcolare la percentuale del massimale.
  // La chiave esterna è l'RPE (da 2 a 10, arrotondato all'intero più vicino).
  // La chiave interna è il numero di ripetizioni (da 1 a 10).
  // Il valore è la percentuale del massimale (1RM) come double (es. 0.955 per 95.5%).
  static const Map<int, Map<int, double>> _rpeTable = {
    10: {
      1: 1.0,
      2: 0.955,
      3: 0.922,
      4: 0.892,
      5: 0.863,
      6: 0.837,
      7: 0.811,
      8: 0.786,
      9: 0.762,
      10: 0.739
    },
    9: {
      1: 0.978,
      2: 0.939,
      3: 0.907,
      4: 0.878,
      5: 0.850,
      6: 0.824,
      7: 0.799,
      8: 0.774,
      9: 0.751,
      10: 0.728
    },
    8: {
      1: 0.955,
      2: 0.922,
      3: 0.892,
      4: 0.863,
      5: 0.837,
      6: 0.811,
      7: 0.786,
      8: 0.762,
      9: 0.739,
      10: 0.717
    },
    7: {
      1: 0.939,
      2: 0.907,
      3: 0.878,
      4: 0.850,
      5: 0.824,
      6: 0.799,
      7: 0.774,
      8: 0.751,
      9: 0.728,
      10: 0.706
    },
    6: {
      1: 0.922,
      2: 0.892,
      3: 0.863,
      4: 0.837,
      5: 0.811,
      6: 0.786,
      7: 0.762,
      8: 0.739,
      9: 0.717,
      10: 0.696
    },
    5: {
      1: 0.907,
      2: 0.878,
      3: 0.850,
      4: 0.824,
      5: 0.799,
      6: 0.774,
      7: 0.751,
      8: 0.728,
      9: 0.706,
      10: 0.685
    },
    4: {
      1: 0.892,
      2: 0.863,
      3: 0.837,
      4: 0.811,
      5: 0.786,
      6: 0.762,
      7: 0.739,
      8: 0.717,
      9: 0.696,
      10: 0.675
    },
    3: {
      1: 0.878,
      2: 0.850,
      3: 0.824,
      4: 0.799,
      5: 0.774,
      6: 0.751,
      7: 0.728,
      8: 0.706,
      9: 0.685,
      10: 0.665
    },
    2: {
      1: 0.863,
      2: 0.837,
      3: 0.811,
      4: 0.786,
      5: 0.762,
      6: 0.739,
      7: 0.717,
      8: 0.696,
      9: 0.675,
      10: 0.655
    },
  };

  // Costanti per i tipi di esercizio.
  static const String _exerciseTypeDumbbells = 'Manubri';
  static const String _exerciseTypeBarbell = 'Bilanciere';
  static const String _exerciseTypeDefault = 'Default';

  // Formatta un double in stringa, omettendo i decimali se sono zero.
  // Es: 10.0 -> "10", 10.5 -> "10.5", 10.53 -> "10.53" (con precisione 2)
  static String _formatDouble(double value, {int precision = 2}) {
    if (value.isNaN || value.isInfinite) return "0"; // Gestisce NaN e Infinito
    // Se il valore è intero (es. 10.0), lo formatta senza decimali.
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    // Altrimenti, lo formatta con il numero specificato di cifre decimali.
    return value.toStringAsFixed(precision);
  }

  /// Calcola il peso target basato sul massimale e l'intensità percentuale.
  static double calculateWeightFromIntensity(
      double maxWeight, double intensity) {
    if (maxWeight <= 0) return 0.0;
    // Assicura che l'intensità sia tra 0 e un massimo ragionevole (es. 200%).
    final clampedIntensity = intensity.clamp(0.0, 200.0);
    return maxWeight * (clampedIntensity / 100);
  }

  /// Ottiene la percentuale del massimale (1RM) basata su RPE e numero di ripetizioni.
  static double getRPEPercentage(double rpe, int reps) {
    // Assicura che RPE e reps siano nei limiti della tabella.
    final rpeInt = rpe.round().clamp(2, 10); // RPE da 2 a 10
    final repsClamped = reps.clamp(1, 10); // Reps da 1 a 10
    // Restituisce la percentuale o 1.0 (100%) come fallback se non trovato.
    return _rpeTable[rpeInt]?[repsClamped] ?? 1.0;
  }

  /// Arrotonda il peso in base al tipo di esercizio.
  static double roundWeight(double weight, String? exerciseType) {
    if (weight.isNaN || weight.isInfinite || weight < 0) return 0.0;

    final String effectiveExerciseType =
        (exerciseType != null && exerciseType.isNotEmpty)
            ? exerciseType
            : _exerciseTypeDefault;

    switch (effectiveExerciseType) {
      case _exerciseTypeDumbbells: // Es. manubri che aumentano di 2kg
        return (weight / 2).roundToDouble() * 2.0;
      case _exerciseTypeBarbell: // Es. bilancieri con dischi da 1.25kg (quindi step di 2.5kg)
        if (weight == 0) return 0.0;
        return (weight / 2.5).roundToDouble() * 2.5;
      case _exerciseTypeDefault:
      default: // Arrotondamento di default (es. macchine con step di 2kg o preferenza)
        // Arrotonda prima a una cifra decimale, poi al multiplo di 2 più vicino.
        final roundedToOneDecimal = double.parse(weight.toStringAsFixed(1));
        return (roundedToOneDecimal / 2).roundToDouble() * 2.0;
    }
  }

  /// Calcola l'intensità percentuale basata sul peso sollevato e il massimale.
  static double calculateIntensityFromWeight(double weight, double maxWeight) {
    if (maxWeight <= 0 || weight < 0) return 0.0;
    final intensity = (weight / maxWeight) * 100;
    // Limita l'intensità a un range ragionevole (es. 0-200%).
    return intensity.clamp(0.0, 200.0);
  }

  /// Calcola l'RPE stimato basato su peso, massimale e numero di ripetizioni.
  static double? calculateRPE(double weight, double latestMaxWeight, int reps) {
    if (latestMaxWeight <= 0 || weight < 0 || reps <= 0 || reps > 10) {
      return null;
    }

    final intensity = weight / latestMaxWeight;
    // Non è necessario clampare reps qui perché getRPEPercentage lo farà,
    // ma è buona norma validare gli input il prima possibile.

    double? calculatedRPE;
    double minDifference = double.infinity;

    // Itera sulla tabella RPE per trovare l'RPE più vicino alla percentuale calcolata.
    _rpeTable.forEach((rpeKey, repPercentages) {
      final percentageFromTable = getRPEPercentage(rpeKey.toDouble(), reps);

      final difference = (intensity - percentageFromTable).abs();
      // Se la differenza è minore della minima trovata finora (con una piccola tolleranza per i double),
      // aggiorna l'RPE calcolato.
      if (difference < minDifference && difference < 0.015) {
        // Tolleranza leggermente aumentata
        minDifference = difference;
        calculatedRPE = rpeKey.toDouble();
      }
    });
    return calculatedRPE;
  }

  /// Recupera l'ultimo massimale registrato per un dato esercizio e utente.
  static Future<double> getLatestMaxWeight(
      ExerciseRecordService exerciseRecordService,
      String userId,
      String exerciseId) async {
    if (userId.isEmpty || exerciseId.isEmpty) {
      debugPrint('UserID o ExerciseID mancanti per getLatestMaxWeight.');
      return 0.0;
    }
    double latestMaxWeight = 0.0;
    try {
      final records = await exerciseRecordService
          .getExerciseRecords(userId: userId, exerciseId: exerciseId)
          .first;
      if (records.isNotEmpty) {
        // Ordina i record per data decrescente per assicurarsi di ottenere il più recente
        records.sort((a, b) => b.date.compareTo(a.date));
        latestMaxWeight = records.first.maxWeight.toDouble();
      }
    } catch (error, stackTrace) {
      debugPrint(
          'Errore durante il recupero del massimale per exerciseId $exerciseId, userId $userId: $error\n$stackTrace');
    }
    return latestMaxWeight.clamp(
        0.0, double.maxFinite); // Assicura che non sia negativo
  }

  /// Aggiorna il controller del peso e il notifier basandosi sull'intensità inserita.
  static void updateWeightFromIntensity(
    TextEditingController weightController,
    TextEditingController intensityController,
    String? exerciseType,
    double latestMaxWeight,
    ValueNotifier<double> weightNotifier,
  ) {
    final intensity = double.tryParse(intensityController.text.trim()) ?? 0.0;

    if (latestMaxWeight <= 0) {
      weightController.text = _formatDouble(0.0);
      weightNotifier.value = 0.0;
      return;
    }

    final calculatedWeight =
        calculateWeightFromIntensity(latestMaxWeight, intensity);
    final roundedWeight = roundWeight(calculatedWeight, exerciseType);

    weightController.text = _formatDouble(roundedWeight);
    weightNotifier.value = roundedWeight;
  }

  /// Aggiorna il controller dell'intensità basandosi sul peso inserito.
  static void updateIntensityFromWeight(
    TextEditingController weightController,
    TextEditingController intensityController,
    double latestMaxWeight,
  ) {
    final weight = double.tryParse(weightController.text.trim()) ?? 0.0;

    if (weight > 0 && latestMaxWeight > 0) {
      final calculatedIntensity =
          calculateIntensityFromWeight(weight, latestMaxWeight);
      intensityController.text = _formatDouble(calculatedIntensity);
    } else {
      intensityController.clear();
    }
  }

  /// Aggiorna peso e intensità basandosi sull'RPE e le ripetizioni inserite.
  static void updateWeightFromRPE(
      TextEditingController repsController,
      TextEditingController weightController,
      TextEditingController rpeController,
      TextEditingController intensityController,
      String? exerciseType,
      double latestMaxWeight,
      ValueNotifier<double> weightNotifier) {
    final rpe = double.tryParse(rpeController.text.trim());
    final reps = int.tryParse(repsController.text.trim());

    if (rpe != null &&
        rpe >= 2 &&
        rpe <= 10 &&
        reps != null &&
        reps > 0 &&
        reps <= 10 &&
        latestMaxWeight > 0) {
      final percentage = getRPEPercentage(rpe, reps);
      final calculatedWeight = latestMaxWeight * percentage;
      final roundedWeight = roundWeight(calculatedWeight, exerciseType);

      weightController.text = _formatDouble(roundedWeight);
      weightNotifier.value = roundedWeight;

      final calculatedIntensity =
          calculateIntensityFromWeight(roundedWeight, latestMaxWeight);
      intensityController.text = _formatDouble(calculatedIntensity);
    } else {
      weightController.text = _formatDouble(0.0);
      weightNotifier.value = 0.0;
      intensityController.clear();
    }
  }

  /// Aggiorna RPE e intensità basandosi sul peso e le ripetizioni inserite.
  static void updateRPE(
      TextEditingController repsController,
      TextEditingController weightController,
      TextEditingController rpeController,
      TextEditingController intensityController,
      double latestMaxWeight) {
    final weight = double.tryParse(weightController.text.trim());
    final reps = int.tryParse(repsController.text.trim());

    if (weight != null &&
        weight > 0 &&
        reps != null &&
        reps > 0 &&
        reps <= 10 &&
        latestMaxWeight > 0) {
      final calculatedRPE = calculateRPE(weight, latestMaxWeight, reps);
      if (calculatedRPE != null) {
        rpeController.text = _formatDouble(calculatedRPE, precision: 1);
        final intensity = calculateIntensityFromWeight(weight, latestMaxWeight);
        intensityController.text = _formatDouble(intensity);
      } else {
        rpeController.clear();
      }
    } else {
      rpeController.clear();
    }
  }

  /// Aggiorna i pesi, intensità e RPE per tutte le serie di un esercizio in un programma.
  static Future<void> updateSeriesWeights(
      TrainingProgram program,
      int weekIndex,
      int workoutIndex,
      int exerciseIndex,
      ExerciseRecordService exerciseRecordService) async {
    if (weekIndex < 0 ||
        weekIndex >= program.weeks.length ||
        workoutIndex < 0 ||
        workoutIndex >= program.weeks[weekIndex].workouts.length ||
        exerciseIndex < 0 ||
        exerciseIndex >=
            program.weeks[weekIndex].workouts[workoutIndex].exercises.length) {
      debugPrint(
          "Indici non validi per updateSeriesWeights: w:$weekIndex, wo:$workoutIndex, ex:$exerciseIndex");
      return;
    }

    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final exerciseId = exercise.exerciseId;
    final athleteId = program.athleteId;

    if (exerciseId != null && exerciseId.isNotEmpty && athleteId.isNotEmpty) {
      final latestMaxWeight = await getLatestMaxWeight(
          exerciseRecordService, athleteId, exerciseId);
      for (final series in exercise.series) {
        _calculateWeight(series, exercise.type, latestMaxWeight);
      }
    } else {
      debugPrint(
          "ID Esercizio ($exerciseId) o ID Atleta ($athleteId) mancante/non valido. Pesi non aggiornati da DB.");
      for (final series in exercise.series) {
        _calculateWeight(series, exercise.type, 0.0);
      }
    }
  }

  /// Logica interna per calcolare e impostare peso, intensità e RPE di una singola serie.
  static void _calculateWeight(
      Series series, String? exerciseType, double latestMaxWeight) {
    final currentMaxWeight = latestMaxWeight.clamp(0.0, double.maxFinite);

    if (currentMaxWeight <= 0) {
      series.weight = 0.0;
      series.intensity = _formatDouble(0.0);
      series.rpe = '';
      return;
    }

    final String intensityText = series.intensity.trim();
    final String rpeText = series.rpe.trim();
    final int reps = series.reps.clamp(0, 100);

    // Priorità 1: Calcolo basato sull'Intensità
    if (intensityText.isNotEmpty) {
      final intensityValue = double.tryParse(intensityText);
      if (intensityValue != null && intensityValue > 0) {
        final calculatedW =
            calculateWeightFromIntensity(currentMaxWeight, intensityValue);
        series.weight = roundWeight(calculatedW, exerciseType);
        series.intensity = _formatDouble(
            calculateIntensityFromWeight(series.weight, currentMaxWeight));
        if (reps > 0 && reps <= 10) {
          final rpe = calculateRPE(series.weight, currentMaxWeight, reps);
          series.rpe = rpe != null ? _formatDouble(rpe, precision: 1) : '';
        } else {
          series.rpe = '';
        }
        return;
      }
    }

    // Priorità 2: Calcolo basato su RPE
    if (rpeText.isNotEmpty && reps > 0 && reps <= 10) {
      final rpeValue = double.tryParse(rpeText);
      if (rpeValue != null && rpeValue >= 2 && rpeValue <= 10) {
        final percentage = getRPEPercentage(rpeValue, reps);
        final calculatedW = currentMaxWeight * percentage;
        series.weight = roundWeight(calculatedW, exerciseType);
        series.intensity = _formatDouble(
            calculateIntensityFromWeight(series.weight, currentMaxWeight));
        series.rpe = _formatDouble(rpeValue, precision: 1);
        return;
      }
    }

    // Priorità 3: Calcolo basato sul Peso
    if (series.weight > 0) {
      series.weight = roundWeight(series.weight, exerciseType);
      series.intensity = _formatDouble(
          calculateIntensityFromWeight(series.weight, currentMaxWeight));
      if (reps > 0 && reps <= 10) {
        final rpe = calculateRPE(series.weight, currentMaxWeight, reps);
        series.rpe = rpe != null ? _formatDouble(rpe, precision: 1) : '';
      } else {
        series.rpe = '';
      }
      return;
    }

    // Fallback
    series.weight = 0.0;
    series.intensity = _formatDouble(0.0);
    series.rpe = '';
  }

  /// Calcola e formatta un range di intensità (min/max) dati i pesi e il massimale.
  static String calculateIntensityRange(
      double minWeight, double maxWeight, double latestMaxWeight) {
    final currentMax = latestMaxWeight.clamp(0.0, double.maxFinite);
    if (currentMax <= 0) return "${_formatDouble(0.0)}/${_formatDouble(0.0)}";

    final minW = minWeight.clamp(0.0, double.maxFinite);
    final maxW = maxWeight.clamp(0.0, double.maxFinite);

    final minIntensity = calculateIntensityFromWeight(minW, currentMax);
    final maxIntensity = calculateIntensityFromWeight(maxW, currentMax);

    final orderedMinIntensity =
        minIntensity <= maxIntensity ? minIntensity : maxIntensity;
    final orderedMaxIntensity =
        minIntensity <= maxIntensity ? maxIntensity : minIntensity;

    return '${_formatDouble(orderedMinIntensity)}/${_formatDouble(orderedMaxIntensity)}';
  }

  /// Calcola un range di pesi (min/max) dato un range di intensità e il massimale.
  static List<double> calculateWeightRange(
      String intensityRange, double latestMaxWeight) {
    final currentMax = latestMaxWeight.clamp(0.0, double.maxFinite);
    if (currentMax <= 0) return [0.0, 0.0];

    final parts = intensityRange.split('/');
    double minW = 0.0;
    double maxW = 0.0;

    if (parts.length == 2) {
      final minIntensity =
          (double.tryParse(parts[0].trim()) ?? 0.0).clamp(0.0, 200.0);
      final maxIntensity =
          (double.tryParse(parts[1].trim()) ?? 0.0).clamp(0.0, 200.0);
      minW = calculateWeightFromIntensity(currentMax, minIntensity);
      maxW = calculateWeightFromIntensity(currentMax, maxIntensity);
    } else if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
      final intensity =
          (double.tryParse(parts[0].trim()) ?? 0.0).clamp(0.0, 200.0);
      minW = maxW = calculateWeightFromIntensity(currentMax, intensity);
    }
    final orderedMinWeight = minW <= maxW ? minW : maxW;
    final orderedMaxWeight = minW <= maxW ? maxW : minW;
    return [orderedMinWeight, orderedMaxWeight];
  }

  /// Calcola e formatta un range di RPE (min/max) dati i pesi, il massimale e le ripetizioni.
  static String? calculateRPERange(
      double minWeight, double maxWeight, double latestMaxWeight, int reps) {
    final currentMax = latestMaxWeight.clamp(0.0, double.maxFinite);
    if (currentMax <= 0 || reps <= 0 || reps > 10) return null;

    final minW = minWeight.clamp(0.0, double.maxFinite);
    final maxW = maxWeight.clamp(0.0, double.maxFinite);

    final minRPE = calculateRPE(minW, currentMax, reps);
    final maxRPE = calculateRPE(maxW, currentMax, reps);

    if (minRPE != null && maxRPE != null) {
      final orderedMinRPE = minRPE <= maxRPE ? minRPE : maxRPE;
      final orderedMaxRPE = minRPE <= maxRPE ? maxRPE : minRPE;
      return '${_formatDouble(orderedMinRPE, precision: 1)}/${_formatDouble(orderedMaxRPE, precision: 1)}';
    } else if (minRPE != null) {
      return _formatDouble(minRPE, precision: 1);
    } else if (maxRPE != null) {
      return _formatDouble(maxRPE, precision: 1);
    }
    return null;
  }

  /// Calcola un range di pesi (min/max) dato un range di RPE, le ripetizioni e il massimale.
  static List<double> calculateWeightRangeFromRPE(
      String rpeRange, int reps, double latestMaxWeight) {
    final currentMax = latestMaxWeight.clamp(0.0, double.maxFinite);
    if (currentMax <= 0 || reps <= 0 || reps > 10) return [0.0, 0.0];

    final parts = rpeRange.split('/');
    double minW = 0.0;
    double maxW = 0.0;

    if (parts.length == 2) {
      final minRPEValue =
          (double.tryParse(parts[0].trim()) ?? 0.0).clamp(2.0, 10.0);
      final maxRPEValue =
          (double.tryParse(parts[1].trim()) ?? 0.0).clamp(2.0, 10.0);
      minW = currentMax * getRPEPercentage(minRPEValue, reps);
      maxW = currentMax * getRPEPercentage(maxRPEValue, reps);
    } else if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
      final rpeValue =
          (double.tryParse(parts[0].trim()) ?? 0.0).clamp(2.0, 10.0);
      minW = maxW = currentMax * getRPEPercentage(rpeValue, reps);
    }
    final orderedMinWeight = minW <= maxW ? minW : maxW;
    final orderedMaxWeight = minW <= maxW ? maxW : minW;
    return [orderedMinWeight, orderedMaxWeight];
  }
}
