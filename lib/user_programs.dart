import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alphanessone/providers/providers.dart';
import './trainingBuilder/controller/training_program_controller.dart';
import './trainingBuilder/services/training_services.dart';

class UserProgramsScreen extends HookConsumerWidget {
  final String userId;

  const UserProgramsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);

    return Scaffold(
      body: Column(
        children: [
          if (userRole == 'admin' || userRole == 'client_premium')
            _buildAddProgramButton(context, userId),
          Expanded(
            child: _buildProgramList(context, ref, userId, userRole, firestoreService),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProgramButton(BuildContext context, String userId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () => _addProgram(context, userId),
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
    );
  }

  Widget _buildProgramList(BuildContext context, WidgetRef ref, String userId, String userRole, FirestoreService firestoreService) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getProgramsStream(userId, userRole),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Si è verificato un errore: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nessun programma trovato'));
        }

        final documents = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: documents.length,
          itemBuilder: (context, index) => _buildProgramCard(context, ref, documents[index], userId, userRole, firestoreService),
        );
      },
    );
  }

  Widget _buildProgramCard(BuildContext context, WidgetRef ref, DocumentSnapshot doc, String userId, String userRole, FirestoreService firestoreService) {
    final isHidden = doc['hide'] ?? false;
    final controller = ref.read(trainingProgramControllerProvider);
    final mesocycleNumber = doc['mesocycleNumber'] ?? 1;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => context.go('/user_programs/$userId/training_viewer/${doc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      doc['name'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    'Mesociclo $mesocycleNumber',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              if (isHidden && userRole == 'admin')
                Text(
                  'Nascosto',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (userRole == 'admin')
                    IconButton(
                      icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => _toggleProgramVisibility(doc.id, isHidden),
                    ),
                  if (userRole == 'admin' || userRole == 'client_premium')
                    _buildPopupMenu(context, doc, userId, controller, firestoreService),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, DocumentSnapshot doc, String userId, TrainingProgramController controller, FirestoreService firestoreService) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text('Modifica'),
          onTap: () => context.go('/user_programs/$userId/training_program/${doc.id}'),
        ),
        PopupMenuItem(
          child: const Text('Elimina'),
          onTap: () => _deleteProgram(context, doc.id, firestoreService),
        ),
        PopupMenuItem(
          child: const Text('Duplica'),
          onTap: () => _duplicateProgram(context, doc.id, controller),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _getProgramsStream(String userId, String userRole) {
    Query query = FirebaseFirestore.instance
        .collection('programs')
        .where('athleteId', isEqualTo: userId);
    
    if (userRole != 'admin') {
      query = query.where('hide', isNotEqualTo: true);
    }
    
    return query.orderBy('mesocycleNumber', descending: false).snapshots();
  }

  Future<void> _addProgram(BuildContext context, String userId) async {
    final programDetails = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddProgramDialog(userId: userId),
    );

    if (programDetails != null) {
      await FirebaseFirestore.instance.collection('programs').add({
        'name': programDetails['name'],
        'description': programDetails['description'],
        'mesocycleNumber': programDetails['mesocycleNumber'],
        'athleteId': userId,
        'hide': false,
      });
    }
  }

  Future<void> _deleteProgram(BuildContext context, String id, FirestoreService firestoreService) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma eliminazione'),
          content: const Text('Sei sicuro di voler eliminare questo programma?'),
          actions: [
            TextButton(
              child: const Text('Annulla'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            FilledButton(
              child: const Text('Elimina'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await firestoreService.removeProgram(id);
    }
  }

  Future<void> _toggleProgramVisibility(String id, bool currentVisibility) async {
    await FirebaseFirestore.instance.collection('programs').doc(id).update({
      'hide': !currentVisibility,
    });
  }

  Future<void> _duplicateProgram(BuildContext context, String docId, TrainingProgramController controller) async {
    String? newProgramName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Duplica Programma'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nuovo Nome del Programma',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (newProgramName != null && newProgramName.isNotEmpty) {
      try {
        final result = await controller.duplicateProgram(docId, newProgramName, context);
        if (context.mounted) {
          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Programma duplicato con successo: $newProgramName')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Errore durante la duplicazione del programma')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante la duplicazione del programma: $e')),
          );
        }
      }
    }
  }
}

class AddProgramDialog extends StatefulWidget {
  final String userId;

  const AddProgramDialog({super.key, required this.userId});

  @override
  AddProgramDialogState createState() => AddProgramDialogState();
}

class AddProgramDialogState extends State<AddProgramDialog> {
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Crea'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final programDetails = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'mesocycleNumber': _mesocycleNumber,
        'athleteId': widget.userId,
      };
      Navigator.of(context).pop(programDetails);
    }
  }
}