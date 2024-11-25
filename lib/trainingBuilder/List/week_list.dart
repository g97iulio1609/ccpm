import 'package:alphanessone/trainingBuilder/models/week_model.dart';
import 'package:alphanessone/trainingBuilder/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../controller/training_program_controller.dart';
import '../dialog/reorder_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';

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
                // Week Number Badge
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

                // Week Title
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

                // Options Menu
                _buildOptionsMenu(context, index, theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsMenu(
    BuildContext context,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
      ),
      itemBuilder: (context) => [
        _buildMenuItem(
          'Copy Week',
          Icons.content_copy_outlined,
          () => controller.copyWeek(index, context),
          theme,
          colorScheme,
        ),
        _buildMenuItem(
          'Delete Week',
          Icons.delete_outline,
          () => controller.removeWeek(index),
          theme,
          colorScheme,
          isDestructive: true,
        ),
        _buildMenuItem(
          'Reorder Weeks',
          Icons.reorder,
          () => _showReorderWeeksDialog(context),
          theme,
          colorScheme,
        ),
        _buildMenuItem(
          'Add Week',
          Icons.add,
          () => controller.addWeek(),
          theme,
          colorScheme,
        ),
      ],
    );
  }

  PopupMenuItem<void> _buildMenuItem(
    String text,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
    ColorScheme colorScheme, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDestructive ? colorScheme.error : colorScheme.onSurface,
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDestructive ? colorScheme.error : colorScheme.onSurface,
            ),
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