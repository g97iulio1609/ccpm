import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'weekdetails.dart'; // Assicurati di importare WeekDetails

class TrainingViewer extends StatefulWidget {
  final String programId; // ID del programma di allenamento
  TrainingViewer({Key? key, required this.programId}) : super(key: key);

  @override
  _TrainingViewerState createState() => _TrainingViewerState();
}

class _TrainingViewerState extends State<TrainingViewer> {
  bool loading = true;
  List<Map<String, dynamic>> weeks = [];

  @override
  void initState() {
    super.initState();
    fetchTrainingWeeks();
  }

  void fetchTrainingWeeks() async {
    setState(() {
      loading = true;
    });

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('weeks')
        .where('programId', isEqualTo: widget.programId)
        .orderBy('number')
        .get();

    weeks = querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settimane", style: Theme.of(context).textTheme.headlineMedium),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: weeks.length,
                itemBuilder: (context, index) {
                  var week = weeks[index];
                  return Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    elevation: 5,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WeekDetails(weekId: week['id']),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Settimana ${week['number']}",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              week['description'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
