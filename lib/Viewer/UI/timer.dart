import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/timer_model.dart';
import '../providers/training_program_provider.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/Main/routes.dart';

class TimerPage extends ConsumerStatefulWidget {
  final TimerModel timerModel;

  const TimerPage({
    super.key,
    required this.timerModel,
  });

  @override
  TimerPageState createState() => TimerPageState();
}

class TimerPageState extends ConsumerState<TimerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeController();
    Future.microtask(() {
      ref.read(timerModelProvider.notifier).state = widget.timerModel;
      ref.read(remainingSecondsProvider.notifier).state =
          widget.timerModel.restTime;
      _startTimer();
    });
  }

  void _initializeController() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.timerModel.restTime),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
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
    final timerModel = ref.read(timerModelProvider);
    if (timerModel != null) {
      final nextSeriesIndex = timerModel.currentSeriesIndex + 1;
      
      if (nextSeriesIndex < timerModel.totalSeries) {
        final result = {
          'startIndex': nextSeriesIndex,
          'superSetExerciseIndex': 0,  // Reset to first exercise in superset
        };
        context.pop(result);
      } else {
        // All series completed, navigate back to workout details
        context.pop(); // Pop timer
        context.pop(); // Pop exercise_details
      }
    } else {
      context.pop();
    }
  }

  void _skipRestTime() {
    _timer.cancel();
    final timerModel = ref.read(timerModelProvider);
    if (timerModel != null) {
      final nextSeriesIndex = timerModel.currentSeriesIndex + 1;
      
      if (nextSeriesIndex < timerModel.totalSeries) {
        final result = {
          'startIndex': nextSeriesIndex,
          'superSetExerciseIndex': 0,  // Reset to first exercise in superset
        };
        context.pop(result);
      } else {
        // All series completed, navigate back to workout details
        context.pop(); // Pop timer
        context.pop(); // Pop exercise_details
      }
    } else {
      context.pop();
    }
  }

  void _onTimerComplete() {
    final path = '${Routes.userPrograms}/${widget.timerModel.userId}/${Routes.trainingViewer}/${widget.timerModel.programId}/${Routes.weekDetails}/${widget.timerModel.weekId}/${Routes.workoutDetails}/${widget.timerModel.workoutId}/${Routes.exerciseDetails}';
    
    context.go(path, extra: {
      'programId': widget.timerModel.programId,
      'weekId': widget.timerModel.weekId,
      'workoutId': widget.timerModel.workoutId,
      'exerciseId': widget.timerModel.exerciseId,
      'userId': widget.timerModel.userId,
      'superSetExercises': widget.timerModel.superSetExercises,
      'superSetExerciseIndex': widget.timerModel.superSetExerciseIndex,
      'seriesList': widget.timerModel.seriesList,
      'currentSeriesIndex': widget.timerModel.currentSeriesIndex
    });
  }

  void _onSkipTimer() {
    final path = '${Routes.userPrograms}/${widget.timerModel.userId}/${Routes.trainingViewer}/${widget.timerModel.programId}/${Routes.weekDetails}/${widget.timerModel.weekId}/${Routes.workoutDetails}/${widget.timerModel.workoutId}/${Routes.exerciseDetails}';
    
    context.go(path, extra: {
      'programId': widget.timerModel.programId,
      'weekId': widget.timerModel.weekId,
      'workoutId': widget.timerModel.workoutId,
      'exerciseId': widget.timerModel.exerciseId,
      'userId': widget.timerModel.userId,
      'superSetExercises': widget.timerModel.superSetExercises,
      'superSetExerciseIndex': widget.timerModel.superSetExerciseIndex,
      'seriesList': widget.timerModel.seriesList,
      'currentSeriesIndex': widget.timerModel.currentSeriesIndex
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerModel = ref.watch(timerModelProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (timerModel == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            'Errore: timerModel non disponibile',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ),
      );
    }

    final remainingSeconds = ref.watch(remainingSecondsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surface.withOpacity(0.92),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(timerModel, theme, colorScheme),
                  SizedBox(height: AppTheme.spacing.xl),
                  _buildTimerContainer(remainingSeconds, theme, colorScheme),
                  SizedBox(height: AppTheme.spacing.xl),
                  if (!timerModel.isEmomMode)
                    _buildSkipButton(theme, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      TimerModel timerModel, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        children: [
          Text(
            timerModel.isEmomMode ? 'EMOM MODE' : 'REST TIME',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (!timerModel.isEmomMode) ...[
            SizedBox(height: AppTheme.spacing.sm),
            Text(
              'Take a breath, stay focused',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerContainer(
      int remainingSeconds, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: 320,
      height: 320,
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.15),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          // Progress indicator più grande e sottile
          _buildProgressIndicator(colorScheme),

          // Container centrale con sfondo sfumato
          Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: -5,
                ),
              ],
            ),
          ),

          // Testo del timer
          _buildCountdownText(remainingSeconds, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CircularProgressIndicator(
          value: _animation.value,
          strokeWidth: 6,
          backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            colorScheme.primary.withOpacity(0.8),
          ),
        );
      },
    );
  }

  Widget _buildCountdownText(
      int remainingSeconds, ThemeData theme, ColorScheme colorScheme) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Timer digits
        Text(
          '$minutes:$seconds',
          style: theme.textTheme.displayLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 64,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        SizedBox(height: AppTheme.spacing.sm),
        // Remaining label
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: AppTheme.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.1),
            ),
          ),
          child: Text(
            'remaining',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(top: AppTheme.spacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _skipRestTime,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.xxl,
              vertical: AppTheme.spacing.lg,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.skip_next_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'SKIP REST',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
