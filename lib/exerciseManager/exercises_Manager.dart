import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../UI/components/card.dart';
import 'exercise_model.dart';
import '../providers/providers.dart';

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
    final exercisesService = ref.watch(exercisesServiceProvider);
    final searchText = useState('');
    final selectedMuscleGroup = useState<String?>(null);
    final selectedExerciseType = useState<String?>(null);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Search Field
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => searchText.value = value,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search exercise...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Exercises List
            Expanded(
              child: StreamBuilder<List<ExerciseModel>>(
                stream: exercisesService.getExercises(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final exercises = snapshot.data!;
                    final filteredExercises = exercises.where((exercise) =>
                      exercise.name.toLowerCase().contains(searchText.value.toLowerCase()) &&
                      (selectedMuscleGroup.value == null || exercise.muscleGroup == selectedMuscleGroup.value) &&
                      (selectedExerciseType.value == null || exercise.type == selectedExerciseType.value)
                    ).toList();

                    if (filteredExercises.isEmpty) {
                      return Center(
                        child: Text(
                          'No exercises found.',
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];
                        return ActionCard(
                          onTap: () => _showEditExerciseBottomSheet(context, ref, exercise),
                          title: Text(
                            exercise.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          subtitle: Text(
                            '${exercise.muscleGroup} - ${exercise.type}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: -0.3,
                            ),
                          ),
                          actions: [
                            if (currentUserRole == 'admin' || exercise.userId == currentUserId) ...[
                              IconButtonWithBackground(
                                icon: Icons.edit_outlined,
                                color: theme.colorScheme.primary,
                                onPressed: () => _showEditExerciseBottomSheet(context, ref, exercise),
                              ),
                              const SizedBox(width: 8),
                              IconButtonWithBackground(
                                icon: Icons.delete_outline,
                                color: theme.colorScheme.error,
                                onPressed: () => _showDeleteConfirmationDialog(
                                  context,
                                  exercise,
                                  ref,
                                  theme,
                                ),
                              ),
                            ],
                          ],
                          bottomContent: exercise.status == 'pending'
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.colorScheme.primary.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.pending_outlined,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Pending Approval',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              : null,
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
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

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.isAdmin,
    required this.canEdit,
    required this.canDelete,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onReject,
  });

  final ExerciseModel exercise;
  final bool isAdmin;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPending = exercise.status == 'pending';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surface,
      child: InkWell(
        onTap: canEdit ? onEdit : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.muscleGroup} - ${exercise.type}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isPending)
                      const Text(
                        'Pending Approval',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              if (isAdmin && isPending)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: onApprove,
                  color: Colors.green,
                ),
              if (isAdmin && isPending)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onReject,
                  color: Colors.red,
                ),
              if (canEdit && !isPending)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  color: colorScheme.onSurface,
                ),
              if (canDelete && !isPending)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                  color: colorScheme.onSurface,
                ),
            ],
          ),
        ),
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
    final selectedMuscleGroup = useState<String?>(exercise?.muscleGroup);
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
                      data: (muscleGroups) => DropdownButtonFormField<String>(
                        value: selectedMuscleGroup.value,
                        items: muscleGroups.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) => selectedMuscleGroup.value = value,
                        decoration: const InputDecoration(
                          labelText: 'Muscle Group',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a muscle group';
                          }
                          return null;
                        },
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
                          selectedMuscleGroup.value!,
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
      String muscleGroup, String exerciseType) {
    final exercisesService = ref.read(exercisesServiceProvider);

    if (exercise == null) {
      exercisesService.addExercise(
        name,
        muscleGroup,
        exerciseType,
        userId,
      );
    } else {
      exercisesService.updateExercise(
        exercise!.id,
        name,
        muscleGroup,
        exerciseType,
      );
    }

    Navigator.of(context).pop();
  }
}