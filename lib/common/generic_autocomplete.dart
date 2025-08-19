import 'package:flutter/material.dart';
import 'app_autocomplete.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';

class GenericAutocompleteField<T> extends HookConsumerWidget {
  final TextEditingController controller;
  final String labelText;
  final Future<List<T>> Function(String) suggestionsCallback;
  final Widget Function(BuildContext, T) itemBuilder;
  final void Function(T) onSelected;
  final void Function(String)? onChanged;
  final Widget? emptyBuilder;
  final IconData? prefixIcon;

  const GenericAutocompleteField({
    required this.controller,
    required this.labelText,
    required this.suggestionsCallback,
    required this.itemBuilder,
    required this.onSelected,
    this.onChanged,
    this.emptyBuilder,
    this.prefixIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode();
    final glassEnabled = ref.watch(uiGlassEnabledProvider);

    return AppAutocompleteField<T>(
      controller: controller,
      suggestionsCallback: suggestionsCallback,
      itemBuilder: itemBuilder,
      onSelected: (T suggestion) {
        onSelected(suggestion);
        FocusScope.of(context).unfocus();
      },
      emptyBuilder: (context) => emptyBuilder ?? const SizedBox.shrink(),
      decorationBuilder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        if (glassEnabled) {
          return GlassLite(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withAlpha(38)),
                ),
                child: child,
              ),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withAlpha(38)),
          ),
          child: child,
        );
      },
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(maxHeight: 200),
      focusNode: focusNode,
      builder: (context, controller, focusNode) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final input = TextField(
          controller: this.controller,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: labelText,
            filled: false,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withAlpha(64),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withAlpha(38),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: colorScheme.onSurfaceVariant)
                : null,
          ),
        );
        return glassEnabled
            ? GlassLite(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: input,
              )
            : input;
      },
    );
  }
}
