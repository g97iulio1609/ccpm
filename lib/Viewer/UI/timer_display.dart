import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'timer_constants.dart';

class TimerDisplay extends StatelessWidget {
  final Animation<double> animation;
  final int remainingSeconds;
  final bool isEmomMode;

  const TimerDisplay({
    super.key,
    required this.animation,
    required this.remainingSeconds,
    this.isEmomMode = false,
  });

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          if (isEmomMode) _buildEmomLabel(theme, colorScheme),
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
        animation: animation,
        builder: (context, child) {
          return CircularProgressIndicator(
            value: animation.value,
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
            _formatTime(remainingSeconds),
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
}
