import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:numberpicker/numberpicker.dart';

class ExerciseDetails extends StatefulWidget {
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
  _ExerciseDetailsState createState() => _ExerciseDetailsState();
}

class _ExerciseDetailsState extends State<ExerciseDetails> {
  int currentSeriesIndex = 0;
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
        widget.superSetExercises[widget.superSetExerciseIndex];
    final currentSeriesList = currentExercise['series'];
    currentSeriesIndex = widget.startIndex < currentSeriesList.length
        ? widget.startIndex
        : currentSeriesList.length - 1;
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

  int _getRestTimeInSeconds() {
    return (_minutes * 60) + _seconds;
  }

  double? _getNextSeriesWeight(int index) {
    final currentExercise = widget.superSetExercises[index];
    final currentSeriesList = currentExercise['series'];
    if (currentSeriesIndex < currentSeriesList.length - 1) {
      final nextSeries = currentSeriesList[currentSeriesIndex + 1];
      return nextSeries['weight'].toDouble();
    }
    return null;
  }

Future<void> _handleNextSeries() async {
  final restTimeInSeconds = _getRestTimeInSeconds();
  final currentExercise = widget.superSetExercises[widget.superSetExerciseIndex];
  final currentSeriesList = currentExercise['series'];

  if (widget.superSetExerciseIndex < widget.superSetExercises.length - 1) {
    // Passa all'esercizio successivo
    final nextExerciseIndex = widget.superSetExerciseIndex + 1;
    final nextExercise = widget.superSetExercises[nextExerciseIndex];
    final nextSeriesList = nextExercise['series'];
    final nextSeriesIndex = currentSeriesIndex < nextSeriesList.length ? currentSeriesIndex : 0;
    final result = await context.push<Map<String, dynamic>>(
      '/programs_screen/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${nextExercise['id']}?currentSeriesIndex=$nextSeriesIndex&totalSeries=${nextSeriesList.length}&restTime=$restTimeInSeconds&isEmomMode=$_isEmomMode&superSetExerciseIndex=$nextExerciseIndex',
      extra: {
        'superSetExercises': widget.superSetExercises,
        'superSetExerciseIndex': nextExerciseIndex,
        'seriesList': nextSeriesList,
        'startIndex': nextSeriesIndex,
      },
    );
    if (result != null) {
      setState(() {
        currentSeriesIndex = result['startIndex'];
      });
    }
  } else {
    // Passa alla serie successiva del primo esercizio
    final nextSeriesIndex = currentSeriesIndex + 1;
    if (nextSeriesIndex < currentSeriesList.length) {
      final result = await context.push<Map<String, dynamic>>(
        '/programs_screen/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${widget.workoutId}/exercise_details/${widget.exerciseId}?currentSeriesIndex=$nextSeriesIndex&totalSeries=${currentSeriesList.length}&restTime=$restTimeInSeconds&isEmomMode=$_isEmomMode&superSetExerciseIndex=0',
        extra: {
          'superSetExercises': widget.superSetExercises,
          'superSetExerciseIndex': 0,
          'seriesList': widget.superSetExercises[0]['series'],
          'startIndex': nextSeriesIndex,
        },
      );
      if (result != null) {
        setState(() {
          currentSeriesIndex = result['startIndex'];
        });
      }
    } else {
      // Tutte le serie di tutti gli esercizi sono state completate
      context.pop();
    }
  }
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
  final currentExercise = widget.superSetExercises[widget.superSetExerciseIndex];
  final currentSeriesList = currentExercise['series'];
  final currentSeries = currentSeriesIndex < currentSeriesList.length
      ? currentSeriesList[currentSeriesIndex]
      : null;

  return Scaffold(
    backgroundColor: theme.colorScheme.background,
    body: SafeArea(
      child: GestureDetector(
        onTap: () => _hideKeyboard(context),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
                _buildSeriesIndicator(theme),
                const SizedBox(height: 16),
                _buildCurrentExerciseIndicator(theme),
                const SizedBox(height: 32),
                if (currentSeries != null) ...[
                  _buildInputField(
                    theme,
                    'REPS',
                    _repsControllers[currentExercise['id']]![currentSeries['id']]!,
                    TextInputType.number,
                    FilteringTextInputFormatter.digitsOnly,
                  ),
                  const SizedBox(height: 24),
                  _buildInputField(
                    theme,
                    'WEIGHT (kg)',
                    _weightControllers[currentExercise['id']]![currentSeries['id']]!,
                    const TextInputType.numberWithOptions(decimal: true),
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (widget.superSetExerciseIndex <
                      widget.superSetExercises.length - 1)
                    Text(
                      'Next: ${widget.superSetExercises[widget.superSetExerciseIndex + 1]['name']}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 32),
                  _buildRestTimeSelector(theme),
                  const SizedBox(height: 32),
                  _buildEmomSwitch(theme),
                  const SizedBox(height: 40),
                  _buildNextButton(theme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


Widget _buildCurrentExerciseIndicator(ThemeData theme) {
  final currentExercise = widget.superSetExercises[widget.superSetExerciseIndex];
  final exerciseName = '${currentExercise['name']} ${currentExercise['variant'] ?? ''}';

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.colorScheme.primary.withOpacity(0.2),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      'Current Exercise: $exerciseName',
      style: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

  Widget _buildSeriesIndicator(ThemeData theme) {
    final exerciseNames = widget.superSetExercises
        .map((exercise) => '${exercise['name']} ${exercise['variant'] ?? ''}')
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            widget.superSetExercises.length > 1
                ? 'Super Set ${widget.superSetExerciseIndex + 1}'
                : 'Set ${currentSeriesIndex + 1} / ${widget.seriesList.length}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          ...exerciseNames.map((exerciseName) {
            return Text(
              exerciseName,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInputField(
    ThemeData theme,
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    TextInputFormatter inputFormatter,
  ) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [inputFormatter],
      textAlign: TextAlign.center,
      style: theme.textTheme.titleLarge?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRestTimeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Rest Time:',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 20),
          _buildNumberPicker(
            theme,
            _minutes,
            0,
            59,
            (value) => setState(() => _minutes = value),
            'min',
          ),
          const SizedBox(width: 12),
          Text(
            ':',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          _buildNumberPicker(
            theme,
            _seconds,
            0,
            59,
            (value) => setState(() => _seconds = value),
            'sec',
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
    String label,
  ) {
    return Container(
      width: 90,
      height: 130,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
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
          color: theme.colorScheme.onSurface,
        ),
        selectedTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            bottom: BorderSide(
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmomSwitch(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'EMOM Mode',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 20),
        Switch(
          value: _isEmomMode,
          onChanged: (value) => setState(() => _isEmomMode = value),
          activeColor: theme.colorScheme.primary,
          activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
          inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(0.5),
          inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildNextButton(ThemeData theme) {
  final nextExerciseIndex = (widget.superSetExerciseIndex + 1) % widget.superSetExercises.length;
  final nextExercise = widget.superSetExercises[nextExerciseIndex];
  final nextSeriesList = nextExercise['series'];
  final nextSeriesIndex = nextExerciseIndex == 0
      ? (currentSeriesIndex + 1) % nextSeriesList.length
      : currentSeriesIndex;
  final nextSeriesWeight = nextSeriesList[nextSeriesIndex]['weight'].toDouble();

  return ElevatedButton(
    onPressed: () async {
      final currentSeries = widget.superSetExercises[widget.superSetExerciseIndex]['series'][currentSeriesIndex];
      await _updateSeriesData(
        widget.superSetExercises[widget.superSetExerciseIndex]['id'],
        currentSeries['id'],
        int.tryParse(_repsControllers[widget.superSetExercises[widget.superSetExerciseIndex]['id']]![currentSeries['id']]!.text),
        _weightControllers[widget.superSetExercises[widget.superSetExerciseIndex]['id']]![currentSeries['id']]!.text,
      );
      await _handleNextSeries();
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),
    child: Text(
      'NEXT (${nextSeriesWeight.toStringAsFixed(2)} kg)',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

  @override
  void dispose() {
    for (final controllers in _repsControllers.values) {
      controllers.values.forEach((controller) => controller.dispose());
    }
    for (final controllers in _weightControllers.values) {
      controllers.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }
}
