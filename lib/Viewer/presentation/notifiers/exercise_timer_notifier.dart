import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/viewer/domain/entities/timer_preset.dart';
import 'package:alphanessone/viewer/domain/usecases/get_timer_presets_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/save_timer_preset_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/delete_timer_preset_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/save_default_timer_presets_use_case.dart';
import 'package:alphanessone/viewer/domain/usecases/update_timer_preset_use_case.dart';
import 'package:alphanessone/viewer/viewer_providers.dart'; // Import per i provider degli use case

// Stato del Timer
enum TimerStatus { initial, running, paused, finished }

class ExerciseTimerState {
  final int initialDuration;
  final int remainingDuration;
  final TimerStatus status;
  final List<TimerPreset> presets;
  final TimerPreset? selectedPreset;
  final String? error;
  final bool isLoadingPresets;

  ExerciseTimerState({
    required this.initialDuration,
    required this.remainingDuration,
    required this.status,
    this.presets = const [],
    this.selectedPreset,
    this.error,
    this.isLoadingPresets = false,
  });

  ExerciseTimerState copyWith({
    int? initialDuration,
    int? remainingDuration,
    TimerStatus? status,
    List<TimerPreset>? presets,
    TimerPreset? selectedPreset,
    String? error,
    bool? isLoadingPresets,
    bool clearSelectedPreset = false,
  }) {
    return ExerciseTimerState(
      initialDuration: initialDuration ?? this.initialDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      status: status ?? this.status,
      presets: presets ?? this.presets,
      selectedPreset:
          clearSelectedPreset ? null : selectedPreset ?? this.selectedPreset,
      error: error ?? this.error,
      isLoadingPresets: isLoadingPresets ?? this.isLoadingPresets,
    );
  }
}

class ExerciseTimerNotifier extends StateNotifier<ExerciseTimerState> {
  final GetTimerPresetsUseCase _getTimerPresetsUseCase;
  final SaveTimerPresetUseCase _saveTimerPresetUseCase;
  final DeleteTimerPresetUseCase _deleteTimerPresetUseCase;
  final SaveDefaultTimerPresetsUseCase _saveDefaultTimerPresetsUseCase;
  final UpdateTimerPresetUseCase _updateTimerPresetUseCase;

  Timer? _timer;
  String _currentUserId; // Assumiamo che l'ID utente sia disponibile

  ExerciseTimerNotifier(
    this._getTimerPresetsUseCase,
    this._saveTimerPresetUseCase,
    this._deleteTimerPresetUseCase,
    this._saveDefaultTimerPresetsUseCase,
    this._updateTimerPresetUseCase,
    this._currentUserId,
    int initialDuration, // Durata iniziale per il timer, es. da una serie
  ) : super(ExerciseTimerState(
          initialDuration: initialDuration,
          remainingDuration: initialDuration,
          status: TimerStatus.initial,
        )) {
    loadPresets();
  }

  Future<void> loadPresets() async {
    state = state.copyWith(isLoadingPresets: true, error: null);
    try {
      final presets = await _getTimerPresetsUseCase.call(_currentUserId);
      if (presets.isEmpty) {
        // Se non ci sono preset, salva quelli di default
        await _createDefaultPresets();
      } else {
        state = state.copyWith(presets: presets, isLoadingPresets: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoadingPresets: false);
    }
  }

  Future<void> _createDefaultPresets() async {
    // Presets di default come nell'originale ExerciseTimerBottomSheet
    final defaultPresets = [
      TimerPreset(id: '', userId: _currentUserId, label: '30 sec', seconds: 30),
      TimerPreset(id: '', userId: _currentUserId, label: '1 min', seconds: 60),
      TimerPreset(id: '', userId: _currentUserId, label: '90 sec', seconds: 90),
      TimerPreset(id: '', userId: _currentUserId, label: '2 min', seconds: 120),
      TimerPreset(id: '', userId: _currentUserId, label: '3 min', seconds: 180),
    ];
    try {
      await _saveDefaultTimerPresetsUseCase.call(SaveDefaultTimerPresetsParams(
          userId: _currentUserId, defaultPresets: defaultPresets));
      // Ricarica i preset dopo aver aggiunto quelli di default
      final presets = await _getTimerPresetsUseCase.call(_currentUserId);
      state = state.copyWith(presets: presets, isLoadingPresets: false);
    } catch (e) {
      state = state.copyWith(
          error: 'Errore nel creare preset di default: ${e.toString()}',
          isLoadingPresets: false);
    }
  }

  void selectPreset(TimerPreset preset) {
    _timer?.cancel();
    state = state.copyWith(
      initialDuration: preset.seconds,
      remainingDuration: preset.seconds,
      status: TimerStatus.initial,
      selectedPreset: preset,
    );
  }

  void setCustomTime(int seconds) {
    _timer?.cancel();
    state = state.copyWith(
      initialDuration: seconds,
      remainingDuration: seconds,
      status: TimerStatus.initial,
      clearSelectedPreset:
          true, // Deseleziona qualsiasi preset quando si imposta un tempo custom
    );
  }

  void startTimer() {
    if (state.status == TimerStatus.running && state.remainingDuration == 0) {
      // Se il timer era in esecuzione ed è arrivato a 0, resettalo alla durata iniziale o del preset selezionato
      state = state.copyWith(
          remainingDuration: state.initialDuration,
          status: TimerStatus.initial);
    }
    if (state.status != TimerStatus.running) {
      _timer?.cancel(); // Cancella timer esistenti per sicurezza
      state = state.copyWith(status: TimerStatus.running, error: null);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.remainingDuration > 0) {
          state =
              state.copyWith(remainingDuration: state.remainingDuration - 1);
        } else {
          _timer?.cancel();
          state = state.copyWith(status: TimerStatus.finished);
          // Qui si potrebbe aggiungere una callback per notificare il completamento del timer
        }
      });
    }
  }

  void pauseTimer() {
    if (state.status == TimerStatus.running) {
      _timer?.cancel();
      state = state.copyWith(status: TimerStatus.paused);
    }
  }

  void resetTimer() {
    _timer?.cancel();
    state = state.copyWith(
        remainingDuration: state.initialDuration, status: TimerStatus.initial);
  }

  Future<void> saveCurrentTimeAsPreset(String label) async {
    if (state.initialDuration <= 0) return; // Non salvare preset di 0 secondi
    state = state.copyWith(isLoadingPresets: true, error: null);
    try {
      final newPreset = TimerPreset(
        id: '', // L'ID sarà generato dal repository/firestore
        userId: _currentUserId,
        label: label,
        seconds: state
            .initialDuration, // Salva la durata iniziale impostata (non quella rimanente)
      );
      await _saveTimerPresetUseCase.call(
          SaveTimerPresetParams(userId: _currentUserId, preset: newPreset));
      await loadPresets(); // Ricarica per aggiornare la lista
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoadingPresets: false);
    }
  }

  Future<void> deleteSelectedPreset() async {
    if (state.selectedPreset == null) return;
    state = state.copyWith(isLoadingPresets: true, error: null);
    try {
      await _deleteTimerPresetUseCase.call(DeleteTimerPresetParams(
          userId: _currentUserId, presetId: state.selectedPreset!.id));
      state = state.copyWith(
          clearSelectedPreset: true); // Deseleziona il preset eliminato
      await loadPresets(); // Ricarica per aggiornare la lista
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoadingPresets: false);
    }
  }

  Future<void> updateSelectedPreset(String newLabel, int newSeconds) async {
    if (state.selectedPreset == null) {
      state = state.copyWith(
          error: "Nessun preset selezionato per l'aggiornamento.");
      return;
    }
    if (newLabel.trim().isEmpty || newSeconds <= 0) {
      state = state.copyWith(
          error: "Etichetta o durata non valide per l'aggiornamento.");
      return;
    }

    state = state.copyWith(isLoadingPresets: true, error: null);
    try {
      final updatedPreset = state.selectedPreset!.copyWith(
        label: newLabel,
        seconds: newSeconds,
        // userId non dovrebbe cambiare, è già corretto nel selectedPreset
      );
      await _updateTimerPresetUseCase.call(UpdateTimerPresetParams(
          userId: _currentUserId, preset: updatedPreset));
      // Dopo l'aggiornamento, il preset selezionato potrebbe necessitare di essere aggiornato nello stato
      // o semplicemente ricarichiamo tutto. Ricaricare è più semplice.
      await loadPresets();
      // Potremmo voler riselezionare il preset aggiornato se l'ID non cambia
      // e se la logica di `loadPresets` non lo deseleziona.
      // Per ora, `loadPresets` aggiorna la lista, la selezione manuale può avvenire nella UI se necessario.
      // Oppure, cerchiamo il preset aggiornato e lo impostiamo come selectedPreset.
      final reloadedPresets =
          await _getTimerPresetsUseCase.call(_currentUserId);
      final potentiallyUpdatedSelectedPreset = reloadedPresets.firstWhere(
        (p) => p.id == updatedPreset.id,
        orElse: () => state
            .selectedPreset!, // fallback al vecchio se non trovato (improbabile)
      );
      state = state.copyWith(
          selectedPreset: potentiallyUpdatedSelectedPreset,
          isLoadingPresets: false);
    } catch (e) {
      state = state.copyWith(
          error: "Errore aggiornamento preset: ${e.toString()}",
          isLoadingPresets: false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Provider per ExerciseTimerNotifier
// Avrà bisogno dell'ID utente e di una durata iniziale,
// quindi sarà probabilmente un Family Provider o un provider che ottiene questi valori in altro modo.
// Esempio con Family (semplificato, l'ID utente andrebbe preso da un AuthProvider)
final exerciseTimerNotifierProvider = StateNotifierProvider.family.autoDispose<
    ExerciseTimerNotifier,
    ExerciseTimerState,
    ({String userId, int initialDuration})>((ref, params) {
  final getPresets = ref.watch(getTimerPresetsUseCaseProvider);
  final savePreset = ref.watch(saveTimerPresetUseCaseProvider);
  final deletePreset = ref.watch(deleteTimerPresetUseCaseProvider);
  final saveDefaults = ref.watch(saveDefaultTimerPresetsUseCaseProvider);
  final updatePreset = ref.watch(updateTimerPresetUseCaseProvider);

  // NOTA: Questo è un esempio. L'ID utente dovrebbe provenire da un provider di autenticazione.
  // final userId = ref.watch(authProvider).currentUser?.id ?? 'default_user_id_placeholder';

  return ExerciseTimerNotifier(getPresets, savePreset, deletePreset,
      saveDefaults, updatePreset, params.userId, params.initialDuration);
});
