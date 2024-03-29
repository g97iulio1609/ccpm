import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';
import 'training_program_form.dart';
import 'training_program_week_list.dart';
import 'volume_dashboard.dart';

class TrainingProgramPage extends HookConsumerWidget {
  final String? programId;
  final String userId;

  const TrainingProgramPage({super.key, this.programId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final controller = ref.watch(trainingProgramControllerProvider);

    useEffect(() {
      controller.loadProgram(programId);
      return null;
    }, [programId]);

    return Scaffold(
    
      body: SingleChildScrollView(
        child: TrainingProgramForm(
          formKey: formKey,
          controller: controller,
          onSubmit: () => controller.submitProgram(context),
          child: Column(
            children: [
              TrainingProgramWeekList(controller: controller),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => controller.addWeek(),
                  child: const Text('Add New Week'),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.program != null) {
            context.go(
              '/programs_screen/user_programs/$userId/training_program/$programId/volume_dashboard',
              extra: controller.program,
            );
          }
        },
        child: const Icon(Icons.show_chart),
      ),
    );
  }
}