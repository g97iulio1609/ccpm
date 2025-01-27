import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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

    return TypeAheadField<T>(
      controller: controller,
      suggestionsCallback: suggestionsCallback,
      itemBuilder: itemBuilder,
      onSelected: (T suggestion) {
        onSelected(suggestion);
        FocusScope.of(context).unfocus();
      },
      emptyBuilder: (context) => emptyBuilder ?? const SizedBox.shrink(),
      hideWithKeyboard: true,
      hideOnSelect: true,
      retainOnLoading: false,
      decorationBuilder: (context, child) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(maxHeight: 200),
      focusNode: focusNode,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: this.controller, // Modifica chiave qui
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: labelText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.white,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)
                : null,
          ),
        );
      },
    );
  }
}
