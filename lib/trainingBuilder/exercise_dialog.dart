import 'package:alphanessone/exerciseManager/exerciseModel.dart';
import 'package:alphanessone/usersServices.dart';
import 'package:alphanessone/trainingBuilder/set_progression_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../exerciseManager/exercisesServices.dart';
import 'trainingModel.dart';
import 'series_dialog.dart';
import 'training_program_controller.dart';
import 'add_exercise_dialog.dart';

class ExerciseDialog extends ConsumerWidget {
  final UsersService usersService;
  final String athleteId;
  final Exercise? exercise;

  const ExerciseDialog({
    required this.usersService,
    required this.athleteId,
    this.exercise,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(trainingProgramControllerProvider);
    final nameController = TextEditingController(text: exercise?.name ?? '');
    final variantController = TextEditingController(text: exercise?.variant ?? '');
    String selectedExerciseId = exercise?.exerciseId ?? '';
    final exercisesService = ref.watch(exercisesServiceProvider);

    return AlertDialog(
      title: Text(exercise == null ? 'Add New Exercise' : 'Edit Exercise'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            StreamBuilder<List<ExerciseModel>>(
              stream: exercisesService.getExercises(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final exercises = snapshot.data!;
                  return Autocomplete<String>(
                    initialValue: TextEditingValue(text: nameController.text),
                    optionsBuilder: (textEditingValue) {
                      final options = exercises
                          .where((exercise) =>
                              exercise.name.toLowerCase().startsWith(textEditingValue.text.toLowerCase()))
                          .map((exercise) => exercise.name)
                          .toList();
                      options.add("Add New Exercise");
                      return options;
                    },
                    onSelected: (selection) async {
                      if (selection == "Add New Exercise") {
                        final newExercise = await showDialog<ExerciseModel>(
                          context: context,
                          builder: (context) => AddExerciseDialog(exercisesService: exercisesService),
                        );
                        if (newExercise != null) {
                          nameController.text = newExercise.name;
                          selectedExerciseId = newExercise.id;
                        }
                      } else {
                        nameController.text = selection;
                        selectedExerciseId = exercises.firstWhere((exercise) => exercise.name == selection).id;
                      }
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      textEditingController.text = nameController.text;
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Exercise',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Failed to load exercises: ${snapshot.error}');
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
            TextFormField(
              controller: variantController,
              decoration: const InputDecoration(labelText: 'Variant'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SetProgressionScreen(
                      exerciseId: selectedExerciseId,
                      exercise: exercise,
                    ),
                  ),
                );
              },
              child: const Text('Set Progression'),
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
          onPressed: () {
            final newExercise = Exercise(
              id: exercise?.id ?? '',
              exerciseId: selectedExerciseId.isNotEmpty ? selectedExerciseId : exercise?.exerciseId ?? '',
              name: nameController.text,
              variant: variantController.text,
              order: exercise?.order ?? 0,
              series: exercise?.series ?? [],
              weekProgressions: exercise?.weekProgressions ?? [],
            );
            Navigator.pop(context, newExercise);
          },
          child: Text(exercise == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}