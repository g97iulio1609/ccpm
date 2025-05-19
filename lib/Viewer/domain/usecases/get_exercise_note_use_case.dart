import 'package:alphanessone/viewer/domain/repositories/workout_repository.dart';

class GetExerciseNoteParams {
  final String workoutId;
  final String exerciseId;

  GetExerciseNoteParams({required this.workoutId, required this.exerciseId});
}

abstract class GetExerciseNoteUseCase {
  Future<String?> call(GetExerciseNoteParams params);
}

class GetExerciseNoteUseCaseImpl implements GetExerciseNoteUseCase {
  final WorkoutRepository _workoutRepository;

  GetExerciseNoteUseCaseImpl(this._workoutRepository);

  @override
  Future<String?> call(GetExerciseNoteParams params) async {
    return await _workoutRepository.getNoteForExercise(
        params.workoutId, params.exerciseId);
  }
}
