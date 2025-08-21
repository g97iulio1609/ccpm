import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_notifications.dart';
import 'package:flutter/scheduler.dart';

class TimerManager {
  final void Function(int) onTick;
  final void Function() onComplete;
  Timer? _timer;
  Ticker? _ticker;
  final AnimationController animationController;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  final String exerciseName;

  TimerManager({
    required this.onTick,
    required this.onComplete,
    required this.animationController,
    required this.exerciseName,
  });

  void startTimer(int totalSeconds, bool isEmom) {
    _remainingSeconds = totalSeconds;
    _totalSeconds = totalSeconds;

    // Cancella timer precedenti
    _timer?.cancel();
    _ticker?.dispose();

    // Configura e avvia l'animazione
    animationController.duration = Duration(seconds: totalSeconds);
    animationController.forward(from: 0.0);

    // Usa Ticker per aggiornamenti fluidi sincronizzati con il refresh rate
    _ticker = Ticker((elapsed) {
      final elapsedSeconds = elapsed.inSeconds;
      final newRemainingSeconds = _totalSeconds - elapsedSeconds;

      if (newRemainingSeconds != _remainingSeconds) {
        _remainingSeconds = newRemainingSeconds;
        onTick(_remainingSeconds);
      }

      if (_remainingSeconds <= 0) {
        _ticker?.dispose();

        if (isEmom) {
          // Reset per EMOM
          _remainingSeconds = totalSeconds;
          animationController.forward(from: 0.0);
          _showTimerCompleteNotification(isEmom: true);

          // Riavvia il ticker per EMOM
          _ticker = Ticker((elapsed) {
            final elapsedSeconds = elapsed.inSeconds;
            final newRemainingSeconds = _totalSeconds - elapsedSeconds;

            if (newRemainingSeconds != _remainingSeconds) {
              _remainingSeconds = newRemainingSeconds;
              onTick(_remainingSeconds);
            }

            if (_remainingSeconds <= 0) {
              // Ricorsivo per EMOM infinito
              startTimer(totalSeconds, isEmom);
            }
          });
          _ticker?.start();
        } else {
          stopTimer();
          onComplete();
          _showTimerCompleteNotification(isEmom: false);
        }
      }
    });

    _ticker?.start();
  }

  Future<void> _showTimerCompleteNotification({required bool isEmom}) async {
    final title = isEmom ? 'EMOM - Nuovo Round' : 'Timer Completato';
    final body = isEmom
        ? 'È ora di iniziare il prossimo round di $exerciseName!'
        : 'Il recupero per $exerciseName è terminato!';

    await showTimerNotification(title: title, body: body, notificationId: exerciseName.hashCode);
  }

  void stopTimer() {
    _timer?.cancel();
    _ticker?.dispose();
    animationController.stop();
  }

  void dispose() {
    _timer?.cancel();
    _ticker?.dispose();
    animationController.dispose();
  }
}
