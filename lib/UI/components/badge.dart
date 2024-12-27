import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

enum AppBadgeVariant {
  filled,
  outline,
  subtle,
  gradient,
}

enum AppBadgeSize {
  small,
  medium,
  large,
}

enum AppBadgeStatus {
  primary,
  success,
  warning,
  error,
  info,
  neutral,
}

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final AppBadgeStatus? status;
  final AppBadgeSize size;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.filled,
    this.status,
    this.size = AppBadgeSize.medium,
    this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color getBadgeColor() {
      if (color != null) return color!;

      switch (status) {
        case AppBadgeStatus.primary:
          return colorScheme.primary;
        case AppBadgeStatus.success:
          return colorScheme.tertiary;
        case AppBadgeStatus.warning:
          return const Color(0xFFF59E0B);
        case AppBadgeStatus.error:
          return colorScheme.error;
        case AppBadgeStatus.info:
          return colorScheme.secondary;
        case AppBadgeStatus.neutral:
          return colorScheme.surfaceContainerHighest;
        default:
          return colorScheme.primary;
      }
    }

    final badgeColor = getBadgeColor();
    final double textSize = size == AppBadgeSize.small
        ? 11
        : size == AppBadgeSize.medium
            ? 12
            : 14;

    BoxDecoration getDecoration() {
      switch (variant) {
        case AppBadgeVariant.filled:
          return BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          );
        case AppBadgeVariant.outline:
          return BoxDecoration(
            color: badgeColor.withAlpha(26),
            border: Border.all(color: badgeColor),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          );
        case AppBadgeVariant.subtle:
          return BoxDecoration(
            color: badgeColor.withAlpha(51),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          );
        case AppBadgeVariant.gradient:
          return BoxDecoration(
            gradient: LinearGradient(
              colors: [badgeColor, badgeColor.withAlpha(204)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          );
      }
    }

    Color getTextColor() {
      switch (variant) {
        case AppBadgeVariant.filled:
        case AppBadgeVariant.gradient:
          return colorScheme.onPrimary;
        case AppBadgeVariant.outline:
        case AppBadgeVariant.subtle:
          return badgeColor;
      }
    }

    Widget badgeContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: textSize + 2,
            color: getTextColor(),
          ),
          SizedBox(width: AppTheme.spacing.xs),
        ],
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: getTextColor(),
            fontSize: textSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: getDecoration(),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
                child: badgeContent,
              ),
            )
          : badgeContent,
    );
  }
}
