import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.sm,
            vertical: AppTheme.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(77),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.primary,
            size: 18,
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
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
        if (trailing != null) trailing!,
      ],
    );
  }
}
