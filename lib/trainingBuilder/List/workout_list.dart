import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../controller/training_program_controller.dart';
import '../dialog/reorder_dialog.dart';
import '../models/workout_model.dart';

class TrainingProgramWorkoutListPage extends StatefulWidget {
  final TrainingProgramController controller;
  final int weekIndex;

  const TrainingProgramWorkoutListPage({
    required this.controller,
    required this.weekIndex,
    super.key,
  });

  @override
  State<TrainingProgramWorkoutListPage> createState() =>
      _TrainingProgramWorkoutListPageState();
}

class _TrainingProgramWorkoutListPageState
    extends State<TrainingProgramWorkoutListPage> {
  @override
  Widget build(BuildContext context) {
    final week = widget.controller.program.weeks[widget.weekIndex];
    final workouts = week.workouts;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: workouts.asMap().entries.map((entry) {
                final index = entry.key;
                final workout = entry.value;
                return _buildWorkoutSlidable(context, workout, index);
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => widget.controller.addWorkout(widget.weekIndex),
              child: const Text('Aggiungi Allenamento'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutSlidable(BuildContext context, Workout workout, int index) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              widget.controller.removeWorkout(widget.weekIndex, workout.order);
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
              widget.controller.addWorkout(widget.weekIndex);
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.add,
            label: 'Aggiungi',
          ),
        ],
      ),
      child: _buildWorkoutCard(context, workout, index),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.go(
              '/programs_screen/user_programs/${widget.controller.program.athleteId}/training_program/${widget.controller.program.id}/week/${widget.weekIndex}/workout/$index');
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
                    onTap: () => widget.controller.copyWorkout(
                        widget.weekIndex, index, context),
                  ),
                  PopupMenuItem(
                    child: const Text('Elimina Allenamento'),
                    onTap: () =>
                        widget.controller.removeWorkout(widget.weekIndex, workout.order),
                  ),
                  PopupMenuItem(
                    child: const Text('Riordina Allenamenti'),
                    onTap: () => _showReorderWorkoutsDialog(context),
                  ),
                  PopupMenuItem(
                    child: const Text('Aggiungi Allenamento'),
                    onTap: () => widget.controller.addWorkout(widget.weekIndex),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReorderWorkoutsDialog(BuildContext context) {
    final workoutNames = widget.controller.program.weeks[widget.weekIndex]
        .workouts
        .map((workout) => 'Allenamento ${workout.order}')
        .toList();

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: workoutNames,
        onReorder: (oldIndex, newIndex) => widget.controller
            .reorderWorkouts(widget.weekIndex, oldIndex, newIndex),
      ),
    );
  }
}