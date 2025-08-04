// lib/exerciseManager/exercises_manager.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_model.dart';
import '../providers/providers.dart';
import 'widgets/exercise_widgets.dart';
import 'controllers/exercise_list_controller.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/icon_button_with_background.dart';
import 'package:alphanessone/UI/components/bottom_input_form.dart';

// Providers per i muscleGroups e exerciseTypes
final muscleGroupsProvider = StreamProvider<List<String>>((ref) {
  return FirebaseFirestore.instance.collection('muscleGroups').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => doc['name'].toString()).toList());
});

final exerciseTypesProvider = StreamProvider<List<String>>((ref) {
  return FirebaseFirestore.instance.collection('ExerciseTypes').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => doc['name'].toString()).toList());
});

class ExercisesManager extends ConsumerWidget {
  const ExercisesManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ExercisesList();
  }

  // Funzione per mostrare il Bottom Sheet per aggiungere un esercizio
  static void showAddExerciseBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ExerciseForm(
        exercise: null,
        userId: ref.read(usersServiceProvider).getCurrentUserId(),
      ),
    );
  }

  // Funzione per mostrare il Bottom Sheet per modificare un esercizio
  static void showEditExerciseBottomSheet(
      BuildContext context, WidgetRef ref, ExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _ExerciseForm(
        exercise: exercise,
        userId: ref.read(usersServiceProvider).getCurrentUserId(),
      ),
    );
  }
}

class ExercisesList extends HookConsumerWidget {
  const ExercisesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final selectedMuscleGroups = useState<List<String>>([]);
    // Rimosso: selectedExerciseType locale non utilizzato per evitare warning.
    final exercisesState = ref.watch(exerciseListControllerProvider);
    final controller = ref.watch(exerciseListControllerProvider.notifier);
    final currentUserRole = ref.watch(userRoleProvider);
    final currentUserId = ref.read(usersServiceProvider).getCurrentUserId();
    final theme = Theme.of(context);

    final muscleGroupsAsyncValue = ref.watch(muscleGroupsProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withAlpha(235),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            TypeAheadField<ExerciseModel>(
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search exercise...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              controller.clear();
                              Future.microtask(() {
                                ref
                                    .read(
                                        exerciseListControllerProvider.notifier)
                                    .resetFilters();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                );
              },
              suggestionsCallback: (pattern) async {
                if (pattern.length < 2) return [];

                final exercises = await ref
                    .read(exercisesServiceProvider)
                    .getExercises()
                    .first;
                return exercises
                    .where((exercise) => exercise.name
                        .toLowerCase()
                        .contains(pattern.toLowerCase()))
                    .toList();
              },
              itemBuilder: (context, exercise) {
                return ListTile(
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${exercise.muscleGroups.join(", ")} - ${exercise.type}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: -0.3,
                        ),
                  ),
                );
              },
              onSelected: (exercise) {
                searchController.text = exercise.name;
                Future.microtask(() {
                  controller.updateFilters(searchText: exercise.name);
                });
              },
              debounceDuration: const Duration(milliseconds: 500),
              hideOnEmpty: false,
              hideOnLoading: false,
              hideOnError: false,
              animationDuration: const Duration(milliseconds: 300),
              constraints: const BoxConstraints(maxHeight: 300),
              decorationBuilder: (context, child) {
                return Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                  child: child,
                );
              },
              loadingBuilder: (context) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              errorBuilder: (context, error) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              emptyBuilder: (context) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No exercises found'),
              ),
            ),
            const SizedBox(height: 16),
            muscleGroupsAsyncValue.when(
              data: (muscleGroups) => SizedBox(
                height: 48,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                    physics: const BouncingScrollPhysics(),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          ...muscleGroups.map((group) {
                            final isSelected =
                                selectedMuscleGroups.value.contains(group);
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: SizedBox(
                                height: 32,
                                child: FilterChip(
                                  label: Text(
                                    group,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? theme
                                              .colorScheme.onSecondaryContainer
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      selectedMuscleGroups.value = [
                                        ...selectedMuscleGroups.value,
                                        group
                                      ];
                                    } else {
                                      selectedMuscleGroups.value =
                                          selectedMuscleGroups.value
                                              .where((g) => g != group)
                                              .toList();
                                    }
                                    controller.updateFilters(
                                      muscleGroups: selectedMuscleGroups.value,
                                    );
                                  },
                                  showCheckmark: false,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  labelPadding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  avatar: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 16,
                                          color: theme
                                              .colorScheme.onSecondaryContainer,
                                        )
                                      : null,
                                  selectedColor:
                                      theme.colorScheme.secondaryContainer,
                                  backgroundColor: theme
                                      .colorScheme.surfaceContainerHighest
                                      .withAlpha(128),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSelected
                                          ? theme.colorScheme.secondary
                                          : theme.colorScheme.outline
                                              .withAlpha(26),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                          if (selectedMuscleGroups.value.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: SizedBox(
                                height: 32,
                                child: TextButton.icon(
                                  onPressed: () {
                                    selectedMuscleGroups.value = [];
                                    controller.updateFilters(muscleGroups: []);
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: theme.colorScheme.error,
                                  ),
                                  label: Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              loading: () => const SizedBox(
                height: 48,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => SizedBox(
                height: 48,
                child: Center(
                  child: Text(
                    'Error loading muscle groups',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: exercisesState.when(
                data: (exercises) {
                  return ExercisesGrid(
                    exercises: exercises,
                    currentUserRole: currentUserRole,
                    currentUserId: currentUserId,
                    onEdit: (exercise) =>
                        ExercisesManager.showEditExerciseBottomSheet(
                            context, ref, exercise),
                    onDelete: (exercise) => _showDeleteConfirmationDialog(
                      context,
                      exercise,
                      ref,
                      theme,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    ExerciseModel exercise,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomInputForm(
        title: 'Elimina Esercizio',
        subtitle: 'Sei sicuro di voler eliminare questo esercizio?',
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withAlpha(76),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.delete_outline,
            color: colorScheme.error,
            size: 24,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final exercisesService = ref.read(exercisesServiceProvider);
                  exercisesService.deleteExercise(exercise.id);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.lg,
                    vertical: AppTheme.spacing.md,
                  ),
                  child: Text(
                    'Elimina',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        children: [
          Text(
            'Questa azione non può essere annullata.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ExercisesGrid extends ConsumerStatefulWidget {
  final List<ExerciseModel> exercises;
  final String currentUserRole;
  final String currentUserId;
  final Function(ExerciseModel) onEdit;
  final Function(ExerciseModel) onDelete;

  const ExercisesGrid({
    super.key,
    required this.exercises,
    required this.currentUserRole,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<ExercisesGrid> createState() => _ExercisesGridState();
}

class _ExercisesGridState extends ConsumerState<ExercisesGrid> {
  void _showExerciseDetails(BuildContext context, ExerciseModel exercise) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: exercise.name,
        subtitle: exercise.muscleGroups.join(", "),
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
        items: [
          BottomMenuItem(
            title: 'Modifica Esercizio',
            icon: Icons.edit_outlined,
            onTap: () {
              widget.onEdit(exercise);
            },
          ),
          BottomMenuItem(
            title: 'Elimina Esercizio',
            icon: Icons.delete_outline,
            onTap: () {
              widget.onDelete(exercise);
            },
            isDestructive: true,
          ),
          if ((widget.currentUserRole == 'admin' ||
                  widget.currentUserRole == 'coach') &&
              exercise.status == 'pending')
            BottomMenuItem(
              title: 'Approva Esercizio',
              icon: Icons.check_circle_outline,
              onTap: () {
                _approveExercise(exercise);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcola il numero di colonne
    final crossAxisCount = _getGridCrossAxisCount(context);

    // Organizza gli esercizi in righe
    final rows = <List<ExerciseModel>>[];
    for (var i = 0; i < widget.exercises.length; i += crossAxisCount) {
      rows.add(
        widget.exercises.sublist(
          i,
          i + crossAxisCount > widget.exercises.length
              ? widget.exercises.length
              : i + crossAxisCount,
        ),
      );
    }

    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (context, index) => SizedBox(height: 24.0),
      itemBuilder: (context, rowIndex) {
        final rowExercises = rows[rowIndex];

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < crossAxisCount; i++) ...[
                if (i < rowExercises.length)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < crossAxisCount - 1 ? 24.0 : 0,
                      ),
                      child: ExerciseCardContent(
                        exercise: rowExercises[i],
                        onTap: () =>
                            _showExerciseDetails(context, rowExercises[i]),
                        actions:
                            _buildExerciseActions(context, rowExercises[i]),
                      ),
                    ),
                  )
                else
                  Expanded(child: Container()), // Placeholder per celle vuote
              ],
            ],
          ),
        );
      },
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  List<Widget> _buildExerciseActions(
      BuildContext context, ExerciseModel exercise) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actions = <Widget>[];

    // Azione Modifica
    actions.add(
      IconButtonWithBackground(
        icon: Icons.edit_outlined,
        color: colorScheme.primary,
        onPressed: () => widget.onEdit(exercise),
        tooltip: 'Modifica',
      ),
    );

    // Azione Elimina
    actions.add(
      IconButtonWithBackground(
        icon: Icons.delete_outline,
        color: colorScheme.error,
        onPressed: () => widget.onDelete(exercise),
        tooltip: 'Elimina',
      ),
    );

    // Azione Approva (solo per admin/coach)
    if ((widget.currentUserRole == 'admin' ||
            widget.currentUserRole == 'coach') &&
        exercise.status == 'pending') {
      actions.add(
        IconButtonWithBackground(
          icon: Icons.check_circle_outline,
          color: colorScheme.tertiary,
          onPressed: () => _approveExercise(exercise),
          tooltip: 'Approva',
        ),
      );
    }

    return actions;
  }

  void _approveExercise(ExerciseModel exercise) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Approve Exercise',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to approve "${exercise.name}"?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(exercisesServiceProvider).approveExercise(exercise.id);
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Approve',
              style: TextStyle(color: theme.colorScheme.tertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseForm extends HookConsumerWidget {
  final ExerciseModel? exercise;
  final String userId;

  const _ExerciseForm({
    required this.exercise,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: exercise?.name);
    final selectedMuscleGroups =
        useState<List<String>>(exercise?.muscleGroups ?? []);
    final selectedExerciseType = useState<String?>(exercise?.type);

    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: BottomInputForm(
            title: exercise == null ? 'Add New Exercise' : 'Modifica Esercizio',
            subtitle: exercise?.name,
            leading: Container(
              padding: EdgeInsets.all(AppTheme.spacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(76),
                borderRadius: BorderRadius.circular(AppTheme.radii.md),
              ),
              child: Icon(
                exercise == null ? Icons.add : Icons.edit_outlined,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Annulla',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withAlpha(204),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withAlpha(51),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (formKey.currentState!.validate()) {
                        final exercisesService =
                            ref.read(exercisesServiceProvider);

                        if (exercise == null) {
                          // Aggiunta nuovo esercizio
                          exercisesService
                              .addExercise(
                            nameController.text,
                            selectedMuscleGroups.value,
                            selectedExerciseType.value!,
                            userId,
                          )
                              .then((_) {
                            Navigator.pop(context);
                          });
                        } else {
                          // Modifica esercizio esistente
                          exercisesService
                              .updateExercise(
                            exercise!.id,
                            nameController.text,
                            selectedMuscleGroups.value,
                            selectedExerciseType.value!,
                          )
                              .then((_) {
                            Navigator.pop(context);
                          });
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.lg,
                        vertical: AppTheme.spacing.md,
                      ),
                      child: Text(
                        'Salva',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            children: [
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome Esercizio
                    BottomInputForm.buildFormField(
                      label: 'Nome Esercizio',
                      theme: theme,
                      colorScheme: colorScheme,
                      child: TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Inserisci il nome dell\'esercizio',
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.fitness_center,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci un nome per l\'esercizio';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.lg),

                    // Muscle Groups
                    Consumer(
                      builder: (context, ref, child) {
                        final muscleGroupsAsyncValue =
                            ref.watch(muscleGroupsProvider);
                        return muscleGroupsAsyncValue.when(
                          data: (muscleGroups) =>
                              BottomInputForm.buildFormField(
                            label: 'Gruppi Muscolari',
                            theme: theme,
                            colorScheme: colorScheme,
                            helperText:
                                'Seleziona i gruppi muscolari coinvolti',
                            child: Wrap(
                              spacing: AppTheme.spacing.sm,
                              runSpacing: AppTheme.spacing.sm,
                              children: muscleGroups.map((group) {
                                final isSelected =
                                    selectedMuscleGroups.value.contains(group);
                                return FilterChip(
                                  label: Text(group),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      selectedMuscleGroups.value = [
                                        ...selectedMuscleGroups.value,
                                        group
                                      ];
                                    } else {
                                      selectedMuscleGroups.value =
                                          selectedMuscleGroups.value
                                              .where((g) => g != group)
                                              .toList();
                                    }
                                  },
                                  selectedColor: colorScheme.primaryContainer,
                                  checkmarkColor: colorScheme.primary,
                                );
                              }).toList(),
                            ),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text(
                              'Errore nel caricamento dei gruppi muscolari'),
                        );
                      },
                    ),
                    SizedBox(height: AppTheme.spacing.lg),

                    // Exercise Type
                    Consumer(
                      builder: (context, ref, child) {
                        final exerciseTypesAsyncValue =
                            ref.watch(exerciseTypesProvider);
                        return exerciseTypesAsyncValue.when(
                          data: (exerciseTypes) =>
                              BottomInputForm.buildFormField(
                            label: 'Tipo di Esercizio',
                            theme: theme,
                            colorScheme: colorScheme,
                            helperText: 'Seleziona il tipo di esercizio',
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withAlpha(128),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radii.lg),
                                border: Border.all(
                                  color: colorScheme.outline.withAlpha(26),
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: selectedExerciseType.value,
                                items: exerciseTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    selectedExerciseType.value = value,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.all(AppTheme.spacing.md),
                                  prefixIcon: Icon(
                                    Icons.category_outlined,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Seleziona un tipo di esercizio';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const Text(
                              'Errore nel caricamento dei tipi di esercizio'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
