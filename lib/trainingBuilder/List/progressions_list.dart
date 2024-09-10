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

final progressionControllersProvider = StateNotifierProvider<ProgressionControllersNotifier, List<List<List<ProgressionControllers>>>>((ref) {
  return ProgressionControllersNotifier();
});

class ProgressionControllers {
  final TextEditingController reps;
  final TextEditingController sets;
  final TextEditingController intensity;
  final TextEditingController rpe;
  final TextEditingController weight;
  final FocusNode repsFocusNode;
  final FocusNode setsFocusNode;
  final FocusNode intensityFocusNode;
  final FocusNode rpeFocusNode;
  final FocusNode weightFocusNode;

  ProgressionControllers({
    required this.reps,
    required this.sets,
    required this.intensity,
    required this.rpe,
    required this.weight,
    FocusNode? repsFocusNode,
    FocusNode? setsFocusNode,
    FocusNode? intensityFocusNode,
    FocusNode? rpeFocusNode,
    FocusNode? weightFocusNode,
  }) : repsFocusNode = repsFocusNode ?? FocusNode(),
       setsFocusNode = setsFocusNode ?? FocusNode(),
       intensityFocusNode = intensityFocusNode ?? FocusNode(),
       rpeFocusNode = rpeFocusNode ?? FocusNode(),
       weightFocusNode = weightFocusNode ?? FocusNode();

  void dispose() {
    for (var controller in [reps, sets, intensity, rpe, weight]) {
      controller.dispose();
    }
    for (var node in [repsFocusNode, setsFocusNode, intensityFocusNode, rpeFocusNode, weightFocusNode]) {
      node.dispose();
    }
  }
}

class ProgressionControllersNotifier extends StateNotifier<List<List<List<ProgressionControllers>>>> {
  ProgressionControllersNotifier() : super([]);

  void initialize(List<List<WeekProgression>> weekProgressions) {
    state = weekProgressions.map((week) => 
      week.map((session) => 
        _groupSeries(session.series).map((group) => ProgressionControllers(
          reps: TextEditingController(text: _formatRangeValue(group.first.reps, group.first.maxReps)),
          sets: TextEditingController(text: group.length.toString()),
          intensity: TextEditingController(text: _formatRangeValue(group.first.intensity, group.first.maxIntensity)),
          rpe: TextEditingController(text: _formatRangeValue(group.first.rpe, group.first.maxRpe)),
          weight: TextEditingController(text: _formatRangeValue(group.first.weight, group.first.maxWeight)),
        )).toList()
      ).toList()
    ).toList();
  }

  void updateControllers(int weekIndex, int sessionIndex, int groupIndex, Series series) {
    if (_isValidIndex(state, weekIndex, sessionIndex, groupIndex)) {
      final controllers = state[weekIndex][sessionIndex][groupIndex];
      controllers.reps.text = _formatRangeValue(series.reps, series.maxReps);
      controllers.sets.text = series.sets.toString();
      controllers.intensity.text = _formatRangeValue(series.intensity, series.maxIntensity);
      controllers.rpe.text = _formatRangeValue(series.rpe, series.maxRpe);
      controllers.weight.text = _formatRangeValue(series.weight, series.maxWeight);
      state = [...state];
    }
  }

  void addControllers(int weekIndex, int sessionIndex, int groupIndex, Series series) {
    if (_isValidIndex(state, weekIndex, sessionIndex)) {
      final newControllers = ProgressionControllers(
        reps: TextEditingController(text: _formatRangeValue(series.reps, series.maxReps)),
        sets: TextEditingController(text: series.sets.toString()),
        intensity: TextEditingController(text: _formatRangeValue(series.intensity, series.maxIntensity)),
        rpe: TextEditingController(text: _formatRangeValue(series.rpe, series.maxRpe)),
        weight: TextEditingController(text: _formatRangeValue(series.weight, series.maxWeight)),
      );
      
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

  static String _formatRangeValue(dynamic value, dynamic maxValue) {
    if (maxValue != null && maxValue != value && maxValue != 0) {
      return '$value/$maxValue';
    }
    return value.toString();
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
        _buildTextField(
          controller: controllers.reps,
          focusNode: controllers.repsFocusNode,
          labelText: 'Reps',
          keyboardType: TextInputType.text,
          onChanged: (value) => _updateSeries(weekIndex, sessionIndex, groupIndex, reps: value),
        ),
        _buildTextField(
          controller: controllers.sets,
          focusNode: controllers.setsFocusNode,
          labelText: 'Sets',
          keyboardType: TextInputType.text,
          onChanged: (value) => _updateSeries(weekIndex, sessionIndex, groupIndex, sets: value),
        ),
        _buildTextField(
          controller: controllers.intensity,
          focusNode: controllers.intensityFocusNode,
          labelText: '1RM%',
          keyboardType: TextInputType.text,
          onChanged: (value) {
            _updateSeries(weekIndex, sessionIndex, groupIndex, intensity: value);
            _updateWeightFromIntensity(weekIndex, sessionIndex, groupIndex, value);
          },
        ),
        _buildTextField(
          controller: controllers.rpe,
          focusNode: controllers.rpeFocusNode,
          labelText: 'RPE',
          keyboardType: TextInputType.text,
          onChanged: (value) {
            _updateSeries(weekIndex, sessionIndex, groupIndex, rpe: value);
            _updateWeightFromRPE(weekIndex, sessionIndex, groupIndex, value, series.reps);
          },
        ),
        _buildTextField(
          controller: controllers.weight,
          focusNode: controllers.weightFocusNode,
          labelText: 'Weight',
          keyboardType: TextInputType.text,
          onChanged: (value) {
            _updateSeries(weekIndex, sessionIndex, groupIndex, weight: value);
            _updateIntensityFromWeight(weekIndex, sessionIndex, groupIndex, value);
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
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
          focusNode: focusNode,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: const TextStyle(color: Colors.white70),
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
            final cursorPosition = controller.selection.base.offset;
            onChanged(value);
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: cursorPosition),
            );
          },
        ),
      ),
    );
  }

   void _updateSeries(int weekIndex, int sessionIndex, int groupIndex, {String? reps, String? sets, String? intensity, String? rpe, String? weight}) {
    final programController = ref.read(trainingProgramControllerProvider);
    final weekProgressions = _buildWeekProgressions(programController.program.weeks, widget.exercise!);

    if (_isValidIndex(weekProgressions, weekIndex, sessionIndex)) {
      final groupedSeries = _groupSeries(weekProgressions[weekIndex][sessionIndex].series);
      if (groupIndex >= 0 && groupIndex < groupedSeries.length) {
        final updatedGroup = groupedSeries[groupIndex].map((series) {
          final updatedSeries = series.copyWith(
            reps: reps != null ? _parseRangeValue(reps, series.reps) : series.reps,
            maxReps: reps != null ? _parseMaxValue(reps, series.maxReps) : series.maxReps,
            sets: sets != null ? (int.tryParse(sets) ?? series.sets) : series.sets,
            intensity: intensity != null ? _parseRangeValue(intensity, series.intensity) : series.intensity,
            maxIntensity: intensity != null ? _parseMaxValue(intensity, series.maxIntensity) : series.maxIntensity,
            rpe: rpe != null ? _parseRangeValue(rpe, series.rpe) : series.rpe,
            maxRpe: rpe != null ? _parseMaxValue(rpe, series.maxRpe) : series.maxRpe,
            weight: weight != null ? _parseRangeValue(weight, series.weight) : series.weight,
            maxWeight: weight != null ? _parseMaxValue(weight, series.maxWeight) : series.maxWeight,
          );
          return updatedSeries;
        }).toList();

        groupedSeries[groupIndex] = updatedGroup;
        weekProgressions[weekIndex][sessionIndex].series = groupedSeries.expand((group) => group).toList();
        _updateProgressionsWithNewSeries(weekProgressions);
        ref.read(progressionControllersProvider.notifier).updateControllers(weekIndex, sessionIndex, groupIndex, updatedGroup.first);
      }
    }
  }

  dynamic _parseRangeValue(String value, dynamic defaultValue) {
    if (value.isEmpty) return defaultValue;
    final parts = value.split('/');
    if (defaultValue is int) {
      return int.tryParse(parts[0]) ?? defaultValue;
    } else if (defaultValue is double) {
      return double.tryParse(parts[0]) ?? defaultValue;
    } else {
      return parts[0];
    }
  }

  dynamic _parseMaxValue(String value, dynamic defaultValue) {
    final parts = value.split('/');
    if (parts.length > 1) {
      if (defaultValue is int) {
        return int.tryParse(parts[1]) ?? defaultValue;
      } else if (defaultValue is double) {
        return double.tryParse(parts[1]) ?? defaultValue;
      } else {
        return parts[1];
      }
    }
    return null;
  }
  
  void _updateWeightFromIntensity(int weekIndex, int sessionIndex, int groupIndex, String intensity) {
    final controllers = ref.read(progressionControllersProvider);
    if (_isValidIndex(controllers, weekIndex, sessionIndex, groupIndex)) {
      final weightController = controllers[weekIndex][sessionIndex][groupIndex].weight;
      final intensityValues = intensity.split('/').map((v) => double.tryParse(v) ?? 0).toList();
      final calculatedWeights = intensityValues.map((i) => SeriesUtils.calculateWeightFromIntensity(
        widget.latestMaxWeight.toDouble(),
        i,
      )).toList();
      final roundedWeights = calculatedWeights.map((w) => SeriesUtils.roundWeight(w, widget.exercise?.type)).toList();
      weightController.text = roundedWeights.map((w) => w.toStringAsFixed(2)).join('/');
      _updateSeries(weekIndex, sessionIndex, groupIndex, weight: weightController.text);
    }
  }

  void _updateWeightFromRPE(int weekIndex, int sessionIndex, int groupIndex, String rpe, int reps) {
    final controllers = ref.read(progressionControllersProvider);
    if (_isValidIndex(controllers, weekIndex, sessionIndex, groupIndex)) {
      final weightController = controllers[weekIndex][sessionIndex][groupIndex].weight;
      final intensityController = controllers[weekIndex][sessionIndex][groupIndex].intensity;
      final rpeValues = rpe.split('/');
      
      final weights = rpeValues.map((r) {
final rpeDouble = double.tryParse(r) ?? 0;
        final percentage = SeriesUtils.getRPEPercentage(rpeDouble, reps);
        final calculatedWeight = widget.latestMaxWeight.toDouble() * percentage;
        return SeriesUtils.roundWeight(calculatedWeight, widget.exercise?.type ?? '');
      }).toList();

      weightController.text = weights.map((w) => w.toStringAsFixed(2)).join('/');
      
      final intensities = weights.map((w) => 
        SeriesUtils.calculateIntensityFromWeight(w, widget.latestMaxWeight.toDouble())
      ).toList();
      intensityController.text = intensities.map((i) => i.toStringAsFixed(2)).join('/');
      
      _updateSeries(
        weekIndex,
        sessionIndex,
        groupIndex,
        weight: weightController.text,
        intensity: intensityController.text,
      );
    }
  }

  void _updateIntensityFromWeight(int weekIndex, int sessionIndex, int groupIndex, String weight) {
    final controllers = ref.read(progressionControllersProvider);
    if (_isValidIndex(controllers, weekIndex, sessionIndex, groupIndex)) {
      final intensityController = controllers[weekIndex][sessionIndex][groupIndex].intensity;
      final weightValues = weight.split('/').map((w) => double.tryParse(w) ?? 0).toList();
      final calculatedIntensities = weightValues.map((w) => 
        SeriesUtils.calculateIntensityFromWeight(w, widget.latestMaxWeight.toDouble())
      ).toList();
      intensityController.text = calculatedIntensities.map((i) => i.toStringAsFixed(2)).join('/');
      _updateSeries(weekIndex, sessionIndex, groupIndex, intensity: intensityController.text);
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
        controllersNotifier.addControllers(weekIndex, sessionIndex, groupIndex + 1, newSeries);
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
  final repsRange = _parseIntRange(groupControllers.reps.text);
  final intensity = _parseStringRange(groupControllers.intensity.text);
  
  // Parsing rpe e maxRpe separatamente
  final rpeRange = _parseStringRange(groupControllers.rpe.text);
  final rpe = rpeRange.start.toStringAsFixed(2);
  final maxRpe = rpeRange.end != rpeRange.start ? rpeRange.end.toStringAsFixed(2) : null;

  final weightRange = _parseDoubleRange(groupControllers.weight.text);
  debugPrint('Sto salvando rpe:$rpe');

  for (int i = 0; i < sets; i++) {
    updatedSeries.add(Series(
      serieId: generateRandomId(16).toString(),
      reps: repsRange.start.toInt(),
      maxReps: repsRange.end != repsRange.start ? repsRange.end.toInt() : null,
      sets: 1,
      intensity: intensity.start.toStringAsFixed(2),
      maxIntensity: intensity.end != intensity.start ? intensity.end.toStringAsFixed(2) : null,
      
      // Assegna rpe e maxRpe separatamente
      rpe: rpe,
      maxRpe: maxRpe,
      
      weight: weightRange.start,
      maxWeight: weightRange.end != weightRange.start ? weightRange.end : null,
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

RangeValues _parseIntRange(String value) {
    final parts = value.split('/');
    int start = int.tryParse(parts[0]) ?? 0;
    int end = parts.length > 1 ? (int.tryParse(parts[1]) ?? start) : start;
    return RangeValues(start.toDouble(), end.toDouble());
  }

  RangeValues _parseDoubleRange(String value) {
    final parts = value.split('/');
    double start = double.tryParse(parts[0]) ?? 0.0;
    double end = parts.length > 1 ? (double.tryParse(parts[1]) ?? start) : start;
    return RangeValues(start, end);
  }

RangeValues _parseStringRange(String value) {
  final parts = value.split('/');
  double start = double.tryParse(parts[0]) ?? 0.0;
  double end = parts.length > 1 ? double.tryParse(parts[1]) ?? start : start;
  return RangeValues(start, end);
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

        return sessionProgression?.series.isNotEmpty == true
            ? sessionProgression!
            : WeekProgression(
                weekNumber: weekIndex + 1,
                sessionNumber: workout.order,
                series: exerciseInWorkout.series,
              );
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