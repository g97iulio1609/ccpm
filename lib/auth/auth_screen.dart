import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'auth_service.dart';
import 'auth_form.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';

class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackground(),

          // Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogoSection(theme),
                    SizedBox(height: AppTheme.spacing.xxl),
                    _buildAuthContainer(theme, authService),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(ThemeData theme) {
    return Column(
      children: [
        // Logo Container with Glow
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withAlpha(51),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(51),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.fitness_center,
            size: 56,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        // App Name with Gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ).createShader(bounds),
          child: Text(
            'ALPHANESS ONE',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inizia il tuo percorso',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(179),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthContainer(ThemeData theme, AuthService authService) {
    return GlassLite(
      radius: AppTheme.radii.xl,
      padding: EdgeInsets.all(AppTheme.spacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AuthForm(authService: authService),
      ),
    );
  }
}

class _AuthBackground extends ConsumerWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mq = MediaQuery.of(context);
    final bool reduceMotion = mq.disableAnimations || mq.accessibleNavigation;
    final bool glassEnabled = ref.watch(uiGlassEnabledProvider);

    return Stack(
      children: [
        // Base gradient coerente con le altre schermate
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cs.surface, cs.surfaceContainerHighest.withAlpha(128)],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        // Accenti radiali soft (primary)
        Positioned(
          top: -80,
          left: -60,
          child: _RadialAccent(color: cs.primary, diameter: 280, opacity: 0.18),
        ),
        // Accenti radiali soft (secondary)
        Positioned(
          bottom: -100,
          right: -80,
          child: _RadialAccent(
            color: cs.secondary,
            diameter: 340,
            opacity: 0.14,
          ),
        ),
        // Velo glass "lite" che ammorbidisce gli accenti se abilitato
        if (glassEnabled && !reduceMotion)
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: cs.surface.withAlpha(26)),
                ),
              ),
            ),
          ),
        // Pattern animato molto lieve, disattivato se l'utente preferisce meno motion
        if (!reduceMotion)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: 0.7,
            child: const AnimatedGridPattern(),
          ),
      ],
    );
  }
}

class _RadialAccent extends StatelessWidget {
  final Color color;
  final double diameter;
  final double opacity;

  const _RadialAccent({
    required this.color,
    required this.diameter,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedGridPattern extends StatefulWidget {
  const AnimatedGridPattern({super.key});

  @override
  State<AnimatedGridPattern> createState() => _AnimatedGridPatternState();
}

class _AnimatedGridPatternState extends State<AnimatedGridPattern>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 30).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: AnimatedGridPatternPainter(
            offset: _animation.value,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(8),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class AnimatedGridPatternPainter extends CustomPainter {
  final double offset;
  final Color color;

  AnimatedGridPatternPainter({required this.offset, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const spacing = 30.0;

    // Diagonali animate
    for (double i = -size.width; i < size.width * 2; i += spacing) {
      final startPoint = Offset(i + offset, 0);
      final endPoint = Offset(i + size.height + offset, size.height);
      canvas.drawLine(startPoint, endPoint, paint);
    }

    for (double i = -size.width; i < size.width * 2; i += spacing) {
      final startPoint = Offset(i - offset, 0);
      final endPoint = Offset(i - size.height - offset, size.height);
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedGridPatternPainter oldDelegate) {
    return offset != oldDelegate.offset;
  }
}
