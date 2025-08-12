import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/Main/app_theme.dart';
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
  // Layout automatico in base alla larghezza schermo

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

    final screenWidth = MediaQuery.of(context).size.width;
    final useGrid = screenWidth >= 900;
    return Column(
      children: [
        // Layout automatico: nessun selettore manuale
        useGrid ? _buildGrid(weeks) : _buildList(weeks),
      ],
    );
  }

  Widget _buildList(List weeks) {
    // Queste viste sono inserite in una colonna non scrollabile nel form principale,
    // quindi usiamo shrinkWrap e disabilitiamo lo scroll.
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

  Widget _buildGrid(List weeks) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeks.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 520,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 120,
      ),
      itemBuilder: (context, index) => _buildWeekCard(context, index),
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
          onCopy: () => widget.controller.copyWeek(index, context),
          onReorder: _showReorderDialog,
          onAdd: () => widget.controller.addWeek(),
          onDelete: () => _handleDeleteWeek(index),
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

  // Opzioni portate a MenuAnchor in _WeekCardContent

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
  final VoidCallback onCopy;
  final VoidCallback onReorder;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _WeekCardContent({
    required this.weekNumber,
    required this.theme,
    required this.colorScheme,
    required this.onCopy,
    required this.onReorder,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildWeekIcon(),
        SizedBox(width: AppTheme.spacing.lg),
        Expanded(child: _buildWeekTitle()),
        _buildOptionsMenu(),
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

  Widget _buildOptionsMenu() {
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
          leadingIcon: const Icon(Icons.content_copy_outlined),
          onPressed: onCopy,
          child: const Text('Copia Settimana'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.reorder),
          onPressed: onReorder,
          child: const Text('Riordina Settimane'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.add),
          onPressed: onAdd,
          child: const Text('Aggiungi Settimana'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          child: const Text('Elimina Settimana'),
        ),
      ],
    );
  }
}
