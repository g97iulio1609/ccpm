import 'package:alphanessone/exerciseManager/exerciseModel.dart';
import 'package:alphanessone/usersServices.dart';
import 'package:alphanessone/trainingBuilder/set_progression_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../exerciseManager/exercisesServices.dart';
import 'trainingModel.dart';
import 'series_dialog.dart';
import 'training_program_controller.dart';

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
                  return Autocomplete<ExerciseModel>(
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<ExerciseModel>.empty();
                      }
                      return exercises.where((exercise) =>
                          exercise.name.toLowerCase().startsWith(textEditingValue.text.toLowerCase()));
                    },
                    displayStringForOption: (exercise) => exercise.name,
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Exercise',
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    onSelected: (selection) {
                      nameController.text = selection.name;
                      selectedExerciseId = selection.id;
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
              id: exercise?.id,
              exerciseId: selectedExerciseId.isNotEmpty ? selectedExerciseId : exercise?.exerciseId,
              name: nameController.text,
              variant: variantController.text,
              order: exercise?.order ?? 0,
              series: exercise?.series ?? [],
              weekProgressions: exercise?.weekProgressions ?? List.generate(
                controller.program.weeks.length,
                (index) => WeekProgression(
                  weekNumber: index + 1,
                  reps: 0,
                  sets: 0,
                  intensity: '',
                  rpe: '',
                  weight: 0,
                ),
              ),
            );
            Navigator.pop(context, newExercise);
          },
          child: Text(exercise == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}