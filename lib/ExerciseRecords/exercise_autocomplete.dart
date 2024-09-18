// exercise_autocomplete_box.dart

import 'package:alphanessone/exerciseManager/exercise_model.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/dialog/add_exercise_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart'; // Importa flutter_hooks
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseAutocompleteBox extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(ExerciseModel) onSelected;
  final ExerciseRecordService exerciseRecordService;
  final String athleteId;

  const ExerciseAutocompleteBox({
    required this.controller,
    required this.onSelected,
    required this.exerciseRecordService,
    required this.athleteId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesService = ref.watch(exercisesServiceProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Usa useFocusNode per gestire il FocusNode
    final focusNode = useFocusNode();

    return TypeAheadField<ExerciseModel>(
      suggestionsCallback: (search) async {
        final exercises = await exercisesService.getExercises().first;
        final suggestions = exercises
            .where((exercise) => exercise.name.toLowerCase().contains(search.toLowerCase()))
            .toList();
        suggestions.add(ExerciseModel(id: '', name: 'Crea Esercizio', type: '', muscleGroup: ''));
        return suggestions;
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion.name),
        );
      },
      onSelected: (suggestion) async {
        if (suggestion.name == 'Crea Esercizio') {
          final newExercise = await showDialog<ExerciseModel>(
            context: context,
            builder: (context) => userId != null
                ? AddExerciseDialog(exercisesService: exercisesService, userId: userId)
                : const SizedBox.shrink(),
          );
          if (newExercise != null) {
            controller.text = newExercise.name;
            onSelected(newExercise);
          }
        } else {
          controller.text = suggestion.name;
          onSelected(suggestion);
        }
      },
      emptyBuilder: (context) => const SizedBox.shrink(),
      hideWithKeyboard: true,
      hideOnSelect: true,
      retainOnLoading: false,
      offset: const Offset(0, 8),
      decorationBuilder: (context, suggestionsBox) {
        return Material(
          elevation: 4,
          color: Theme.of(context).colorScheme.surface,
          child: suggestionsBox,
        );
      },
      controller: controller,
      focusNode: focusNode, // Usa il focusNode gestito
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Colors.white,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }
}
