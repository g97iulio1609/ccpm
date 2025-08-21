import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

enum SnackbarType { success, error, warning, info }

class AppSnackbar extends StatelessWidget {
  final String message;
  final SnackbarType type;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Duration duration;
  final VoidCallback? onDismiss;
  final bool showProgressBar;
  final double? progressValue;

  const AppSnackbar({
    super.key,
    required this.message,
    this.type = SnackbarType.info,
    this.icon,
    this.onAction,
    this.actionLabel,
    this.duration = const Duration(seconds: 4),
    this.onDismiss,
    this.showProgressBar = false,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final snackbarColor = _getSnackbarColor(colorScheme);
    final snackbarIcon = icon ?? _getSnackbarIcon();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppTheme.spacing.xl, vertical: AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
        boxShadow: [
          BoxShadow(color: snackbarColor.withAlpha(26), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Indicator
          if (showProgressBar) ...[
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: snackbarColor.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(snackbarColor),
              minHeight: 2,
            ),
          ],

          // Content
          Material(
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
                          color: snackbarColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(AppTheme.radii.md),
                        ),
                        child: Icon(snackbarIcon, color: snackbarColor, size: 20),
                      ),
                      SizedBox(width: AppTheme.spacing.md),
                      Expanded(
                        child: Text(
                          message,
                          style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
                        ),
                      ),
                      if (onDismiss != null) ...[
                        SizedBox(width: AppTheme.spacing.sm),
                        IconButton(
                          icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant, size: 20),
                          onPressed: onDismiss,
                        ),
                      ],
                    ],
                  ),
                ),

                // Action Button
                if (onAction != null && actionLabel != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: colorScheme.outline.withAlpha(26))),
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
                              color: snackbarColor,
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
        ],
      ),
    );
  }

  Color _getSnackbarColor(ColorScheme colorScheme) {
    switch (type) {
      case SnackbarType.success:
        return colorScheme.tertiary;
      case SnackbarType.error:
        return colorScheme.error;
      case SnackbarType.warning:
        return colorScheme.secondary;
      case SnackbarType.info:
        return colorScheme.primary;
    }
  }

  IconData _getSnackbarIcon() {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle_outline;
      case SnackbarType.error:
        return Icons.error_outline;
      case SnackbarType.warning:
        return Icons.warning_amber_outlined;
      case SnackbarType.info:
        return Icons.info_outline;
    }
  }

  // Helper method per mostrare uno snackbar
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onDismiss,
    bool showProgressBar = false,
    double? progressValue,
  }) {
    final snackBar = SnackBar(
      content: AppSnackbar(
        message: message,
        type: type,
        icon: icon,
        onAction: onAction,
        actionLabel: actionLabel,
        duration: duration,
        onDismiss: onDismiss,
        showProgressBar: showProgressBar,
        progressValue: progressValue,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
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
      type: SnackbarType.success,
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
      type: SnackbarType.error,
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
      type: SnackbarType.warning,
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
      type: SnackbarType.info,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  static void showProgress(
    BuildContext context, {
    required String message,
    required double progressValue,
    VoidCallback? onAction,
    String? actionLabel,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: SnackbarType.info,
      onAction: onAction,
      actionLabel: actionLabel,
      duration: duration ?? const Duration(seconds: 4),
      showProgressBar: true,
      progressValue: progressValue,
    );
  }
}
