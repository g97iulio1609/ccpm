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
      _repsControllers[series['id']] =
          TextEditingController(text: series['reps'].toString());
      _weightControllers[series['id']] =
          TextEditingController(text: series['weight'].toString());
    }
  }

  void _setCurrentSeriesIndex() {
    currentSeriesIndex = widget.startIndex < widget.seriesList.length
        ? widget.startIndex
        : widget.seriesList.length - 1;
  }

  Future<void> _updateSeriesData(
      String seriesId, int? repsDone, double? weightDone) async {
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
      final result = await context.push<Map<String, dynamic>>(
        '/programs_screen/training_viewer/${Uri.encodeComponent(widget.programId)}/week_details/${Uri.encodeComponent(widget.weekId)}/workout_details/${Uri.encodeComponent(widget.workoutId)}/exercise_details/${Uri.encodeComponent(widget.exerciseId)}/timer?currentSeriesIndex=${currentSeriesIndex + 1}&totalSeries=${widget.seriesList.length}&restTime=$restTimeInSeconds&isEmomMode=$_isEmomMode',
      );
      if (result != null) {
        setState(() {
          currentSeriesIndex = result['startIndex'];
        });
      }
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSeries = currentSeriesIndex < widget.seriesList.length
        ? widget.seriesList[currentSeriesIndex]
        : null;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSeriesIndicator(theme),
              const SizedBox(height: 24),
              if (currentSeries != null) ...[
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
                  'WEIGHT (kg)',
                  _weightControllers[currentSeries['id']]!,
                  const TextInputType.numberWithOptions(decimal: true),
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                ),
              ],
              const Spacer(),
              _buildRestTimeSelector(theme),
              const SizedBox(height: 24),
              _buildEmomSwitch(theme),
              const SizedBox(height: 24),
              _buildNextButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeriesIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Set ${currentSeriesIndex + 1} / ${widget.seriesList.length}',
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
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
    TextInputFormatter inputFormatter,
  ) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [inputFormatter],
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRestTimeSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Rest Time:',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          _buildNumberPicker(
            theme,
            _minutes,
            0,
            59,
            (value) => setState(() => _minutes = value),
            'min',
          ),
          const SizedBox(width: 8),
          Text(
            ':',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
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
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: NumberPicker(
        value: value,
        minValue: minValue,
        maxValue: maxValue,
        onChanged: onChanged,
        itemHeight: 40,
        textStyle: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        selectedTextStyle: theme.textTheme.titleMedium?.copyWith(
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
          style: theme.textTheme.titleMedium?.copyWith(
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
      onPressed: currentSeriesIndex < widget.seriesList.length
          ? () async {
              final currentSeries = widget.seriesList[currentSeriesIndex];
              await _updateSeriesData(
                currentSeries['id'],
                int.tryParse(_repsControllers[currentSeries['id']]!.text),
                double.tryParse(_weightControllers[currentSeries['id']]!.text),
              );
              await _handleNextSeries();
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Text(
        currentSeriesIndex == widget.seriesList.length - 1
            ? 'FINISH'
            : 'NEXT SET',
        style: theme.textTheme.titleMedium?.copyWith(
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
