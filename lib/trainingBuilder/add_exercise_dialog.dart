import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../exerciseManager/exerciseModel.dart';
import '../exerciseManager/exercisesServices.dart';
import '../exerciseManager/exerciseList.dart';

class AddExerciseDialog extends HookConsumerWidget {
  final ExercisesService exercisesService;

  const AddExerciseDialog({required this.exercisesService, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = useTextEditingController();
    final _muscleGroupController = useTextEditingController();
    final _typeController = useTextEditingController();

    final muscleGroupsStream = ref.watch(muscleGroupsProvider);
    final exerciseTypesStream = ref.watch(exerciseTypesProvider);

    return AlertDialog(
      title: const Text('Add New Exercise'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
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
                  _muscleGroupController.text = selection;
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Muscle Group',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a muscle group';
                      }
                      return null;
                    },
                  );
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
            const SizedBox(height: 10),
            exerciseTypesStream.when(
              data: (exerciseTypes) => Autocomplete<String>(
                optionsBuilder: (textEditingValue) {
                  return exerciseTypes.where((exerciseType) =>
                      exerciseType.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) {
                  _typeController.text = selection;
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an exercise type';
                      }
                      return null;
                    },
                  );
                },
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await exercisesService.addExercise(
                _nameController.text.trim(),
                _muscleGroupController.text.trim(),
                _typeController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}