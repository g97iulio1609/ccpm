import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/range_controllers.dart';

/// Reusable widget for range input fields (min/max)
class RangeInputField extends StatelessWidget {
  final String label;
  final RangeControllers controllers;
  final IconData icon;
  final String? hint;
  final String? maxHint;
  final Function(String min, String max)? onChanged;
  final bool enabled;

  const RangeInputField({
    super.key,
    required this.label,
    required this.controllers,
    required this.icon,
    this.hint,
    this.maxHint,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controllers.min,
                hint: hint ?? 'Min',
                icon: icon,
                theme: theme,
                colorScheme: colorScheme,
                onChanged: (value) =>
                    onChanged?.call(value, controllers.max.text),
              ),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: _buildTextField(
                controller: controllers.max,
                hint: maxHint ?? 'Max',
                icon: Icons.arrow_upward,
                theme: theme,
                colorScheme: colorScheme,
                onChanged: (value) =>
                    onChanged?.call(controllers.min.text, value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(128),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.spacing.md),
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: colorScheme.onSurfaceVariant.withAlpha(128),
            size: 20,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
