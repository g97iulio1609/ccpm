import 'package:alphanessone/Viewer/domain/entities/timer_preset.dart';
import 'package:alphanessone/Viewer/domain/repositories/timer_preset_repository.dart';

class SaveTimerPresetParams {
  final String userId;
  final TimerPreset
  preset; // L'ID potrebbe essere vuoto se è una nuova creazione

  SaveTimerPresetParams({required this.userId, required this.preset});
}

abstract class SaveTimerPresetUseCase {
  Future<void> call(SaveTimerPresetParams params);
}

class SaveTimerPresetUseCaseImpl implements SaveTimerPresetUseCase {
  final TimerPresetRepository _repository;

  SaveTimerPresetUseCaseImpl(this._repository);

  @override
  Future<void> call(SaveTimerPresetParams params) async {
    // Validazioni: es. label non vuota, seconds > 0
    if (params.preset.label.trim().isEmpty) {
      throw ArgumentError('Il nome del preset non può essere vuoto.');
    }
    if (params.preset.seconds <= 0) {
      throw ArgumentError(
        'I secondi del preset devono essere maggiori di zero.',
      );
    }
    // Potrebbe esserci logica per prevenire duplicati di label o secondi,
    // ma il repository già gestisce la deduplicazione per 'seconds' nella cache.
    await _repository.saveTimerPreset(params.userId, params.preset);
  }
}
