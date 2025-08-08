import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/dialog.dart';
import 'package:alphanessone/shared/shared.dart';
import '../forms/bulk_series_form.dart';

class BulkSeriesSelectionDialog extends HookConsumerWidget {
  final Exercise initialExercise;
  final List<Exercise> workoutExercises;
  final Function(List<Exercise>) onNext;

  const BulkSeriesSelectionDialog({
    super.key,
    required this.initialExercise,
    required this.workoutExercises,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedExercises = useState<List<Exercise>>([initialExercise]);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      title: 'Gestione Serie in Bulk',
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(
          Icons.format_list_numbered,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      actions: [
        AppDialog.buildCancelButton(context: context),
        AppDialog.buildActionButton(
          context: context,
          label: 'Gestisci Serie',
          icon: Icons.playlist_add,
          onPressed: () {
            Navigator.pop(context);
            onNext(selectedExercises.value);
          },
        ),
      ],
      children: [
        _buildExerciseSelection(context, selectedExercises, theme, colorScheme),
      ],
    );
  }

  Widget _buildExerciseSelection(
    BuildContext context,
    ValueNotifier<List<Exercise>> selectedExercises,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleziona gli Esercizi',
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        ...workoutExercises.map(
          (exercise) => _buildExerciseCheckbox(
            exercise,
            selectedExercises,
            theme,
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCheckbox(
    Exercise exercise,
    ValueNotifier<List<Exercise>> selectedExercises,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return CheckboxListTile(
      value: selectedExercises.value.contains(exercise),
      onChanged: (checked) {
        if (checked ?? false) {
          selectedExercises.value = [...selectedExercises.value, exercise];
        } else {
          selectedExercises.value = selectedExercises.value
              .where((selected) => selected.id != exercise.id)
              .toList();
        }
      },
      title: Text(
        exercise.name,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: (exercise.variant?.isNotEmpty ?? false)
          ? Text(
              exercise.variant!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      secondary: Container(
        padding: EdgeInsets.all(AppTheme.spacing.xs),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Text(
          exercise.type,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class BulkSeriesConfigurationDialog extends HookConsumerWidget {
  final List<Exercise> exercises;
  final Function(List<Exercise>) onApply;

  const BulkSeriesConfigurationDialog({
    super.key,
    required this.exercises,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      title: 'Configura Serie',
      subtitle: 'Le serie verranno applicate a ${exercises.length} esercizi',
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(
          Icons.playlist_add_check,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      actions: [
        AppDialog.buildCancelButton(context: context),
        AppDialog.buildActionButton(
          context: context,
          label: 'Applica',
          icon: Icons.check,
          onPressed: () => _handleApply(context),
        ),
      ],
      children: [
        BulkSeriesForm(
          exercises: exercises,
          onApply: (updatedExercises) {
            onApply(updatedExercises);
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  void _handleApply(BuildContext context) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Serie aggiornate per ${exercises.length} esercizi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
