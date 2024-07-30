import 'package:alphanessone/providers/providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'exercise_model.dart';
import 'exercises_services.dart';

final muscleGroupsProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance.collection('muscleGroups').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => doc['name'].toString()).toList());
});

final exerciseTypesProvider = StreamProvider((ref) {
  return FirebaseFirestore.instance.collection('ExerciseTypes').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => doc['name'].toString()).toList());
});

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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            TextField(
              onChanged: (value) => searchText.value = value,
              decoration: InputDecoration(
                hintText: 'Search exercise...',
                hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<ExerciseModel>>(
                stream: exercisesService.getExercises(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final exercises = snapshot.data!;
                    final filteredExercises = exercises
                        .where((exercise) =>
                            exercise.name
                                .toLowerCase()
                                .contains(searchText.value.toLowerCase()) &&
                            (selectedMuscleGroup.value == null ||
                                exercise.muscleGroup ==
                                    selectedMuscleGroup.value) &&
                            (selectedExerciseType.value == null ||
                                exercise.type == selectedExerciseType.value))
                        .toList();

                    if (filteredExercises.isEmpty) {
                      return Center(
                        child: Text(
                          'No exercises found.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ExerciseCard(
                            exercise: exercise,
                            isAdmin: currentUserRole == 'admin',
                            canEdit: currentUserRole == 'admin' ||
                                exercise.userId == currentUserId,
                            canDelete: currentUserRole == 'admin' ||
                                exercise.userId == currentUserId,
                            onEdit: () => _showEditExerciseBottomSheet(
                                context, ref, exercise),
                            onDelete: () => _showDeleteConfirmationDialog(
                                context, ref, exercise),
                            onApprove: () =>
                                exercisesService.approveExercise(exercise.id),
                            onReject: () =>
                                exercisesService.deleteExercise(exercise.id),
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
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
      BuildContext context, WidgetRef ref, ExerciseModel exercise) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _ExerciseForm(
          scrollController: controller,
          exercise: exercise,
          userId: ref.read(usersServiceProvider).getCurrentUserId(),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, WidgetRef ref, ExerciseModel exercise) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('Confirm Deletion',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          content: Text('Are you sure you want to delete this exercise?',
              style: TextStyle(color: theme.colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: theme.colorScheme.primary)),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(exercisesServiceProvider)
                    .deleteExercise(exercise.id);
                Navigator.of(context).pop();
              },
              child: Text('Delete',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        );
      },
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
  final ScrollController scrollController;
  final ExerciseModel? exercise;
  final String userId;

  const _ExerciseForm({
    required this.scrollController,
    this.exercise,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formKey = useState(GlobalKey<FormState>());
    final nameController = useTextEditingController(text: exercise?.name);
    final selectedMuscleGroup = useState<String?>(exercise?.muscleGroup);
    final selectedExerciseType = useState<String?>(exercise?.type);

    return SingleChildScrollView(
      controller: scrollController,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              exercise == null ? 'Add New Exercise' : 'Edit Exercise',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            Form(
              key: formKey.value,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Exercise Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      final muscleGroupsStream =
                          ref.watch(muscleGroupsProvider);
                      return muscleGroupsStream.when(
                        data: (muscleGroups) => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Muscle Group',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          value: selectedMuscleGroup.value,
                          items: muscleGroups.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            selectedMuscleGroup.value = newValue;
                          },
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
                      final exerciseTypesStream =
                          ref.watch(exerciseTypesProvider);
                      return exerciseTypesStream.when(
                        data: (exerciseTypes) => DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Exercise Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          value: selectedExerciseType.value,
                          items: exerciseTypes.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            selectedExerciseType.value = newValue;
                          },
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
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.value.currentState!.validate()) {
                        _submitExercise(ref, context, nameController.text, selectedMuscleGroup.value!, selectedExerciseType.value!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 32),
                    ),
                    child: Text(exercise == null ? 'Add' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitExercise(WidgetRef ref, BuildContext context, String name, String muscleGroup, String exerciseType) {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _ExerciseForm(
          scrollController: controller,
          exercise: null,
          userId: ref.read(usersServiceProvider).getCurrentUserId(),
        ),
      ),
    );
  }
}