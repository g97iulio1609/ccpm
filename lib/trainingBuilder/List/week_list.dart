import 'package:alphanessone/trainingBuilder/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

    return _buildWeeksList(
        controller, programId, userId, theme, colorScheme, context);
  }

  Widget _buildWeeksList(
    TrainingProgramController controller,
    String programId,
    String userId,
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.program.weeks.length,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
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
            onTap: () => context.go('/user_programs/training_program/week',
                extra: {
                  'userId': userId,
                  'programId': programId,
                  'weekIndex': index
                }),
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
                        '${controller.program.weeks[index].number}',
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
                      'Week ${controller.program.weeks[index].number}',
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
                    onPressed: () =>
                        _showWeekOptions(context, index, theme, colorScheme),
                  ),
                ],
              ),
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

  void _showReorderWeeksDialog(BuildContext context) {
    final weekNames =
        controller.program.weeks.map((week) => 'Week ${week.number}').toList();
    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: weekNames,
        onReorder: controller.reorderWeeks,
      ),
    );
  }
}
