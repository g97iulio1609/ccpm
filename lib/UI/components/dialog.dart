import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final bool showDividers;
  final double? maxWidth;
  final double? maxHeight;
  final bool barrierDismissible;
  final Color? backgroundColor;

  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.actions,
    this.contentPadding,
    this.showDividers = true,
    this.maxWidth,
    this.maxHeight,
    this.barrierDismissible = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 560,
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
          boxShadow: AppTheme.elevations.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: AppTheme.spacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: AppTheme.spacing.xs),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (barrierDismissible)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: contentPadding ?? EdgeInsets.all(AppTheme.spacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < children.length; i++) ...[
                      children[i],
                      if (showDividers && i < children.length - 1) ...[
                        SizedBox(height: AppTheme.spacing.lg),
                        if (i < children.length - 1)
                          Divider(
                            color: colorScheme.outline.withOpacity(0.1),
                          ),
                        SizedBox(height: AppTheme.spacing.lg),
                      ] else if (i < children.length - 1)
                        SizedBox(height: AppTheme.spacing.lg),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            if (actions != null) ...[
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(76),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppTheme.radii.xl),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions!.length; i++) ...[
                      actions![i],
                      if (i < actions!.length - 1)
                        SizedBox(width: AppTheme.spacing.md),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods per creare azioni comuni
  static Widget buildCancelButton({
    required BuildContext context,
    String label = 'Annulla',
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextButton(
      onPressed: onPressed ?? () => Navigator.pop(context),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.lg,
          vertical: AppTheme.spacing.md,
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static Widget buildActionButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isDestructive = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary && !isDestructive
            ? LinearGradient(
                colors: [
                  isDestructive ? colorScheme.error : colorScheme.primary,
                  (isDestructive ? colorScheme.error : colorScheme.primary)
                      .withAlpha(204),
                ],
              )
            : null,
        color: !isPrimary
            ? colorScheme.surfaceContainerHighest.withAlpha(76)
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color:
                      (isDestructive ? colorScheme.error : colorScheme.primary)
                          .withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.lg,
              vertical: AppTheme.spacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
            ),
          ),
        ),
      ),
    );
  }

  // Helper method per mostrare un dialogo di conferma
  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: (isDestructive ? colorScheme.error : colorScheme.primary)
                .withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            icon ??
                (isDestructive
                    ? Icons.warning_amber_rounded
                    : Icons.help_outline),
            color: isDestructive ? colorScheme.error : colorScheme.primary,
            size: 24,
          ),
        ),
        actions: [
          buildCancelButton(
            context: context,
            label: cancelLabel ?? 'Annulla',
          ),
          buildActionButton(
            context: context,
            label: confirmLabel ?? 'Conferma',
            onPressed: () => Navigator.pop(context, true),
            isDestructive: isDestructive,
          ),
        ],
        children: [
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
