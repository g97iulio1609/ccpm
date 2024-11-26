import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

enum AppButtonVariant {
  primary, // Bottone principale con sfondo pieno
  secondary, // Bottone secondario con sfondo trasparente
  outlined, // Bottone con bordo
  text, // Bottone solo testo
  icon, // Bottone solo icona
}

enum AppButtonSize {
  small, // Bottone piccolo
  medium, // Bottone medio (default)
  large, // Bottone grande
  full, // Bottone a larghezza piena
}

class AppButton extends StatelessWidget {
  final String? label;
  final VoidCallback onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Color? customColor;
  final EdgeInsets? customPadding;
  final double? customWidth;
  final double? customHeight;
  final double? customBorderRadius;
  final TextStyle? customTextStyle;

  const AppButton({
    super.key,
    this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.customColor,
    this.customPadding,
    this.customWidth,
    this.customHeight,
    this.customBorderRadius,
    this.customTextStyle,
  }) : assert(label != null || icon != null,
            'Either label or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calcola dimensioni in base alla size
    final padding = customPadding ?? _getPadding();
    final height = customHeight ?? _getHeight();
    final width = customWidth ?? _getWidth();
    final borderRadius = customBorderRadius ?? AppTheme.radii.lg;

    // Calcola colori in base alla variant
    final backgroundColor = _getBackgroundColor(colorScheme);
    final foregroundColor = _getForegroundColor(colorScheme);
    final borderColor = _getBorderColor(colorScheme);

    // Costruisce il contenuto del bottone
    Widget content = Row(
      mainAxisSize:
          size == AppButtonSize.full ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(
              icon,
              color: foregroundColor,
              size: _getIconSize(),
            ),
            if (label != null) SizedBox(width: AppTheme.spacing.sm),
          ],
          if (label != null)
            Text(
              label!,
              style: customTextStyle ??
                  theme.textTheme.labelLarge?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
        ],
      ],
    );

    // Costruisce il container del bottone
    Widget button = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: variant == AppButtonVariant.primary
            ? LinearGradient(
                colors: [
                  backgroundColor,
                  backgroundColor.withOpacity(0.8),
                ],
              )
            : null,
        color: variant != AppButtonVariant.primary ? backgroundColor : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: variant == AppButtonVariant.outlined
            ? Border.all(
                color: borderColor,
                width: 1.5,
              )
            : null,
        boxShadow: variant == AppButtonVariant.primary
            ? [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled || isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: content,
          ),
        ),
      ),
    );

    // Applica opacità se disabilitato
    if (isDisabled) {
      button = Opacity(
        opacity: 0.5,
        child: button,
      );
    }

    return button;
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.xs,
        );
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.lg,
          vertical: AppTheme.spacing.sm,
        );
      case AppButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.xl,
          vertical: AppTheme.spacing.md,
        );
      case AppButtonSize.full:
        return EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.lg,
          vertical: AppTheme.spacing.md,
        );
    }
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 32;
      case AppButtonSize.medium:
        return 40;
      case AppButtonSize.large:
        return 48;
      case AppButtonSize.full:
        return 48;
    }
  }

  double? _getWidth() {
    return size == AppButtonSize.full ? double.infinity : null;
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 20;
      case AppButtonSize.large:
        return 24;
      case AppButtonSize.full:
        return 24;
    }
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (customColor != null) return customColor!;

    switch (variant) {
      case AppButtonVariant.primary:
        return colorScheme.primary;
      case AppButtonVariant.secondary:
        return colorScheme.surfaceContainerHighest.withOpacity(0.3);
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
      case AppButtonVariant.icon:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(ColorScheme colorScheme) {
    if (customColor != null) {
      return variant == AppButtonVariant.primary ? Colors.white : customColor!;
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return colorScheme.onPrimary;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
      case AppButtonVariant.icon:
        return colorScheme.primary;
    }
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    return customColor ?? colorScheme.primary;
  }

  // Factory constructors per casi comuni
  factory AppButton.primary({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: AppButtonVariant.primary,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
    );
  }

  factory AppButton.secondary({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: AppButtonVariant.secondary,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
    );
  }

  factory AppButton.outlined({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isLoading = false,
    bool isDisabled = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: AppButtonVariant.outlined,
      size: size,
      isLoading: isLoading,
      isDisabled: isDisabled,
    );
  }

  factory AppButton.text({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.medium,
    bool isDisabled = false,
  }) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      variant: AppButtonVariant.text,
      size: size,
      isDisabled: isDisabled,
    );
  }

  factory AppButton.icon({
    required IconData icon,
    required VoidCallback onPressed,
    AppButtonSize size = AppButtonSize.medium,
    bool isDisabled = false,
    Color? color,
  }) {
    return AppButton(
      icon: icon,
      onPressed: onPressed,
      variant: AppButtonVariant.icon,
      size: size,
      isDisabled: isDisabled,
      customColor: color,
    );
  }
}
