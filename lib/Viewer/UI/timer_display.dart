import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/Viewer/UI/widgets/workout_formatters.dart';
import 'dart:math' as math;

class TimerDisplay extends StatefulWidget {
  final Animation<double> animation;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isEmomMode;

  const TimerDisplay({
    super.key,
    required this.animation,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.isEmomMode = false,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _smoothProgressAnimation;

  @override
  void initState() {
    super.initState();

    // Controller per l'effetto pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Controller per il progresso fluido
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _smoothProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _progressController.forward();
  }

  @override
  void didUpdateWidget(TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Aggiorna l'animazione del progresso quando cambia il widget
    if (oldWidget.remainingSeconds != widget.remainingSeconds ||
        oldWidget.totalSeconds != widget.totalSeconds) {
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }


  bool get _shouldPulse =>
      widget.remainingSeconds <= 5 && widget.remainingSeconds > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Gestione animazione pulse più fluida
    if (_shouldPulse) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isEmomMode) _buildEmomLabel(theme, colorScheme),
          _buildFluidTimerDisplay(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildFluidTimerDisplay(ThemeData theme, ColorScheme colorScheme) {
    final rawProgress = widget.totalSeconds > 0
        ? (widget.totalSeconds - widget.remainingSeconds) / widget.totalSeconds
        : 0.0;

    final isWarning =
        widget.remainingSeconds <= 10 && widget.remainingSeconds > 5;
    final isCritical = widget.remainingSeconds <= 5;

    Color accentColor = AppTheme.primaryGold;
    if (isCritical) {
      accentColor = AppTheme.error;
    } else if (isWarning) {
      accentColor = AppTheme.warning;
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.animation,
        _pulseAnimation,
        _smoothProgressAnimation,
      ]),
      builder: (context, child) {
        // Progresso interpolato per maggiore fluidità
        final smoothProgress = rawProgress * _smoothProgressAnimation.value;

        return Transform.scale(
          scale: _shouldPulse ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              border: Border.all(
                color: colorScheme.outline.withAlpha(15),
                width: 1,
              ),
              boxShadow: [
                if (isCritical)
                  BoxShadow(
                    color: accentColor.withAlpha(30),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Background circle
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surfaceContainerHighest.withAlpha(20),
                    ),
                  ),
                ),

                // Progress indicator con animazione fluida
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CustomPaint(
                      painter: FluidProgressPainter(
                        progress: smoothProgress,
                        color: accentColor,
                        backgroundColor: colorScheme.outline.withAlpha(10),
                        strokeWidth: 6,
                        pulseEffect: _shouldPulse ? _pulseAnimation.value : 1.0,
                      ),
                    ),
                  ),
                ),

                // Center content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Time display con animazione del testo più fluida
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(0.0, 0.2),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                  child: child,
                                ),
                              );
                            },
                        child: Text(
                          WorkoutFormatters.formatTime(widget.remainingSeconds),
                          key: ValueKey(widget.remainingSeconds),
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                      ),

                      SizedBox(height: AppTheme.spacing.xs),

                      // Status indicator animato
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing.sm,
                          vertical: AppTheme.spacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radii.full,
                          ),
                          border: Border.all(
                            color: accentColor.withAlpha(50),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacing.xxs),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                isCritical ? 'Quasi finito' : 'In corso',
                                key: ValueKey(isCritical),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmomLabel(ThemeData theme, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: EdgeInsets.only(bottom: AppTheme.spacing.lg),
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryGold.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        border: Border.all(
          color: AppTheme.primaryGold.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.repeat_rounded, size: 16, color: AppTheme.primaryGold),
          SizedBox(width: AppTheme.spacing.xs),
          Text(
            'MODALITÀ EMOM',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Progress painter migliorato per animazioni più fluide
class FluidProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;
  final double pulseEffect;

  FluidProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
    this.pulseEffect = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc con effetto glow se in stato critico
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * pulseEffect
        ..strokeCap = StrokeCap.round;

      // Effetto glow per stati critici
      if (pulseEffect > 1.0) {
        final glowPaint = Paint()
          ..color = color.withAlpha(30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * pulseEffect * 2
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          -math.pi / 2,
          progress * 2 * math.pi,
          false,
          glowPaint,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at top
        progress * 2 * math.pi,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FluidProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.pulseEffect != pulseEffect;
  }
}
