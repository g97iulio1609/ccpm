import 'package:flutter/material.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';

Future<void> showSeriesExecutionDialog({
  required BuildContext context,
  required int initialReps,
  required double initialWeight,
  required Future<void> Function(int repsDone, double weightDone) onSave,
}) async {
  // Usa tematizzazione di default del dialog
  final repsController = TextEditingController(text: initialReps.toString());
  final weightController = TextEditingController(
    text: initialWeight.toString(),
  );

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
      TextButton(
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: () async {
          final repsDone = int.tryParse(repsController.text.trim()) ?? 0;
          final weightDone =
              double.tryParse(weightController.text.trim()) ?? 0.0;
          await onSave(repsDone, weightDone);
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
        child: const Text('Salva'),
      ),
    ],
  );
}
