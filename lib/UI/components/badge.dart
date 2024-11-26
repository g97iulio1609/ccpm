import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

enum AppBadgeVariant {
  filled, // Badge con sfondo pieno
  outlined, // Badge con bordo
  subtle, // Badge con sfondo trasparente
  gradient // Badge con sfondo sfumato
}

enum AppBadgeSize {
  small, // Badge piccolo
  medium, // Badge medio (default)
  large // Badge grande
}

enum AppBadgeStatus {
  primary, // Stato primario (default)
  success, // Stato successo
  warning, // Stato avviso
  error, // Stato errore
  info, // Stato informativo
  neutral // Stato neutro
}

class AppBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final AppBadgeVariant variant;
  final AppBadgeSize size;
  final AppBadgeStatus status;
  final Color? customColor;
  final VoidCallback? onTap;
  final bool isInteractive;

  const AppBadge({
    super.key,
    required this.text,
    this.icon,
    this.variant = AppBadgeVariant.filled,
    this.size = AppBadgeSize.medium,
    this.status = AppBadgeStatus.primary,
    this.customColor,
    this.onTap,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final badgeColor = _getBadgeColor(colorScheme);
    final textColor = _getTextColor(colorScheme);
    final padding = _getPadding();
    final fontSize = _getFontSize(theme);
    final iconSize = _getIconSize();
    final height = _getHeight();
    final borderRadius = _getBorderRadius();

    Widget badge = Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: variant == AppBadgeVariant.gradient
            ? LinearGradient(
                colors: [
                  badgeColor,
                  badgeColor.withOpacity(0.8),
                ],
              )
            : null,
        color: variant == AppBadgeVariant.filled
            ? badgeColor
            : variant == AppBadgeVariant.subtle
                ? badgeColor.withOpacity(0.12)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: variant == AppBadgeVariant.outlined
            ? Border.all(
                color: badgeColor,
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor,
              size: iconSize,
            ),
            SizedBox(width: AppTheme.spacing.xxs),
          ],
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );

    if (isInteractive && onTap != null) {
      badge = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: badge,
        ),
      );
    }

    return badge;
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppBadgeSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.xs,
          vertical: AppTheme.spacing.xxs,
        );
      case AppBadgeSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.sm,
          vertical: AppTheme.spacing.xs,
        );
      case AppBadgeSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.sm,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case AppBadgeSize.small:
        return 20;
      case AppBadgeSize.medium:
        return 24;
      case AppBadgeSize.large:
        return 32;
    }
  }

  double _getFontSize(ThemeData theme) {
    switch (size) {
      case AppBadgeSize.small:
        return 11;
      case AppBadgeSize.medium:
        return 12;
      case AppBadgeSize.large:
        return 14;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppBadgeSize.small:
        return 12;
      case AppBadgeSize.medium:
        return 14;
      case AppBadgeSize.large:
        return 16;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case AppBadgeSize.small:
        return AppTheme.radii.full;
      case AppBadgeSize.medium:
        return AppTheme.radii.full;
      case AppBadgeSize.large:
        return AppTheme.radii.full;
    }
  }

  Color _getBadgeColor(ColorScheme colorScheme) {
    if (customColor != null) return customColor!;

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
    }
  }

  Color _getTextColor(ColorScheme colorScheme) {
    if (variant == AppBadgeVariant.filled ||
        variant == AppBadgeVariant.gradient) {
      switch (status) {
        case AppBadgeStatus.primary:
          return colorScheme.onPrimary;
        case AppBadgeStatus.success:
          return colorScheme.onTertiary;
        case AppBadgeStatus.warning:
          return Colors.white;
        case AppBadgeStatus.error:
          return colorScheme.onError;
        case AppBadgeStatus.info:
          return colorScheme.onSecondary;
        case AppBadgeStatus.neutral:
          return colorScheme.onSurface;
      }
    } else {
      return _getBadgeColor(colorScheme);
    }
  }

  // Factory constructors per casi comuni
  factory AppBadge.status({
    required String text,
    required AppBadgeStatus status,
    IconData? icon,
  }) {
    return AppBadge(
      text: text,
      icon: icon,
      status: status,
      variant: AppBadgeVariant.filled,
      size: AppBadgeSize.medium,
    );
  }

  factory AppBadge.subtle({
    required String text,
    required AppBadgeStatus status,
    IconData? icon,
  }) {
    return AppBadge(
      text: text,
      icon: icon,
      status: status,
      variant: AppBadgeVariant.subtle,
      size: AppBadgeSize.medium,
    );
  }

  factory AppBadge.outlined({
    required String text,
    required AppBadgeStatus status,
    IconData? icon,
  }) {
    return AppBadge(
      text: text,
      icon: icon,
      status: status,
      variant: AppBadgeVariant.outlined,
      size: AppBadgeSize.medium,
    );
  }

  factory AppBadge.gradient({
    required String text,
    required AppBadgeStatus status,
    IconData? icon,
  }) {
    return AppBadge(
      text: text,
      icon: icon,
      status: status,
      variant: AppBadgeVariant.gradient,
      size: AppBadgeSize.medium,
    );
  }
}
