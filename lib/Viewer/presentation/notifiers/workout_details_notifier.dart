import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/viewer/domain/repositories/workout_repository.dart'; // Per caricare il workout completo
import 'package:alphanessone/viewer/domain/usecases/complete_series_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/save_exercise_note_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/delete_exercise_note_use_case.dart';
import 'package:alphanessone/viewer/viewer_providers.dart'; // Import per i provider
// Potremmo aggiungere GetWorkoutUseCase se volessimo più logica nel caricamento

class WorkoutDetailsState {
  final Workout? workout;
  final bool isLoading;
  final String? error;
  final String?
      activeExerciseId; // ID dell'esercizio attualmente "aperto" o in focus
  // Potremmo aggiungere qui altri stati specifici della UI, es. per i dialoghi

  WorkoutDetailsState({
    this.workout,
    this.isLoading = false,
    this.error,
    this.activeExerciseId,
  });

  WorkoutDetailsState copyWith({
    Workout? workout,
    bool? isLoading,
    String? error,
    String? activeExerciseId,
    bool clearError = false,
  }) {
    return WorkoutDetailsState(
      workout: workout ?? this.workout,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      activeExerciseId: activeExerciseId ?? this.activeExerciseId,
    );
  }
}

class WorkoutDetailsNotifier extends StateNotifier<WorkoutDetailsState> {
  final WorkoutRepository _workoutRepository;
  final CompleteSeriesUseCase _completeSeriesUseCase;
  final SaveExerciseNoteUseCase _saveExerciseNoteUseCase;
  final DeleteExerciseNoteUseCase _deleteExerciseNoteUseCase;
  final String _workoutId;

  WorkoutDetailsNotifier(
    this._workoutRepository,
    this._completeSeriesUseCase,
    this._saveExerciseNoteUseCase,
    this._deleteExerciseNoteUseCase,
    this._workoutId,
  ) : super(WorkoutDetailsState(isLoading: true)) {
    _loadWorkout();
  }

  Future<void> _loadWorkout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final workout = await _workoutRepository.getWorkout(_workoutId);
      state = state.copyWith(workout: workout, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refreshWorkout() async {
    await _loadWorkout();
  }

  void setActiveExercise(String? exerciseId) {
    state = state.copyWith(activeExerciseId: exerciseId);
  }

  Future<void> completeSeries(
      String seriesId, bool isDone, int repsDone, double weightDone) async {
    // Potremmo voler mostrare un feedback di caricamento specifico per la serie
    try {
      await _completeSeriesUseCase.call(CompleteSeriesParams(
        seriesId: seriesId,
        isDone: isDone,
        repsDone: repsDone,
        weightDone: weightDone,
      ));
      // Dopo aver completato la serie, ricarichiamo il workout per riflettere i cambiamenti.
      // Questo è un approccio semplice. Alternative più complesse potrebbero aggiornare
      // solo la serie specifica nello stato locale per una UI più reattiva,
      // ma richiederebbero una gestione dello stato più granulare.
      await _loadWorkout();
    } catch (e) {
      // Gestire l'errore, magari mostrandolo nella UI
      state = state.copyWith(
          error: "Errore nel completare la serie: ${e.toString()}");
    }
  }

  Future<void> saveExerciseNote(String exerciseId, String note) async {
    if (state.workout == null) return;
    try {
      await _saveExerciseNoteUseCase.call(SaveExerciseNoteParams(
        workoutId: state.workout!.id,
        exerciseId: exerciseId,
        note: note,
      ));
      // Ricarica per vedere la nota aggiornata
      await _loadWorkout();
    } catch (e) {
      state =
          state.copyWith(error: "Errore nel salvare la nota: ${e.toString()}");
    }
  }

  Future<void> deleteExerciseNote(String exerciseId) async {
    if (state.workout == null) return;
    try {
      await _deleteExerciseNoteUseCase.call(DeleteExerciseNoteParams(
        workoutId: state.workout!.id,
        exerciseId: exerciseId,
      ));
      // Ricarica per vedere la nota rimossa
      await _loadWorkout();
    } catch (e) {
      state = state.copyWith(
          error: "Errore nell'eliminare la nota: ${e.toString()}");
    }
  }

  // Altri metodi per gestire logica di superset, cambio ordine esercizi, ecc. potrebbero essere aggiunti qui.
}

// Provider per WorkoutDetailsNotifier
final workoutDetailsNotifierProvider = StateNotifierProvider.family
    .autoDispose<WorkoutDetailsNotifier, WorkoutDetailsState, String>(
        (ref, workoutId) {
  final workoutRepository = ref
      .watch(workoutRepositoryProvider); // Importato da viewer_providers.dart
  final completeSeriesUseCase = ref.watch(completeSeriesUseCaseProvider);
  final saveNoteUseCase = ref.watch(saveExerciseNoteUseCaseProvider);
  final deleteNoteUseCase = ref.watch(deleteExerciseNoteUseCaseProvider);

  return WorkoutDetailsNotifier(workoutRepository, completeSeriesUseCase,
      saveNoteUseCase, deleteNoteUseCase, workoutId);
});
