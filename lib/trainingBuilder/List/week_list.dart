// week_list.dart
import 'package:alphanessone/trainingBuilder/Provider/week_state_provider.dart';
import 'package:alphanessone/trainingBuilder/training_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../controller/training_program_controller.dart';
import '../Provider/training_program_state_provider.dart';
import '../reorder_dialog.dart';

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
    final weeks = ref.watch(weekStateProvider);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        final week = weeks[index];
        return _buildWeekSlidable(context, week, index, ref);
      },
    );
  }

  Widget _buildWeekSlidable(BuildContext context, Week week, int index, WidgetRef ref) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              ref.read(weekStateProvider.notifier).removeWeek(index);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Elimina',
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              ref.read(weekStateProvider.notifier).addWeek();
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.add,
            label: 'Aggiungi',
          ),
        ],
      ),
      child: _buildWeekCard(context, week, index, ref),
    );
  }

  Widget _buildWeekCard(BuildContext context, Week week, int index, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.go('/programs_screen/user_programs/$userId/training_program/$programId/week/$index');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${week.number}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Settimana ${week.number}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Copia Settimana'),
                    onTap: () => ref.read(weekStateProvider.notifier).copyWeek(index, context),
                  ),
                  PopupMenuItem(
                    child: const Text('Elimina Settimana'),
                    onTap: () => ref.read(weekStateProvider.notifier).removeWeek(index),
                  ),
                  PopupMenuItem(
                    child: const Text('Riordina Settimane'),
                    onTap: () => _showReorderWeeksDialog(context, ref),
                  ),
                  PopupMenuItem(
                    child: const Text('Aggiungi Settimana'),
                    onTap: () => ref.read(weekStateProvider.notifier).addWeek(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReorderWeeksDialog(BuildContext context, WidgetRef ref) {
    final weekNames = ref.watch(weekStateProvider).map((week) => 'Settimana ${week.number}').toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: weekNames,
        onReorder: (oldIndex, newIndex) {
          ref.read(weekStateProvider.notifier).reorderWeeks(oldIndex, newIndex);
        },
      ),
    );
  }
}