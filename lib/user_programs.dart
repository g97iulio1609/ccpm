import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'users_services.dart';
import './trainingBuilder/controller/training_program_controller.dart';

class UserProgramsScreen extends HookConsumerWidget {
  final String? userId;

  const UserProgramsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = useTextEditingController();
    final userRole = ref.watch(userRoleProvider);

    Future<void> addProgram() async {
      final name = controller.text.trim();
      if (name.isEmpty) return;
      await FirebaseFirestore.instance.collection('programs').add({
        'name': name,
        'athleteId': userId ?? FirebaseAuth.instance.currentUser!.uid,
        'hide': false,
      });
      controller.clear();
    }

    Future<void> deleteProgram(String id) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Conferma eliminazione'),
            content: const Text('Sei sicuro di voler eliminare questo programma?'),
            actions: [
              TextButton(
                child: const Text('Annulla'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FilledButton(
                child: const Text('Elimina'),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('programs').doc(id).delete();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

    Future<void> toggleProgramVisibility(String id, bool currentVisibility) async {
      await FirebaseFirestore.instance.collection('programs').doc(id).update({
        'hide': !currentVisibility,
      });
    }

    Stream<QuerySnapshot> getProgramsStream() {
      final query = FirebaseFirestore.instance
          .collection('programs')
          .where('athleteId', isEqualTo: userId ?? FirebaseAuth.instance.currentUser!.uid);
      
      if (userRole != 'admin') {
        query.where('hide', isEqualTo: false);
      }
      
      return query.snapshots();
    }

    return Scaffold(
      body: Column(
        children: [
          if (userRole == 'admin')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Crea Programma Di Allenamento',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: addProgram,
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getProgramsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Si è verificato un errore');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final documents = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final isHidden = doc['hide'];
                    final controller = ref.read(trainingProgramControllerProvider);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        onTap: () => context.go(
                          '/programs_screen/user_programs/$userId/training_viewer/${doc.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doc['name'],
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              if (userRole == 'admin')
                                IconButton(
                                  icon: Icon(isHidden
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () =>
                                      toggleProgramVisibility(doc.id, isHidden),
                                ),
                              if (userRole == 'admin')
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      child: const Text('Modifica'),
                                      onTap: () {
                                        context.go(
                                          '/programs_screen/user_programs/$userId/training_program/${doc.id}');
                                      },
                                    ),
                                    PopupMenuItem(
                                      child: const Text('Elimina'),
                                      onTap: () => deleteProgram(doc.id),
                                    ),
                                    PopupMenuItem(
                                      child: const Text('Duplica'),
                                      onTap: () async {
                                        String? newProgramName =
                                            await showDialog<String>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            TextEditingController
                                                _nameController =
                                                TextEditingController();
                                            return AlertDialog(
                                              title: const Text(
                                                  'Duplica Programma'),
                                              content: TextField(
                                                controller: _nameController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText:
                                                      'Nuovo Nome del Programma',
                                                ),
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: const Text(
                                                      'Annulla'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(
                                                              _nameController
                                                                  .text
                                                                  .trim()),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (newProgramName != null &&
                                            newProgramName.isNotEmpty) {
                                          await controller.duplicateProgram(
                                            doc.id,
                                            newProgramName,
                                            context);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                            ],
                          ),
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