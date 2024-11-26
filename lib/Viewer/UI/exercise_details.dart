import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:numberpicker/numberpicker.dart';
import '../models/timer_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alphanessone/Main/app_theme.dart';

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
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => _hideKeyboard(context),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSeriesIndicator(theme, colorScheme),
                  SizedBox(height: AppTheme.spacing.lg),
                  if (currentSeries != null) ...[
                    _buildInputFields(theme, colorScheme, currentExercise, currentSeries),
                    SizedBox(height: AppTheme.spacing.lg),
                  ],
                  SizedBox(height: AppTheme.spacing.xl),
                  if (currentSuperSetExerciseIndex < widget.superSetExercises.length - 1)
                    _buildNextExerciseIndicator(theme, colorScheme),
                  SizedBox(height: AppTheme.spacing.xl),
                  _buildRestTimeSelector(theme, colorScheme),
                  SizedBox(height: AppTheme.spacing.xl),
                  _buildEmomSwitch(theme, colorScheme),
                  SizedBox(height: AppTheme.spacing.xxl),
                  if (currentSeries != null)
                    _buildNextButton(theme, colorScheme, currentExercise, currentSeries),
                  SizedBox(height: AppTheme.spacing.lg),
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
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        children: [
          Text(
            widget.superSetExercises.length > 1
                ? 'Super Set ${currentSeriesIndex + 1}'
                : 'Set ${currentSeriesIndex + 1} / ${widget.seriesList.length}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.superSetExercises.length > 1) ...[
            SizedBox(height: AppTheme.spacing.sm),
            Text(
              'Exercise ${currentSuperSetExerciseIndex + 1}/${widget.superSetExercises.length}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextExerciseIndicator(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_forward,
            color: colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Text(
            widget.superSetExercises[currentSuperSetExerciseIndex + 1]['name'],
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      children: [
        Expanded(
          child: _buildInputField(
            theme,
            'REPS',
            _repsControllers[currentExercise['id']]![currentSeries['id']]!,
            TextInputType.number,
            FilteringTextInputFormatter.digitsOnly,
            colorScheme,
            icon: Icons.repeat,
          ),
        ),
        SizedBox(width: AppTheme.spacing.md),
        Expanded(
          child: _buildInputField(
            theme,
            'WEIGHT (kg)',
            _weightControllers[currentExercise['id']]![currentSeries['id']]!,
            const TextInputType.numberWithOptions(decimal: true),
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
            colorScheme,
            icon: Icons.fitness_center,
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
    IconData? icon,
    bool isEnabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: TextField(
        controller: controller,
        enabled: isEnabled,
        keyboardType: keyboardType,
        inputFormatters: [inputFormatter],
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          prefixIcon: icon != null 
              ? Icon(icon, color: colorScheme.onSurfaceVariant)
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: AppTheme.spacing.lg,
            horizontal: AppTheme.spacing.md,
          ),
        ),
      ),
    );
  }

  Widget _buildRestTimeSelector(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Column(
        children: [
          Text(
            'Rest Time',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppTheme.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNumberPickerWithLabel(
                theme,
                'Minutes',
                _minutes,
                0,
                59,
                (value) => setState(() => _minutes = value),
                colorScheme,
              ),
              SizedBox(width: AppTheme.spacing.md),
              _buildNumberPickerWithLabel(
                theme,
                'Seconds',
                _seconds,
                0,
                59,
                (value) => setState(() => _seconds = value),
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmomSwitch(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'EMOM Mode',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch(
            value: _isEmomMode,
            onChanged: (value) => setState(() => _isEmomMode = value),
            activeColor: colorScheme.primary,
            activeTrackColor: colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> currentExercise,
    Map<String, dynamic> currentSeries,
  ) {
    return ElevatedButton(
      onPressed: () async {
        await _updateSeriesData(
          currentExercise['id'],
          currentSeries['id'],
          int.tryParse(_repsControllers[currentExercise['id']]![currentSeries['id']]!.text),
          _weightControllers[currentExercise['id']]![currentSeries['id']]!.text,
        );
        _moveToNextExercise();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.spacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radii.md),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'NEXT',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Icon(
            Icons.arrow_forward,
            color: colorScheme.onPrimary,
          ),
        ],
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
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppTheme.spacing.sm),
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
        borderRadius: BorderRadius.circular(AppTheme.radii.md),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: AppTheme.elevations.small,
      ),
      child: NumberPicker(
        value: value,
        minValue: minValue,
        maxValue: maxValue,
        onChanged: onChanged,
        itemHeight: 45,
        textStyle: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        selectedTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
            ),
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
            ),
          ),
        ),
      ),
    );
  }
}