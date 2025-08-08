import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/widgets/page_scaffold.dart';
import 'package:alphanessone/shared/widgets/empty_state.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/reorder_dialog.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';

/// Pagina per visualizzare e gestire la lista degli allenamenti (workouts)
class TrainingProgramWorkoutListPage extends StatefulWidget {
  final TrainingProgramController controller;
  final int weekIndex;

  const TrainingProgramWorkoutListPage({
    super.key,
    required this.controller,
    required this.weekIndex,
  });

  @override
  State<TrainingProgramWorkoutListPage> createState() =>
      _TrainingProgramWorkoutListPageState();
}

class _TrainingProgramWorkoutListPageState
    extends State<TrainingProgramWorkoutListPage>
    with TrainingListMixin {
  String _layout = 'list'; // 'list' | 'grid'
  String _density = 'detail'; // 'compact' | 'detail'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final workouts = widget.controller.program.weeks[widget.weekIndex].workouts;
    final screenSize = MediaQuery.of(context).size;
    final isNarrow = screenSize.width < 900;
    final isCompactDensity = _density == 'compact' || isNarrow;

    return PageScaffold(
      colorScheme: colorScheme,
      slivers: [
        // Header con SegmentedButton per layout e densità
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppTheme.spacing.lg,
              right: AppTheme.spacing.lg,
              left: AppTheme.spacing.lg,
              bottom: AppTheme.spacing.md,
            ),
            child: Wrap(
              spacing: AppTheme.spacing.md,
              runSpacing: AppTheme.spacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'list',
                      icon: Icon(Icons.view_list),
                      label: Text('Lista'),
                    ),
                    ButtonSegment(
                      value: 'grid',
                      icon: Icon(Icons.grid_view),
                      label: Text('Griglia'),
                    ),
                  ],
                  selected: {_layout},
                  onSelectionChanged: (s) => setState(() => _layout = s.first),
                ),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'compact',
                      icon: Icon(Icons.compress),
                      label: Text('Compatta'),
                    ),
                    ButtonSegment(
                      value: 'detail',
                      icon: Icon(Icons.unfold_more),
                      label: Text('Dettaglio'),
                    ),
                  ],
                  selected: {_density},
                  onSelectionChanged: (s) => setState(() => _density = s.first),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(
            isCompactDensity ? AppTheme.spacing.md : AppTheme.spacing.lg,
          ),
          sliver: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: workouts.isEmpty
                ? _buildEmptyState(theme, colorScheme, isCompactDensity)
                : (_layout == 'list'
                      ? _buildWorkoutsList(
                          workouts,
                          theme,
                          colorScheme,
                          isCompactDensity,
                        )
                      : _buildWorkoutsGrid(
                          workouts,
                          theme,
                          colorScheme,
                          isCompactDensity,
                        )),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isCompact,
  ) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyState(
        icon: Icons.fitness_center_outlined,
        title: 'Nessun allenamento disponibile',
        subtitle: 'Aggiungi il primo allenamento per iniziare',
      ),
    );
  }

  Widget _buildWorkoutsList(
    List<dynamic> workouts,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isCompact,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: isCompact ? AppTheme.spacing.sm : AppTheme.spacing.md,
          ),
          child: _buildWorkoutCard(
            context,
            index,
            theme,
            colorScheme,
            isCompact,
          ),
        );
      }, childCount: workouts.length),
    );
  }

  Widget _buildWorkoutsGrid(
    List<dynamic> workouts,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isCompact,
  ) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate((context, index) {
        return _buildWorkoutCard(context, index, theme, colorScheme, isCompact);
      }, childCount: workouts.length),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isCompact ? 400 : 520,
        mainAxisSpacing: AppTheme.spacing.md,
        crossAxisSpacing: AppTheme.spacing.md,
        mainAxisExtent: isCompact ? 120 : 140,
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isCompact,
  ) {
    return buildCard(
      colorScheme: colorScheme,
      onTap: () => _navigateToWorkout(index),
      child: Padding(
        padding: EdgeInsets.all(
          isCompact ? AppTheme.spacing.md : AppTheme.spacing.lg,
        ),
        child: _WorkoutCardContent(
          index: index,
          theme: theme,
          colorScheme: colorScheme,
          isCompact: isCompact,
          onCopy: () =>
              widget.controller.copyWorkout(widget.weekIndex, index, context),
          onReorder: _showReorderDialog,
          onAdd: () => widget.controller.addWorkout(widget.weekIndex),
          onDelete: () => _handleDeleteWorkout(index),
        ),
      ),
    );
  }

  void _navigateToWorkout(int index) {
    context.go(
      '/user_programs/training_program/week/workout',
      extra: {
        'userId': widget.controller.program.athleteId,
        'programId': widget.controller.program.id,
        'weekIndex': widget.weekIndex,
        'workoutIndex': index,
      },
    );
  }

  void _showReorderDialog() {
    final workoutNames = widget
        .controller
        .program
        .weeks[widget.weekIndex]
        .workouts
        .map((workout) => 'Workout ${workout.order}')
        .toList();

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: workoutNames,
        onReorder: (oldIndex, newIndex) => widget.controller.reorderWorkouts(
          widget.weekIndex,
          oldIndex,
          newIndex,
        ),
      ),
    );
  }

  void _handleDeleteWorkout(int index) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Elimina Allenamento',
      content: 'Sei sicuro di voler eliminare questo allenamento?',
    );

    if (confirmed && mounted) {
      widget.controller.removeWorkout(widget.weekIndex, index + 1);
    }
  }
}

class _WorkoutCardContent extends StatelessWidget {
  final int index;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isCompact;
  final VoidCallback onCopy;
  final VoidCallback onReorder;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _WorkoutCardContent({
    required this.index,
    required this.theme,
    required this.colorScheme,
    required this.isCompact,
    required this.onCopy,
    required this.onReorder,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            _buildWorkoutIcon(),
            SizedBox(
              width: isCompact ? AppTheme.spacing.md : AppTheme.spacing.lg,
            ),
            Expanded(child: _buildWorkoutTitle()),
            _buildOptionsMenu(),
          ],
        );
      },
    );
  }

  Widget _buildWorkoutIcon() {
    final iconSize = isCompact ? 40.0 : 48.0;

    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(76),
        borderRadius: BorderRadius.circular(
          isCompact ? AppTheme.radii.sm : AppTheme.radii.md,
        ),
      ),
      child: Center(
        child: FittedBox(
          child: Text(
            '${index + 1}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: isCompact ? 16 : 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutTitle() {
    return Text(
      'Workout ${index + 1}',
      style: theme.textTheme.titleMedium?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: isCompact ? 16 : 18,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildOptionsMenu() {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          icon: Icon(
            Icons.more_vert,
            color: colorScheme.primary,
            size: isCompact ? 20 : 24,
          ),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          padding: EdgeInsets.all(
            isCompact ? AppTheme.spacing.xs : AppTheme.spacing.sm,
          ),
          splashRadius: isCompact ? 20 : 24,
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_copy_outlined),
          onPressed: onCopy,
          child: const Text('Copia Allenamento'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.reorder),
          onPressed: onReorder,
          child: const Text('Riordina Allenamenti'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.add),
          onPressed: onAdd,
          child: const Text('Aggiungi Allenamento'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          child: const Text('Elimina Allenamento'),
        ),
      ],
    );
  }
}
