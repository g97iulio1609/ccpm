import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/viewer/presentation/notifiers/workout_details_notifier.dart';
import 'package:alphanessone/viewer/presentation/widgets/exercise_timer_bottom_sheet.dart';

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
  @override
  Widget build(BuildContext context) {
    // Osserviamo lo stato dal WorkoutDetailsNotifier
    final state = ref.watch(workoutDetailsNotifierProvider(widget.workoutId));
    final notifier =
        ref.read(workoutDetailsNotifierProvider(widget.workoutId).notifier);

    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isListMode = screenWidth < 600;

    // Determina il numero di colonne in base alla larghezza dello schermo
    final crossAxisCount = isListMode ? 1 : 2;
    final padding = AppTheme.spacing.md;
    final spacing = AppTheme.spacing.md;

    // Se è in caricamento, mostra un indicatore di progresso
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
              ),
              SizedBox(height: AppTheme.spacing.md),
              Text(
                'Caricamento esercizi...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Se c'è un errore, mostralo
    if (state.error != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
                size: 48,
              ),
              SizedBox(height: AppTheme.spacing.md),
              Text(
                'Errore durante il caricamento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
              SizedBox(height: AppTheme.spacing.sm),
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacing.lg),
              FilledButton.icon(
                onPressed: () => notifier.refreshWorkout(),
                icon: const Icon(Icons.refresh),
                label: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    // Se non ci sono esercizi, mostra un messaggio
    if (state.workout == null || state.workout!.exercises.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 48,
              ),
              SizedBox(height: AppTheme.spacing.md),
              Text(
                'Nessun esercizio trovato',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Raggruppa gli esercizi per superSet
    final exercises = state.workout!.exercises;
    final groupedExercises = _groupExercisesBySuperSet(exercises);

    // Mostra gli esercizi in una lista o griglia
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          state.workout!.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refreshWorkout(),
            tooltip: 'Aggiorna',
          ),
        ],
      ),
      body: isListMode
          ? ListView.builder(
              padding: EdgeInsets.all(padding),
              itemCount: groupedExercises.length,
              itemBuilder: (context, index) {
                final entry = groupedExercises.entries.elementAt(index);
                final superSetId = entry.key;
                final exercises = entry.value;

                return Padding(
                  padding: EdgeInsets.only(bottom: spacing),
                  child: superSetId == null || superSetId.isEmpty
                      ? _buildSingleExerciseCard(exercises.first, context)
                      : _buildSuperSetCard(exercises, context),
                );
              },
            )
          : GridView.builder(
              padding: EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 1.2,
              ),
              itemCount: groupedExercises.length,
              key: PageStorageKey('workout_exercises_${widget.workoutId}'),
              itemBuilder: (context, index) {
                final entry = groupedExercises.entries.elementAt(index);
                final superSetId = entry.key;
                final exercises = entry.value;

                return superSetId == null || superSetId.isEmpty
                    ? _buildSingleExerciseCard(exercises.first, context)
                    : _buildSuperSetCard(exercises, context);
              },
            ),
    );
  }

  // Raggruppa gli esercizi per superSet
  Map<String?, List<Exercise>> _groupExercisesBySuperSet(
      List<Exercise> exercises) {
    final groupedExercises = <String?, List<Exercise>>{};

    for (final exercise in exercises) {
      final superSetId = exercise.superSetId;

      if (superSetId != null && superSetId.isNotEmpty) {
        (groupedExercises[superSetId] ??= []).add(exercise);
      } else {
        groupedExercises[null] ??= [];
        groupedExercises[null]!.add(exercise);
      }
    }

    // Per gli esercizi normali, vogliamo una entry per esercizio
    final result = <String?, List<Exercise>>{};

    groupedExercises.forEach((superSetId, exercises) {
      if (superSetId == null || superSetId.isEmpty) {
        for (final exercise in exercises) {
          result[exercise.id] = [exercise];
        }
      } else {
        result[superSetId] = exercises;
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

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
          width: 1,
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(77),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withAlpha(26),
                  ),
                ),
              ),
              child: _buildExerciseName(exercise, context),
            ),
            if (isListMode)
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!allSeriesCompleted) ...[
                      _buildStartButton(exercise, firstNotDoneSeriesIndex,
                          isContinueMode, context),
                      SizedBox(height: AppTheme.spacing.md),
                    ],
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: AppTheme.spacing.xs,
                        horizontal: AppTheme.spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.surfaceContainerHighest.withAlpha(77),
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
                        if (!allSeriesCompleted) ...[
                          _buildStartButton(exercise, firstNotDoneSeriesIndex,
                              isContinueMode, context),
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
                            borderRadius:
                                BorderRadius.circular(AppTheme.radii.sm),
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
      ),
    );
  }

  Widget _buildExerciseName(Exercise exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier =
        ref.read(workoutDetailsNotifierProvider(widget.workoutId).notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              if (exercise.variant != null && exercise.variant!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  exercise.variant!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.note_alt_outlined,
            color: exercise.note != null && exercise.note!.isNotEmpty
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          onPressed: () => _showNoteDialog(
                exercise.id ?? '', exercise.name, exercise.note, notifier),
          tooltip: 'Nota',
        ),
      ],
    );
  }

  Widget _buildSuperSetCard(
      List<Exercise> superSetExercises, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allSeriesCompleted = superSetExercises.every((exercise) {
      return exercise.series.every((series) => series.isCompleted);
    });

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
          width: 1,
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(77),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withAlpha(26),
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Super Set',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...superSetExercises.asMap().entries.map((entry) =>
                    _buildSuperSetExerciseName(
                        entry.key, entry.value, context)),
              ],
            ),
          ),
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
                    _buildSeriesHeaderRow(context),
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
      int index, Exercise exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier =
        ref.read(workoutDetailsNotifierProvider(widget.workoutId).notifier);

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
          IconButton(
            icon: Icon(
              Icons.note_alt_outlined,
              size: 20,
              color: exercise.note != null && exercise.note!.isNotEmpty
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _showNoteDialog(
                exercise.id ?? '', exercise.name, exercise.note, notifier),
            tooltip: 'Nota',
          ),
        ],
      ),
    );
  }

  Future<void> _showNoteDialog(String exerciseId, String exerciseName,
      String? existingNote, WorkoutDetailsNotifier notifier) async {
    final TextEditingController noteController =
        TextEditingController(text: existingNote);
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Note per $exerciseName',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
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
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '#',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Reps',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Peso',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Fatti',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(width: 40), // Space for checkmark
      ],
    );
  }

  List<Widget> _buildSeriesContainers(
      List<Series> seriesList, BuildContext context) {
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
              ? Colors.green.withAlpha(26)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radii.sm),
        ),
        child: _buildSeriesRow(index, series, context),
      );
    }).toList();
  }

  List<Widget> _buildSeriesRows(
      List<Exercise> exercises, BuildContext context) {
    final rows = <Widget>[];

    // Assumiamo che ogni esercizio nel superset abbia lo stesso numero di serie
    final seriesCount = exercises.first.series.length;

    for (var i = 0; i < seriesCount; i++) {
      for (var j = 0; j < exercises.length; j++) {
        final exercise = exercises[j];
        final series = exercise.series[i];

        rows.add(
          Container(
            margin: EdgeInsets.only(bottom: AppTheme.spacing.xs),
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.xs,
              horizontal: AppTheme.spacing.sm,
            ),
            decoration: BoxDecoration(
              color: series.isCompleted
                  ? Colors.green.withAlpha(26)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${i + 1}${String.fromCharCode(65 + j)}', // 1A, 1B, 2A, 2B, etc.
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${series.reps}',
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${series.weight} kg',
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    series.isCompleted
                        ? '${series.repsDone}×${series.weightDone}'
                        : '-',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              series.isCompleted ? FontWeight.bold : null,
                        ),
                  ),
                ),
                _buildCompletionButton(series, exercise.name, context),
              ],
            ),
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildSeriesRow(int index, Series series, BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '${index + 1}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${series.reps}',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${series.weight} kg',
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            series.isCompleted
                ? '${series.repsDone}×${series.weightDone}'
                : '-',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: series.isCompleted ? FontWeight.bold : null,
                ),
          ),
        ),
        _buildCompletionButton(series, "", context),
      ],
    );
  }

  Widget _buildCompletionButton(
      Series series, String exerciseName, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier =
        ref.read(workoutDetailsNotifierProvider(widget.workoutId).notifier);

    return SizedBox(
      width: 40,
      child: IconButton(
        icon: Icon(
          series.isCompleted
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color:
              series.isCompleted ? Colors.green : colorScheme.onSurfaceVariant,
          size: 24,
        ),
        onPressed: () {
          if (series.isCompleted) {
            // Se già completata, chiedi conferma per marcarla come non fatta
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Conferma'),
                content: const Text(
                    'Vuoi segnare questa serie come non completata?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annulla'),
                  ),
                  FilledButton(
                    onPressed: () {
                      notifier.completeSeries(series.id, false, 0, 0);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Conferma'),
                  ),
                ],
              ),
            );
          } else {
            // Se non completata, mostra il timer per completarla
            ExerciseTimerBottomSheet.show(
              context: context,
              userId: widget.userId,
              exerciseId: series.exerciseId,
              workoutId: widget.workoutId,
              exerciseName: exerciseName.isNotEmpty
                  ? exerciseName
                  : "Serie ${series.order}",
              onSeriesComplete: (repsDone, weightDone) {
                notifier.completeSeries(series.id, true, repsDone, weightDone);
                Navigator.of(context).pop();
              },
              initialTimerSeconds: series.restTimeSeconds ?? 60,
              reps: series.reps,
              weight: series.weight,
            );
          }
        },
      ),
    );
  }

  Widget _buildStartButton(Exercise exercise, int startIndex,
      bool isContinueMode, BuildContext context) {
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
                workoutDetailsNotifierProvider(widget.workoutId).notifier);
            notifier.completeSeries(series.id, true, repsDone, weightDone);
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
      List<Exercise> exercises, BuildContext context) {
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

    final isContinueMode =
        exercises.any((e) => e.series.any((s) => s.isCompleted));

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
                workoutDetailsNotifierProvider(widget.workoutId).notifier);
            notifier.completeSeries(series.id, true, repsDone, weightDone);
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
}
