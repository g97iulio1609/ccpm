import 'package:alphanessone/Viewer/domain/repositories/workout_repository.dart';
import 'package:alphanessone/Viewer/domain/usecases/complete_series_use_case.dart';

class CompleteSeriesUseCaseImpl implements CompleteSeriesUseCase {
  final WorkoutRepository _workoutRepository;

  CompleteSeriesUseCaseImpl(this._workoutRepository);

  @override
  Future<void> call(CompleteSeriesParams params) async {
    // Qui potrebbe esserci logica aggiuntiva prima o dopo la chiamata al repository
    // Esempio: validazione dei parametri, calcoli basati sui reps/weight target,
    // gestione di logica specifica per tipi di serie (drop set, myo-reps etc.)
    // che non dovrebbe stare nel repository.

    // Per ora, chiamiamo direttamente il metodo del repository che fa al caso nostro.
    // WorkoutRepository.updateSeriesDoneStatus fa esattamente ciò che serve.
    await _workoutRepository.updateSeriesDoneStatus(
      params.seriesId,
      params.isDone,
      params.repsDone,
      params.weightDone,
    );

    // Esempio di logica aggiuntiva che potrebbe stare qui:
    // if (params.isDone) {
    //   final series = await _workoutRepository.getSeries(params.seriesId);
    //   // Controlla se questo completa l'esercizio o il workout
    //   // Invia eventi analytics
    // }
  }
}
