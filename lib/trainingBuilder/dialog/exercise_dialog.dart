import 'package:alphanessone/exerciseManager/exercise_model.dart';
import 'package:alphanessone/services/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../exerciseManager/exercises_services.dart';
import '../controller/training_program_controller.dart';
import 'add_exercise_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseDialog extends ConsumerWidget {
  final ExerciseRecordService exerciseRecordService;
  final String athleteId;
  final Exercise? exercise;

  const ExerciseDialog({
    required this.exerciseRecordService,
    required this.athleteId,
    this.exercise,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(trainingProgramControllerProvider);
    final exerciseNameController = TextEditingController(text: exercise?.name ?? '');
    final variantController = TextEditingController(text: exercise?.variant ?? '');
    String selectedExerciseId = exercise?.exerciseId ?? '';
    String selectedExerciseType = exercise?.type ?? '';

    final exercisesService = ref.watch(exercisesServiceProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      contentTextStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
      title: Text(exercise == null ? 'Aggiungi Esercizio' : 'Modifica Esercizio'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TypeAheadField<ExerciseModel>(
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
                    exerciseNameController.text = newExercise.name;
                    selectedExerciseId = newExercise.id;
                    selectedExerciseType = newExercise.type;
                  }
                } else {
                  exerciseNameController.text = suggestion.name;
                  selectedExerciseId = suggestion.id;
                  selectedExerciseType = suggestion.type;
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
              controller: exerciseNameController,
              focusNode: FocusNode(),
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
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: variantController,
              decoration: InputDecoration(
                labelText: 'Variante',
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
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            final newExercise = Exercise(
              id: exercise?.id ?? '',
              exerciseId: selectedExerciseId,
              name: exerciseNameController.text,
              type: selectedExerciseType,
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
          child: Text(exercise == null ? 'Aggiungi' : 'Aggiorna'),
        ),
      ],
    );
  }
}
