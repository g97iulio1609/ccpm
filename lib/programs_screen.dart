import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'trainingviewer.dart';  // Assicurati di importare il file correttamente

class ProgramsScreen extends HookConsumerWidget {
  const ProgramsScreen({Key? key}) : super(key: key);

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
      appBar: AppBar(
        title: const Text('Programmi Di Allenamento'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Crea Programma Di Allenamento',
                suffixIcon: Icon(Icons.add), // Modifica qui se necessario per la logica
              ),
              onSubmitted: (value) => addProgram(value), // Aggiunge il programma alla pressione del tasto invio
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
                    crossAxisCount: 2, // Puoi modificare in base alla larghezza della schermata
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
                          builder: (context) => TrainingViewer(programId: doc.id),
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
                                    foregroundColor: Colors.white, backgroundColor: Colors.green, // text color
                                  ),
                                  onPressed: () {
                                    // Implementa la logica per modificare il nome del programma
                                  },
                                  child: const Text('Modifica'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white, backgroundColor: Colors.red, // text color
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
