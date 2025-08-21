import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppRadioSelect<T> extends StatelessWidget {
  final String label;
  final String? helperText;
  final T? value;
  final List<T> options;
  final String Function(T) getLabel;
  final IconData? Function(T)? getIcon;
  final void Function(T?) onChanged;
  final bool isEnabled;
  final bool isRequired;
  final String? Function(T?)? validator;
  final bool isVertical;
  final double? spacing;

  const AppRadioSelect({
    super.key,
    required this.label,
    required this.options,
    required this.getLabel,
    required this.onChanged,
    this.helperText,
    this.value,
    this.getIcon,
    this.isEnabled = true,
    this.isRequired = false,
    this.validator,
    this.isVertical = false,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                '*',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),

        // Helper Text
        if (helperText != null) ...[
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(179),
            ),
          ),
        ],

        SizedBox(height: AppTheme.spacing.sm),

        // Radio Options
        if (isVertical)
          Column(children: _buildOptions(theme, colorScheme))
        else
          Wrap(
            spacing: spacing ?? AppTheme.spacing.md,
            runSpacing: spacing ?? AppTheme.spacing.sm,
            children: _buildOptions(theme, colorScheme),
          ),

        // Validation Error
        if (validator != null) ...[
          Builder(
            builder: (context) {
              final errorText = validator!(value);
              if (errorText != null) {
                return Padding(
                  padding: EdgeInsets.only(top: AppTheme.spacing.xs, left: AppTheme.spacing.sm),
                  child: Text(
                    errorText,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }

  List<Widget> _buildOptions(ThemeData theme, ColorScheme colorScheme) {
    return options.map((option) {
      final isSelected = value == option;
      final icon = getIcon?.call(option);

      return Container(
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withAlpha(76)
              : colorScheme.surfaceContainerHighest.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline.withAlpha(26),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? () => onChanged(option) : null,
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEnabled
                            ? (isSelected ? colorScheme.primary : colorScheme.outline)
                            : colorScheme.onSurfaceVariant.withAlpha(128),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isSelected
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isEnabled
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant.withAlpha(128),
                              ),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: isEnabled
                          ? (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant)
                          : colorScheme.onSurfaceVariant.withAlpha(128),
                    ),
                    SizedBox(width: AppTheme.spacing.sm),
                  ],
                  Text(
                    getLabel(option),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isEnabled
                          ? (isSelected ? colorScheme.primary : colorScheme.onSurface)
                          : colorScheme.onSurfaceVariant.withAlpha(128),
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // Factory constructor per radio buttons con icone
  static AppRadioSelect<T> withIcons<T>({
    required String label,
    required List<T> options,
    required String Function(T) getLabel,
    required IconData Function(T) getIcon,
    required void Function(T?) onChanged,
    T? value,
    String? helperText,
    bool isEnabled = true,
    bool isRequired = false,
    String? Function(T?)? validator,
    bool isVertical = false,
    double? spacing,
  }) {
    return AppRadioSelect<T>(
      label: label,
      options: options,
      getLabel: getLabel,
      getIcon: getIcon,
      onChanged: onChanged,
      value: value,
      helperText: helperText,
      isEnabled: isEnabled,
      isRequired: isRequired,
      validator: validator,
      isVertical: isVertical,
      spacing: spacing,
    );
  }
}
