import 'package:alphanessone/Viewer/data/repositories/timer_preset_repository_impl.dart';
import 'package:alphanessone/Viewer/data/repositories/workout_repository_impl.dart';
import 'package:alphanessone/Viewer/domain/repositories/timer_preset_repository.dart';
import 'package:alphanessone/Viewer/domain/repositories/workout_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alphanessone/Viewer/domain/usecases/complete_series_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/complete_series_use_case_impl.dart';
import 'package:alphanessone/Viewer/domain/usecases/get_exercise_note_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/save_exercise_note_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/delete_exercise_note_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/get_timer_presets_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/save_timer_preset_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/update_timer_preset_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/delete_timer_preset_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/save_default_timer_presets_use_case.dart';

// Firestore Instance Provider
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// SharedPreferences Instance Provider
// Questo provider è asincrono, quindi tipicamente lo si usa con FutureProvider o
// si gestisce l'istanza in modo che sia disponibile quando serve.
// Per semplicità, qui assumiamo che SharedPreferences sia inizializzato altrove
// e possiamo ottenere un'istanza sincrona se gestita correttamente all'avvio dell'app.
// Se SharedPreferences.getInstance() deve essere chiamato qui,
// allora timerPresetRepositoryProvider dovrebbe diventare un FutureProvider
// o dovremmo usare un approccio diverso per l'iniezione.

// Alternativa più robusta per SharedPreferences:
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

// Repository Providers

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return WorkoutRepositoryImpl(firestore);
});

// Implementazione corretta e asincrona del TimerPresetRepository
final timerPresetRepositoryProvider = FutureProvider<TimerPresetRepository>((
  ref,
) async {
  final firestore = ref.watch(firestoreProvider);
  final sharedPrefs = await ref.watch(sharedPreferencesProvider.future);
  return TimerPresetRepositoryImpl(firestore, sharedPrefs);
});

// Provider sincrono di fallback per quando SharedPreferences non è disponibile
final timerPresetRepositoryFallbackProvider = Provider<TimerPresetRepository?>((
  ref,
) {
  final firestore = ref.watch(firestoreProvider);
  final sharedPrefsAsync = ref.watch(sharedPreferencesProvider);

  return sharedPrefsAsync.when(
    data: (prefs) => TimerPresetRepositoryImpl(firestore, prefs),
    loading: () => null, // Restituisce null durante il caricamento
    error: (err, stack) {
      // Log dell'errore per debugging
      debugPrint("Errore nel caricamento di SharedPreferences: $err");
      return null; // Restituisce null in caso di errore
    },
  );
});

// --- Use Case Providers ---

final completeSeriesUseCaseProvider = Provider<CompleteSeriesUseCase>((ref) {
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  return CompleteSeriesUseCaseImpl(workoutRepository);
});

final getExerciseNoteUseCaseProvider = Provider<GetExerciseNoteUseCase>((ref) {
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  return GetExerciseNoteUseCaseImpl(workoutRepository);
});

final saveExerciseNoteUseCaseProvider = Provider<SaveExerciseNoteUseCase>((
  ref,
) {
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  return SaveExerciseNoteUseCaseImpl(workoutRepository);
});

final deleteExerciseNoteUseCaseProvider = Provider<DeleteExerciseNoteUseCase>((
  ref,
) {
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  return DeleteExerciseNoteUseCaseImpl(workoutRepository);
});

final getTimerPresetsUseCaseProvider = FutureProvider<GetTimerPresetsUseCase>((
  ref,
) async {
  final timerRepository = await ref.watch(timerPresetRepositoryProvider.future);
  return GetTimerPresetsUseCaseImpl(timerRepository);
});

final saveTimerPresetUseCaseProvider = FutureProvider<SaveTimerPresetUseCase>((
  ref,
) async {
  final timerRepository = await ref.watch(timerPresetRepositoryProvider.future);
  return SaveTimerPresetUseCaseImpl(timerRepository);
});

final updateTimerPresetUseCaseProvider =
    FutureProvider<UpdateTimerPresetUseCase>((ref) async {
      final timerRepository = await ref.watch(
        timerPresetRepositoryProvider.future,
      );
      return UpdateTimerPresetUseCaseImpl(timerRepository);
    });

final deleteTimerPresetUseCaseProvider =
    FutureProvider<DeleteTimerPresetUseCase>((ref) async {
      final timerRepository = await ref.watch(
        timerPresetRepositoryProvider.future,
      );
      return DeleteTimerPresetUseCaseImpl(timerRepository);
    });

final saveDefaultTimerPresetsUseCaseProvider =
    FutureProvider<SaveDefaultTimerPresetsUseCase>((ref) async {
      final timerRepository = await ref.watch(
        timerPresetRepositoryProvider.future,
      );
      return SaveDefaultTimerPresetsUseCaseImpl(timerRepository);
    });

// Altri provider per UseCases e StateNotifiers verranno aggiunti qui progressivamente.
