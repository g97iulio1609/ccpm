import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

Future<void> showNoteDialog({
  required BuildContext context,
  required String title,
  String? existingNote,
  required Future<void> Function() onDelete,
  required Future<void> Function(String note) onSave,
}) async {
  final TextEditingController noteController = TextEditingController(
    text: existingNote,
  );
  final colorScheme = Theme.of(context).colorScheme;

  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: colorScheme.surface,
      title: Text(
        title,
        style: Theme.of(
          ctx,
        ).textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      content: TextField(
        controller: noteController,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: 'Inserisci una nota...',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radii.sm),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        style: TextStyle(color: colorScheme.onSurface),
      ),
      actions: [
        if (existingNote != null)
          TextButton(
            onPressed: () async {
              await onDelete();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text('Elimina', style: TextStyle(color: colorScheme.error)),
          ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Annulla', style: TextStyle(color: colorScheme.primary)),
        ),
        FilledButton(
          onPressed: () async {
            final note = noteController.text.trim();
            if (note.isNotEmpty) {
              await onSave(note);
            }
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
          style: FilledButton.styleFrom(backgroundColor: colorScheme.primary),
          child: Text('Salva', style: TextStyle(color: colorScheme.onPrimary)),
        ),
      ],
    ),
  );
}
