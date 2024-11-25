import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/Main/app_theme.dart';

class BottomInputForm extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final List<Widget>? actions;
  final ScrollController? scrollController;
  final bool showDragHandle;
  final EdgeInsets? contentPadding;
  final bool showDividers;

  const BottomInputForm({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.actions,
    this.scrollController,
    this.showDragHandle = true,
    this.contentPadding,
    this.showDividers = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDragHandle) ...[
            Center(
              child: Container(
                margin: EdgeInsets.only(top: AppTheme.spacing.md),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(AppTheme.radii.full),
                ),
              ),
            ),
          ],

          // Header
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: showDragHandle 
                  ? null 
                  : BorderRadius.vertical(top: Radius.circular(AppTheme.radii.xl)),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: AppTheme.spacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
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
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: contentPadding ?? EdgeInsets.all(AppTheme.spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (showDividers && i < children.length - 1) ...[
                      SizedBox(height: AppTheme.spacing.lg),
                      if (i < children.length - 1)
                        Divider(
                          color: colorScheme.outline.withOpacity(0.1),
                        ),
                      SizedBox(height: AppTheme.spacing.lg),
                    ] else if (i < children.length - 1)
                      SizedBox(height: AppTheme.spacing.lg),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          if (actions != null) ...[
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
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
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildFormField({
    required String label,
    required Widget child,
    required ThemeData theme,
    required ColorScheme colorScheme,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            helperText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
        SizedBox(height: AppTheme.spacing.xs),
        child,
      ],
    );
  }

  static Widget buildTextInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    FocusNode? focusNode,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            icon,
            color: colorScheme.primary,
            size: 20,
          ),
          suffixText: suffixText,
          suffixStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.spacing.md),
        ),
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  static Widget buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool isPrimary = true,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary ? LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ) : null,
        color: isPrimary ? null : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.lg,
              vertical: AppTheme.spacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isPrimary ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  SizedBox(width: AppTheme.spacing.sm),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isPrimary ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 