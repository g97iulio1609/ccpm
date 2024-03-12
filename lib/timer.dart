import 'dart:async';
import 'package:flutter/material.dart';

class TimerPage extends StatefulWidget {
  final int currentSeriesIndex;
  final int totalSeries;
  final int restTime;

  const TimerPage({
    Key? key,
    required this.currentSeriesIndex,
    required this.totalSeries,
    required this.restTime,
  }) : super(key: key);

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late Timer _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.restTime;
    startTimer();
  }

  void startTimer() {
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
    Navigator.pop(context, true); // true indica che si desidera passare alla prossima serie
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'REST TIME',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              Duration(seconds: _remainingSeconds).toString().split('.').first.padLeft(8, '0'),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleNextSeries,
              child: const Text('SKIP'),
            ),
          ],
        ),
      ),
    );
  }
}
