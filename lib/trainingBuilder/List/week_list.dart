import 'package:alphanessone/trainingBuilder/models/week_model.dart';
import 'package:alphanessone/trainingBuilder/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../controller/training_program_controller.dart';
import '../dialog/reorder_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';

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
    final weeks = program.weeks;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        final week = weeks[index];
        return _buildWeekSlidable(context, week, index, theme, colorScheme);
      },
    );
  }

  Widget _buildWeekSlidable(
    BuildContext context,
    Week week,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => controller.removeWeek(index),
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(AppTheme.radii.lg),
            ),
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
        ],
      ),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => controller.addWeek(),
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(AppTheme.radii.lg),
            ),
            icon: Icons.add,
            label: 'Add',
          ),
        ],
      ),
      child: _buildWeekCard(context, week, index, theme, colorScheme),
    );
  }

  Widget _buildWeekCard(
    BuildContext context,
    Week week,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppTheme.spacing.xs,
        horizontal: AppTheme.spacing.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToWeek(context, userId, programId, index),
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${week.number}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: AppTheme.spacing.lg),
                Expanded(
                  child: Text(
                    'Week ${week.number}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => _showWeekOptions(context, index, theme, colorScheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showWeekOptions(
    BuildContext context,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: 'Settimana ${index + 1}',
        subtitle: 'Gestisci settimana',
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.calendar_today,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Copia Settimana',
            icon: Icons.content_copy_outlined,
            onTap: () => controller.copyWeek(index, context),
          ),
          BottomMenuItem(
            title: 'Riordina Settimane',
            icon: Icons.reorder,
            onTap: () => _showReorderWeeksDialog(context),
          ),
          BottomMenuItem(
            title: 'Aggiungi Settimana',
            icon: Icons.add,
            onTap: () => controller.addWeek(),
          ),
          BottomMenuItem(
            title: 'Elimina Settimana',
            icon: Icons.delete_outline,
            onTap: () => controller.removeWeek(index),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _navigateToWeek(BuildContext context, String userId, String programId, int weekIndex) {
    final routePath = '/user_programs/$userId/training_program/$programId/week/$weekIndex';
    context.go(routePath);
  }

  void _showReorderWeeksDialog(BuildContext context) {
    final weekNames = controller.program.weeks.map((week) => 'Week ${week.number}').toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: weekNames,
        onReorder: controller.reorderWeeks,
      ),
    );
  }
}