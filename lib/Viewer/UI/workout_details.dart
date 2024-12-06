import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/dialog/exercise_dialog.dart';
import 'package:alphanessone/trainingBuilder/dialog/series_dialog.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/providers/providers.dart' as app_providers;
import 'package:alphanessone/Viewer/UI/workout_provider.dart' as workout_provider;
import 'package:alphanessone/Viewer/providers/training_program_provider.dart';
import 'workout_services.dart';

class WorkoutDetails extends ConsumerStatefulWidget {
  final String programId;
  final String userId;
  final String weekId;
  final String workoutId;
  final List<Series>? currentSeriesGroup;

  const WorkoutDetails({
    super.key,
    required this.userId,
    required this.programId,
    required this.weekId,
    required this.workoutId,
    this.currentSeriesGroup,
  });

  @override
  ConsumerState<WorkoutDetails> createState() => _WorkoutDetailsState();
}

class _WorkoutDetailsState extends ConsumerState<WorkoutDetails> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (mounted && !_isInitialized) {
        await ref
            .read(workout_provider.workoutServiceProvider)
            .initializeWorkout(widget.programId, widget.weekId, widget.workoutId);
        _isInitialized = true;
      }
    });
  }

  @override
  void didUpdateWidget(WorkoutDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workoutId != oldWidget.workoutId) {
      _isInitialized = false;
      Future.microtask(() async {
        if (mounted && !_isInitialized) {
          await ref
              .read(workout_provider.workoutServiceProvider)
              .initializeWorkout(widget.programId, widget.weekId, widget.workoutId);
          _isInitialized = true;
        }
      });
    }
  }

  @override
  void dispose() {
    ref.read(workout_provider.workoutServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _showNoteDialog(String exerciseId, String exerciseName,
      [String? existingNote]) async {
    if (!mounted) return;
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
                await ref
                    .read(workout_provider.workoutServiceProvider)
                    .deleteNote(exerciseId, widget.workoutId);
                if (mounted) Navigator.of(context).pop();
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
                await ref
                    .read(workout_provider.workoutServiceProvider)
                    .showNoteDialog(exerciseId, exerciseName, widget.workoutId, note);
              }
              if (mounted) Navigator.of(context).pop();
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

  void _showEditSeriesDialog(Map<String, dynamic> exercise, List<Map<String, dynamic>> series) {
    _showSeriesEditDialog(exercise, series);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(loadingProvider);
    final exercises = ref.watch(workout_provider.exercisesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : exercises.isEmpty
              ? Center(
                  child: Text(
                    'Nessun esercizio trovato',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(AppTheme.spacing.md),
                  itemCount: exercises.length,
                  key: PageStorageKey('workout_exercises_${widget.workoutId}'),
                  itemBuilder: (context, index) =>
                      _buildExerciseCard(exercises[index], context),
                ),
    );
  }

  Widget _buildExerciseCard(
      Map<String, dynamic> exercise, BuildContext context) {
    final superSetId = exercise['superSetId'];
    final exercises = ref.read(workout_provider.exercisesProvider);
    final grouped = ref.read(workout_provider.workoutServiceProvider).groupExercisesBySuperSet(exercises);
    if (superSetId != null) {
      final superSetExercises = grouped[superSetId];
      if (superSetExercises != null && superSetExercises.first == exercise) {
        return _buildSuperSetCard(superSetExercises, context);
      } else {
        return Container();
      }
    } else {
      return _buildSingleExerciseCard(exercise, context);
    }
  }

  Widget _buildSuperSetCard(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allSeriesCompleted = superSetExercises.every((exercise) {
      final series = List<Map<String, dynamic>>.from(exercise['series']);
      return series.every((serie) => ref.read(workout_provider.workoutServiceProvider).isSeriesDone(serie));
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: _buildCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              _buildSuperSetExerciseName(entry.key, entry.value, context)),
          const SizedBox(height: 24),
          if (!allSeriesCompleted) ...[
            _buildSuperSetStartButton(superSetExercises, context),
            const SizedBox(height: 24),
          ],
          _buildSeriesHeaderRow(context),
          ..._buildSeriesRows(superSetExercises, context),
        ],
      ),
    );
  }

  Widget _buildSingleExerciseCard(
      Map<String, dynamic> exercise, BuildContext context) {
    final series = List<Map<String, dynamic>>.from(exercise['series']);
    final firstNotDoneSeriesIndex =
        ref.read(workout_provider.workoutServiceProvider).findFirstNotDoneSeriesIndex(series);
    final isContinueMode = firstNotDoneSeriesIndex > 0;
    final allSeriesCompleted = series.every((serie) => ref.read(workout_provider.workoutServiceProvider).isSeriesDone(serie));
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withOpacity(0.1),
                  ),
                ),
              ),
              child: _buildExerciseName(exercise, context),
            ),
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
                          colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radii.sm),
                    ),
                    child: _buildSeriesHeaderRow(context),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  ..._buildSeriesContainers(series, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  Widget _buildSuperSetExerciseName(
      int index, Map<String, dynamic> exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '${index + 1}. ${exercise['name']} ${exercise['variant'] ?? ''}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
      ),
    );
  }

  Widget _buildSuperSetStartButton(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allSeriesCompleted = superSetExercises.every((exercise) =>
        exercise['series'].every((series) => ref.read(workout_provider.workoutServiceProvider).isSeriesDone(series)));

    if (allSeriesCompleted) return const SizedBox.shrink();

    final firstNotDoneExerciseIndex = superSetExercises.indexWhere((exercise) =>
        exercise['series'].any((series) => !ref.read(workout_provider.workoutServiceProvider).isSeriesDone(series)));

    return GestureDetector(
      onTap: () =>
          _navigateToExerciseDetails(superSetExercises[firstNotDoneExerciseIndex], superSetExercises),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'START',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSeriesHeaderRow(BuildContext context) {
    return Row(
      children: [
        _buildHeaderText('Serie', context, 1),
        _buildHeaderText('Reps', context, 2),
        _buildHeaderText('Kg', context, 2),
        _buildHeaderText('✓', context, 1),
      ],
    );
  }

  Widget _buildHeaderText(String text, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildSeriesRows(
      List<Map<String, dynamic>> superSetExercises, BuildContext context) {
    final maxSeriesCount = superSetExercises
        .map((exercise) => exercise['series'].length)
        .reduce((a, b) => a > b ? a : b);

    return List.generate(maxSeriesCount, (seriesIndex) {
      return Column(
        children: [
          Row(
            children: [
              _buildSeriesIndexText(seriesIndex, context, 1),
              ..._buildSuperSetSeriesColumns(
                  superSetExercises, seriesIndex, context),
            ],
          ),
          if (seriesIndex < maxSeriesCount - 1)
            const Divider(height: 16, thickness: 1),
        ],
      );
    });
  }

  Widget _buildSeriesIndexText(
      int seriesIndex, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Text(
        '${seriesIndex + 1}',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  List<Widget> _buildSuperSetSeriesColumns(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      BuildContext context) {
    return [
      _buildSuperSetSeriesColumn(
          superSetExercises, seriesIndex, 'reps', context, 2),
      _buildSuperSetSeriesColumn(
          superSetExercises, seriesIndex, 'weight', context, 2),
      _buildSuperSetSeriesDoneColumn(
          superSetExercises, seriesIndex, context, 1),
    ];
  }

  Widget _buildSuperSetSeriesColumn(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      String field,
      BuildContext context,
      int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Column(
        children: superSetExercises.map((exercise) {
          final series = exercise['series'].asMap().containsKey(seriesIndex)
              ? exercise['series'][seriesIndex]
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: series != null
                ? GestureDetector(
                    onTap: () =>
                        _showEditSeriesDialog(exercise, [series]),
                    child: Text(
                      _formatSeriesValue(series, field),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : const SizedBox(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSuperSetSeriesDoneColumn(
      List<Map<String, dynamic>> superSetExercises,
      int seriesIndex,
      BuildContext context,
      int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Column(
        children: superSetExercises.map((exercise) {
          final series = exercise['series'].asMap().containsKey(seriesIndex)
              ? exercise['series'][seriesIndex]
              : null;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: series != null
                ? GestureDetector(
                    onTap: () => ref.read(workout_provider.workoutServiceProvider).toggleSeriesDone(series),
                    child: Icon(
                      ref.read(workout_provider.workoutServiceProvider).isSeriesDone(series) ? Icons.check_circle : Icons.cancel,
                      color: ref.read(workout_provider.workoutServiceProvider).isSeriesDone(series)
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  )
                : const SizedBox(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExerciseName(
      Map<String, dynamic> exercise, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final notes = ref.watch(workout_provider.exerciseNotesProvider);
    final hasNote = notes.containsKey(exercise['id']);
    final userRole = ref.watch(app_providers.userRoleProvider);
    final isAdmin = userRole == 'admin';

    return Row(
      children: [
        if (hasNote)
          GestureDetector(
            onTap: () => _showNoteDialog(
              exercise['id'],
              exercise['name'],
              notes[exercise['id']],
            ),
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
            onLongPress: () => _showNoteDialog(
              exercise['id'],
              exercise['name'],
              notes[exercise['id']],
            ),
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
        if (isAdmin)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurfaceVariant,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change',
                child: Text('Cambia esercizio'),
              ),
              const PopupMenuItem(
                value: 'edit_series',
                child: Text('Modifica serie'),
              ),
              const PopupMenuItem(
                value: 'update_max',
                child: Text('Aggiorna Massimale'),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'change':
                  _showChangeExerciseDialog(context, exercise);
                  break;
                case 'edit_series':
                  _showSeriesEditDialog(
                    exercise,
                    List<Map<String, dynamic>>.from(exercise['series'] ?? []),
                  );
                  break;
                case 'update_max':
                  _showUpdateMaxWeightDialog(context, exercise);
                  break;
              }
            },
          )
        else
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change',
                child: Text('Cambia esercizio'),
              ),
              const PopupMenuItem(
                value: 'update_max',
                child: Text('Aggiorna Massimale'),
              ),
            ],
            onSelected: (value) {
              if (value == 'change') {
                _showChangeExerciseDialog(context, exercise);
              } else if (value == 'update_max') {
                _showUpdateMaxWeightDialog(context, exercise);
              }
            },
          ),
      ],
    );
  }

  Future<void> _showUpdateMaxWeightDialog(BuildContext context, Map<String, dynamic> exercise) {
    final weightController = TextEditingController();
    final repsController = TextEditingController(text: "1");
    final calculatedMaxWeight = ValueNotifier<double?>(null);
    final keepWeightSwitch = ValueNotifier<bool>(false);

    void calculateMaxWeight() {
      final weight = double.tryParse(weightController.text);
      final reps = int.tryParse(repsController.text);
      
      if (weight != null && reps != null && reps > 0) {
        calculatedMaxWeight.value = (weight / (1.0278 - 0.0278 * reps)).roundToDouble();
      } else {
        calculatedMaxWeight.value = null;
      }
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aggiorna Massimale'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => calculateMaxWeight(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ripetizioni',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => calculateMaxWeight(),
              ),
              SizedBox(height: 16),
              ValueListenableBuilder<double?>(
                valueListenable: calculatedMaxWeight,
                builder: (context, maxWeight, child) {
                  return maxWeight != null
                      ? Text(
                          'Massimale calcolato (1RM): ${maxWeight.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : SizedBox.shrink();
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Mantieni pesi attuali'),
                  Switch(
                    value: keepWeightSwitch.value,
                    onChanged: (value) {
                      setState(() {
                        keepWeightSwitch.value = value;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              final maxWeight = calculatedMaxWeight.value;
              
              if (maxWeight != null) {
                await ref.read(workout_provider.workoutServiceProvider).updateMaxWeight(
                  exercise,
                  maxWeight,  
                  widget.userId,
                  repetitions: 1,  
                  keepCurrentWeights: keepWeightSwitch.value
                );
                
                Navigator.pop(context);
              }
            },
            child: Text('Salva'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(Map<String, dynamic> exercise,
      int firstNotDoneSeriesIndex, bool isContinueMode, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: () => _navigateToExerciseDetails(
          exercise, [exercise], firstNotDoneSeriesIndex),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
      ),
      child: Text(
        isContinueMode ? 'CONTINUA' : 'INIZIA',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  List<Widget> _buildSeriesContainers(
      List<Map<String, dynamic>> series, BuildContext context) {
    return series.asMap().entries.map((entry) {
      final seriesIndex = entry.key;
      final seriesData = entry.value;

      return GestureDetector(
        onTap: () {
          final exercise = {
            'id': seriesData['exerciseId'],
            'type': seriesData['type'] ?? 'weight',
          };
          _showEditSeriesDialog(exercise, [seriesData]);
        },
        child: Column(
          children: [
            Row(
              children: [
                _buildSeriesIndexText(seriesIndex, context, 1),
                _buildSeriesDataText('reps', seriesData, context, 2),
                _buildSeriesDataText('weight', seriesData, context, 2),
                _buildSeriesDoneIcon(seriesData, context, 1),
              ],
            ),
            if (seriesIndex < series.length - 1)
              const Divider(height: 16, thickness: 1),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSeriesDataText(String field, Map<String, dynamic> seriesData,
      BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            final exercise = {
              'id': seriesData['exerciseId'],
              'type': seriesData['type'] ?? 'weight',
            };
            _showEditSeriesDialog(exercise, [seriesData]);
          },
          child: Text(
            _formatSeriesValue(seriesData, field),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  String _formatSeriesValue(Map<String, dynamic> seriesData, String field) {
    final value = seriesData[field];
    final maxValue = seriesData['max${field.capitalize()}'];
    final valueDone = seriesData['${field}_done'];
    final isDone = ref.read(workout_provider.workoutServiceProvider).isSeriesDone(seriesData);
    final unit = field == 'reps' ? 'R' : 'Kg';

    if (isDone || (valueDone != 0)) {
      return '$valueDone$unit';
    }

    String text = maxValue != null && maxValue != value
        ? '$value-$maxValue$unit'
        : '$value$unit';

    return text;
  }

  Widget _buildSeriesDoneIcon(
      Map<String, dynamic> seriesData, BuildContext context, int flex) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      flex: flex,
      child: Container(
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => ref.read(workout_provider.workoutServiceProvider).toggleSeriesDone(seriesData),
          child: Icon(
            ref.read(workout_provider.workoutServiceProvider).isSeriesDone(seriesData) ? Icons.check_circle : Icons.cancel,
            color: ref.read(workout_provider.workoutServiceProvider).isSeriesDone(seriesData)
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _navigateToExerciseDetails(
      Map<String, dynamic> exercise, List<Map<String, dynamic>> exercises,
      [int startIndex = 0]) {
    if (!mounted) return;

    final extra = {
      'programId': widget.programId,
      'weekId': widget.weekId,
      'workoutId': widget.workoutId,
      'exerciseId': exercise['id'],
      'userId': widget.userId,
      'superSetExercises': exercises,
      'superSetExerciseIndex':
          exercises.indexWhere((e) => e['id'] == exercise['id']),
      'seriesList': exercise['series'],
      'startIndex': startIndex
    };

    context.pushNamed('exercise_details', extra: extra);
  }

  void _showChangeExerciseDialog(
      BuildContext context, Map<String, dynamic> currentExercise) {
    final exerciseRecordService = ref.read(app_providers.exerciseRecordServiceProvider);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => ExerciseDialog(
        exerciseRecordService: exerciseRecordService,
        athleteId: widget.userId,
        exercise: Exercise(
          id: currentExercise['id'] ?? '',
          exerciseId: currentExercise['exerciseId'] ?? '',
          name: currentExercise['name'] ?? '',
          type: currentExercise['type'] ?? '',
          variant: currentExercise['variant'] ?? '',
          order: currentExercise['order'] ?? 0,
          series: [],
          weekProgressions: [],
        ),
      ),
    ).then((newExercise) async {
      if (newExercise != null) {
        await ref.read(workout_provider.workoutServiceProvider).updateExercise(currentExercise, newExercise as Exercise);
      }
    });
  }

  void _showSeriesEditDialog(
      Map<String, dynamic> exercise, List<Map<String, dynamic>> series) async {
    final List<Series> seriesList =
        series.map((s) => Series.fromMap(s)).toList();
    final originalExerciseId = seriesList.first.originalExerciseId ?? exercise['id'];

    final recordsStream = ref.read(app_providers.exerciseRecordServiceProvider)
        .getExerciseRecords(
          userId: widget.userId,
          exerciseId: originalExerciseId,
        )
        .map((records) => records.isNotEmpty
            ? records.reduce((a, b) => a.date.compareTo(b.date) > 0 ? a : b)
            : null);

    final latestRecord = await recordsStream.first;
    num latestMaxWeight = latestRecord?.maxWeight ?? 0.0;

    final colorScheme = Theme.of(context).colorScheme;

    final weightNotifier = ref.read(workout_provider.workoutServiceProvider).getWeightNotifier(exercise['id']) ??
        ValueNotifier<double>(0.0);

    final result = await showDialog<List<Series>>(
      context: context,
      builder: (context) => SeriesDialog(
        exerciseRecordService: ref.read(app_providers.exerciseRecordServiceProvider),
        athleteId: widget.userId,
        exerciseId: exercise['id'],
        exerciseType: exercise['type'] ?? 'weight',
        weekIndex: 0,
        exercise: Exercise.fromMap(exercise),
        currentSeriesGroup: seriesList,
        latestMaxWeight: latestMaxWeight.toDouble(),
        weightNotifier: weightNotifier,
      ),
    );

    if (result != null && mounted) {
      try {
        await ref.read(workout_provider.workoutServiceProvider).applySeriesChanges(exercise, result);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio delle modifiche: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }
}
