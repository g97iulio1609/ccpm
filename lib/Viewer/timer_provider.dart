import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'timer_model.dart';
import 'timer_services.dart';

final timerModelProvider = StateProvider<TimerModel?>((ref) => null);
final remainingSecondsProvider = StateProvider<int>((ref) => 0);
final timerServiceProvider = Provider<TimerService>((ref) => TimerService());
