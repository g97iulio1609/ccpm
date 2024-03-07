import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'trainingprogram.dart';  // Assicurati che questa importazione sia corretta
import 'trainingviewer.dart';  // Assicurati che questa importazione sia corretta

class ProgramsScreen extends HookConsumerWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = useTextEditingController();

    Future<void> addProgram(String name) async {
      if (name.trim().isEmpty) return;
      await FirebaseFirestore.instance.collection('programs').add({
        'name': name,
      });
      controller.clear();
    }

    Future<void> deleteProgram(String id) async {
      await FirebaseFirestore.instance.collection('programs').doc(id).delete();
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Crea Programma Di Allenamento',
                suffixIcon: Icon(Icons.add),
              ),
              onSubmitted: (value) => addProgram(value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('programs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Si è verificato un errore');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final documents = snapshot.data!.docs;

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.all(10),
                      child: InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => TrainingViewer(programId: doc.id), // Ora passa a TrainingViewer
                        )),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(doc['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white, backgroundColor: Colors.green,
                                  ),
                                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => TrainingProgramPage(programId: doc.id), // Passa a TrainingProgram per modifica
                                  )),
                                  child: const Text('Modifica'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white, backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => deleteProgram(doc.id),
                                  child: const Text('Elimina'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
