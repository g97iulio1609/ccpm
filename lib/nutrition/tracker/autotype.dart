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
    final suggestionsController = SuggestionsController<String>();

    return TypeAheadField<String>(
      suggestionsController: suggestionsController,
      suggestionsCallback: (pattern) async {
        try {
          await Future.delayed(const Duration(milliseconds: 300));
          return await macrosService.getSuggestions(pattern);
        } catch (e) {
          debugPrint('Error fetching suggestions: $e');
          return [];
        }
      },
      debounceDuration: const Duration(milliseconds: 300),
      itemBuilder: (context, String suggestion) {
        return ListTile(
          title: Text(suggestion),
        );
      },
      onSelected: (String suggestion) async {
        controller.text = suggestion;
        final foods = await macrosService.searchOpenFoodFacts(suggestion);
        if (foods.isNotEmpty) {
          onSelected(foods.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No food found for the selected suggestion')),
          );
        }
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
