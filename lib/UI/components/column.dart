import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppColumn extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final List<Widget>? actions;
  final bool showDividers;
  final bool isSelected;
  final bool enabled;
  final EdgeInsets? contentPadding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double? maxWidth;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  const AppColumn({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.actions,
    this.showDividers = false,
    this.isSelected = false,
    this.enabled = true,
    this.contentPadding,
    this.backgroundColor,
    this.borderRadius,
    this.maxWidth,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints:
          maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isSelected
                ? colorScheme.primaryContainer.withAlpha(76)
                : colorScheme.surfaceContainerHighest.withAlpha(76)),
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: enabled ? AppTheme.elevations.small : null,
      ),
      child: Column(
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          if (title != null || leading != null) ...[
            Padding(
              padding: contentPadding ?? EdgeInsets.all(AppTheme.spacing.lg),
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
                        if (title != null)
                          Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: enabled
                                  ? (isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface)
                                  : colorScheme.onSurfaceVariant.withAlpha(128),
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                          ),
                        if (title != null && subtitle != null)
                          SizedBox(height: AppTheme.spacing.xs),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: enabled
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurfaceVariant.withAlpha(128),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (actions != null) ...[
                    ...actions!.map((action) => Padding(
                          padding: EdgeInsets.only(left: AppTheme.spacing.sm),
                          child: action,
                        )),
                  ],
                ],
              ),
            ),
            if (showDividers && children.isNotEmpty)
              Divider(
                color: colorScheme.outline.withOpacity(0.1),
                height: 1,
              ),
          ],
          Padding(
            padding: contentPadding ?? EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisSize: mainAxisSize,
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (showDividers && i < children.length - 1) ...[
                    SizedBox(height: AppTheme.spacing.md),
                    Divider(
                      color: colorScheme.outline.withOpacity(0.1),
                      height: 1,
                    ),
                    SizedBox(height: AppTheme.spacing.md),
                  ] else if (i < children.length - 1)
                    SizedBox(height: AppTheme.spacing.md),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Factory constructors per casi comuni
  factory AppColumn.card({
    required String title,
    String? subtitle,
    Widget? leading,
    required List<Widget> children,
    List<Widget>? actions,
    bool showDividers = true,
    double? maxWidth,
  }) {
    return AppColumn(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      showDividers: showDividers,
      maxWidth: maxWidth,
      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      backgroundColor: null,
      children: children,
    );
  }

  factory AppColumn.section({
    required String title,
    String? subtitle,
    required List<Widget> children,
    bool showDividers = false,
    EdgeInsets? contentPadding,
  }) {
    return AppColumn(
      title: title,
      subtitle: subtitle,
      showDividers: showDividers,
      contentPadding: contentPadding,
      backgroundColor: Colors.transparent,
      borderRadius: null,
      children: children,
    );
  }

  factory AppColumn.group({
    required List<Widget> children,
    bool showDividers = true,
    EdgeInsets? contentPadding,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return AppColumn(
      showDividers: showDividers,
      contentPadding: contentPadding ?? EdgeInsets.all(AppTheme.spacing.md),
      backgroundColor: Colors.transparent,
      borderRadius: null,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}
