import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'workout_details.dart';

class WeekDetails extends StatefulWidget {
  final String weekId;
  const WeekDetails({super.key, required this.weekId});

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
                            builder: (context) =>
                                WorkoutDetails(workoutId: workout['id']),
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
                                  Icons.fitness_center,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  "Allenamento ${workout['order']}",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
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