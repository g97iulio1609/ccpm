import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? size;
  final bool isOutlined;
  final bool isPulsing;
  final VoidCallback? onTap;
  final bool isGradient;

  const AppBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.size,
    this.isOutlined = false,
    this.isPulsing = false,
    this.onTap,
    this.isGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final badgeColor = backgroundColor ?? colorScheme.primary;
    final labelColor = textColor ?? (isOutlined ? badgeColor : colorScheme.onPrimary);
    final textStyle = (size == AppBadgeSize.small 
        ? theme.textTheme.labelSmall 
        : theme.textTheme.labelMedium)?.copyWith(
      color: labelColor,
      fontWeight: FontWeight.w600,
    );

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == AppBadgeSize.small ? AppTheme.spacing.sm : AppTheme.spacing.md,
        vertical: size == AppBadgeSize.small ? AppTheme.spacing.xxs : AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: isGradient ? LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withOpacity(0.8),
          ],
        ) : null,
        color: isOutlined ? Colors.transparent : (isGradient ? null : badgeColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        border: isOutlined ? Border.all(
          color: badgeColor,
          width: 1.5,
        ) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: size == AppBadgeSize.small ? 12 : 16,
              color: labelColor,
            ),
            SizedBox(width: AppTheme.spacing.xs),
          ],
          Text(
            text,
            style: textStyle,
          ),
        ],
      ),
    );

    if (isPulsing) {
      badge = _PulsingBadge(child: badge);
    }

    if (onTap != null) {
      badge = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.full),
          child: badge,
        ),
      );
    }

    return badge;
  }

  // Factory constructors per casi comuni
  factory AppBadge.status({
    required String text,
    required BadgeStatus status,
    IconData? icon,
    bool isPulsing = false,
    VoidCallback? onTap,
  }) {
    Color getStatusColor(BadgeStatus status, ColorScheme colorScheme) {
      switch (status) {
        case BadgeStatus.success:
          return colorScheme.tertiary;
        case BadgeStatus.warning:
          return colorScheme.secondary;
        case BadgeStatus.error:
          return colorScheme.error;
        case BadgeStatus.info:
          return colorScheme.primary;
        case BadgeStatus.neutral:
          return colorScheme.outline;
      }
    }

    return AppBadge(
      text: text,
      icon: icon,
      isPulsing: isPulsing,
      onTap: onTap,
      isOutlined: true,
      backgroundColor: (context) => getStatusColor(status, Theme.of(context).colorScheme),
    );
  }

  factory AppBadge.counter({
    required String count,
    Color? backgroundColor,
    bool isPulsing = false,
  }) {
    return AppBadge(
      text: count,
      backgroundColor: backgroundColor,
      size: AppBadgeSize.small,
      isPulsing: isPulsing,
      isGradient: true,
    );
  }

  factory AppBadge.chip({
    required String text,
    IconData? icon,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return AppBadge(
      text: text,
      icon: icon,
      backgroundColor: backgroundColor,
      onTap: onTap,
      isOutlined: true,
    );
  }
}

// Widget per l'effetto pulsante
class _PulsingBadge extends StatefulWidget {
  final Widget child;

  const _PulsingBadge({required this.child});

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}

// Dimensioni predefinite per i badge
class AppBadgeSize {
  static const double small = 16.0;
  static const double medium = 20.0;
  static const double large = 24.0;
}

// Stati predefiniti per i badge
enum BadgeStatus {
  success,
  warning,
  error,
  info,
  neutral,
} 