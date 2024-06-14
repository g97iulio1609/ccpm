import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'exerciseManager/exercise_model.dart';
import 'exerciseManager/exercises_services.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/services/exercise_record_services.dart';

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
final usersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final service = ref.watch(userServiceProvider);
  return service.getUsers();
});
final keepWeightProvider = StateProvider<bool>((ref) => false);

class MaxRMDashboard extends HookConsumerWidget {
  const MaxRMDashboard({super.key});

  @override
@override
Widget build(BuildContext context, WidgetRef ref) {
  final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
  final usersService = ref.watch(userServiceProvider);
  final exerciseRecordService = ref.watch(exerciseRecordServiceProvider);
  final selectedExerciseController = useState<ExerciseModel?>(null);
  final exerciseNameController = useTextEditingController();
  final maxWeightController = useTextEditingController();
  final repetitionsController = useTextEditingController();
  final keepWeight = ref.watch(keepWeightProvider);
  final dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> addRecord({
    required String exerciseId,
    required String exerciseName,
    required num maxWeight,
    required int repetitions,
  }) async {
    String userId = usersService.getCurrentUserId();
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
          _buildExerciseTypeAheadField(exercisesAsyncValue, selectedExerciseController, exerciseNameController, context),
          _buildTextFormField(
            controller: maxWeightController,
            labelText: 'Max weight lifted',
            context: context,
            keyboardType: TextInputType.number,
          ),
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
          SizedBox(height: 20), // Aggiungi questa linea per creare spazio
          _buildAllExercisesMaxRMs(ref, usersService, exerciseRecordService, context),
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

            if (context.mounted) {
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
  ) {
    final exercisesAsyncValue = ref.watch(exercisesStreamProvider);
    final userId = usersService.getCurrentUserId();

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
                  return _buildExerciseCard(context, record, exercise, exerciseRecordService, usersService);
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

  Widget _buildExerciseCard(
    BuildContext context,
    ExerciseRecord? record,
    ExerciseModel exercise,
    ExerciseRecordService exerciseRecordService,
    UsersService usersService,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditDialog(context, record, exercise, exerciseRecordService, usersService),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${record?.maxWeight} kg x ${record?.repetitions} reps',
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record!.date,
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditDialog(context, record, exercise, exerciseRecordService, usersService),
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteDialog(context, record, exercise, exerciseRecordService, usersService),
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    ExerciseRecord record,
    ExerciseModel exercise,
    ExerciseRecordService exerciseRecordService,
    UsersService usersService,
  ) {
    TextEditingController maxWeightController = TextEditingController(text: record.maxWeight.toString());
    TextEditingController repetitionsController = TextEditingController(text: record.repetitions.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditRecordDialog(
          record: record,
          exercise: exercise,
          exerciseRecordService: exerciseRecordService,
          usersService: usersService,
          maxWeightController: maxWeightController,
          repetitionsController: repetitionsController,
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    ExerciseRecord record,
    ExerciseModel exercise,
    ExerciseRecordService exerciseRecordService,
    UsersService usersService,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
            TextButton(
              onPressed: () async {
                await exerciseRecordService.deleteExerciseRecord(
                  userId: usersService.getCurrentUserId(),
                  exerciseId: exercise.id,
                  recordId: record.id,
                );
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            ),
          ],
        );
      },
    );
  }
}

class EditRecordDialog extends StatefulWidget {
  final ExerciseRecord record;
  final ExerciseModel exercise;
  final ExerciseRecordService exerciseRecordService;
  final UsersService usersService;
  final TextEditingController maxWeightController;
  final TextEditingController repetitionsController;

  const EditRecordDialog({
    Key? key,
    required this.record,
    required this.exercise,
    required this.exerciseRecordService,
    required this.usersService,
    required this.maxWeightController,
    required this.repetitionsController,
  }) : super(key: key);

  @override
  _EditRecordDialogState createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<EditRecordDialog> {
  bool keepWeight = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Edit Record',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogTextFormField(widget.maxWeightController, 'Max weight', context),
          _buildDialogTextFormField(widget.repetitionsController, 'Repetitions', context),
          Row(
            children: [
              Text(
                'Keep current weight',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              Switch(
                value: keepWeight,
                onChanged: (value) {
                  setState(() {
                    keepWeight = value;
                  });
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
          onPressed: () async {
            double newMaxWeight = double.parse(widget.maxWeightController.text);
            int newRepetitions = int.parse(widget.repetitionsController.text);

            if (newRepetitions > 1) {
              newMaxWeight = (newMaxWeight / (1.0278 - (0.0278 * newRepetitions))).roundToDouble();
              newRepetitions = 1;
            }

            await widget.exerciseRecordService.updateExerciseRecord(
              userId: widget.usersService.getCurrentUserId(),
              exerciseId: widget.exercise.id,
              recordId: widget.record.id,
              maxWeight: newMaxWeight,
              repetitions: newRepetitions,
            );

            if (context.mounted) {
              if (keepWeight) {
                debugPrint('Updating intensity while keeping weight.');
                await widget.exerciseRecordService.updateIntensityForProgram(
                  widget.usersService.getCurrentUserId(),
                  widget.exercise.id,
                  newMaxWeight,
                );
              } else {
                debugPrint('Updating weights based on new max weight.');
                await widget.exerciseRecordService.updateWeightsForProgram(
                  widget.usersService.getCurrentUserId(),
                  widget.exercise.id,
                  newMaxWeight,
                );
              }
            }

            if (context.mounted) {
              Navigator.of(context).pop();
            }
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
}
