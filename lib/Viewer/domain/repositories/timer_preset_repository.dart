import 'package:alphanessone/viewer/domain/entities/timer_preset.dart';

abstract class TimerPresetRepository {
  Future<List<TimerPreset>> getTimerPresets(String userId);
  Future<void> saveTimerPreset(String userId, TimerPreset preset);
  Future<void> updateTimerPreset(String userId, TimerPreset preset);
  Future<void> deleteTimerPreset(String userId, String presetId);
  Future<void> saveDefaultTimerPresets(
      String userId, List<TimerPreset> defaultPresets);
}
