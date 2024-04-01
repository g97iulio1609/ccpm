import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'users_services.dart';

class UserProgramsScreen extends HookConsumerWidget {
  final String? userId;

  const UserProgramsScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = useTextEditingController();
    final userRole = ref.watch(userRoleProvider);

    int getCrossAxisCount(double width) {
      if (width > 1200) {
        return 4;
      } else if (width > 800) {
        return 3;
      } else if (width > 600) {
        return 2;
      } else {
        return 1;
      }
    }

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
                final screenWidth = MediaQuery.of(context).size.width;

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: getCrossAxisCount(screenWidth),
                    childAspectRatio: 3 / 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final isHidden = doc['hide'];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: InkWell(
                        onTap: () => context.go('/programs_screen/user_programs/$userId/training_viewer/${doc.id}'),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    doc['name'],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (userRole == 'admin')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        FilledButton(
                                          onPressed: () {
                                            context.go('/programs_screen/user_programs/$userId/training_program/${doc.id}');
                                          },
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: const Text('Modifica'),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton(
                                          onPressed: () => deleteProgram(doc.id),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          ),
                                          child: const Text('Elimina'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (userRole == 'admin')
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility),
                                  color: Theme.of(context).colorScheme.onSurface,
                                  onPressed: () => toggleProgramVisibility(doc.id, isHidden),
                                ),
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