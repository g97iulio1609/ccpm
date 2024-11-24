import 'package:alphanessone/ExerciseRecords/exercise_autocomplete.dart';
import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/Coaching/coaching_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../exerciseManager/exercise_model.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import '../../user_autocomplete.dart';
import '../../providers/providers.dart';

class MaxRMDashboard extends HookConsumerWidget {
  const MaxRMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.watch(usersServiceProvider);
    final coachingService = ref.watch(coachingServiceProvider);
    final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
    final currentUserRole = ref.watch(currentUserRoleProvider);
    final selectedUserController = useTextEditingController();
    final selectedUserId = ref.watch(selectedUserIdProvider);

    final userFetchComplete = useState(false);

    useEffect(() {
      Future<void> fetchUsers() async {
        if (currentUserRole == 'admin' || currentUserRole == 'coach') {
          try {
            List<UserModel> users = await _fetchUsersByRole(currentUserRole, usersService, coachingService);
            ref.read(userListProvider.notifier).state = users;
            ref.read(filteredUserListProvider.notifier).state = users;
          } catch (e) {
            // Handle error if needed
          }
        } 
        userFetchComplete.value = true;
      }

      fetchUsers();
      return null;
    }, [currentUserRole]);

    void filterUsers(String pattern) {
      if (currentUserRole == 'admin' || currentUserRole == 'coach') {
        final allUsers = ref.read(userListProvider);
        final lowerPattern = pattern.toLowerCase();
        final filtered = pattern.isEmpty
            ? allUsers
            : allUsers.where((user) =>
                user.name.toLowerCase().contains(lowerPattern) ||
                user.email.toLowerCase().contains(lowerPattern)).toList();
        ref.read(filteredUserListProvider.notifier).state = filtered;
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              if ((currentUserRole == 'admin' || currentUserRole == 'coach') && 
                  userFetchComplete.value) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    ),
                  ),
                  child: UserTypeAheadField(
                    controller: selectedUserController,
                    focusNode: FocusNode(),
                    onSelected: (UserModel user) {
                      ref.read(selectedUserIdProvider.notifier).state = user.id;
                    },
                    onChanged: (String value) {
                      filterUsers(value);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Personal Records',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: _buildAllExercisesMaxRMs(
                  ref, 
                  usersService, 
                  exerciseRecordService, 
                  context, 
                  selectedUserId
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<UserModel>> _fetchUsersByRole(
      String role, UsersService usersService, CoachingService coachingService) async {
    List<UserModel> users = [];
    if (role == 'admin') {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } else if (role == 'coach') {
      final currentUserId = usersService.getCurrentUserId();
      final associations = await coachingService.getCoachAssociations(currentUserId).first;
      for (var association in associations) {
        if (association.status == 'accepted') {
          final athlete = await usersService.getUserById(association.athleteId);
          if (athlete != null) {
            users.add(athlete);
          }
        }
      }
    }
    return users;
  }

  Widget _buildAllExercisesMaxRMs(
    WidgetRef ref,
    UsersService usersService,
    ExerciseRecordService exerciseRecordService,
    BuildContext context,
    String? selectedUserId,
  ) {
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final userId = selectedUserId ?? usersService.getCurrentUserId();

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

  static void showAddMaxRMDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => _MaxRMForm(
        onSubmit: (exerciseId, exerciseName, maxWeight, repetitions, date, keepWeight, selectedUserId) async {
          final exerciseRecordService = ref.read(exerciseRecordServiceProvider);
          final usersService = ref.read(usersServiceProvider);
          final userId = selectedUserId ?? usersService.getCurrentUserId();

          double adjustedMaxWeight = maxWeight.toDouble();
          if (repetitions > 1) {
            adjustedMaxWeight = (maxWeight / (1.0278 - (0.0278 * repetitions))).roundToDouble();
          }

          await exerciseRecordService.addExerciseRecord(
            userId: userId,
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            maxWeight: adjustedMaxWeight,
            repetitions: 1,
            date: DateFormat('yyyy-MM-dd').format(date),
          );

          if (keepWeight) {
            await exerciseRecordService.updateIntensityForProgram(
              userId,
              exerciseId,
              adjustedMaxWeight,
            );
          } else {
            await exerciseRecordService.updateWeightsForProgram(
              userId,
              exerciseId,
              adjustedMaxWeight,
            );
          }

          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Max RM added successfully')),
            );
          }
        },
      ),
    );
  }
}

class ExerciseCard extends ConsumerWidget {
  final ExerciseRecord record;
  final ExerciseModel exercise;
  final ExerciseRecordService exerciseRecordService;
  final UsersService usersService;

  const ExerciseCard({
    super.key,
    required this.record,
    required this.exercise,
    required this.exerciseRecordService,
    required this.usersService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedUserId = ref.watch(selectedUserIdProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push(
              '/maxrmdashboard/exercise_stats/${exercise.id}',
              extra: {
                'exercise': exercise,
                'userId': selectedUserId ?? usersService.getCurrentUserId(),
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditDialog(context, ref),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _showDeleteDialog(context, ref),
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${record.maxWeight} kg',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      record.date,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditRecordDialog(
          record: record,
          exercise: exercise,
          exerciseRecordService: exerciseRecordService,
          usersService: usersService,
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Confirmation',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performDelete(context, ref);
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  void _performDelete(BuildContext context, WidgetRef ref) async {
    final selectedUserId = ref.read(selectedUserIdProvider);
    try {
      await exerciseRecordService.deleteExerciseRecord(
        userId: selectedUserId ?? usersService.getCurrentUserId(),
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

  const EditRecordDialog({
    super.key,
    required this.record,
    required this.exercise,
    required this.exerciseRecordService,
    required this.usersService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxWeightController = useTextEditingController(text: record.maxWeight.toString());
    final repetitionsController = useTextEditingController(text: record.repetitions.toString());
    final keepWeight = useState(false);
    final selectedDate = useState(DateTime.parse(record.date));

    return AlertDialog(
      title: Text(
        'Edit Record',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextFormField(maxWeightController, 'Max weight', context),
            _buildDialogTextFormField(repetitionsController, 'Repetitions', context),
            _buildDatePicker(context, selectedDate),
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
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _handleSave(context, ref, maxWeightController.text, repetitionsController.text, selectedDate.value, keepWeight.value);
          },
          child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _buildDialogTextFormField(TextEditingController controller, String labelText, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.number,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, ValueNotifier<DateTime> selectedDate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate.value,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (picked != null && picked != selectedDate.value) {
            selectedDate.value = picked;
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date',
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(selectedDate.value),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave(BuildContext context, WidgetRef ref, String maxWeightText, String repetitionsText, DateTime selectedDate, bool keepWeight) async {
    final selectedUserId = ref.read(selectedUserIdProvider);
    double newMaxWeight = double.parse(maxWeightText);
    int newRepetitions = int.parse(repetitionsText);

    if (newRepetitions > 1) {
      newMaxWeight = (newMaxWeight / (1.0278 - (0.0278 * newRepetitions))).roundToDouble();
      newRepetitions = 1;
    }

    try {
      await exerciseRecordService.updateExerciseRecord(
        userId: selectedUserId ?? usersService.getCurrentUserId(),
        exerciseId: exercise.id,
        recordId: record.id,
        maxWeight: newMaxWeight,
        repetitions: newRepetitions,
      );

      if (keepWeight) {
        await exerciseRecordService.updateIntensityForProgram(
          selectedUserId ?? usersService.getCurrentUserId(),
          exercise.id,
          newMaxWeight,
        );
      } else {
        await exerciseRecordService.updateWeightsForProgram(
          selectedUserId ?? usersService.getCurrentUserId(),
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

class _MaxRMForm extends HookConsumerWidget {
  final Function(String, String, num, int, DateTime, bool, String?) onSubmit;

  const _MaxRMForm({
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(exercisesStreamProvider);
    final selectedExerciseController = useState<ExerciseModel?>(null);
    final exerciseNameController = useTextEditingController();
    final maxWeightController = useTextEditingController();
    final repetitionsController = useTextEditingController();
    final keepWeight = useState(false);
    final selectedDate = useState(DateTime.now());
    final formKey = GlobalKey<FormState>();

    final maxWeightFocusNode = useFocusNode();
    final repetitionsFocusNode = useFocusNode();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Max RM',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Integra ExerciseAutocompleteBox
                  ExerciseAutocompleteBox(
                    controller: exerciseNameController,
                    exerciseRecordService: ref.watch(exerciseRecordServiceProvider),
                    athleteId: ref.watch(selectedUserIdProvider) ?? '',
                    onSelected: (selectedExercise) {
                      selectedExerciseController.value = selectedExercise;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: maxWeightController,
                    labelText: 'Max weight lifted',
                    keyboardType: TextInputType.number,
                    focusNode: maxWeightFocusNode,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: repetitionsController,
                    labelText: 'Number of repetitions',
                    keyboardType: TextInputType.number,
                    focusNode: repetitionsFocusNode,
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(context, selectedDate),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final exerciseId = selectedExerciseController.value?.id ?? '';
                          final exerciseName = exerciseNameController.text;
                          final maxWeight = num.tryParse(maxWeightController.text) ?? 0;
                          final repetitions = int.tryParse(repetitionsController.text) ?? 0;
                          final selectedUserId = ref.read(selectedUserIdProvider);
                          onSubmit(exerciseId, exerciseName, maxWeight, repetitions, selectedDate.value, keepWeight.value, selectedUserId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700), // Yellow color
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Max RM', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    required FocusNode focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(BuildContext context, ValueNotifier<DateTime> selectedDate) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate.value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null && picked != selectedDate.value) {
          selectedDate.value = picked;
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(selectedDate.value)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}