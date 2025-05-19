import 'package:alphanessone/viewer/domain/repositories/timer_preset_repository.dart';

class DeleteTimerPresetParams {
  final String userId;
  final String presetId;

  DeleteTimerPresetParams({required this.userId, required this.presetId});
}

abstract class DeleteTimerPresetUseCase {
  Future<void> call(DeleteTimerPresetParams params);
}

class DeleteTimerPresetUseCaseImpl implements DeleteTimerPresetUseCase {
  final TimerPresetRepository _repository;

  DeleteTimerPresetUseCaseImpl(this._repository);

  @override
  Future<void> call(DeleteTimerPresetParams params) async {
    if (params.presetId.isEmpty) {
      throw ArgumentError('ID del TimerPreset mancante per l\'eliminazione.');
    }
    await _repository.deleteTimerPreset(params.userId, params.presetId);
  }
}
