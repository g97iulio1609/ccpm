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

  const CustomInputField({
    super.key,
    required this.controller,
    required this.label,
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

  final Map<String, Map<String, TextEditingController>> _repsControllers = {};
  final Map<String, Map<String, TextEditingController>> _weightControllers = {};

  bool _isTimerMode = false;
  bool _isEmomMode = false;
  int _currentSeriesIndex = 0;
  int _currentSuperSetExerciseIndex = 0;
  int _timerMinutes = 1;
  int _timerSeconds = 0;
  int _remainingSeconds = 0;
  List<Map<String, dynamic>> _presets = TimerConstants.defaultPresets;

  @override
  void initState() {
    super.initState();
    _loadUserPresets();
    _initializeState();
  }

  List<Map<String, dynamic>> _loadPresetsFromCache(
      SharedPreferences prefs, String key) {
    final data = prefs.getString(key);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data);
      return decoded is List
          ? decoded.map((item) => Map<String, dynamic>.from(item)).toList()
          : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadUserPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carica dati dalla cache
      final cachedPresets =
          _loadPresetsFromCache(prefs, 'timer_presets_${widget.userId}');

      // Sincronizza con Firestore
      try {
        final presets = await FirebaseFirestore.instance
            .collection('timer_presets')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('seconds')
            .get();

        if (presets.docs.isNotEmpty) {
          final updatedPresets = _removeDuplicatePresets(presets.docs
              .map((doc) => {
                    'id': doc.id,
                    'label': doc.data()['label'] as String,
                    'seconds': doc.data()['seconds'] as int,
                  })
              .toList());

          // Aggiorna cache
          await _saveToCache(
              prefs, 'timer_presets_${widget.userId}', updatedPresets);
          setState(() => _presets = updatedPresets);
          return;
        }

        // Se non ci sono preset, crea quelli predefiniti
        final batch = FirebaseFirestore.instance.batch();
        final defaultPresets = await Future.wait(
          TimerConstants.defaultPresets.map((preset) async {
            final docRef =
                FirebaseFirestore.instance.collection('timer_presets').doc();
            batch.set(docRef, {
              'userId': widget.userId,
              'label': preset['label'],
              'seconds': preset['seconds'],
              'createdAt': FieldValue.serverTimestamp(),
            });
            return {
              'id': docRef.id,
              ...preset,
            };
          }),
        );

        await batch.commit();
        await _saveToCache(
            prefs, 'timer_presets_${widget.userId}', defaultPresets);
        setState(() => _presets = defaultPresets);
      } catch (_) {
        // Usa dati dalla cache se Firestore non disponibile
        setState(() => _presets = _removeDuplicatePresets(cachedPresets));
      }
    } catch (_) {
      setState(() => _presets = []);
    }
  }

  List<Map<String, dynamic>> _removeDuplicatePresets(
      List<Map<String, dynamic>> presets) {
    final uniquePresets = <int, Map<String, dynamic>>{};
    for (final preset in presets) {
      final seconds = preset['seconds'] as int;
      if (!uniquePresets.containsKey(seconds)) {
        uniquePresets[seconds] = preset;
      }
    }
    return uniquePresets.values.toList()
      ..sort((a, b) => a['seconds'].compareTo(b['seconds']));
  }

  Future<void> _savePreset(String label, int seconds) async {
    // Controlla se esiste già un preset con gli stessi secondi
    if (_presets.any((p) => p['seconds'] == seconds)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Esiste già un preset da $seconds secondi')),
        );
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final docRef =
          await FirebaseFirestore.instance.collection('timer_presets').add({
        'userId': widget.userId,
        'label': label,
        'seconds': seconds,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final newPreset = {
        'id': docRef.id,
        'label': label,
        'seconds': seconds,
      };

      setState(() {
        _presets = _removeDuplicatePresets([..._presets, newPreset]);
      });

      await _saveToCache(prefs, 'timer_presets_${widget.userId}', _presets);
    } catch (_) {}
  }

  Future<void> _updatePreset(String presetId, String label, int seconds) async {
    // Controlla se esiste già un altro preset con gli stessi secondi
    if (_presets.any((p) => p['seconds'] == seconds && p['id'] != presetId)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Esiste già un preset da $seconds secondi')),
        );
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await FirebaseFirestore.instance
          .collection('timer_presets')
          .doc(presetId)
          .update({
        'label': label,
        'seconds': seconds,
      });

      setState(() {
        final index = _presets.indexWhere((p) => p['id'] == presetId);
        if (index != -1) {
          _presets[index] = {
            'id': presetId,
            'label': label,
            'seconds': seconds,
          };
          _presets.sort((a, b) => a['seconds'].compareTo(b['seconds']));
        }
      });

      await _saveToCache(prefs, 'timer_presets_${widget.userId}', _presets);
    } catch (_) {}
  }

  Future<void> _deletePreset(String presetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await FirebaseFirestore.instance
          .collection('timer_presets')
          .doc(presetId)
          .delete();

      setState(() {
        _presets.removeWhere((preset) => preset['id'] == presetId);
      });

      await _saveToCache(prefs, 'timer_presets_${widget.userId}', _presets);
    } catch (_) {}
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
                  _savePreset(label, totalSeconds);
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

  void _initializeState() {
    _initializeControllers();
    _initializeIndices();
    _initializeAnimation();

    _timerManager = TimerManager(
      onTick: _onTimerTick,
      onComplete: _onTimerComplete,
      animationController: _animationController,
      exerciseName: widget.superSetExercises[_currentSuperSetExerciseIndex]
          ['name'] as String,
    );
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
  }

  void _onTimerComplete() {
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
        Navigator.of(context).pop();
      }
      _isTimerMode = false;
    });
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
        backgroundColor: const Color(0xFFFACC15),
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        ),
      ),
      child: Text(buttonText),
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

                              // Timer or Input Fields
                              if (_isTimerMode)
                                _buildTimerDisplay(theme, colorScheme)
                              else
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CustomInputField(
                                          controller: _repsControllers[
                                                  currentExercise['id']]![
                                              currentExercise['series']
                                                  [_currentSeriesIndex]['id']]!,
                                          label: 'REPS',
                                        ),
                                        SizedBox(width: AppTheme.spacing.md),
                                        CustomInputField(
                                          controller: _weightControllers[
                                                  currentExercise['id']]![
                                              currentExercise['series']
                                                  [_currentSeriesIndex]['id']]!,
                                          label: 'WEIGHT',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ListTile(
                                      title: const Text('Modalità EMOM'),
                                      trailing: Switch(
                                        value: _isEmomMode,
                                        onChanged: (value) =>
                                            setState(() => _isEmomMode = value),
                                        activeColor: colorScheme.primary,
                                        activeTrackColor:
                                            colorScheme.primaryContainer,
                                      ),
                                    ),
                                  ],
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
                                          backgroundColor:
                                              const Color(0xFFEF4444),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                              vertical: AppTheme.spacing.lg),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppTheme.radii.lg),
                                          ),
                                        ),
                                        child: const Text('ANNULLA'),
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
                                Column(
                                  children: [
                                    _buildTimerSelector(theme, colorScheme),
                                    SizedBox(height: AppTheme.spacing.lg),
                                    _buildStartButton(theme, colorScheme),
                                  ],
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

  Widget _buildTimerDisplay(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: TimerConstants.timerDisplaySize,
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isEmomMode) _buildEmomLabel(theme, colorScheme),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildTimerCircle(colorScheme),
                  _buildTimerText(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CircularProgressIndicator(
            value: _animation.value,
            strokeWidth: TimerConstants.progressStrokeWidth,
            backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(26),
            color: AppTheme.primaryGold,
            strokeCap: StrokeCap.round,
          );
        },
      ),
    );
  }

  Widget _buildTimerText(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(_remainingSeconds),
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 48,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.sm,
              vertical: AppTheme.spacing.xxs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(AppTheme.radii.full),
            ),
            child: Text(
              'rimanenti',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white.withAlpha(204),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmomLabel(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
      ),
      child: Text(
        'EMOM',
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimerSelector(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPresetButtons(theme, colorScheme),
        SizedBox(height: AppTheme.spacing.md),
        _buildCustomTimePicker(theme, colorScheme),
      ],
    );
  }

  Widget _buildPresetButtons(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _presets.map((preset) {
                return Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacing.xs),
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          final seconds = preset['seconds'] as int;
                          _timerMinutes = seconds ~/ 60;
                          _timerSeconds = seconds % 60;
                        });
                      },
                      onLongPress: () => _showEditPresetDialog(preset),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colorScheme.primary),
                        padding: EdgeInsets.only(
                          left: AppTheme.spacing.sm,
                          right: AppTheme.spacing.xl,
                          top: AppTheme.spacing.sm,
                          bottom: AppTheme.spacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radii.md),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(preset['seconds'] as int),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: AppTheme.spacing.xs),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            onPressed: () =>
                                _deletePreset(preset['id'] as String),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddPresetDialog,
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi preset'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: colorScheme.primary.withAlpha(128)),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTimePicker(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNumberPicker(
            theme,
            colorScheme,
            'Minuti',
            _timerMinutes,
            59,
            (value) => setState(() => _timerMinutes = value),
          ),
          VerticalDivider(
            color: colorScheme.outline.withAlpha(26),
            width: AppTheme.spacing.lg,
          ),
          _buildNumberPicker(
            theme,
            colorScheme,
            'Secondi',
            _timerSeconds,
            59,
            (value) => setState(() => _timerSeconds = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPicker(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    int value,
    int maxValue,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        NumberPicker(
          value: value,
          minValue: 0,
          maxValue: maxValue,
          onChanged: onChanged,
          itemHeight: TimerConstants.numberPickerItemHeight,
          textStyle: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          selectedTextStyle: theme.textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.outline.withAlpha(26)),
              bottom: BorderSide(color: colorScheme.outline.withAlpha(26)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(ThemeData theme, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() => _isTimerMode = true);
          final totalSeconds = (_timerMinutes * 60) + _timerSeconds;
          _remainingSeconds = totalSeconds;
          _timerManager.startTimer(totalSeconds, _isEmomMode);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          ),
        ),
        child: Text(
          'AVVIA TIMER',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
                  _updatePreset(preset['id'] as String, label, totalSeconds);
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

  Future<void> _saveToCache(
      SharedPreferences prefs, String key, dynamic data) async {
    await prefs.setString(key, jsonEncode(data));
  }
}
