import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isDestructive = false,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: isFullWidth ? double.infinity : width,
      height: height,
      decoration: BoxDecoration(
        gradient: isPrimary && !isDestructive ? LinearGradient(
          colors: [
            isDestructive ? colorScheme.error : colorScheme.primary,
            (isDestructive ? colorScheme.error : colorScheme.primary).withOpacity(0.8),
          ],
        ) : null,
        color: !isPrimary ? colorScheme.surfaceVariant.withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: (isDestructive ? colorScheme.error : colorScheme.primary).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: padding ?? EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.lg,
              vertical: AppTheme.spacing.md,
            ),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPrimary ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: isPrimary 
                          ? colorScheme.onPrimary 
                          : isDestructive 
                              ? colorScheme.error 
                              : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: AppTheme.spacing.sm),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isPrimary 
                          ? colorScheme.onPrimary 
                          : isDestructive 
                              ? colorScheme.error 
                              : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Factory constructors per varianti comuni
  factory AppButton.primary({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isPrimary: true,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  factory AppButton.secondary({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isPrimary: false,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  factory AppButton.destructive({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isPrimary: true,
      isDestructive: true,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  factory AppButton.icon({
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isDestructive = false,
    double? size,
  }) {
    return AppButton(
      label: '',
      onPressed: onPressed,
      icon: icon,
      isPrimary: isPrimary,
      isDestructive: isDestructive,
      padding: EdgeInsets.all(size ?? 12),
    );
  }
}

// Pulsante con animazione di ripple circolare
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final double size;

  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isPrimary && !isDestructive ? LinearGradient(
          colors: [
            isDestructive ? colorScheme.error : colorScheme.primary,
            (isDestructive ? colorScheme.error : colorScheme.primary).withOpacity(0.8),
          ],
        ) : null,
        color: !isPrimary ? colorScheme.surfaceVariant.withOpacity(0.3) : null,
        boxShadow: isPrimary ? [
          BoxShadow(
            color: (isDestructive ? colorScheme.error : colorScheme.primary).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            color: isPrimary 
                ? colorScheme.onPrimary 
                : isDestructive 
                    ? colorScheme.error 
                    : colorScheme.onSurfaceVariant,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

// Pulsante con effetto di pressione
class PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scale;
  final Duration duration;

  const PressableButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scale = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
} 