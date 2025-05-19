import 'package:alphanessone/viewer/domain/entities/timer_preset.dart';
import 'package:alphanessone/viewer/domain/repositories/timer_preset_repository.dart';

// Parametri semplici, userId è una stringa

abstract class GetTimerPresetsUseCase {
  Future<List<TimerPreset>> call(String userId);
}

class GetTimerPresetsUseCaseImpl implements GetTimerPresetsUseCase {
  final TimerPresetRepository _repository;

  GetTimerPresetsUseCaseImpl(this._repository);

  @override
  Future<List<TimerPreset>> call(String userId) async {
    // Logica aggiuntiva potrebbe includere ordinamento specifico se non gestito dal repo,
    // o trasformazioni dei dati prima di passarli al layer di presentazione.
    return await _repository.getTimerPresets(userId);
  }
}
