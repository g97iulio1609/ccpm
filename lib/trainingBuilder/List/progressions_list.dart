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

// Utility function for number formatting
String formatNumber(dynamic value) {
  if (value == null) return '';
  if (value is int) return value.toString();
  if (value is double) {
    return value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
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

class ProgressionControllersNotifier extends StateNotifier<List<List<List<ProgressionControllers>>>> {
  ProgressionControllersNotifier() : super([]);

  void initialize(List<List<WeekProgression>> weekProgressions) {
    state = weekProgressions.map((week) => 
      week.map((session) => 
        _groupSeries(session.series).map((_) => ProgressionControllers()).toList()
      ).toList()
    ).toList();

    for (int weekIndex = 0; weekIndex < weekProgressions.length; weekIndex++) {
      for (int sessionIndex = 0; sessionIndex < weekProgressions[weekIndex].length; sessionIndex++) {
        final groupedSeries = _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
        for (int groupIndex = 0; groupIndex < groupedSeries.length; groupIndex++) {
          updateControllers(weekIndex, sessionIndex, groupIndex, groupedSeries[groupIndex].first);
        }
      }
    }
  }

  void updateControllers(int weekIndex, int sessionIndex, int groupIndex, Series series) {
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

  bool _isValidIndex(List<List<List<ProgressionControllers>>> list, int weekIndex, [int? sessionIndex, int? groupIndex]) {
    return weekIndex >= 0 && weekIndex < list.length &&
           (sessionIndex == null || (sessionIndex >= 0 && sessionIndex < list[weekIndex].length)) &&
           (groupIndex == null || (groupIndex >= 0 && groupIndex < list[weekIndex][sessionIndex!].length));
  }

  static List<List<Series>> _groupSeries(List<Series> series) {
    final groupedSeries = <List<Series>>[];
    for (final s in series) {
      if (groupedSeries.isEmpty || !_isSameGroup(s, groupedSeries.last.first)) {
        groupedSeries.add([s]);
      } else {
        groupedSeries.last.add(s);
      }
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

final progressionControllersProvider = StateNotifierProvider<ProgressionControllersNotifier, List<List<List<ProgressionControllers>>>>((ref) {
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

class _ProgressionsListState extends ConsumerState<ProgressionsList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isSwipeInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeControllers());
  }

  void _initializeControllers() {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);
    ref.read(progressionControllersProvider.notifier).initialize(weekProgressions);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final programController = ref.watch(trainingProgramControllerProvider);
    final controllers = ref.watch(progressionControllersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);

    if (controllers.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(progressionControllersProvider.notifier).initialize(weekProgressions);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: weekProgressions.length,
                itemBuilder: (context, weekIndex) {
                  return weekIndex < controllers.length
                      ? _buildWeekItem(weekIndex, weekProgressions[weekIndex], controllers[weekIndex], colorScheme)
                      : const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSaveButton(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekItem(int weekIndex, List<WeekProgression> weekProgression, List<List<ProgressionControllers>> weekControllers, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            'Week ${weekIndex + 1}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ...weekProgression.asMap().entries.map((entry) {
          final sessionIndex = entry.key;
          final session = entry.value;
          return _buildSessionItem(weekIndex, sessionIndex, session, weekControllers[sessionIndex], colorScheme);
        }),
      ],
    );
  }

  Widget _buildSessionItem(int weekIndex, int sessionIndex, WeekProgression session, List<ProgressionControllers> sessionControllers, ColorScheme colorScheme) {
    final groupedSeries = _groupSeries(session.series);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            'Session ${sessionIndex + 1}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        ...groupedSeries.asMap().entries.map((entry) {
          final groupIndex = entry.key;
          final seriesGroup = entry.value;
          return _buildSeriesItem(weekIndex, sessionIndex, groupIndex, seriesGroup, sessionControllers[groupIndex], colorScheme);
        }),
      ],
    );
  }

  Widget _buildSeriesItem(int weekIndex, int sessionIndex, int groupIndex, List<Series> seriesGroup, ProgressionControllers controllers, ColorScheme colorScheme) {
    return GestureDetector(
      onHorizontalDragStart: (_) => setState(() => _isSwipeInProgress = true),
      onHorizontalDragEnd: (_) => setState(() => _isSwipeInProgress = false),
      onHorizontalDragCancel: () => setState(() => _isSwipeInProgress = false),
      child: Slidable(
        key: ValueKey('$weekIndex-$sessionIndex-$groupIndex'),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _addSeriesGroup(weekIndex, sessionIndex, groupIndex),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.add,
              label: 'Add',
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _removeSeriesGroup(weekIndex, sessionIndex, groupIndex),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: AbsorbPointer(
          absorbing: _isSwipeInProgress,
          child: Container(
            color: colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeriesFields(weekIndex, sessionIndex, groupIndex, seriesGroup.first, controllers),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesFields(int weekIndex, int sessionIndex, int groupIndex, Series series, ProgressionControllers controllers) {
    return Row(
      children: [
        _buildRangeField(
          controllers.reps,
          'Reps',
          () => _showRangeDialog(weekIndex, sessionIndex, groupIndex, 'Reps', controllers.reps),
        ),
        _buildTextField(
          controller: controllers.sets,
          labelText: 'Sets',
          keyboardType: TextInputType.number,
          onChanged: (value) => _updateSeries(weekIndex, sessionIndex, groupIndex, sets: value),
        ),
        _buildRangeField(
          controllers.intensity,
          '1RM%',
          () => _showRangeDialog(weekIndex, sessionIndex, groupIndex, 'Intensity', controllers.intensity),
        ),
        _buildRangeField(
          controllers.rpe,
          'RPE',
          () => _showRangeDialog(weekIndex, sessionIndex, groupIndex, 'RPE', controllers.rpe),
        ),
        _buildRangeField(
          controllers.weight,
          'Weight',
          () => _showRangeDialog(weekIndex, sessionIndex, groupIndex, 'Weight', controllers.weight),
        ),
      ],
    );
  }

  Widget _buildRangeField(RangeControllers controllers, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white70),
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            controllers.displayText,
textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required TextInputType keyboardType,
    required Function(String) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: const TextStyle(color: Colors.white70),
            alignLabelWithHint: true,
            filled: true,
            fillColor: colorScheme.surface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withOpacity(0.12),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            final formattedValue = formatNumber(value);
            if (formattedValue != value) {
              controller.text = formattedValue;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: formattedValue.length),
              );
            }
            onChanged(formattedValue);
          },
        ),
      ),
    );
  }

  void _showRangeDialog(int weekIndex, int sessionIndex, int groupIndex, String title, RangeControllers controllers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext dialogContext) {
        return RangeEditDialog(
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
    final controllers = ref.read(progressionControllersProvider)[weekIndex][sessionIndex][groupIndex];

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

  void _updateWeightFromIntensity(ProgressionControllers controllers, String min, String max) {
    final minIntensity = double.tryParse(min) ?? 0;
    final minWeight = SeriesUtils.calculateWeightFromIntensity(widget.latestMaxWeight.toDouble(), minIntensity);
    controllers.weight.min.text = SeriesUtils.roundWeight(minWeight, widget.exercise!.type).toStringAsFixed(1);

    if (max.isNotEmpty) {
      final maxIntensity = double.tryParse(max) ?? 0;
      final maxWeight = SeriesUtils.calculateWeightFromIntensity(widget.latestMaxWeight.toDouble(), maxIntensity);
      controllers.weight.max.text = SeriesUtils.roundWeight(maxWeight, widget.exercise!.type).toStringAsFixed(1);
    } else {
      controllers.weight.max.text = '';
    }
  }

  void _updateIntensityFromWeight(ProgressionControllers controllers, String min, String max) {
    final minWeight = double.tryParse(min) ?? 0;
    final minIntensity = SeriesUtils.calculateIntensityFromWeight(minWeight, widget.latestMaxWeight);
    controllers.intensity.min.text = minIntensity.toStringAsFixed(1);

    if (max.isNotEmpty) {
      final maxWeight = double.tryParse(max) ?? 0;
      final maxIntensity = SeriesUtils.calculateIntensityFromWeight(maxWeight, widget.latestMaxWeight);
      controllers.intensity.max.text = maxIntensity.toStringAsFixed(1);
    } else {
      controllers.intensity.max.text = '';
    }
  }

  void _updateSeries(int weekIndex, int sessionIndex, int groupIndex, {
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
    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);

    if (_isValidIndex(weekProgressions, weekIndex, sessionIndex)) {
      final groupedSeries = _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        final updatedGroup = groupedSeries[groupIndex].map((series) {
          return series.copyWith(
            reps: reps != null ? int.tryParse(reps) ?? series.reps : series.reps,
            maxReps: maxReps?.isEmpty == true ? null : int.tryParse(maxReps!),
            sets: sets != null ? int.tryParse(sets) ?? series.sets : series.sets,
            intensity: intensity?.isEmpty == true ? null : intensity,
            maxIntensity: maxIntensity?.isEmpty == true ? null : maxIntensity,
            rpe: rpe?.isEmpty == true ? null : rpe,
            maxRpe: maxRpe?.isEmpty == true ? null : maxRpe,
            weight: weight != null ? double.tryParse(weight) ?? series.weight : series.weight,
            maxWeight: maxWeight?.isEmpty == true ? null : double.tryParse(maxWeight!),
          );
        }).toList();

        groupedSeries[groupIndex] = updatedGroup;
        weekProgressions[weekIndex][sessionIndex].series = groupedSeries.expand((group) => group).toList();
        _updateProgressionsWithNewSeries(weekProgressions);
        
        final controllers = ref.read(progressionControllersProvider.notifier);
        controllers.updateControllers(weekIndex, sessionIndex, groupIndex, updatedGroup.first);
        
        setState(() {});
      }
    }
  }

  void _addSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);
    final controllersNotifier = ref.read(progressionControllersProvider.notifier);

    if (_isValidIndex(weekProgressions, weekIndex, sessionIndex)) {
      final currentSession = weekProgressions[weekIndex][sessionIndex];
      final groupedSeries = _groupSeries(currentSession.series);

      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        final newSeries = Series(
          serieId: generateRandomId(16).toString(),
          reps: 0,
          sets: 1,
          intensity: '',
          rpe: '',
          weight: 0.0,
          order: groupedSeries.length + 1,
          done: false,
          reps_done: 0,
          weight_done: 0.0,
        );

        groupedSeries.insert(groupIndex + 1, [newSeries]);
        currentSession.series = groupedSeries.expand((group) => group).toList();
        _updateProgressionsWithNewSeries(weekProgressions);
        controllersNotifier.addControllers(weekIndex, sessionIndex, groupIndex + 1);
        setState(() {});
      }
    }
  }

  void _removeSeriesGroup(int weekIndex, int sessionIndex, int groupIndex) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);

    if (_isValidIndex(weekProgressions, weekIndex, sessionIndex)) {
      final groupedSeries = _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        groupedSeries.removeAt(groupIndex);
        weekProgressions[weekIndex][sessionIndex].series = groupedSeries.expand((group) => group).toList();
        _updateProgressionsWithNewSeries(weekProgressions);
        ref.read(progressionControllersProvider.notifier).removeControllers(weekIndex, sessionIndex, groupIndex);
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
        for (int sessionIndex = 0; sessionIndex < controllers[weekIndex].length; sessionIndex++) {
          List<Series> updatedSeries = [];
          for (int groupIndex = 0; groupIndex < controllers[weekIndex][sessionIndex].length; groupIndex++) {
            final groupControllers = controllers[weekIndex][sessionIndex][groupIndex];
            final sets = int.tryParse(groupControllers.sets.text) ?? 1;
            
            for (int i = 0; i < sets; i++) {
              updatedSeries.add(Series(
                serieId: generateRandomId(16).toString(),
                reps: int.tryParse(groupControllers.reps.min.text) ?? 0,
                maxReps: int.tryParse(groupControllers.reps.max.text),
                sets: 1,
                intensity: groupControllers.intensity.min.text,
                maxIntensity: groupControllers.intensity.max.text.isNotEmpty ? groupControllers.intensity.max.text : null,
                rpe: groupControllers.rpe.min.text,
                maxRpe: groupControllers.rpe.max.text.isNotEmpty ? groupControllers.rpe.max.text : null,
                weight: double.tryParse(groupControllers.weight.min.text) ?? 0.0,
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
      
      programController.updateWeekProgressions(updatedWeekProgressions, widget.exercise!.exerciseId!);
      
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

  List<List<WeekProgression>> _buildWeekProgressions(List<Week> weeks, Exercise exercise) {
    return List.generate(weeks.length, (weekIndex) {
      final week = weeks[weekIndex];
      return week.workouts.map((workout) {
        final exerciseInWorkout = workout.exercises.firstWhere(
          (e) => e.exerciseId == exercise.exerciseId,
          orElse: () => Exercise(name: '', type: '', variant: '', order: 0),
        );

        final existingProgressions = exerciseInWorkout.weekProgressions;
        WeekProgression? sessionProgression;
        if (existingProgressions.isNotEmpty && existingProgressions.length > weekIndex) {
          sessionProgression = existingProgressions[weekIndex].firstWhere(
            (progression) => progression.sessionNumber == workout.order,
            orElse: () => WeekProgression(weekNumber: weekIndex + 1, sessionNumber: workout.order, series: []),
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

  List<List<Series>> _groupSeries(List<Series> series) {
    final groupedSeries = <List<Series>>[];
    for (final s in series) {
      if (groupedSeries.isEmpty || !_isSameGroup(s, groupedSeries.last.first)) {
        groupedSeries.add([s]);
      } else {
        groupedSeries.last.add(s);
      }
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

  bool _isValidIndex(List list, int index1, [int? index2, int? index3]) {
    return index1 >= 0 && index1 < list.length &&
           (index2 == null || (index2 >= 0 && index2 < list[index1].length)) &&
           (index3 == null || (index3 >= 0 && index3 < list[index1][index2].length));
  }

  void _updateProgressionsWithNewSeries(List<List<WeekProgression>> weekProgressions) {
    ref.read(trainingProgramControllerProvider).updateWeekProgressions(weekProgressions, widget.exercise!.exerciseId!);
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
  _RangeEditDialogState createState() => _RangeEditDialogState();
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                widget.onChanged(value, _maxController.text);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _maxController,
              decoration: InputDecoration(labelText: 'Maximum ${widget.title}'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  widget.onSave(min.isNotEmpty ? min : null, max.isNotEmpty ? max : null);
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