import 'package:alphanessone/viewer/domain/repositories/workout_repository.dart';

class SaveExerciseNoteParams {
  final String workoutId;
  final String exerciseId;
  final String note;

  SaveExerciseNoteParams({
    required this.workoutId,
    required this.exerciseId,
    required this.note,
  });
}

abstract class SaveExerciseNoteUseCase {
  Future<void> call(SaveExerciseNoteParams params);
}

class SaveExerciseNoteUseCaseImpl implements SaveExerciseNoteUseCase {
  final WorkoutRepository _workoutRepository;

  SaveExerciseNoteUseCaseImpl(this._workoutRepository);

  @override
  Future<void> call(SaveExerciseNoteParams params) async {
    // Qui potrebbe esserci logica aggiuntiva, es. sanitizzazione dell'input 'note'
    // o controllo lunghezza massima, ecc.
    if (params.note.trim().isEmpty) {
      // Se la nota è vuota dopo il trim, considerala come un'eliminazione
      // o semplicemente non salvarla. Dipende dai requisiti.
      // Qui scegliamo di eliminare se la nota diventa vuota.
      return await _workoutRepository.deleteNoteForExercise(
          params.workoutId, params.exerciseId);
    }
    await _workoutRepository.saveNoteForExercise(
        params.workoutId, params.exerciseId, params.note);
  }
}
