import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../exerciseManager/exercises_services.dart';
import '../../exerciseManager/exercises_manager.dart';
import '../../Main/app_theme.dart';
import '../../UI/components/dialog.dart';

class AddExerciseDialog extends HookConsumerWidget {
  final ExercisesService exercisesService;
  final String userId;

  const AddExerciseDialog(
      {required this.exercisesService, required this.userId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formKey = GlobalKey<FormState>();
    final nameController = useTextEditingController();
    final muscleGroupController = useTextEditingController();
    final typeController = useTextEditingController();

    final muscleGroupsStream = ref.watch(muscleGroupsProvider);
    final exerciseTypesStream = ref.watch(exerciseTypesProvider);

    Widget buildTextField({
      required TextEditingController controller,
      required String label,
      required String? Function(String?) validator,
      IconData? icon,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: TextFormField(
          controller: controller,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(AppTheme.spacing.md),
            labelText: label,
            labelStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 20,
                  )
                : null,
          ),
          validator: validator,
        ),
      );
    }

    Widget buildAutocomplete({
      required AsyncValue<List<String>> optionsValue,
      required TextEditingController controller,
      required String label,
      required String errorMessage,
      required IconData icon,
    }) {
      return optionsValue.when(
        data: (options) => Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Autocomplete<String>(
            optionsBuilder: (textEditingValue) {
              return options.where((option) => option
                  .toLowerCase()
                  .startsWith(textEditingValue.text.toLowerCase()));
            },
            onSelected: (selection) {
              controller.text = selection;
            },
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: textEditingController,
                focusNode: focusNode,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(AppTheme.spacing.md),
                  labelText: label,
                  labelStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(
                    icon,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: 20,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return errorMessage;
                  }
                  return null;
                },
              );
            },
          ),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Errore nel caricamento: $error',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppDialog(
      title: 'Crea Nuovo Esercizio',
      leading: Container(
        padding: EdgeInsets.all(AppTheme.spacing.sm),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        child: Icon(
          Icons.fitness_center,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      actions: [
        AppDialog.buildCancelButton(context: context),
        AppDialog.buildActionButton(
          context: context,
          label: 'Crea',
          icon: Icons.add,
          onPressed: () {
            if (formKey.currentState!.validate()) {
              final name = nameController.text.trim();
              final muscleGroup = [muscleGroupController.text.trim()];
              final type = typeController.text.trim();

              Navigator.pop(context);

              exercisesService.addExercise(
                name,
                muscleGroup,
                type,
                userId,
              );
            }
          },
        ),
      ],
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dettagli Esercizio',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppTheme.spacing.md),
              buildTextField(
                controller: nameController,
                label: 'Nome Esercizio',
                icon: Icons.edit_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci il nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppTheme.spacing.lg),
              buildAutocomplete(
                optionsValue: muscleGroupsStream,
                controller: muscleGroupController,
                label: 'Muscolo Target',
                errorMessage: 'Inserire Muscolo Target',
                icon: Icons.sports_gymnastics,
              ),
              SizedBox(height: AppTheme.spacing.lg),
              buildAutocomplete(
                optionsValue: exerciseTypesStream,
                controller: typeController,
                label: 'Tipologia Esercizio',
                errorMessage: 'Inserire tipologia esercizio',
                icon: Icons.category_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
