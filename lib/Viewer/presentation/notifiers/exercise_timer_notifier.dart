import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alphanessone/Viewer/domain/entities/timer_preset.dart';
import 'package:alphanessone/Viewer/domain/repositories/timer_preset_repository.dart';
import 'package:alphanessone/Viewer/domain/usecases/get_timer_presets_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/save_timer_preset_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/delete_timer_preset_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/save_default_timer_presets_use_case.dart';
import 'package:alphanessone/Viewer/domain/usecases/update_timer_preset_use_case.dart';
import 'package:alphanessone/Viewer/viewer_providers.dart';

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
      selectedPreset: clearSelectedPreset
          ? null
          : selectedPreset ?? this.selectedPreset,
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
  final String _currentUserId;

  ExerciseTimerNotifier(
    this._getTimerPresetsUseCase,
    this._saveTimerPresetUseCase,
    this._deleteTimerPresetUseCase,
    this._saveDefaultTimerPresetsUseCase,
    this._updateTimerPresetUseCase,
    this._currentUserId,
    int initialDuration,
  ) : super(
        ExerciseTimerState(
          initialDuration: initialDuration,
          remainingDuration: initialDuration,
          status: TimerStatus.initial,
        ),
      ) {
    loadPresets();
  }

  Future<void> loadPresets() async {
    state = state.copyWith(isLoadingPresets: true, error: null);
    try {
      final presets = await _getTimerPresetsUseCase.call(_currentUserId);
      if (presets.isEmpty) {
        await _createDefaultPresets();
      } else {
        state = state.copyWith(presets: presets, isLoadingPresets: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoadingPresets: false);
    }
  }

  Future<void> _createDefaultPresets() async {
    final defaultPresets = [
      TimerPreset(id: '', userId: _currentUserId, label: '30 sec', seconds: 30),
      TimerPreset(id: '', userId: _currentUserId, label: '1 min', seconds: 60),
      TimerPreset(id: '', userId: _currentUserId, label: '90 sec', seconds: 90),
      TimerPreset(id: '', userId: _currentUserId, label: '2 min', seconds: 120),
      TimerPreset(id: '', userId: _currentUserId, label: '3 min', seconds: 180),
    ];
    try {
      await _saveDefaultTimerPresetsUseCase.call(
        SaveDefaultTimerPresetsParams(
          userId: _currentUserId,
          defaultPresets: defaultPresets,
        ),
      );
      final presets = await _getTimerPresetsUseCase.call(_currentUserId);
      state = state.copyWith(presets: presets, isLoadingPresets: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Errore nel creare preset di default: ${e.toString()}',
        isLoadingPresets: false,
      );
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
      clearSelectedPreset: true,
    );
  }

  void startTimer() {
    if (state.status == TimerStatus.running && state.remainingDuration == 0) {
      state = state.copyWith(
        remainingDuration: state.initialDuration,
        status: TimerStatus.initial,
      );
    }
    if (state.status != TimerStatus.running) {
      _timer?.cancel();
      state = state.copyWith(status: TimerStatus.running, error: null);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (state.remainingDuration > 0) {
          state = state.copyWith(
            remainingDuration: state.remainingDuration - 1,
          );
        } else {
          _timer?.cancel();
          state = state.copyWith(status: TimerStatus.finished);
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
      remainingDuration: state.initialDuration,
      status: TimerStatus.initial,
    );
  }

  Future<void> saveCurrentTimeAsPreset(String label) async {
    if (state.initialDuration <= 0 || label.trim().isEmpty) {
      state = state.copyWith(error: 'Durata o etichetta non valide');
      return;
    }

    state = state.copyWith(isLoadingPresets: true, error: null);
    try {
      final newPreset = TimerPreset(
        id: '',
        userId: _currentUserId,
        label: label.trim(),
        seconds: state.initialDuration,
      );
      await _saveTimerPresetUseCase.call(
        SaveTimerPresetParams(userId: _currentUserId, preset: newPreset),
      );
      await loadPresets();
    } catch (e) {
      state = state.copyWith(
        error: 'Errore nel salvare il preset: ${e.toString()}',
        isLoadingPresets: false,
      );
    }
  }

  Future<void> deleteSelectedPreset() async {
    if (state.selectedPreset == null) {
      state = state.copyWith(error: 'Nessun preset selezionato');
      return;
    }

    state = state.copyWith(isLoadingPresets: true, error: null);
    try {
      await _deleteTimerPresetUseCase.call(
        DeleteTimerPresetParams(
          userId: _currentUserId,
          presetId: state.selectedPreset!.id,
        ),
      );
      state = state.copyWith(clearSelectedPreset: true);
      await loadPresets();
    } catch (e) {
      state = state.copyWith(
        error: 'Errore nell\'eliminare il preset: ${e.toString()}',
        isLoadingPresets: false,
      );
    }
  }

  Future<void> updateSelectedPreset(String newLabel, int newSeconds) async {
    if (state.selectedPreset == null) {
      state = state.copyWith(
        error: "Nessun preset selezionato per l'aggiornamento",
      );
      return;
    }
    if (newLabel.trim().isEmpty || newSeconds <= 0) {
      state = state.copyWith(
        error: "Etichetta o durata non valide per l'aggiornamento",
      );
      return;
    }

    state = state.copyWith(isLoadingPresets: true, error: null);
    try {
      final updatedPreset = state.selectedPreset!.copyWith(
        label: newLabel.trim(),
        seconds: newSeconds,
      );
      await _updateTimerPresetUseCase.call(
        UpdateTimerPresetParams(userId: _currentUserId, preset: updatedPreset),
      );

      await loadPresets();
      final reloadedPresets = await _getTimerPresetsUseCase.call(
        _currentUserId,
      );
      final potentiallyUpdatedSelectedPreset = reloadedPresets.firstWhere(
        (p) => p.id == updatedPreset.id,
        orElse: () => state.selectedPreset!,
      );
      state = state.copyWith(
        selectedPreset: potentiallyUpdatedSelectedPreset,
        isLoadingPresets: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: "Errore nell'aggiornamento del preset: ${e.toString()}",
        isLoadingPresets: false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Implementazioni degli use case inline per evitare dipendenze circolari
class _GetTimerPresetsUseCaseImpl implements GetTimerPresetsUseCase {
  final TimerPresetRepository _repository;
  _GetTimerPresetsUseCaseImpl(this._repository);

  @override
  Future<List<TimerPreset>> call(String userId) async {
    return await _repository.getTimerPresets(userId);
  }
}

class _SaveTimerPresetUseCaseImpl implements SaveTimerPresetUseCase {
  final TimerPresetRepository _repository;
  _SaveTimerPresetUseCaseImpl(this._repository);

  @override
  Future<void> call(SaveTimerPresetParams params) async {
    if (params.preset.label.trim().isEmpty) {
      throw ArgumentError('Il nome del preset non può essere vuoto.');
    }
    if (params.preset.seconds <= 0) {
      throw ArgumentError(
        'I secondi del preset devono essere maggiori di zero.',
      );
    }
    await _repository.saveTimerPreset(params.userId, params.preset);
  }
}

class _DeleteTimerPresetUseCaseImpl implements DeleteTimerPresetUseCase {
  final TimerPresetRepository _repository;
  _DeleteTimerPresetUseCaseImpl(this._repository);

  @override
  Future<void> call(DeleteTimerPresetParams params) async {
    if (params.presetId.isEmpty) {
      throw ArgumentError('ID del TimerPreset mancante per l\'eliminazione.');
    }
    await _repository.deleteTimerPreset(params.userId, params.presetId);
  }
}

class _SaveDefaultTimerPresetsUseCaseImpl
    implements SaveDefaultTimerPresetsUseCase {
  final TimerPresetRepository _repository;
  _SaveDefaultTimerPresetsUseCaseImpl(this._repository);

  @override
  Future<void> call(SaveDefaultTimerPresetsParams params) async {
    if (params.defaultPresets.isEmpty) {
      return;
    }
    await _repository.saveDefaultTimerPresets(
      params.userId,
      params.defaultPresets,
    );
  }
}

class _UpdateTimerPresetUseCaseImpl implements UpdateTimerPresetUseCase {
  final TimerPresetRepository _repository;
  _UpdateTimerPresetUseCaseImpl(this._repository);

  @override
  Future<void> call(UpdateTimerPresetParams params) async {
    if (params.preset.id.isEmpty) {
      throw ArgumentError('ID del TimerPreset mancante per l\'aggiornamento.');
    }
    if (params.preset.label.trim().isEmpty) {
      throw ArgumentError('Il nome del preset non può essere vuoto.');
    }
    if (params.preset.seconds <= 0) {
      throw ArgumentError(
        'I secondi del preset devono essere maggiori di zero.',
      );
    }
    await _repository.updateTimerPreset(params.userId, params.preset);
  }
}

// Dummy use cases per gestire errori quando il repository non è disponibile
class _DummyGetTimerPresetsUseCase implements GetTimerPresetsUseCase {
  final String error;
  _DummyGetTimerPresetsUseCase(this.error);

  @override
  Future<List<TimerPreset>> call(String userId) async {
    throw Exception(error);
  }
}

class _DummySaveTimerPresetUseCase implements SaveTimerPresetUseCase {
  final String error;
  _DummySaveTimerPresetUseCase(this.error);

  @override
  Future<void> call(SaveTimerPresetParams params) async {
    throw Exception(error);
  }
}

class _DummyDeleteTimerPresetUseCase implements DeleteTimerPresetUseCase {
  final String error;
  _DummyDeleteTimerPresetUseCase(this.error);

  @override
  Future<void> call(DeleteTimerPresetParams params) async {
    throw Exception(error);
  }
}

class _DummySaveDefaultTimerPresetsUseCase
    implements SaveDefaultTimerPresetsUseCase {
  final String error;
  _DummySaveDefaultTimerPresetsUseCase(this.error);

  @override
  Future<void> call(SaveDefaultTimerPresetsParams params) async {
    throw Exception(error);
  }
}

class _DummyUpdateTimerPresetUseCase implements UpdateTimerPresetUseCase {
  final String error;
  _DummyUpdateTimerPresetUseCase(this.error);

  @override
  Future<void> call(UpdateTimerPresetParams params) async {
    throw Exception(error);
  }
}

/// Provider per ottenere l'ID utente corrente dall'autenticazione Firebase
final currentUserIdProvider = Provider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.uid ?? '';
});

/// Provider FutureProvider per ExerciseTimerNotifier che gestisce i FutureProvider degli use case
final exerciseTimerNotifierProvider = FutureProvider.family
    .autoDispose<ExerciseTimerNotifier, ({String userId, int initialDuration})>(
      (ref, params) async {
        // Ottieni gli use case dai FutureProvider
        final getPresets = await ref.watch(
          getTimerPresetsUseCaseProvider.future,
        );
        final savePreset = await ref.watch(
          saveTimerPresetUseCaseProvider.future,
        );
        final deletePreset = await ref.watch(
          deleteTimerPresetUseCaseProvider.future,
        );
        final saveDefaults = await ref.watch(
          saveDefaultTimerPresetsUseCaseProvider.future,
        );
        final updatePreset = await ref.watch(
          updateTimerPresetUseCaseProvider.future,
        );

        return ExerciseTimerNotifier(
          getPresets,
          savePreset,
          deletePreset,
          saveDefaults,
          updatePreset,
          params.userId,
          params.initialDuration,
        );
      },
    );

/// Provider StateNotifierProvider per gestire lo stato del timer in modo sincrono
final exerciseTimerStateProvider = StateNotifierProvider.family
    .autoDispose<
      ExerciseTimerNotifier,
      ExerciseTimerState,
      ({String userId, int initialDuration})
    >((ref, params) {
      // Usa il repository fallback sincrono
      final timerRepo = ref.watch(timerPresetRepositoryFallbackProvider);

      if (timerRepo == null) {
        // Se il repository non è disponibile, ritorna un notifier con stato di errore
        return _createErrorNotifier(
          params.initialDuration,
          'Repository timer non disponibile',
        );
      }

      // Crea gli use case con il repository disponibile
      final getPresets = _GetTimerPresetsUseCaseImpl(timerRepo);
      final savePreset = _SaveTimerPresetUseCaseImpl(timerRepo);
      final deletePreset = _DeleteTimerPresetUseCaseImpl(timerRepo);
      final saveDefaults = _SaveDefaultTimerPresetsUseCaseImpl(timerRepo);
      final updatePreset = _UpdateTimerPresetUseCaseImpl(timerRepo);

      return ExerciseTimerNotifier(
        getPresets,
        savePreset,
        deletePreset,
        saveDefaults,
        updatePreset,
        params.userId,
        params.initialDuration,
      );
    });

/// Helper per creare un notifier con stato di errore
ExerciseTimerNotifier _createErrorNotifier(int initialDuration, String error) {
  final dummyGetPresets = _DummyGetTimerPresetsUseCase(error);
  final dummySavePreset = _DummySaveTimerPresetUseCase(error);
  final dummyDeletePreset = _DummyDeleteTimerPresetUseCase(error);
  final dummySaveDefaults = _DummySaveDefaultTimerPresetsUseCase(error);
  final dummyUpdatePreset = _DummyUpdateTimerPresetUseCase(error);

  return ExerciseTimerNotifier(
    dummyGetPresets,
    dummySavePreset,
    dummyDeletePreset,
    dummySaveDefaults,
    dummyUpdatePreset,
    '',
    initialDuration,
  );
}
