import 'package:alphanessone/exerciseManager/exercise_model.dart';
import 'package:alphanessone/users_services.dart';
import 'package:alphanessone/trainingBuilder/set_progression_screen.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../exerciseManager/exercises_services.dart';
import 'training_model.dart';
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
        List<ExerciseModel> exercises = []; // Aggiungi questa riga


    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      contentTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      title: Text(exercise == null ? 'Add New Exercise' : 'Edit Exercise'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            StreamBuilder<List<ExerciseModel>>(
              stream: exercisesService.getExercises(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  exercises = snapshot.data!; // Aggiorna il valore di exercises qui
                  return RawAutocomplete<String>(
                    textEditingController: nameController,
                    focusNode: FocusNode(),
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
                          exercises.firstWhere((exercise) => exercise.name == selection);
                      }
                    },
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController,
                        FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      return TextFormField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Exercise',
                          labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.outline,
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
                    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected,
                        Iterable<String> options) {
                      return Material(
                        elevation: 4,
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.3,
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () {
                                  onSelected(option);
                                },
                                child: Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Text(
                                    option,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
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
            const SizedBox(height: 16),
            TextFormField(
              controller: variantController,
              decoration: InputDecoration(
                labelText: 'Variant',
                labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
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
            ),
            const SizedBox(height: 16),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Set Progression'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newExercise = Exercise(
              id: exercise?.id ?? '',
              exerciseId: selectedExerciseId.isNotEmpty ? selectedExerciseId : exercise?.exerciseId ?? '',
              name: nameController.text,
    type: exercise?.type ?? exercises.firstWhere((e) => e.id == selectedExerciseId).type,
              variant: variantController.text,
              order: exercise?.order ?? 0,
              series: exercise?.series ?? [],
              weekProgressions: exercise?.weekProgressions ?? [],
            );
            Navigator.pop(context, newExercise);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(exercise == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}