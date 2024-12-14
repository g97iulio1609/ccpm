import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppSlider extends StatelessWidget {
  final String label;
  final String? helperText;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double)? valueLabel;
  final void Function(double) onChanged;
  final void Function(double)? onChangeEnd;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveColor;
  final Widget? leading;
  final Widget? trailing;

  const AppSlider({
    super.key,
    required this.label,
    this.helperText,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.valueLabel,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
    this.activeColor,
    this.inactiveColor,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con label e valore
        Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: AppTheme.spacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: enabled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withAlpha(128),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (helperText != null) ...[
                    SizedBox(height: AppTheme.spacing.xs),
                    Text(
                      helperText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? colorScheme.onSurfaceVariant.withAlpha(179)
                            : colorScheme.onSurfaceVariant.withAlpha(128),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.sm,
                vertical: AppTheme.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: enabled
                    ? colorScheme.primaryContainer.withAlpha(76)
                    : colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
              ),
              child: Text(
                valueLabel?.call(value) ??
                    value.toStringAsFixed(divisions != null ? 0 : 1),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: enabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withAlpha(128),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: AppTheme.spacing.sm),
              trailing!,
            ],
          ],
        ),

        SizedBox(height: AppTheme.spacing.md),

        // Slider personalizzato
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: enabled
                ? (activeColor ?? colorScheme.primary).withAlpha(76)
                : colorScheme.surfaceContainerHighest.withAlpha(76),
            inactiveTrackColor: enabled
                ? (inactiveColor ?? colorScheme.surfaceContainerHighest)
                    .withAlpha(76)
                : colorScheme.surfaceContainerHighest.withOpacity(0.1),
            thumbColor: enabled
                ? activeColor ?? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            overlayColor:
                (activeColor ?? colorScheme.primary).withOpacity(0.12),
            valueIndicatorColor: colorScheme.primaryContainer,
            valueIndicatorTextStyle: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
            tickMarkShape: const RoundSliderTickMarkShape(),
            activeTickMarkColor: enabled
                ? (activeColor ?? colorScheme.primary).withAlpha(128)
                : colorScheme.surfaceContainerHighest.withAlpha(76),
            inactiveTickMarkColor: enabled
                ? (inactiveColor ?? colorScheme.surfaceContainerHighest)
                    .withAlpha(76)
                : colorScheme.surfaceContainerHighest.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? onChangeEnd : null,
          ),
        ),
      ],
    );
  }

  // Factory constructors per casi comuni
  factory AppSlider.percentage({
    required String label,
    String? helperText,
    required double value,
    required void Function(double) onChanged,
    void Function(double)? onChangeEnd,
    bool enabled = true,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppSlider(
      label: label,
      helperText: helperText,
      value: value,
      min: 0,
      max: 100,
      divisions: 100,
      valueLabel: (v) => '${v.toInt()}%',
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      enabled: enabled,
      leading: leading,
      trailing: trailing,
    );
  }

  factory AppSlider.rating({
    required String label,
    String? helperText,
    required double value,
    required void Function(double) onChanged,
    void Function(double)? onChangeEnd,
    double min = 0,
    double max = 5,
    bool enabled = true,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppSlider(
      label: label,
      helperText: helperText,
      value: value,
      min: min,
      max: max,
      divisions: (max - min).toInt(),
      valueLabel: (v) => v.toStringAsFixed(1),
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      enabled: enabled,
      leading: leading,
      trailing: trailing,
    );
  }

  factory AppSlider.range({
    required String label,
    String? helperText,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required void Function(double) onChanged,
    void Function(double)? onChangeEnd,
    String Function(double)? valueLabel,
    bool enabled = true,
    Widget? leading,
    Widget? trailing,
  }) {
    return AppSlider(
      label: label,
      helperText: helperText,
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      valueLabel: valueLabel,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      enabled: enabled,
      leading: leading,
      trailing: trailing,
    );
  }
}

// Helper widget per il range slider
class AppRangeSlider extends StatelessWidget {
  final String label;
  final String? helperText;
  final RangeValues values;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double, double)? valueLabel;
  final void Function(RangeValues) onChanged;
  final void Function(RangeValues)? onChangeEnd;
  final bool enabled;
  final Color? activeColor;
  final Color? inactiveColor;
  final Widget? leading;
  final Widget? trailing;

  const AppRangeSlider({
    super.key,
    required this.label,
    this.helperText,
    required this.values,
    required this.min,
    required this.max,
    this.divisions,
    this.valueLabel,
    required this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
    this.activeColor,
    this.inactiveColor,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con label e valori
        Row(
          children: [
            if (leading != null) ...[
              leading!,
              SizedBox(width: AppTheme.spacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: enabled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurfaceVariant.withAlpha(128),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (helperText != null) ...[
                    SizedBox(height: AppTheme.spacing.xs),
                    Text(
                      helperText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: enabled
                            ? colorScheme.onSurfaceVariant.withOpacity(0.7)
                            : colorScheme.onSurfaceVariant.withAlpha(128),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.sm,
                vertical: AppTheme.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: enabled
                    ? colorScheme.primaryContainer.withAlpha(76)
                    : colorScheme.surfaceContainerHighest.withAlpha(76),
                borderRadius: BorderRadius.circular(AppTheme.radii.full),
              ),
              child: Text(
                valueLabel?.call(values.start, values.end) ??
                    '${values.start.toStringAsFixed(divisions != null ? 0 : 1)} - ${values.end.toStringAsFixed(divisions != null ? 0 : 1)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: enabled
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withAlpha(128),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) ...[
              SizedBox(width: AppTheme.spacing.sm),
              trailing!,
            ],
          ],
        ),

        SizedBox(height: AppTheme.spacing.md),

        // Range Slider personalizzato
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: enabled
                ? (activeColor ?? colorScheme.primary).withAlpha(76)
                : colorScheme.surfaceContainerHighest.withAlpha(76),
            inactiveTrackColor: enabled
                ? (inactiveColor ?? colorScheme.surfaceContainerHighest)
                    .withAlpha(76)
                : colorScheme.surfaceContainerHighest.withOpacity(0.1),
            thumbColor: enabled
                ? activeColor ?? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            overlayColor:
                (activeColor ?? colorScheme.primary).withOpacity(0.12),
            valueIndicatorColor: colorScheme.primaryContainer,
            valueIndicatorTextStyle: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
            tickMarkShape: const RoundSliderTickMarkShape(),
            activeTickMarkColor: enabled
                ? (activeColor ?? colorScheme.primary).withAlpha(128)
                : colorScheme.surfaceContainerHighest.withAlpha(76),
            inactiveTickMarkColor: enabled
                ? (inactiveColor ?? colorScheme.surfaceContainerHighest)
                    .withAlpha(76)
                : colorScheme.surfaceContainerHighest.withOpacity(0.1),
          ),
          child: RangeSlider(
            values: values,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
            onChangeEnd: enabled ? onChangeEnd : null,
          ),
        ),
      ],
    );
  }
}
