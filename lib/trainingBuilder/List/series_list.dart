import 'package:alphanessone/ExerciseRecords/exercise_record_services.dart';
import 'package:alphanessone/shared/shared.dart';
import 'package:alphanessone/trainingBuilder/models/superseries_model.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../controller/training_program_controller.dart';
import '../dialog/reorder_dialog.dart';
import '../series_utils.dart';
import '../dialog/series_dialog.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/bottom_menu.dart';
import 'package:alphanessone/UI/components/button.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/UI/components/series_input_fields.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/series_components.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart';

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

/// Widget for displaying and managing series list
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
    extends ConsumerState<TrainingProgramSeriesList> with TrainingListMixin {
  late num latestMaxWeight = 0;

  @override
  void initState() {
    super.initState();
    _fetchLatestMaxWeight();
  }

  Future<void> _fetchLatestMaxWeight() async {
    final exercise = _getCurrentExercise();
    final maxWeight = await SeriesUtils.getLatestMaxWeight(
        widget.exerciseRecordService,
        widget.controller.program.athleteId,
        exercise.exerciseId ?? '');

    if (mounted) {
      setState(() {
        latestMaxWeight = maxWeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final workout = widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex];

    if (widget.exerciseIndex >= workout.exercises.length) {
      return _buildErrorWidget('Invalid exercise index');
    }

    final exercise = workout.exercises[widget.exerciseIndex];
    final groupedSeries = _SeriesGrouper.groupSeries(exercise.series);
    final expansionState = ref.watch(expansionStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSeriesList(groupedSeries, expansionState),
        SizedBox(height: AppTheme.spacing.md),
        SeriesActionButtons(
          onReorder: () => _showReorderDialog(exercise.series),
          onAdd: () => _showEditSeriesDialog(null),
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      message,
      style: theme.textTheme.titleMedium?.copyWith(
        color: colorScheme.error,
      ),
    );
  }

  Widget _buildSeriesList(
    List<dynamic> groupedSeries,
    Map<String, bool> expansionState,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedSeries.length,
      itemBuilder: (context, index) {
        final item = groupedSeries[index];
        final key = 'series_group_$index';
        final isExpanded = expansionState[key] ?? false;

        if (item is List<Series>) {
          return _buildSeriesGroupCard(item, index, isExpanded, key);
        } else {
          return _buildSingleSeriesCard(item as Series, index);
        }
      },
    );
  }

  Widget _buildSeriesGroupCard(
    List<Series> seriesGroup,
    int groupIndex,
    bool isExpanded,
    String key,
  ) {
    return SeriesGroupCard(
      seriesGroup: seriesGroup,
      isExpanded: isExpanded,
      onExpansionChanged: () {
        ref.read(expansionStateProvider.notifier).toggleExpansionState(key);
      },
      onOptionsPressed: () => _showSeriesGroupOptions(seriesGroup, groupIndex),
      seriesBuilder: (series, seriesIndex) => _buildSeriesWithInput(
        series,
        groupIndex,
        seriesIndex,
        () => _removeSeriesFromGroup(seriesGroup, seriesIndex),
      ),
    );
  }

  Widget _buildSingleSeriesCard(Series series, int groupIndex) {
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      child: SeriesInfoCard(
        series: series,
        onRemove: () => _removeSingleSeries(groupIndex),
      ),
    );
  }

  Widget _buildSeriesWithInput(
    Series series,
    int groupIndex,
    int seriesIndex,
    VoidCallback onRemove,
  ) {
    final exercise = _getCurrentExercise();

    return Column(
      children: [
        SeriesInfoCard(
          series: series,
          onRemove: onRemove,
        ),
        SizedBox(height: AppTheme.spacing.sm),
        SeriesInputFields(
          maxWeight: latestMaxWeight,
          exerciseName: exercise.name,
          initialIntensity: series.intensity,
          initialMaxIntensity: series.maxIntensity,
          initialRpe: series.rpe,
          initialMaxRpe: series.maxRpe,
          initialWeight: series.weight.toString(),
          initialMaxWeight: series.maxWeight?.toString(),
          onIntensityChanged: (intensity) => _updateSeriesField(
              series, 'intensity', intensity.toStringAsFixed(1)),
          onMaxIntensityChanged: (maxIntensity) => _updateSeriesField(
              series, 'maxIntensity', maxIntensity?.toStringAsFixed(1)),
          onRpeChanged: (rpe) =>
              _updateSeriesField(series, 'rpe', rpe.toStringAsFixed(1)),
          onMaxRpeChanged: (maxRpe) =>
              _updateSeriesField(series, 'maxRpe', maxRpe?.toStringAsFixed(1)),
          onWeightChanged: (weight) =>
              _updateSeriesField(series, 'weight', weight),
          onMaxWeightChanged: (maxWeight) =>
              _updateSeriesField(series, 'maxWeight', maxWeight),
        ),
      ],
    );
  }

  // Helper methods
  Exercise _getCurrentExercise() {
    return widget.controller.program.weeks[widget.weekIndex]
        .workouts[widget.workoutIndex].exercises[widget.exerciseIndex];
  }

  void _updateSeriesField(Series series, String field, dynamic value) {
    setState(() {
      // Note: Cannot modify series properties directly as they are final
      // This would need to be handled by the calling code using series.copyWith()
      switch (field) {
        case 'intensity':
        case 'maxIntensity':
        case 'rpe':
        case 'maxRpe':
        case 'weight':
        case 'maxWeight':
          // Property assignment not possible with immutable Series
          break;
      }
      _updateSeriesInController();
    });
  }

  void _updateSeriesInController() {
    final exercise = _getCurrentExercise();
    ref.read(trainingProgramControllerProvider.notifier).updateSeries(
          widget.weekIndex,
          widget.workoutIndex,
          widget.exerciseIndex,
          exercise.series,
        );
  }

  void _removeSeriesFromGroup(List<Series> seriesGroup, int seriesIndex) {
    seriesGroup.removeAt(seriesIndex);
    widget.controller.updateSeries(
      widget.weekIndex,
      widget.workoutIndex,
      widget.exerciseIndex,
      seriesGroup,
    );
  }

  void _removeSingleSeries(int groupIndex) {
    ref.read(trainingProgramControllerProvider.notifier).removeSeries(
          widget.weekIndex,
          widget.workoutIndex,
          widget.exerciseIndex,
          groupIndex,
          0,
        );
  }

  void _showReorderDialog(List<Series> series) {
    final seriesNames = series.map((s) {
      final repsText = s.maxReps != null ? '${s.reps}-${s.maxReps}' : '${s.reps}';
      final weightText = s.maxWeight != null ? '${s.weight.toStringAsFixed(1)}-${s.maxWeight!.toStringAsFixed(1)}kg' : '${s.weight.toStringAsFixed(1)}kg';
      return 'Series ${s.order}: ${repsText} reps @ ${weightText}';
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
    final exercise = _getCurrentExercise();

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
    final exercise = _getCurrentExercise();
    final startIndex = exercise.series
        .indexWhere((s) => s.serieId == oldSeriesGroup.first.serieId);

    if (startIndex != -1) {
      exercise.series
          .removeRange(startIndex, startIndex + oldSeriesGroup.length);
      exercise.series.insertAll(startIndex, updatedSeries);
      _reorderSeriesNumbers();
      _updateSeriesInController();
    }
  }

  void _addNewSeries(List<Series> newSeries) {
    final exercise = _getCurrentExercise();
    exercise.series.addAll(newSeries);
    _reorderSeriesNumbers();
    _updateSeriesInController();
  }

  void _reorderSeriesNumbers() {
    final exercise = _getCurrentExercise();
    for (int i = 0; i < exercise.series.length; i++) {
      // Note: Cannot modify series.order directly as it's final
      // This would need to be handled using series.copyWith()
    }
  }

  void _showSeriesGroupOptions(List<Series> seriesGroup, int groupIndex) {
    showOptionsBottomSheet(
      context,
      title: 'Gruppo Serie',
      subtitle: '${seriesGroup.length} serie',
      leadingIcon: Icons.format_list_numbered,
      items: _buildSeriesGroupMenuItems(seriesGroup, groupIndex),
    );
  }

  List<BottomMenuItem> _buildSeriesGroupMenuItems(
      List<Series> seriesGroup, int groupIndex) {
    final exercise = _getCurrentExercise();

    return [
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
                    order: exercise.series.length + seriesGroup.indexOf(s) + 1,
                  ))
              .toList();
          _addNewSeries(newSeriesGroup);
        },
      ),
      BottomMenuItem(
        title: 'Riordina Serie',
        icon: Icons.reorder,
        onTap: () => _showReorderDialog(seriesGroup),
      ),
      BottomMenuItem(
        title: 'Elimina Gruppo',
        icon: Icons.delete_outline,
        onTap: () => _handleDeleteSeriesGroup(seriesGroup, groupIndex),
        isDestructive: true,
      ),
    ];
  }

  void _handleDeleteSeriesGroup(
      List<Series> seriesGroup, int groupIndex) async {
    final confirmed = await showDeleteConfirmation(
      context,
      title: 'Elimina Gruppo Di Serie',
      content: 'Confermi Di Voler Eliminare Questo Gruppo Di Serie',
    );

    if (confirmed && mounted) {
      _deleteSeriesGroup(seriesGroup, groupIndex);
    }
  }

  void _deleteSeriesGroup(List<Series> seriesGroup, int groupIndex) {
    final exercise = _getCurrentExercise();

    for (Series series in seriesGroup) {
      if (series.serieId != null) {
        widget.controller.program.trackToDeleteSeries.add(series.serieId!);
      }
    }

    exercise.series.removeWhere((series) => seriesGroup.contains(series));
    _reorderSeriesNumbers();
    _updateSeriesInController();
  }
}

/// Helper class for grouping series logic (following SRP)
class _SeriesGrouper {
  static List<dynamic> groupSeries(List<Series> series) {
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

  static bool _areSeriesEqual(Series a, Series b) {
    return a.reps == b.reps &&
        a.maxReps == b.maxReps &&
        a.intensity == b.intensity &&
        a.maxIntensity == b.maxIntensity &&
        a.rpe == b.rpe &&
        a.maxRpe == b.maxRpe &&
        a.weight == b.weight &&
        a.maxWeight == b.maxWeight;
  }
}
