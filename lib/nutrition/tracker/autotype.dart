import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models&Services/macros_model.dart';
import '../models&Services/macros_services.dart';

class AutoTypeField extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(Food) onSelected;

  const AutoTypeField({
    required this.controller,
    required this.focusNode,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final macrosService = ref.watch(macrosServiceProvider);

    return TypeAheadField<Food>(
      suggestionsCallback: (pattern) async {
        try {
          return await macrosService.searchFoods(pattern).first;
        } catch (e) {
          debugPrint('Error fetching suggestions: $e');
          return [];
        }
      },
      debounceDuration: const Duration(milliseconds: 500),
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
      },
      errorBuilder: (context, error) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Error: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
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
          borderRadius: BorderRadius.circular(10),
          child: child,
        );
      },
      controller: controller,
      focusNode: focusNode,
      builder: (context, suggestionsController, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Search Food',
          ),
        );
      },
    );
  }
}
