import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/services/coaching_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'exerciseManager/exercise_model.dart';
import 'exerciseManager/exercises_services.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/services/exercise_record_services.dart';
import '../user_type_ahead_field.dart';

// Providers
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final exercisesStreamProvider = StreamProvider<List<ExerciseModel>>((ref) {
  final service = ref.watch(exercisesServiceProvider);
  return service.getExercises();
});
final userServiceProvider = Provider<UsersService>((ref) {
  return UsersService(ref, FirebaseFirestore.instance, FirebaseAuth.instance);
});
final exerciseRecordServiceProvider = Provider<ExerciseRecordService>((ref) {
  return ExerciseRecordService(FirebaseFirestore.instance);
});
final coachingServiceProvider = Provider<CoachingService>((ref) {
  return CoachingService(FirebaseFirestore.instance);
});
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(userServiceProvider);
  return service.getUsers();
});
final keepWeightProvider = StateProvider<bool>((ref) => false);
final currentUserRoleProvider = StateProvider<String>((ref) {
  final usersService = ref.watch(userServiceProvider);
  usersService.fetchUserRole();
  return usersService.getCurrentUserRole();
});
final userListProvider = StateProvider<List<UserModel>>((ref) => []);
final filteredUserListProvider = StateProvider<List<UserModel>>((ref) => []);

class MaxRMDashboard extends HookConsumerWidget {
  const MaxRMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final usersService = ref.watch(userServiceProvider);
    final coachingService = ref.watch(coachingServiceProvider);
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
    final selectedExerciseController = useState<ExerciseModel?>(null);
    final exerciseNameController = useTextEditingController();
    final maxWeightController = useTextEditingController();
    final repetitionsController = useTextEditingController();
    final keepWeight = ref.watch(keepWeightProvider);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final currentUserRole = ref.watch(currentUserRoleProvider);
    final selectedUserController = useTextEditingController();
    final selectedUser = useState<UserModel?>(null);

    useEffect(() {
      Future<void> fetchUsers() async {
        List<UserModel> users = [];
        if (currentUserRole == 'admin') {
          final snapshot = await FirebaseFirestore.instance.collection('users').get();
          users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
        } else if (currentUserRole == 'coach') {
          final associations = await coachingService.getUserAssociations(usersService.getCurrentUserId()).first;
          for (var association in associations) {
            if (association.status == 'accepted') {
              final athlete = await usersService.getUserById(association.athleteId);
              if (athlete != null) {
                users.add(athlete);
              }
            }
          }
        }
        ref.read(userListProvider.notifier).state = users;
        ref.read(filteredUserListProvider.notifier).state = users;
      }

      fetchUsers();
      return null;
    }, []);

    void filterUsers(String pattern) {
      final allUsers = ref.read(userListProvider);
      if (pattern.isEmpty) {
        ref.read(filteredUserListProvider.notifier).state = allUsers;
      } else {
        final filtered = allUsers.where((user) => user.name.toLowerCase().contains(pattern.toLowerCase())).toList();
        ref.read(filteredUserListProvider.notifier).state = filtered;
      }
    }

    Future<void> addRecord({
      required String exerciseId,
      required String exerciseName,
      required num maxWeight,
      required int repetitions,
    }) async {
      String userId = selectedUser.value?.id ?? usersService.getCurrentUserId();
      await exerciseRecordService.addExerciseRecord(
        userId: userId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        maxWeight: maxWeight,
        repetitions: repetitions,
        date: dateFormat.format(DateTime.now()),
      );
      debugPrint('Record added: $exerciseName, Max Weight: $maxWeight, Repetitions: $repetitions');
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentUserRole == 'admin' || currentUserRole == 'coach') ...[
              UserTypeAheadField(
                controller: selectedUserController,
                focusNode: FocusNode(),
                onSelected: (UserModel user) {
                  selectedUser.value = user;
                },
                onChanged: filterUsers,
              ),
              const SizedBox(height: 8),
            ],
            _buildExerciseTypeAheadField(exercisesAsyncValue, selectedExerciseController, exerciseNameController, context),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: maxWeightController,
              labelText: 'Max weight lifted',
              context: context,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: repetitionsController,
              labelText: 'Number of repetitions',
              context: context,
              keyboardType: TextInputType.number,
            ),
            _buildKeepWeightSwitch(context, keepWeight, ref),
            _buildAddRecordButton(
              context,
              selectedExerciseController,
              maxWeightController,
              repetitionsController,
              addRecord,
              exerciseRecordService,
              usersService,
              keepWeight,
            ),
            const SizedBox(height: 20),
            _buildAllExercisesMaxRMs(ref, usersService, exerciseRecordService, context, selectedUser.value),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTypeAheadField(
    AsyncValue<List<ExerciseModel>> exercisesAsyncValue,
    ValueNotifier<ExerciseModel?> selectedExerciseController,
    TextEditingController exerciseNameController,
    BuildContext context,
  ) {
    return exercisesAsyncValue.when(
      data: (exercises) {
        return TypeAheadField<ExerciseModel>(
          suggestionsCallback: (search) async {
            return exercises.where((exercise) => exercise.name.toLowerCase().contains(search.toLowerCase())).toList();
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
          decorationBuilder: (context, child) {
            return Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
          offset: const Offset(0, 8),
          constraints: const BoxConstraints(maxHeight: 200),
          controller: exerciseNameController,
          focusNode: FocusNode(),
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Exercise Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            );
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text("Error loading exercises: $error"),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required BuildContext context,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildKeepWeightSwitch(BuildContext context, bool keepWeight, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Keep current weight',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        Switch(
          value: keepWeight,
          onChanged: (value) {
            ref.read(keepWeightProvider.notifier).state = value;
          },
        ),
      ],
    );
  }

  Widget _buildAddRecordButton(
    BuildContext context,
    ValueNotifier<ExerciseModel?> selectedExerciseController,
    TextEditingController maxWeightController,
    TextEditingController repetitionsController,
    Future<void> Function({
      required String exerciseId,
      required String exerciseName,
      required num maxWeight,
      required int repetitions,
    }) addRecord,
    ExerciseRecordService exerciseRecordService,
    UsersService usersService,
    bool keepWeight,
  ) {
    return Center(
      child: ElevatedButton(
        onPressed: () async {
          final int repetitions = int.tryParse(repetitionsController.text) ?? 0;
          double maxWeight = double.tryParse(maxWeightController.text) ?? 0;
          if (repetitions > 1) {
            maxWeight = (maxWeight / (1.0278 - (0.0278 * repetitions))).roundToDouble();
          }
          final ExerciseModel? selectedExercise = selectedExerciseController.value;
          if (selectedExercise != null && maxWeight > 0) {
            await addRecord(
              exerciseId: selectedExercise.id,
              exerciseName: selectedExercise.name,
              maxWeight: maxWeight,
              repetitions: 1,
            );

            if (keepWeight) {
              debugPrint('Updating intensity while keeping weight.');
              await exerciseRecordService.updateIntensityForProgram(
                usersService.getCurrentUserId(),
                selectedExercise.id,
                maxWeight,
              );
            } else {
              debugPrint('Updating weights based on new max weight.');
              await exerciseRecordService.updateWeightsForProgram(
                usersService.getCurrentUserId(),
                selectedExercise.id,
                maxWeight,
              );
            }

            maxWeightController.clear();
            repetitionsController.clear();
            selectedExerciseController.value = null;
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Add Record'),
      ),
    );
  }

  Widget _buildAllExercisesMaxRMs(
    WidgetRef ref,
    UsersService usersService,
    ExerciseRecordService exerciseRecordService,
    BuildContext context,
    UserModel? selectedUser,
  ) {
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final userId = selectedUser?.id ?? usersService.getCurrentUserId();

    return exercisesAsyncValue.when(
      data: (exercises) {
        List<Stream<ExerciseRecord?>> exerciseRecordStreams = exercises.map((exercise) {
          return exerciseRecordService
              .getExerciseRecords(userId: userId, exerciseId: exercise.id)
              .map((records) => records.isNotEmpty ? records.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b) : null);
        }).toList();

        return StreamBuilder<List<ExerciseRecord?>>(
          stream: CombineLatestStream.list(exerciseRecordStreams),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            var latestRecords = snapshot.data ?? [];
            latestRecords = latestRecords.where((record) => record != null).toList();

            return Expanded(
              child: ListView.builder(
                itemCount: latestRecords.length,
                itemBuilder: (context, index) {
                  var record = latestRecords[index];
                  ExerciseModel exercise = exercises.firstWhere(
                    (ex) => ex.id == record?.exerciseId,
                    orElse: () => ExerciseModel(id: '', name: 'Exercise not found', type: '', muscleGroup: ''),
                  );
                  return ExerciseCard(
                    record: record!,
                    exercise: exercise,
                    exerciseRecordService: exerciseRecordService,
                    usersService: usersService,
                    selectedUser: selectedUser, // Aggiunto passaggio di selectedUser
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
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final ExerciseRecord record;
  final ExerciseModel exercise;
  final ExerciseRecordService exerciseRecordService;
  final UsersService usersService;
  final UserModel? selectedUser; // Aggiunto questo campo

  const ExerciseCard({
    super.key,
    required this.record,
    required this.exercise,
    required this.exerciseRecordService,
    required this.usersService,
    this.selectedUser, // Aggiunto questo campo
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push(
            '/maxrmdashboard/exercise_stats/${exercise.id}',
            extra: {
              'exercise': exercise,
              'userId': selectedUser?.id ?? usersService.getCurrentUserId(), // Passaggio dell'ID utente qui
            },
          );
        },
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${record.maxWeight} kg x ${record.repetitions} reps',
                      style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.date,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(context),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditRecordDialog(
          record: record,
          exercise: exercise,
          exerciseRecordService: exerciseRecordService,
          usersService: usersService,
          selectedUser: selectedUser, // Aggiunto passaggio di selectedUser
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Confirmation',
            style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          content: Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Theme.of(dialogContext).colorScheme.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performDelete(context);
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(dialogContext).colorScheme.onPrimary)),
            ),
          ],
        );
      },
    );
  }

  void _performDelete(BuildContext context) async {
    try {
      await exerciseRecordService.deleteExerciseRecord(
        userId: usersService.getCurrentUserId(),
        exerciseId: exercise.id,
        recordId: record.id,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete record: $e')),
        );
      }
    }
  }
}

class EditRecordDialog extends HookConsumerWidget {
  final ExerciseRecord record;
  final ExerciseModel exercise;
  final ExerciseRecordService exerciseRecordService;
  final UsersService usersService;
  final UserModel? selectedUser; // Aggiunto questo campo

  const EditRecordDialog({
    super.key,
    required this.record,
    required this.exercise,
    required this.exerciseRecordService,
    required this.usersService,
    this.selectedUser, // Aggiunto questo campo
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxWeightController = useTextEditingController(text: record.maxWeight.toString());
    final repetitionsController = useTextEditingController(text: record.repetitions.toString());
    final keepWeight = useState(false);

    return AlertDialog(
      title: Text(
        'Edit Record',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogTextFormField(maxWeightController, 'Max weight', context),
          _buildDialogTextFormField(repetitionsController, 'Repetitions', context),
          Row(
            children: [
              Text(
                'Keep current weight',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              Switch(
                value: keepWeight.value,
                onChanged: (value) {
                  keepWeight.value = value;
                },
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _handleSave(context, maxWeightController.text, repetitionsController.text, keepWeight.value);
          },
          child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _buildDialogTextFormField(TextEditingController controller, String labelText, BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      keyboardType: TextInputType.number,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    );
  }

  void _handleSave(BuildContext context, String maxWeightText, String repetitionsText, bool keepWeight) async {
    double newMaxWeight = double.parse(maxWeightText);
    int newRepetitions = int.parse(repetitionsText);

    if (newRepetitions > 1) {
      newMaxWeight = (newMaxWeight / (1.0278 - (0.0278 * newRepetitions))).roundToDouble();
      newRepetitions = 1;
    }

    try {
      await exerciseRecordService.updateExerciseRecord(
        userId: usersService.getCurrentUserId(),
        exerciseId: exercise.id,
        recordId: record.id,
        maxWeight: newMaxWeight,
        repetitions: newRepetitions,
      );

      if (keepWeight) {
        debugPrint('Updating intensity while keeping weight.');
        await exerciseRecordService.updateIntensityForProgram(
          usersService.getCurrentUserId(),
          exercise.id,
          newMaxWeight,
        );
      } else {
        debugPrint('Updating weights based on new max weight.');
        await exerciseRecordService.updateWeightsForProgram(
          usersService.getCurrentUserId(),
          exercise.id,
          newMaxWeight,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update record: $e')),
        );
      }
    }
  }
}
