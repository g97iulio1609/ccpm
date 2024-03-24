import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timer.dart';

class ExerciseDetails extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final String? exerciseVariant;
  final List<Map<String, dynamic>> seriesList;
  final int startIndex;

  const ExerciseDetails({
    super.key,
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
  final TextEditingController _minutesController = TextEditingController(text: "00");
  final TextEditingController _secondsController = TextEditingController(text: "10");
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
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    return (minutes * 60) + seconds;
  }

  Future<void> _handleNextSeries() async {
    final restTimeInSeconds = _getRestTimeInSeconds();
    if (currentSeriesIndex < widget.seriesList.length - 1) {
      final shouldProceed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => TimerPage(
            currentSeriesIndex: currentSeriesIndex,
            totalSeries: widget.seriesList.length,
            restTime: restTimeInSeconds,
            isEmomMode: _isEmomMode,
          ),
        ),
      );
      if (shouldProceed == true) {
        setState(() {
          currentSeriesIndex++;
        });
      }
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentSeries = widget.seriesList[currentSeriesIndex];

    return Scaffold(
     /* appBar: AppBar(
        title: Text('${widget.exerciseName} ${widget.exerciseVariant ?? ''}'),
        backgroundColor: theme.colorScheme.surfaceVariant,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
      ),*/
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSeriesIndicator(theme),
            const SizedBox(height: 32),
            _buildWeightInput(theme, currentSeries),
            const SizedBox(height: 16),
            _buildRepsInput(theme, currentSeries),
            const SizedBox(height: 16),
            _buildRestTimeInput(theme),
            const SizedBox(height: 16),
            _buildEmomSwitch(theme),
            const SizedBox(height: 32),
            _buildNextButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesIndicator(ThemeData theme) {
    return Text(
      'Set ${currentSeriesIndex + 1} / ${widget.seriesList.length}',
      style: theme.textTheme.headlineSmall,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildWeightInput(ThemeData theme, Map<String, dynamic> currentSeries) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'WEIGHT',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: TextField(
              controller: _weightControllers[currentSeries['id']],
              textAlign: TextAlign.center,
              decoration: const InputDecoration.collapsed(hintText: ''),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
            ),
          ),
          Text('kg', style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildRepsInput(ThemeData theme, Map<String, dynamic> currentSeries) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'REPS',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: TextField(
        controller: _repsControllers[currentSeries['id']],
        textAlign: TextAlign.center,
        decoration: const InputDecoration.collapsed(hintText: ''),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
  }

  Widget _buildRestTimeInput(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minutesController,
            decoration: InputDecoration(
              labelText: "Minuti",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _secondsController,
            decoration: InputDecoration(
              labelText: "Secondi",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmomSwitch(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('EMOM Mode', style: theme.textTheme.titleMedium),
        Switch(
          value: _isEmomMode,
          onChanged: (value) {
            setState(() {
              _isEmomMode = value;
            });
          },
          activeColor: theme.colorScheme.primary,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Text(
        currentSeriesIndex == widget.seriesList.length - 1 ? 'FINISH' : 'NEXT SET',
        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary),
      ),
    );
  }

  @override
  void dispose() {
    _repsControllers.values.forEach((controller) => controller.dispose());
    _weightControllers.values.forEach((controller) => controller.dispose());
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }
}