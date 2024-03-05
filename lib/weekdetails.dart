import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'workoutdetails.dart'; // Make sure you have this file in your project

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
          'order': doc['order'] + 1, // Incrementing week index by 1
        })
        .toList();

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: Container(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  var workout = workouts[index];
                  return Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Updated for Material 3 design
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WorkoutDetails(workoutId: workout['id']),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Allenamento ${workout['order']}",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                            ),
                            // Removed "Creato il" section
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
