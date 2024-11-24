import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../UI/components/card.dart';
import 'exercise_model.dart';
import '../providers/providers.dart';
import 'widgets/exercise_widgets.dart';
import 'controllers/exercise_list_controller.dart';
import '../ExerciseRecords/exercise_autocomplete.dart';
import '../ExerciseRecords/exercise_record_services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

// Providers per i muscleGroups e exerciseTypes
final muscleGroupsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance.collection('muscleGroups').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc['name'].toString()).toList());
});

final exerciseTypesProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance.collection('ExerciseTypes').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc['name'].toString()).toList());
});

class ExercisesManager extends ConsumerWidget {
  const ExercisesManager({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ExercisesList();
  }

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
}

class ExercisesList extends HookConsumerWidget {
  const ExercisesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final selectedMuscleGroup = useState<String?>(null);
    final selectedExerciseType = useState<String?>(null);
    final exercisesState = ref.watch(exerciseListControllerProvider);
    final controller = ref.watch(exerciseListControllerProvider.notifier);
    final currentUserRole = ref.watch(userRoleProvider);
    final currentUserId = ref.read(usersServiceProvider).getCurrentUserId();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.92),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            TypeAheadField<ExerciseModel>(
              suggestionsCallback: (pattern) async {
                if (pattern.length < 2) return [];
                
                final exercises = await ref.read(exercisesServiceProvider).getExercises().first;
                return exercises.where((exercise) => 
                  exercise.name.toLowerCase().contains(pattern.toLowerCase())
                ).toList();
              },
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
                                ref.read(exerciseListControllerProvider.notifier).resetFilters();
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
                if (exercise != null) {
                  searchController.text = exercise.name;
                  Future.microtask(() {
                    controller.updateFilters(searchText: exercise.name);
                  });
                }
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
            const SizedBox(height: 24),
            Expanded(
              child: exercisesState.when(
                data: (exercises) {
                  return ExercisesGrid(
                    exercises: exercises,
                    currentUserRole: currentUserRole,
                    currentUserId: currentUserId,
                    onEdit: (exercise) => _showEditExerciseBottomSheet(context, ref, exercise),
                    onDelete: (exercise) => _showDeleteConfirmationDialog(
                      context, exercise, ref, theme,
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

  void _showEditExerciseBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ExerciseModel exercise,
  ) {
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

  void _showExerciseOptions(
    BuildContext context,
    ExerciseModel exercise,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final exercisesService = ref.read(exercisesServiceProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionTile(
              context,
              'Edit',
              Icons.edit_outlined,
              () {
                Navigator.pop(context);
                _showEditExerciseBottomSheet(context, ref, exercise);
              },
            ),
            _buildOptionTile(
              context,
              'Delete',
              Icons.delete_outline,
              () {
                Navigator.pop(context);
                exercisesService.deleteExercise(exercise.id);
              },
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmationDialog(
    BuildContext context,
    ExerciseModel exercise,
    WidgetRef ref,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Exercise',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this exercise?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              final exercisesService = ref.read(exercisesServiceProvider);
              exercisesService.deleteExercise(exercise.id);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class ExercisesGrid extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverLayoutBuilder(
          builder: (context, constraints) {
            final isMobile = MediaQuery.of(context).size.width <= 600;
            
            return isMobile 
                ? _buildList(context, ref)
                : _buildGrid(context, ref);
          },
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 16.0,
          ),
          child: _buildExerciseCard(context, exercises[index], ref),
        ),
        childCount: exercises.length,
      ),
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref) {
    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getGridCrossAxisCount(context),
          crossAxisSpacing: 24.0,
          mainAxisSpacing: 24.0,
          childAspectRatio: 1.2,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildExerciseCard(context, exercises[index], ref),
          childCount: exercises.length,
        ),
      ),
    );
  }

  int _getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildExerciseCard(BuildContext context, ExerciseModel exercise, WidgetRef ref) {
    final canModify = currentUserRole == 'admin' || exercise.userId == currentUserId;
    final isAdmin = currentUserRole == 'admin';
    
    final List<Widget> actionButtons = [];

    if (canModify) {
      actionButtons.addAll([
        IconButtonWithBackground(
          icon: Icons.edit_outlined,
          color: Theme.of(context).colorScheme.primary,
          onPressed: () => onEdit(exercise),
        ),
        const SizedBox(width: 8),
        IconButtonWithBackground(
          icon: Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
          onPressed: () => onDelete(exercise),
        ),
      ]);
    }

    if (isAdmin && exercise.status == 'pending') {
      if (actionButtons.isNotEmpty) {
        actionButtons.insert(0, const SizedBox(width: 8));
      }
      actionButtons.insert(0, 
        IconButtonWithBackground(
          icon: Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.tertiary,
          onPressed: () => _showApproveConfirmationDialog(context, exercise, ref),
        ),
      );
    }
    
    return ExerciseCardContent(
      exercise: exercise,
      onTap: () => onEdit(exercise),
      actions: actionButtons,
    );
  }

  void _showApproveConfirmationDialog(
    BuildContext context,
    ExerciseModel exercise,
    WidgetRef ref,
  ) {
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
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: exercise?.name);
    final selectedMuscleGroups = useState<List<String>>(exercise?.muscleGroups ?? []);
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
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise == null ? 'Add New Exercise' : 'Edit Exercise',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an exercise name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final muscleGroupsAsyncValue = ref.watch(muscleGroupsProvider);
                    return muscleGroupsAsyncValue.when(
                      data: (muscleGroups) => Wrap(
                        spacing: 8.0,
                        children: muscleGroups.map((String group) {
                          final isSelected = selectedMuscleGroups.value.contains(group);
                          return FilterChip(
                            label: Text(group),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              if (selected) {
                                selectedMuscleGroups.value = [...selectedMuscleGroups.value, group];
                              } else {
                                selectedMuscleGroups.value = selectedMuscleGroups.value.where((g) => g != group).toList();
                              }
                            },
                          );
                        }).toList(),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Failed to load muscle groups'),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, child) {
                    final exerciseTypesAsyncValue = ref.watch(exerciseTypesProvider);
                    return exerciseTypesAsyncValue.when(
                      data: (exerciseTypes) => DropdownButtonFormField<String>(
                        value: selectedExerciseType.value,
                        items: exerciseTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) => selectedExerciseType.value = value,
                        decoration: const InputDecoration(
                          labelText: 'Exercise Type',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an exercise type';
                          }
                          return null;
                        },
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const Text('Failed to load exercise types'),
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        _submitExercise(
                          ref,
                          context,
                          nameController.text,
                          selectedMuscleGroups.value,
                          selectedExerciseType.value!,
                        );
                      }
                    },
                    child: Text(exercise == null ? 'Add' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitExercise(WidgetRef ref, BuildContext context, String name,
      List<String> muscleGroups, String exerciseType) {
    final exercisesService = ref.read(exercisesServiceProvider);

    if (exercise == null) {
      exercisesService.addExercise(
        name,
        muscleGroups,
        exerciseType,
        userId,
      );
    } else {
      exercisesService.updateExercise(
        exercise!.id,
        name,
        muscleGroups,
        exerciseType,
      );
    }

    Navigator.of(context).pop();
  }
}