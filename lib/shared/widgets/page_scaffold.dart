import 'package:flutter/material.dart';

/// Body scaffold condiviso: gradient opzionale + SafeArea + CustomScrollView (slivers)
class PageScaffold extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<Widget> slivers;
  final EdgeInsetsGeometry? padding;
  final bool useGradient;
  final Alignment begin;
  final Alignment end;

  const PageScaffold({
    super.key,
    required this.colorScheme,
    required this.slivers,
    this.padding,
    this.useGradient = true,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: CustomScrollView(
        slivers: [
          if (padding != null)
            SliverPadding(
              padding: padding!,
              sliver: SliverList(delegate: SliverChildListDelegate([])),
            ),
          ...slivers,
        ],
      ),
    );

    if (!useGradient) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withAlpha(128),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: content,
    );
  }
}
