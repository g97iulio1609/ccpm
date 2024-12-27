import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:ui' as ui;
import 'auth_service.dart';
import 'auth_form.dart';

class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient con Pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerHighest,
                ],
              ),
            ),
            child: const AnimatedGridPattern(),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    _buildLogoSection(theme),
                    const SizedBox(height: 48),
                    // Auth Container
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
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
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
          'Begin your journey',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(179),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAuthContainer(ThemeData theme, AuthService authService) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(179),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(26),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: AuthForm(authService: authService),
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
