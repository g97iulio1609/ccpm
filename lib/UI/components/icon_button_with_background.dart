import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/glass.dart';

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

    final content = Material(
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
    );

    if (isGradient) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withAlpha(204)]),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(51),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      );
    }

    return GlassLite(
      padding: EdgeInsets.zero,
      radius: AppTheme.radii.lg,
      tint: color.withAlpha(32),
      border: isOutlined
          ? Border.all(color: color.withAlpha(76), width: 1.5)
          : null,
      child: content,
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
