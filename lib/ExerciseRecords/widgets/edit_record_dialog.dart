import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/UI/components/input.dart';
import 'package:alphanessone/UI/components/date_picker_field.dart';
import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/services/users_services.dart';
import 'package:alphanessone/models/exercise_record.dart';
import 'package:alphanessone/exerciseManager/exercise_model.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/exercise_utils.dart';
import 'package:alphanessone/ExerciseRecords/utils/max_rm_helpers.dart' as helpers;

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


