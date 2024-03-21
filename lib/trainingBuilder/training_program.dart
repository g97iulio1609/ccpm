import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';
import 'training_program_form.dart';
import 'training_program_week_list.dart';

class TrainingProgramPage extends HookConsumerWidget {
  final String? programId;

  const TrainingProgramPage({super.key, this.programId});

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final formKey = useMemoized(() => GlobalKey<FormState>());
  final controller = ref.watch(trainingProgramControllerProvider);

  useEffect(() {
    controller.loadProgram(programId);
    return null;
  }, [programId]);

  return Scaffold(
    appBar: AppBar(
      title: const Text('Training Program'),
    ),
    body: TrainingProgramForm(
      formKey: formKey,
      controller: controller,
      onSubmit: () => controller.submitProgram(context),
      child: TrainingProgramWeekList(controller: controller),
    ),
  );
}}