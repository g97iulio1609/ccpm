import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:alphanessone/Viewer/domain/entities/timer_preset.dart';
import 'package:alphanessone/Viewer/presentation/notifiers/exercise_timer_notifier.dart';

// Costanti per il layout (manteniamo quelle esistenti)
class TimerConstants {
  static const timerDisplaySize = 300.0;
  static const progressStrokeWidth = 8.0;
  static const numberPickerItemHeight = 42.0;
}

// Widget per il campo di input personalizzato (riutilizziamo quello esistente)
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
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
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

class ExerciseTimerBottomSheet extends ConsumerStatefulWidget {
  final String userId;
  final String exerciseId;
  final String workoutId;
  final String exerciseName;
  final Function(int repsDone, double weightDone) onSeriesComplete;
  final int initialTimerSeconds;
  final int reps;
  final double weight;

  const ExerciseTimerBottomSheet({
    super.key,
    required this.userId,
    required this.exerciseId,
    required this.workoutId,
    required this.exerciseName,
    required this.onSeriesComplete,
    this.initialTimerSeconds = 60, // Default a 1 minuto
    required this.reps,
    required this.weight,
  });

  static Future<void> show({
    required BuildContext context,
    required String userId,
    required String exerciseId,
    required String workoutId,
    required String exerciseName,
    required Function(int repsDone, double weightDone) onSeriesComplete,
    int initialTimerSeconds = 60,
    required int reps,
    required double weight,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExerciseTimerBottomSheet(
        userId: userId,
        exerciseId: exerciseId,
        workoutId: workoutId,
        exerciseName: exerciseName,
        onSeriesComplete: onSeriesComplete,
        initialTimerSeconds: initialTimerSeconds,
        reps: reps,
        weight: weight,
      ),
    );
  }

  @override
  ConsumerState<ExerciseTimerBottomSheet> createState() =>
      _ExerciseTimerBottomSheetState();
}

class _ExerciseTimerBottomSheetState
    extends ConsumerState<ExerciseTimerBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  // Controllers per i campi di input
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  // Variabili locali per lo stato dell'UI
  bool _isEmomMode = false;

  @override
  void initState() {
    super.initState();

    // Inizializza i controller con i valori iniziali
    _repsController = TextEditingController(text: widget.reps.toString());
    _weightController = TextEditingController(text: widget.weight.toString());

    // Inizializza l'animazione
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.initialTimerSeconds),
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleTimerComplete() {
    // Quando il timer è completato, chiama la callback per completare la serie
    final int repsDone = int.tryParse(_repsController.text) ?? 0;
    final double weightDone = double.tryParse(_weightController.text) ?? 0.0;
    widget.onSeriesComplete(repsDone, weightDone);
  }

  Future<void> _showAddPresetDialog() async {
    final minutesController = TextEditingController();
    final secondsController = TextEditingController();
    final labelController = TextEditingController();

    return showDialog(
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
                      decoration: const InputDecoration(labelText: 'Minuti'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Secondi'),
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
                  // Usa il notifier per salvare il preset
                  final notifier = ref.read(
                    exerciseTimerStateProvider((
                      userId: widget.userId,
                      initialDuration: widget.initialTimerSeconds,
                    )).notifier,
                  );
                  notifier.saveCurrentTimeAsPreset(label);
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

  Future<void> _showEditPresetDialog(TimerPreset preset) async {
    final minutesController = TextEditingController(
      text: ((preset.seconds) ~/ 60).toString(),
    );
    final secondsController = TextEditingController(
      text: ((preset.seconds) % 60).toString(),
    );
    final labelController = TextEditingController(text: preset.label);

    return showDialog(
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
                      decoration: const InputDecoration(labelText: 'Minuti'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Secondi'),
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
                  // Usa il notifier per aggiornare il preset
                  final notifier = ref.read(
                    exerciseTimerStateProvider((
                      userId: widget.userId,
                      initialDuration: widget.initialTimerSeconds,
                    )).notifier,
                  );
                  notifier.updateSelectedPreset(label, totalSeconds);
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

  @override
  Widget build(BuildContext context) {
    // Accedi allo stato del timer attraverso il provider
    final timerState = ref.watch(
      exerciseTimerStateProvider((
        userId: widget.userId,
        initialDuration: widget.initialTimerSeconds,
      )),
    );
    final timerNotifier = ref.read(
      exerciseTimerStateProvider((
        userId: widget.userId,
        initialDuration: widget.initialTimerSeconds,
      )).notifier,
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Sincronizza l'animazione con lo stato del timer
    if (timerState.status == TimerStatus.running) {
      _animationController.value =
          timerState.remainingDuration / timerState.initialDuration;
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
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
                            scrollController.offset + details.primaryDelta!,
                          );
                          if (scrollController.offset >=
                              scrollController.position.maxScrollExtent) {
                            Navigator.of(context).pop();
                          }
                        } else {
                          // Trascinamento verso l'alto
                          scrollController.jumpTo(
                            scrollController.offset + details.primaryDelta!,
                          );
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
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacing.sm,
                        ),
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
                                    widget.exerciseName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  // Qui potrebbe andare un'informazione sulla serie corrente se necessario
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Timer o Input Fields in base allo stato
                              if (timerState.status == TimerStatus.running ||
                                  timerState.status == TimerStatus.paused ||
                                  timerState.status == TimerStatus.finished)
                                _buildTimerDisplay(
                                  timerState,
                                  theme,
                                  colorScheme,
                                )
                              else
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CustomInputField(
                                          controller: _repsController,
                                          label: 'REPS',
                                        ),
                                        SizedBox(width: AppTheme.spacing.md),
                                        CustomInputField(
                                          controller: _weightController,
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
                              if (timerState.status == TimerStatus.running ||
                                  timerState.status == TimerStatus.paused ||
                                  timerState.status == TimerStatus.finished)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          timerNotifier.resetTimer();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFEF4444,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            vertical: AppTheme.spacing.lg,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radii.lg,
                                            ),
                                          ),
                                        ),
                                        child: const Text('ANNULLA'),
                                      ),
                                    ),
                                    SizedBox(width: AppTheme.spacing.md),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _handleTimerComplete,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFACC15,
                                          ),
                                          foregroundColor: Colors.black,
                                          padding: EdgeInsets.symmetric(
                                            vertical: AppTheme.spacing.lg,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radii.lg,
                                            ),
                                          ),
                                        ),
                                        child: const Text('SERIE COMPLETATA'),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _buildTimerSelector(
                                      timerState,
                                      timerNotifier,
                                      theme,
                                      colorScheme,
                                    ),
                                    SizedBox(height: AppTheme.spacing.lg),
                                    _buildStartButton(
                                      timerNotifier,
                                      _isEmomMode,
                                      theme,
                                      colorScheme,
                                    ),
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

  Widget _buildTimerDisplay(
    ExerciseTimerState timerState,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
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
                  _buildTimerCircle(timerState, colorScheme),
                  _buildTimerText(timerState, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCircle(
    ExerciseTimerState timerState,
    ColorScheme colorScheme,
  ) {
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
          // Calcola il valore del progresso con range 0-1
          final progress =
              timerState.remainingDuration / timerState.initialDuration;
          return CircularProgressIndicator(
            value: progress,
            strokeWidth: TimerConstants.progressStrokeWidth,
            backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(26),
            color: AppTheme.primaryGold,
            strokeCap: StrokeCap.round,
          );
        },
      ),
    );
  }

  Widget _buildTimerText(ExerciseTimerState timerState, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(timerState.remainingDuration),
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

  Widget _buildTimerSelector(
    ExerciseTimerState timerState,
    ExerciseTimerNotifier timerNotifier,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPresetButtons(timerState, timerNotifier, theme, colorScheme),
        SizedBox(height: AppTheme.spacing.md),
        _buildCustomTimePicker(timerState, timerNotifier, theme, colorScheme),
      ],
    );
  }

  Widget _buildPresetButtons(
    ExerciseTimerState timerState,
    ExerciseTimerNotifier timerNotifier,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: timerState.presets.map((preset) {
                final isSelected = timerState.selectedPreset?.id == preset.id;
                return Padding(
                  padding: EdgeInsets.only(right: AppTheme.spacing.xs),
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () {
                        timerNotifier.selectPreset(preset);
                      },
                      onLongPress: () => _showEditPresetDialog(preset),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isSelected
                            ? colorScheme.primaryContainer
                            : null,
                        side: BorderSide(color: colorScheme.primary),
                        padding: EdgeInsets.only(
                          left: AppTheme.spacing.sm,
                          right: AppTheme.spacing.xl,
                          top: AppTheme.spacing.sm,
                          bottom: AppTheme.spacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radii.md,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDuration(preset.seconds),
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
                            onPressed: () {
                              timerNotifier.deleteSelectedPreset();
                            },
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

  Widget _buildCustomTimePicker(
    ExerciseTimerState timerState,
    ExerciseTimerNotifier timerNotifier,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    // Calcola minuti e secondi dal timer state
    final minutes = timerState.initialDuration ~/ 60;
    final seconds = timerState.initialDuration % 60;

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
          _buildNumberPicker(theme, colorScheme, 'Minuti', minutes, 59, (
            value,
          ) {
            final newSeconds = value * 60 + seconds;
            timerNotifier.setCustomTime(newSeconds);
          }),
          VerticalDivider(
            color: colorScheme.outline.withAlpha(26),
            width: AppTheme.spacing.lg,
          ),
          _buildNumberPicker(theme, colorScheme, 'Secondi', seconds, 59, (
            value,
          ) {
            final newSeconds = minutes * 60 + value;
            timerNotifier.setCustomTime(newSeconds);
          }),
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

  Widget _buildStartButton(
    ExerciseTimerNotifier timerNotifier,
    bool isEmom,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Avvia il timer con l'opzione EMOM
          timerNotifier.startTimer();

          // Avvia anche la notifica quando completo
          // Nota: Questo dovrebbe essere gestito nel notifier stesso in una versione più avanzata
          if (isEmom) {
            // Logica per notifica EMOM
            // Potremmo passare isEmom al notifier, o gestire le notifiche qui
          }
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

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
}
