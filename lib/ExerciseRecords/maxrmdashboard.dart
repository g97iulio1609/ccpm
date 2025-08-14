import 'package:alphanessone/ExerciseRecords/exercise_autocomplete.dart';
import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:alphanessone/Coaching/coaching_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../exerciseManager/exercise_model.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import '../../providers/providers.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/providers/ui_settings_provider.dart';
import 'package:alphanessone/UI/components/glass.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/UI/components/date_picker_field.dart';
import 'package:alphanessone/UI/components/input.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/exercise_utils.dart';
import 'package:alphanessone/ExerciseRecords/providers/max_rm_providers.dart'
    as maxrm;
import 'package:alphanessone/ExerciseRecords/widgets/max_rm_search_bar.dart';
import 'package:alphanessone/ExerciseRecords/widgets/max_rm_grid.dart';
import 'package:alphanessone/ExerciseRecords/utils/max_rm_helpers.dart'
    as helpers;

class MaxRMDashboard extends HookConsumerWidget {
  const MaxRMDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersService = ref.watch(usersServiceProvider);
    final coachingService = ref.watch(coachingServiceProvider);
    ref.watch(exerciseRecordServiceProvider);
    final currentUserRole = ref.watch(currentUserRoleProvider);
    final selectedUserController = useTextEditingController();
    final selectedUserId = ref.watch(selectedUserIdProvider);
    final focusNode = useFocusNode();
    final userFetchComplete = useState(false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final glassEnabled = ref.watch(uiGlassEnabledProvider);

    // Effetto per caricare gli utenti
    useEffect(() {
      Future<void> fetchUsers() async {
        if (currentUserRole == 'admin' || currentUserRole == 'coach') {
          try {
            List<UserModel> users = await _fetchUsersByRole(
              currentUserRole,
              usersService,
              coachingService,
            );
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

    final content = SafeArea(
      child: CustomScrollView(
        slivers: [
          // Search Bar
          if (currentUserRole == 'admin' || currentUserRole == 'coach')
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.xl),
                child: MaxRMSearchBar(
                  controller: selectedUserController,
                  focusNode: focusNode,
                ),
              ),
            ),

          // Records Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.xl,
                vertical: AppTheme.spacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GlassLite(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Filtra per esercizio...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          ref.read(maxrm.recordsFilterProvider.notifier).state =
                              value.trim().toLowerCase();
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  GlassLite(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ref.watch(maxrm.recordsSortProvider),
                        items: const [
                          DropdownMenuItem(
                            value: 'date_desc',
                            child: Text('Più recenti'),
                          ),
                          DropdownMenuItem(
                            value: 'weight_desc',
                            child: Text('Peso maggiore'),
                          ),
                        ],
                        onChanged: (v) =>
                            ref.read(maxrm.recordsSortProvider.notifier).state =
                                v ?? 'date_desc',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(AppTheme.spacing.xl),
            sliver: MaxRMGridSliver(selectedUserId: selectedUserId),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: glassEnabled
          ? GlassLite(padding: EdgeInsets.zero, radius: 0, child: content)
          : Container(
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
              child: content,
            ),
    );
  }

  // Pulito da codice legacy: grid/search/dialog modularizzati in widgets e utils

  Future<List<UserModel>> _fetchUsersByRole(
    String role,
    UsersService usersService,
    CoachingService coachingService,
  ) async {
    List<UserModel> users = [];
    if (role == 'admin') {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      users = snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } else if (role == 'coach') {
      final currentUserId = usersService.getCurrentUserId();
      final associations = await coachingService
          .getCoachAssociations(currentUserId)
          .first;
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
        onSubmit:
            (
              exerciseId,
              exerciseName,
              maxWeight,
              repetitions,
              date,
              keepWeight,
              selectedUserId,
            ) async {
              final exerciseRecordService = ref.read(
                exerciseRecordServiceProvider,
              );
              final usersService = ref.read(usersServiceProvider);
              final userId = selectedUserId ?? usersService.getCurrentUserId();

              double adjustedMaxWeight = repetitions > 1
                  ? ExerciseUtils.calculateMaxRM(
                      maxWeight.toDouble(),
                      repetitions,
                    ).roundToDouble()
                  : maxWeight.toDouble();

              await exerciseRecordService.addExerciseRecord(
                userId: userId,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                maxWeight: adjustedMaxWeight,
                repetitions: 1,
                date: DateFormat('yyyy-MM-dd').format(date),
              );

              await helpers.updateProgramAfterMaxRM(
                exerciseRecordService,
                userId,
                exerciseId,
                adjustedMaxWeight,
                keepWeight,
              );

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

  // legacy: non più utilizzato (gestito nel widget estratto)
  // static void _showEditMaxRMDialog(...) {}

  // legacy: non più utilizzato (gestito nel widget estratto)
  // static void _showDeleteMaxRMDialog(...) {}

  // legacy: gestione delete spostata nel widget estratto

  // legacy: non più utilizzato
  // void _navigateToExerciseStats(...) {}
}

// Spostati in providers/max_rm_providers.dart

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
    final maxWeightController = useTextEditingController(
      text: record.maxWeight.toString(),
    );
    final repetitionsController = useTextEditingController(
      text: record.repetitions.toString(),
    );
    final keepWeight = useState(false);
    final selectedDate = useState(record.date);

    return AppDialog(
      title: const Text('Edit Record'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _handleSave(
              context,
              ref,
              maxWeightController.text,
              repetitionsController.text,
              selectedDate.value,
              keepWeight.value,
            );
          },
          child: const Text('Save'),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextFormField(
              maxWeightController,
              'Max weight',
              context,
            ),
            _buildDialogTextFormField(
              repetitionsController,
              'Repetitions',
              context,
            ),
            _buildDatePicker(context, selectedDate),
            Row(
              children: [
                Text(
                  'Keep current weight',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
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
    );
  }

  Widget _buildDialogTextFormField(
    TextEditingController controller,
    String labelText,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AppInput.number(controller: controller, label: labelText),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    ValueNotifier<DateTime> selectedDate,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DatePickerField(
        value: selectedDate.value,
        label: 'Date',
        onDateSelected: (date) => selectedDate.value = date,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      ),
    );
  }

  void _handleSave(
    BuildContext context,
    WidgetRef ref,
    String maxWeightText,
    String repetitionsText,
    DateTime selectedDate,
    bool keepWeight,
  ) async {
    final selectedUserId = ref.read(selectedUserIdProvider);
    double newMaxWeight = double.parse(maxWeightText);
    int newRepetitions = int.parse(repetitionsText);

    if (newRepetitions > 1) {
      newMaxWeight = ExerciseUtils.calculateMaxRM(
        newMaxWeight,
        newRepetitions,
      ).roundToDouble();
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

      await helpers.updateProgramAfterMaxRM(
        exerciseRecordService,
        selectedUserId ?? usersService.getCurrentUserId(),
        exercise.id,
        newMaxWeight,
        keepWeight,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record updated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update record: $e')));
      }
    }
  }
}

class _MaxRMForm extends HookConsumerWidget {
  final Function(String, String, num, int, DateTime, bool, String?) onSubmit;

  const _MaxRMForm({required this.onSubmit});

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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
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
                          final selectedUserId = ref.read(
                            selectedUserIdProvider,
                          );
                          onSubmit(
                            exerciseId,
                            exerciseName,
                            maxWeight,
                            repetitions,
                            selectedDate.value,
                            keepWeight.value,
                            selectedUserId,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFFFFD700,
                        ), // Yellow color
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add Max RM',
                        style: TextStyle(fontSize: 16),
                      ),
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
    if (keyboardType == TextInputType.number) {
      return AppInput.number(
        controller: controller,
        label: labelText,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $labelText';
          }
          return null;
        },
      );
    }
    return AppInput.text(
      controller: controller,
      label: labelText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $labelText';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    ValueNotifier<DateTime> selectedDate,
  ) {
    return DatePickerField(
      value: selectedDate.value,
      label: 'Date',
      onDateSelected: (date) => selectedDate.value = date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
  }
}
