import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/shared/shared.dart';

class BulkExerciseDeleteDialog extends HookConsumerWidget {
  final List<Exercise> workoutExercises;
  final Exercise initialSelection;
  final void Function(List<Exercise>) onConfirm;

  const BulkExerciseDeleteDialog({
    super.key,
    required this.workoutExercises,
    required this.initialSelection,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = useState<List<Exercise>>([initialSelection]);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final double listHeight = (screenHeight * 0.45).clamp(240.0, 520.0) as double;

    final allSelected = selected.value.length == workoutExercises.length;

    return AppDialog(
      title: 'Elimina Esercizi (Bulk)',
      subtitle: 'Seleziona uno o più esercizi da rimuovere',
      maxHeight: screenHeight * 0.85,
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(Icons.delete_sweep_outlined, color: colorScheme.error, size: 24),
      ),
      actions: [
        AppDialogHelpers.buildCancelButton(context: context),
        AppDialogHelpers.buildActionButton(
          context: context,
          label: 'Elimina (${selected.value.length})',
          icon: Icons.delete_outline,
          isPrimary: false,
          isDestructive: true,
          onPressed: () {
            Navigator.pop(context);
            onConfirm(selected.value);
          },
        ),
      ],
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seleziona esercizi',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                if (allSelected) {
                  selected.value = [initialSelection];
                } else {
                  selected.value = List<Exercise>.from(workoutExercises);
                }
              },
              icon: Icon(allSelected ? Icons.remove_done : Icons.done_all),
              label: Text(allSelected ? 'Deseleziona Tutti' : 'Seleziona Tutti'),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        SizedBox(
          height: listHeight,
          child: Scrollbar(
            child: ListView.separated(
              itemCount: workoutExercises.length,
              separatorBuilder: (_, __) => SizedBox(height: AppTheme.spacing.xs),
              itemBuilder: (context, index) {
                final exercise = workoutExercises[index];
                final isChecked = selected.value.contains(exercise);
                return CheckboxListTile(
                  value: isChecked,
                  onChanged: (checked) {
                    if (checked ?? false) {
                      if (!isChecked) {
                        selected.value = [...selected.value, exercise];
                      }
                    } else {
                      selected.value = selected.value
                          .where((e) => e.id != exercise.id)
                          .toList();
                    }
                  },
                  title: Text(
                    exercise.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: (exercise.variant?.isNotEmpty ?? false)
                      ? Text(
                          exercise.variant!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      : null,
                  secondary: Container(
                    padding: EdgeInsets.all(AppTheme.spacing.xs),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                    ),
                    child: Text(
                      exercise.type,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
