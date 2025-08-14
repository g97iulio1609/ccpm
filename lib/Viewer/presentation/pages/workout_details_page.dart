import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/Viewer/presentation/notifiers/workout_details_notifier.dart';
import 'package:alphanessone/UI/components/skeleton.dart';
import 'package:alphanessone/UI/components/app_card.dart';
import 'package:alphanessone/UI/components/section_header.dart';
import 'package:alphanessone/Viewer/presentation/widgets/exercise_timer_bottom_sheet.dart';
import 'package:alphanessone/shared/widgets/page_scaffold.dart';
import 'package:alphanessone/shared/widgets/empty_state.dart';
import 'package:alphanessone/Viewer/UI/widgets/workout_dialogs.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/grouping.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/meta_chips.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/progress_bar.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/exercise_header.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/series_list.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/start_buttons.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/superset_components.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/superset_series_matrix.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/note_dialog.dart'
    as note_dialog;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:alphanessone/Viewer/presentation/widgets/workout_details/series_execution_dialog.dart'
    as series_dialog;

class WorkoutDetailsPage extends ConsumerStatefulWidget {
  final String programId;
  final String userId;
  final String weekId;
  final String workoutId;

  const WorkoutDetailsPage({
    super.key,
    required this.userId,
    required this.programId,
    required this.weekId,
    required this.workoutId,
  });

  @override
  ConsumerState<WorkoutDetailsPage> createState() => _WorkoutDetailsPageState();
}

class _WorkoutDetailsPageState extends ConsumerState<WorkoutDetailsPage> {
  @override
  Widget build(BuildContext context) {
    // Osserviamo lo stato dal WorkoutDetailsNotifier
    final state = ref.watch(workoutDetailsNotifierProvider(widget.workoutId));
    final notifier = ref.read(
      workoutDetailsNotifierProvider(widget.workoutId).notifier,
    );

    final colorScheme = Theme.of(context).colorScheme;
    // Stabilizziamo il rendering: per ora usiamo sempre la LISTA in tutte le larghezze
    // per evitare calcoli incoerenti che causano layout error su desktop.

    // Deprecated: calcolo colonne non più usato (si usa maxCrossAxisExtent)
    final padding = AppTheme.spacing.md;
    final spacing = AppTheme.spacing.md;

    // Se è in caricamento, mostra un indicatore di progresso
    if (state.isLoading) {
      return PageScaffold(
        colorScheme: colorScheme,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            sliver: SliverList.builder(
              itemCount: 6,
              itemBuilder: (context, index) => const SkeletonCard(),
            ),
          ),
        ],
      );
    }

    // Se c'è un errore, mostralo
    if (state.error != null) {
      return PageScaffold(
        colorScheme: colorScheme,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Errore durante il caricamento',
              subtitle: state.error!,
              onPrimaryAction: () => notifier.refreshWorkout(),
              primaryActionLabel: 'Riprova',
            ),
          ),
        ],
      );
    }

    // Se non ci sono esercizi, mostra un messaggio
    if (state.workout == null || state.workout!.exercises.isEmpty) {
      return PageScaffold(
        colorScheme: colorScheme,
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.fitness_center,
              title: 'Nessun esercizio trovato',
            ),
          ),
        ],
      );
    }

    // Raggruppa gli esercizi per superSet
    final exercises = state.workout!.exercises;
    final groupedExercises = groupExercisesBySuperSet(exercises);

    // Mostra gli esercizi in una lista o griglia
    Widget buildListBody() => RefreshIndicator(
      onRefresh: () => notifier.refreshWorkout(),
      child: Semantics(
        container: true,
        label: 'Dettagli allenamento, lista esercizi',
        child: ListView.builder(
          padding: EdgeInsets.all(padding),
          itemCount: groupedExercises.length,
          itemBuilder: (context, index) {
            final entry = groupedExercises.entries.elementAt(index);
            final exercises = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: exercises.length == 1
                  ? _buildSingleExerciseCard(
                      exercises.first,
                      context,
                      isListMode: true,
                    )
                  : _buildSuperSetCard(
                      superSetExercises: exercises,
                      context: context,
                      isListMode: true,
                    ),
            );
          },
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Soglia per passare alla griglia desktop/tablet
          const gridThreshold = 1200.0;
          if (width < gridThreshold) {
            return buildListBody();
          }

          // Griglia a colonne con altezza variabile (masonry): le card non vengono mai tagliate
          final bool ultraWide = width >= 1800;
          final bool veryWide = width >= 1600 && width < 1800;
          final double gridSpacing = (veryWide || ultraWide)
              ? AppTheme.spacing.sm
              : spacing;
          final int columns = ultraWide
              ? 5
              : veryWide
              ? 4
              : (width >= 1400 ? 3 : 2);

          return RefreshIndicator(
            onRefresh: () => notifier.refreshWorkout(),
            child: MasonryGridView.count(
              padding: EdgeInsets.all(padding),
              crossAxisCount: columns,
              mainAxisSpacing: gridSpacing,
              crossAxisSpacing: gridSpacing,
              itemCount: groupedExercises.length,
              itemBuilder: (context, index) {
                final entry = groupedExercises.entries.elementAt(index);
                final exercises = entry.value;
                final child = exercises.length == 1
                    ? _buildSingleExerciseCard(
                        exercises.first,
                        context,
                        // Usa layout completo anche in griglia per evitare tagli
                        isListMode: true,
                      )
                    : _buildSuperSetCard(
                        superSetExercises: exercises,
                        context: context,
                        // Usa layout completo anche in griglia per evitare tagli
                        isListMode: true,
                      );
                return Semantics(
                  container: true,
                  label: 'Scheda esercizio',
                  child: child,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Raggruppamento estratto in grouping.dart

  Widget _buildSingleExerciseCard(
    Exercise exercise,
    BuildContext context, {
    required bool isListMode,
  }) {
    final series = exercise.series;
    final firstNotDoneSeriesIndex = _findFirstNotDoneSeriesIndex(series);
    final isContinueMode = firstNotDoneSeriesIndex > 0;
    final allSeriesCompleted = series.every((serie) => serie.isCompleted);

    return AppCard(
      glass: true,
      header: ExerciseHeader(
        exercise: exercise,
        onNote: () => _showNoteDialog(
          exercise.id ?? '',
          exercise.name,
          exercise.note,
          ref.read(workoutDetailsNotifierProvider(widget.workoutId).notifier),
        ),
        onMenuSelected: (value) {
          if (value == 'change') {
            WorkoutDialogs.showChangeExerciseDialog(
              context,
              ref,
              exercise.toMap(),
              widget.userId,
              widget.workoutId,
            );
          } else if (value == 'edit_series') {
            WorkoutDialogs.showSeriesEditDialog(
              context,
              ref,
              exercise.toMap(),
              exercise.series.map((s) => s.toMap()).toList(),
              widget.userId,
              widget.workoutId,
            );
          }
        },
      ),
      background: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(38),
      child: Column(
        children: [
          if (isListMode)
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MetaChips(exercise: exercise),
                  SizedBox(height: AppTheme.spacing.sm),
                  ProgressBar(
                    done: series.where((s) => s.isCompleted).length,
                    total: series.length,
                    labelBuilder: (pct) =>
                        '${(pct * 100).round()}% • ${series.where((s) => s.isCompleted).length}/${series.length} serie',
                  ),
                  SizedBox(height: AppTheme.spacing.md),
                  if (!allSeriesCompleted) ...[
                    StartExerciseButton(
                      exercise: exercise,
                      startIndex: firstNotDoneSeriesIndex,
                      isContinue: isContinueMode,
                      onStart: _handleStartSeries,
                    ),
                    SizedBox(height: AppTheme.spacing.md),
                  ],
                  SeriesList(
                    series: series,
                    onSeriesTap: (s) => _showSeriesExecutionDialog(context, s),
                    onToggleComplete: (s) =>
                        _toggleSeriesCompletion(context, s),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MetaChips(exercise: exercise),
                      SizedBox(height: AppTheme.spacing.sm),
                      ProgressBar(
                        done: series.where((s) => s.isCompleted).length,
                        total: series.length,
                        labelBuilder: (pct) =>
                            '${(pct * 100).round()}% • ${series.where((s) => s.isCompleted).length}/${series.length} serie',
                      ),
                      SizedBox(height: AppTheme.spacing.md),
                      if (!allSeriesCompleted) ...[
                        StartExerciseButton(
                          exercise: exercise,
                          startIndex: firstNotDoneSeriesIndex,
                          isContinue: isContinueMode,
                          onStart: _handleStartSeries,
                        ),
                        SizedBox(height: AppTheme.spacing.md),
                      ],
                      SeriesList(
                        series: series,
                        onSeriesTap: (s) =>
                            _showSeriesExecutionDialog(context, s),
                        onToggleComplete: (s) =>
                            _toggleSeriesCompletion(context, s),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Header estratto in ExerciseHeader

  Widget _buildSuperSetCard({
    required List<Exercise> superSetExercises,
    required BuildContext context,
    required bool isListMode,
  }) {
    final allSeriesCompleted = superSetExercises.every((exercise) {
      return exercise.series.every((series) => series.isCompleted);
    });
    final totalSeries = superSetExercises
        .map((e) => e.series.length)
        .fold<int>(0, (p, c) => p + c);
    final doneSeries = superSetExercises
        .map((e) => e.series.where((s) => s.isCompleted).length)
        .fold<int>(0, (p, c) => p + c);

    return AppCard(
      glass: true,
      header: SectionHeader(
        title: 'Super Set',
        subtitle: '${superSetExercises.length} esercizi',
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
            child: Column(
              children: [
                ...superSetExercises.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final exercise = entry.value;
                  return SuperSetExerciseNameEntry(
                    index: idx,
                    exercise: exercise,
                    onNote: () => _showNoteDialog(
                      exercise.id ?? '',
                      exercise.name,
                      exercise.note,
                      ref.read(
                        workoutDetailsNotifierProvider(
                          widget.workoutId,
                        ).notifier,
                      ),
                    ),
                    onMenuSelected: (value) {
                      if (value == 'change') {
                        WorkoutDialogs.showChangeExerciseDialog(
                          context,
                          ref,
                          exercise.toMap(),
                          widget.userId,
                          widget.workoutId,
                        );
                      } else if (value == 'edit_series') {
                        WorkoutDialogs.showSeriesEditDialog(
                          context,
                          ref,
                          exercise.toMap(),
                          exercise.series.map((s) => s.toMap()).toList(),
                          widget.userId,
                          widget.workoutId,
                        );
                      }
                    },
                  );
                }),
                Padding(
                  padding: EdgeInsets.only(top: AppTheme.spacing.sm),
                  child: ProgressBar(
                    done: doneSeries,
                    total: totalSeries,
                    labelBuilder: (pct) =>
                        '${(pct * 100).round()}% • $doneSeries/$totalSeries serie',
                  ),
                ),
              ],
            ),
          ),
          if (isListMode)
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!allSeriesCompleted) ...[
                    StartSuperSetButton(
                      exercises: superSetExercises,
                      onStart: _handleStartSeries,
                    ),
                    const SizedBox(height: 24),
                  ],
                  SuperSetHeaderRow(exercises: superSetExercises),
                  SuperSetSeriesMatrix(
                    exercises: superSetExercises,
                    onSeriesTap: (s) => _showSeriesExecutionDialog(context, s),
                    onToggleComplete: (s) =>
                        _toggleSeriesCompletion(context, s),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!allSeriesCompleted) ...[
                        StartSuperSetButton(
                          exercises: superSetExercises,
                          onStart: _handleStartSeries,
                        ),
                        const SizedBox(height: 24),
                      ],
                      SuperSetHeaderRow(exercises: superSetExercises),
                      SuperSetSeriesMatrix(
                        exercises: superSetExercises,
                        onSeriesTap: (s) =>
                            _showSeriesExecutionDialog(context, s),
                        onToggleComplete: (s) =>
                            _toggleSeriesCompletion(context, s),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Superset exercise headers extracted in SuperSetExerciseNameEntry

  Future<void> _showNoteDialog(
    String exerciseId,
    String exerciseName,
    String? existingNote,
    WorkoutDetailsNotifier notifier,
  ) {
    return note_dialog.showNoteDialog(
      context: context,
      title: 'Note per $exerciseName',
      existingNote: existingNote,
      onDelete: () => notifier.deleteExerciseNote(exerciseId),
      onSave: (note) => notifier.saveExerciseNote(exerciseId, note),
    );
  }

  // Series header gestito da SeriesList

  // Series list estratto in SeriesList

  // Superset series matrix extracted in SuperSetSeriesMatrix

  // Series row estratto in SeriesList

  void _toggleSeriesCompletion(BuildContext context, Series series) {
    final notifier = ref.read(
      workoutDetailsNotifierProvider(widget.workoutId).notifier,
    );
    if (series.isCompleted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conferma'),
          content: const Text('Vuoi segnare questa serie come non completata?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () {
                notifier.completeSeries(series.id ?? '', false, 0, 0);
                Navigator.of(context).pop();
              },
              child: const Text('Conferma'),
            ),
          ],
        ),
      );
    } else {
      notifier.completeSeries(
        series.id ?? '',
        true,
        series.reps,
        series.weight,
      );
    }
  }

  // StartButton estratto in StartExerciseButton

  // Button estratto in StartSuperSetButton

  // Metodi di utilità
  int _findFirstNotDoneSeriesIndex(List<Series> series) {
    for (int i = 0; i < series.length; i++) {
      if (!series[i].isCompleted) {
        return i;
      }
    }
    return 0; // Se tutte le serie sono completate, restituisci 0
  }

  // UI helper estratti in widget modulari

  // Superset header extracted in SuperSetHeaderRow

  Future<void> _showSeriesExecutionDialog(BuildContext context, Series series) {
    return series_dialog.showSeriesExecutionDialog(
      context: context,
      initialReps: series.repsDone > 0 ? series.repsDone : series.reps,
      initialWeight: series.weightDone > 0 ? series.weightDone : series.weight,
      onSave: (repsDone, weightDone) async {
        final notifier = ref.read(
          workoutDetailsNotifierProvider(widget.workoutId).notifier,
        );

        try {
          await notifier.completeSeries(
            series.id ?? '',
            true,
            repsDone,
            weightDone,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Serie completata: ${repsDone}R × ${weightDone}kg',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }

  void _handleStartSeries(Series series, Exercise exercise) {
    ExerciseTimerBottomSheet.show(
      context: context,
      userId: widget.userId,
      exerciseId: exercise.id ?? '',
      workoutId: widget.workoutId,
      exerciseName: exercise.name,
      onSeriesComplete: (repsDone, weightDone) {
        final notifier = ref.read(
          workoutDetailsNotifierProvider(widget.workoutId).notifier,
        );
        notifier.completeSeries(series.id ?? '', true, repsDone, weightDone);
        Navigator.of(context).pop();
      },
      initialTimerSeconds: series.restTimeSeconds ?? 60,
      reps: series.reps,
      weight: series.weight,
    );
  }
}
