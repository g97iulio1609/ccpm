import 'package:flutter/material.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';
import 'package:alphanessone/trainingBuilder/shared/utils/format_utils.dart';

Future<void> showSeriesExecutionDialog({
  required BuildContext context,
  required int initialReps,
  required double initialWeight,
  required Future<void> Function(int repsDone, double weightDone) onSave,
}) async {
  // Usa tematizzazione di default del dialog
  final repsController = TextEditingController(text: initialReps.toString());
  final weightController = TextEditingController(text: initialWeight.toString());

  return showAppDialog(
    context: context,
    title: const Text('Segna serie'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: repsController,
          keyboardType: const TextInputType.numberWithOptions(),
          decoration: const InputDecoration(labelText: 'Reps fatte'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Peso fatto (kg)'),
        ),
      ],
    ),
    actions: [
      AppDialogHelpers.buildCancelButton(context: context, label: 'Annulla'),
      AppDialogHelpers.buildActionButton(
        context: context,
        label: 'Salva',
        onPressed: () async {
          final repsDone = int.tryParse(repsController.text.trim()) ?? 0;
          final weightDone = FormatParsingExtensions.parseFlexibleDouble(weightController.text.trim()) ?? 0.0;
          await onSave(repsDone, weightDone);
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    ],
  );
}

Future<void> showCardioSeriesExecutionDialog({
  required BuildContext context,
  int? initialExecutedDurationSeconds,
  int? initialExecutedDistanceMeters,
  int? initialAvgHr,
  required Future<void> Function({int? executedDurationSeconds, int? executedDistanceMeters, int? executedAvgHr})
      onSave,
}) async {
  final durationController = TextEditingController(
    text: initialExecutedDurationSeconds != null ? _formatDuration(initialExecutedDurationSeconds) : '',
  );
  final distanceController = TextEditingController(
    text: initialExecutedDistanceMeters != null ? (initialExecutedDistanceMeters / 1000).toStringAsFixed(2) : '',
  );
  final avgHrController = TextEditingController(
    text: initialAvgHr?.toString() ?? '',
  );

  return showAppDialog(
    context: context,
    title: const Text('Segna Cardio'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: durationController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            labelText: 'Durata (mm:ss)',
            hintText: '15:30',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: distanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Distanza (km)',
            hintText: '5.00',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: avgHrController,
          keyboardType: const TextInputType.numberWithOptions(),
          decoration: const InputDecoration(
            labelText: 'FC Media (bpm)',
            hintText: '150',
          ),
        ),
      ],
    ),
    actions: [
      AppDialogHelpers.buildCancelButton(context: context, label: 'Annulla'),
      AppDialogHelpers.buildActionButton(
        context: context,
        label: 'Salva',
        onPressed: () async {
          final durationSeconds = _parseDuration(durationController.text.trim());
          final distanceMeters = _parseDistance(distanceController.text.trim());
          final avgHr = int.tryParse(avgHrController.text.trim());
          
          await onSave(
            executedDurationSeconds: durationSeconds,
            executedDistanceMeters: distanceMeters,
            executedAvgHr: avgHr,
          );
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    ],
  );
}

String _formatDuration(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

int? _parseDuration(String input) {
  if (input.isEmpty) return null;
  
  final parts = input.split(':');
  if (parts.length != 2) return null;
  
  final minutes = int.tryParse(parts[0]);
  final seconds = int.tryParse(parts[1]);
  
  if (minutes == null || seconds == null) return null;
  if (seconds >= 60) return null;
  
  return minutes * 60 + seconds;
}

int? _parseDistance(String input) {
  if (input.isEmpty) return null;
  final km = FormatParsingExtensions.parseFlexibleDouble(input);
  if (km == null || km < 0) return null;
  return (km * 1000).round();
}
