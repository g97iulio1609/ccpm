import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:flutter/material.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import './models/training_model.dart';

class SeriesUtils {
  static double calculateWeightFromIntensity(double maxWeight, double intensity) {
    return maxWeight * (intensity / 100);
  }

  static double getRPEPercentage(double rpe, int reps) {
    final rpeTable = {
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

    return rpeTable[rpe.toInt()]?[reps] ?? 1.0;
  }

 static double roundWeight(double weight, String? exerciseType) {
    final effectiveExerciseType =
        exerciseType?.isNotEmpty == true ? exerciseType : 'Default';
    switch (effectiveExerciseType) {
      case 'Manubri':
        return (weight / 2).round() * 2.0;
      case 'Bilanciere':
        if (weight == 0) {
          return 0;
        } else {
          return (weight / 2.5).round() * 2.5;
        }
      default:
        final roundedWeight = double.parse((weight).toStringAsFixed(1));
        return (roundedWeight / 2).round() * 2.0;
    }
  }

  static num calculateIntensityFromWeight(num weight, num maxWeight) {
    if (maxWeight == 0) return 0;
    return (weight / maxWeight) * 100;
  }

  static double? calculateRPE(double weight, num latestMaxWeight, int reps) {
    final rpeTable = {
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

    if (latestMaxWeight != 0) {
      final intensity = weight / latestMaxWeight;
      double? calculatedRPE;
      rpeTable.forEach((rpe, repPercentages) {
        repPercentages.forEach((rep, percentage) {
          if ((intensity - percentage).abs() < 0.01 && rep == reps) {
            calculatedRPE = rpe.toDouble();
          }
        });
      });
      return calculatedRPE;
    } else {
      return null;
    }
  }

  static Future<num> getLatestMaxWeight(
      ExerciseRecordService exerciseRecordService, String userId, String exerciseId) async {
    num latestMaxWeight = 0;
    await exerciseRecordService
        .getExerciseRecords(userId: userId, exerciseId: exerciseId)
        .first
        .then((records) {
      if (records.isNotEmpty) {
        final latestRecord = records.first;
        latestMaxWeight = latestRecord.maxWeight;
      }
    }).catchError((error) {
      // Handle error
    });
    return latestMaxWeight;
  }

  static void updateWeightFromIntensity(
    TextEditingController weightController,
    TextEditingController intensityController,
    String exerciseType,
    num latestMaxWeight,
    ValueNotifier<double> weightNotifier,
  ) {
    final intensity = double.tryParse(intensityController.text) ?? 0;
    final calculatedWeight = calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
    final roundedWeight = roundWeight(calculatedWeight, exerciseType);
    weightController.text = roundedWeight.toStringAsFixed(2);
    weightNotifier.value = roundedWeight;
  }

  static void updateIntensityFromWeight(
    TextEditingController weightController,
    TextEditingController intensityController,
    num latestMaxWeight,
  ) {
    final weight = double.tryParse(weightController.text) ?? 0;
    if (weight > 0 && latestMaxWeight > 0) {
      final calculatedIntensity = calculateIntensityFromWeight(weight, latestMaxWeight);
      intensityController.text = calculatedIntensity.toStringAsFixed(2);
    } else {
      intensityController.clear();
    }
  }

 static void updateWeightFromRPE(
      TextEditingController repsController,
      TextEditingController weightController,
      TextEditingController rpeController,
      TextEditingController intensityController,
      String exerciseType,
      num latestMaxWeight,
      ValueNotifier<double> weightNotifier) {
    final rpeText = rpeController.text;
    if (rpeText.isNotEmpty) {
      final rpe = double.parse(rpeText);
      final reps = int.tryParse(repsController.text) ?? 0;
      final percentage = getRPEPercentage(rpe, reps);
      final calculatedWeight = latestMaxWeight.toDouble() * percentage;
      final roundedWeight = roundWeight(calculatedWeight, exerciseType);
      weightController.text = roundedWeight.toStringAsFixed(2);
      weightNotifier.value = roundedWeight;
      final calculatedIntensity = calculateIntensityFromWeight(
          roundedWeight, latestMaxWeight.toDouble());
      intensityController.text = calculatedIntensity.toStringAsFixed(2);
    }
  }

  static void updateRPE(
      TextEditingController repsController,
      TextEditingController weightController,
      TextEditingController rpeController,
      TextEditingController intensityController,
      num latestMaxWeight) {
    final weight = double.tryParse(weightController.text) ?? 0;
    final reps = int.tryParse(repsController.text) ?? 0;
    final calculatedRPE =
        calculateRPE(weight, latestMaxWeight.toDouble(), reps);
    if (calculatedRPE != null) {
      rpeController.text = calculatedRPE.toStringAsFixed(1);
      final intensity =
          calculateIntensityFromWeight(weight, latestMaxWeight.toDouble());
      intensityController.text = intensity.toStringAsFixed(2);
    } else {
     rpeController.clear();
    }
  }

  static Future<void> updateSeriesWeights(TrainingProgram program, int weekIndex,
      int workoutIndex, int exerciseIndex, ExerciseRecordService exerciseRecordService) async {
    final exercise = program
        .weeks[weekIndex].workouts[workoutIndex].exercises[exerciseIndex];
    final exerciseId = exercise.exerciseId;
    final athleteId = program.athleteId;
    if (exerciseId != null) {
      final latestMaxWeight =
          await getLatestMaxWeight(exerciseRecordService, athleteId, exerciseId);
      for (final series in exercise.series) {
        _calculateWeight(series, exercise.type, latestMaxWeight);
      }
        }
  }

  static void _calculateWeight(
      Series series, String? exerciseType, num? latestMaxWeight) {
    double calculatedWeight = 0;

    if (latestMaxWeight != null) {
      if (series.intensity.isNotEmpty) {
        final intensity = double.tryParse(series.intensity) ?? 0;
        if (intensity > 0) {
          calculatedWeight = calculateWeightFromIntensity(
              latestMaxWeight.toDouble(), intensity);
          series.weight = roundWeight(calculatedWeight, exerciseType);
        }
      } else if (series.rpe.isNotEmpty) {
        final rpe = double.tryParse(series.rpe) ?? 0;
        if (rpe > 0) {
          final rpePercentage = getRPEPercentage(rpe, series.reps);
          calculatedWeight = latestMaxWeight.toDouble() * rpePercentage;
          series.weight = roundWeight(calculatedWeight, exerciseType);
        }
      } else {
        series.intensity = calculateIntensityFromWeight(
                series.weight, latestMaxWeight.toDouble())
            .toStringAsFixed(2);
        final rpe = calculateRPE(
            series.weight, latestMaxWeight.toDouble(), series.reps);
        series.rpe = rpe != null ? rpe.toStringAsFixed(1) : '';
      }
    }
  }

  static String calculateIntensityRange(double minWeight, double maxWeight, num latestMaxWeight) {
    if (latestMaxWeight == 0) return '0';
    final minIntensity = (minWeight / latestMaxWeight) * 100;
    final maxIntensity = (maxWeight / latestMaxWeight) * 100;
    return '${minIntensity.toStringAsFixed(2)}/${maxIntensity.toStringAsFixed(2)}';
  }

  static List<double> calculateWeightRange(String intensityRange, num latestMaxWeight) {
    final parts = intensityRange.split('/');
    if (parts.length == 2) {
      final minIntensity = double.parse(parts[0]);
      final maxIntensity = double.parse(parts[1]);
      final minWeight = calculateWeightFromIntensity(latestMaxWeight.toDouble(), minIntensity);
      final maxWeight = calculateWeightFromIntensity(latestMaxWeight.toDouble(), maxIntensity);
      return [minWeight, maxWeight];
    } else {
      final intensity = double.parse(intensityRange);
      final weight = calculateWeightFromIntensity(latestMaxWeight.toDouble(), intensity);
      return [weight, weight];
    }
  }

  static String? calculateRPERange(double minWeight, double maxWeight, num latestMaxWeight, int reps) {
    final minRPE = calculateRPE(minWeight, latestMaxWeight, reps);
    final maxRPE = calculateRPE(maxWeight, latestMaxWeight, reps);
    if (minRPE != null && maxRPE != null) {
      return '${minRPE.toStringAsFixed(1)}/${maxRPE.toStringAsFixed(1)}';
    }
    return null;
  }

  static List<double> calculateWeightRangeFromRPE(String rpeRange, int reps, num latestMaxWeight) {
    final parts = rpeRange.split('/');
    if (parts.length == 2) {
      final minRPE = double.parse(parts[0]);
      final maxRPE = double.parse(parts[1]);
      final minPercentage = getRPEPercentage(minRPE, reps);
      final maxPercentage = getRPEPercentage(maxRPE, reps);
      final minWeight = latestMaxWeight.toDouble() * minPercentage;
      final maxWeight = latestMaxWeight.toDouble() * maxPercentage;
      return [minWeight, maxWeight];
    } else {
      final rpe = double.parse(rpeRange);
      final percentage = getRPEPercentage(rpe, reps);
      final weight = latestMaxWeight.toDouble() * percentage;
      return [weight, weight];
    }
  }
}