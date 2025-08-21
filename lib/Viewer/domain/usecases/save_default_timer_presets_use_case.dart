import 'package:alphanessone/Viewer/domain/entities/timer_preset.dart';
import 'package:alphanessone/Viewer/domain/repositories/timer_preset_repository.dart';

class SaveDefaultTimerPresetsParams {
  final String userId;
  final List<TimerPreset> defaultPresets;

  SaveDefaultTimerPresetsParams({required this.userId, required this.defaultPresets});
}

abstract class SaveDefaultTimerPresetsUseCase {
  Future<void> call(SaveDefaultTimerPresetsParams params);
}

class SaveDefaultTimerPresetsUseCaseImpl implements SaveDefaultTimerPresetsUseCase {
  final TimerPresetRepository _repository;

  SaveDefaultTimerPresetsUseCaseImpl(this._repository);

  @override
  Future<void> call(SaveDefaultTimerPresetsParams params) async {
    if (params.defaultPresets.isEmpty) {
      // Non fare nulla se la lista dei preset di default è vuota
      return;
    }
    // Ulteriori validazioni sui singoli preset potrebbero essere aggiunte qui se necessario
    await _repository.saveDefaultTimerPresets(params.userId, params.defaultPresets);
  }
}
