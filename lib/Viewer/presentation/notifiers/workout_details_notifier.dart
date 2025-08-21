import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/Viewer/domain/repositories/workout_repository.dart'; // Per caricare il workout completo
import 'package:alphanessone/Viewer/domain/usecases/complete_series_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/save_exercise_note_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/delete_exercise_note_use_case.dart';
import 'package:alphanessone/Viewer/viewer_providers.dart'; // Import per i provider
// Potremmo aggiungere GetWorkoutUseCase se volessimo più logica nel caricamento

class WorkoutDetailsState {
  final Workout? workout;
  final bool isLoading;
  final String? error;
  final String? activeExerciseId; // ID dell'esercizio attualmente "aperto" o in focus
  // Potremmo aggiungere qui altri stati specifici della UI, es. per i dialoghi

  WorkoutDetailsState({this.workout, this.isLoading = false, this.error, this.activeExerciseId});

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

  Future<void> completeSeries(String seriesId, bool isDone, int repsDone, double weightDone) async {
    // Validazione parametri
    if (seriesId.isEmpty) {
      state = state.copyWith(error: "ID serie mancante");
      return;
    }

    try {
      await _completeSeriesUseCase.call(
        CompleteSeriesParams(
          seriesId: seriesId,
          isDone: isDone,
          repsDone: repsDone,
          weightDone: weightDone,
        ),
      );

      // Tenta l'aggiornamento locale, se fallisce ricarichiamo tutto
      try {
        _updateSeriesInLocalState(seriesId, isDone, repsDone, weightDone);
      } catch (localUpdateError) {
        await _loadWorkout();
      }
    } catch (e) {
      state = state.copyWith(error: "Errore nel completare la serie: ${e.toString()}");
    }
  }

  Future<void> completeCardioSeries(
    Series series, {
    int? executedDurationSeconds,
    int? executedDistanceMeters,
    int? executedAvgHr,
  }) async {
    if (series.id == null || series.id!.isEmpty) {
      state = state.copyWith(error: "ID serie mancante");
      return;
    }

    final updated = series.copyWith(
      done: true,
      isCompleted: true,
      executedDurationSeconds: executedDurationSeconds ?? series.executedDurationSeconds,
      executedDistanceMeters: executedDistanceMeters ?? series.executedDistanceMeters,
      executedAvgHr: executedAvgHr ?? series.executedAvgHr,
    );

    try {
      await _workoutRepository.updateSeries(updated);
      _replaceSeriesInLocalState(updated);
    } catch (e) {
      state = state.copyWith(error: "Errore nel completare la serie cardio: ${e.toString()}");
    }
  }

  void _replaceSeriesInLocalState(Series updated) {
    final workout = state.workout;
    if (workout == null) return;
    try {
      final newExercises = workout.exercises.map((ex) {
        final newSeries = ex.series.map((s) => s.id == updated.id ? updated : s).toList();
        return ex.copyWith(series: newSeries);
      }).toList();
      state = state.copyWith(workout: workout.copyWith(exercises: newExercises));
    } catch (_) {
      // fallback: reload
      _loadWorkout();
    }
  }

  Future<void> saveExerciseNote(String exerciseId, String note) async {
    if (state.workout == null || state.workout!.id == null) return;
    try {
      await _saveExerciseNoteUseCase.call(
        SaveExerciseNoteParams(workoutId: state.workout!.id!, exerciseId: exerciseId, note: note),
      );
      // Aggiorna solo la nota nell'esercizio specifico
      _updateExerciseNoteInLocalState(exerciseId, note);
    } catch (e) {
      state = state.copyWith(error: "Errore nel salvare la nota: ${e.toString()}");
    }
  }

  Future<void> deleteExerciseNote(String exerciseId) async {
    if (state.workout == null || state.workout!.id == null) return;
    try {
      await _deleteExerciseNoteUseCase.call(
        DeleteExerciseNoteParams(workoutId: state.workout!.id!, exerciseId: exerciseId),
      );
      // Rimuove la nota dall'esercizio specifico
      _updateExerciseNoteInLocalState(exerciseId, null);
    } catch (e) {
      state = state.copyWith(error: "Errore nell'eliminare la nota: ${e.toString()}");
    }
  }

  /// Aggiorna solo la serie specifica nello stato locale senza ricaricare tutto
  void _updateSeriesInLocalState(String seriesId, bool isDone, int repsDone, double weightDone) {
    if (state.workout == null) return;

    final updatedWorkout = _updateSeriesInWorkout(
      state.workout!,
      seriesId,
      isDone,
      repsDone,
      weightDone,
    );

    if (updatedWorkout != null) {
      state = state.copyWith(workout: updatedWorkout);
    }
  }

  /// Trova e aggiorna la serie nel workout
  Workout? _updateSeriesInWorkout(
    Workout workout,
    String seriesId,
    bool isDone,
    int repsDone,
    double weightDone,
  ) {
    if (seriesId.isEmpty) {
      return null;
    }

    bool updated = false;

    try {
      final updatedExercises = workout.exercises.map((exercise) {
        final updatedSeries = exercise.series.map((series) {
          if (series.id == seriesId) {
            updated = true;
            return series.copyWith(
              done: isDone,
              isCompleted: isDone,
              repsDone: repsDone,
              weightDone: weightDone,
            );
          }
          return series;
        }).toList();

        return exercise.copyWith(series: updatedSeries);
      }).toList();

      if (updated) {
        return workout.copyWith(exercises: updatedExercises);
      }
    } catch (e) {
      // In caso di errore, ricarichiamo tutto per sicurezza
      _loadWorkout();
      return null;
    }

    return null;
  }

  /// Aggiorna solo la nota dell'esercizio specifico nello stato locale
  void _updateExerciseNoteInLocalState(String exerciseId, String? note) {
    if (state.workout == null || exerciseId.isEmpty) return;

    try {
      final updatedExercises = state.workout!.exercises.map((exercise) {
        if (exercise.id == exerciseId) {
          return exercise.copyWith(note: note);
        }
        return exercise;
      }).toList();

      final updatedWorkout = state.workout!.copyWith(exercises: updatedExercises);
      state = state.copyWith(workout: updatedWorkout);
    } catch (e) {
      // In caso di errore, ricarichiamo tutto per sicurezza
      _loadWorkout();
    }
  }

  // Altri metodi per gestire logica di superset, cambio ordine esercizi, ecc. potrebbero essere aggiunti qui.
}

// Provider per WorkoutDetailsNotifier
final workoutDetailsNotifierProvider = StateNotifierProvider.family
    .autoDispose<WorkoutDetailsNotifier, WorkoutDetailsState, String>((ref, workoutId) {
      final workoutRepository = ref.watch(
        workoutRepositoryProvider,
      ); // Importato da viewer_providers.dart
      final completeSeriesUseCase = ref.watch(completeSeriesUseCaseProvider);
      final saveNoteUseCase = ref.watch(saveExerciseNoteUseCaseProvider);
      final deleteNoteUseCase = ref.watch(deleteExerciseNoteUseCaseProvider);

      return WorkoutDetailsNotifier(
        workoutRepository,
        completeSeriesUseCase,
        saveNoteUseCase,
        deleteNoteUseCase,
        workoutId,
      );
    });
