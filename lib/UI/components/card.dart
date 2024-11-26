import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/badge.dart';

enum AppCardVariant { elevated, outlined, gradient, flat }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final String? badge;
  final AppBadgeStatus? badgeStatus;
  final IconData? leadingIcon;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool isGradient;
  final bool isOutlined;
  final bool isInteractive;
  final AppCardVariant variant;
  final CrossAxisAlignment contentAlignment;
  final MainAxisAlignment actionsAlignment;
  final bool centerContent;
  final String? mesocycleNumber;

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
    this.variant = AppCardVariant.elevated,
    this.contentAlignment = CrossAxisAlignment.start,
    this.actionsAlignment = MainAxisAlignment.end,
    this.centerContent = false,
    this.mesocycleNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardColor = backgroundColor ?? colorScheme.surface;

    Widget cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: contentAlignment,
      children: [
        if (mesocycleNumber != null) ...[
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.md,
                vertical: AppTheme.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
              ),
              child: Text(
                'Mesocycle $mesocycleNumber',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: AppTheme.spacing.md),
        ],
        if (title != null || badge != null) ...[
          _buildHeader(context),
          SizedBox(height: AppTheme.spacing.md),
        ],
        Padding(
          padding: padding,
          child: centerContent ? Center(child: child) : child,
        ),
        if (actions != null) ...[
          _buildActions(context),
        ],
      ],
    );

    Widget card = Container(
      decoration: BoxDecoration(
        gradient: variant == AppCardVariant.gradient
            ? LinearGradient(
                colors: [
                  cardColor,
                  cardColor.withOpacity(0.8),
                ],
              )
            : null,
        color: variant != AppCardVariant.gradient ? cardColor : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: variant == AppCardVariant.outlined
            ? Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              )
            : border,
        boxShadow: variant == AppCardVariant.elevated
            ? boxShadow ?? AppTheme.elevations.small
            : null,
      ),
      child: cardContent,
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (subtitle != null) ...[
                  SizedBox(height: AppTheme.spacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (badge != null) ...[
            SizedBox(width: AppTheme.spacing.md),
            AppBadge(
              text: badge!,
              status: badgeStatus ?? AppBadgeStatus.primary,
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
        mainAxisAlignment: actionsAlignment,
        children: [
          for (int i = 0; i < actions!.length; i++) ...[
            actions![i],
            if (i < actions!.length - 1) SizedBox(width: AppTheme.spacing.md),
          ],
        ],
      ),
    );
  }

  // Factory constructors per casi comuni
  factory AppCard.program({
    required String title,
    required String subtitle,
    required String mesocycleNumber,
    required List<Widget> actions,
    VoidCallback? onTap,
  }) {
    return AppCard(
      variant: AppCardVariant.elevated,
      title: title,
      subtitle: subtitle,
      mesocycleNumber: mesocycleNumber,
      actions: actions,
      onTap: onTap,
      centerContent: true,
      contentAlignment: CrossAxisAlignment.center,
      actionsAlignment: MainAxisAlignment.center,
      child: const SizedBox.shrink(),
    );
  }

  factory AppCard.action({
    required String title,
    String? subtitle,
    required List<Widget> actions,
    List<Widget>? bottomContent,
    VoidCallback? onTap,
    IconData? leadingIcon,
    String? badge,
    AppBadgeStatus? badgeStatus,
  }) {
    return AppCard(
      variant: AppCardVariant.elevated,
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      badge: badge,
      badgeStatus: badgeStatus,
      onTap: onTap,
      actions: actions,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bottomContent != null) ...[
            SizedBox(height: AppTheme.spacing.md),
            Row(
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
      variant: AppCardVariant.gradient,
      backgroundColor: backgroundColor,
      onTap: onTap,
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      actions: actions,
      child: child,
    );
  }
}
