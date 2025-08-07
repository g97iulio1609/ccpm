import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:alphanessone/providers/providers.dart' as app_providers;
import 'package:alphanessone/Viewer/UI/workout_provider.dart'
    as workout_provider;
import 'package:alphanessone/Viewer/UI/widgets/workout_dialogs.dart';

import 'package:alphanessone/Viewer/UI/widgets/series_widgets.dart';

class ExerciseCard extends ConsumerWidget {
  final Map<String, dynamic> exercise;
  final String userId;
  final String workoutId;
  final Function(Map<String, dynamic>, List<Map<String, dynamic>>, [int])
  onNavigateToDetails;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.userId,
    required this.workoutId,
    required this.onNavigateToDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = List<Map<String, dynamic>>.from(exercise['series']);
    final firstNotDoneSeriesIndex = ref
        .read(workout_provider.workoutServiceProvider)
        .findFirstNotDoneSeriesIndex(series);
    final isContinueMode = firstNotDoneSeriesIndex > 0;
    final allSeriesCompleted = series.every(
      (serie) =>
          ref.read(workout_provider.workoutServiceProvider).isSeriesDone(serie),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isListMode = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(color: colorScheme.outline.withAlpha(26), width: 1),
        boxShadow: AppTheme.elevations.small,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Column(
          children: [
            // Header dell'esercizio
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(77),
                border: Border(
                  bottom: BorderSide(color: colorScheme.outline.withAlpha(26)),
                ),
              ),
              child: _buildExerciseName(context, ref),
            ),

            // Contenuto dell'esercizio - layout responsive
            if (isListMode)
              // Layout per mobile
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!allSeriesCompleted) ...[
                      _buildStartButton(
                        context,
                        firstNotDoneSeriesIndex,
                        isContinueMode,
                      ),
                      SizedBox(height: AppTheme.spacing.md),
                    ],
                    const SeriesHeaderRow(),
                    SizedBox(height: AppTheme.spacing.sm),
                    ...SeriesWidgets.buildSeriesContainers(
                      series,
                      context,
                      ref,
                      _showEditSeriesDialog,
                    ),
                  ],
                ),
              )
            else
              // Layout per desktop/tablet
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!allSeriesCompleted) ...[
                          _buildStartButton(
                            context,
                            firstNotDoneSeriesIndex,
                            isContinueMode,
                          ),
                          SizedBox(height: AppTheme.spacing.md),
                        ],
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: AppTheme.spacing.xs,
                            horizontal: AppTheme.spacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withAlpha(77),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radii.sm,
                            ),
                          ),
                          child: const SeriesHeaderRow(),
                        ),
                        SizedBox(height: AppTheme.spacing.sm),
                        ...SeriesWidgets.buildSeriesContainers(
                          series,
                          context,
                          ref,
                          _showEditSeriesDialog,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseName(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = ref.watch(workout_provider.exerciseNotesProvider);
    final hasNote = notes.containsKey(exercise['id']);
    final userRole = ref.watch(app_providers.userRoleProvider);
    final isAdmin = userRole == 'admin';

    return Row(
      children: [
        if (hasNote)
          GestureDetector(
            onTap: () => _showNoteDialog(context, ref, notes[exercise['id']]),
            child: Container(
              margin: EdgeInsets.only(right: AppTheme.spacing.xs),
              padding: EdgeInsets.all(AppTheme.spacing.xxs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer,
              ),
              child: Text(
                'N',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Expanded(
          child: GestureDetector(
            onLongPress: () =>
                _showNoteDialog(context, ref, notes[exercise['id']]),
            child: Text(
              "${exercise['name']} ${exercise['variant'] ?? ''}",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _buildPopupMenu(context, ref, isAdmin),
      ],
    );
  }

  Widget _buildPopupMenu(BuildContext context, WidgetRef ref, bool isAdmin) {
    final colorScheme = Theme.of(context).colorScheme;

    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () => _handleMenuSelection(context, ref, 'change'),
          leadingIcon: const Icon(Icons.swap_horiz),
          child: const Text('Cambia esercizio'),
        ),
        if (isAdmin)
          MenuItemButton(
            onPressed: () => _handleMenuSelection(context, ref, 'edit_series'),
            leadingIcon: const Icon(Icons.list_alt),
            child: const Text('Modifica serie'),
          ),
        MenuItemButton(
          onPressed: () => _handleMenuSelection(context, ref, 'update_max'),
          leadingIcon: const Icon(Icons.fitness_center),
          child: const Text('Aggiorna Massimale'),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, WidgetRef ref, String value) {
    switch (value) {
      case 'change':
        WorkoutDialogs.showChangeExerciseDialog(context, ref, exercise, userId);
        break;
      case 'edit_series':
        _showEditSeriesDialog(
          context,
          ref,
          exercise,
          List<Map<String, dynamic>>.from(exercise['series'] ?? []),
        );
        break;
      case 'update_max':
        WorkoutDialogs.showUpdateMaxWeightDialog(
          context,
          ref,
          exercise,
          userId,
        );
        break;
    }
  }

  Widget _buildStartButton(
    BuildContext context,
    int firstNotDoneSeriesIndex,
    bool isContinueMode,
  ) {
    return AppButton(
      label: isContinueMode ? 'CONTINUA' : 'INIZIA',
      onPressed: () =>
          onNavigateToDetails(exercise, [exercise], firstNotDoneSeriesIndex),
      variant: AppButtonVariant.primary,
      size: AppButtonSize.md,
      block: true,
    );
  }

  void _showNoteDialog(
    BuildContext context,
    WidgetRef ref,
    String? existingNote,
  ) {
    WorkoutDialogs.showNoteDialog(
      context,
      ref,
      exercise['id'],
      exercise['name'],
      workoutId,
      existingNote,
    );
  }

  void _showEditSeriesDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> exercise,
    List<Map<String, dynamic>> series,
  ) {
    WorkoutDialogs.showSeriesEditDialog(context, ref, exercise, series, userId);
  }
}
