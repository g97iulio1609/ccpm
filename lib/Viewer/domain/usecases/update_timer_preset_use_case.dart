import 'package:alphanessone/Viewer/domain/entities/timer_preset.dart';
import 'package:alphanessone/Viewer/domain/repositories/timer_preset_repository.dart';

class UpdateTimerPresetParams {
  final String userId;
  final TimerPreset preset; // L'ID DEVE essere presente per un aggiornamento

  UpdateTimerPresetParams({required this.userId, required this.preset});
}

abstract class UpdateTimerPresetUseCase {
  Future<void> call(UpdateTimerPresetParams params);
}

class UpdateTimerPresetUseCaseImpl implements UpdateTimerPresetUseCase {
  final TimerPresetRepository _repository;

  UpdateTimerPresetUseCaseImpl(this._repository);

  @override
  Future<void> call(UpdateTimerPresetParams params) async {
    if (params.preset.id.isEmpty) {
      throw ArgumentError('ID del TimerPreset mancante per l\'aggiornamento.');
    }
    if (params.preset.label.trim().isEmpty) {
      throw ArgumentError('Il nome del preset non può essere vuoto.');
    }
    if (params.preset.seconds <= 0) {
      throw ArgumentError('I secondi del preset devono essere maggiori di zero.');
    }
    await _repository.updateTimerPreset(params.userId, params.preset);
  }
}
