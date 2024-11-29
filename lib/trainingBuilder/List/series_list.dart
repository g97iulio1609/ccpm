import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/superseries_model.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../controller/training_program_controller.dart';
import '../dialog/reorder_dialog.dart';
import '../series_utils.dart';
import '../dialog/series_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/UI/components/weight_input_fields.dart';
import 'package:alphanessone/UI/components/series_input_fields.dart';

final expansionStateProvider = StateNotifierProvider.autoDispose<
    ExpansionStateNotifier, Map<String, bool>>((ref) {
  return ExpansionStateNotifier();
});

class ExpansionStateNotifier extends StateNotifier<Map<String, bool>> {
  ExpansionStateNotifier() : super({});

  void toggleExpansionState(String key) {
    final currentState = state[key] ?? false;
    state = {
      ...state,
      key: !currentState,
    };
  }
}

class TrainingProgramSeriesList extends ConsumerStatefulWidget {
  final TrainingProgramController controller;
  final ExerciseRecordService exerciseRecordService;
  final int weekIndex;
  final int workoutIndex;
  final int exerciseIndex;
  final String exerciseType;

  const TrainingProgramSeriesList({
    required this.controller,
    required this.exerciseRecordService,
    required this.weekIndex,
    required this.workoutIndex,
    required this.exerciseIndex,
    required this.exerciseType,
    super.key,
  });

  @override
  TrainingProgramSeriesListState createState() =>
      TrainingProgramSeriesListState();
}

class TrainingProgramSeriesListState
    extends ConsumerState<TrainingProgramSeriesList> {
  late num latestMaxWeight;

  @override
  void initState() {
    super.initState();
    _fetchLatestMaxWeight();
  }

  Future<void> _fetchLatestMaxWeight() async {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];
    final exerciseId = exercise.exerciseId;
    final athleteId = widget.controller.program.athleteId;

    latestMaxWeight = await SeriesUtils.getLatestMaxWeight(
      widget.exerciseRecordService,
      athleteId,
      exerciseId ?? '',
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.exerciseIndex >= workout.exercises.length) {
      return Text(
        'Invalid exercise index',
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.error,
        ),
      );
    }

    final exercise = workout.exercises[widget.exerciseIndex];
    final groupedSeries = _groupSeries(exercise.series);
    final expansionState = ref.watch(expansionStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groupedSeries.length,
          itemBuilder: (context, index) {
            final item = groupedSeries[index];
            final key = 'series_group_$index';
            final isExpanded = expansionState[key] ?? false;

            if (item is List<Series>) {
              return _buildSeriesGroupCard(
                  context, item, index, isExpanded, key, theme, colorScheme);
            } else {
              return _buildSeriesCard(
                  context, item as Series, index, theme, colorScheme);
            }
          },
        ),
        SizedBox(height: AppTheme.spacing.md),
        _buildActionButtons(exercise.series, theme, colorScheme),
      ],
    );
  }

  Widget _buildSeriesGroupCard(
    BuildContext context,
    List<Series> seriesGroup,
    int groupIndex,
    bool isExpanded,
    String key,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final series = seriesGroup.first;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key(key),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (value) {
            ref.read(expansionStateProvider.notifier).toggleExpansionState(key);
          },
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.sm,
                  vertical: AppTheme.spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radii.full),
                ),
                child: Text(
                  '${seriesGroup.length} serie',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacing.sm),
              Expanded(
                child: Text(
                  _formatSeriesInfo(series),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _showSeriesGroupOptions(
              context,
              seriesGroup,
              groupIndex,
              theme,
              colorScheme,
            ),
          ),
          children: [
            for (int i = 0; i < seriesGroup.length; i++)
              _buildSeriesCard(
                context,
                seriesGroup[i],
                groupIndex,
                theme,
                colorScheme,
                i,
                () {
                  seriesGroup.removeAt(i);
                  widget.controller.updateSeries(
                    widget.weekIndex,
                    widget.workoutIndex,
                    widget.exerciseIndex,
                    seriesGroup,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesCard(
    BuildContext context,
    Series series,
    int groupIndex,
    ThemeData theme,
    ColorScheme colorScheme, [
    int? seriesIndex,
    VoidCallback? onRemove,
  ]) {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.xs,
      ),
      padding: EdgeInsets.all(AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Serie ${series.order}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.xs),
                    Text(
                      _formatSeriesInfo(series),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: colorScheme.error,
                  ),
                  onPressed: onRemove,
                ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.sm),
          SeriesInputFields(
            maxWeight: latestMaxWeight,
            exerciseName: exercise.name,
            initialIntensity: series.intensity,
            initialMaxIntensity: series.maxIntensity,
            initialRpe: series.rpe,
            initialMaxRpe: series.maxRpe,
            initialWeight: series.weight?.toString(),
            initialMaxWeight: series.maxWeight?.toString(),
            onIntensityChanged: (intensity) {
              setState(() {
                series.intensity = intensity.toStringAsFixed(1);
                widget.controller.notifyListeners();
              });
            },
            onMaxIntensityChanged: (maxIntensity) {
              setState(() {
                series.maxIntensity = maxIntensity?.toStringAsFixed(1);
                widget.controller.notifyListeners();
              });
            },
            onRpeChanged: (rpe) {
              setState(() {
                series.rpe = rpe.toStringAsFixed(1);
                widget.controller.notifyListeners();
              });
            },
            onMaxRpeChanged: (maxRpe) {
              setState(() {
                series.maxRpe = maxRpe?.toStringAsFixed(1);
                widget.controller.notifyListeners();
              });
            },
            onWeightChanged: (weight) {
              setState(() {
                series.weight = weight;
                widget.controller.notifyListeners();
              });
            },
            onMaxWeightChanged: (maxWeight) {
              setState(() {
                series.maxWeight = maxWeight;
                widget.controller.notifyListeners();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      List<Series> series, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.reorder,
            label: 'Reorder Series',
            onTap: () => _showReorderSeriesDialog(series),
            isPrimary: false,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
        SizedBox(width: AppTheme.spacing.md),
        Expanded(
          child: _buildActionButton(
            icon: Icons.add,
            label: 'Add Series',
            onTap: () => _showEditSeriesDialog(null),
            isPrimary: true,
            theme: theme,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPrimary
              ? [colorScheme.primary, colorScheme.primary.withOpacity(0.8)]
              : [
                  colorScheme.surfaceContainerHighest,
                  colorScheme.surfaceContainerHighest.withOpacity(0.8)
                ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        boxShadow: isPrimary ? AppTheme.elevations.small : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: AppTheme.spacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isPrimary
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isPrimary
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<dynamic> _groupSeries(List<Series> series) {
    final groupedSeries = <dynamic>[];
    List<Series> currentGroup = [];

    for (int i = 0; i < series.length; i++) {
      final currentSeries = series[i];
      if (i == 0 || !_areSeriesEqual(currentSeries, series[i - 1])) {
        if (currentGroup.isNotEmpty) {
          groupedSeries.add(currentGroup);
          currentGroup = [];
        }
        currentGroup.add(currentSeries);
      } else {
        currentGroup.add(currentSeries);
      }
    }

    if (currentGroup.isNotEmpty) {
      groupedSeries.add(currentGroup);
    }

    return groupedSeries;
  }

  bool _areSeriesEqual(Series a, Series b) {
    return a.reps == b.reps &&
        a.maxReps == b.maxReps &&
        a.intensity == b.intensity &&
        a.maxIntensity == b.maxIntensity &&
        a.rpe == b.rpe &&
        a.maxRpe == b.maxRpe &&
        a.weight == b.weight &&
        a.maxWeight == b.maxWeight;
  }

  void _showReorderSeriesDialog(List<Series> series) {
    final seriesNames = series.map((s) {
      return 'Series ${s.order}: ${_formatSeriesInfo(s)}';
    }).toList();

    showDialog(
      context: context,
      builder: (context) => ReorderDialog(
        items: seriesNames,
        onReorder: (oldIndex, newIndex) {
          widget.controller.reorderSeries(widget.weekIndex, widget.workoutIndex,
              widget.exerciseIndex, oldIndex, newIndex);
        },
      ),
    );
  }

  void _showEditSeriesDialog(List<Series>? seriesGroup,
      {bool isIndividualEdit = false}) {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => SeriesDialog(
        exerciseRecordService: widget.exerciseRecordService,
        athleteId: widget.controller.program.athleteId,
        exerciseId: exercise.exerciseId ?? '',
        exerciseType: widget.exerciseType,
        weekIndex: widget.weekIndex,
        exercise: exercise,
        currentSeriesGroup: seriesGroup,
        latestMaxWeight: latestMaxWeight,
        weightNotifier: ValueNotifier<double>(0.0),
        isIndividualEdit: isIndividualEdit,
      ),
    ).then((result) {
      if (result != null) {
        if (result['action'] == 'update') {
          _updateExistingSeries(result['originalGroup'], result['series']);
        } else if (result['action'] == 'add') {
          _addNewSeries(result['series']);
        }
      }
    });
  }

  void _updateExistingSeries(
      List<Series> oldSeriesGroup, List<Series> updatedSeries) {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];

    // Trova l'indice di inizio del gruppo di serie da aggiornare
    final startIndex = exercise.series
        .indexWhere((s) => s.serieId == oldSeriesGroup.first.serieId);
    if (startIndex != -1) {
      // Rimuovi le vecchie serie
      exercise.series
          .removeRange(startIndex, startIndex + oldSeriesGroup.length);

      // Inserisci le serie aggiornate
      exercise.series.insertAll(startIndex, updatedSeries);

      // Aggiorna gli ordini delle serie
      for (int i = 0; i < exercise.series.length; i++) {
        exercise.series[i].order = i + 1;
      }

      widget.controller.updateSeries(widget.weekIndex, widget.workoutIndex,
          widget.exerciseIndex, exercise.series);
    }
  }

  void _addNewSeries(List<Series> newSeries) {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];

    exercise.series.addAll(newSeries);

    for (int i = 0; i < exercise.series.length; i++) {
      exercise.series[i].order = i + 1;
    }

    widget.controller.updateSeries(widget.weekIndex, widget.workoutIndex,
        widget.exerciseIndex, exercise.series);
  }

  String _formatSeriesInfo(Series series) {
    final reps =
        _formatRange(series.reps.toString(), series.maxReps?.toString());
    final sets =
        _formatRange(series.sets.toString(), series.maxSets?.toString());
    final weight =
        _formatRange(series.weight.toString(), series.maxWeight?.toString());
    return '$sets set(s), $reps reps x $weight kg';
  }

  String _formatRange(String minValue, String? maxValue) {
    if (maxValue != null && maxValue != minValue) {
      return '$minValue-$maxValue';
    }
    return minValue;
  }

  void _showDeleteSeriesGroupDialog(List<Series> seriesGroup, int groupIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Gruppo Di Serie'),
        content:
            const Text('Confermi Di Voler Eliminare Questo Gruppo Di Serie'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              _deleteSeriesGroup(seriesGroup, groupIndex);
              Navigator.pop(context);
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _deleteSeriesGroup(List<Series> seriesGroup, int groupIndex) {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];

    List<Series> seriesToRemove = List.from(seriesGroup);

    for (Series series in seriesToRemove) {
      if (series.serieId != null) {
        widget.controller.program.trackToDeleteSeries.add(series.serieId!);
      }
    }

    exercise.series.removeWhere((series) => seriesToRemove.contains(series));

    for (int i = 0; i < exercise.series.length; i++) {
      exercise.series[i].order = i + 1;
    }

    widget.controller.updateSeries(widget.weekIndex, widget.workoutIndex,
        widget.exerciseIndex, exercise.series);
  }

  void _showSeriesOptions(
    BuildContext context,
    Series series,
    List<Series> seriesGroup,
    int groupIndex,
    int? seriesIndex,
    VoidCallback? onRemove,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: 'Serie ${series.order}',
        subtitle: _formatSeriesInfo(series),
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.fitness_center,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Modifica',
            icon: Icons.edit_outlined,
            onTap: () =>
                _showEditSeriesDialog([series], isIndividualEdit: true),
          ),
          BottomMenuItem(
            title: 'Duplica Serie',
            icon: Icons.content_copy_outlined,
            onTap: () {
              final newSeries = series.copyWith(
                serieId: generateRandomId(16),
                order: exercise.series.length + 1,
              );
              _addNewSeries([newSeries]);
            },
          ),
          BottomMenuItem(
            title: 'Elimina',
            icon: Icons.delete_outline,
            onTap: () {
              if (onRemove != null) {
                onRemove();
              } else {
                widget.controller.removeSeries(
                  widget.weekIndex,
                  widget.workoutIndex,
                  widget.exerciseIndex,
                  groupIndex,
                  seriesIndex ?? 0,
                );
              }
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _showSeriesGroupOptions(
    BuildContext context,
    List<Series> seriesGroup,
    int groupIndex,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final exercise = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BottomMenu(
        title: 'Gruppo Serie',
        subtitle: '${seriesGroup.length} serie',
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppTheme.radii.md),
          ),
          child: Icon(
            Icons.format_list_numbered,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        items: [
          BottomMenuItem(
            title: 'Modifica Gruppo',
            icon: Icons.edit_outlined,
            onTap: () => _showEditSeriesDialog(seriesGroup),
          ),
          BottomMenuItem(
            title: 'Duplica Gruppo',
            icon: Icons.content_copy_outlined,
            onTap: () {
              final newSeriesGroup = seriesGroup
                  .map((s) => s.copyWith(
                        serieId: generateRandomId(16),
                        order:
                            exercise.series.length + seriesGroup.indexOf(s) + 1,
                      ))
                  .toList();
              _addNewSeries(newSeriesGroup);
            },
          ),
          BottomMenuItem(
            title: 'Riordina Serie',
            icon: Icons.reorder,
            onTap: () => _showReorderSeriesDialog(seriesGroup),
          ),
          BottomMenuItem(
            title: 'Elimina Gruppo',
            icon: Icons.delete_outline,
            onTap: () => _showDeleteSeriesGroupDialog(seriesGroup, groupIndex),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  void _navigateToExerciseDetails(BuildContext context,
      {required String? userId,
      required String? programId,
      required String? weekId,
      required String? workoutId,
      required String? exerciseId,
      required List<SuperSet> superSets,
      required int superSetExerciseIndex,
      required List<Series> seriesList,
      required int startIndex}) {
    if (userId == null ||
        programId == null ||
        weekId == null ||
        workoutId == null ||
        exerciseId == null) return;

    context.go(
        '/user_programs/training_viewer/week_details/workout_details/exercise_details',
        extra: {
          'programId': programId,
          'weekId': weekId,
          'workoutId': workoutId,
          'exerciseId': exerciseId,
          'userId': userId,
          'superSetExercises': superSets.map((s) => s.toMap()).toList(),
          'superSetExerciseIndex': superSetExerciseIndex,
          'seriesList': seriesList.map((s) => s.toMap()).toList(),
          'startIndex': startIndex
        });
  }
}
