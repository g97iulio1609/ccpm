import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
    final userRole = ref.watch(userRoleProvider);

    Future<void> addProgram() async {
      final programDetails = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AddProgramDialog(userId: userId),
      );

      if (programDetails != null) {
        await FirebaseFirestore.instance.collection('programs').add({
          'name': programDetails['name'],
          'description': programDetails['description'],
          'mesocycleNumber': programDetails['mesocycleNumber'],
          'athleteId': userId ?? FirebaseAuth.instance.currentUser!.uid,
          'hide': false,
        });
      }
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
    return query.where('hide', isEqualTo: false).snapshots();
  }
  
  return query.snapshots();
}

    return Scaffold(
      body: Column(
        children: [
          if (userRole == 'admin' || userRole == 'client_premium')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: addProgram,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
               Text(
                      'Crea Programma Di Allenamento',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                  ],
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
                    final isHidden = doc['hide'] ?? false;
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
          if (userRole == 'admin' || userRole == 'client_premium')
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

class AddProgramDialog extends StatefulWidget {
  final String? userId;

  const AddProgramDialog({super.key, this.userId});

  @override
  _AddProgramDialogState createState() => _AddProgramDialogState();
}

class _AddProgramDialogState extends State<AddProgramDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _mesocycleNumber = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo Programma'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Inserisci un nome';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrizione',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _mesocycleNumber,
              decoration: const InputDecoration(
                labelText: 'Numero Mesociclo',
              ),
              items: List.generate(12, (index) => index + 1)
                  .map((number) => DropdownMenuItem(
                        value: number,
                        child: Text(number.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _mesocycleNumber = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final programDetails = {
                'name': _nameController.text.trim(),
                'description': _descriptionController.text.trim(),
                'mesocycleNumber': _mesocycleNumber,
                'athleteId': widget.userId,
              };
              Navigator.of(context).pop(programDetails);
            }
          },
          child: const Text('Crea'),
        ),
      ],
    );
  }
}