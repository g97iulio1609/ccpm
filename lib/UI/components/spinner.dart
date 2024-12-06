import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppSpinner extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;
  final double strokeWidth;
  final bool overlay;

  const AppSpinner({
    super.key,
    this.message,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.overlay = false,
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
                ),
              ),
              if (message != null) ...[
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
}
