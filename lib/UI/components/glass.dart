import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.blurSigma = 12,
    this.tintColor,
    this.padding,
    this.margin,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mq = MediaQuery.of(context);

    final bool reduceEffects = mq.disableAnimations || mq.accessibleNavigation;
    final bool highContrast = mq.highContrast;
    final Color baseTint =
        tintColor ??
        (cs.brightness == Brightness.dark
            ? cs.surface.withAlpha(highContrast ? 220 : 180)
            : cs.surface.withAlpha(highContrast ? 242 : 204));

    final borderColor = cs.outline.withAlpha(highContrast ? 64 : 38);

    // Gradient tint for a more pronounced glass effect
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseTint.withAlpha(highContrast ? 235 : 215),
        baseTint.withAlpha(highContrast ? 215 : 185),
      ],
    );

    Widget decoratedChild = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: borderColor, width: 1.0),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (reduceEffects) {
      return ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: decoratedChild);
    }

    // Add a subtle directional shine overlay for glass look
    final shineOverlay = IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(highContrast ? 36 : 24),
              Colors.white.withAlpha(0),
            ],
          ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            RepaintBoundary(child: decoratedChild),
            shineOverlay,
          ],
        ),
      ),
    );
  }
}

//

// Helper preconfigurato per il tema Glass "lite"
class GlassLite extends GlassContainer {
  GlassLite({
    super.key,
    required super.child,
    double? radius,
    double? blur,
    Color? tint,
    super.padding,
    super.margin,
    super.border,
    super.boxShadow,
  }) : super(borderRadius: radius ?? AppTheme.radii.lg, blurSigma: blur ?? 12, tintColor: tint);
}
