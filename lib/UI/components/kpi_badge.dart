import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class KpiBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;

  const KpiBadge({super.key, required this.text, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = color ?? colorScheme.primary;
    final background = base.withAlpha(76);
    final foreground = base.computeLuminance() > 0.5 ? Colors.black : base;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            SizedBox(width: AppTheme.spacing.xs),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
