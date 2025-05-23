import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'timer_display.dart';
import 'timer_controls.dart';

class TimerDemo extends StatefulWidget {
  const TimerDemo({super.key});

  @override
  State<TimerDemo> createState() => _TimerDemoState();
}

class _TimerDemoState extends State<TimerDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  int _timerMinutes = 1;
  int _timerSeconds = 30;
  int _remainingSeconds = 90;
  int _totalSeconds = 90;
  bool _isTimerRunning = false;
  bool _isEmomMode = false;

  List<Map<String, dynamic>> _presets = [
    {'id': '1', 'label': 'Breve', 'seconds': 30},
    {'id': '2', 'label': 'Standard', 'seconds': 60},
    {'id': '3', 'label': 'Medio', 'seconds': 120},
    {'id': '4', 'label': 'Lungo', 'seconds': 180},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );
    _animation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    final totalSeconds = (_timerMinutes * 60) + _timerSeconds;
    setState(() {
      _isTimerRunning = true;
      _remainingSeconds = totalSeconds;
      _totalSeconds = totalSeconds;
    });

    _animationController.duration = Duration(seconds: totalSeconds);
    _animationController.forward(from: 0.0);
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
    });
    _animationController.stop();
    _animationController.reset();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return remainingSeconds > 0
          ? '${minutes}m ${remainingSeconds}s'
          : '${minutes}m';
    }
    return '${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Timer Modernizzato',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Container(
                  padding: EdgeInsets.all(AppTheme.spacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer.withAlpha(30),
                        colorScheme.primaryContainer.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radii.xl),
                    border: Border.all(
                      color: colorScheme.outline.withAlpha(30),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer_rounded,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      SizedBox(height: AppTheme.spacing.md),
                      Text(
                        'Timer di Recupero',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacing.xs),
                      Text(
                        'Design moderno e fluido con animazioni migliorate',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppTheme.spacing.xl),

                // Timer Display
                if (_isTimerRunning)
                  TimerDisplay(
                    animation: _animation,
                    remainingSeconds: _remainingSeconds,
                    totalSeconds: _totalSeconds,
                    isEmomMode: _isEmomMode,
                  )
                else
                  // Timer Controls
                  TimerControls(
                    timerMinutes: _timerMinutes,
                    timerSeconds: _timerSeconds,
                    onMinutesChanged: (value) =>
                        setState(() => _timerMinutes = value),
                    onSecondsChanged: (value) =>
                        setState(() => _timerSeconds = value),
                    onStartTimer: _startTimer,
                    presets: _presets,
                    onPresetSelected: (preset) {
                      final seconds = preset['seconds'] as int;
                      setState(() {
                        _timerMinutes = seconds ~/ 60;
                        _timerSeconds = seconds % 60;
                      });
                    },
                    onAddPresetPressed: () {
                      // Demo: aggiunge un preset casuale
                      final newPreset = {
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'label': 'Custom',
                        'seconds': 90,
                      };
                      setState(() {
                        _presets.add(newPreset);
                      });
                    },
                    onEditPresetPressed: (preset) {
                      // Demo: modifica preset
                      print('Modifica preset: ${preset['label']}');
                    },
                    onDeletePresetPressed: (presetId) {
                      setState(() {
                        _presets.removeWhere((p) => p['id'] == presetId);
                      });
                    },
                    formatDuration: _formatDuration,
                  ),

                if (_isTimerRunning) ...[
                  SizedBox(height: AppTheme.spacing.xl),

                  // Control buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _stopTimer,
                          icon: Icon(Icons.stop_rounded),
                          label: Text('FERMA'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: AppTheme.spacing.lg),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radii.lg),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEmomMode = !_isEmomMode;
                            });
                          },
                          icon: Icon(_isEmomMode
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded),
                          label: Text(_isEmomMode ? 'NORMALE' : 'EMOM'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEmomMode
                                ? AppTheme.primaryGold
                                : colorScheme.secondary,
                            foregroundColor: _isEmomMode
                                ? Colors.black
                                : colorScheme.onSecondary,
                            padding: EdgeInsets.symmetric(
                                vertical: AppTheme.spacing.lg),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radii.lg),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
