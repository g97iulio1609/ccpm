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
  late List<String> items;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radii.xl),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
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
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.sm,
                      vertical: AppTheme.spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppTheme.radii.full),
                    ),
                    child: Icon(
                      Icons.reorder,
                      color: colorScheme.primary,
                      size: 20,
                    ),
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
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: ReorderableListView(
                  buildDefaultDragHandles: false,
                  shrinkWrap: true,
                  padding: EdgeInsets.all(AppTheme.spacing.lg),
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                          boxShadow: AppTheme.elevations.medium,
                        ),
                        child: child,
                      ),
                    );
                  },
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Container(
                      key: ValueKey(item),
                      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.1),
                        ),
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
                            item,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          leading: Container(
                            padding: EdgeInsets.all(AppTheme.spacing.xs),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(0.3),
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
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: Container(
                              padding: EdgeInsets.all(AppTheme.spacing.sm),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                    );
                  }).toList(),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = items.removeAt(oldIndex);
                      items.insert(newIndex, item);
                      widget.onReorder(oldIndex, newIndex);
                    });
                  },
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.radii.xl),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radii.lg),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
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
