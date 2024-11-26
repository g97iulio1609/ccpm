import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class BottomMenuItem {
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool isDestructive;

  const BottomMenuItem({
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.isDestructive = false,
  });
}

class BottomMenu extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<BottomMenuItem>? items;
  final List<Widget>? actions;
  final double? height;
  final bool isDismissible;
  final Widget? leading;

  const BottomMenu({
    super.key,
    required this.title,
    this.subtitle,
    this.items,
    this.actions,
    this.height,
    this.isDismissible = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: height ?? MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radii.full),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
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
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: colorScheme.outline.withOpacity(0.1),
          ),

          // Content
          if (items != null && items!.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(
                  vertical: AppTheme.spacing.md,
                ),
                itemCount: items!.length,
                itemBuilder: (context, index) {
                  final item = items![index];
                  return ListTile(
                    leading: item.leading ??
                        (item.icon != null
                            ? Icon(
                                item.icon,
                                color: item.isDestructive
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              )
                            : null),
                    title: Text(
                      item.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: item.isDestructive
                            ? colorScheme.error
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(
                            item.subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    trailing: item.trailing,
                    onTap: item.onTap,
                  );
                },
              ),
            ),

          // Actions
          if (actions != null && actions!.isNotEmpty) ...[
            Container(
              height: 1,
              color: colorScheme.outline.withOpacity(0.1),
            ),
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              child: Column(
                children: [
                  for (var i = 0; i < actions!.length; i++) ...[
                    if (i > 0) SizedBox(height: AppTheme.spacing.md),
                    actions![i],
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
