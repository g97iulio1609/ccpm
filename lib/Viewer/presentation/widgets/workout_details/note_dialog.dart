import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/UI/components/app_dialog.dart';

Future<void> showNoteDialog({
  required BuildContext context,
  required String title,
  String? existingNote,
  required Future<void> Function() onDelete,
  required Future<void> Function(String note) onSave,
}) async {
  final TextEditingController noteController = TextEditingController(text: existingNote);
  final colorScheme = Theme.of(context).colorScheme;

  return showAppDialog(
    context: context,
    title: Text(title),
    child: TextField(
      controller: noteController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Inserisci una nota...',
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radii.sm)),
      ),
      style: TextStyle(color: colorScheme.onSurface),
    ),
    actions: [
      if (existingNote != null)
        AppDialogHelpers.buildActionButton(
          context: context,
          label: 'Elimina',
          onPressed: () async {
            await onDelete();
            if (context.mounted) {
              Navigator.of(context, rootNavigator: true).pop();
            }
          },
          isDestructive: true,
        ),
      AppDialogHelpers.buildCancelButton(context: context),
      AppDialogHelpers.buildActionButton(
        context: context,
        label: 'Salva',
        onPressed: () async {
          final note = noteController.text.trim();
          if (note.isNotEmpty) {
            await onSave(note);
          }
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      ),
    ],
  );
}
