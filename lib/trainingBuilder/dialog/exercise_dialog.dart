// exercise_dialog.dart

import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/training_providers.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/exerciseManager/exercise_model.dart';

class ExerciseDialog extends HookConsumerWidget {
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
    ref.watch(trainingProgramControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final exerciseNameController = useTextEditingController(
      text: exercise?.name ?? '',
    );
    final variantController = useTextEditingController(
      text: exercise?.variant ?? '',
    );
    final selectedExerciseId = useState<String>(exercise?.exerciseId ?? '');
    final selectedExerciseType = useState<String>(exercise?.type ?? '');

    final exercisesService = ref.watch(exercisesServiceProvider);
    final exercisesStream = useMemoized(() => exercisesService.getExercises());
    final exercisesSnapshot = useStream(exercisesStream);
    final List<ExerciseModel> exercisesList = exercisesSnapshot.data ?? [];

    return AppDialog(
      title: exercise == null ? 'Aggiungi Esercizio' : 'Modifica Esercizio',
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(
          exercise == null ? Icons.add_circle_outline : Icons.edit_outlined,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      actions: [
        AppDialogHelpers.buildCancelButton(context: context),
        AppDialogHelpers.buildActionButton(
          context: context,
          label: exercise == null ? 'Aggiungi' : 'Aggiorna',
          icon: exercise == null ? Icons.add : Icons.check,
          onPressed: () {
            final newExercise = Exercise(
              id: exercise?.id, // lascia null per nuovi esercizi
              exerciseId: selectedExerciseId.value,
              name: exerciseNameController.text,
              type: selectedExerciseType.value,
              variant: variantController.text,
              // l'ordine verrà assegnato dal servizio in base alla posizione
              order: exercise?.order ?? 0,
              series: exercise?.series ?? [],
              weekProgressions: exercise?.weekProgressions ?? [],
            );
            Navigator.pop(context, newExercise);
          },
        ),
      ],
      children: [
        // Exercise Name Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nome Esercizio',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppTheme.spacing.xs),
            // Autocomplete coerente con AppTheme + Glass lite
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(26),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(color: colorScheme.outline.withAlpha(26)),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  searchViewTheme: SearchViewThemeData(
                    // Slightly higher opacity for better readability
                    backgroundColor: colorScheme.surfaceContainerHighest.withAlpha(184),
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      side: BorderSide(color: colorScheme.outline.withAlpha(90)),
                    ),
                  ),
                ),
                child: SearchAnchor(
                  isFullScreen: false,
                  builder: (context, controller) {
                    return SearchBar(
                      controller: controller,
                      hintText: 'Cerca esercizio',
                      leading: Icon(Icons.search, color: colorScheme.primary),
                      onTap: controller.openView,
                      onChanged: (_) => controller.openView(),
                      onSubmitted: (value) {
                        exerciseNameController.text = value;
                      },
                    padding: MaterialStatePropertyAll(
                      EdgeInsets.all(AppTheme.spacing.md),
                    ),
                    elevation: const MaterialStatePropertyAll(0),
                    backgroundColor: MaterialStatePropertyAll(
                      // Match the overlay with higher opacity
                      colorScheme.surfaceContainerHighest.withAlpha(184),
                    ),
                    shape: MaterialStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      side: BorderSide(
                        color: colorScheme.outline.withAlpha(90),
                      ),
                       ),
                     ),
                   );
                 },
                  suggestionsBuilder: (context, controller) {
                    final query = controller.text.toLowerCase();
                    final filtered = query.isEmpty
                        ? exercisesList
                        : exercisesList
                              .where((e) => e.name.toLowerCase().contains(query))
                              .toList();
                    return filtered.map((e) {
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withAlpha(196),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.fitness_center,
                            color: colorScheme.primary,
                          ),
                          title: Text(e.name),
                          onTap: () {
                            controller.closeView(e.name);
                            exerciseNameController.text = e.name;
                            selectedExerciseId.value = e.id;
                            selectedExerciseType.value = e.type;
                          },
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
          ],
        ),

        // Variant Field
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variante',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppTheme.spacing.xs),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(26),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(color: colorScheme.outline.withAlpha(26)),
              ),
              child: TextFormField(
                controller: variantController,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(AppTheme.spacing.md),
                  hintText: 'Inserisci la variante',
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  prefixIcon: Icon(
                    Icons.tune,
                    color: colorScheme.onSurfaceVariant.withAlpha(179),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
