import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/UI/components/button.dart';

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
    final media = MediaQuery.of(context);
    final viewInsets = media.viewInsets;
    // Build an inset padding that respects the keyboard (viewInsets)
    final effectiveInsetPadding = EdgeInsets.only(
      left: AppTheme.spacing.xl + viewInsets.left,
      right: AppTheme.spacing.xl + viewInsets.right,
      top: AppTheme.spacing.lg + viewInsets.top,
      bottom: AppTheme.spacing.lg + viewInsets.bottom,
    );

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

    // Content should always be scrollable to avoid overflows when space is tight
    final Widget content = Flexible(
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
          child: contentCore,
        ),
      ),
    );

    // Compute a robust max dialog height that respects keyboard and insets
    final availableHeight = media.size.height - effectiveInsetPadding.vertical;
    final maxDialogHeight = math.max(
      0.0,
      (maxHeight != null)
          ? math.min(maxHeight!, availableHeight)
          : availableHeight,
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: effectiveInsetPadding,
      child: GlassLite(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Cap height to the available area to enable scrolling inside
              maxHeight: maxDialogHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [header, content, footer],
            ),
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
    return AppButton(
      label: label,
      variant: AppButtonVariant.subtle,
      onPressed: onPressed ?? () => Navigator.of(context, rootNavigator: true).pop(),
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
    if (isDestructive) {
      return AppButton(
        label: label,
        icon: icon,
        onPressed: onPressed,
        glass: false,
        variant: AppButtonVariant.filled,
        backgroundColor: colorScheme.error,
        iconColor: colorScheme.onError,
      );
    }
    return AppButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      variant: isPrimary ? AppButtonVariant.primary : AppButtonVariant.subtle,
    );
  }
}
