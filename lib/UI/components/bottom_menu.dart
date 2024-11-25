import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class BottomMenu extends StatelessWidget {
  final List<BottomMenuItem> items;
  final String? title;
  final String? subtitle;
  final Widget? leading;

  const BottomMenu({
    super.key,
    required this.items,
    this.title,
    this.subtitle,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.xl),
        ),
        boxShadow: AppTheme.elevations.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.only(top: AppTheme.spacing.md),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
              ),
            ),
          ),

          if (title != null || subtitle != null || leading != null)
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
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
                        if (title != null)
                          Text(
                            title!,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Menu Items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isDestructive = item.isDestructive ?? false;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        item.onTap();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing.lg,
                          vertical: AppTheme.spacing.md,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacing.sm),
                              decoration: BoxDecoration(
                                color: (isDestructive
                                        ? colorScheme.error
                                        : colorScheme.primary)
                                    .withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radii.md),
                              ),
                              child: Icon(
                                item.icon,
                                color: isDestructive
                                    ? colorScheme.error
                                    : colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: AppTheme.spacing.md),
                            Expanded(
                              child: Text(
                                item.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: isDestructive
                                      ? colorScheme.error
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (item.trailing != null) ...[
                              SizedBox(width: AppTheme.spacing.sm),
                              item.trailing!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.lg,
                      ),
                      child: Divider(
                        height: 1,
                        color: colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                ],
              );
            },
          ),

          // Bottom Padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class BottomMenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool? isDestructive;
  final Widget? trailing;

  const BottomMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive,
    this.trailing,
  });
} 