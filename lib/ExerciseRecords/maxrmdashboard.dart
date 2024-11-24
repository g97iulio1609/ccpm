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
import '../UI/components/card.dart';

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
    final focusNode = useFocusNode();
    final userFetchComplete = useState(false);

    // Effetto per caricare gli utenti
    useEffect(() {
      Future<void> fetchUsers() async {
        if (currentUserRole == 'admin' || currentUserRole == 'coach') {
          try {
            List<UserModel> users = await _fetchUsersByRole(currentUserRole, usersService, coachingService);
            ref.read(userListProvider.notifier).state = users;
            ref.read(filteredUserListProvider.notifier).state = users;
          } catch (e) {
            debugPrint('Error fetching users: $e');
          }
        }
        userFetchComplete.value = true;
      }

      fetchUsers();
      return null;
    }, [currentUserRole]);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.92),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Campo di ricerca utente
              if (currentUserRole == 'admin' || currentUserRole == 'coach') 
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: UserTypeAheadField(
                        controller: selectedUserController,
                        focusNode: focusNode,
                        onSelected: (UserModel user) {
                          ref.read(selectedUserIdProvider.notifier).state = user.id;
                        },
                        onChanged: (String value) {
                          final allUsers = ref.read(userListProvider);
                          final filteredUsers = allUsers.where((user) =>
                            user.name.toLowerCase().contains(value.toLowerCase()) ||
                            user.email.toLowerCase().contains(value.toLowerCase())
                          ).toList();
                          ref.read(filteredUserListProvider.notifier).state = filteredUsers;
                        },
                      ),
                    ),
                  ),
                ),
              // Lista dei record
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: _buildAllExercisesMaxRMs(
                        ref,
                        usersService,
                        exerciseRecordService,
                        context,
                        selectedUserId,
                      ),
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

  SliverToBoxAdapter _buildAllExercisesMaxRMs(
    WidgetRef ref,
    UsersService usersService,
    ExerciseRecordService exerciseRecordService,
    BuildContext context,
    String? selectedUserId,
  ) {
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final userId = selectedUserId ?? usersService.getCurrentUserId();

    return SliverToBoxAdapter(
      child: exercisesAsyncValue.when(
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
              
              final latestRecords = (snapshot.data ?? [])
                  .where((record) => record != null)
                  .toList();

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth <= 600;
                  final crossAxisCount = switch (constraints.maxWidth) {
                    > 1200 => 4, // Desktop large
                    > 900 => 3,  // Desktop
                    > 600 => 2,  // Tablet
                    _ => 1,      // Mobile
                  };

                  if (isMobile) {
                    // Per mobile, usiamo ListView invece di GridView per altezza adattiva
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: latestRecords.length,
                      itemBuilder: (context, index) {
                        final record = latestRecords[index];
                        ExerciseModel exercise = exercises.firstWhere(
                          (ex) => ex.id == record?.exerciseId,
                          orElse: () => ExerciseModel(id: '', name: 'Exercise not found', type: '', muscleGroup: ''),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          child: ActionCard(
                            onTap: () {
                              context.push(
                                '/maxrmdashboard/exercise_stats/${exercise.id}',
                                extra: {
                                  'exercise': exercise,
                                  'userId': selectedUserId ?? usersService.getCurrentUserId(),
                                },
                              );
                            },
                            title: Text(
                              exercise.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              exercise.muscleGroup,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                letterSpacing: -0.3,
                              ),
                            ),
                            actions: [
                              IconButtonWithBackground(
                                icon: Icons.edit_outlined,
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: () {
                                  if (record != null) {
                                    _showEditMaxRMDialog(context, ref, record!, exercise);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              IconButtonWithBackground(
                                icon: Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                                onPressed: () {
                                  if (record != null) {
                                    _showDeleteMaxRMDialog(context, ref, record!, exercise);
                                  }
                                },
                              ),
                            ],
                            bottomContent: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${record?.maxWeight ?? 0} kg',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat('d MMM yyyy').format(
                                  DateTime.parse(record?.date ?? DateTime.now().toString()),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  // Per tablet/desktop, manteniamo il GridView
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(crossAxisCount == 1 ? 16 : 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 20.0,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: latestRecords.length,
                    itemBuilder: (context, index) {
                      final record = latestRecords[index];
                      ExerciseModel exercise = exercises.firstWhere(
                        (ex) => ex.id == record?.exerciseId,
                        orElse: () => ExerciseModel(id: '', name: 'Exercise not found', type: '', muscleGroup: ''),
                      );
                      return ActionCard(
                        onTap: () {
                          context.push(
                            '/maxrmdashboard/exercise_stats/${exercise.id}',
                            extra: {
                              'exercise': exercise,
                              'userId': selectedUserId ?? usersService.getCurrentUserId(),
                            },
                          );
                        },
                        title: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          exercise.muscleGroup,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: -0.3,
                          ),
                        ),
                        actions: [
                          IconButtonWithBackground(
                            icon: Icons.edit_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () {
                              if (record != null) {
                                _showEditMaxRMDialog(context, ref, record!, exercise);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButtonWithBackground(
                            icon: Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error,
                            onPressed: () {
                              if (record != null) {
                                _showDeleteMaxRMDialog(context, ref, record!, exercise);
                              }
                            },
                          ),
                        ],
                        bottomContent: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${record?.maxWeight ?? 0} kg',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('d MMM yyyy').format(
                              DateTime.parse(record?.date ?? DateTime.now().toString()),
                            ),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
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

  void _showEditMaxRMDialog(
    BuildContext context,
    WidgetRef ref,
    ExerciseRecord record,
    ExerciseModel exercise,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditRecordDialog(
          record: record,
          exercise: exercise,
          exerciseRecordService: ref.read(exerciseRecordServiceProvider),
          usersService: ref.read(usersServiceProvider),
        );
      },
    );
  }

  void _showDeleteMaxRMDialog(
    BuildContext context,
    WidgetRef ref,
    ExerciseRecord record,
    ExerciseModel exercise,
  ) {
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
                _performDelete(context, ref, record, exercise);
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  void _performDelete(
    BuildContext context,
    WidgetRef ref,
    ExerciseRecord record,
    ExerciseModel exercise,
  ) async {
    final exerciseRecordService = ref.read(exerciseRecordServiceProvider);
    final selectedUserId = ref.read(selectedUserIdProvider);
    final usersService = ref.read(usersServiceProvider);
    
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
    final theme = Theme.of(context);

    return ActionCard(
      onTap: () {
        context.push(
          '/maxrmdashboard/exercise_stats/${exercise.id}',
          extra: {
            'exercise': exercise,
            'userId': selectedUserId ?? usersService.getCurrentUserId(),
          },
        );
      },
      title: Text(
        exercise.name,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      subtitle: Text(
        exercise.muscleGroup,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButtonWithBackground(
          icon: Icons.edit_outlined,
          color: theme.colorScheme.primary,
          onPressed: () => _showEditDialog(context, ref),
        ),
        const SizedBox(width: 8),
        IconButtonWithBackground(
          icon: Icons.delete_outline,
          color: theme.colorScheme.error,
          onPressed: () => _showDeleteDialog(context, ref),
        ),
      ],
      bottomContent: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${record.maxWeight} kg',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimaryContainer,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Text(
          DateFormat('d MMM yyyy').format(DateTime.parse(record.date)),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: -0.3,
          ),
        ),
      ],
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