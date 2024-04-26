import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../exerciseManager/exercises_services.dart';
import '../exerciseManager/exercises_Manager.dart';

class AddExerciseDialog extends HookConsumerWidget {
  final ExercisesService exercisesService;

  const AddExerciseDialog({required this.exercisesService, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameController = useTextEditingController();
    final muscleGroupController = useTextEditingController();
    final typeController = useTextEditingController();

    final muscleGroupsStream = ref.watch(muscleGroupsProvider);
    final exerciseTypesStream = ref.watch(exerciseTypesProvider);

    return AlertDialog(
      title: const Text('Crea Nuovo Esercizio'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci il nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            muscleGroupsStream.when(
              data: (muscleGroups) => Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  return muscleGroups.where((muscleGroup) =>
                      muscleGroup.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) {
                  muscleGroupController.text = selection;
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Muscolo Target',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserire Muscolo Target';
                      }
                      return null;
                    },
                  );
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Errore: $error'),
            ),
            const SizedBox(height: 10),
            exerciseTypesStream.when(
              data: (exerciseTypes) => Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  return exerciseTypes.where((exerciseType) =>
                      exerciseType.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) {
                  typeController.text = selection;
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Tipologia Esercizio',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserire tipologia esercizio';
                      }
                      return null;
                    },
                  );
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Errore: $error'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              await exercisesService.addExercise(
                nameController.text.trim(),
                muscleGroupController.text.trim(),
                typeController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Crea'),
        ),
      ],
    );
  }
}