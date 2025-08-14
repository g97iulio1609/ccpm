import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/glass.dart';

class AppDialog extends StatelessWidget {
  // Title/subtitle accettano sia Widget che String per compat
  final dynamic title;
  final dynamic subtitle;
  final Widget? leading;
  final Widget? trailing;
  // Compat: puoi passare un child singolo o una lista di children
  final Widget? child;
  final List<Widget>? children;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;
  // Compat: vincoli opzionali
  final double? maxWidth;
  final double? maxHeight;

  const AppDialog({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.child,
    this.children,
    this.actions,
    this.contentPadding,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Widget? resolvedTitleWidget = title == null
        ? null
        : (title is Widget ? title as Widget : Text(title.toString()));
    final Widget? resolvedSubtitleWidget = subtitle == null
        ? null
        : (subtitle is Widget
              ? subtitle as Widget
              : Text(
                  subtitle.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ));

    final header =
        (resolvedTitleWidget != null || leading != null || trailing != null)
        ? Container(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radii.xl),
              ),
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withAlpha(26)),
              ),
            ),
            child: Row(
              children: [
                if (leading != null) leading!,
                if (leading != null && resolvedTitleWidget != null)
                  SizedBox(width: AppTheme.spacing.md),
                if (resolvedTitleWidget != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle.merge(
                          style: theme.textTheme.titleLarge,
                          child: resolvedTitleWidget,
                        ),
                        if (resolvedSubtitleWidget != null) ...[
                          SizedBox(height: AppTheme.spacing.xs),
                          resolvedSubtitleWidget,
                        ],
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          )
        : const SizedBox.shrink();

    final footer = (actions != null && actions!.isNotEmpty)
        ? Container(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(AppTheme.radii.xl),
              ),
              border: Border(
                top: BorderSide(color: colorScheme.outline.withAlpha(26)),
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
          )
        : const SizedBox.shrink();

    final Widget effectiveChild =
        child ??
        (children != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children!,
              )
            : const SizedBox.shrink());

    final contentCore = Padding(
      padding: contentPadding ?? EdgeInsets.all(AppTheme.spacing.xl),
      child: effectiveChild,
    );

    final content = (maxWidth != null || maxHeight != null)
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? double.infinity,
              maxHeight: maxHeight ?? double.infinity,
            ),
            child: contentCore,
          )
        : contentCore;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.xl,
        vertical: AppTheme.spacing.lg,
      ),
      child: GlassLite(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [header, content, footer],
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  dynamic title,
  dynamic subtitle,
  Widget? leading,
  Widget? trailing,
  Widget? child,
  List<Widget>? children,
  List<Widget>? actions,
  EdgeInsetsGeometry? contentPadding,
  double? maxWidth,
  double? maxHeight,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      actions: actions,
      contentPadding: contentPadding,
      child: child,
      children: children,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    ),
  );
}

// Helper compatibili per ridurre duplicazioni nei call-site
extension AppDialogHelpers on AppDialog {
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
                          .withAlpha(51),
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
}
