import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/badge.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final String? badge;
  final BadgeStatus? badgeStatus;
  final IconData? leadingIcon;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool isGradient;
  final bool isOutlined;
  final bool isInteractive;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.backgroundColor,
    this.borderRadius = 24,
    this.boxShadow,
    this.border,
    this.badge,
    this.badgeStatus,
    this.leadingIcon,
    this.title,
    this.subtitle,
    this.actions,
    this.isGradient = false,
    this.isOutlined = false,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final cardColor = backgroundColor ?? colorScheme.surface;
    
    Widget card = Container(
      decoration: BoxDecoration(
        gradient: isGradient ? LinearGradient(
          colors: [
            cardColor,
            cardColor.withOpacity(0.8),
          ],
        ) : null,
        color: isGradient ? null : cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: isOutlined ? Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ) : border,
        boxShadow: boxShadow ?? (isOutlined ? null : AppTheme.elevations.small),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || badge != null) ...[
            _buildHeader(context),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
          if (actions != null) ...[
            _buildActions(context),
          ],
        ],
      ),
    );

    if (isInteractive && onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.sm,
                vertical: AppTheme.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
              ),
              child: Icon(
                leadingIcon,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
          ],
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (badge != null) ...[
            SizedBox(width: AppTheme.spacing.md),
            AppBadge(
              text: badge!,
              status: badgeStatus,
              size: AppBadgeSize.small,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (int i = 0; i < actions!.length; i++) ...[
            actions![i],
            if (i < actions!.length - 1)
              SizedBox(width: AppTheme.spacing.md),
          ],
        ],
      ),
    );
  }

  // Factory constructors per casi comuni
  factory AppCard.action({
    required String title,
    String? subtitle,
    required List<Widget> actions,
    List<Widget>? bottomContent,
    VoidCallback? onTap,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    EdgeInsetsGeometry actionsPadding = const EdgeInsets.symmetric(horizontal: 8),
    IconData? leadingIcon,
    String? badge,
    BadgeStatus? badgeStatus,
  }) {
    return AppCard(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      badge: badge,
      badgeStatus: badgeStatus,
      onTap: onTap,
      padding: EdgeInsets.zero,
      actions: actions,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bottomContent != null) ...[
            SizedBox(height: AppTheme.spacing.md),
            Padding(
              padding: contentPadding,
              child: Row(
                children: bottomContent.map((content) {
                  final index = bottomContent.indexOf(content);
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index > 0 ? AppTheme.spacing.lg : 0,
                    ),
                    child: content,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  factory AppCard.gradient({
    required Widget child,
    Color? backgroundColor,
    VoidCallback? onTap,
    String? title,
    String? subtitle,
    IconData? leadingIcon,
    List<Widget>? actions,
  }) {
    return AppCard(
      backgroundColor: backgroundColor,
      onTap: onTap,
      isGradient: true,
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      actions: actions,
      child: child,
    );
  }

  factory AppCard.outlined({
    required Widget child,
    VoidCallback? onTap,
    String? title,
    String? subtitle,
    IconData? leadingIcon,
    List<Widget>? actions,
  }) {
    return AppCard(
      onTap: onTap,
      isOutlined: true,
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      actions: actions,
      child: child,
    );
  }
}