import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'controller/training_program_controller.dart';
import 'training_program_state_provider.dart';
import 'reorder_dialog.dart';

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
    final weeks = program.weeks;

    return Scaffold(
      body: ListView.builder(
        itemCount: weeks.length,
        itemBuilder: (context, index) {
          final week = weeks[index];
          return _buildWeekCard(context, week, index);
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

  Widget _buildWeekCard(BuildContext context, Week week, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(
          'Week ${week.number}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Copy Week'),
              onTap: () => controller.copyWeek(index, context),
            ),
            PopupMenuItem(
              child: const Text('Delete Week'),
              onTap: () => controller.removeWeek(index),
            ),
            PopupMenuItem(
              child: const Text('Reorder Weeks'),
              onTap: () => _showReorderWeeksDialog(context),
            ),
          ],
        ),
        onTap: () {
          context.go(
              '/programs_screen/user_programs/$userId/training_program/$programId/week/$index');
        },
      ),
    );
  }

  void _showReorderWeeksDialog(BuildContext context) {
    final weekNames =
        controller.program.weeks.map((week) => 'Week ${week.number}').toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: weekNames,
        onReorder: controller.reorderWeeks,
      ),
    );
  }
}