import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppRow extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showDivider;
  final bool isSelected;
  final bool enabled;
  final EdgeInsets? contentPadding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const AppRow({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.actions,
    this.onTap,
    this.onLongPress,
    this.showDivider = false,
    this.isSelected = false,
    this.enabled = true,
    this.contentPadding,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: backgroundColor ??
                (isSelected
                    ? colorScheme.primaryContainer.withAlpha(76)
                    : colorScheme.surfaceContainerHighest.withAlpha(76)),
            borderRadius:
                borderRadius ?? BorderRadius.circular(AppTheme.radii.lg),
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
              onLongPress: enabled ? onLongPress : null,
              borderRadius:
                  borderRadius ?? BorderRadius.circular(AppTheme.radii.lg),
              child: Padding(
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
                                    : colorScheme.onSurfaceVariant
                                        .withAlpha(128),
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
                                    : colorScheme.onSurfaceVariant
                                        .withAlpha(128),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      SizedBox(width: AppTheme.spacing.md),
                      trailing!,
                    ],
                    if (actions != null) ...[
                      SizedBox(width: AppTheme.spacing.md),
                      ...actions!.map((action) => Padding(
                            padding: EdgeInsets.only(left: AppTheme.spacing.sm),
                            child: action,
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: colorScheme.outline.withAlpha(26),
            height: 1,
          ),
      ],
    );
  }

  // Factory constructors per casi comuni
  factory AppRow.simple({
    required String title,
    String? subtitle,
    IconData? icon,
    VoidCallback? onTap,
    bool showDivider = false,
  }) {
    return AppRow(
      title: title,
      subtitle: subtitle,
      leading: icon != null ? Icon(icon) : null,
      onTap: onTap,
      showDivider: showDivider,
    );
  }

  factory AppRow.withBadge({
    required String title,
    required String badgeText,
    Color? badgeColor,
    IconData? icon,
    VoidCallback? onTap,
    bool showDivider = false,
  }) {
    return AppRow(
      title: title,
      leading: icon != null ? Icon(icon) : null,
      trailing: _Badge(
        text: badgeText,
        color: badgeColor,
      ),
      onTap: onTap,
      showDivider: showDivider,
    );
  }

  factory AppRow.withSwitch({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
    bool showDivider = false,
  }) {
    return AppRow(
      title: title,
      subtitle: subtitle,
      leading: icon != null ? Icon(icon) : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
      showDivider: showDivider,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color? color;

  const _Badge({
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final badgeColor = color ?? colorScheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(51),
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
