import 'dart:math';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'services/exercise_service.dart' as tb_exercise_service;

Future<num> getLatestMaxWeight(
  ExerciseRecordService exerciseRecordService,
  String userId,
  String exerciseId,
) async {
  // DRY: delega alla funzione centralizzata
  return tb_exercise_service.ExerciseService.getLatestMaxWeight(
    exerciseRecordService,
    userId,
    exerciseId,
  );
}

double? calculateRPE(double weight, num latestMaxWeight, int reps) {
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
      10: 0.739,
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
      10: 0.728,
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
      10: 0.717,
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
      10: 0.706,
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
      10: 0.696,
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
      10: 0.685,
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
      10: 0.675,
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
      10: 0.665,
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
      10: 0.655,
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

String generateRandomId(int length) {
  final random = Random.secure();
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
