import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final bool isEnabled;
  final String? helperText;
  final IconData? icon;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.isEnabled = true,
    this.helperText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: isEnabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                border: Border.all(
                  color: value
                      ? (isEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant.withAlpha(128))
                      : colorScheme.outline,
                  width: 2,
                ),
                color: value
                    ? (isEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withAlpha(128))
                    : Colors.transparent,
              ),
              child: value
                  ? Icon(
                      Icons.check,
                      size: 18,
                      color: isEnabled ? colorScheme.onPrimary : colorScheme.surface,
                    )
                  : null,
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 20,
                          color: isEnabled
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant.withAlpha(128),
                        ),
                        SizedBox(width: AppTheme.spacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: isEnabled
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant.withAlpha(128),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (helperText != null) ...[
                    SizedBox(height: AppTheme.spacing.xs),
                    Text(
                      helperText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isEnabled
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurfaceVariant.withAlpha(128),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppCheckboxGroup<T> extends StatelessWidget {
  final List<T> values;
  final List<T> selectedValues;
  final ValueChanged<List<T>> onChanged;
  final String Function(T) getLabel;
  final bool Function(T)? isEnabled;
  final String? Function(T)? getHelperText;
  final IconData? Function(T)? getIcon;

  const AppCheckboxGroup({
    super.key,
    required this.values,
    required this.selectedValues,
    required this.onChanged,
    required this.getLabel,
    this.isEnabled,
    this.getHelperText,
    this.getIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: values.map((value) {
        final isItemEnabled = isEnabled?.call(value) ?? true;
        return Padding(
          padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
          child: AppCheckbox(
            value: selectedValues.contains(value),
            onChanged: (bool? isSelected) {
              if (isSelected == true) {
                onChanged([...selectedValues, value]);
              } else {
                onChanged(selectedValues.where((v) => v != value).toList());
              }
            },
            label: getLabel(value),
            isEnabled: isItemEnabled,
            helperText: getHelperText?.call(value),
            icon: getIcon?.call(value),
          ),
        );
      }).toList(),
    );
  }
}
