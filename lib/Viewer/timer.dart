import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'timer_model.dart';
import 'timer_provider.dart';

class TimerPage extends ConsumerStatefulWidget {
  final TimerModel timerModel;

  const TimerPage({
    super.key,
    required this.timerModel,
  });

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timerModelProvider.notifier).state = widget.timerModel;
      ref.read(remainingSecondsProvider.notifier).state = widget.timerModel.restTime;
      _controller = AnimationController(
        vsync: this,
        duration: Duration(seconds: widget.timerModel.restTime),
      );
      _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
      _startTimer();
    });
  }

  void _startTimer() {
    _controller.forward(from: 0.0);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remainingSeconds = ref.read(remainingSecondsProvider);
      if (remainingSeconds > 0) {
        ref.read(remainingSecondsProvider.notifier).state--;
      } else {
        _handleNextSeries();
      }
    });
  }

  void _handleNextSeries() {
    _timer.cancel();
    final timerModel = ref.read(timerModelProvider)!;
    if (timerModel.isEmomMode) {
      ref.read(remainingSecondsProvider.notifier).state = timerModel.restTime;
      _startTimer();
    } else {
      ref.read(timerServiceProvider).showNotification('Rest Time Completed', 'Your rest time has ended.');
      if (timerModel.currentSeriesIndex < timerModel.seriesList.length - 1) {
        final result = <String, dynamic>{
          'startIndex': timerModel.currentSeriesIndex + 1,
          'superSetExerciseIndex': timerModel.superSetExerciseIndex,
          'seriesList': timerModel.seriesList,
        };
        context.pop(result);
      } else {
        final workoutDetailsUrl =
            '/programs_screen/user_programs/${timerModel.userId}/training_viewer/${timerModel.programId}/week_details/${timerModel.weekId}/workout_details/${timerModel.workoutId}';
        context.go(workoutDetailsUrl);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerModel = ref.watch(timerModelProvider)!;
    final remainingSeconds = ref.watch(remainingSecondsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timerModel.isEmomMode ? 'EMOM MODE' : 'REST TIME',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.center,
                children: [
                  _buildProgressIndicator(),
                  _buildCountdownText(remainingSeconds),
                ],
              ),
              const SizedBox(height: 24),
              if (!timerModel.isEmomMode) _buildSkipButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 300,
      height: 300,
      child: CircularProgressIndicator(
        value: _animation.value,
        strokeWidth: 12,
        backgroundColor: Colors.white.withOpacity(0.2),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildCountdownText(int remainingSeconds) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    final shadow = Shadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 5),
    );
    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        color: Colors.white,
        fontSize: 72,
        fontWeight: FontWeight.bold,
        shadows: [shadow],
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _handleNextSeries,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      child: const Text(
        'SKIP',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
