import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timer.dart';

class ExerciseDetails extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final String? exerciseVariant;
  final List<Map<String, dynamic>> seriesList;

  const ExerciseDetails({
    Key? key,
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseVariant,
    required this.seriesList,
  }) : super(key: key);

  @override
  _ExerciseDetailsState createState() => _ExerciseDetailsState();
}

class _ExerciseDetailsState extends State<ExerciseDetails> {
  int currentSeriesIndex = 0;
  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final TextEditingController _restTimeController = TextEditingController(text: "00:10"); // Controller per il tempo di riposo nel formato mm:ss

  @override
  void initState() {
    super.initState();
    widget.seriesList.forEach((series) {
      _repsControllers[series['id']] = TextEditingController(text: series['reps_done']?.toString() ?? '');
      _weightControllers[series['id']] = TextEditingController(text: series['weight_done']?.toString() ?? '');
    });
  }

  Future<void> updateSeriesData(String seriesId, int? repsDone, double? weightDone) async {
    await FirebaseFirestore.instance.collection('series').doc(seriesId).update({
      'done': repsDone != null && weightDone != null,
      'reps_done': repsDone,
      'weight_done': weightDone,
    });
  }

  int _convertTimeToSeconds(String time) {
    var parts = time.split(':');
    if (parts.length != 2) return 0;
    int minutes = int.tryParse(parts[0]) ?? 0;
    int seconds = int.tryParse(parts[1]) ?? 0;
    return (minutes * 60) + seconds;
  }

  void _handleNextSeries() async {
    final restTimeInSeconds = _convertTimeToSeconds(_restTimeController.text);
    if (currentSeriesIndex < widget.seriesList.length - 1) {
      final shouldProceed = await Navigator.push(
        context,
        MaterialPageRoute<bool>(
          builder: (context) => TimerPage(
            currentSeriesIndex: currentSeriesIndex,
            totalSeries: widget.seriesList.length,
            restTime: restTimeInSeconds,
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
    ThemeData theme = Theme.of(context);
    Map<String, dynamic> currentSeries = widget.seriesList[currentSeriesIndex];
    TextEditingController repsController = _repsControllers[currentSeries['id']]!;
    TextEditingController weightController = _weightControllers[currentSeries['id']]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseName} ${widget.exerciseVariant ?? ''}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Set ${currentSeriesIndex + 1} / ${widget.seriesList.length}', style: theme.textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('WEIGHT', style: theme.textTheme.titleMedium),
                SizedBox(width: 16),
                Container(
                  width: 100,
                  child: TextField(
                    controller: weightController,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                  ),
                ),
                SizedBox(width: 16),
                Text('kg', style: theme.textTheme.titleMedium),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('REPS', style: theme.textTheme.titleMedium),
                SizedBox(width: 16),
                Container(
                  width: 100,
                  child: TextField(
                    controller: repsController,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _restTimeController,
              decoration: InputDecoration(
                labelText: "Tempo di riposo (mm:ss)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}:\d{0,2}$'))],
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await updateSeriesData(
                  currentSeries['id'],
                  int.tryParse(repsController.text),
                  double.tryParse(weightController.text),
                );
                _handleNextSeries();
              },
              child: currentSeriesIndex == widget.seriesList.length - 1 ? Text('FINISH') : Text('NEXT SET'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _repsControllers.forEach((key, controller) => controller.dispose());
    _weightControllers.forEach((key, controller) => controller.dispose());
    _restTimeController.dispose();
    super.dispose();
  }
}
