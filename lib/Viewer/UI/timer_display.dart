import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'timer_constants.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get _shouldPulse =>
      widget.remainingSeconds <= 5 && widget.remainingSeconds > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_shouldPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_shouldPulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Container(
      width: double.infinity,
      height: TimerConstants.timerDisplaySize,
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: Colors.black, // Uso un colore più scuro per contrasto
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isEmomMode) _buildEmomLabel(theme, colorScheme),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedBuilder(
                animation:
                    Listenable.merge([widget.animation, _pulseAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _shouldPulse ? _pulseAnimation.value : 1.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildOuterRing(colorScheme),
                        _buildProgressCircle(colorScheme),
                        _buildQuarterMarkers(colorScheme),
                        _buildTimerText(theme),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOuterRing(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: colorScheme.surfaceContainerHighest.withAlpha(40),
          width: 4,
        ),
      ),
    );
  }

  Widget _buildProgressCircle(ColorScheme colorScheme) {
    Color progressColor = AppTheme.primaryGold;

    // Cambia colore negli ultimi 5 secondi
    if (widget.remainingSeconds <= 5) {
      progressColor = AppTheme.success;
    }

    return CustomPaint(
      painter: ProgressArcPainter(
        progress: widget.animation.value,
        progressColor: progressColor,
        progressWidth: TimerConstants.progressStrokeWidth,
        backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(20),
      ),
    );
  }

  Widget _buildQuarterMarkers(ColorScheme colorScheme) {
    // Solo se il timer totale è superiore a 30 secondi
    if (widget.totalSeconds < 30) return const SizedBox.shrink();

    return CustomPaint(
      painter: QuarterMarkersPainter(
        markerColor: colorScheme.surfaceContainerHighest.withAlpha(80),
        totalSeconds: widget.totalSeconds,
      ),
    );
  }

  Widget _buildTimerText(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: theme.textTheme.displayLarge?.copyWith(
                  color: _shouldPulse
                      ? (widget.remainingSeconds <= 3
                          ? AppTheme.error
                          : AppTheme.success)
                      : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 52,
                  height: 1,
                  letterSpacing: -1,
                ) ??
                const TextStyle(),
            child: Text(_formatTime(widget.remainingSeconds)),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.sm,
              vertical: AppTheme.spacing.xxs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTheme.radii.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: Colors.white.withAlpha(150),
                ),
                SizedBox(width: 4),
                Text(
                  'rimanenti',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withAlpha(150),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
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
        color: AppTheme.primaryGold.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        border: Border.all(
          color: AppTheme.primaryGold.withAlpha(100),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.repeat,
            size: 16,
            color: AppTheme.primaryGold,
          ),
          SizedBox(width: 4),
          Text(
            'EMOM',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppTheme.primaryGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter per l'arco di progresso
class ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double progressWidth;

  ProgressArcPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.progressWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - progressWidth / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = progressWidth
      ..strokeCap = StrokeCap.round;

    // Effetto sfumato
    final gradient = SweepGradient(
      center: Alignment.center,
      startAngle: -math.pi / 2,
      endAngle: 3 * math.pi / 2,
      colors: [
        progressColor.withAlpha(50),
        progressColor,
      ],
      stops: const [0.0, 1.0],
      transform: GradientRotation(-math.pi / 2),
    );

    progressPaint.shader = gradient.createShader(
      Rect.fromCircle(center: center, radius: radius),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top
      progress * 2 * math.pi, // Full circle is 2*pi
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressWidth != progressWidth;
  }
}

// Custom painter per i marker dei quarti
class QuarterMarkersPainter extends CustomPainter {
  final Color markerColor;
  final int totalSeconds;

  QuarterMarkersPainter({
    required this.markerColor,
    required this.totalSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4; // Un po' interno

    final paint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Calcola quanti marker disegnare (1 ogni 15 secondi)
    final quarters = totalSeconds ~/ 15;
    if (quarters <= 1) return; // Non disegnare marker se troppo pochi

    for (int i = 1; i <= quarters; i++) {
      final angle = -math.pi / 2 + (i * (2 * math.pi / (totalSeconds / 15)));
      final startPoint = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius + 8) * math.cos(angle),
        center.dy + (radius + 8) * math.sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant QuarterMarkersPainter oldDelegate) {
    return oldDelegate.markerColor != markerColor ||
        oldDelegate.totalSeconds != totalSeconds;
  }
}
