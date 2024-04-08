// week_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WeekDetails extends StatefulWidget {
  final String programId;
  final String weekId;
  final String userId;
  const WeekDetails({super.key, required this.programId, required this.weekId, required this.userId});

  @override
  _WeekDetailsState createState() => _WeekDetailsState();
}

class _WeekDetailsState extends State<WeekDetails> {
  bool loading = true;
  List<Map<String, dynamic>> workouts = [];

  @override
  void initState() {
    super.initState();
    fetchWorkouts();
  }

  void fetchWorkouts() async {
    setState(() {
      loading = true;
    });

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('workouts')
        .where('weekId', isEqualTo: widget.weekId)
        .orderBy('order')
        .get();

    // Create a batch for reading the workout documents
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in querySnapshot.docs) {
      batch.set(doc.reference, doc.data(), SetOptions(merge: true));
    }
    await batch.commit();

    workouts = querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
              'order': doc['order'],
            })
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
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                var workout = workouts[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: InkWell(
                      onTap: () {
                        context.go(
                            '/programs_screen/user_programs/${widget.userId}/training_viewer/${widget.programId}/week_details/${widget.weekId}/workout_details/${workout['id']}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  color: Theme.of(context).primaryColor,
                                  size: 28.0,
                                ),
                                const SizedBox(width: 12.0),
                                Text(
                                  "Allenamento ${workout['order']}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              workout['description'] ?? '',
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