import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(64),
        borderRadius: borderRadius,
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 120});

  @override
  Widget build(BuildContext context) {
    final spacing = 12.0;
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: spacing),
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(height: 20, width: 180),
            SizedBox(height: 12),
            SkeletonBox(height: 14, width: 240),
            SizedBox(height: 12),
            SkeletonBox(height: 14, width: 120),
          ],
        ),
      ),
    );
  }
}
