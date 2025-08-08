import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alphanessone/Main/app_theme.dart';

class AppInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? suffixText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final FocusNode? focusNode;
  final bool isRequired;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;

  const AppInput({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.hintText,
    this.prefixIcon,
    this.suffix,
    this.suffixText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.focusNode,
    this.isRequired = false,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
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

        SizedBox(height: AppTheme.spacing.xs),

        // Input Field
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurface.withAlpha(128),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: enabled
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withAlpha(128),
                    size: 20,
                  )
                : null,
            suffix: suffix,
            suffixText: suffixText,
            suffixStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: enabled
                ? colorScheme.surfaceContainerHighest.withAlpha(76)
                : colorScheme.surfaceContainerHighest.withAlpha(26),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.md,
              vertical: AppTheme.spacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              borderSide: BorderSide(color: colorScheme.outline.withAlpha(26)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              borderSide: BorderSide(color: colorScheme.outline.withAlpha(26)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
              borderSide: BorderSide(color: colorScheme.error, width: 2),
            ),
          ),
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
        ),
      ],
    );
  }

  // Factory constructors per varianti comuni
  factory AppInput.text({
    required TextEditingController controller,
    required String label,
    String? helperText,
    String? hintText,
    IconData? prefixIcon,
    bool isRequired = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool enabled = true,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      helperText: helperText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      isRequired: isRequired,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  factory AppInput.email({
    required TextEditingController controller,
    String label = 'Email',
    String? helperText,
    bool isRequired = true,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      helperText: helperText,
      hintText: 'Inserisci la tua email',
      prefixIcon: Icons.email_outlined,
      isRequired: isRequired,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Inserisci un\'email valida';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Inserisci un\'email valida';
        }
        return null;
      },
    );
  }

  factory AppInput.password({
    required TextEditingController controller,
    String label = 'Password',
    String? helperText,
    bool isRequired = true,
    bool enabled = true,
    void Function(String)? onChanged,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      helperText: helperText,
      hintText: 'Inserisci la password',
      prefixIcon: Icons.lock_outline,
      isRequired: isRequired,
      enabled: enabled,
      onChanged: onChanged,
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Inserisci una password';
        }
        if (value.length < 6) {
          return 'La password deve contenere almeno 6 caratteri';
        }
        return null;
      },
    );
  }

  factory AppInput.number({
    required TextEditingController controller,
    required String label,
    String? helperText,
    String? hintText,
    IconData? prefixIcon,
    String? suffixText,
    bool isRequired = false,
    bool enabled = true,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      helperText: helperText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixText: suffixText,
      isRequired: isRequired,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
    );
  }

  factory AppInput.multiline({
    required TextEditingController controller,
    required String label,
    String? helperText,
    String? hintText,
    IconData? prefixIcon,
    bool isRequired = false,
    bool enabled = true,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
    int minLines = 3,
    int maxLines = 5,
  }) {
    return AppInput(
      controller: controller,
      label: label,
      helperText: helperText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      isRequired: isRequired,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
