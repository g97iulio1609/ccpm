import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/macros_model.dart';
import '../models/macros_services.dart';

class AutoTypeField extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(Food) onSelected;
  final void Function(String) onChanged;

  const AutoTypeField({
    required this.controller,
    required this.focusNode,
    required this.onSelected,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macrosService = ref.watch(macrosServiceProvider);

    return TypeAheadField<Food>(
      suggestionsCallback: (pattern) async {
        onChanged(pattern);
        try {
          return await macrosService.searchFoods(pattern).first;
        } catch (e) {
          debugPrint('Error fetching suggestions: $e');
          return [];
        }
      },
      itemBuilder: (context, Food suggestion) {
        return ListTile(
          title: Text(suggestion.name),
          subtitle: Text(
            'Brand: ${suggestion.brands}\n'
            'C: ${suggestion.carbs}g, P: ${suggestion.protein}g, F: ${suggestion.fat}g, Kcal:${suggestion.kcal}'
          ),
        );
      },
      onSelected: (Food suggestion) {
        controller.text = suggestion.name;
        onSelected(suggestion);
        FocusScope.of(context).unfocus(); // Close the dropdown
      },
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No items found'),
      ),
      hideWithKeyboard: true,
      hideOnSelect: true,
      retainOnLoading: false,
      decorationBuilder: (context, child) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      offset: const Offset(0, 8),
      constraints: const BoxConstraints(maxHeight: 200),
      controller: controller,
      focusNode: focusNode,
      builder: (context, suggestionsController, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: 'Search Food',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        );
      },
    );
  }
}
