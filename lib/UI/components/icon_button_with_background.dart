import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class IconButtonWithBackground extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;
  final EdgeInsetsGeometry padding;
  final String? tooltip;
  final bool isGradient;
  final bool isOutlined;

  const IconButtonWithBackground({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.size = 20,
    this.padding = const EdgeInsets.all(8),
    this.tooltip,
    this.isGradient = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: isGradient
            ? LinearGradient(
                colors: [
                  color,
                  color.withAlpha(204),
                ],
              )
            : null,
        color: isGradient ? null : color.withAlpha(26),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: isOutlined
            ? Border.all(
                color: color.withAlpha(76),
                width: 1.5,
              )
            : null,
        boxShadow: isGradient
            ? [
                BoxShadow(
                  color: color.withAlpha(51),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Tooltip(
          message: tooltip ?? '',
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            child: Padding(
              padding: padding,
              child: Icon(
                icon,
                color: isGradient ? colorScheme.surface : color,
                size: size,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Factory constructors per casi comuni
  factory IconButtonWithBackground.primary({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    String? tooltip,
  }) {
    return IconButtonWithBackground(
      icon: icon,
      color: const Color(0xFF6366F1), // Indigo
      onPressed: onPressed,
      size: size,
      padding: padding,
      tooltip: tooltip,
      isGradient: true,
    );
  }

  factory IconButtonWithBackground.success({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    String? tooltip,
  }) {
    return IconButtonWithBackground(
      icon: icon,
      color: const Color(0xFF22C55E), // Green
      onPressed: onPressed,
      size: size,
      padding: padding,
      tooltip: tooltip,
      isGradient: true,
    );
  }

  factory IconButtonWithBackground.error({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    String? tooltip,
  }) {
    return IconButtonWithBackground(
      icon: icon,
      color: const Color(0xFFEF4444), // Red
      onPressed: onPressed,
      size: size,
      padding: padding,
      tooltip: tooltip,
      isGradient: true,
    );
  }

  factory IconButtonWithBackground.warning({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    String? tooltip,
  }) {
    return IconButtonWithBackground(
      icon: icon,
      color: const Color(0xFFF59E0B), // Amber
      onPressed: onPressed,
      size: size,
      padding: padding,
      tooltip: tooltip,
      isGradient: true,
    );
  }

  factory IconButtonWithBackground.info({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    String? tooltip,
  }) {
    return IconButtonWithBackground(
      icon: icon,
      color: const Color(0xFF3B82F6), // Blue
      onPressed: onPressed,
      size: size,
      padding: padding,
      tooltip: tooltip,
      isGradient: true,
    );
  }

  factory IconButtonWithBackground.neutral({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 20,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8),
    String? tooltip,
  }) {
    return IconButtonWithBackground(
      icon: icon,
      color: const Color(0xFF6B7280), // Gray
      onPressed: onPressed,
      size: size,
      padding: padding,
      tooltip: tooltip,
      isOutlined: true,
    );
  }
}
