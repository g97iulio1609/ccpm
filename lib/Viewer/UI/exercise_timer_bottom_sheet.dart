import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:alphanessone/Viewer/UI/workout_provider.dart'
    as workout_provider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:alphanessone/Main/app_notifications.dart';

// Componenti estratti
import 'timer_constants.dart';
import 'timer_manager.dart';
import 'custom_input_field.dart';
import 'timer_display.dart';
import 'timer_controls.dart';
import 'preset_manager.dart';
import 'mini_timer.dart';

// Costanti per il layout
class TimerConstants {
  static const defaultPresets = [
    {'label': '30s', 'seconds': 30},
    {'label': '1m', 'seconds': 60},
    {'label': '2m', 'seconds': 120},
    {'label': '3m', 'seconds': 180},
  ];
  static const timerDisplaySize = 300.0;
  static const progressStrokeWidth = 8.0;
  static const numberPickerItemHeight = 42.0;
}

// Classe per gestire la logica del timer
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

// Widget per il campo di input personalizzato
class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 100,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))
        ],
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.sm,
            vertical: AppTheme.spacing.sm,
          ),
          alignLabelWithHint: true,
          floatingLabelAlignment: FloatingLabelAlignment.center,
        ),
      ),
    );
  }
}

class ExerciseTimer extends ConsumerStatefulWidget {
  final String userId;
  final String programId;
  final String weekId;
  final String workoutId;
  final String exerciseId;
  final List<Map<String, dynamic>> superSetExercises;
  final int superSetExerciseIndex;
  final List<Map<String, dynamic>> seriesList;
  final int startIndex;

  const ExerciseTimer({
    super.key,
    required this.userId,
    required this.programId,
    required this.weekId,
    required this.workoutId,
    required this.exerciseId,
    required this.superSetExercises,
    required this.superSetExerciseIndex,
    required this.seriesList,
    required this.startIndex,
  });

  @override
  ConsumerState<ExerciseTimer> createState() => _ExerciseTimerState();
}

class _ExerciseTimerState extends ConsumerState<ExerciseTimer>
    with SingleTickerProviderStateMixin {
  late final TimerManager _timerManager;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late final PresetManager _presetManager;

  final Map<String, Map<String, TextEditingController>> _repsControllers = {};
  final Map<String, Map<String, TextEditingController>> _weightControllers = {};

  bool _isTimerMode = false;
  bool _isEmomMode = false;
  bool _isCompactMode = false;
  int _currentSeriesIndex = 0;
  int _currentSuperSetExerciseIndex = 0;
  int _timerMinutes = 1;
  int _timerSeconds = 0;
  int _remainingSeconds = 0;
  int _totalSeconds = 60; // Inizializzato a 60 secondi di default
  List<Map<String, dynamic>> _presets = TimerConstants.defaultPresets;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    _initializeControllers();
    _initializeIndices();
    _initializeAnimation();
    _initializePresetManager();

    _timerManager = TimerManager(
      onTick: _onTimerTick,
      onComplete: _onTimerComplete,
      animationController: _animationController,
      exerciseName: widget.superSetExercises[_currentSuperSetExerciseIndex]
          ['name'] as String,
    );
  }

  void _initializePresetManager() {
    _presetManager = PresetManager(
      userId: widget.userId,
      onPresetsUpdated: (presets) {
        setState(() => _presets = presets);
      },
    );
    _presetManager.loadUserPresets();
  }

  void _initializeControllers() {
    for (final exercise in widget.superSetExercises) {
      final exerciseId = exercise['id'] as String;
      _repsControllers[exerciseId] = {};
      _weightControllers[exerciseId] = {};

      for (final series in exercise['series']) {
        final seriesId = series['id'] as String;
        _repsControllers[exerciseId]![seriesId] = TextEditingController(
          text: series['reps'].toString(),
        );
        _weightControllers[exerciseId]![seriesId] = TextEditingController(
          text: series['weight'].toString(),
        );
      }
    }
  }

  void _initializeIndices() {
    _currentSuperSetExerciseIndex = widget.superSetExerciseIndex;
    final currentExercise =
        widget.superSetExercises[_currentSuperSetExerciseIndex];
    final seriesCount = (currentExercise['series'] as List).length;
    _currentSeriesIndex =
        widget.startIndex < seriesCount ? widget.startIndex : seriesCount - 1;
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: (_timerMinutes * 60) + _timerSeconds),
    );
    _animation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);
  }

  void _onTimerTick(int remainingSeconds) {
    setState(() {
      _remainingSeconds = remainingSeconds;
    });

    // Feedback aptico negli ultimi 5 secondi
    if (remainingSeconds <= 5 && remainingSeconds > 0) {
      HapticFeedback.lightImpact();
    }
  }

  void _onTimerComplete() {
    // Feedback aptico più forte quando il timer è completato
    HapticFeedback.mediumImpact();

    if (_isEmomMode) {
      _resetEmomTimer();
    } else {
      _moveToNextSeries();
    }
  }

  void _resetEmomTimer() {
    final totalSeconds = (_timerMinutes * 60) + _timerSeconds;
    setState(() {
      _remainingSeconds = totalSeconds;
    });
  }

  Future<void> _moveToNextSeries() async {
    final currentExercise =
        widget.superSetExercises[_currentSuperSetExerciseIndex];
    await _updateSeriesData(currentExercise);

    if (_isEmomMode) {
      _resetEmomTimer();
      return;
    }

    setState(() {
      if (_currentSuperSetExerciseIndex < widget.superSetExercises.length - 1) {
        _currentSuperSetExerciseIndex++;
      } else if (_currentSeriesIndex < widget.seriesList.length - 1) {
        _currentSeriesIndex++;
        _currentSuperSetExerciseIndex = 0;
      } else {
        if (_isCompactMode) {
          _isCompactMode = false;
        }
        Navigator.of(context).pop();
      }

      if (!_isCompactMode) {
        _isTimerMode = false;
      }
    });

    // Feedback aptico quando si passa alla serie successiva
    HapticFeedback.selectionClick();
  }

  void _toggleCompactMode() {
    if (!_isTimerMode) return;

    setState(() {
      _isCompactMode = !_isCompactMode;
    });

    // Fornisci feedback aptico
    HapticFeedback.mediumImpact();

    // Chiudi il bottom sheet se stiamo entrando in modalità compatta
    if (_isCompactMode) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateSeriesData(Map<String, dynamic> exercise) async {
    final series = exercise['series'][_currentSeriesIndex];
    final seriesId = series['id'] as String;
    final repsController = _repsControllers[exercise['id']]![seriesId]!;
    final weightController = _weightControllers[exercise['id']]![seriesId]!;

    await ref.read(workout_provider.workoutServiceProvider).updateSeriesData(
      exercise['id'] as String,
      {
        ...series,
        'reps_done': int.tryParse(repsController.text) ?? 0,
        'weight_done': double.tryParse(weightController.text) ?? 0.0,
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getNextSeriesWeight() {
    if (_currentSuperSetExerciseIndex < widget.superSetExercises.length - 1) {
      // Se c'è un altro esercizio nel superset
      final nextExercise =
          widget.superSetExercises[_currentSuperSetExerciseIndex + 1];
      final nextSeries = nextExercise['series'][_currentSeriesIndex];
      return nextSeries['weight'].toString();
    } else if (_currentSeriesIndex < widget.seriesList.length - 1) {
      // Se c'è una serie successiva
      final currentExercise = widget.superSetExercises[0];
      final currentSeries = currentExercise['series'][_currentSeriesIndex];
      final nextSeries = currentExercise['series'][_currentSeriesIndex + 1];

      // Confronta il peso attuale con quello successivo
      if (currentSeries['weight'] != nextSeries['weight']) {
        return nextSeries['weight'].toString();
      }
    }
    return '';
  }

  Widget _buildNextSeriesButton(ThemeData theme, ColorScheme colorScheme) {
    final nextWeight = _getNextSeriesWeight();
    final buttonText = nextWeight.isNotEmpty
        ? 'SERIE SUCCESSIVA (${nextWeight}kg)'
        : 'SERIE SUCCESSIVA';

    return ElevatedButton(
      onPressed: () {
        _timerManager.stopTimer();
        _moveToNextSeries();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        ),
        elevation: 6,
        shadowColor: AppTheme.primaryGold.withAlpha(50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            buttonText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: AppTheme.spacing.xs),
          Icon(
            Icons.arrow_forward_rounded,
            size: 20,
            color: Colors.black,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timerManager.dispose();
    for (final controllers in _repsControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    for (final controllers in _weightControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentExercise =
        widget.superSetExercises[_currentSuperSetExerciseIndex];

    // Se siamo in modalità compatta, mostriamo solo il mini-timer flottante
    if (_isCompactMode) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            GestureDetector(
              onTap: () {}, // Impedisce che i tap passino attraverso
              child: Container(color: Colors.transparent),
            ),
            MiniTimer(
              remainingSeconds: _remainingSeconds,
              isEmomMode: _isEmomMode,
              onExpand: _toggleCompactMode,
              onCancel: () {
                _timerManager.stopTimer();
                setState(() {
                  _isCompactMode = false;
                  _isTimerMode = false;
                });
              },
              onNext: () {
                _timerManager.stopTimer();
                _moveToNextSeries();
              },
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Sfondo scuro cliccabile per chiudere
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.black54),
          ),
          // Bottom sheet trascinabile
          DraggableScrollableSheet(
            initialChildSize: 0.95,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            snap: true,
            snapSizes: const [0.5, 0.95],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    // Drag Handle con area di tocco più ampia
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        if (details.primaryDelta! > 0) {
                          // Trascinamento verso il basso
                          scrollController.jumpTo(
                              scrollController.offset + details.primaryDelta!);
                          if (scrollController.offset >=
                              scrollController.position.maxScrollExtent) {
                            Navigator.of(context).pop();
                          }
                        } else {
                          // Trascinamento verso l'alto
                          scrollController.jumpTo(
                              scrollController.offset + details.primaryDelta!);
                        }
                      },
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity! > 0 &&
                            scrollController.offset == 0) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding:
                            EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.outline.withAlpha(77),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Contenuto scrollabile
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const ClampingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Column(
                                children: [
                                  Text(
                                    currentExercise['name'] as String,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Serie ${_currentSeriesIndex + 1}/${widget.seriesList.length}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Timer or Input Fields with Swipe Gesture
                              GestureDetector(
                                onVerticalDragEnd: (details) {
                                  // Swipe up: passa dalla modalità input a timer
                                  if (details.primaryVelocity! < -500 &&
                                      !_isTimerMode) {
                                    HapticFeedback.mediumImpact();
                                    final totalSeconds =
                                        (_timerMinutes * 60) + _timerSeconds;
                                    if (totalSeconds > 0) {
                                      setState(() {
                                        _isTimerMode = true;
                                        _remainingSeconds = totalSeconds;
                                        _totalSeconds = totalSeconds;
                                      });
                                      _timerManager.startTimer(
                                          totalSeconds, _isEmomMode);
                                    }
                                  }
                                  // Swipe down: passa dalla modalità timer a input
                                  else if (details.primaryVelocity! > 500 &&
                                      _isTimerMode) {
                                    HapticFeedback.mediumImpact();
                                    _timerManager.stopTimer();
                                    setState(() => _isTimerMode = false);
                                  }
                                },
                                child: Column(
                                  children: [
                                    // Indicatore di swipe solo in modalità input
                                    if (!_isTimerMode)
                                      Container(
                                        width: 40,
                                        height: 4,
                                        margin: EdgeInsets.only(
                                            bottom: AppTheme.spacing.md),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryGold
                                              .withAlpha(150),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),

                                    // Contenuto effettivo (timer o input fields)
                                    if (_isTimerMode)
                                      Column(
                                        children: [
                                          // Pulsante per passare alla modalità compatta
                                          GestureDetector(
                                            onTap: _toggleCompactMode,
                                            child: Container(
                                              margin: EdgeInsets.only(
                                                  bottom: AppTheme.spacing.sm),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: AppTheme.spacing.sm,
                                                vertical: AppTheme.spacing.xxs,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTheme.radii.md),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.open_in_new,
                                                    size: 14,
                                                    color: Colors.white
                                                        .withAlpha(200),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Modalità compatta',
                                                    style: TextStyle(
                                                      color: Colors.white
                                                          .withAlpha(200),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          TimerDisplay(
                                            animation: _animation,
                                            remainingSeconds: _remainingSeconds,
                                            totalSeconds: _totalSeconds,
                                            isEmomMode: _isEmomMode,
                                          ),
                                        ],
                                      )
                                    else
                                      Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacing.md,
                                              vertical: AppTheme.spacing.md,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppTheme.radii.lg),
                                                border: Border.all(
                                                  color: colorScheme.outline
                                                      .withAlpha(40),
                                                ),
                                              ),
                                              padding: EdgeInsets.all(
                                                  AppTheme.spacing.md),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'Inserisci i valori per questa serie',
                                                    style: theme
                                                        .textTheme.titleSmall
                                                        ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          AppTheme.spacing.md),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      CustomInputField(
                                                        controller: _repsControllers[
                                                                currentExercise[
                                                                    'id']]![
                                                            currentExercise[
                                                                        'series']
                                                                    [
                                                                    _currentSeriesIndex]
                                                                ['id']]!,
                                                        label: 'REPS',
                                                        hint: '0',
                                                        icon: Icons.repeat,
                                                      ),
                                                      SizedBox(
                                                          width: AppTheme
                                                              .spacing.md),
                                                      CustomInputField(
                                                        controller: _weightControllers[
                                                                currentExercise[
                                                                    'id']]![
                                                            currentExercise[
                                                                        'series']
                                                                    [
                                                                    _currentSeriesIndex]
                                                                ['id']]!,
                                                        label: 'PESO (kg)',
                                                        hint: '0',
                                                        icon: Icons
                                                            .fitness_center,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                horizontal:
                                                    AppTheme.spacing.md),
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme.radii.md),
                                            ),
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.loop,
                                                color: _isEmomMode
                                                    ? AppTheme.primaryGold
                                                    : Colors.white
                                                        .withAlpha(100),
                                              ),
                                              title: Text(
                                                'Modalità EMOM',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              subtitle: _isEmomMode
                                                  ? Text(
                                                      'Il timer si resetta automaticamente',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withAlpha(150),
                                                        fontSize: 12,
                                                      ),
                                                    )
                                                  : null,
                                              trailing: Switch(
                                                value: _isEmomMode,
                                                onChanged: (value) {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  setState(() =>
                                                      _isEmomMode = value);
                                                },
                                                activeColor:
                                                    AppTheme.primaryGold,
                                                activeTrackColor: AppTheme
                                                    .primaryGold
                                                    .withAlpha(50),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                    // Indicatore di swipe in modalità timer
                                    if (_isTimerMode)
                                      Container(
                                        width: 40,
                                        height: 4,
                                        margin: EdgeInsets.only(
                                            top: AppTheme.spacing.md),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(100),
                                          borderRadius:
                                              BorderRadius.circular(2),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Bottom Actions
                              if (_isTimerMode)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _timerManager.stopTimer();
                                          setState(() => _isTimerMode = false);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.error,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              vertical: AppTheme.spacing.lg),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radii.lg),
                                          ),
                                          elevation: 6,
                                          shadowColor:
                                              AppTheme.error.withAlpha(50),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.cancel_outlined,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                            SizedBox(
                                                width: AppTheme.spacing.xs),
                                            const Text('ANNULLA'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: AppTheme.spacing.md),
                                    Expanded(
                                      child: _buildNextSeriesButton(
                                          theme, colorScheme),
                                    ),
                                  ],
                                )
                              else
                                TimerControls(
                                  timerMinutes: _timerMinutes,
                                  timerSeconds: _timerSeconds,
                                  onMinutesChanged: (value) =>
                                      setState(() => _timerMinutes = value),
                                  onSecondsChanged: (value) =>
                                      setState(() => _timerSeconds = value),
                                  onStartTimer: () {
                                    // Feedback aptico quando si avvia il timer
                                    HapticFeedback.mediumImpact();

                                    final totalSeconds =
                                        (_timerMinutes * 60) + _timerSeconds;
                                    setState(() {
                                      _isTimerMode = true;
                                      _remainingSeconds = totalSeconds;
                                      _totalSeconds = totalSeconds;
                                    });
                                    _timerManager.startTimer(
                                        totalSeconds, _isEmomMode);
                                  },
                                  presets: _presets,
                                  onPresetSelected: (preset) {
                                    // Feedback aptico leggero quando si seleziona un preset
                                    HapticFeedback.selectionClick();

                                    setState(() {
                                      final seconds = preset['seconds'] as int;
                                      _timerMinutes = seconds ~/ 60;
                                      _timerSeconds = seconds % 60;
                                    });
                                  },
                                  onAddPresetPressed: _showAddPresetDialog,
                                  onEditPresetPressed: _showEditPresetDialog,
                                  onDeletePresetPressed:
                                      _presetManager.deletePreset,
                                  formatDuration: _presetManager.formatDuration,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddPresetDialog() {
    final minutesController = TextEditingController();
    final secondsController = TextEditingController();
    final labelController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aggiungi Preset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Nome preset',
                  hintText: 'es. Recupero breve',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minuti',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Secondi',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                final minutes = int.tryParse(minutesController.text) ?? 0;
                final seconds = int.tryParse(secondsController.text) ?? 0;
                final totalSeconds = (minutes * 60) + seconds;
                final label = labelController.text.isNotEmpty
                    ? labelController.text
                    : '${minutes}m ${seconds}s';

                if (totalSeconds > 0) {
                  _presetManager.savePreset(label, totalSeconds, context);
                  Navigator.pop(context);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPresetDialog(Map<String, dynamic> preset) {
    final minutesController = TextEditingController(
        text: ((preset['seconds'] as int) ~/ 60).toString());
    final secondsController = TextEditingController(
        text: ((preset['seconds'] as int) % 60).toString());
    final labelController =
        TextEditingController(text: preset['label'] as String);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica Preset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Nome preset',
                  hintText: 'es. Recupero breve',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minuti',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Secondi',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                final minutes = int.tryParse(minutesController.text) ?? 0;
                final seconds = int.tryParse(secondsController.text) ?? 0;
                final totalSeconds = (minutes * 60) + seconds;
                final label = labelController.text.isNotEmpty
                    ? labelController.text
                    : '${minutes}m ${seconds}s';

                if (totalSeconds > 0) {
                  _presetManager.updatePreset(
                      preset['id'] as String, label, totalSeconds, context);
                  Navigator.pop(context);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }
}
