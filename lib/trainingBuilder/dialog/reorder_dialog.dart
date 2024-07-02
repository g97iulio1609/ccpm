import 'package:flutter/material.dart';

class ReorderDialog extends StatefulWidget {
  final List<String> items;
  final Function(int, int) onReorder;

  const ReorderDialog({required this.items, required this.onReorder, super.key});

  @override
  _ReorderDialogState createState() => _ReorderDialogState();
}

class _ReorderDialogState extends State<ReorderDialog> {
  late List<String> items;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reorder Items'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: ReorderableListView(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            children: items
                .map(
                  (item) => ListTile(
                    key: ValueKey(item),
                    title: Text(item),
                    trailing: ReorderableDragStartListener(
                      index: items.indexOf(item),
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
                )
                .toList(),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}