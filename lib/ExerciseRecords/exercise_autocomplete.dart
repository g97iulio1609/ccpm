import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/app_search_field.dart';
import '../exerciseManager/exercise_model.dart';
import '../trainingBuilder/dialog/add_exercise_dialog.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import '../providers/providers.dart';

class ExerciseAutocompleteBox extends HookConsumerWidget {
  final TextEditingController controller;
  final Function(ExerciseModel) onSelected;
  final String athleteId;

  const ExerciseAutocompleteBox({
    required this.controller,
    required this.onSelected,
    required this.athleteId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesService = ref.watch(exerciseServiceProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return AppSearchField<ExerciseModel>(
      controller: controller,
      hintText: 'Search Exercise',
      suggestionsCallback: (search) async {
        final exercisesList = await exercisesService.getExercises().first;
        final suggestions = exercisesList
            .where((exercise) => exercise.name.toLowerCase().contains(search.toLowerCase()))
            .toList();
        suggestions.add(ExerciseModel(id: '', name: 'Crea Esercizio', type: '', muscleGroups: []));
        return suggestions;
      },
      itemBuilder: (context, suggestion) {
        return ListTile(title: Text(suggestion.name));
      },
      onSelected: (suggestion) async {
        if (suggestion.name == 'Crea Esercizio') {
          final newExercise = await showAppDialog<ExerciseModel>(
            context: context,
            title: const Text('Crea Esercizio'),
            child: userId != null
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
    );
  }
}
