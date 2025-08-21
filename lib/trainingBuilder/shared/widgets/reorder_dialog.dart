import 'package:flutter/material.dart';
import 'package:alphanessone/Main/app_theme.dart';

class ReorderDialog extends StatefulWidget {
  final List<String> items;
  final Function(int, int) onReorder;

  const ReorderDialog({required this.items, required this.onReorder, super.key});

  @override
  ReorderDialogState createState() => ReorderDialogState();
}

class ReorderDialogState extends State<ReorderDialog> {
  // Etichette visualizzate
  late List<String> _labels;
  // Chiavi stabili per ciascun elemento, restano legate all'elemento anche dopo il riordino
  late List<String> _stableKeys;
  // Indice dell'elemento attualmente in drag
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    _labels = List<String>.from(widget.items);
    // Genera chiavi univoche e stabili in base alla posizione iniziale
    // Nota: non includiamo l'indice corrente nell'etichetta per evitare chiavi instabili
    _stableKeys = List<String>.generate(_labels.length, (index) => 'reorder_key_$index');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final viewInsets = MediaQuery.of(context).viewInsets;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: AppTheme.spacing.xl + viewInsets.left,
        right: AppTheme.spacing.xl + viewInsets.right,
        top: AppTheme.spacing.lg + viewInsets.top,
        bottom: AppTheme.spacing.lg + viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          border: Border.all(color: colorScheme.outline.withAlpha(26)),
          boxShadow: AppTheme.elevations.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(77),
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radii.xl)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withAlpha(76),
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Icon(Icons.reorder, color: colorScheme.primary, size: 20),
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  Text(
                    'Riordina Elementi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                shrinkWrap: false,
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                mouseCursor: SystemMouseCursors.grab,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(204),
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        boxShadow: AppTheme.elevations.medium,
                      ),
                      child: child,
                    ),
                  );
                },
                itemCount: _labels.length,
                itemBuilder: (context, index) {
                  final itemLabel = _labels[index];
                  return Container(
                    key: ValueKey(_stableKeys[index]),
                    margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                    decoration: BoxDecoration(
                      color: _draggingIndex == index
                          ? colorScheme.primaryContainer.withAlpha(96)
                          : colorScheme.surfaceContainerHighest.withAlpha(76),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      border: Border.all(color: colorScheme.outline.withAlpha(26)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing.lg,
                          vertical: AppTheme.spacing.sm,
                        ),
                        title: Text(
                          itemLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        leading: Container(
                          padding: EdgeInsets.all(AppTheme.spacing.xs),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withAlpha(76),
                            borderRadius: BorderRadius.circular(AppTheme.radii.md),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        trailing: MouseRegion(
                          cursor: _draggingIndex == index
                              ? SystemMouseCursors.grabbing
                              : SystemMouseCursors.grab,
                          child: ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: EdgeInsets.all(AppTheme.spacing.sm),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withAlpha(128),
                                borderRadius: BorderRadius.circular(AppTheme.radii.md),
                              ),
                              child: Icon(
                                Icons.drag_handle,
                                color: colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final int externalOldIndex = oldIndex;
                    final int externalNewIndex = newIndex;

                    int insertIndex = newIndex;
                    if (oldIndex < newIndex) {
                      insertIndex -= 1;
                    }

                    final movedLabel = _labels.removeAt(oldIndex);
                    final movedKey = _stableKeys.removeAt(oldIndex);
                    _labels.insert(insertIndex, movedLabel);
                    _stableKeys.insert(insertIndex, movedKey);

                    widget.onReorder(externalOldIndex, externalNewIndex);
                  });
                },
                onReorderStart: (index) {
                  setState(() {
                    _draggingIndex = index;
                  });
                },
                onReorderEnd: (index) {
                  setState(() {
                    _draggingIndex = null;
                  });
                },
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(77),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppTheme.radii.xl)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.primary.withAlpha(204)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                            vertical: AppTheme.spacing.md,
                          ),
                          child: Text(
                            'Fatto',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
