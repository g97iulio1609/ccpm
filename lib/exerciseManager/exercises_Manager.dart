import 'package:alphanessone/services/users_services.dart';
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
    final muscleGroupsStream = ref.watch(muscleGroupsProvider);
    final exerciseTypesStream = ref.watch(exerciseTypesProvider);
    final searchText = useState('');
    final selectedMuscleGroup = useState<String?>(null);
    final selectedExerciseType = useState<String?>(null);
    final TextEditingController nameController = useTextEditingController();
    final editingExerciseId = useState<String?>(null);

    ExerciseModel? exerciseToEdit;
    ExerciseModel? exerciseToDelete;

    void addOrEditExercise() {
      final data = {
        'name': nameController.text.trim(),
        'muscleGroup': selectedMuscleGroup.value,
        'type': selectedExerciseType.value
      };

      final currentUserRole = ref.read(userRoleProvider);
      final currentUserId = ref.read(userNameProvider.notifier).state;

      if (editingExerciseId.value != null) {
        if (currentUserRole == 'admin' ||
            (exerciseToEdit?.userId == currentUserId)) {
          exercisesService.updateExercise(
            editingExerciseId.value!,
            data['name']!,
            data['muscleGroup']!,
            data['type']!,
          );
        }
      } else if (nameController.text.trim().isNotEmpty &&
          selectedMuscleGroup.value != null &&
          selectedExerciseType.value != null) {
        exercisesService.addExercise(
          data['name']!,
          data['muscleGroup']!,
          data['type']!,
          currentUserId,
        );
      }

      nameController.clear();
      selectedMuscleGroup.value = null;
      selectedExerciseType.value = null;
      editingExerciseId.value = null;
      exerciseToEdit = null;
      exerciseToDelete = null;
    }

    Future<void> editExercise(ExerciseModel exercise) async {
      exerciseToEdit = exercise;
      nameController.text = exercise.name;
      selectedMuscleGroup.value = exercise.muscleGroup;
      selectedExerciseType.value = exercise.type;
      editingExerciseId.value = exercise.id;
    }

    Future<void> deleteExercise(String id) async {
      final currentUserRole = ref.read(userRoleProvider);
      final currentUserId = ref.read(userNameProvider.notifier).state;

      if (currentUserRole == 'admin' ||
          (exerciseToDelete?.userId == currentUserId)) {
        await exercisesService.deleteExercise(id);
      }
    }

    Future<void> approveExercise(String id) async {
      final currentUserRole = ref.read(userRoleProvider);

      if (currentUserRole == 'admin') {
        await exercisesService.approveExercise(id);
      }
    }

    Future<void> rejectExercise(String id) async {
      final currentUserRole = ref.read(userRoleProvider);

      if (currentUserRole == 'admin') {
        await exercisesService.deleteExercise(id);
      }
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: editingExerciseId.value != null
                    ? 'Edit Exercise'
                    : 'New Exercise',
                hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addOrEditExercise,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
            const SizedBox(height: 16),
            muscleGroupsStream.when(
              data: (muscleGroups) => DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Muscle Group',
                  hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                value: selectedMuscleGroup.value,
                items: muscleGroups
                    .toSet()
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  selectedMuscleGroup.value = newValue;
                },
                dropdownColor: Theme.of(context).colorScheme.surface,
              ),
              loading: () => const SizedBox(),
              error: (error, stack) => const SizedBox(),
            ),
            const SizedBox(height: 16),
            exerciseTypesStream.when(
              data: (exerciseTypes) => DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Exercise Type',
                  hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                value: selectedExerciseType.value,
                items: exerciseTypes
                    .toSet()
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  selectedExerciseType.value = newValue;
                },
                dropdownColor: Theme.of(context).colorScheme.surface,
              ),
              loading: () => const SizedBox(),
              error: (error, stack) => const SizedBox(),
            ),
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
                    final pendingExercises = exercises
                        .where(
                          (exercise) =>
                              exercise.status == 'pending' &&
                              (exercise.userId ==
                                      ref.read(userNameProvider.notifier).state ||
                                  ref.read(userRoleProvider) == 'admin'),
                        )
                        .toList();
                    final approvedExercises = exercises
                        .where(
                          (exercise) =>
                              exercise.status == 'approved' &&
                              exercise.name
                                  .toLowerCase()
                                  .contains(searchText.value.toLowerCase()),
                        )
                        .toList();

                    final filteredExercises = [
                      ...pendingExercises,
                      ...approvedExercises,
                    ];

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
                            isAdmin: ref.read(userRoleProvider) == 'admin',
                            canEdit: ref.read(userRoleProvider) == 'admin' ||
                                exercise.userId ==
                                    ref.read(userNameProvider.notifier).state,
                            canDelete: ref.read(userRoleProvider) == 'admin' ||
                                exercise.userId ==
                                    ref.read(userNameProvider.notifier).state,
                            onEdit: () => editExercise(exercise),
                            onDelete: () {
                              exerciseToDelete = exercise;
                              deleteExercise(exercise.id);
                            },
                            onApprove: () => approveExercise(exercise.id),
                            onReject: () => rejectExercise(exercise.id),
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
                  color: colorScheme.onBackground,
                ),
              if (canDelete && !isPending)
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                  color: colorScheme.onBackground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}