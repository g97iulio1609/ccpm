// exercise_dialog.dart

import 'package:alphanessone/ExerciseRecords/exercise_autocomplete.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/dialog.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../controller/training_program_controller.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

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

    final exerciseNameController =
        useTextEditingController(text: exercise?.name ?? '');
    final variantController =
        useTextEditingController(text: exercise?.variant ?? '');
    final selectedExerciseId = useState<String>(exercise?.exerciseId ?? '');
    final selectedExerciseType = useState<String>(exercise?.type ?? '');

    return AppDialog(
      title: exercise == null ? 'Aggiungi Esercizio' : 'Modifica Esercizio',
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(
          exercise == null ? Icons.add_circle_outline : Icons.edit_outlined,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      actions: [
        AppDialog.buildCancelButton(context: context),
        AppDialog.buildActionButton(
          context: context,
          label: exercise == null ? 'Aggiungi' : 'Aggiorna',
          icon: exercise == null ? Icons.add : Icons.check,
          onPressed: () {
            final newExercise = Exercise(
              id: exercise?.id ?? '',
              exerciseId: selectedExerciseId.value,
              name: exerciseNameController.text,
              type: selectedExerciseType.value,
              variant: variantController.text,
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
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: ExerciseAutocompleteBox(
                controller: exerciseNameController,
                onSelected: (selectedExercise) {
                  if (selectedExercise.id.isNotEmpty) {
                    selectedExerciseId.value = selectedExercise.id;
                    selectedExerciseType.value = selectedExercise.type;
                  }
                },
                athleteId: athleteId,
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
                color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                ),
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
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.tune,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
