import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/glass.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? background;
  final VoidCallback? onTap;
  final bool glass;
  final Color? glassTint;
  final double? glassBlur;
  final double? glassRadius;
  // Header helpers (compat con versione precedente in card.dart)
  final String? title;
  final String? subtitle;
  final IconData? leadingIcon;
  final List<Widget>? actions;

  const AppCard({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
    this.margin,
    this.background,
    this.onTap,
    this.glass = false,
    this.glassTint,
    this.glassBlur,
    this.glassRadius,
    this.title,
    this.subtitle,
    this.leadingIcon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget core = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null || title != null || leadingIcon != null)
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(77),
              border: Border(bottom: BorderSide(color: colorScheme.outline.withAlpha(26))),
            ),
            child: header ?? _buildDefaultHeader(context),
          ),
        Padding(padding: padding ?? EdgeInsets.all(AppTheme.spacing.md), child: child),
        if (actions != null && actions!.isNotEmpty)
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(77),
              border: Border(top: BorderSide(color: colorScheme.outline.withAlpha(26))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (int i = 0; i < actions!.length; i++) ...[
                  actions![i],
                  if (i < actions!.length - 1) SizedBox(width: AppTheme.spacing.md),
                ],
              ],
            ),
          ),
        if (footer != null) Padding(padding: EdgeInsets.all(AppTheme.spacing.md), child: footer),
      ],
    );

    Widget content = glass
        ? GlassLite(
            margin: margin,
            padding: EdgeInsets.zero,
            tint: glassTint,
            blur: glassBlur,
            radius: glassRadius,
            child: core,
          )
        : Card(
            elevation: 0,
            margin: margin ?? EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              side: BorderSide(color: colorScheme.outline.withAlpha(26), width: 1),
            ),
            color: background ?? colorScheme.surface,
            child: ClipRRect(borderRadius: BorderRadius.circular(AppTheme.radii.lg), child: core),
          );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildDefaultHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        if (leadingIcon != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.sm,
              vertical: AppTheme.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(77),
              borderRadius: BorderRadius.circular(AppTheme.radii.full),
            ),
            child: Icon(leadingIcon, color: colorScheme.primary, size: 20),
          ),
        if (leadingIcon != null) SizedBox(width: AppTheme.spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (subtitle != null) ...[
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
