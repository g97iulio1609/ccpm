import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:rxdart/rxdart.dart';
import 'exerciseManager/exercise_model.dart';
import 'exerciseManager/exercises_services.dart';
import 'users_services.dart';

// Providers
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final exercisesStreamProvider = StreamProvider<List<ExerciseModel>>((ref) {
  final service = ref.watch(exercisesServiceProvider);
  return service.getExercises();
});
final userServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, FirebaseFirestore.instance, FirebaseAuth.instance);
});
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(userServiceProvider);
  return service.getUsers();
});

class MaxRMDashboard extends HookConsumerWidget {
  const MaxRMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FirebaseAuth auth = ref.watch(authProvider);
    final User? user = auth.currentUser;
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final usersAsyncValue = ref.watch(usersStreamProvider);
    final usersService = ref.watch(userServiceProvider);
    final selectedExerciseController = useState<ExerciseModel?>(null);
    final selectedUserController = useState<UserModel?>(null);
    final exerciseNameController = useTextEditingController();
    final maxWeightController = useTextEditingController();
    final repetitionsController = useTextEditingController();
    final userNameController = useTextEditingController();
    final dateFormat = DateFormat('yyyy-MM-dd');

    Future<void> addRecord({
      required String exerciseId,
      required String exerciseName,
      required int maxWeight,
      required int repetitions,
    }) async {
      String userId = user?.uid ?? '';
      if (usersService.getCurrentUserRole() == 'admin' &&
          selectedUserController.value != null) {
        userId = selectedUserController.value!.id;
      }
      if (userId.isNotEmpty) {
        await usersService.addExerciseRecord(
          userId: userId,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          maxWeight: maxWeight,
          repetitions: repetitions,
          date: dateFormat.format(DateTime.now()),
        );
      }
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (usersService.getCurrentUserRole() == 'admin')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: usersAsyncValue.when(
                  data: (users) {
                    return TypeAheadField<UserModel>(
                      suggestionsCallback: (search) async {
                        return users.where((user) =>
                            user.name.toLowerCase().contains(search.toLowerCase())).toList();
                      },
                      itemBuilder: (context, suggestion) {
                        return ListTile(
                          title: Text(suggestion.name),
                        );
                      },
                      onSelected: (suggestion) {
                        selectedUserController.value = suggestion;
                        userNameController.text = suggestion.name;
                      },
                      emptyBuilder: (context) => const SizedBox.shrink(),
                      hideWithKeyboard: true,
                      hideOnSelect: true,
                      retainOnLoading: false,
                      offset: const Offset(0, 8),
                      decorationBuilder: (context, suggestionsBox) {
                        return Material(
                          elevation: 4,
                          color: Theme.of(context).colorScheme.surface,
                          child: suggestionsBox,
                        );
                      },
                      controller: userNameController,
                      focusNode: FocusNode(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text("Error loading users: $error"),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: exercisesAsyncValue.when(
                data: (exercises) {
                  return TypeAheadField<ExerciseModel>(
                    suggestionsCallback: (search) async {
                      return exercises.where((exercise) =>
                          exercise.name.toLowerCase().contains(search.toLowerCase())).toList();
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text(suggestion.name),
                      );
                    },
                    onSelected: (suggestion) {
                      selectedExerciseController.value = suggestion;
                      exerciseNameController.text = suggestion.name;
                    },
                    emptyBuilder: (context) => const SizedBox.shrink(),
                    hideWithKeyboard: true,
                    hideOnSelect: true,
                    retainOnLoading: false,
                    offset: const Offset(0, 8),
                    decorationBuilder: (context, suggestionsBox) {
                      return Material(
                        elevation: 4,
                        color: Theme.of(context).colorScheme.surface,
                        child: suggestionsBox,
                      );
                    },
                    controller: exerciseNameController,
                    focusNode: FocusNode(),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text("Error loading exercises: $error"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: maxWeightController,
                decoration: InputDecoration(
                  labelText: 'Max weight lifted',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextFormField(
                controller: repetitionsController,
                decoration: InputDecoration(
                  labelText: 'Number of repetitions',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    final int repetitions = int.tryParse(repetitionsController.text) ?? 0;
                    int maxWeight = int.tryParse(maxWeightController.text) ?? 0;
                    if (repetitions > 1) {
                      maxWeight = (maxWeight / (1.0278 - (0.0278 * repetitions))).round();
                    }
                    final ExerciseModel? selectedExercise = selectedExerciseController.value;
                    if (selectedExercise != null && maxWeight > 0) {
                      addRecord(
                        exerciseId: selectedExercise.id,
                        exerciseName: selectedExercise.name,
                        maxWeight: maxWeight,
                        repetitions: 1,
                      );
                      maxWeightController.clear();
                      repetitionsController.clear();
                      selectedExerciseController.value = null;
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Record'),
                ),
              ),
            ),
            if (usersService.getCurrentUserRole() == 'admin')
              _buildAllExercisesMaxRMs(ref, selectedUserController.value?.id ?? ''),
            if (usersService.getCurrentUserRole() != 'admin' && user != null)
              _buildAllExercisesMaxRMs(ref, user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildAllExercisesMaxRMs(WidgetRef ref, String userId) {
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final usersService = ref.watch(userServiceProvider);

    return exercisesAsyncValue.when(
      data: (exercises) {
        List<Stream<ExerciseRecord?>> exerciseRecordStreams = [];
        if (userId.isNotEmpty) {
          exerciseRecordStreams = exercises.map((exercise) {
            return usersService
                .getExerciseRecords(
                  userId: userId,
                  exerciseId: exercise.id,
                )
                .map((records) => records.isNotEmpty
                    ? records
                        .reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
                    : null);
          }).toList();
        }

        return StreamBuilder<List<ExerciseRecord?>>(
          stream: CombineLatestStream.list(exerciseRecordStreams),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var latestRecords = snapshot.data ?? [];
            latestRecords =
                latestRecords.where((record) => record != null).toList();

            return Expanded(
              child: ListView.builder(
                itemCount: latestRecords.length,
                itemBuilder: (context, index) {
                  var record = latestRecords[index];
                  ExerciseModel exercise = exercises.firstWhere(
                      (ex) => ex.id == record?.exerciseId,
                      orElse: () => ExerciseModel(
                          id: '',
                          name: 'Exercise not found',
                          type: '',
                          muscleGroup: ''));
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => showEditDialog(
                        context,
                        record!,
                        exercise,
                        userId,
                        usersService,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${record?.maxWeight} kg x ${record?.repetitions} reps',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  record!.date,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => showEditDialog(
                                    context,
                                    record,
                                    exercise,
                                    userId,
                                    usersService,
                                  ),
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => showDeleteDialog(
                                    context,
                                    record,
                                    exercise,
                                    userId,
                                    usersService,
                                  ),
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading max RMs: $error',
          style: TextStyle(
            color: Theme.of(context as BuildContext).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void showEditDialog(
    BuildContext context,
    ExerciseRecord record,
    ExerciseModel exercise,
    String userId,
    UsersService usersService,
  ) {
    TextEditingController maxWeightController =
        TextEditingController(text: record.maxWeight.toString());
    TextEditingController repetitionsController =
        TextEditingController(text: record.repetitions.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Record',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: maxWeightController,
                decoration: InputDecoration(
                  labelText: 'Max weight',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextFormField(
                controller: repetitionsController,
                decoration: InputDecoration(
                  labelText: 'Repetitions',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                int newMaxWeight = int.parse(maxWeightController.text);
                int newRepetitions = int.parse(repetitionsController.text);
                if (newRepetitions > 1) {
                  newMaxWeight =
                      (newMaxWeight / (1.0278 - (0.0278 * newRepetitions)))
                          .round();
                  newRepetitions = 1;
                }
                if (userId.isNotEmpty) {
                  usersService.updateExerciseRecord(
                    userId: userId,
                    exerciseId: exercise.id,
                    recordId: record.id,
                    maxWeight: newMaxWeight,
                    repetitions: newRepetitions,
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showDeleteDialog(
    BuildContext context,
    ExerciseRecord record,
    ExerciseModel exercise,
    String userId,
    UsersService usersService,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirmation',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (userId.isNotEmpty) {
                  usersService.deleteExerciseRecord(
                    userId: userId,
                    exerciseId: exercise.id,
                    recordId: record.id,
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
 