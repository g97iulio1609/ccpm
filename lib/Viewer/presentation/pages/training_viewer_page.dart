import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

import 'package:alphanessone/viewer/presentation/pages/workout_details_page.dart';
import 'package:alphanessone/viewer/viewer_providers.dart';

class TrainingViewerPage extends ConsumerStatefulWidget {
  final String programId;
  final String userId;

  const TrainingViewerPage({
    super.key,
    required this.programId,
    required this.userId,
  });

  @override
  ConsumerState<TrainingViewerPage> createState() => _TrainingViewerPageState();
}

class _TrainingViewerPageState extends ConsumerState<TrainingViewerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Week> _weeks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeeks();
  }

  Future<void> _loadWeeks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(workoutRepositoryProvider);
      final weeksStream = repository.getTrainingWeeks(widget.programId);

      final weeks = await weeksStream.first;

      if (mounted) {
        setState(() {
          _weeks = weeks;
          _isLoading = false;

          // Inizializza il TabController dopo aver caricato le settimane
          _tabController = TabController(
            length: _weeks.length,
            vsync: this,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_weeks.isNotEmpty) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Mostra il loader mentre carica
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
              ),
              SizedBox(height: AppTheme.spacing.md),
              Text(
                'Caricamento programma...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Mostra errore se presente
    if (_error != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 48,
              ),
              SizedBox(height: AppTheme.spacing.md),
              Text(
                'Errore durante il caricamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              SizedBox(height: AppTheme.spacing.sm),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacing.lg),
              FilledButton.icon(
                onPressed: _loadWeeks,
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    // Mostra messaggio se non ci sono settimane
    if (_weeks.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Programma di allenamento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
          ),
          backgroundColor: colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 48,
              ),
              SizedBox(height: AppTheme.spacing.md),
              Text(
                'Nessuna settimana trovata',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Mostra le settimane e i workout
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Programma di allenamento',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _weeks.map((week) {
            return Tab(
              text: 'Settimana ${week.number}',
            );
          }).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWeeks,
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _weeks.map((week) {
          return _WeekView(
            week: week,
            userId: widget.userId,
            programId: widget.programId,
          );
        }).toList(),
      ),
    );
  }
}

class _WeekView extends ConsumerWidget {
  final Week week;
  final String userId;
  final String programId;

  const _WeekView({
    required this.week,
    required this.userId,
    required this.programId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final spacing = AppTheme.spacing.md;

    // Se non ci sono workout, mostra un messaggio
    if (week.workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              size: 48,
            ),
            SizedBox(height: AppTheme.spacing.md),
            Text(
              'Nessun allenamento trovato',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
      );
    }

    // Mostra la lista dei workout per questa settimana
    return ListView.builder(
      padding: EdgeInsets.all(spacing),
      itemCount: week.workouts.length,
      itemBuilder: (context, index) {
        final workout = week.workouts[index];
        return _WorkoutCard(
          workout: workout,
          userId: userId,
          programId: programId,
          weekId: week.id,
        );
      },
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final String userId;
  final String programId;
  final String weekId;

  const _WorkoutCard({
    required this.workout,
    required this.userId,
    required this.programId,
    required this.weekId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Calcola lo stato di completamento
    final totalSeries = workout.exercises
        .fold<int>(0, (sum, exercise) => sum + exercise.series.length);
    final completedSeries = workout.exercises.fold<int>(
        0,
        (sum, exercise) =>
            sum + exercise.series.where((series) => series.isCompleted).length);
    final completionPercentage =
        totalSeries > 0 ? (completedSeries / totalSeries * 100).round() : 0;

    return Card(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutDetailsPage(
                userId: userId,
                programId: programId,
                weekId: weekId,
                workoutId: workout.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      workout.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: _getCompletionColor(
                          completionPercentage, colorScheme),
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Text(
                      '$completionPercentage%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: _getCompletionTextColor(
                                completionPercentage, colorScheme),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacing.sm),
              Text(
                '${workout.exercises.length} esercizi',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              SizedBox(height: AppTheme.spacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                child: LinearProgressIndicator(
                  value: totalSeries > 0 ? completedSeries / totalSeries : 0,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: _getCompletionColor(completionPercentage, colorScheme),
                  minHeight: 8,
                ),
              ),
              SizedBox(height: AppTheme.spacing.xs),
              Text(
                '$completedSeries/$totalSeries serie completate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCompletionColor(int percentage, ColorScheme colorScheme) {
    if (percentage >= 100) {
      return Colors.green;
    } else if (percentage > 50) {
      return colorScheme.primary;
    } else if (percentage > 0) {
      return Colors.orange;
    } else {
      return colorScheme.outline;
    }
  }

  Color _getCompletionTextColor(int percentage, ColorScheme colorScheme) {
    if (percentage >= 100) {
      return Colors.white;
    } else if (percentage > 50) {
      return colorScheme.onPrimary;
    } else if (percentage > 0) {
      return Colors.white;
    } else {
      return colorScheme.onSurface;
    }
  }
}
