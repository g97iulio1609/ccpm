import 'package:alphanessone/Viewer/domain/repositories/workout_repository.dart';

class DeleteExerciseNoteParams {
  final String workoutId;
  final String exerciseId;

  DeleteExerciseNoteParams({required this.workoutId, required this.exerciseId});
}

abstract class DeleteExerciseNoteUseCase {
  Future<void> call(DeleteExerciseNoteParams params);
}

class DeleteExerciseNoteUseCaseImpl implements DeleteExerciseNoteUseCase {
  final WorkoutRepository _workoutRepository;

  DeleteExerciseNoteUseCaseImpl(this._workoutRepository);

  @override
  Future<void> call(DeleteExerciseNoteParams params) async {
    await _workoutRepository.deleteNoteForExercise(
      params.workoutId,
      params.exerciseId,
    );
  }
}
