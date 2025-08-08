import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';
import 'package:alphanessone/shared/shared.dart';

class SuperSetHeaderRow extends StatelessWidget {
  final List<Exercise> exercises;
  const SuperSetHeaderRow({super.key, required this.exercises});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: AppTheme.spacing.xs,
        horizontal: AppTheme.spacing.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(AppTheme.radii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...exercises.asMap().entries.map((entry) {
            final exIndex = entry.key;
            return Expanded(
              child: Row(
                children: [
                  if (exIndex != 0) SizedBox(width: AppTheme.spacing.xs),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ID',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Reps',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Peso',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Fatti',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        SizedBox(width: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class SuperSetExerciseNameEntry extends StatelessWidget {
  final int index;
  final Exercise exercise;
  final VoidCallback onNote;
  final void Function(String action) onMenuSelected;
  const SuperSetExerciseNameEntry({
    super.key,
    required this.index,
    required this.exercise,
    required this.onNote,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: Text(
              exercise.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Semantics(
            label: 'Aggiungi o modifica nota esercizio del superset',
            button: true,
            child: IconButton(
              icon: Icon(
                Icons.note_alt_outlined,
                size: 20,
                color: exercise.note != null && exercise.note!.isNotEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              onPressed: onNote,
              tooltip: 'Nota',
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Azioni',
            icon: Icon(
              Icons.more_vert,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
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
