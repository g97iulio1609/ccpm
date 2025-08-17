import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/macros_model.dart';
import '../models/macros_services.dart';
import 'package:alphanessone/common/generic_autocomplete.dart';

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

    return GenericAutocompleteField<Food>(
      controller: controller,
      labelText: 'Search Food',
      prefixIcon: Icons.fastfood,
      suggestionsCallback: (pattern) async {
        onChanged(pattern);
        try {
          return await macrosService.searchFoods(pattern).first;
        } catch (e) {
          return [];
        }
      },
      itemBuilder: (context, Food suggestion) {
        return ListTile(
          title: Text(suggestion.name),
          subtitle: Text(
            'Brand: ${suggestion.brands}\nC: ${suggestion.carbs}g, P: ${suggestion.protein}g, F: ${suggestion.fat}g, Kcal:${suggestion.kcal}',
          ),
        );
      },
      onSelected: (Food suggestion) {
        controller.text = suggestion.name;
        onSelected(suggestion);
      },
      onChanged: onChanged,
    );
  }
}
