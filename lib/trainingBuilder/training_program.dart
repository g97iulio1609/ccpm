import 'package:alphanessone/trainingBuilder/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/training_program_form.dart';
import 'package:alphanessone/trainingBuilder/training_program_week_list.dart';
import 'package:alphanessone/trainingBuilder/training_program_workout_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_state_provider.dart';

class TrainingProgramPage extends HookConsumerWidget {
  final String? programId;
  final String userId;
  final int? weekIndex;

  const TrainingProgramPage({super.key, this.programId, required this.userId, this.weekIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final controller = ref.watch(trainingProgramControllerProvider);
    final program = ref.watch(trainingProgramStateProvider);

    useEffect(() {
      if (programId != null && program.id != programId) {
        controller.loadProgram(programId!);
      }
      return null;
    }, [programId]);

    return Scaffold(
      body: program != null
          ? weekIndex != null
              ? TrainingProgramWorkoutListPage(
                  controller: controller,
                  weekIndex: weekIndex!,
                )
              : SingleChildScrollView(
                  child: TrainingProgramForm(
                    formKey: formKey,
                    controller: controller,
                    onSubmit: () => controller.submitProgram(context),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.9,
                      ),
                      child: TrainingProgramWeekList(
                        programId: programId!,
                        userId: userId,
                        controller: controller,
                      ),
                    ),
                  ),
                )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}