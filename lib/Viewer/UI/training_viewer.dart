import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/training_program_provider.dart';

class TrainingViewer extends ConsumerStatefulWidget {
  final String programId;
  final String userId;

  const TrainingViewer({super.key, required this.programId, required this.userId});

  @override
  _TrainingViewerState createState() => _TrainingViewerState();
}

class _TrainingViewerState extends ConsumerState<TrainingViewer> {
  @override
  void initState() {
    super.initState();
    // Delay the fetch call to after the build phase
    Future.microtask(() => fetchTrainingWeeks());
  }

  Future<void> fetchTrainingWeeks() async {
    ref.read(trainingLoadingProvider.notifier).state = true;
    try {
      final weeks = await ref.read(trainingServiceProvider).fetchTrainingWeeks(widget.programId);
      if (mounted) {
        ref.read(trainingWeeksProvider.notifier).state = weeks;
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        ref.read(trainingLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(trainingLoadingProvider);
    final weeks = ref.watch(trainingWeeksProvider);

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                var week = weeks[index];
                return WeekCard(
                  weekNumber: week['number'],
                  weekDescription: week['description'] ?? '',
                  onTap: () {
                    context.go(
                        '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${week['id']}');
                  },
                );
              },
            ),
    );
  }
}

class WeekCard extends StatelessWidget {
  final int weekNumber;
  final String weekDescription;
  final VoidCallback onTap;

  const WeekCard({
    super.key,
    required this.weekNumber,
    required this.weekDescription,
    required this.onTap,
  });

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
                    '$weekNumber',
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
                    'Settimana $weekNumber',
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
