import 'package:flutter/material.dart';

Future<void> showSeriesExecutionDialog({
  required BuildContext context,
  required int initialReps,
  required double initialWeight,
  required Future<void> Function(int repsDone, double weightDone) onSave,
}) async {
  final colorScheme = Theme.of(context).colorScheme;
  final repsController = TextEditingController(text: initialReps.toString());
  final weightController = TextEditingController(
    text: initialWeight.toString(),
  );

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        'Segna serie',
        style: Theme.of(
          ctx,
        ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      content: Column(
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
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Annulla', style: TextStyle(color: colorScheme.primary)),
        ),
        FilledButton(
          onPressed: () async {
            final repsDone = int.tryParse(repsController.text.trim()) ?? 0;
            final weightDone =
                double.tryParse(weightController.text.trim()) ?? 0.0;
            await onSave(repsDone, weightDone);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
          child: Text('Salva', style: TextStyle(color: colorScheme.onPrimary)),
        ),
      ],
    ),
  );
}
