import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:numberpicker/numberpicker.dart';
import '../models/timer_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentExerciseNameProvider = StateProvider<String>((ref) => '');

class ExerciseDetails extends ConsumerStatefulWidget {
  final String userId;
  final String programId;
  final String weekId;
  final String workoutId;
  final String exerciseId;
  final List<Map<String, dynamic>> superSetExercises;
  final int superSetExerciseIndex;
  final List<Map<String, dynamic>> seriesList;
  final int startIndex;

  const ExerciseDetails({
    super.key,
    required this.userId,
    required this.programId,
    required this.weekId,
    required this.workoutId,
    required this.exerciseId,
    required this.superSetExercises,
    required this.superSetExerciseIndex,
    required this.seriesList,
    required this.startIndex,
  });

  @override
  ConsumerState<ExerciseDetails> createState() => ExerciseDetailsState();
}

class ExerciseDetailsState extends ConsumerState<ExerciseDetails> {
  int currentSeriesIndex = 0;
  int currentSuperSetExerciseIndex = 0;
  final Map<String, Map<String, TextEditingController>> _repsControllers = {};
  final Map<String, Map<String, TextEditingController>> _weightControllers = {};
  int _minutes = 1;
  int _seconds = 0;
  bool _isEmomMode = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _setCurrentSeriesIndex();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentExerciseName();
    });
  }

  void _initControllers() {
    for (final exercise in widget.superSetExercises) {
      _repsControllers[exercise['id']] = {};
      _weightControllers[exercise['id']] = {};
      for (final series in exercise['series']) {
        _repsControllers[exercise['id']]![series['id']] =
            TextEditingController(text: series['reps'].toString());
        _weightControllers[exercise['id']]![series['id']] =
            TextEditingController(text: series['weight'].toString());
      }
    }
  }

  void _setCurrentSeriesIndex() {
    final currentExercise =
        widget.superSetExercises[currentSuperSetExerciseIndex];
    final currentSeriesList = currentExercise['series'];
    currentSeriesIndex = widget.startIndex < currentSeriesList.length
        ? widget.startIndex
        : currentSeriesList.length - 1;
  }

  void _updateCurrentExerciseName() {
    final currentExercise = widget.superSetExercises[currentSuperSetExerciseIndex];
    final exerciseName = '${currentExercise['name']} ${currentExercise['variant'] ?? ''}';
    ref.read(currentExerciseNameProvider.notifier).state = exerciseName;
  }

  Future<void> _updateSeriesData(String exerciseId, String seriesId,
      int? repsDone, String? weightDoneString) async {
    final currentSeries = widget.superSetExercises
        .firstWhere((exercise) => exercise['id'] == exerciseId)['series']
        .firstWhere((series) => series['id'] == seriesId);
    final expectedReps = currentSeries['reps'];
    final expectedWeight = currentSeries['weight'];

    final weightDone = double.tryParse(weightDoneString ?? '');

    final done = (repsDone != null && repsDone >= expectedReps) &&
        (weightDone != null && weightDone >= expectedWeight);

    await FirebaseFirestore.instance.collection('series').doc(seriesId).update({
      'done': done,
      'reps_done': repsDone,
      'weight_done': weightDone,
    });
  }

  Future<void> _navigateToTimer() async {
    if (!mounted) return;

    final result = await context.push<Map<String, dynamic>>(
      '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${widget.exerciseId}/timer',
      extra: TimerModel(
        programId: widget.programId,
        userId: widget.userId,
        seriesList: widget.seriesList,
        weekId: widget.weekId,
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
        currentSeriesIndex: currentSeriesIndex,
        totalSeries: widget.seriesList.length,
        restTime: _getRestTimeInSeconds(),
        isEmomMode: _isEmomMode,
        superSetExerciseIndex: currentSuperSetExerciseIndex,
        superSetExercises: widget.superSetExercises,
      ),
    );

    if (!mounted) return;

    if (result != null) {
      final int nextIndex = result['startIndex'] as int;
      final int superSetIndex = result['superSetExerciseIndex'] as int;

      if (nextIndex >= widget.seriesList.length) {
        context.pop();
      } else {
        setState(() {
          currentSeriesIndex = nextIndex;
          currentSuperSetExerciseIndex = superSetIndex;
        });
      }

      if (nextIndex < widget.seriesList.length) {
        setState(() {
          currentSeriesIndex = nextIndex;
        });
      } else {
        context.go(
          '/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}',
        );
      }
    }
  }

  int _getRestTimeInSeconds() {
    return (_minutes * 60) + _seconds;
  }

  void _hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentExercise =
        widget.superSetExercises[currentSuperSetExerciseIndex];
    final currentSeriesList = currentExercise['series'];
    final currentSeries = currentSeriesIndex < currentSeriesList.length
        ? currentSeriesList[currentSeriesIndex]
        : null;

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _hideKeyboard(context),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSeriesIndicator(theme, colorScheme),
                  const SizedBox(height: 24),
                  if (currentSeries != null) ...[
                    _buildInputFields(
                      theme,
                      colorScheme,
                      currentExercise,
                      currentSeries,
                    ),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 32),
                  if (currentSuperSetExerciseIndex <
                      widget.superSetExercises.length - 1)
                    Text(
                      'Next: ${widget.superSetExercises[currentSuperSetExerciseIndex + 1]['name']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 32),
                  _buildRestTimeSelector(
                    theme,
                    colorScheme,
                    colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  _buildEmomSwitch(theme, colorScheme),
                  const SizedBox(height: 40),
                  if (currentSeries != null)
                    _buildNextButton(
                      theme,
                      colorScheme,
                      colorScheme.primary,
                      currentExercise,
                      currentSeries,
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        widget.superSetExercises.length > 1
            ? 'Super Set ${currentSeriesIndex + 1}'
            : 'Set ${currentSeriesIndex + 1} / ${widget.seriesList.length}',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildInputFields(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> currentExercise,
    Map<String, dynamic> currentSeries,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildInputField(
            theme,
            'REPS',
            _repsControllers[currentExercise['id']]![currentSeries['id']]!,
            TextInputType.number,
            FilteringTextInputFormatter.digitsOnly,
            colorScheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInputField(
            theme,
            'WEIGHT (kg)',
            _weightControllers[currentExercise['id']]![currentSeries['id']]!,
            const TextInputType.numberWithOptions(decimal: true),
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
            colorScheme,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    ThemeData theme,
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    TextInputFormatter inputFormatter,
    ColorScheme colorScheme, {
    bool isEnabled = true,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        enabled: isEnabled,
        keyboardType: keyboardType,
        inputFormatters: [inputFormatter],
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildRestTimeSelector(
    ThemeData theme,
    ColorScheme colorScheme,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNumberPickerWithLabel(
            theme,
            'Minuti',
            _minutes,
            0,
            59,
            (value) => setState(() => _minutes = value),
            colorScheme,
          ),
          const SizedBox(width: 16),
          _buildNumberPickerWithLabel(
            theme,
            'Secondi',
            _seconds,
            0,
            59,
            (value) => setState(() => _seconds = value),
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPicker(
    ThemeData theme,
    int value,
    int minValue,
    int maxValue,
    ValueChanged<int> onChanged,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: 90,
      height: 130,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white,
          width: 0.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: NumberPicker(
        value: value,
        minValue: minValue,
        maxValue: maxValue,
        onChanged: onChanged,
        itemHeight: 45,
        textStyle: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
selectedTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withOpacity(0.2),
            ),
            bottom: BorderSide(
              color: colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberPickerWithLabel(
    ThemeData theme,
    String label,
    int value,
    int minValue,
    int maxValue,
    ValueChanged<int> onChanged,
    ColorScheme colorScheme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _buildNumberPicker(
          theme,
          value,
          minValue,
          maxValue,
          onChanged,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildEmomSwitch(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'EMOM Mode',
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 20),
        Switch(
          value: _isEmomMode,
          onChanged: (value) => setState(() => _isEmomMode = value),
          activeColor: colorScheme.primary,
          activeTrackColor: colorScheme.primary.withOpacity(0.5),
          inactiveThumbColor: colorScheme.onSurface.withOpacity(0.5),
          inactiveTrackColor: colorScheme.onSurface.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildNextButton(
    ThemeData theme,
    ColorScheme colorScheme,
    Color primaryColor,
    Map<String, dynamic> currentExercise,
    Map<String, dynamic> currentSeries,
  ) {
    return ElevatedButton(
      onPressed: () async {
        await _updateSeriesData(
          currentExercise['id'],
          currentSeries['id'],
          int.tryParse(
              _repsControllers[currentExercise['id']]![currentSeries['id']]!
                  .text),
          _weightControllers[currentExercise['id']]![currentSeries['id']]!.text,
        );
        _moveToNextExercise();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Text(
        'NEXT',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.black,
        ),
      ),
    );
  }

  void _moveToNextExercise() {
    setState(() {
      if (currentSuperSetExerciseIndex < widget.superSetExercises.length - 1) {
        currentSuperSetExerciseIndex++;
      } else {
        currentSuperSetExerciseIndex = 0;
        currentSeriesIndex++;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCurrentExerciseName();
    });

    if (currentSuperSetExerciseIndex == 0) {
      _navigateToTimer();
    }
  }

  @override
  void dispose() {
    for (final controllers in _repsControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    for (final controllers in _weightControllers.values) {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}