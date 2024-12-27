import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppGrid extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final List<Widget>? actions;
  final int crossAxisCount;
  final double spacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final bool showDividers;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final double? maxWidth;
  final ScrollController? scrollController;
  final bool shrinkWrap;

  const AppGrid({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.actions,
    required this.crossAxisCount,
    this.spacing = 16.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.showDividers = false,
    this.backgroundColor,
    this.borderRadius,
    this.maxWidth,
    this.scrollController,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints:
          maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || leading != null) ...[
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: borderRadius != null
                    ? BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radii.lg))
                    : null,
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
                          title!,
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
                  if (actions != null) ...[
                    ...actions!.map((action) => Padding(
                          padding: EdgeInsets.only(left: AppTheme.spacing.sm),
                          child: action,
                        )),
                  ],
                ],
              ),
            ),
            if (showDividers)
              Divider(
                height: 1,
                color: colorScheme.outline.withAlpha(26),
              ),
          ],

          // Grid Content
          Flexible(
            child: GridView.builder(
              controller: scrollController,
              shrinkWrap: shrinkWrap,
              padding: padding ?? EdgeInsets.all(AppTheme.spacing.lg),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
            ),
          ),
        ],
      ),
    );
  }

  // Factory constructors per casi comuni
  factory AppGrid.card({
    required String title,
    String? subtitle,
    Widget? leading,
    required List<Widget> children,
    List<Widget>? actions,
    required int crossAxisCount,
    double spacing = 16.0,
    double childAspectRatio = 1.0,
    double? maxWidth,
  }) {
    return AppGrid(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      crossAxisCount: crossAxisCount,
      spacing: spacing,
      childAspectRatio: childAspectRatio,
      maxWidth: maxWidth,
      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      showDividers: true,
      children: children,
    );
  }

  factory AppGrid.section({
    required String title,
    String? subtitle,
    required List<Widget> children,
    required int crossAxisCount,
    double spacing = 16.0,
    double childAspectRatio = 1.0,
    EdgeInsets? padding,
  }) {
    return AppGrid(
      title: title,
      subtitle: subtitle,
      crossAxisCount: crossAxisCount,
      spacing: spacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      backgroundColor: Colors.transparent,
      borderRadius: null,
      children: children,
    );
  }

  factory AppGrid.responsive({
    String? title,
    String? subtitle,
    Widget? leading,
    required List<Widget> children,
    List<Widget>? actions,
    required BuildContext context,
    double desiredMinWidth = 300,
    double spacing = 16.0,
    double childAspectRatio = 1.0,
  }) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = (width / desiredMinWidth).floor();

    return AppGrid(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      crossAxisCount: crossAxisCount > 0 ? crossAxisCount : 1,
      spacing: spacing,
      childAspectRatio: childAspectRatio,
      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      showDividers: true,
      children: children,
    );
  }
}

// Helper widget per celle della griglia
class GridCell extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool enabled;
  final Widget? trailing;

  const GridCell({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isSelected = false,
    this.enabled = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withAlpha(76)
            : colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withAlpha(26),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(height: AppTheme.spacing.md),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: enabled
                        ? (isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface)
                        : colorScheme.onSurfaceVariant.withAlpha(128),
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppTheme.spacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withAlpha(128),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (trailing != null) ...[
                  SizedBox(height: AppTheme.spacing.md),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
