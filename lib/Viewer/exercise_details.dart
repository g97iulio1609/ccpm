import 'package:alphanessone/Viewer/timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:numberpicker/numberpicker.dart';

class ExerciseDetails extends StatefulWidget {
  final String programId;
  final String weekId;
  final String workoutId;
  final String exerciseId;
  final String exerciseName;
  final String? exerciseVariant;
  final List<Map<String, dynamic>> seriesList;
  final int startIndex;

  const ExerciseDetails({
    super.key,
    required this.programId,
    required this.weekId,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseVariant,
    required this.seriesList,
    required this.startIndex,
  });

  @override
  _ExerciseDetailsState createState() => _ExerciseDetailsState();
}

class _ExerciseDetailsState extends State<ExerciseDetails> {
  int currentSeriesIndex = 0;
  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};
  int _minutes = 0;
  int _seconds = 10;
  bool _isEmomMode = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _setCurrentSeriesIndex();
  }

  void _initControllers() {
    for (final series in widget.seriesList) {
      _repsControllers[series['id']] = TextEditingController(text: series['reps'].toString());
      _weightControllers[series['id']] = TextEditingController(text: series['weight'].toString());
    }
  }

  void _setCurrentSeriesIndex() {
    currentSeriesIndex = widget.startIndex;
  }

  Future<void> _updateSeriesData(String seriesId, int? repsDone, double? weightDone) async {
    final currentSeries = widget.seriesList[currentSeriesIndex];
    final expectedReps = currentSeries['reps'];
    final expectedWeight = currentSeries['weight'];

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

Future<void> _handleNextSeries() async {
  final restTimeInSeconds = _getRestTimeInSeconds();
  if (currentSeriesIndex < widget.seriesList.length - 1) {
    final shouldProceed = await context.push<bool>(
      '/programs_screen/training_viewer/${Uri.encodeComponent(widget.programId)}/week_details/${Uri.encodeComponent(widget.weekId)}/workout_details/${Uri.encodeComponent(widget.workoutId)}/exercise_details/${Uri.encodeComponent(widget.exerciseId)}/timer?currentSeriesIndex=${currentSeriesIndex + 1}&totalSeries=${widget.seriesList.length}&restTime=$restTimeInSeconds&isEmomMode=$_isEmomMode',
    );
    if (shouldProceed == true) {
      setState(() {
        currentSeriesIndex++;
      });
    }
  } else {
    context.pop();
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSeries = widget.seriesList[currentSeriesIndex];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSeriesIndicator(theme),
            const SizedBox(height: 32),
            _buildInputField(
              theme,
              'REPS',
              _repsControllers[currentSeries['id']]!,
              TextInputType.number,
              FilteringTextInputFormatter.digitsOnly,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              theme,
              'WEIGHT',
              _weightControllers[currentSeries['id']]!,
              const TextInputType.numberWithOptions(decimal: true),
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              suffix: 'kg',
            ),
            const SizedBox(height: 32),
            _buildRestTimeSelector(theme),
            const SizedBox(height: 32),
            _buildEmomSwitch(theme),
            const SizedBox(height: 48),
            _buildNextButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'Set ${currentSeriesIndex + 1} / ${widget.seriesList.length}',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildInputField(
    ThemeData theme,
    String label,
    TextEditingController controller,
    TextInputType keyboardType,
    TextInputFormatter inputFormatter, {
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: [inputFormatter],
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.colorScheme.surface.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            suffixText: suffix,
            suffixStyle: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestTimeSelector(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Rest Time',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNumberPicker(
                theme,
                _minutes,
                0,
                59,
                (value) => setState(() => _minutes = value),
                'min',
              ),
              const SizedBox(width: 16),
              Text(
                ':',
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
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
    String label,
  ) {
    return Column(
      children: [
        NumberPicker(
          value: value,
          minValue: minValue,
          maxValue: maxValue,
          onChanged: onChanged,
          itemWidth: 80,
          itemHeight: 80,
          textStyle: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          selectedTextStyle: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEmomSwitch(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'EMOM Mode',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
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
    return ElevatedButton(
      onPressed: () async {
        final currentSeries = widget.seriesList[currentSeriesIndex];
        await _updateSeriesData(
          currentSeries['id'],
          int.tryParse(_repsControllers[currentSeries['id']]!.text),
          double.tryParse(_weightControllers[currentSeries['id']]!.text),
        );
        await _handleNextSeries();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
        shadowColor: theme.colorScheme.primary.withOpacity(0.5),
      ),
      child: Text(
        currentSeriesIndex == widget.seriesList.length - 1 ? 'FINISH' : 'NEXT SET',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _repsControllers.values.forEach((controller) => controller.dispose());
    _weightControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }
}