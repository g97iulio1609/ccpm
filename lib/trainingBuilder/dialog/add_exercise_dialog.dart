import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../exerciseManager/exercises_services.dart';
import '../../exerciseManager/exercises_manager.dart';
import '../../Main/app_theme.dart';
import '../../UI/components/dialog.dart';
import '../../common/generic_autocomplete.dart';

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

    // State per i muscoli target selezionati
    final selectedMuscleGroups = useState<List<String>>([]);

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
          color: colorScheme.surfaceContainerHighest.withAlpha(26),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          border: Border.all(
            color: colorScheme.outline.withAlpha(26),
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

    Widget buildMuscleGroupsSelector() {
      return muscleGroupsStream.when(
        data: (muscleGroups) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GenericAutocompleteField<String>(
              controller: muscleGroupController,
              labelText: 'Muscolo Target',
              prefixIcon: Icons.sports_gymnastics,
              suggestionsCallback: (pattern) async {
                return muscleGroups
                    .where((muscleGroup) =>
                        muscleGroup
                            .toLowerCase()
                            .contains(pattern.toLowerCase()) &&
                        !selectedMuscleGroups.value.contains(muscleGroup))
                    .toList();
              },
              itemBuilder: (context, muscleGroup) => ListTile(
                title: Text(muscleGroup),
                leading: const Icon(Icons.fitness_center),
              ),
              onSelected: (muscleGroup) {
                muscleGroupController.clear();
                if (!selectedMuscleGroups.value.contains(muscleGroup)) {
                  selectedMuscleGroups.value = [
                    ...selectedMuscleGroups.value,
                    muscleGroup
                  ];
                }
              },
            ),
            if (selectedMuscleGroups.value.isNotEmpty) ...[
              SizedBox(height: AppTheme.spacing.md),
              Wrap(
                spacing: AppTheme.spacing.sm,
                runSpacing: AppTheme.spacing.sm,
                children: selectedMuscleGroups.value.map((muscleGroup) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radii.full),
                        onTap: () {
                          selectedMuscleGroups.value = selectedMuscleGroups
                              .value
                              .where((m) => m != muscleGroup)
                              .toList();
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.md,
                            vertical: AppTheme.spacing.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              SizedBox(width: AppTheme.spacing.xs),
                              Text(
                                muscleGroup,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                              SizedBox(width: AppTheme.spacing.xs),
                              Icon(
                                Icons.close,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
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
            color: colorScheme.errorContainer.withAlpha(26),
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

    Widget buildTypeSelector() {
      return exerciseTypesStream.when(
        data: (types) => GenericAutocompleteField<String>(
          controller: typeController,
          labelText: 'Tipologia Esercizio',
          prefixIcon: Icons.category_outlined,
          suggestionsCallback: (pattern) async {
            return types
                .where((type) =>
                    type.toLowerCase().contains(pattern.toLowerCase()))
                .toList();
          },
          itemBuilder: (context, type) => ListTile(
            title: Text(type),
            leading: const Icon(Icons.category_outlined),
          ),
          onSelected: (type) {
            typeController.text = type;
          },
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
            color: colorScheme.errorContainer.withAlpha(26),
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
          color: colorScheme.primaryContainer.withAlpha(76),
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
            if (formKey.currentState!.validate() &&
                selectedMuscleGroups.value.isNotEmpty) {
              final name = nameController.text.trim();
              final type = typeController.text.trim();

              Navigator.pop(context);

              exercisesService.addExercise(
                name,
                selectedMuscleGroups.value,
                type,
                userId,
              );
            } else if (selectedMuscleGroups.value.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: colorScheme.onError),
                      const SizedBox(width: 8),
                      const Text('Seleziona almeno un muscolo target'),
                    ],
                  ),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
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
              buildMuscleGroupsSelector(),
              SizedBox(height: AppTheme.spacing.lg),
              buildTypeSelector(),
            ],
          ),
        ),
      ],
    );
  }
}
