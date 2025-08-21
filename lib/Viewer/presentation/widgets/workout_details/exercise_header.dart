import 'package:flutter/material.dart';
import 'package:alphanessone/UI/components/section_header.dart';
import 'package:alphanessone/shared/shared.dart';

class ExerciseHeader extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onNote;
  final void Function(String action) onMenuSelected;
  final bool isAdmin;
  const ExerciseHeader({
    super.key,
    required this.exercise,
    required this.onNote,
    required this.onMenuSelected,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SectionHeader(
      title: exercise.name,
      subtitle: (exercise.variant != null && exercise.variant!.isNotEmpty)
          ? exercise.variant!
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Aggiungi o modifica nota esercizio',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.note_alt_outlined,
                color: exercise.note != null && exercise.note!.isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: onNote,
              tooltip: 'Nota',
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Azioni esercizio',
            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
            onSelected: onMenuSelected,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'change',
                child: ListTile(leading: Icon(Icons.swap_horiz), title: Text('Cambia esercizio')),
              ),
              const PopupMenuItem(
                value: 'edit_series',
                child: ListTile(leading: Icon(Icons.tune), title: Text('Modifica serie…')),
              ),
              if (isAdmin) const PopupMenuDivider(),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'add_series',
                  child: ListTile(leading: Icon(Icons.add), title: Text('Aggiungi serie…')),
                ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'add_series_group',
                  child: ListTile(
                    leading: Icon(Icons.playlist_add),
                    title: Text('Aggiungi gruppo di serie…'),
                  ),
                ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'remove_last_series',
                  child: ListTile(
                    leading: Icon(Icons.remove_circle_outline),
                    title: Text('Rimuovi ultima serie'),
                  ),
                ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'remove_all_series',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Rimuovi tutte le serie'),
                  ),
                ),
              if (isAdmin)
                const PopupMenuItem(
                  value: 'remove_exercise',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline),
                    title: Text('Rimuovi esercizio'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
