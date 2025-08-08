import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? background;

  const AppCard({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
    this.margin,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: margin ?? EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        side: BorderSide(color: colorScheme.outline.withAlpha(26), width: 1),
      ),
      color: background ?? colorScheme.surface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (header != null)
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(77),
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outline.withAlpha(26),
                    ),
                  ),
                ),
                child: header,
              ),
            Padding(
              padding: padding ?? EdgeInsets.all(AppTheme.spacing.md),
              child: child,
            ),
            if (footer != null)
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
