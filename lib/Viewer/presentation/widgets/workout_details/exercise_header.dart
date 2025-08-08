import 'package:flutter/material.dart';
import 'package:alphanessone/UI/components/section_header.dart';
import 'package:alphanessone/shared/shared.dart';

class ExerciseHeader extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onNote;
  final void Function(String action) onMenuSelected;
  const ExerciseHeader({super.key, required this.exercise, required this.onNote, required this.onMenuSelected});

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
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'change',
                child: ListTile(
                  leading: Icon(Icons.swap_horiz),
                  title: Text('Cambia esercizio'),
                ),
              ),
              PopupMenuItem(
                value: 'edit_series',
                child: ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('Modifica serie…'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

