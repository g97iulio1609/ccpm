import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/training_program_provider.dart';

class WeekDetails extends ConsumerStatefulWidget {
  final String programId;
  final String weekId;
  final String userId;

  const WeekDetails({
    Key? key,
    required this.programId,
    required this.weekId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<WeekDetails> createState() => _WeekDetailsState();
}

class _WeekDetailsState extends ConsumerState<WeekDetails> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeWeekName();
      _isInitialized = true;
    }
  }

  Future<void> _initializeWeekName() async {
    final weekService = ref.read(trainingProgramServicesProvider);
    final weekName = await weekService.fetchWeekName(widget.weekId);
    if (mounted) {
      ref.read(currentWeekNameProvider.notifier).state = weekName;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekService = ref.watch(trainingProgramServicesProvider);

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: weekService.getWorkouts(widget.weekId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final workouts = snapshot.data!.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  })
              .toList();

          return ListView.builder(
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final workoutId = workout['id'];

              return WorkoutCard(
                workoutOrder: workout['order'],
                workoutDescription: workout['description'] ?? '',
                onTap: () {
                  if (workoutId != null) {
                    context.go(
                      '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/$workoutId',
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final int workoutOrder;
  final String workoutDescription;
  final VoidCallback onTap;

  const WorkoutCard({
    Key? key,
    required this.workoutOrder,
    required this.workoutDescription,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
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
                    '$workoutOrder',
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
                    'Allenamento $workoutOrder',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}