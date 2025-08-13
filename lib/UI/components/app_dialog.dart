import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/glass.dart';

class AppDialog extends StatelessWidget {
  final Widget? title;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? contentPadding;

  const AppDialog({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    required this.child,
    this.actions,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final header = (title != null || leading != null || trailing != null)
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
                if (leading != null && title != null)
                  SizedBox(width: AppTheme.spacing.md),
                if (title != null)
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: theme.textTheme.titleLarge,
                      child: title!,
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

    final content = Padding(
      padding: contentPadding ?? EdgeInsets.all(AppTheme.spacing.xl),
      child: child,
    );

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
  Widget? title,
  Widget? leading,
  Widget? trailing,
  required Widget child,
  List<Widget>? actions,
  EdgeInsetsGeometry? contentPadding,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      leading: leading,
      trailing: trailing,
      child: child,
      actions: actions,
      contentPadding: contentPadding,
    ),
  );
}
