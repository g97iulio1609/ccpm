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
import '../UI/components/user_autocomplete.dart';
import '../../providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Effetto per caricare gli utenti
    useEffect(() {
      Future<void> fetchUsers() async {
        if (currentUserRole == 'admin' || currentUserRole == 'coach') {
          try {
            List<UserModel> users = await _fetchUsersByRole(
                currentUserRole, usersService, coachingService);
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
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withAlpha(128),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Search Bar
              if (currentUserRole == 'admin' || currentUserRole == 'coach')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing.xl),
                    child: _buildSearchBar(
                      selectedUserController,
                      focusNode,
                      context,
                      ref,
                      theme,
                      colorScheme,
                    ),
                  ),
                ),

              // Records Grid
              SliverPadding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                sliver: _buildAllExercisesMaxRMs(
                  ref,
                  usersService,
                  exerciseRecordService,
                  theme,
                  colorScheme,
                  selectedUserId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(
    TextEditingController controller,
    FocusNode focusNode,
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(128),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      child: UserTypeAheadField(
        controller: controller,
        focusNode: focusNode,
        onSelected: (UserModel user) {
          ref.read(selectedUserIdProvider.notifier).state = user.id;
        },
        onChanged: (String value) {
          final allUsers = ref.read(userListProvider);
          final filteredUsers = allUsers
              .where((user) =>
                  user.name.toLowerCase().contains(value.toLowerCase()) ||
                  user.email.toLowerCase().contains(value.toLowerCase()))
              .toList();
          ref.read(filteredUserListProvider.notifier).state = filteredUsers;
        },
      ),
    );
  }

  Widget _buildAllExercisesMaxRMs(
    WidgetRef ref,
    UsersService usersService,
    ExerciseRecordService exerciseRecordService,
    ThemeData theme,
    ColorScheme colorScheme,
    String? selectedUserId,
  ) {
    return Builder(builder: (context) {
      final exercisesAsyncValue = ref.watch(exercisesStreamProvider);

      return exercisesAsyncValue.when(
        data: (exercises) {
          final userId = selectedUserId ?? usersService.getCurrentUserId();
          List<Stream<ExerciseRecord?>> exerciseRecordStreams =
              exercises.map((exercise) {
            return exerciseRecordService
                .getExerciseRecords(userId: userId, exerciseId: exercise.id)
                .map((records) => records.isNotEmpty
                    ? records
                        .reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
                    : null);
          }).toList();

          return StreamBuilder<List<ExerciseRecord?>>(
            stream: CombineLatestStream.list(exerciseRecordStreams),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                );
              }

              final latestRecords = (snapshot.data ?? [])
                  .where((record) => record != null)
                  .toList();

              if (latestRecords.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withAlpha(128),
                        ),
                        SizedBox(height: AppTheme.spacing.md),
                        Text(
                          'No Records Found',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing.sm),
                        Text(
                          'Start adding your max records',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final record = latestRecords[index]!;
                    final exercise = exercises.firstWhere(
                      (ex) => ex.id == record.exerciseId,
                      orElse: () => ExerciseModel(
                        id: '',
                        name: 'Exercise not found',
                        type: '',
                        muscleGroups: [],
                      ),
                    );
                    return _buildRecordCard(
                      record,
                      exercise,
                      theme,
                      colorScheme,
                      context,
                    );
                  },
                  childCount: latestRecords.length,
                ),
              );
            },
          );
        },
        loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => SliverToBoxAdapter(
          child: Center(
            child: Text(
              'Error loading max RMs: $error',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRecordCard(
    ExerciseRecord record,
    ExerciseModel exercise,
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return Builder(builder: (context) {
      final ref = ProviderScope.containerOf(context);

      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          border: Border.all(
            color: colorScheme.outline.withAlpha(128),
          ),
          boxShadow: AppTheme.elevations.small,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToExerciseStats(
                context, exercise, record.id.split('_')[0]),
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Exercise Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(77),
                      borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                    ),
                    child: Text(
                      exercise.muscleGroups.firstOrNull ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  SizedBox(height: AppTheme.spacing.xs),

                  Text(
                    exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: AppTheme.spacing.xs),

                  // Max Weight Display
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withAlpha(51),
                          colorScheme.primary.withAlpha(51).withAlpha(204),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.xxl),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${record.maxWeight} kg',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  SizedBox(height: AppTheme.spacing.xs),

                  // Date
                  Text(
                    DateFormat('d MMM yyyy').format(record.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  SizedBox(height: AppTheme.spacing.xs),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: () => _showEditMaxRMDialog(
                            context, ref, record, exercise),
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      SizedBox(width: AppTheme.spacing.xs),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        onTap: () => _showDeleteMaxRMDialog(
                            context, ref, record, exercise),
                        colorScheme: colorScheme,
                        theme: theme,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radii.full),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.sm,
            vertical: AppTheme.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: isDestructive
                ? colorScheme.errorContainer.withAlpha(77)
                : colorScheme.surfaceContainerHighest.withAlpha(77),
            borderRadius: BorderRadius.circular(AppTheme.radii.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDestructive ? colorScheme.error : colorScheme.primary,
              ),
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      isDestructive ? colorScheme.error : colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<UserModel>> _fetchUsersByRole(String role,
      UsersService usersService, CoachingService coachingService) async {
    List<UserModel> users = [];
    if (role == 'admin') {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } else if (role == 'coach') {
      final currentUserId = usersService.getCurrentUserId();
      final associations =
          await coachingService.getCoachAssociations(currentUserId).first;
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

  static void showAddMaxRMDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) => _MaxRMForm(
        onSubmit: (exerciseId, exerciseName, maxWeight, repetitions, date,
            keepWeight, selectedUserId) async {
          final exerciseRecordService = ref.read(exerciseRecordServiceProvider);
          final usersService = ref.read(usersServiceProvider);
          final userId = selectedUserId ?? usersService.getCurrentUserId();

          double adjustedMaxWeight = maxWeight.toDouble();
          if (repetitions > 1) {
            adjustedMaxWeight =
                (maxWeight / (1.0278 - (0.0278 * repetitions))).roundToDouble();
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

  static void _showEditMaxRMDialog(
    BuildContext context,
    ProviderContainer ref,
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

  static void _showDeleteMaxRMDialog(
    BuildContext context,
    ProviderContainer ref,
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
              child: Text('Cancel',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performDelete(context, ref, record, exercise);
              },
              child: Text('Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  static void _performDelete(
    BuildContext context,
    ProviderContainer ref,
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

  void _navigateToExerciseStats(
      BuildContext context, ExerciseModel exercise, String userId) {
    context.push('/maxrmdashboard/exercise_stats',
        extra: {'exercise': exercise, 'userId': userId});
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
    final maxWeightController =
        useTextEditingController(text: record.maxWeight.toString());
    final repetitionsController =
        useTextEditingController(text: record.repetitions.toString());
    final keepWeight = useState(false);
    final selectedDate = useState(record.date);

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
            _buildDialogTextFormField(
                maxWeightController, 'Max weight', context),
            _buildDialogTextFormField(
                repetitionsController, 'Repetitions', context),
            _buildDatePicker(context, selectedDate),
            Row(
              children: [
                Text(
                  'Keep current weight',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
          child: Text('Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _handleSave(
                context,
                ref,
                maxWeightController.text,
                repetitionsController.text,
                selectedDate.value,
                keepWeight.value);
          },
          child: Text('Save',
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }

  Widget _buildDialogTextFormField(TextEditingController controller,
      String labelText, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle:
              TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: TextInputType.number,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildDatePicker(
      BuildContext context, ValueNotifier<DateTime> selectedDate) {
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
            labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(selectedDate.value),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              Icon(Icons.calendar_today,
                  color: Theme.of(context).colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave(BuildContext context, WidgetRef ref, String maxWeightText,
      String repetitionsText, DateTime selectedDate, bool keepWeight) async {
    final selectedUserId = ref.read(selectedUserIdProvider);
    double newMaxWeight = double.parse(maxWeightText);
    int newRepetitions = int.parse(repetitionsText);

    if (newRepetitions > 1) {
      newMaxWeight =
          (newMaxWeight / (1.0278 - (0.0278 * newRepetitions))).roundToDouble();
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
                    onSelected: (selectedExercise) {
                      selectedExerciseController.value = selectedExercise;
                    },
                    athleteId: ref.watch(selectedUserIdProvider) ?? '',
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
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
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
                          final exerciseId =
                              selectedExerciseController.value?.id ?? '';
                          final exerciseName = exerciseNameController.text;
                          final maxWeight =
                              num.tryParse(maxWeightController.text) ?? 0;
                          final repetitions =
                              int.tryParse(repetitionsController.text) ?? 0;
                          final selectedUserId =
                              ref.read(selectedUserIdProvider);
                          onSubmit(
                              exerciseId,
                              exerciseName,
                              maxWeight,
                              repetitions,
                              selectedDate.value,
                              keepWeight.value,
                              selectedUserId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFFD700), // Yellow color
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Add Max RM',
                          style: TextStyle(fontSize: 16)),
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

  Widget _buildDatePicker(
      BuildContext context, ValueNotifier<DateTime> selectedDate) {
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
