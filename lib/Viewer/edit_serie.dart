import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditSeriesPage extends StatefulWidget {
  final String seriesId;

  const EditSeriesPage({super.key, required this.seriesId});

  @override
  _EditSeriesPageState createState() => _EditSeriesPageState();
}

class _EditSeriesPageState extends State<EditSeriesPage> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController();
    _weightController = TextEditingController();
    _fetchSeriesData();
  }

  Future<void> _fetchSeriesData() async {
    final seriesDoc = await FirebaseFirestore.instance
        .collection('series')
        .doc(widget.seriesId)
        .get();

    if (seriesDoc.exists) {
      final seriesData = seriesDoc.data() as Map<String, dynamic>? ?? {};
      setState(() {
        _repsController.text = seriesData['reps_done']?.toString() ?? '';
        _weightController.text = seriesData['weight_done']?.toString() ?? '';
        _done = seriesData['done'] ?? false;
      });
    }
  }

  Future<void> _updateSeriesData() async {
    await FirebaseFirestore.instance
        .collection('series')
        .doc(widget.seriesId)
        .update({
      'reps_done': int.tryParse(_repsController.text) ?? 0,
      'weight_done': double.tryParse(_weightController.text) ?? 0.0,
      'done': _done,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifica Serie')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Peso (kg)'),
            ),
            SwitchListTile(
              title: const Text('Completato'),
              value: _done,
              onChanged: (value) {
                setState(() {
                  _done = value;
                });
              },
            ),
            ElevatedButton(
              onPressed: _updateSeriesData,
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}