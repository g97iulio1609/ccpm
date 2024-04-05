import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'training_program_controller.dart';
import 'training_program_state_provider.dart';

class TrainingProgramWeekList extends ConsumerWidget {
  final String programId;
  final String userId;
  final TrainingProgramController controller;

  const TrainingProgramWeekList({
    super.key,
    required this.programId,
    required this.userId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(trainingProgramStateProvider);

    return Scaffold(
    
      body: ListView.builder(
        itemCount: program.weeks.length,
        itemBuilder: (context, index) {
          final week = program.weeks[index];
          return ListTile(
            title: Text('Week ${week.number}'),
            onTap: () {
              context.go('/programs_screen/user_programs/$userId/training_program/$programId/week/$index');
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.addWeek();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}