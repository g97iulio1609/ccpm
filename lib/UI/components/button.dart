import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/glass.dart';

enum AppButtonVariant { filled, outline, ghost, subtle, primary, secondary }

enum AppButtonSize { sm, md, lg, full }

class AppButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool block;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool glass;

  const AppButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.md,
    this.block = false,
    this.isLoading = false,
    this.backgroundColor,
    this.iconColor,
    this.glass = true,
  }) : assert(label != null || icon != null);

  factory AppButton.icon({
    required IconData icon,
    VoidCallback? onPressed,
    AppButtonVariant variant = AppButtonVariant.filled,
    AppButtonSize size = AppButtonSize.md,
    bool isLoading = false,
    Color? backgroundColor,
    Color? iconColor,
    bool glass = true,
  }) {
    return AppButton(
      icon: icon,
      onPressed: onPressed,
      variant: variant,
      size: size,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      iconColor: iconColor,
      glass: glass,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double height = size == AppButtonSize.sm
        ? 32
        : size == AppButtonSize.md
        ? 40
        : 48;
    final double iconSize = size == AppButtonSize.sm
        ? 16
        : size == AppButtonSize.md
        ? 20
        : 24;
    final double fontSize = size == AppButtonSize.sm
        ? 14
        : size == AppButtonSize.md
        ? 16
        : 18;
    final double horizontalPadding = size == AppButtonSize.sm
        ? 12
        : size == AppButtonSize.md
        ? 16
        : 24;

    Color getBackgroundColor() {
      if (backgroundColor != null) return backgroundColor!;
      switch (variant) {
        case AppButtonVariant.filled:
        case AppButtonVariant.primary:
          return glass ? Colors.transparent : colorScheme.primary;
        case AppButtonVariant.outline:
        case AppButtonVariant.ghost:
          return Colors.transparent;
        case AppButtonVariant.subtle:
          return glass ? Colors.transparent : colorScheme.primaryContainer.withAlpha(77);
        case AppButtonVariant.secondary:
          return glass ? Colors.transparent : colorScheme.secondary;
      }
    }

    Color getForegroundColor() {
      if (iconColor != null) return iconColor!;
      switch (variant) {
        case AppButtonVariant.filled:
        case AppButtonVariant.primary:
          // In modalità glass lo sfondo è trasparente: usare il primario per garantire contrasto
          return glass ? colorScheme.primary : colorScheme.onPrimary;
        case AppButtonVariant.outline:
        case AppButtonVariant.ghost:
        case AppButtonVariant.subtle:
          return colorScheme.primary;
        case AppButtonVariant.secondary:
          return colorScheme.onSecondary;
      }
    }

    BorderSide? getBorderSide() {
      switch (variant) {
        case AppButtonVariant.outline:
          return BorderSide(color: colorScheme.primary, width: 1.5);
        default:
          return null;
      }
    }

    Widget buttonChild = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(getForegroundColor()),
            ),
          ),
          if (label != null) SizedBox(width: AppTheme.spacing.sm),
        ] else ...[
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: getForegroundColor()),
            if (label != null) SizedBox(width: AppTheme.spacing.sm),
          ],
        ],
        if (label != null)
          Text(
            label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: getForegroundColor(),
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );

    final coreButton = SizedBox(
      width: block ? double.infinity : null,
      height: height,
      child: MaterialButton(
        onPressed: isLoading ? null : onPressed,
        color: getBackgroundColor(),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          side: getBorderSide() ?? BorderSide.none,
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: buttonChild,
      ),
    );

    final shouldUseGlass =
        glass && variant != AppButtonVariant.outline && variant != AppButtonVariant.ghost;
    if (!shouldUseGlass) return coreButton;

    return GlassLite(
      padding: EdgeInsets.zero,
      radius: AppTheme.radii.lg,
      tint: colorScheme.surfaceContainerHighest.withAlpha(72),
      child: coreButton,
    );
  }
}
