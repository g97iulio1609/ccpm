import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/athlete_selection_dialog.dart';
import 'package:alphanessone/trainingBuilder/week_list.dart';
import 'package:alphanessone/trainingBuilder/workout_list.dart';
import 'package:alphanessone/trainingBuilder/exercise_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_state_provider.dart';
import '../users_services.dart';

class TrainingProgramPage extends HookConsumerWidget {
  final String? programId;
  final String userId;
  final int? weekIndex;
  final int? workoutIndex;

  const TrainingProgramPage({
    super.key,
    this.programId,
    required this.userId,
    this.weekIndex,
    this.workoutIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final controller = ref.watch(trainingProgramControllerProvider);
    final program = ref.watch(trainingProgramStateProvider);
    final userRole = ref.watch(userRoleProvider);

    useEffect(() {
      if (programId != null && program.id != programId) {
        controller.loadProgram(programId!);
      }
      return null;
    }, [programId]);

    return Scaffold(
      body: program != null
          ? weekIndex != null
              ? workoutIndex != null
                  ? TrainingProgramExerciseList(
                      controller: controller,
                      weekIndex: weekIndex!,
                      workoutIndex: workoutIndex!,
                    )
                  : TrainingProgramWorkoutListPage(
                      controller: controller,
                      weekIndex: weekIndex!,
                    )
              : Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: controller.nameController,
                                decoration: const InputDecoration(labelText: 'Program Name'),
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'Please enter a program name' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: controller.descriptionController,
                                decoration: const InputDecoration(labelText: 'Description'),
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'Please enter a description' : null,
                              ),
                              const SizedBox(height: 16),
                              if (userRole == 'admin')
                                ElevatedButton(
                                  onPressed: () => _showAthleteSelectionDialog(context, ref, controller),
                                  child: const Text('Select Athlete'),
                                ),
                              if (userRole == 'admin') const SizedBox(height: 16),
                              TextFormField(
                                controller: controller.mesocycleNumberController,
                                decoration: const InputDecoration(labelText: 'Mesocycle Number'),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value?.isEmpty ?? true ? 'Please enter a mesocycle number' : null,
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('Hide Program'),
                                value: controller.program.hide,
                                onChanged: (value) {
                                  controller.updateHideProgram(value);
                                },
                              ),
                              const SizedBox(height: 16),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TrainingProgramWeekList(
                                    programId: programId ?? '',
                                    userId: userId,
                                    controller: controller,
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0).copyWith(bottom: 32),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: controller.addWeek,
                                child: const Text('Aggiungi Settimana'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => controller.submitProgram(context),
                                child: const Text('Salva Programma'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  void _showAthleteSelectionDialog(BuildContext context, WidgetRef ref, TrainingProgramController controller) {
    showDialog(
      context: context,
      builder: (context) => AthleteSelectionDialog(controller: controller),
    );
  }
}