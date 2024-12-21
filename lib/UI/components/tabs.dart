import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final Function(int) onTabSelected;
  final bool isScrollable;
  final double? height;
  final EdgeInsets? padding;
  final bool showIndicator;
  final bool showDivider;
  final Widget? leading;
  final Widget? trailing;

  const AppTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.isScrollable = false,
    this.height,
    this.padding,
    this.showIndicator = true,
    this.showDivider = true,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: showDivider ? AppTheme.elevations.small : null,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withAlpha(26),
                ),
              )
            : null,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: AppTheme.spacing.md),
          ],
          Expanded(
            child: TabBar(
              isScrollable: isScrollable,
              padding: padding,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              indicatorColor: colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: showIndicator ? 2 : 0,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
              unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  return states.contains(WidgetState.focused)
                      ? null
                      : Colors.transparent;
                },
              ),
              tabs: tabs.map((tab) => _buildTab(tab, colorScheme)).toList(),
              onTap: onTabSelected,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: AppTheme.spacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }

  Widget _buildTab(String label, ColorScheme colorScheme) {
    return Tab(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radii.full),
        ),
        child: Text(label),
      ),
    );
  }

  // Factory constructor per tabs con badge
  static AppTabs withBadges({
    required List<String> tabs,
    required List<int?> badges,
    required int selectedIndex,
    required Function(int) onTabSelected,
    bool isScrollable = false,
    double? height,
    EdgeInsets? padding,
    bool showIndicator = true,
    bool showDivider = true,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppTabs(
      tabs: tabs,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      isScrollable: isScrollable,
      height: height,
      padding: padding,
      showIndicator: showIndicator,
      showDivider: showDivider,
      leading: leading,
      trailing: trailing,
    );
  }

  // Factory constructor per tabs con icone
  static AppTabs withIcons({
    required List<String> tabs,
    required List<IconData> icons,
    required int selectedIndex,
    required Function(int) onTabSelected,
    bool isScrollable = false,
    double? height,
    EdgeInsets? padding,
    bool showIndicator = true,
    bool showDivider = true,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppTabs(
      tabs: tabs,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      isScrollable: isScrollable,
      height: height,
      padding: padding,
      showIndicator: showIndicator,
      showDivider: showDivider,
      leading: leading,
      trailing: trailing,
    );
  }
}

// Badge per i tab
class TabBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const TabBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.xs,
        vertical: AppTheme.spacing.xxs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primary,
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
      ),
      child: Text(
        count.toString(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor ?? colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// Tab con icona
class IconTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const IconTab({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color:
                isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: AppTheme.spacing.xs),
          Text(label),
        ],
      ),
    );
  }
}
