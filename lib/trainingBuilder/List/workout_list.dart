import 'package:alphanessone/trainingBuilder/Provider/workout_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../training_model.dart';
import '../controller/training_program_controller.dart';
import '../reorder_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:alphanessone/trainingBuilder/Provider/training_program_state_provider.dart';

class TrainingProgramWorkoutListPage extends ConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;

  const TrainingProgramWorkoutListPage({
    required this.controller,
    required this.weekIndex,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutStateProvider);
    final program = ref.watch(trainingProgramStateProvider.notifier).state;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: workouts.asMap().entries.map((entry) {
                final index = entry.key;
                final workout = entry.value;
                return _buildWorkoutSlidable(context, workout, index, ref, program);
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                ref.read(workoutStateProvider.notifier).addWorkout(weekIndex);
              },
              child: const Text('Aggiungi Allenamento'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSlidable(BuildContext context, Workout workout, int index, WidgetRef ref, TrainingProgram program) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              ref.read(workoutStateProvider.notifier).removeWorkout(index, program, weekIndex);
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
              ref.read(workoutStateProvider.notifier).addWorkout(weekIndex);
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.add,
            label: 'Aggiungi',
          ),
        ],
      ),
      child: _buildWorkoutCard(context, workout, index, ref, program),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout, int index, WidgetRef ref, TrainingProgram program) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.go(
              '/programs_screen/user_programs/${controller.program.athleteId}/training_program/${controller.program.id}/week/$weekIndex/workout/$index');
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
                    '${workout.order}',
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
                    'Allenamento ${workout.order}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Copia Allenamento'),
                    onTap: () {
                      ref.read(workoutStateProvider.notifier).copyWorkout(index, context, program, weekIndex);
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Elimina Allenamento'),
                    onTap: () {
                      ref.read(workoutStateProvider.notifier).removeWorkout(index, program, weekIndex);
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Riordina Allenamenti'),
                    onTap: () {
                      _showReorderWorkoutsDialog(context, ref, weekIndex);
                    },
                  ),
                  PopupMenuItem(
                    child: const Text('Aggiungi Allenamento'),
                    onTap: () {
                      ref.read(workoutStateProvider.notifier).addWorkout(weekIndex);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReorderWorkoutsDialog(BuildContext context, WidgetRef ref, int weekIndex) {
    final workoutNames = ref.watch(workoutStateProvider).map((workout) => 'Allenamento ${workout.order}').toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: workoutNames,
        onReorder: (oldIndex, newIndex) {
          ref.read(workoutStateProvider.notifier).reorderWorkouts(oldIndex, newIndex, weekIndex);
        },
      ),
    );
  }
}