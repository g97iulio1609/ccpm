import 'dart:async';
import 'package:flutter/material.dart';

class TimerPage extends StatefulWidget {
  final int currentSeriesIndex;
  final int totalSeries;
  final int restTime;
  final bool isEmomMode;

  const TimerPage({
    Key? key,
    required this.currentSeriesIndex,
    required this.totalSeries,
    required this.restTime,
    required this.isEmomMode,
  }) : super(key: key);

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.restTime;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.restTime),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
    _startTimer();
  }

  void _startTimer() {
    _controller.forward(from: 0.0);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _handleNextSeries();
      }
    });
  }

  void _handleNextSeries() {
    _timer.cancel();
    if (widget.isEmomMode) {
      _remainingSeconds = widget.restTime;
      _startTimer();
    } else {
      Navigator.pop(context, true);
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isEmomMode ? 'EMOM MODE' : 'REST TIME',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Stack(
                alignment: Alignment.center,
                children: [
                  _buildProgressIndicator(theme),
                  _buildCountdownText(theme),
                ],
              ),
              const SizedBox(height: 24), // Ridotto spazio tra il timer e il pulsante SKIP
              if (!widget.isEmomMode) _buildSkipButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return SizedBox(
      width: 240,
      height: 240,
      child: CircularProgressIndicator(
        value: _animation.value,
        strokeWidth: 12,
        backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildCountdownText(ThemeData theme) {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      style: theme.textTheme.displayLarge?.copyWith(
        color: theme.colorScheme.onPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSkipButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _handleNextSeries,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.onPrimary,
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        'SKIP',
        style: theme.textTheme.headlineMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
