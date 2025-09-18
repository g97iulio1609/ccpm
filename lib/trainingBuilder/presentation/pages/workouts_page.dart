import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/shared/widgets/page_scaffold.dart';
import 'package:alphanessone/shared/widgets/empty_state.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/reorder_dialog.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/controller/workout_controller.dart'
    show WorkoutDuplicationException;

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
  // Layout e densità ora sono automatici in base ai breakpoints

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Protezione: in fase di caricamento il programma potrebbe non avere ancora la settimana richiesta
    final hasWeek =
        widget.weekIndex <
        (widget.controller.program.weeks.isNotEmpty
            ? widget.controller.program.weeks.length
            : 0);
    if (!hasWeek) {
      return PageScaffold(
        colorScheme: colorScheme,
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }
    final workouts = widget.controller.program.weeks[widget.weekIndex].workouts;
    final screenSize = MediaQuery.of(context).size;
    final bool useGrid = screenSize.width >= 900;
    final bool isCompactDensity = screenSize.width < 700;

    return PageScaffold(
      colorScheme: colorScheme,
      slivers: [
        // Header semplificato: titolo e sottotitolo con info layout
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppTheme.spacing.lg,
              right: AppTheme.spacing.lg,
              left: AppTheme.spacing.lg,
              bottom: AppTheme.spacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allenamenti',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Sottotitolo rimosso su richiesta (niente dicitura vista compatta/dettagliata)
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(
            isCompactDensity ? AppTheme.spacing.md : AppTheme.spacing.lg,
          ),
          sliver: workouts.isEmpty
              ? _buildEmptyState(theme, colorScheme, isCompactDensity)
              : (useGrid
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
        maxCrossAxisExtent: isCompact ? 420 : 560,
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
          onDuplicate: () => _handleDuplicateWorkout(index),
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

  Future<void> _handleDuplicateWorkout(int index) async {
    final week = widget.controller.program.weeks[widget.weekIndex];
    final maxOrder = week.workouts.length + 1;
    final Set<int> existingOrders = week.workouts.map((w) => w.order).toSet();
    int suggestedOrder = (week.workouts[index].order + 1).clamp(1, maxOrder);
    while (existingOrders.contains(suggestedOrder) &&
        suggestedOrder < maxOrder) {
      suggestedOrder++;
    }
    if (existingOrders.contains(suggestedOrder)) {
      suggestedOrder = maxOrder;
    }

    final newOrder = await _showDuplicateWorkoutDialog(
      maxOrder: maxOrder,
      suggestedOrder: suggestedOrder,
      existingOrders: existingOrders,
    );

    if (!mounted || newOrder == null) return;

    try {
      widget.controller.duplicateWorkout(widget.weekIndex, index, newOrder);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Allenamento duplicato come Workout $newOrder')),
      );
    } on WorkoutDuplicationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      const errorMessage = 'Errore durante la duplicazione dell\'allenamento';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(errorMessage)));
    }
  }

  Future<int?> _showDuplicateWorkoutDialog({
    required int maxOrder,
    required int suggestedOrder,
    required Set<int> existingOrders,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return _DuplicateWorkoutDialog(
          maxOrder: maxOrder,
          initialOrder: suggestedOrder,
          existingOrders: existingOrders,
        );
      },
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

class _DuplicateWorkoutDialog extends StatefulWidget {
  final int maxOrder;
  final int initialOrder;
  final Set<int> existingOrders;

  const _DuplicateWorkoutDialog({
    required this.maxOrder,
    required this.initialOrder,
    required this.existingOrders,
  });

  @override
  State<_DuplicateWorkoutDialog> createState() =>
      _DuplicateWorkoutDialogState();
}

class _DuplicateWorkoutDialogState extends State<_DuplicateWorkoutDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialOrder.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: const Text('Duplica Allenamento'),
      subtitle: Text(
        'Inserisci il numero del nuovo allenamento (1-${widget.maxOrder}).',
      ),
      actions: [
        AppDialogHelpers.buildCancelButton(context: context),
        AppDialogHelpers.buildActionButton(
          context: context,
          label: 'Duplica',
          onPressed: _confirm,
        ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Numero allenamento',
                helperText: 'Scegli un numero non ancora utilizzato.',
              ),
              validator: _validateOrder,
            ),
          ],
        ),
      ),
    );
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final value = int.parse(_controller.text.trim());
    Navigator.of(context, rootNavigator: true).pop(value);
  }

  String? _validateOrder(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Inserisci un numero valido.';
    }

    final parsed = int.tryParse(trimmed);
    if (parsed == null) {
      return 'Inserisci un numero valido.';
    }

    if (parsed < 1 || parsed > widget.maxOrder) {
      return 'Scegli un valore tra 1 e ${widget.maxOrder}.';
    }

    if (widget.existingOrders.contains(parsed)) {
      return 'Questo numero è già assegnato. Usa un valore diverso.';
    }

    return null;
  }
}

class _WorkoutCardContent extends StatelessWidget {
  final int index;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final bool isCompact;
  final VoidCallback onDuplicate;
  final VoidCallback onCopy;
  final VoidCallback onReorder;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const _WorkoutCardContent({
    required this.index,
    required this.theme,
    required this.colorScheme,
    required this.isCompact,
    required this.onDuplicate,
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
          leadingIcon: const Icon(Icons.copy_all_outlined),
          onPressed: onDuplicate,
          child: const Text('Duplica Allenamento'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.content_copy_outlined),
          onPressed: onCopy,
          child: const Text('Copia in un\'altra settimana'),
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
