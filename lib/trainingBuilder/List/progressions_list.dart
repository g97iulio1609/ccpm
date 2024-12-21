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

class RangeControllers {
  final TextEditingController min;
  final TextEditingController max;

  RangeControllers()
      : min = TextEditingController(),
        max = TextEditingController();

  void dispose() {
    min.dispose();
    max.dispose();
  }

  String get displayText {
    final minText = formatNumber(min.text);
    final maxText = formatNumber(max.text);
    if (maxText.isEmpty) return minText;
    if (minText.isEmpty) return maxText;
    return "$minText-$maxText";
  }

  void updateFromDialog(String minValue, String maxValue) {
    min.text = minValue;
    max.text = maxValue;
  }
}

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
}

class ProgressionControllersNotifier
    extends StateNotifier<List<List<List<ProgressionControllers>>>> {
  ProgressionControllersNotifier() : super([]);

  void initialize(List<List<WeekProgression>> weekProgressions) {
    state = weekProgressions
        .map((week) => week
            .map((session) => _groupSeries(session.series)
                .map((_) => ProgressionControllers())
                .toList())
            .toList())
        .toList();

    for (int weekIndex = 0; weekIndex < weekProgressions.length; weekIndex++) {
      for (int sessionIndex = 0;
          sessionIndex < weekProgressions[weekIndex].length;
          sessionIndex++) {
        final groupedSeries =
            _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
        for (int groupIndex = 0;
            groupIndex < groupedSeries.length;
            groupIndex++) {
          updateControllers(weekIndex, sessionIndex, groupIndex,
              groupedSeries[groupIndex].first);
        }
      }
    }
  }

  void updateControllers(
      int weekIndex, int sessionIndex, int groupIndex, Series series) {
    if (_isValidIndex(state, weekIndex, sessionIndex, groupIndex)) {
      final controllers = state[weekIndex][sessionIndex][groupIndex];
      controllers.reps.min.text = formatNumber(series.reps);
      controllers.reps.max.text = formatNumber(series.maxReps);
      controllers.sets.text = formatNumber(series.sets);
      controllers.intensity.min.text = formatNumber(series.intensity);
      controllers.intensity.max.text = formatNumber(series.maxIntensity);
      controllers.rpe.min.text = formatNumber(series.rpe);
      controllers.rpe.max.text = formatNumber(series.maxRpe);
      controllers.weight.min.text = formatNumber(series.weight);
      controllers.weight.max.text = formatNumber(series.maxWeight);
      state = [...state];
    }
  }

  void addControllers(int weekIndex, int sessionIndex, int groupIndex) {
    if (_isValidIndex(state, weekIndex, sessionIndex)) {
      final newControllers = ProgressionControllers();
      final newState = List<List<List<ProgressionControllers>>>.from(state);
      newState[weekIndex][sessionIndex].insert(groupIndex, newControllers);
      state = newState;
    }
  }

  void removeControllers(int weekIndex, int sessionIndex, int groupIndex) {
    if (_isValidIndex(state, weekIndex, sessionIndex, groupIndex)) {
      final newState = List<List<List<ProgressionControllers>>>.from(state);
      newState[weekIndex][sessionIndex].removeAt(groupIndex);
      state = newState;
    }
  }

  bool _isValidIndex(
      List<List<List<ProgressionControllers>>> list, int weekIndex,
      [int? sessionIndex, int? groupIndex]) {
    return weekIndex >= 0 &&
        weekIndex < list.length &&
        (sessionIndex == null ||
            (sessionIndex >= 0 && sessionIndex < list[weekIndex].length)) &&
        (groupIndex == null ||
            (groupIndex >= 0 &&
                groupIndex < list[weekIndex][sessionIndex!].length));
  }

  static List<List<Series>> _groupSeries(List<Series> series) {
    if (series.isEmpty) return [];

    final groupedSeries = <List<Series>>[];
    List<Series> currentGroup = [series[0]];

    for (int i = 1; i < series.length; i++) {
      final currentSeries = series[i];
      final previousSeries = series[i - 1];

      if (_isSameGroup(currentSeries, previousSeries)) {
        currentGroup.add(currentSeries);
      } else {
        groupedSeries.add(List<Series>.from(currentGroup));
        currentGroup = [currentSeries];
      }
    }

    // Aggiungi l'ultimo gruppo
    if (currentGroup.isNotEmpty) {
      groupedSeries.add(currentGroup);
    }

    return groupedSeries;
  }

  static bool _isSameGroup(Series a, Series b) {
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

final progressionControllersProvider = StateNotifierProvider<
    ProgressionControllersNotifier,
    List<List<List<ProgressionControllers>>>>((ref) {
  return ProgressionControllersNotifier();
});

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
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final bool _isSwipeInProgress = false;

  List<List<Series>> _groupSeries(List<Series> series) {
    if (series.isEmpty) return [];

    final groupedSeries = <List<Series>>[];
    List<Series> currentGroup = [series[0]];

    for (int i = 1; i < series.length; i++) {
      final currentSeries = series[i];
      final previousSeries = series[i - 1];

      if (_isSameGroup(currentSeries, previousSeries)) {
        currentGroup.add(currentSeries);
      } else {
        groupedSeries.add(List<Series>.from(currentGroup));
        currentGroup = [currentSeries];
      }
    }

    // Aggiungi l'ultimo gruppo
    if (currentGroup.isNotEmpty) {
      groupedSeries.add(currentGroup);
    }

    return groupedSeries;
  }

  bool _isSameGroup(Series a, Series b) {
    return a.reps == b.reps &&
        a.maxReps == b.maxReps &&
        a.intensity == b.intensity &&
        a.maxIntensity == b.maxIntensity &&
        a.rpe == b.rpe &&
        a.maxRpe == b.maxRpe &&
        a.weight == b.weight &&
        a.maxWeight == b.maxWeight;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initializeControllers());
  }

  void _initializeControllers() {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(
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

    final weekProgressions = _buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    if (controllers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(progressionControllersProvider.notifier)
            .initialize(weekProgressions);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determina il numero massimo di sessioni
    final maxSessions = weekProgressions.fold<int>(
        0, (max, week) => week.length > max ? week.length : max);

    // Crea una mappa per tenere traccia delle sessioni non vuote
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
                    // Crea una tabella per ogni sessione non vuota
                    ...nonEmptySessions.map(
                      (sessionNumber) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: AppTheme.spacing.lg),
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
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radii.lg),
                              border: Border.all(
                                color: colorScheme.outline.withAlpha(26),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildTableHeader(colorScheme, theme, false),
                                // Righe per ogni settimana
                                for (int weekIndex = 0;
                                    weekIndex < weekProgressions.length;
                                    weekIndex++)
                                  if (weekIndex < controllers.length &&
                                      sessionNumber <
                                          controllers[weekIndex].length &&
                                      controllers[weekIndex][sessionNumber]
                                          .isNotEmpty)
                                    _buildWeekRow(
                                      weekIndex,
                                      sessionNumber,
                                      weekProgressions[weekIndex]
                                          [sessionNumber],
                                      controllers[weekIndex][sessionNumber],
                                      colorScheme,
                                      theme,
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSaveButton(colorScheme),
          SizedBox(height: AppTheme.spacing.lg),
        ],
      ),
    );
  }

  Widget _buildTableHeader(
      ColorScheme colorScheme, ThemeData theme, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(76),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radii.lg),
        ),
      ),
      child: Row(
        children: [
          if (!isSmallScreen)
            Expanded(
              flex: 2,
              child: Text(
                'Week',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(128),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ...['Reps', 'Sets', 'Load'].map((header) {
            return Expanded(
              flex: 2,
              child: Text(
                header,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(128),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildGroupRow(
    int weekIndex,
    int sessionIndex,
    int groupIndex,
    ProgressionControllers controllers,
    ColorScheme colorScheme,
    ThemeData theme,
    bool isSmallScreen,
  ) {
    final groupContent = Row(
      children: [
        Expanded(
          child: _buildGroupFields(
            weekIndex,
            sessionIndex,
            groupIndex,
            controllers,
            colorScheme,
            theme,
          ),
        ),
        if (!isSmallScreen)
          IconButton(
            icon:
                Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
            onPressed: () =>
                _removeSeriesGroup(weekIndex, sessionIndex, groupIndex),
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
                  _removeSeriesGroup(weekIndex, sessionIndex, groupIndex),
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

  Widget _buildWeekRow(
    int weekIndex,
    int sessionIndex,
    WeekProgression session,
    List<ProgressionControllers> sessionControllers,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

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
            // Numero settimana come titolo su mobile
            if (isSmallScreen)
              Padding(
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
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonna Week solo su desktop
                if (!isSmallScreen)
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${weekIndex + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                // Gruppi di serie
                Expanded(
                  flex: isSmallScreen ? 12 : 10,
                  child: Column(
                    children: [
                      ...sessionControllers.asMap().entries.map((entry) {
                        final groupIndex = entry.key;
                        final controllers = entry.value;
                        return Column(
                          children: [
                            if (groupIndex > 0)
                              SizedBox(height: AppTheme.spacing.sm),
                            _buildGroupRow(
                              weekIndex,
                              sessionIndex,
                              groupIndex,
                              controllers,
                              colorScheme,
                              theme,
                              isSmallScreen,
                            ),
                          ],
                        );
                      }),
                      // Pulsante aggiungi gruppo
                      Padding(
                        padding: EdgeInsets.only(top: AppTheme.spacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _addSeriesGroup(weekIndex, sessionIndex,
                                      sessionControllers.length);
                                });
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupFields(
    int weekIndex,
    int sessionIndex,
    int groupIndex,
    ProgressionControllers controllers,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    String getLoadDisplayText() {
      final List<String> values = [];

      // Mostra percentuale e peso calcolato
      if (controllers.intensity.displayText.isNotEmpty) {
        final minIntensity =
            double.tryParse(controllers.intensity.min.text) ?? 0;
        final maxIntensity = controllers.intensity.max.text.isNotEmpty
            ? double.tryParse(controllers.intensity.max.text)
            : null;

        final minWeight = SeriesUtils.calculateWeightFromIntensity(
            widget.latestMaxWeight.toDouble(), minIntensity);
        final maxWeight = maxIntensity != null
            ? SeriesUtils.calculateWeightFromIntensity(
                widget.latestMaxWeight.toDouble(), maxIntensity)
            : null;

        String intensityText = minIntensity.toString();
        if (maxIntensity != null && maxIntensity > 0) {
          intensityText = '$minIntensity-$maxIntensity';
        }

        String weightText = minWeight.toStringAsFixed(1);
        if (maxWeight != null && maxWeight > minWeight) {
          weightText =
              '${minWeight.toStringAsFixed(1)}-${maxWeight.toStringAsFixed(1)}';
        }

        values.add('$intensityText% ($weightText kg)');
      }

      // RPE
      if (controllers.rpe.displayText.isNotEmpty) {
        final minRpe = double.tryParse(controllers.rpe.min.text) ?? 0;
        final maxRpe = controllers.rpe.max.text.isNotEmpty
            ? double.tryParse(controllers.rpe.max.text)
            : null;

        String rpeText = minRpe.toString();
        if (maxRpe != null && maxRpe > 0 && maxRpe != minRpe) {
          rpeText = '$minRpe-$maxRpe';
        }

        values.add('RPE: $rpeText');
      }

      return values.join('\n\n');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reps
        Expanded(
          child: _buildFieldContainer(
            'Reps',
            controllers.reps.displayText,
            () => _showRangeDialog(
                weekIndex, sessionIndex, groupIndex, 'Reps', controllers.reps),
            colorScheme,
            theme,
            false,
          ),
        ),
        SizedBox(width: AppTheme.spacing.xs),
        // Sets
        Expanded(
          child: _buildTextField(
            controller: controllers.sets,
            labelText: 'Sets',
            keyboardType: TextInputType.number,
            onChanged: (value) =>
                _updateSeries(weekIndex, sessionIndex, groupIndex, sets: value),
            colorScheme: colorScheme,
            theme: theme,
          ),
        ),
        SizedBox(width: AppTheme.spacing.xs),
        // Combined Load Fields
        Expanded(
          flex: isSmallScreen ? 2 : 1,
          child: _buildFieldContainer(
            'Load',
            getLoadDisplayText(),
            () => _showCombinedLoadDialog(weekIndex, sessionIndex, groupIndex,
                controllers, colorScheme, theme),
            colorScheme,
            theme,
            true,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldContainer(
    String label,
    String value,
    VoidCallback onTap,
    ColorScheme colorScheme,
    ThemeData theme,
    bool isLoadField,
  ) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
        child: Container(
          padding: EdgeInsets.all(AppTheme.spacing.sm),
          constraints: isLoadField && isSmallScreen
              ? const BoxConstraints(minHeight: 80)
              : null,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            border: Border.all(
              color: colorScheme.outline.withAlpha(26),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppTheme.spacing.sm),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: isSmallScreen && isLoadField ? 1.5 : 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: isSmallScreen && isLoadField ? 4 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String labelText,
      required TextInputType keyboardType,
      required Function(String) onChanged,
      required ColorScheme colorScheme,
      required ThemeData theme}) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
        border: Border.all(
          color: colorScheme.outline.withAlpha(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            labelText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing.xs),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showRangeDialog(int weekIndex, int sessionIndex, int groupIndex,
      String title, RangeControllers controllers) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radii.xl),
            ),
          ),
          padding: EdgeInsets.all(AppTheme.spacing.xl),
          child: RangeEditDialog(
            title: title,
            initialMin: controllers.min.text,
            initialMax: controllers.max.text,
            onSave: (min, max) {
              setState(() {
                controllers.updateFromDialog(min ?? '', max ?? '');
              });
              Navigator.of(dialogContext).pop();
              _updateSeriesWithRealTimeCalculations(
                weekIndex,
                sessionIndex,
                groupIndex,
                title,
                min ?? '',
                max ?? '',
              );
            },
            onChanged: (min, max) {
              _updateSeriesWithRealTimeCalculations(
                weekIndex,
                sessionIndex,
                groupIndex,
                title,
                min ?? '',
                max ?? '',
              );
            },
          ),
        );
      },
    );
  }

  void _updateSeriesWithRealTimeCalculations(
    int weekIndex,
    int sessionIndex,
    int groupIndex,
    String title,
    String min,
    String max,
  ) {
    final controllers = ref.read(progressionControllersProvider)[weekIndex]
        [sessionIndex][groupIndex];

    switch (title) {
      case 'Intensity':
        _updateWeightFromIntensity(controllers, min, max);
        break;
      case 'Weight':
        _updateIntensityFromWeight(controllers, min, max);
        break;
      case 'Reps':
      case 'RPE':
        // Aggiorna altri campi se necessario
        break;
    }

    _updateSeries(
      weekIndex,
      sessionIndex,
      groupIndex,
      reps: title == 'Reps' ? min : null,
      maxReps: title == 'Reps' ? max : null,
      intensity: title == 'Intensity' ? min : null,
      maxIntensity: title == 'Intensity' ? max : null,
      rpe: title == 'RPE' ? min : null,
      maxRpe: title == 'RPE' ? max : null,
      weight: title == 'Weight' ? min : null,
      maxWeight: title == 'Weight' ? max : null,
    );
  }

  void _updateWeightFromIntensity(
      ProgressionControllers controllers, String min, String max) {
    final minIntensity = double.tryParse(min) ?? 0;
    final minWeight = SeriesUtils.calculateWeightFromIntensity(
        widget.latestMaxWeight.toDouble(), minIntensity);
    controllers.weight.min.text =
        SeriesUtils.roundWeight(minWeight, widget.exercise!.type)
            .toStringAsFixed(1);

    if (max.isNotEmpty) {
      final maxIntensity = double.tryParse(max) ?? 0;
      final maxWeight = SeriesUtils.calculateWeightFromIntensity(
          widget.latestMaxWeight.toDouble(), maxIntensity);
      controllers.weight.max.text =
          SeriesUtils.roundWeight(maxWeight, widget.exercise!.type)
              .toStringAsFixed(1);
    } else {
      controllers.weight.max.text = '';
    }
  }

  void _updateIntensityFromWeight(
      ProgressionControllers controllers, String min, String max) {
    final minWeight = double.tryParse(min) ?? 0;
    final minIntensity = SeriesUtils.calculateIntensityFromWeight(
        minWeight, widget.latestMaxWeight);
    controllers.intensity.min.text = minIntensity.toStringAsFixed(1);

    if (max.isNotEmpty) {
      final maxWeight = double.tryParse(max) ?? 0;
      final maxIntensity = SeriesUtils.calculateIntensityFromWeight(
          maxWeight, widget.latestMaxWeight);
      controllers.intensity.max.text = maxIntensity.toStringAsFixed(1);
    } else {
      controllers.intensity.max.text = '';
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
    final weekProgressions = _buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    if (_isValidIndex(weekProgressions, weekIndex, sessionIndex)) {
      final groupedSeries =
          _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
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
        controllers.updateControllers(
            weekIndex, sessionIndex, groupIndex, updatedGroup.first);

        setState(() {});
      }
    }
  }

  void _addSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(
        programController.program.weeks, widget.exercise!);
    final controllersNotifier =
        ref.read(progressionControllersProvider.notifier);

    if (_isValidIndex(weekProgressions, weekIndex, sessionIndex)) {
      final newSeries = Series(
        serieId: generateRandomId(16).toString(),
        reps: 0,
        sets: 1,
        intensity: '',
        rpe: '',
        weight: 0.0,
        order: groupIndex + 1,
        done: false,
        reps_done: 0,
        weight_done: 0.0,
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
    final weekProgressions = _buildWeekProgressions(
        programController.program.weeks, widget.exercise!);

    if (_isValidIndex(weekProgressions, weekIndex, sessionIndex)) {
      final groupedSeries =
          _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
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

  Widget _buildSaveButton(ColorScheme colorScheme) {
    return ElevatedButton(
      onPressed: _handleSave,
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

  Future<void> _handleSave() async {
    final programController = ref.read(trainingProgramControllerProvider);
    final controllers = ref.read(progressionControllersProvider);

    try {
      List<List<WeekProgression>> updatedWeekProgressions = [];

      for (int weekIndex = 0; weekIndex < controllers.length; weekIndex++) {
        List<WeekProgression> weekProgressions = [];
        for (int sessionIndex = 0;
            sessionIndex < controllers[weekIndex].length;
            sessionIndex++) {
          List<Series> updatedSeries = [];

          // Itera attraverso ogni gruppo
          for (int groupIndex = 0;
              groupIndex < controllers[weekIndex][sessionIndex].length;
              groupIndex++) {
            final groupControllers =
                controllers[weekIndex][sessionIndex][groupIndex];
            final sets = int.tryParse(groupControllers.sets.text) ?? 1;

            // Crea il numero corretto di serie per questo gruppo
            for (int i = 0; i < sets; i++) {
              updatedSeries.add(Series(
                serieId: generateRandomId(16).toString(),
                reps: int.tryParse(groupControllers.reps.min.text) ?? 0,
                maxReps: int.tryParse(groupControllers.reps.max.text),
                sets: 1, // Ogni serie individuale ha sets=1
                intensity: groupControllers.intensity.min.text,
                maxIntensity: groupControllers.intensity.max.text.isNotEmpty
                    ? groupControllers.intensity.max.text
                    : null,
                rpe: groupControllers.rpe.min.text,
                maxRpe: groupControllers.rpe.max.text.isNotEmpty
                    ? groupControllers.rpe.max.text
                    : null,
                weight:
                    double.tryParse(groupControllers.weight.min.text) ?? 0.0,
                maxWeight: double.tryParse(groupControllers.weight.max.text),
                order: updatedSeries.length + 1,
                done: false,
                reps_done: 0,
                weight_done: 0.0,
              ));
            }
          }

          weekProgressions.add(WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: sessionIndex + 1,
            series: updatedSeries,
          ));
        }
        updatedWeekProgressions.add(weekProgressions);
      }

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

  List<List<WeekProgression>> _buildWeekProgressions(
      List<Week> weeks, Exercise exercise) {
    return List.generate(weeks.length, (weekIndex) {
      final week = weeks[weekIndex];
      return week.workouts.map((workout) {
        final exerciseInWorkout = workout.exercises.firstWhere(
          (e) => e.exerciseId == exercise.exerciseId,
          orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
        );

        final existingProgressions = exerciseInWorkout.weekProgressions;
        WeekProgression? sessionProgression;
        if (existingProgressions.isNotEmpty &&
            existingProgressions.length > weekIndex) {
          sessionProgression = existingProgressions[weekIndex].firstWhere(
            (progression) => progression.sessionNumber == workout.order,
            orElse: () => WeekProgression(
                weekNumber: weekIndex + 1,
                sessionNumber: workout.order,
                series: []),
          );
        }

        if (sessionProgression?.series.isNotEmpty == true) {
          return sessionProgression!;
        } else {
          final groupedSeries = _groupSeries(exerciseInWorkout.series);
          return WeekProgression(
            weekNumber: weekIndex + 1,
            sessionNumber: workout.order,
            series: groupedSeries.map((group) {
              final firstSeries = group.first;
              return Series(
                serieId: firstSeries.serieId,
                reps: firstSeries.reps,
                maxReps: firstSeries.maxReps,
                sets: group.length,
                intensity: firstSeries.intensity,
                maxIntensity: firstSeries.maxIntensity,
                rpe: firstSeries.rpe,
                maxRpe: firstSeries.maxRpe,
                weight: firstSeries.weight,
                maxWeight: firstSeries.maxWeight,
                order: firstSeries.order,
                done: firstSeries.done,
                reps_done: firstSeries.reps_done,
                weight_done: firstSeries.weight_done,
              );
            }).toList(),
          );
        }
      }).toList();
    });
  }

  bool _isValidIndex(List list, int index1, [int? index2, int? index3]) {
    return index1 >= 0 &&
        index1 < list.length &&
        (index2 == null || (index2 >= 0 && index2 < list[index1].length)) &&
        (index3 == null ||
            (index3 >= 0 && index3 < list[index1][index2].length));
  }

  void _updateProgressionsWithNewSeries(
      List<List<WeekProgression>> weekProgressions) {
    ref
        .read(trainingProgramControllerProvider)
        .updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);
  }

  void _showCombinedLoadDialog(
    int weekIndex,
    int sessionIndex,
    int groupIndex,
    ProgressionControllers controllers,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              padding: EdgeInsets.all(AppTheme.spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carico',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  // 1RM% Fields
                  Text(
                    '1RM%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllers.intensity.min,
                          decoration: const InputDecoration(
                            labelText: 'Minimo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            setModalState(() {
                              _updateSeriesWithRealTimeCalculations(
                                  weekIndex,
                                  sessionIndex,
                                  groupIndex,
                                  'Intensity',
                                  value,
                                  controllers.intensity.max.text);
                            });
                          },
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing.md),
                      Expanded(
                        child: TextField(
                          controller: controllers.intensity.max,
                          decoration: const InputDecoration(
                            labelText: 'Massimo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            setModalState(() {
                              _updateSeriesWithRealTimeCalculations(
                                  weekIndex,
                                  sessionIndex,
                                  groupIndex,
                                  'Intensity',
                                  controllers.intensity.min.text,
                                  value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  // RPE Fields
                  Text(
                    'RPE',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllers.rpe.min,
                          decoration: const InputDecoration(
                            labelText: 'Minimo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            setModalState(() {
                              _updateSeriesWithRealTimeCalculations(
                                  weekIndex,
                                  sessionIndex,
                                  groupIndex,
                                  'RPE',
                                  value,
                                  controllers.rpe.max.text);
                            });
                          },
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing.md),
                      Expanded(
                        child: TextField(
                          controller: controllers.rpe.max,
                          decoration: const InputDecoration(
                            labelText: 'Massimo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            setModalState(() {
                              _updateSeriesWithRealTimeCalculations(
                                  weekIndex,
                                  sessionIndex,
                                  groupIndex,
                                  'RPE',
                                  controllers.rpe.min.text,
                                  value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  // Weight Fields
                  Text(
                    'Weight',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllers.weight.min,
                          decoration: const InputDecoration(
                            labelText: 'Minimo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            setModalState(() {
                              _updateSeriesWithRealTimeCalculations(
                                  weekIndex,
                                  sessionIndex,
                                  groupIndex,
                                  'Weight',
                                  value,
                                  controllers.weight.max.text);
                            });
                          },
                        ),
                      ),
                      SizedBox(width: AppTheme.spacing.md),
                      Expanded(
                        child: TextField(
                          controller: controllers.weight.max,
                          decoration: const InputDecoration(
                            labelText: 'Massimo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            setModalState(() {
                              _updateSeriesWithRealTimeCalculations(
                                  weekIndex,
                                  sessionIndex,
                                  groupIndex,
                                  'Weight',
                                  controllers.weight.min.text,
                                  value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppTheme.spacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        setState(
                            () {}); // Forza l'aggiornamento dell'UI principale
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                      ),
                      child: const Text('Conferma'),
                    ),
                  ),
                  SizedBox(
                      height: MediaQuery.of(dialogContext).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class RangeEditDialog extends StatefulWidget {
  final String title;
  final String initialMin;
  final String initialMax;
  final Function(String?, String?) onSave;
  final Function(String?, String?) onChanged;

  const RangeEditDialog({
    super.key,
    required this.title,
    required this.initialMin,
    required this.initialMax,
    required this.onSave,
    required this.onChanged,
  });

  @override
  State<RangeEditDialog> createState() => _RangeEditDialogState();
}

class _RangeEditDialogState extends State<RangeEditDialog> {
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.initialMin);
    _maxController = TextEditingController(text: widget.initialMax);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit ${widget.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minController,
              decoration: InputDecoration(labelText: 'Minimum ${widget.title}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                widget.onChanged(value, _maxController.text);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _maxController,
              decoration: InputDecoration(labelText: 'Maximum ${widget.title}'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                widget.onChanged(_minController.text, value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final min = _minController.text.trim();
                  final max = _maxController.text.trim();
                  widget.onSave(
                      min.isNotEmpty ? min : null, max.isNotEmpty ? max : null);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }
}
