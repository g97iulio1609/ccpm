import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';

Future<void> updateProgramAfterMaxRM(
  ExerciseRecordService exerciseRecordService,
  String userId,
  String exerciseId,
  num newMaxWeight,
  bool keepWeight,
) async {
  if (keepWeight) {
    await exerciseRecordService.updateIntensityForProgram(
      userId,
      exerciseId,
      newMaxWeight,
    );
  } else {
    await exerciseRecordService.updateWeightsForProgram(
      userId,
      exerciseId,
      newMaxWeight,
    );
  }
}


