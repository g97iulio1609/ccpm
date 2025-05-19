import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_notifications.dart';

class TimerManager {
  final void Function(int) onTick;
  final void Function() onComplete;
  Timer? _timer;
  final AnimationController animationController;
  int _remainingSeconds = 0;
  final String exerciseName;

  TimerManager({
    required this.onTick,
    required this.onComplete,
    required this.animationController,
    required this.exerciseName,
  });

  void startTimer(int totalSeconds, bool isEmom) {
    _remainingSeconds = totalSeconds;
    _timer?.cancel();
    animationController.duration = Duration(seconds: totalSeconds);
    animationController.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      onTick(_remainingSeconds);
      if (_remainingSeconds <= 0) {
        if (isEmom) {
          _remainingSeconds = totalSeconds;
          animationController.forward(from: 0.0);
          _showTimerCompleteNotification(isEmom: true);
        } else {
          stopTimer();
          onComplete();
          _showTimerCompleteNotification(isEmom: false);
        }
      }
    });
  }

  Future<void> _showTimerCompleteNotification({required bool isEmom}) async {
    final title = isEmom ? 'EMOM - Nuovo Round' : 'Timer Completato';
    final body = isEmom
        ? 'È ora di iniziare il prossimo round di $exerciseName!'
        : 'Il recupero per $exerciseName è terminato!';

    await showTimerNotification(
      title: title,
      body: body,
      notificationId: exerciseName.hashCode,
    );
  }

  void stopTimer() {
    _timer?.cancel();
    animationController.stop();
  }

  void dispose() {
    _timer?.cancel();
    animationController.dispose();
  }
}
