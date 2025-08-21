import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onPrimaryAction;
  final String? primaryActionLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onPrimaryAction,
    this.primaryActionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(76),
              borderRadius: BorderRadius.circular(AppTheme.radii.xl),
            ),
            child: Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
          ),
          SizedBox(height: AppTheme.spacing.lg),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppTheme.spacing.sm),
            Text(
              subtitle!,
              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          if (onPrimaryAction != null && primaryActionLabel != null) ...[
            SizedBox(height: AppTheme.spacing.lg),
            FilledButton.icon(
              onPressed: onPrimaryAction,
              icon: const Icon(Icons.add),
              label: Text(primaryActionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
