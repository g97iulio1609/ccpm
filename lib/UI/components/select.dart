import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppSelect<T> extends StatelessWidget {
  final String label;
  final String? helperText;
  final T? value;
  final List<T> items;
  final String Function(T) getLabel;
  final IconData? icon;
  final void Function(T?)? onChanged;
  final bool isRequired;
  final bool isExpanded;
  final bool enabled;
  final String? Function(T?)? validator;
  final Widget Function(T)? customItemBuilder;

  const AppSelect({
    super.key,
    required this.label,
    required this.items,
    required this.getLabel,
    this.helperText,
    this.value,
    this.icon,
    this.onChanged,
    this.isRequired = false,
    this.isExpanded = true,
    this.enabled = true,
    this.validator,
    this.customItemBuilder,
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
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],

        SizedBox(height: AppTheme.spacing.xs),

        // Dropdown
        Container(
          decoration: BoxDecoration(
            color: enabled 
                ? colorScheme.surfaceVariant.withOpacity(0.3)
                : colorScheme.surfaceVariant.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: isExpanded,
            icon: Icon(
              Icons.arrow_drop_down,
              color: enabled 
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.5),
            ),
            decoration: InputDecoration(
              enabled: enabled,
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: enabled 
                          ? colorScheme.primary 
                          : colorScheme.onSurfaceVariant.withOpacity(0.5),
                      size: 20,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(AppTheme.spacing.md),
            ),
            dropdownColor: colorScheme.surface,
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: customItemBuilder != null
                    ? customItemBuilder!(item)
                    : Text(
                        getLabel(item),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              );
            }).toList(),
            onChanged: enabled ? onChanged : null,
            validator: validator,
          ),
        ),
      ],
    );
  }

  // Factory constructors per casi comuni
  static AppSelect<String> simple({
    required String label,
    required List<String> items,
    String? value,
    String? helperText,
    IconData? icon,
    void Function(String?)? onChanged,
    bool isRequired = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return AppSelect<String>(
      label: label,
      items: items,
      getLabel: (item) => item,
      value: value,
      helperText: helperText,
      icon: icon,
      onChanged: onChanged,
      isRequired: isRequired,
      enabled: enabled,
      validator: validator,
    );
  }

  static AppSelect<Map<String, dynamic>> fromMap({
    required String label,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    required String valueKey,
    Map<String, dynamic>? value,
    String? helperText,
    IconData? icon,
    void Function(Map<String, dynamic>?)? onChanged,
    bool isRequired = false,
    bool enabled = true,
    String? Function(Map<String, dynamic>?)? validator,
  }) {
    return AppSelect<Map<String, dynamic>>(
      label: label,
      items: items,
      getLabel: (item) => item[labelKey] as String,
      value: value,
      helperText: helperText,
      icon: icon,
      onChanged: onChanged,
      isRequired: isRequired,
      enabled: enabled,
      validator: validator,
    );
  }

  static AppSelect<T> withIcon<T>({
    required String label,
    required List<T> items,
    required String Function(T) getLabel,
    required IconData Function(T) getIcon,
    T? value,
    String? helperText,
    IconData? icon,
    void Function(T?)? onChanged,
    bool isRequired = false,
    bool enabled = true,
    String? Function(T?)? validator,
  }) {
    return AppSelect<T>(
      label: label,
      items: items,
      getLabel: getLabel,
      value: value,
      helperText: helperText,
      icon: icon,
      onChanged: onChanged,
      isRequired: isRequired,
      enabled: enabled,
      validator: validator,
      customItemBuilder: (item) => Row(
        children: [
          Icon(
            getIcon(item),
            size: 20,
            color: enabled ? null : Colors.grey,
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: Text(
              getLabel(item),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  static AppSelect<T> withAvatar<T>({
    required String label,
    required List<T> items,
    required String Function(T) getLabel,
    required String Function(T) getAvatarUrl,
    T? value,
    String? helperText,
    IconData? icon,
    void Function(T?)? onChanged,
    bool isRequired = false,
    bool enabled = true,
    String? Function(T?)? validator,
  }) {
    return AppSelect<T>(
      label: label,
      items: items,
      getLabel: getLabel,
      value: value,
      helperText: helperText,
      icon: icon,
      onChanged: onChanged,
      isRequired: isRequired,
      enabled: enabled,
      validator: validator,
      customItemBuilder: (item) => Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundImage: NetworkImage(getAvatarUrl(item)),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: Text(
              getLabel(item),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
} 