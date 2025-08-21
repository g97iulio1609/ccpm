import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';

/// Mixin that provides common functionality for training list widgets
mixin TrainingListMixin<T extends StatefulWidget> on State<T> {
  /// Shows a confirmation dialog for deletion
  Future<bool> showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        insetPadding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Elimina')),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows a bottom sheet with options
  void showOptionsBottomSheet(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData leadingIcon,
    required List<BottomMenuItem> items,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: title,
        subtitle: subtitle,
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(leadingIcon, color: colorScheme.onPrimaryContainer, size: 24),
        ),
        items: items,
      ),
    );
  }

  /// Creates a standardized card widget
  Widget buildCard({required Widget child, VoidCallback? onTap, required ColorScheme colorScheme}) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: child,
        ),
      ),
    );
  }

  /// Creates a standardized action button
  Widget buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        foregroundColor: isPrimary ? colorScheme.onPrimary : colorScheme.onSurface,
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.lg,
          vertical: AppTheme.spacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radii.lg)),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }

  /// Gets responsive layout properties
  @Deprecated('Use MediaQuery.of(context).size.width directly for responsive checks')
  ({bool isSmallScreen, double spacing, EdgeInsets padding}) getLayoutProperties(
    BuildContext context,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return (
      isSmallScreen: isSmallScreen,
      spacing: isSmallScreen ? AppTheme.spacing.sm : AppTheme.spacing.md,
      padding: EdgeInsets.all(isSmallScreen ? AppTheme.spacing.md : AppTheme.spacing.lg),
    );
  }

  /// Helper method to check if the screen is compact (mobile-like)
  static bool isCompactScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Helper method to get responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    return isCompactScreen(context) ? AppTheme.spacing.sm : AppTheme.spacing.md;
  }

  /// Helper method to get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.all(isCompactScreen(context) ? AppTheme.spacing.md : AppTheme.spacing.lg);
  }
}
