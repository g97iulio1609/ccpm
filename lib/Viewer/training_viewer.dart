import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'week_details.dart';

class TrainingViewer extends StatefulWidget {
  final String programId;
  const TrainingViewer({super.key, required this.programId});

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
     
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: weeks.length,
              itemBuilder: (context, index) {
                var week = weeks[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WeekDetails(weekId: week['id']),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  "Settimana ${week['number']}",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              week['description'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}