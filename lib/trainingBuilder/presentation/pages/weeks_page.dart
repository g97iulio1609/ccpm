import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/reorder_dialog.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/shared/widgets/empty_state.dart';

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
    final weeks = controller.program.weeks;
    return _WeekListView(
      controller: controller,
      programId: programId,
      userId: userId,
      weeks: weeks,
    );
  }
}

class _WeekListView extends StatefulWidget {
  final TrainingProgramController controller;
  final String programId;
  final String userId;
  final List weeks;

  const _WeekListView({
    required this.controller,
    required this.programId,
    required this.userId,
    required this.weeks,
  });

  @override
  State<_WeekListView> createState() => _WeekListViewState();
}

class _WeekListViewState extends State<_WeekListView> with TrainingListMixin {
  @override
  Widget build(BuildContext context) {
    final weeks = widget.controller.program.weeks;
    if (weeks.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.lg),
        child: EmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'Nessuna settimana disponibile',
          subtitle: 'Aggiungi la prima settimana per iniziare',
          onPrimaryAction: widget.controller.addWeek,
          primaryActionLabel: 'Aggiungi settimana',
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeks.length,
      itemBuilder: (context, index) => Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
        child: _buildWeekCard(context, index),
      ),
    );
  }

  Widget _buildWeekCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final week = widget.controller.program.weeks[index];

    return buildCard(
      colorScheme: colorScheme,
      onTap: () => _navigateToWeek(index),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.lg),
        child: _WeekCardContent(
          weekNumber: week.number,
          theme: theme,
          colorScheme: colorScheme,
          onOptionsPressed: () => _showWeekOptions(context, index),
        ),
      ),
    );
  }

  void _navigateToWeek(int index) {
    context.go(
      '/user_programs/training_program/week',
      extra: {
        'userId': widget.userId,
        'programId': widget.programId,
        'weekIndex': index,
      },
    );
  }

  void _showWeekOptions(BuildContext context, int index) {
    showOptionsBottomSheet(
      context,
      title: 'Settimana ${index + 1}',
      subtitle: 'Gestisci settimana',
      leadingIcon: Icons.calendar_today,
      items: _buildWeekMenuItems(index),
    );
  }

  List<BottomMenuItem> _buildWeekMenuItems(int index) {
    return [
      BottomMenuItem(
        title: 'Copia Settimana',
        icon: Icons.content_copy_outlined,
        onTap: () => widget.controller.copyWeek(index, context),
      ),
      BottomMenuItem(
        title: 'Riordina Settimane',
        icon: Icons.reorder,
        onTap: () => _showReorderDialog(),
      ),
      BottomMenuItem(
        title: 'Aggiungi Settimana',
        icon: Icons.add,
        onTap: () => widget.controller.addWeek(),
      ),
      BottomMenuItem(
        title: 'Elimina Settimana',
        icon: Icons.delete_outline,
        onTap: () => _handleDeleteWeek(index),
        isDestructive: true,
      ),
    ];
  }

  void _showReorderDialog() {
    final weekNames = widget.controller.program.weeks
        .map((week) => 'Week ${week.number}')
        .toList();

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: weekNames,
        onReorder: widget.controller.reorderWeeks,
      ),
    );
  }

  void _handleDeleteWeek(int index) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Elimina Settimana',
      content: 'Sei sicuro di voler eliminare questa settimana?',
    );

    if (confirmed && mounted) {
      widget.controller.removeWeek(index);
    }
  }
}

class _WeekCardContent extends StatelessWidget {
  final int weekNumber;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onOptionsPressed;

  const _WeekCardContent({
    required this.weekNumber,
    required this.theme,
    required this.colorScheme,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildWeekIcon(),
        SizedBox(width: AppTheme.spacing.lg),
        Expanded(child: _buildWeekTitle()),
        _buildOptionsButton(),
      ],
    );
  }

  Widget _buildWeekIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(76),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$weekNumber',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekTitle() {
    return Text(
      'Week $weekNumber',
      style: theme.textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildOptionsButton() {
    return IconButton(
      icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
      onPressed: onOptionsPressed,
    );
  }
}
