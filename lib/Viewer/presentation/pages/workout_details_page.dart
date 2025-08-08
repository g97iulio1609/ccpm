import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/Viewer/presentation/notifiers/workout_details_notifier.dart';
import 'package:alphanessone/UI/components/skeleton.dart';
import 'package:alphanessone/UI/components/app_card.dart';
import 'package:alphanessone/UI/components/section_header.dart';
import 'package:alphanessone/Viewer/presentation/widgets/exercise_timer_bottom_sheet.dart';
import 'package:alphanessone/UI/components/series_header.dart';
import 'package:alphanessone/shared/widgets/page_scaffold.dart';
import 'package:alphanessone/shared/widgets/empty_state.dart';
import 'package:alphanessone/Viewer/UI/widgets/workout_dialogs.dart';

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
  bool _compactLayout = false;
  @override
  Widget build(BuildContext context) {
    // Osserviamo lo stato dal WorkoutDetailsNotifier
    final state = ref.watch(workoutDetailsNotifierProvider(widget.workoutId));
    final notifier = ref.read(
      workoutDetailsNotifierProvider(widget.workoutId).notifier,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    // Forza la modalità lista praticamente sempre per stabilizzare il rendering
    final isListMode = screenWidth < 10000;

    // Deprecated: calcolo colonne non più usato (si usa maxCrossAxisExtent)
    final padding = AppTheme.spacing.md;
    final spacing = AppTheme.spacing.md;
    // Griglia moderna: usa maxCrossAxisExtent + mainAxisExtent (Flutter 3.10+)
    final maxCrossAxisExtent = screenWidth >= 1600
        ? 420.0
        : screenWidth >= 1200
        ? 380.0
        : screenWidth >= 900
        ? 340.0
        : 320.0;
    final mainAxisExtent = screenWidth >= 1600
        ? 460.0
        : screenWidth >= 1200
        ? 500.0
        : 540.0;

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
    final groupedExercises = _groupExercisesBySuperSet(exercises);

    // Mostra gli esercizi in una lista o griglia
    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: isListMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _compactLayout = !_compactLayout),
              icon: Icon(
                _compactLayout ? Icons.unfold_more : Icons.unfold_less,
              ),
              label: Text(_compactLayout ? 'Estesa' : 'Compatta'),
              tooltip: 'Cambia densità card',
            ),
      body: isListMode
          ? RefreshIndicator(
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
                          ? _buildSingleExerciseCard(exercises.first, context)
                          : _buildSuperSetCard(
                              superSetExercises: exercises,
                              context: context,
                              isListMode: true,
                            ),
                    );
                  },
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => notifier.refreshWorkout(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: GridView.builder(
                  key: ValueKey<bool>(_compactLayout),
                  padding: EdgeInsets.all(padding),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: maxCrossAxisExtent,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: mainAxisExtent,
                  ),
                  itemCount: groupedExercises.length,
                  itemBuilder: (context, index) {
                    final entry = groupedExercises.entries.elementAt(index);
                    final exercises = entry.value;

                    return Semantics(
                      container: true,
                      label: 'Scheda esercizio',
                      child: exercises.length == 1
                          ? _buildSingleExerciseCard(exercises.first, context)
                          : _buildSuperSetCard(
                              superSetExercises: exercises,
                              context: context,
                              isListMode: false,
                            ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  // Raggruppa gli esercizi per superSet
  Map<String?, List<Exercise>> _groupExercisesBySuperSet(
    List<Exercise> exercises,
  ) {
    // 1) Raggruppa per superSetId
    final Map<String?, List<Exercise>> temp = {};
    for (final exercise in exercises) {
      final superSetId = exercise.superSetId;
      (temp[superSetId] ??= <Exercise>[]).add(exercise);
    }

    // 2) Solo i gruppi con almeno 2 elementi restano "superset".
    //    Gli altri tornano ad essere esercizi singoli.
    final Map<String?, List<Exercise>> result = {};
    temp.forEach((superSetId, group) {
      if (superSetId == null || superSetId.isEmpty || group.length < 2) {
        for (final ex in group) {
          result[ex.id] = [ex];
        }
      } else {
        // Ordina per ordine definito nell'esercizio per coerenza
        group.sort((a, b) => a.order.compareTo(b.order));
        result[superSetId] = group;
      }
    });

    return result;
  }

  Widget _buildSingleExerciseCard(Exercise exercise, BuildContext context) {
    final series = exercise.series;
    final firstNotDoneSeriesIndex = _findFirstNotDoneSeriesIndex(series);
    final isContinueMode = firstNotDoneSeriesIndex > 0;
    final allSeriesCompleted = series.every((serie) => serie.isCompleted);
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isListMode = screenWidth < 600;

    return AppCard(
    header: _buildExerciseName(exercise, context),
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
          // Meta info: set, target, rest
          _buildExerciseMetaChips(exercise, context),
          SizedBox(height: AppTheme.spacing.sm),
          _buildExerciseProgress(series, context),
          SizedBox(height: AppTheme.spacing.md),
                  if (!allSeriesCompleted) ...[
                    _buildStartButton(
                      exercise,
                      firstNotDoneSeriesIndex,
                      isContinueMode,
                      context,
                    ),
                    SizedBox(height: AppTheme.spacing.md),
                  ],
                  SectionHeader(title: 'Serie'),
                  SizedBox(height: AppTheme.spacing.sm),
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: AppTheme.spacing.xs,
                      horizontal: AppTheme.spacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(77),
                      borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                    ),
                    child: _buildSeriesHeaderRow(context),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  ..._buildSeriesContainers(series, context),
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
            _buildExerciseMetaChips(exercise, context),
            SizedBox(height: AppTheme.spacing.sm),
            _buildExerciseProgress(series, context),
            SizedBox(height: AppTheme.spacing.md),
                      if (!allSeriesCompleted) ...[
                        _buildStartButton(
                          exercise,
                          firstNotDoneSeriesIndex,
                          isContinueMode,
                          context,
                        ),
                        SizedBox(height: AppTheme.spacing.md),
                      ],
                      SectionHeader(title: 'Serie'),
                      SizedBox(height: AppTheme.spacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: AppTheme.spacing.xs,
                          horizontal: AppTheme.spacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withAlpha(
                            77,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radii.sm,
                          ),
                        ),
                        child: _buildSeriesHeaderRow(context),
                      ),
                      SizedBox(height: AppTheme.spacing.sm),
                      ..._buildSeriesContainers(series, context),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseName(Exercise exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(
      workoutDetailsNotifierProvider(widget.workoutId).notifier,
    );

    return SectionHeader(
      title: exercise.name,
      subtitle: (exercise.variant != null && exercise.variant!.isNotEmpty)
          ? exercise.variant!
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Aggiungi o modifica nota esercizio',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.note_alt_outlined,
                color: exercise.note != null && exercise.note!.isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _showNoteDialog(
                exercise.id ?? '',
                exercise.name,
                exercise.note,
                notifier,
              ),
              tooltip: 'Nota',
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Azioni esercizio',
            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
            onSelected: (value) async {
              if (value == 'change') {
                WorkoutDialogs.showChangeExerciseDialog(
                  context,
                  ref,
                  exercise.toMap(),
                  widget.userId,
                );
              } else if (value == 'edit_series') {
                WorkoutDialogs.showSeriesEditDialog(
                  context,
                  ref,
                  exercise.toMap(),
                  exercise.series.map((s) => s.toMap()).toList(),
                  widget.userId,
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'change',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Cambia esercizio'),
                ),
              ),
              const PopupMenuItem(
                value: 'edit_series',
                child: ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('Modifica serie…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
                ...superSetExercises.asMap().entries.map(
                  (entry) => _buildSuperSetExerciseName(
                    entry.key,
                    entry.value,
                    context,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: AppTheme.spacing.sm),
                  child: _buildProgressBar(
                    doneSeries,
                    totalSeries,
                    context,
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
                    _buildSuperSetStartButton(superSetExercises, context),
                    const SizedBox(height: 24),
                  ],
          _buildSuperSetHeaderRow(superSetExercises, context),
                  ..._buildSeriesRows(superSetExercises, context),
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
                        _buildSuperSetStartButton(superSetExercises, context),
                        const SizedBox(height: 24),
                      ],
            _buildSuperSetHeaderRow(superSetExercises, context),
                      ..._buildSeriesRows(superSetExercises, context),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuperSetExerciseName(
    int index,
    Exercise exercise,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(
      workoutDetailsNotifierProvider(widget.workoutId).notifier,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Semantics(
            label: 'Aggiungi o modifica nota esercizio del superset',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.note_alt_outlined,
                size: 20,
                color: exercise.note != null && exercise.note!.isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: () => _showNoteDialog(
                exercise.id ?? '',
                exercise.name,
                exercise.note,
                notifier,
              ),
              tooltip: 'Nota',
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Azioni',
            icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurfaceVariant),
            onSelected: (value) async {
              if (value == 'change') {
                WorkoutDialogs.showChangeExerciseDialog(
                  context,
                  ref,
                  exercise.toMap(),
                  widget.userId,
                );
              } else if (value == 'edit_series') {
                WorkoutDialogs.showSeriesEditDialog(
                  context,
                  ref,
                  exercise.toMap(),
                  exercise.series.map((s) => s.toMap()).toList(),
                  widget.userId,
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'change',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Cambia esercizio'),
                ),
              ),
              PopupMenuItem(
                value: 'edit_series',
                child: ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('Modifica serie…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNoteDialog(
    String exerciseId,
    String exerciseName,
    String? existingNote,
    WorkoutDetailsNotifier notifier,
  ) async {
    final TextEditingController noteController = TextEditingController(
      text: existingNote,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Note per $exerciseName',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Inserisci una nota...',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          if (existingNote != null)
            TextButton(
              onPressed: () async {
                await notifier.deleteExerciseNote(exerciseId);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(
                'Elimina',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annulla',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final note = noteController.text.trim();
              if (note.isNotEmpty) {
                await notifier.saveExerciseNote(exerciseId, note);
              }
              if (context.mounted) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
            child: Text(
              'Salva',
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesHeaderRow(BuildContext context) {
    return const SeriesHeader();
  }

  List<Widget> _buildSeriesContainers(
    List<Series> seriesList,
    BuildContext context,
  ) {
    return seriesList.asMap().entries.map((entry) {
      final index = entry.key;
      final series = entry.value;

      return Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacing.xs),
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacing.xs,
          horizontal: AppTheme.spacing.sm,
        ),
        decoration: BoxDecoration(
      color: series.isCompleted
        ? Theme.of(context)
          .colorScheme
          .primaryContainer
          .withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radii.sm),
          border: Border.all(
      color: Theme.of(context)
        .colorScheme
        .outlineVariant
        .withValues(alpha: series.isCompleted ? 0 : 0.3),
          ),
        ),
        child: _buildSeriesRow(index, series, context),
      );
    }).toList();
  }

  List<Widget> _buildSeriesRows(
    List<Exercise> exercises,
    BuildContext context,
  ) {
    // Modello a colonne per evitare sovrapposizioni: una colonna per ogni esercizio del superset
    final maxSeries = exercises
        .map((e) => e.series.length)
        .fold<int>(0, (p, c) => c > p ? c : p);

    return List<Widget>.generate(maxSeries, (rowIndex) {
      return Container(
        margin: EdgeInsets.only(bottom: AppTheme.spacing.xs),
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacing.xs,
          horizontal: AppTheme.spacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radii.sm),
          color: Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '${rowIndex + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            ...exercises.asMap().entries.map((entry) {
              final exIndex = entry.key;
              final exercise = entry.value;
              final hasSeries = rowIndex < exercise.series.length;
              final series = hasSeries ? exercise.series[rowIndex] : null;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: exIndex == 0 ? 0 : AppTheme.spacing.xs,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: AppTheme.spacing.xs,
                    horizontal: AppTheme.spacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: series?.isCompleted == true
                        ? Colors.green.withAlpha(26)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                  ),
                  child: hasSeries
                      ? Builder(
                          builder: (context) {
                            final s = series!;
                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    String.fromCharCode(65 + exIndex),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _showSeriesExecutionDialog(
                                      context,
                                      s,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        '${s.reps}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _showSeriesExecutionDialog(
                                      context,
                                      s,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        '${s.weight} kg',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(6),
                                    onTap: () => _showSeriesExecutionDialog(
                                      context,
                                      s,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        s.isCompleted
                                            ? '${s.repsDone}×${s.weightDone}'
                                            : '-',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: s.isCompleted
                                                  ? FontWeight.bold
                                                  : null,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildCompletionButton(
                                  s,
                                  exercise.name,
                                  context,
                                ),
                              ],
                            );
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSeriesRow(int index, Series series, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final done = series.isCompleted;
    return Row(
      children: [
        // Index badge
        SizedBox(
          width: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
        color: done
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: done
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Target reps
        Expanded(
          flex: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showSeriesExecutionDialog(context, series),
            child: _pill(
              context,
              label: '${series.reps}',
              icon: Icons.repeat,
              filled: false,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Target weight
        Expanded(
          flex: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showSeriesExecutionDialog(context, series),
            child: _pill(
              context,
              label: _formatWeight(series.weight),
              icon: Icons.fitness_center,
              filled: false,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Done summary
        Expanded(
          flex: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showSeriesExecutionDialog(context, series),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                done ? '${series.repsDone}×${series.weightDone}' : '-',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                      color: done
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ),
        // Actions
        Row(
          children: [
            _buildCompletionButton(series, "", context),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionButton(
    Series series,
    String exerciseName,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(
      workoutDetailsNotifierProvider(widget.workoutId).notifier,
    );

    return SizedBox(
      width: 40,
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
          child: Icon(
            series.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_outlined,
            key: ValueKey<bool>(series.isCompleted),
            color: series.isCompleted
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        onPressed: () {
          if (series.isCompleted) {
            // Se già completata, chiedi conferma per marcarla come non fatta
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Conferma'),
                content: const Text(
                  'Vuoi segnare questa serie come non completata?',
                ),
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
            // Segna direttamente come completata usando i target come valori fatti
            notifier.completeSeries(
              series.id ?? '',
              true,
              series.reps,
              series.weight,
            );
          }
        },
      ),
    );
  }

  Widget _buildStartButton(
    Exercise exercise,
    int startIndex,
    bool isContinueMode,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: () {
        final series = exercise.series[startIndex];

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
            notifier.completeSeries(
              series.id ?? '',
              true,
              repsDone,
              weightDone,
            );
            Navigator.of(context).pop();
          },
          initialTimerSeconds: series.restTimeSeconds ?? 60,
          reps: series.reps,
          weight: series.weight,
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
      ),
      icon: Icon(
        isContinueMode ? Icons.play_arrow : Icons.fitness_center,
        color: colorScheme.onPrimary,
      ),
      label: Text(
        isContinueMode
            ? 'Continua (Serie ${startIndex + 1})'
            : 'Inizia Allenamento',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSuperSetStartButton(
    List<Exercise> exercises,
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Trova il primo esercizio e serie non completati
    Exercise? firstExercise;
    int startSeriesIndex = 0;

    for (final exercise in exercises) {
      for (int i = 0; i < exercise.series.length; i++) {
        if (!exercise.series[i].isCompleted) {
          firstExercise = exercise;
          startSeriesIndex = i;
          break;
        }
      }
      if (firstExercise != null) break;
    }

    if (firstExercise == null) return const SizedBox.shrink();

    final isContinueMode = exercises.any(
      (e) => e.series.any((s) => s.isCompleted),
    );

    return FilledButton.icon(
      onPressed: () {
        final series = firstExercise!.series[startSeriesIndex];

        ExerciseTimerBottomSheet.show(
          context: context,
          userId: widget.userId,
          exerciseId: firstExercise.id ?? '',
          workoutId: widget.workoutId,
          exerciseName: firstExercise.name,
          onSeriesComplete: (repsDone, weightDone) {
            final notifier = ref.read(
              workoutDetailsNotifierProvider(widget.workoutId).notifier,
            );
            notifier.completeSeries(
              series.id ?? '',
              true,
              repsDone,
              weightDone,
            );
            Navigator.of(context).pop();
          },
          initialTimerSeconds: series.restTimeSeconds ?? 60,
          reps: series.reps,
          weight: series.weight,
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
      ),
      icon: Icon(
        isContinueMode ? Icons.play_arrow : Icons.fitness_center,
        color: colorScheme.onPrimary,
      ),
      label: Text(
        isContinueMode
            ? 'Continua Super Set (Serie ${startSeriesIndex + 1})'
            : 'Inizia Super Set',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Metodi di utilità
  int _findFirstNotDoneSeriesIndex(List<Series> series) {
    for (int i = 0; i < series.length; i++) {
      if (!series[i].isCompleted) {
        return i;
      }
    }
    return 0; // Se tutte le serie sono completate, restituisci 0
  }

  // ================= UI helpers migliorati =================
  Widget _buildExerciseMetaChips(Exercise exercise, BuildContext context) {
    final reps = exercise.series.isNotEmpty ? exercise.series.first.reps : null;
    final weight = exercise.series.isNotEmpty ? exercise.series.first.weight : null;
    final rest = exercise.series
        .firstWhere((s) => s.restTimeSeconds != null, orElse: () => exercise.series.first)
        .restTimeSeconds;

    return Wrap(
      spacing: AppTheme.spacing.xs,
      runSpacing: AppTheme.spacing.xs,
      children: [
        _chip(context, Icons.layers_outlined, '${exercise.series.length} serie'),
        if (reps != null) _chip(context, Icons.repeat, 'x$reps'),
        if (weight != null) _chip(context, Icons.fitness_center, _formatWeight(weight)),
  if (rest != null) _chip(context, Icons.timer_outlined, _formatRest(rest)),
      ],
    );
  }

  Widget _buildExerciseProgress(List<Series> series, BuildContext context) {
    final total = series.length;
    final done = series.where((s) => s.isCompleted).length;
    return _buildProgressBar(
      done,
      total,
      context,
      labelBuilder: (pct) => '${(pct * 100).round()}% • $done/$total serie',
    );
  }

  Widget _buildProgressBar(
    int done,
    int total,
    BuildContext context, {
    String Function(double pct)? labelBuilder,
  }) {
    final pct = total == 0 ? 0.0 : done / total;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct.clamp(0, 1),
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Text(
          labelBuilder?.call(pct) ?? '${(pct * 100).round()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required IconData icon,
    bool filled = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: filled ? cs.onPrimaryContainer : cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeight(dynamic weight) {
    if (weight == null) return '-';
    if (weight is int || weight is double) {
      final num w = weight as num;
      final str = (w % 1 == 0) ? w.toInt().toString() : w.toStringAsFixed(1);
      return '$str kg';
    }
    return '$weight kg';
  }

  String _formatRest(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m > 0) {
      return '${m}m${s.toString().padLeft(2, '0')}s';
    }
    return '${s}s';
  }

  // Header per tabelle di superset: # + per ogni esercizio (lettera, reps, peso, fatti) + azione
  Widget _buildSuperSetHeaderRow(
    List<Exercise> exercises,
    BuildContext context,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTheme.spacing.xs,
        horizontal: AppTheme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...exercises.asMap().entries.map((entry) {
            final exIndex = entry.key;
            return Expanded(
              child: Row(
                children: [
                  if (exIndex != 0) SizedBox(width: AppTheme.spacing.xs),
                  // manteniamo lo stesso numero di colonne delle righe
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ID',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Reps',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Peso',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Fatti',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        SizedBox(width: 40), // spazio azione (match IconButton)
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _showSeriesExecutionDialog(
    BuildContext context,
    Series series,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final repsController = TextEditingController(
      text: (series.repsDone > 0 ? series.repsDone : series.reps).toString(),
    );
    final weightController = TextEditingController(
      text: (series.weightDone > 0 ? series.weightDone : series.weight)
          .toString(),
    );

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Segna serie',
          style: Theme.of(ctx)
              .textTheme
              .titleLarge
              ?.copyWith(color: colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: repsController,
              keyboardType: const TextInputType.numberWithOptions(),
              decoration: const InputDecoration(labelText: 'Reps fatte'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Peso fatto (kg)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Annulla', style: TextStyle(color: colorScheme.primary)),
          ),
          FilledButton(
            onPressed: () async {
              final repsDone = int.tryParse(repsController.text.trim()) ?? 0;
              final weightDone =
                  double.tryParse(weightController.text.trim()) ?? 0.0;

              final notifier = ref.read(
                workoutDetailsNotifierProvider(widget.workoutId).notifier,
              );
              await notifier.completeSeries(
                series.id ?? '',
                true,
                repsDone,
                weightDone,
              );
              if (context.mounted) Navigator.of(ctx).pop();
            },
            style:
                FilledButton.styleFrom(backgroundColor: colorScheme.primary),
            child: Text('Salva', style: TextStyle(color: colorScheme.onPrimary)),
          ),
        ],
      ),
    );
  }
}
