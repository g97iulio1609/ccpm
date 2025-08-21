import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/Main/app_theme.dart';

class NumberInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hint;
  final bool isDecimal;
  final Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  const NumberInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hint,
    this.isDecimal = true,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(128)),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: isDecimal
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        inputFormatters: isDecimal
            ? [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text.replaceAll(',', '.');
                  return newValue.copyWith(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                }),
              ]
            : [FilteringTextInputFormatter.digitsOnly],
        style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.spacing.md),
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant.withAlpha(128), size: 20),
          labelStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant.withAlpha(128),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
