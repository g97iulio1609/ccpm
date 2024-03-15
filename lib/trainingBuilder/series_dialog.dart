import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'trainingModel.dart';
import '../usersServices.dart';

class SeriesDialog extends ConsumerWidget {
  final UsersService usersService;
  final String athleteId;
  final String exerciseId;
  final Series? series;

  const SeriesDialog({
    required this.usersService,
    required this.athleteId,
    required this.exerciseId,
    this.series,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
      print('Debug: exerciseId passed to SeriesDialog: $exerciseId');

    final repsController = TextEditingController(text: series?.reps.toString() ?? '');
    final setsController = TextEditingController(text: series?.sets.toString() ?? '');
    final intensityController = TextEditingController(text: series?.intensity ?? '');
    final rpeController = TextEditingController(text: series?.rpe ?? '');
    final weightController = TextEditingController(text: series?.weight.toStringAsFixed(2) ?? '');
    int latestMaxWeight = 0;

    print('Debug: Using exerciseId: $exerciseId');
 usersService.getExerciseRecords(userId: athleteId, exerciseId: exerciseId).first.then((records) {
  if (records.isNotEmpty && exerciseId.isNotEmpty) {
    final latestRecord = records.first;
    latestMaxWeight = latestRecord.maxWeight;
    print('Debug: Latest max weight received: $latestMaxWeight for exerciseId: $exerciseId');
  } else {
    print('Debug: No exercise records found or invalid exerciseId: $exerciseId');
  }
}).catchError((error) {
  print('Error retrieving exercise records for exerciseId: $exerciseId - $error');
});

    intensityController.addListener(() {
      final intensity = double.tryParse(intensityController.text) ?? 0;
      final calculatedWeight = (latestMaxWeight * intensity) / 100;
      weightController.text = calculatedWeight.toStringAsFixed(2);
      print('Debug: Calculated weight: $calculatedWeight for exerciseId: $exerciseId');
    });

    return AlertDialog(
      title: Text(series == null ? 'Add New Series' : 'Edit Series'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: setsController,
              decoration: const InputDecoration(labelText: 'Sets'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: intensityController,
              decoration: const InputDecoration(labelText: 'Intensity (%)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: rpeController,
              decoration: const InputDecoration(labelText: 'RPE'),
            ),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
              readOnly: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newSeries = Series(
              id: series?.id,
              serieId: series?.serieId ?? '',
              reps: int.parse(repsController.text),
              sets: int.parse(setsController.text),
              intensity: intensityController.text,
              rpe: rpeController.text,
              weight: double.parse(weightController.text),
              order: series?.order ?? 1,
              done: series?.done ?? false,
              reps_done: series?.reps_done ?? 0,
              weight_done: series?.weight_done ?? 0.0,
            );
            
            // Verifica che serieId abbia un valore valido
            if (newSeries.serieId.isEmpty) {
              newSeries.serieId = DateTime.now().millisecondsSinceEpoch.toString();
            }
            
            Navigator.pop(context, newSeries);
          },
          child: Text(series == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}