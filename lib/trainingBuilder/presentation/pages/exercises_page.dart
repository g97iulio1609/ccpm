import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/cards/exercise_card.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/bulk_series_dialog.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/lists/series_list_widget.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/exercise_options_dialog.dart';
import 'package:alphanessone/trainingBuilder/presentation/widgets/dialogs/bulk_exercise_delete_dialog.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/trainingBuilder/services/exercise_service.dart';
import 'package:alphanessone/providers/providers.dart';
import 'package:alphanessone/shared/widgets/page_scaffold.dart';
import 'package:alphanessone/shared/widgets/empty_state.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/reorder_dialog.dart';
import 'package:alphanessone/trainingBuilder/widgets/exercise_list_widgets.dart'
    show ReorderExercisesFAB;

class ExercisesPage extends ConsumerWidget {
  final TrainingProgramController controller;
  final int weekIndex;
  final int workoutIndex;

  const ExercisesPage({
    super.key,
    required this.controller,
    required this.weekIndex,
    required this.workoutIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final exercises = workout.exercises;
    final usersService = ref.watch(usersServiceProvider);
    final exerciseRecordService = usersService.exerciseRecordService;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    // Breakpoints responsivi
    final bool useGrid = screenWidth >= 900;
    final bool compact = screenWidth < 700; // mobile stretto => compatto

    final page = PageScaffold(
      colorScheme: colorScheme,
      slivers: [
        // Header con titolo contestuale e CTA aggiungi (layout/densità automatici)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppTheme.spacing.lg,
              right: AppTheme.spacing.lg,
              left: AppTheme.spacing.lg,
              bottom: AppTheme.spacing.md,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 780;
                final isMobile = constraints.maxWidth < 600;
                
                final actions = [
                  if (exercises.isNotEmpty) ...[
                    Flexible(
                      child: AppButton(
                        label: isMobile ? 'Riordina' : 'Riordina Esercizi',
                        icon: Icons.reorder,
                        variant: AppButtonVariant.ghost,
                        size: compact ? AppButtonSize.sm : AppButtonSize.md,
                        block: !isMobile,
                        onPressed: () => _showReorderDialog(context, exercises),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.sm),
                  ],
                  Flexible(
                    child: AppButton(
                      label: isMobile ? 'Aggiungi' : 'Aggiungi Esercizio',
                      icon: Icons.add_circle_outline,
                      variant: AppButtonVariant.primary,
                      size: compact ? AppButtonSize.sm : AppButtonSize.md,
                      block: !isMobile,
                      onPressed: () => controller.addExercise(weekIndex, workoutIndex, context),
                    ),
                  ),
                ];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'Esercizi',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    if (isNarrow)
                      Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: AppTheme.spacing.sm,
                          runSpacing: AppTheme.spacing.xs,
                          children: actions,
                        ),
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(AppTheme.spacing.md),
          sliver: exercises.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.fitness_center_outlined,
                    title: 'Nessun esercizio disponibile',
                    subtitle: 'Aggiungi il primo esercizio per iniziare',
                    onPrimaryAction: () => controller.addExercise(weekIndex, workoutIndex, context),
                    primaryActionLabel: 'Aggiungi esercizio',
                  ),
                )
              : (useGrid
                    ? _buildGridView(
                        context,
                        exercises,
                        exerciseRecordService,
                        compact ? 'compact' : 'detail',
                      )
                    : _buildListView(
                        context,
                        exercises,
                        exerciseRecordService,
                        compact ? 'compact' : 'detail',
                      )),
        ),
      ],
    );

    // Su schermi compatti, mostra un FAB per il riordino come azione rapida
    final showFab = compact && exercises.isNotEmpty;
    if (!showFab) return page;

    return Stack(
      children: [
        page,
        Positioned(
          right: AppTheme.spacing.lg,
          bottom: AppTheme.spacing.lg,
          child: ReorderExercisesFAB(
            onPressed: () => _showReorderDialog(context, exercises),
            isCompact: true,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  void _showReorderDialog(BuildContext context, List<Exercise> exercises) {
    if (exercises.isEmpty) return;
    final labels = exercises.map((e) => e.name).toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: labels,
        onReorder: (oldIndex, newIndex) {
          controller.reorderExercises(weekIndex, workoutIndex, oldIndex, newIndex);
        },
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<Exercise> exercises,
    dynamic exerciseRecordService,
    String density,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
          child: _buildExerciseCard(context, exercises[index], exerciseRecordService, density),
        );
      }, childCount: exercises.length),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<Exercise> exercises,
    dynamic exerciseRecordService,
    String density,
  ) {
    final isCompact = density == 'compact';
    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        return _buildExerciseCard(context, exercises[index], exerciseRecordService, density);
      }, childCount: exercises.length),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isCompact ? 420 : 560,
        mainAxisSpacing: AppTheme.spacing.md,
        crossAxisSpacing: AppTheme.spacing.md,
        mainAxisExtent: isCompact ? 420 : 520,
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    Exercise exercise,
    dynamic exerciseRecordService,
    String density,
  ) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    final superSets = (workout.superSets as List<dynamic>? ?? [])
        .where((ss) => (ss['exerciseIds'] as List<dynamic>? ?? []).contains(exercise.id))
        .map((ss) => SuperSet.fromMap(ss as Map<String, dynamic>))
        .toList();

    return FutureBuilder<num>(
      future: ExerciseService.getLatestMaxWeight(
        exerciseRecordService,
        controller.program.athleteId,
        exercise.exerciseId ?? '',
      ),
      builder: (context, snapshot) {
        final latestMaxWeight = snapshot.data ?? 0;

        return ExerciseCard(
          exercise: exercise,
          superSets: superSets,
          latestMaxWeight: latestMaxWeight,
          onTap: () => _navigateToExerciseDetails(context, exercise, superSets),
          onOptions: () => _showExerciseOptions(context, exercise, latestMaxWeight),
          seriesWidget: SeriesListWidget(
            exercise: exercise,
            controller: controller,
            weekIndex: weekIndex,
            workoutIndex: workoutIndex,
            exerciseIndex: exercise.order - 1,
            latestMaxWeight: latestMaxWeight,
          ),
          dense: density == 'compact',
        );
      },
    );
  }


  // Max weight unified via ExerciseService.getLatestMaxWeight

  void _navigateToExerciseDetails(
    BuildContext context,
    Exercise exercise,
    List<SuperSet> superSets,
  ) {
    final superSetExerciseIndex = superSets.isNotEmpty
        ? superSets.indexOf(
            superSets.firstWhere(
              (ss) => ss.exerciseIds.contains(exercise.id),
              orElse: () => SuperSet(id: '', exerciseIds: []),
            ),
          )
        : 0;

    context.go(
      '/user_programs/training_viewer/week_details/workout_details/exercise_details',
      extra: {
        'programId': controller.program.id,
        'weekId': controller.program.weeks[weekIndex].id,
        'workoutId': controller.program.weeks[weekIndex].workouts[workoutIndex].id,
        'exerciseId': exercise.id,
        'userId': controller.program.athleteId,
        'superSetExercises': superSets.map((s) => s.toMap()).toList(),
        'superSetExerciseIndex': superSetExerciseIndex,
        'seriesList': exercise.series.map((s) => s.toMap()).toList(),
        'startIndex': 0,
      },
    );
  }

  void _showExerciseOptions(BuildContext context, Exercise exercise, num latestMaxWeight) {
    showDialog(
      context: context,
      builder: (context) => ExerciseOptionsDialog(
        exercise: exercise,
        latestMaxWeight: latestMaxWeight,
        controller: controller,
        weekIndex: weekIndex,
        workoutIndex: workoutIndex,
        onBulkSeries: () => _showBulkSeriesDialog(context, exercise),
        onBulkDelete: () => _showBulkDeleteDialog(context, exercise),
        onEdit: () => controller.editExercise(weekIndex, workoutIndex, exercise.order - 1, context),
        onDuplicate: () =>
            controller.duplicateExercise(weekIndex, workoutIndex, exercise.order - 1),
        onDelete: () => controller.removeExercise(weekIndex, workoutIndex, exercise.order - 1),
      ),
    );
  }

  void _showBulkDeleteDialog(BuildContext context, Exercise initialExercise) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];
    showDialog(
      context: context,
      builder: (context) => BulkExerciseDeleteDialog(
        workoutExercises: workout.exercises,
        initialSelection: initialExercise,
        onConfirm: (selected) async {
          final ids = selected.map((e) => e.id).whereType<String>().toList();
          if (ids.isEmpty) return;
          await controller.removeExercisesBulk(weekIndex, workoutIndex, ids, context);
        },
      ),
    );
  }

  void _showBulkSeriesDialog(BuildContext context, Exercise exercise) {
    final workout = controller.program.weeks[weekIndex].workouts[workoutIndex];

    showDialog(
      context: context,
      builder: (context) => BulkSeriesSelectionDialog(
        initialExercise: exercise,
        workoutExercises: workout.exercises,
        onNext: (selectedExercises) {
          _showBulkSeriesConfigurationDialog(context, selectedExercises);
        },
      ),
    );
  }

  void _showBulkSeriesConfigurationDialog(BuildContext context, List<Exercise> exercises) {
    showDialog(
      context: context,
      builder: (context) => BulkSeriesConfigurationDialog(
        exercises: exercises,
        onApply: (updatedExercises) {
          // Aggiorna gli esercizi nel controller
          for (var exercise in updatedExercises) {
            controller.updateExercise(exercise);
          }
        },
      ),
    );
  }
}
