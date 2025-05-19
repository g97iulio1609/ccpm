import 'package:alphanessone/viewer/data/repositories/timer_preset_repository_impl.dart';
import 'package:alphanessone/viewer/data/repositories/workout_repository_impl.dart';
import 'package:alphanessone/viewer/domain/repositories/timer_preset_repository.dart';
import 'package:alphanessone/viewer/domain/repositories/workout_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alphanessone/viewer/domain/usecases/complete_series_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/complete_series_use_case_impl.dart';
import 'package:alphanessone/viewer/domain/usecases/get_exercise_note_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/save_exercise_note_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/delete_exercise_note_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/get_timer_presets_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/save_timer_preset_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/update_timer_preset_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/delete_timer_preset_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/save_default_timer_presets_use_case.dart';

// Firestore Instance Provider
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// SharedPreferences Instance Provider
// Questo provider è asincrono, quindi tipicamente lo si usa con FutureProvider o
// si gestisce l'istanza in modo che sia disponibile quando serve.
// Per semplicità, qui assumiamo che SharedPreferences sia inizializzato altrove
// e possiamo ottenere un'istanza sincrona se gestita correttamente all'avvio dell'app.
// Se SharedPreferences.getInstance() deve essere chiamato qui,
// allora timerPresetRepositoryProvider dovrebbe diventare un FutureProvider
// o dovremmo usare un approccio diverso per l'iniezione.

// Alternativa più robusta per SharedPreferences:
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Repository Providers

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return WorkoutRepositoryImpl(firestore);
});

final timerPresetRepositoryProvider = Provider<TimerPresetRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  // Per ora, un'iniezione più semplice assumendo che SharedPreferences sia
  // ottenibile in modo sincrono (es. inizializzato e passato all'app principale)
  // Questo è meno ideale ma semplifica l'esempio iniziale.
  // NELLA VITA REALE: preferire l'approccio con FutureProvider e la gestione asincrona.
  // TODO: Sostituire con un accesso corretto e asincrono a SharedPreferences se necessario.

  // Temporaneamente usiamo un late final per shared prefs o lo passiamo diversamente.
  // Questa è una semplificazione per non bloccare il flusso del refactoring qui.
  // Idealmente, l'app inizializza SharedPreferences e lo rende disponibile.
  // Se questo non è il caso, timerPresetRepositoryProvider dovrebbe essere un FutureProvider.
  final sharedPrefs = ref.watch(sharedPreferencesProvider);

  return sharedPrefs.when(
    data: (prefs) => TimerPresetRepositoryImpl(firestore, prefs),
    loading: () {
      // Potremmo voler restituire un'implementazione di fallback o lanciare un errore specifico
      // print("SharedPreferences is loading for TimerPresetRepository");
      // Per ora, per non bloccare, potremmo lanciare un errore se usato troppo presto
      // o attendere. Ma un Provider normale non può essere async.
      // Questo scenario evidenzia la necessità di gestire dipendenze asincrone.
      // Un approccio comune è rendere questo provider dipendente da un FutureProvider
      // e gestire lo stato di caricamento a livello UI o in un UseCase.
      throw Exception("SharedPreferences not ready for TimerPresetRepository");
    },
    error: (err, stack) {
      // print("Error loading SharedPreferences for TimerPresetRepository: $err");
      throw Exception(
          "Error loading SharedPreferences for TimerPresetRepository: $err");
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

final saveExerciseNoteUseCaseProvider =
    Provider<SaveExerciseNoteUseCase>((ref) {
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  return SaveExerciseNoteUseCaseImpl(workoutRepository);
});

final deleteExerciseNoteUseCaseProvider =
    Provider<DeleteExerciseNoteUseCase>((ref) {
  final workoutRepository = ref.watch(workoutRepositoryProvider);
  return DeleteExerciseNoteUseCaseImpl(workoutRepository);
});

final getTimerPresetsUseCaseProvider = Provider<GetTimerPresetsUseCase>((ref) {
  final timerRepository = ref.watch(timerPresetRepositoryProvider);
  return GetTimerPresetsUseCaseImpl(timerRepository);
});

final saveTimerPresetUseCaseProvider = Provider<SaveTimerPresetUseCase>((ref) {
  final timerRepository = ref.watch(timerPresetRepositoryProvider);
  return SaveTimerPresetUseCaseImpl(timerRepository);
});

final updateTimerPresetUseCaseProvider =
    Provider<UpdateTimerPresetUseCase>((ref) {
  final timerRepository = ref.watch(timerPresetRepositoryProvider);
  return UpdateTimerPresetUseCaseImpl(timerRepository);
});

final deleteTimerPresetUseCaseProvider =
    Provider<DeleteTimerPresetUseCase>((ref) {
  final timerRepository = ref.watch(timerPresetRepositoryProvider);
  return DeleteTimerPresetUseCaseImpl(timerRepository);
});

final saveDefaultTimerPresetsUseCaseProvider =
    Provider<SaveDefaultTimerPresetsUseCase>((ref) {
  final timerRepository = ref.watch(timerPresetRepositoryProvider);
  return SaveDefaultTimerPresetsUseCaseImpl(timerRepository);
});

// Altri provider per UseCases e StateNotifiers verranno aggiunti qui progressivamente.
