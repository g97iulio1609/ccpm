import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

enum ToastType {
  success,
  error,
  warning,
  info,
}

class AppToast extends StatelessWidget {
  final String message;
  final ToastType type;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Duration duration;
  final VoidCallback? onDismiss;

  const AppToast({
    super.key,
    required this.message,
    this.type = ToastType.info,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final toastColor = _getToastColor(colorScheme);
    final toastIcon = icon ?? _getToastIcon();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.xl,
          vertical: AppTheme.spacing.lg,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: toastColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: toastColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radii.md),
                      ),
                      child: Icon(
                        toastIcon,
                        color: toastColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (onDismiss != null) ...[
                      SizedBox(width: AppTheme.spacing.sm),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: onDismiss,
                      ),
                    ],
                  ],
                ),
              ),
              if (onAction != null && actionLabel != null) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onAction,
                      child: Container(
                        padding: EdgeInsets.all(AppTheme.spacing.md),
                        alignment: Alignment.center,
                        child: Text(
                          actionLabel!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: toastColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getToastColor(ColorScheme colorScheme) {
    switch (type) {
      case ToastType.success:
        return colorScheme.tertiary;
      case ToastType.error:
        return colorScheme.error;
      case ToastType.warning:
        return colorScheme.secondary;
      case ToastType.info:
        return colorScheme.primary;
    }
  }

  IconData _getToastIcon() {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  // Helper method per mostrare un toast
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 0,
        right: 0,
        child: SafeArea(
          child: AppToast(
            message: message,
            type: type,
            icon: icon,
            onAction: onAction != null
                ? () {
                    overlayEntry.remove();
                    onAction();
                  }
                : null,
            actionLabel: actionLabel,
            onDismiss: () {
              overlayEntry.remove();
              onDismiss?.call();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    if (duration != Duration.zero) {
      Future.delayed(duration, () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    }
  }

  // Factory constructors per casi comuni
  static void success(
    BuildContext context, {
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: ToastType.success,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void error(
    BuildContext context, {
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: ToastType.error,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void warning(
    BuildContext context, {
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: ToastType.warning,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void info(
    BuildContext context, {
    required String message,
    VoidCallback? onAction,
    String? actionLabel,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: ToastType.info,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration ?? const Duration(seconds: 4),
    );
  }
} 