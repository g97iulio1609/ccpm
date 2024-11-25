import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppSpinner extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final double strokeWidth;
  final bool overlay;
  final bool showMessage;

  const AppSpinner({
    super.key,
    this.message,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.overlay = false,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spinnerColor = color ?? colorScheme.primary;

    Widget spinner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
                  backgroundColor: spinnerColor.withOpacity(0.2),
                ),
              ),
              if (showMessage && message != null) ...[
                SizedBox(height: AppTheme.spacing.md),
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (overlay) {
      return Stack(
        children: [
          ModalBarrier(
            color: colorScheme.scrim.withOpacity(0.32),
          ),
          Center(child: spinner),
        ],
      );
    }

    return spinner;
  }

  // Factory constructors per casi comuni
  factory AppSpinner.overlay({
    String? message,
    Color? color,
    double size = 40.0,
  }) {
    return AppSpinner(
      message: message,
      color: color,
      size: size,
      overlay: true,
    );
  }

  factory AppSpinner.small({
    Color? color,
  }) {
    return AppSpinner(
      color: color,
      size: 24.0,
      strokeWidth: 2.0,
      showMessage: false,
    );
  }

  factory AppSpinner.button({
    Color? color,
  }) {
    return AppSpinner(
      color: color,
      size: 20.0,
      strokeWidth: 2.0,
      showMessage: false,
    );
  }
}

// Spinner con animazione personalizzata
class AppSpinnerWithAnimation extends StatefulWidget {
  final String? message;
  final Color? color;
  final double size;
  final bool overlay;

  const AppSpinnerWithAnimation({
    super.key,
    this.message,
    this.color,
    this.size = 40.0,
    this.overlay = false,
  });

  @override
  State<AppSpinnerWithAnimation> createState() => _AppSpinnerWithAnimationState();
}

class _AppSpinnerWithAnimationState extends State<AppSpinnerWithAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final spinnerColor = widget.color ?? colorScheme.primary;

    Widget spinner = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              spinnerColor.withOpacity(0.0),
                              spinnerColor,
                            ],
                            stops: const [0.0, 1.0],
                            transform: GradientRotation(_rotationAnimation.value * 2 * 3.14159),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(widget.size * 0.15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (widget.message != null) ...[
                SizedBox(height: AppTheme.spacing.md),
                Text(
                  widget.message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (widget.overlay) {
      return Stack(
        children: [
          ModalBarrier(
            color: colorScheme.scrim.withOpacity(0.32),
          ),
          Center(child: spinner),
        ],
      );
    }

    return spinner;
  }
} 