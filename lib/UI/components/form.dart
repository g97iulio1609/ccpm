import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/button.dart';

class AppForm extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> children;
  final List<Widget>? actions;
  final bool showDividers;
  final EdgeInsets? contentPadding;
  final GlobalKey<FormState>? formKey;
  final VoidCallback? onSubmit;
  final bool isLoading;

  const AppForm({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.children,
    this.actions,
    this.showDividers = true,
    this.contentPadding,
    this.formKey,
    this.onSubmit,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.xl),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.large,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radii.xl),
                ),
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
            Padding(
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

            // Actions
            if (actions != null || onSubmit != null) ...[
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppTheme.radii.xl),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (actions != null) ...[
                      ...actions!.map((action) => Padding(
                        padding: EdgeInsets.only(right: AppTheme.spacing.md),
                        child: action,
                      )),
                    ],
                    if (onSubmit != null)
                      AppButton(
                        label: 'Salva',
                        onPressed: onSubmit!,
                        isLoading: isLoading,
                        icon: Icons.save_outlined,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods per creare form fields comuni
  static Widget buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        SizedBox(height: AppTheme.spacing.md),
        ...children,
      ],
    );
  }

  static Widget buildGrid({
    required List<Widget> children,
    required int crossAxisCount,
    required double childAspectRatio,
    required double spacing,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
      children: children,
    );
  }

  static Widget buildFormRow({
    required List<Widget> children,
    required double spacing,
  }) {
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1)
            SizedBox(width: spacing),
        ],
      ],
    );
  }

  // Factory constructors per casi comuni
  factory AppForm.dialog({
    required String title,
    String? subtitle,
    Widget? leading,
    required List<Widget> children,
    List<Widget>? actions,
    VoidCallback? onSubmit,
    bool isLoading = false,
    GlobalKey<FormState>? formKey,
  }) {
    return AppForm(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      onSubmit: onSubmit,
      isLoading: isLoading,
      formKey: formKey,
      contentPadding: EdgeInsets.all(AppTheme.spacing.xl),
      children: children,
    );
  }

  factory AppForm.card({
    required String title,
    String? subtitle,
    Widget? leading,
    required List<Widget> children,
    List<Widget>? actions,
    VoidCallback? onSubmit,
    bool isLoading = false,
    GlobalKey<FormState>? formKey,
  }) {
    return AppForm(
      title: title,
      subtitle: subtitle,
      leading: leading,
      actions: actions,
      onSubmit: onSubmit,
      isLoading: isLoading,
      formKey: formKey,
      showDividers: false,
      contentPadding: EdgeInsets.all(AppTheme.spacing.lg),
      children: children,
    );
  }
} 