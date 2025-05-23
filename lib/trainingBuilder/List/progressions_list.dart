import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:alphanessone/trainingBuilder/models/exercise_model.dart';
import 'package:alphanessone/trainingBuilder/models/progressions_model.dart';
import 'package:alphanessone/trainingBuilder/models/series_model.dart';
import 'package:alphanessone/trainingBuilder/models/week_model.dart';
import 'package:alphanessone/trainingBuilder/series_utils.dart';
import 'package:alphanessone/trainingBuilder/controller/training_program_controller.dart';
import 'package:alphanessone/trainingBuilder/utility_functions.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/trainingBuilder/services/progression_service.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/range_controllers.dart';
import 'package:alphanessone/trainingBuilder/shared/widgets/progression_components.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart';
import 'package:alphanessone/trainingBuilder/shared/mixins/training_list_mixin.dart';

// Utility function for number formatting
String formatNumber(dynamic value) {
  if (value == null) return '';
  if (value is int) return value.toString();
  if (value is double) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }
  if (value is String) {
    if (value.isEmpty) return '';
    final doubleValue = double.tryParse(value);
    return doubleValue != null ? formatNumber(doubleValue) : value;
  }
  return value.toString();
}

/// Controller for progression data
class ProgressionControllers {
  final RangeControllers reps;
  final TextEditingController sets;
  final RangeControllers intensity;
  final RangeControllers rpe;
  final RangeControllers weight;

  ProgressionControllers()
      : reps = RangeControllers(),
        sets = TextEditingController(),
        intensity = RangeControllers(),
        rpe = RangeControllers(),
        weight = RangeControllers();

  void dispose() {
    reps.dispose();
    sets.dispose();
    intensity.dispose();
    rpe.dispose();
    weight.dispose();
  }

  void updateFromSeries(Series series) {
    reps.min.text = FormatUtils.formatNumber(series.reps);
    reps.max.text = FormatUtils.formatNumber(series.maxReps);
    sets.text = FormatUtils.formatNumber(series.sets);
    intensity.min.text = FormatUtils.formatNumber(series.intensity);
    intensity.max.text = FormatUtils.formatNumber(series.maxIntensity);
    rpe.min.text = FormatUtils.formatNumber(series.rpe);
    rpe.max.text = FormatUtils.formatNumber(series.maxRpe);
    weight.min.text = FormatUtils.formatNumber(series.weight);
    weight.max.text = FormatUtils.formatNumber(series.maxWeight);
  }

  /// Gets the display text for load field
  String getLoadDisplayText(double latestMaxWeight) {
    return ProgressionService.getLoadDisplayText(
      minIntensity: intensity.min.text,
      maxIntensity: intensity.max.text,
      minRpe: rpe.min.text,
      maxRpe: rpe.max.text,
      latestMaxWeight: latestMaxWeight,
    );
  }
}

/// StateNotifier for managing progression controllers
class ProgressionControllersNotifier
    extends StateNotifier<List<List<List<ProgressionControllers>>>> {
  ProgressionControllersNotifier() : super([]);

  void initialize(List<List<WeekProgression>> weekProgressions) {
    state = weekProgressions
        .map((week) => week
            .map((session) =>
                session.series.map((_) => ProgressionControllers()).toList())
            .toList())
        .toList();

    for (int weekIndex = 0; weekIndex < weekProgressions.length; weekIndex++) {
      for (int sessionIndex = 0;
          sessionIndex < weekProgressions[weekIndex].length;
          sessionIndex++) {
        final seriesFromProgressions =
            weekProgressions[weekIndex][sessionIndex].series;
        for (int seriesIndex = 0;
            seriesIndex < seriesFromProgressions.length;
            seriesIndex++) {
          final s = seriesFromProgressions[seriesIndex];
          updateControllers(weekIndex, sessionIndex, seriesIndex, s);
        }
      }
    }
  }

  void updateControllers(
      int weekIndex, int sessionIndex, int groupIndex, Series series) {
    if (ProgressionService.isValidIndex(
        state, weekIndex, sessionIndex, groupIndex)) {
      final controllers = state[weekIndex][sessionIndex][groupIndex];
      controllers.updateFromSeries(series);
      state = [...state];
    }
  }

  void addControllers(int weekIndex, int sessionIndex, int groupIndex) {
    if (ProgressionService.isValidIndex(state, weekIndex, sessionIndex)) {
      final newControllers = ProgressionControllers();
      final newState = List<List<List<ProgressionControllers>>>.from(state);
      newState[weekIndex][sessionIndex].insert(groupIndex, newControllers);
      state = newState;
    }
  }

  void removeControllers(int weekIndex, int sessionIndex, int groupIndex) {
    if (ProgressionService.isValidIndex(
        state, weekIndex, sessionIndex, groupIndex)) {
      final newState = List<List<List<ProgressionControllers>>>.from(state);
      newState[weekIndex][sessionIndex].removeAt(groupIndex);
      state = newState;
    }
  }
}

final progressionControllersProvider = StateNotifierProvider<
    ProgressionControllersNotifier,
    List<List<List<ProgressionControllers>>>>((ref) {
  return ProgressionControllersNotifier();
});

/// Main progressions list widget
class ProgressionsList extends ConsumerStatefulWidget {
  final String exerciseId;
  final Exercise? exercise;
  final num latestMaxWeight;

  const ProgressionsList({
    super.key,
    required this.exerciseId,
    this.exercise,
    required this.latestMaxWeight,
  });

  @override
  ConsumerState<ProgressionsList> createState() => _ProgressionsListState();
}

class _ProgressionsListState extends ConsumerState<ProgressionsList>
    with AutomaticKeepAliveClientMixin, TrainingListMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initializeControllers());
  }

  void _initializeControllers() {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = ProgressionService.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);
    ref
        .read(progressionControllersProvider.notifier)
        .initialize(weekProgressions);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final programController = ref.watch(trainingProgramControllerProvider);
    final controllers = ref.watch(progressionControllersProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final weekProgressions = ProgressionService.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    if (controllers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(progressionControllersProvider.notifier)
            .initialize(weekProgressions);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _ProgressionsView(
      weekProgressions: weekProgressions,
      controllers: controllers,
      exercise: widget.exercise!,
      latestMaxWeight: widget.latestMaxWeight,
      colorScheme: colorScheme,
      theme: theme,
      onSave: _handleSave,
      onAddSeriesGroup: _addSeriesGroup,
      onRemoveSeriesGroup: _removeSeriesGroup,
      onUpdateSeries: _updateSeries,
    );
  }

  void _addSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = ProgressionService.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);
    final controllersNotifier =
        ref.read(progressionControllersProvider.notifier);

    if (ProgressionService.isValidIndex(
        weekProgressions, weekIndex, sessionIndex)) {
      final newSeries = ProgressionService.createNewSeries(
        weekIndex: weekIndex,
        sessionIndex: sessionIndex,
        groupIndex: groupIndex,
      );

      final currentSession = weekProgressions[weekIndex][sessionIndex];
      final updatedSeries = List<Series>.from(currentSession.series)
        ..add(newSeries);
      currentSession.series = updatedSeries;

      weekProgressions[weekIndex][sessionIndex] = currentSession;
      programController.updateWeekProgressions(
          weekProgressions, widget.exercise!.exerciseId!);
      controllersNotifier.addControllers(weekIndex, sessionIndex, groupIndex);
    }
  }

  void _removeSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = ProgressionService.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    if (ProgressionService.isValidIndex(
        weekProgressions, weekIndex, sessionIndex)) {
      final groupedSeries = ProgressionService.groupSeries(
          weekProgressions[weekIndex][sessionIndex].series);
      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        groupedSeries.removeAt(groupIndex);
        weekProgressions[weekIndex][sessionIndex].series =
            groupedSeries.expand((group) => group).toList();
        _updateProgressionsWithNewSeries(weekProgressions);
        ref
            .read(progressionControllersProvider.notifier)
            .removeControllers(weekIndex, sessionIndex, groupIndex);
      }
    }
  }

  void _updateSeries(
    int weekIndex,
    int sessionIndex,
    int groupIndex, {
    String? reps,
    String? maxReps,
    String? sets,
    String? intensity,
    String? maxIntensity,
    String? rpe,
    String? maxRpe,
    String? weight,
    String? maxWeight,
  }) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = ProgressionService.buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    if (ProgressionService.isValidIndex(
        weekProgressions, weekIndex, sessionIndex)) {
      final groupedSeries = ProgressionService.groupSeries(
          weekProgressions[weekIndex][sessionIndex].series);
      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        final updatedGroup = groupedSeries[groupIndex].map((series) {
          return series.copyWith(
            reps:
                reps != null ? int.tryParse(reps) ?? series.reps : series.reps,
            maxReps: maxReps?.isEmpty == true ? null : int.tryParse(maxReps!),
            sets:
                sets != null ? int.tryParse(sets) ?? series.sets : series.sets,
            intensity: intensity?.isEmpty == true ? null : intensity,
            maxIntensity: maxIntensity?.isEmpty == true ? null : maxIntensity,
            rpe: rpe?.isEmpty == true ? null : rpe,
            maxRpe: maxRpe?.isEmpty == true ? null : maxRpe,
            weight: weight != null
                ? double.tryParse(weight) ?? series.weight
                : series.weight,
            maxWeight:
                maxWeight?.isEmpty == true ? null : double.tryParse(maxWeight!),
          );
        }).toList();

        groupedSeries[groupIndex] = updatedGroup;
        weekProgressions[weekIndex][sessionIndex].series =
            groupedSeries.expand((group) => group).toList();
        _updateProgressionsWithNewSeries(weekProgressions);

        final controllers = ref.read(progressionControllersProvider.notifier);
        final representativeSeries =
            updatedGroup.first.copyWith(sets: updatedGroup.length);
        controllers.updateControllers(
            weekIndex, sessionIndex, groupIndex, representativeSeries);

        setState(() {});
      }
    }
  }

  Future<void> _handleSave() async {
    final programController = ref.read(trainingProgramControllerProvider);
    final controllers = ref.read(progressionControllersProvider);

    try {
      final updatedWeekProgressions =
          ProgressionService.createUpdatedWeekProgressions(
        controllers,
        (text) => int.tryParse(text) ?? 0,
        (text) => double.tryParse(text) ?? 0.0,
      );

      programController.updateWeekProgressions(
          updatedWeekProgressions, widget.exercise!.exerciseId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progressions saved successfully')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('ERROR: Failed to save changes: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving progressions: $e')),
      );
    }
  }

  void _updateProgressionsWithNewSeries(
      List<List<WeekProgression>> weekProgressions) {
    ref
        .read(trainingProgramControllerProvider)
        .updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);
  }
}

/// Separated view component for progressions display
class _ProgressionsView extends StatelessWidget {
  final List<List<WeekProgression>> weekProgressions;
  final List<List<List<ProgressionControllers>>> controllers;
  final Exercise exercise;
  final num latestMaxWeight;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onSave;
  final Function(int, int, int) onAddSeriesGroup;
  final Function(int, int, int) onRemoveSeriesGroup;
  final Function(int, int, int,
      {String? reps,
      String? maxReps,
      String? sets,
      String? intensity,
      String? maxIntensity,
      String? rpe,
      String? maxRpe,
      String? weight,
      String? maxWeight}) onUpdateSeries;

  const _ProgressionsView({
    required this.weekProgressions,
    required this.controllers,
    required this.exercise,
    required this.latestMaxWeight,
    required this.colorScheme,
    required this.theme,
    required this.onSave,
    required this.onAddSeriesGroup,
    required this.onRemoveSeriesGroup,
    required this.onUpdateSeries,
  });

  @override
  Widget build(BuildContext context) {
    final maxSessions = weekProgressions.fold<int>(
        0, (max, week) => week.length > max ? week.length : max);

    final nonEmptySessions = _getNonEmptySessions(maxSessions);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...nonEmptySessions.map(
                      (sessionNumber) =>
                          _buildSessionTable(sessionNumber, context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSaveButton(),
          SizedBox(height: AppTheme.spacing.lg),
        ],
      ),
    );
  }

  List<int> _getNonEmptySessions(int maxSessions) {
    final nonEmptySessions = <int>[];
    for (int sessionNumber = 0; sessionNumber < maxSessions; sessionNumber++) {
      bool hasData = false;
      for (int weekIndex = 0;
          weekIndex < weekProgressions.length;
          weekIndex++) {
        if (weekIndex < controllers.length &&
            sessionNumber < controllers[weekIndex].length &&
            controllers[weekIndex][sessionNumber].isNotEmpty) {
          hasData = true;
          break;
        }
      }
      if (hasData) {
        nonEmptySessions.add(sessionNumber);
      }
    }
    return nonEmptySessions;
  }

  Widget _buildSessionTable(int sessionNumber, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.lg),
          child: Text(
            'Sessione ${sessionNumber + 1}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radii.lg),
            border: Border.all(
              color: colorScheme.outline.withAlpha(26),
            ),
          ),
          child: Column(
            children: [
              ProgressionTableHeader(
                colorScheme: colorScheme,
                theme: theme,
                isSmallScreen: MediaQuery.of(context).size.width < 768,
              ),
              ...weekProgressions.asMap().entries.map((entry) {
                final weekIndex = entry.key;
                return _buildWeekRow(weekIndex, sessionNumber, context);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekRow(int weekIndex, int sessionIndex, BuildContext context) {
    if (weekIndex >= controllers.length ||
        sessionIndex >= controllers[weekIndex].length ||
        controllers[weekIndex][sessionIndex].isEmpty) {
      return const SizedBox.shrink();
    }

    final sessionControllers = controllers[weekIndex][sessionIndex];
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    return _WeekRowWidget(
      weekIndex: weekIndex,
      sessionIndex: sessionIndex,
      sessionControllers: sessionControllers,
      exercise: exercise,
      latestMaxWeight: latestMaxWeight,
      colorScheme: colorScheme,
      theme: theme,
      isSmallScreen: isSmallScreen,
      onAddSeriesGroup: onAddSeriesGroup,
      onRemoveSeriesGroup: onRemoveSeriesGroup,
      onUpdateSeries: onUpdateSeries,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Save',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Widget for displaying week row with progression data
class _WeekRowWidget extends StatelessWidget {
  final int weekIndex;
  final int sessionIndex;
  final List<ProgressionControllers> sessionControllers;
  final Exercise exercise;
  final num latestMaxWeight;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final bool isSmallScreen;
  final Function(int, int, int) onAddSeriesGroup;
  final Function(int, int, int) onRemoveSeriesGroup;
  final Function(int, int, int,
      {String? reps,
      String? maxReps,
      String? sets,
      String? intensity,
      String? maxIntensity,
      String? rpe,
      String? maxRpe,
      String? weight,
      String? maxWeight}) onUpdateSeries;

  const _WeekRowWidget({
    required this.weekIndex,
    required this.sessionIndex,
    required this.sessionControllers,
    required this.exercise,
    required this.latestMaxWeight,
    required this.colorScheme,
    required this.theme,
    required this.isSmallScreen,
    required this.onAddSeriesGroup,
    required this.onRemoveSeriesGroup,
    required this.onUpdateSeries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withAlpha(26),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSmallScreen) _buildWeekHeader(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isSmallScreen) _buildWeekColumn(),
                Expanded(
                  flex: isSmallScreen ? 12 : 10,
                  child: _buildGroupsColumn(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.sm,
          vertical: AppTheme.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(76),
          borderRadius: BorderRadius.circular(AppTheme.radii.full),
        ),
        child: Text(
          'Week ${weekIndex + 1}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekColumn() {
    return Expanded(
      flex: 2,
      child: Text(
        '${weekIndex + 1}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildGroupsColumn(BuildContext context) {
    return Column(
      children: [
        ...sessionControllers.asMap().entries.map((entry) {
          final groupIndex = entry.key;
          final controllers = entry.value;
          return Column(
            children: [
              if (groupIndex > 0) SizedBox(height: AppTheme.spacing.sm),
              _buildGroupRow(context, groupIndex, controllers),
            ],
          );
        }),
        _buildAddGroupButton(),
      ],
    );
  }

  Widget _buildGroupRow(BuildContext context, int groupIndex,
      ProgressionControllers controllers) {
    final groupContent = Row(
      children: [
        Expanded(
          child: _ProgressionGroupFields(
            weekIndex: weekIndex,
            sessionIndex: sessionIndex,
            groupIndex: groupIndex,
            controllers: controllers,
            exercise: exercise,
            latestMaxWeight: latestMaxWeight,
            colorScheme: colorScheme,
            theme: theme,
            onUpdateSeries: onUpdateSeries,
          ),
        ),
        if (!isSmallScreen)
          IconButton(
            icon:
                Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
            onPressed: () =>
                onRemoveSeriesGroup(weekIndex, sessionIndex, groupIndex),
            tooltip: 'Rimuovi Gruppo',
          ),
      ],
    );

    if (isSmallScreen) {
      return Slidable(
        key: ValueKey('group-$weekIndex-$sessionIndex-$groupIndex'),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) =>
                  onRemoveSeriesGroup(weekIndex, sessionIndex, groupIndex),
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              icon: Icons.delete,
              label: 'Rimuovi',
            ),
          ],
        ),
        child: groupContent,
      );
    }

    return groupContent;
  }

  Widget _buildAddGroupButton() {
    return Padding(
      padding: EdgeInsets.only(top: AppTheme.spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              onAddSeriesGroup(
                  weekIndex, sessionIndex, sessionControllers.length);
            },
            icon: Icon(
              Icons.add_circle_outline,
              size: 16,
              color: colorScheme.primary,
            ),
            label: Text(
              'Aggiungi Gruppo',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing.md,
                vertical: AppTheme.spacing.sm,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Component for progression group fields - Funzionalità completa ripristinata
class _ProgressionGroupFields extends StatelessWidget {
  final int weekIndex;
  final int sessionIndex;
  final int groupIndex;
  final ProgressionControllers controllers;
  final Exercise exercise;
  final num latestMaxWeight;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final Function(int, int, int,
      {String? reps,
      String? maxReps,
      String? sets,
      String? intensity,
      String? maxIntensity,
      String? rpe,
      String? maxRpe,
      String? weight,
      String? maxWeight}) onUpdateSeries;

  const _ProgressionGroupFields({
    required this.weekIndex,
    required this.sessionIndex,
    required this.groupIndex,
    required this.controllers,
    required this.exercise,
    required this.latestMaxWeight,
    required this.colorScheme,
    required this.theme,
    required this.onUpdateSeries,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reps
        Expanded(
          child: ProgressionFieldContainer(
            label: 'Reps',
            value: controllers.reps.displayText,
            onTap: () => _showRepsDialog(context),
            colorScheme: colorScheme,
            theme: theme,
            isLoadField: false,
            isSmallScreen: isSmallScreen,
          ),
        ),
        SizedBox(width: AppTheme.spacing.xs),
        // Sets
        Expanded(
          child: ProgressionTextField(
            controller: controllers.sets,
            labelText: 'Sets',
            keyboardType: TextInputType.number,
            onChanged: (value) => onUpdateSeries(
                weekIndex, sessionIndex, groupIndex,
                sets: value),
            colorScheme: colorScheme,
            theme: theme,
          ),
        ),
        SizedBox(width: AppTheme.spacing.xs),
        // Load (Funzionalità completa)
        Expanded(
          flex: isSmallScreen ? 2 : 1,
          child: ProgressionFieldContainer(
            label: 'Load',
            value: controllers.getLoadDisplayText(latestMaxWeight.toDouble()),
            onTap: () => _showLoadDialog(context),
            colorScheme: colorScheme,
            theme: theme,
            isLoadField: true,
            isSmallScreen: isSmallScreen,
          ),
        ),
      ],
    );
  }

  void _showRepsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgressionRangeEditDialog(
        title: 'Ripetizioni',
        initialMin: controllers.reps.min.text,
        initialMax: controllers.reps.max.text,
        onSave: (min, max) {
          if (min != null) controllers.reps.min.text = min;
          if (max != null) controllers.reps.max.text = max;

          onUpdateSeries(
            weekIndex,
            sessionIndex,
            groupIndex,
            reps: min,
            maxReps: max,
          );

          Navigator.pop(context);
        },
        onChanged: (min, max) {
          // Aggiornamento real-time opzionale
        },
      ),
    );
  }

  void _showLoadDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgressionCombinedLoadDialog(
        intensityControllers: controllers.intensity,
        rpeControllers: controllers.rpe,
        weightControllers: controllers.weight,
        colorScheme: colorScheme,
        theme: theme,
        onRealTimeUpdate: (type, minValue, maxValue, field) {
          _handleLoadUpdate(type, minValue, maxValue, field, context);
        },
      ),
    );
  }

  void _handleLoadUpdate(String type, String minValue, String maxValue,
      String field, BuildContext context) {
    switch (type) {
      case 'Intensity':
        // Aggiorna i peso basandosi sull'intensità
        ProgressionService.updateWeightFromIntensity(
          minIntensity: minValue,
          maxIntensity: maxValue,
          latestMaxWeight: latestMaxWeight.toDouble(),
          exerciseType: exercise.type,
          onUpdate: (minWeight, maxWeight) {
            controllers.weight.min.text = minWeight;
            controllers.weight.max.text = maxWeight;

            // Aggiorna le serie
            onUpdateSeries(
              weekIndex,
              sessionIndex,
              groupIndex,
              intensity: minValue.isNotEmpty ? minValue : null,
              maxIntensity: maxValue.isNotEmpty ? maxValue : null,
              weight: minWeight.isNotEmpty ? minWeight : null,
              maxWeight: maxWeight.isNotEmpty ? maxWeight : null,
            );
          },
        );
        break;

      case 'Weight':
        // Aggiorna l'intensità basandosi sul peso
        ProgressionService.updateIntensityFromWeight(
          minWeight: minValue,
          maxWeight: maxValue,
          latestMaxWeight: latestMaxWeight.toDouble(),
          onUpdate: (minIntensity, maxIntensity) {
            controllers.intensity.min.text = minIntensity;
            controllers.intensity.max.text = maxIntensity;

            // Aggiorna le serie
            onUpdateSeries(
              weekIndex,
              sessionIndex,
              groupIndex,
              weight: minValue.isNotEmpty ? minValue : null,
              maxWeight: maxValue.isNotEmpty ? maxValue : null,
              intensity: minIntensity.isNotEmpty ? minIntensity : null,
              maxIntensity: maxIntensity.isNotEmpty ? maxIntensity : null,
            );
          },
        );
        break;

      case 'RPE':
        // Aggiorna solo RPE
        onUpdateSeries(
          weekIndex,
          sessionIndex,
          groupIndex,
          rpe: minValue.isNotEmpty ? minValue : null,
          maxRpe: maxValue.isNotEmpty ? maxValue : null,
        );
        break;
    }
  }
}
